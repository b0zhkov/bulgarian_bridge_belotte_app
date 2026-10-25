import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/agents/bot_agent.dart';
import '../../core/agents/hint.dart';
import '../../core/rules/rules.dart';
import '../../online/db.dart';
import '../../online/firebase_db.dart';
import '../../online/room_client.dart';
import '../../online/room_logic.dart';
import '../emotes/emotes.dart';
import '../../online/room_models.dart';
import '../game/game_controller.dart';
import '../game/labels.dart';
import '../profile/match_history.dart';
import '../profile/profile_controller.dart';
import '../stats/stats_controller.dart';
import 'room_screen.dart' show seatInfosFor;

/// How to reach the backend; tests override it with a `MemoryDb`.
final dbConnectorProvider = Provider<Future<Db> Function()>(
  (ref) => FirebaseDb.connect,
);

enum OnlineError { notFound, closed, connection }

enum SeatNoticeKind { leftBot, back, joined }

/// A short toast about a seat changing hands during a game.
class SeatNotice {
  const SeatNotice(this.id, this.kind, this.name, this.seat);
  final int id;
  final SeatNoticeKind kind;

  /// The human's name (who left, came back or joined).
  final String name;

  /// Absolute seat (used to name the bot).
  final int seat;
}

class OnlineState {
  const OnlineState({
    this.client,
    this.busy = false,
    this.error,
    this.table,
    this.revision = 0,
    this.notice,
  });

  /// Latest seat change toast (cleared after [OnlineController.noticeTime]).
  final SeatNotice? notice;

  final RoomClient? client;
  final bool busy;
  final OnlineError? error;

  /// Table as seen from this player's seat (null when not seated).
  final TableState? table;
  final int revision;
}

/// Connects the UI to a [RoomClient]: create/join/leave, lobby actions and
/// the [TableActions] used by the shared table view. Presentation-only
/// state (trick pause, bubbles, hint and auto-play timers) lives here.
class OnlineController extends Notifier<OnlineState> implements TableActions {
  static Duration trickPause = const Duration(milliseconds: 1300);
  static Duration noticeTime = const Duration(milliseconds: 3500);

  final TurnTimers _turn = TurnTimers();
  RoomClient? _active;
  Timer? _holdTimer;
  Trick? _displayTrick;
  final Map<int, Announcement> _bubbles = {};
  Card? _hint;
  int? _pendingVersion;
  int _lastTricks = -1;
  int _lastDeal = -1;
  int _announcementAt = -1;
  List<Seat>? _prevSeats;
  SeatNotice? _notice;
  Timer? _noticeTimer;
  int _noticeId = 0;
  final Map<int, EmoteShow> _emotes = {};
  int _emoteNonce = 0;
  final EmoteLimiter _emoteLimiter = EmoteLimiter();

  /// Deals of the current match already counted in the stats (-1 = not
  /// seen yet) and the last match recorded in the history.
  int _countedDeals = -1;
  String? _recordedMatch;

  @override
  OnlineState build() {
    ref.onDispose(() {
      _turn.cancel();
      _holdTimer?.cancel();
      _noticeTimer?.cancel();
      _active?.detach();
    });
    return const OnlineState();
  }

  RoomClient? get client => state.client;

  Future<bool> create() => _open(
    (db, name) => RoomClient.create(
      db,
      name: name,
      avatar: ref.read(playerAvatarProvider),
      onChange: _changed,
    ),
  );

  Future<bool> join(String code) => _open(
    (db, name) => RoomClient.join(
      db,
      code,
      name: name,
      avatar: ref.read(playerAvatarProvider),
      onChange: _changed,
    ),
  );

  Future<bool> _open(
    Future<RoomClient> Function(Db db, String name) open,
  ) async {
    if (state.busy) return false;
    await leave();
    state = const OnlineState(busy: true);
    try {
      final db = await ref.read(dbConnectorProvider)();
      final name = ref.read(playerNameProvider) ?? '?';
      final c = await open(db, name);
      if (c.connection == RoomConnection.notFound) {
        state = const OnlineState(error: OnlineError.notFound);
        return false;
      }
      if (c.connection == RoomConnection.closed) {
        state = const OnlineState(error: OnlineError.closed);
        return false;
      }
      _reset();
      c.onEmote = _onEmote;
      _active = c;
      state = OnlineState(client: c);
      _changed();
      return true;
    } catch (_) {
      state = const OnlineState(error: OnlineError.connection);
      return false;
    }
  }

  void _reset() {
    _turn.cancel();
    _holdTimer?.cancel();
    _displayTrick = null;
    _bubbles.clear();
    _hint = null;
    _pendingVersion = null;
    _lastTricks = -1;
    _lastDeal = -1;
    _announcementAt = -1;
    _prevSeats = null;
    _notice = null;
    _noticeTimer?.cancel();
    _emotes.clear();
    _countedDeals = -1;
  }

  Future<void> leave() async {
    final c = state.client;
    _reset();
    _active = null;
    if (c != null) {
      state = const OnlineState();
      await c.leave();
    }
  }

  void clearError() =>
      state = OnlineState(client: state.client, table: state.table);

  // -------------------------------------------------------------- emotes

  /// Whether the rate limit allows another emote now.
  bool get canEmote => _emoteLimiter.canSend();

  /// Sends an emote; false when rate-limited or not seated.
  bool sendEmote(Emote e) {
    final c = state.client;
    if (c == null || c.mySeat == null) return false;
    if (!_emoteLimiter.tryUse()) return false;
    c.sendEmote(e.name).catchError((_) {});
    _onEmote(c.uid, e.name);
    return true;
  }

  void _onEmote(String uid, String id) {
    final c = _active;
    final e = Emote.parse(id);
    if (c == null || e == null) return;
    final abs = RoomLogic.seatOf(c.seats, uid);
    final me = c.mySeat;
    if (abs == null || me == null) return;
    if (uid != c.uid && ref.read(emotesMutedProvider)) return;
    final view = (abs - me) % 4;
    final show = EmoteShow(e, ++_emoteNonce);
    _emotes[view] = show;
    Timer(kEmoteDuration, () {
      if (_emotes[view] == show) {
        _emotes.remove(view);
        _changed();
      }
    });
    _changed();
  }

  // ------------------------------------------------------- stats/history

  /// Counts deals scored while this player is seated (team 0 = mine in
  /// [view]) and records the finished match once in the history.
  void _recordProgress(RoomClient c, GameState view) {
    final n = view.history.length;
    if (_countedDeals < 0 || n < _countedDeals) {
      // First look at this match (or a new one): earlier deals were not
      // played by us here.
      _countedDeals = n;
    }
    const mode = PlayMode.online();
    final stats = ref.read(statsProvider.notifier);
    while (_countedDeals < n) {
      stats.recordDeal(view.history[_countedDeals], mode);
      _countedDeals++;
    }
    if (view.phase != GamePhase.matchOver) return;
    final key = '${c.code}/${c.meta?.matchNo}/${view.seed}';
    if (_recordedMatch == key) return;
    _recordedMatch = key;
    stats.recordMatch(mode, won: view.winnerTeam == 0);
    final infos = seatInfosFor(
      appStrings(),
      c,
      c.name,
      ref.read(playerAvatarProvider),
    );
    ref
        .read(matchHistoryProvider.notifier)
        .add(
          MatchRecord.of(
            view,
            mode: mode,
            room: c.code,
            us: [infos[0].name, infos[2].name],
            them: [infos[1].name, infos[3].name],
          ),
        );
  }

  // ---------------------------------------------------------------- view

  void _changed() {
    final c = state.client;
    if (c == null) return;
    _detectSeatChanges(c);
    state = OnlineState(
      client: c,
      table: _buildTable(c),
      revision: state.revision + 1,
      notice: _notice,
    );
  }

  /// Toasts when a bot takes over a player's seat or a player takes a
  /// bot's seat (returning or joining) while a match is on.
  void _detectSeatChanges(RoomClient c) {
    final now = c.meta?.status == RoomStatus.playing ? c.seats : null;
    final prev = _prevSeats;
    _prevSeats = now;
    if (prev == null || now == null || prev.length != now.length) return;
    SeatNotice? n;
    for (var i = 0; i < now.length; i++) {
      final a = prev[i], b = now[i];
      if (!a.bot && b.bot && a.uid != c.uid) {
        n = SeatNotice(++_noticeId, SeatNoticeKind.leftBot, a.name ?? '?', i);
      } else if (a.bot && !b.bot && b.uid != c.uid) {
        final back = a.heldFor != null && a.heldFor == b.uid;
        n = SeatNotice(
          ++_noticeId,
          back ? SeatNoticeKind.back : SeatNoticeKind.joined,
          b.name ?? '?',
          i,
        );
      }
    }
    if (n == null) return;
    _notice = n;
    _noticeTimer?.cancel();
    _noticeTimer = Timer(noticeTime, () {
      _notice = null;
      _changed();
    });
  }

  TableState? _buildTable(RoomClient c) {
    final g = c.game;
    final seat = c.mySeat;
    if (g == null || seat == null) {
      _turn.cancel();
      return null;
    }
    final view = rotateState(g, seat);
    _recordProgress(c, view);
    if (view.dealNumber != _lastDeal) {
      _lastDeal = view.dealNumber;
      _lastTricks = view.tricks.length;
      _displayTrick = null;
      _bubbles.clear();
      _hint = null;
    } else if (view.tricks.length > _lastTricks) {
      _lastTricks = view.tricks.length;
      _displayTrick = view.tricks.last;
      _holdTimer?.cancel();
      _holdTimer = Timer(trickPause, () {
        _displayTrick = null;
        _changed();
      });
    }
    final a = view.lastAnnouncement;
    final played = view.tricks.length * 4 + view.currentTrick.plays.length;
    if (a != null && played != _announcementAt) {
      _announcementAt = played;
      _bubbles[a.seat] = a;
      Timer(const Duration(milliseconds: 2200), () {
        if (_bubbles[a.seat] == a) {
          _bubbles.remove(a.seat);
          _changed();
        }
      });
    }
    if (_pendingVersion != null && _pendingVersion != c.version) {
      _pendingVersion = null;
    }
    var table = TableState(
      game: view,
      displayTrick: _displayTrick,
      bubbles: Map.of(_bubbles),
      hint: _hint,
      locked: !c.handInSync || _pendingVersion == c.version,
      waitingReady: c.ready.contains(c.uid),
      emotes: Map.of(_emotes),
    );
    if (table.isHumanTurn) {
      _startTurnTimers(c.version, view);
    } else {
      _turn.cancel();
      if (_hint != null) {
        _hint = null;
        table = table.copyWith(clearHint: true);
      }
    }
    return table;
  }

  void _startTurnTimers(int version, GameState view) {
    _turn.start(
      ('turn', version),
      hints: ref.read(hintsEnabledProvider) && view.phase == GamePhase.playing,
      autoPlay: ref.read(autoPlayEnabledProvider),
      onHint: () {
        final t = state.table;
        if (t == null || !t.isHumanTurn || client?.version != version) return;
        if (!ref.read(hintsEnabledProvider)) return;
        _hint = suggestCard(t.game, kHumanSeat);
        _changed();
      },
      onAuto: () {
        final t = state.table;
        if (t == null || !t.isHumanTurn || client?.version != version) return;
        if (!ref.read(autoPlayEnabledProvider)) return;
        if (t.game.phase == GamePhase.playing) {
          humanPlay(_hint ?? suggestCard(t.game, kHumanSeat));
        } else if (t.game.phase == GamePhase.bidding) {
          humanBid(Bid.pass);
        }
      },
    );
  }

  // ---------------------------------------------------------- TableActions

  @override
  List<Bid> humanBids() {
    final t = state.table;
    if (t == null || !t.isHumanTurn) return const [];
    return BelotEngine.validBids(t.game, kHumanSeat);
  }

  @override
  Set<Card> humanLegalCards() {
    final t = state.table;
    if (t == null || !t.isHumanTurn) return const {};
    return BelotEngine.getLegalMoves(t.game, kHumanSeat).toSet();
  }

  @override
  void humanBid(Bid bid) {
    final c = client;
    if (c == null || !humanBids().contains(bid)) return;
    _pendingVersion = c.version;
    _turn.cancel();
    c.bid(bid);
    _changed();
  }

  @override
  void humanPlay(Card card) {
    final c = client;
    if (c == null || !humanLegalCards().contains(card)) return;
    _pendingVersion = c.version;
    _turn.cancel();
    _hint = null;
    c.play(card);
    _changed();
  }

  @override
  void nextDeal() => client?.markReady();

  @override
  void newMatch() => client?.markReady();

  // ---------------------------------------------------------------- lobby

  Future<void> setTeam(int team) async => client?.setTeam(team);
  Future<void> chooseWaitingTeam(int team) async =>
      client?.chooseWaitingTeam(team);
  Future<void> addBots() async => client?.addBots();

  Future<void> setBotLevel(BotLevel level) async => client?.setBotLevel(level);
  Future<void> startMatch() async => client?.startMatch();
}

final onlineControllerProvider =
    NotifierProvider<OnlineController, OnlineState>(OnlineController.new);
