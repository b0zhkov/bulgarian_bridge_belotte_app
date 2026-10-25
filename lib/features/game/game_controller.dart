import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/agents/hint.dart';
import '../../core/constants/deal_timing.dart';
import '../../core/agents/bot_agent.dart';
import '../../core/agents/bot_runner.dart';
import '../../core/rules/rules.dart';
import '../emotes/emotes.dart';
import '../profile/profile_controller.dart';
import '../../l10n/generated/app_localizations.dart';
import 'labels.dart';
import '../stats/stats_controller.dart';

const int kHumanSeat = 0;

/// What the table shows. Wraps the immutable engine state with transient
/// presentation state (trick pauses, speech bubbles).
class TableState {
  const TableState({
    required this.game,
    this.displayTrick,
    this.bubbles = const {},
    this.hint,
    this.seatInfos,
    this.locked = false,
    this.waitingReady = false,
    this.emotes = const {},
  });

  /// Online: emotes currently shown per (view) seat.
  final Map<int, EmoteShow> emotes;

  /// Names/emojis per (view) seat for online games; null = offline bots.
  final List<SeatInfo>? seatInfos;

  /// Input temporarily blocked (online: an action is in flight or the hand
  /// is not in sync with the public state yet).
  final bool locked;

  /// Online: this player already confirmed the deal result.
  final bool waitingReady;

  final GameState game;

  /// A just-completed trick kept on the table for a moment.
  final Trick? displayTrick;

  /// Short-lived announcements per seat (declarations, belot).
  final Map<int, Announcement> bubbles;

  /// Suggested card for the human after a long pause (null = no hint).
  final Card? hint;

  bool get holding => displayTrick != null;
  Trick get visibleTrick => displayTrick ?? game.currentTrick;
  bool get isHumanTurn =>
      !holding &&
      !locked &&
      game.currentSeat == kHumanSeat &&
      (game.phase == GamePhase.bidding || game.phase == GamePhase.playing);

  TableState copyWith({
    GameState? game,
    Trick? displayTrick,
    bool clearDisplayTrick = false,
    Map<int, Announcement>? bubbles,
    Card? hint,
    bool clearHint = false,
    List<SeatInfo>? seatInfos,
    bool? locked,
    bool? waitingReady,
    Map<int, EmoteShow>? emotes,
  }) => TableState(
    game: game ?? this.game,
    displayTrick: clearDisplayTrick
        ? null
        : (displayTrick ?? this.displayTrick),
    bubbles: bubbles ?? this.bubbles,
    hint: clearHint ? null : (hint ?? this.hint),
    seatInfos: seatInfos ?? this.seatInfos,
    locked: locked ?? this.locked,
    waitingReady: waitingReady ?? this.waitingReady,
    emotes: emotes ?? this.emotes,
  );

  /// Name and emoji for a view seat.
  SeatInfo infoFor(AppLocalizations l, int seat, [String? myName]) =>
      seatInfos?[seat] ?? seatInfo(l, seat, myName);
}

/// What the table screen can ask the game to do (offline controller or
/// online room).
abstract class TableActions {
  List<Bid> humanBids();
  Set<Card> humanLegalCards();
  void humanBid(Bid bid);
  void humanPlay(Card card);
  void nextDeal();
  void newMatch();
}

/// Hint (25 s) and auto-play (40 s) timers for the local player's turn.
class TurnTimers {
  static Duration hintDelay = const Duration(seconds: 25);
  static Duration autoPlayDelay = const Duration(seconds: 40);

  Timer? _hint;
  Timer? _auto;
  Object? _token;

  /// Starts timers for [token] (a turn identity); no-op if already running
  /// for the same turn.
  void start(
    Object token, {
    required bool hints,
    required bool autoPlay,
    required void Function() onHint,
    required void Function() onAuto,
  }) {
    if (token == _token) return;
    cancel();
    _token = token;
    if (hints) _hint = Timer(hintDelay, onHint);
    if (autoPlay) _auto = Timer(autoPlayDelay, onAuto);
  }

  void cancel() {
    _hint?.cancel();
    _auto?.cancel();
    _hint = _auto = null;
    _token = null;
  }
}

/// Drives a local match: the human plays seat 0, [BotAgent]s of the chosen
/// difficulty play the other seats.
class GameController extends Notifier<TableState> implements TableActions {
  final List<Timer> _timers = [];
  late Map<int, BotAgent> _agents;
  Random _rnd = Random();

  /// A natural pause before a bot acts: [botDelay] to twice that
  /// (0.6–1.2 s by default).
  Duration get _botPause {
    final pause = botDelay * (1 + _rnd.nextDouble());
    final hold = _dealHoldUntil?.difference(clock.now());
    return hold != null && hold > pause ? hold : pause;
  }

  /// Bots wait while the cards are being dealt on screen.
  DateTime? _dealHoldUntil;
  void _holdForDeal(int cards) =>
      _dealHoldUntil = clock.now().add(DealTiming.hold(cards));

  static Duration botDelay = const Duration(milliseconds: 600);
  static Duration trickPause = const Duration(milliseconds: 1100);
  static Duration redealPause = const Duration(milliseconds: 1600);
  static Duration get hintDelay => TurnTimers.hintDelay;
  static set hintDelay(Duration d) => TurnTimers.hintDelay = d;
  static Duration get autoPlayDelay => TurnTimers.autoPlayDelay;
  static set autoPlayDelay(Duration d) => TurnTimers.autoPlayDelay = d;
  static int? fixedSeed;
  final TurnTimers _turn = TurnTimers();

  @override
  TableState build() {
    ref.onDispose(_cancelTimers);
    return _start();
  }

  TableState _start() {
    final seed = fixedSeed ?? Random().nextInt(1 << 31);
    final level = ref.read(botLevelProvider);
    _agents = {
      for (final s in [1, 2, 3]) s: BotAgent(level, seed: seed + s),
    };
    _rnd = Random(seed);
    _holdForDeal(20);
    final initial = TableState(game: BelotEngine.newMatch(seed: seed));
    Future.microtask(_schedule);
    return initial;
  }

  void _cancelTimers() {
    _turn.cancel();
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  void _after(Duration d, void Function() f) {
    late Timer t;
    t = Timer(d, () {
      _timers.remove(t);
      f();
    });
    _timers.add(t);
  }

  void _schedule() {
    final s = state;
    if (s.holding) return;
    final g = s.game;
    switch (g.phase) {
      case GamePhase.bidding:
        if (g.currentSeat == kHumanSeat) _startTurnTimers();
        if (g.currentSeat != kHumanSeat) {
          _after(_botPause, () {
            final seat = state.game.currentSeat;
            if (state.game.phase != GamePhase.bidding || seat == kHumanSeat) {
              return;
            }
            _bid(seat, _agents[seat]!.chooseBid(state.game, seat));
          });
        }
      case GamePhase.playing:
        if (g.currentSeat == kHumanSeat) _startTurnTimers();
        if (g.currentSeat != kHumanSeat) {
          // Hard bots think in the background while the pause runs.
          final seat0 = g.currentSeat;
          final pending = _agents[seat0]!.level == BotLevel.hard
              ? chooseBotPlay(_agents[seat0]!, g, seat0)
              : null;
          _after(_botPause, () async {
            final seat = state.game.currentSeat;
            if (state.game.phase != GamePhase.playing ||
                seat == kHumanSeat ||
                state.holding) {
              return;
            }
            final before = state.game;
            final card = pending != null && seat == seat0
                ? await pending
                : _agents[seat]!.choosePlay(before, seat);
            if (!identical(state.game, before)) return;
            _play(seat, card);
          });
        }
      case GamePhase.allPassed:
        _after(redealPause, () {
          if (state.game.phase == GamePhase.allPassed) {
            _holdForDeal(20);
            state = state.copyWith(
              game: BelotEngine.nextDeal(state.game),
              bubbles: const {},
            );
            _schedule();
          }
        });
      case GamePhase.dealScored:
      case GamePhase.matchOver:
        break;
    }
  }

  int _cardsPlayed(GameState g) =>
      g.tricks.length * 4 + g.currentTrick.plays.length;

  /// Hint after 25 s and auto-play after 40 s on the human's turn.
  void _startTurnTimers() {
    final g = state.game;
    final token = (g.dealNumber, g.phase, _cardsPlayed(g), g.bids.length);
    bool sameTurn() {
      final n = state.game;
      return state.isHumanTurn &&
          (n.dealNumber, n.phase, _cardsPlayed(n), n.bids.length) == token;
    }

    _turn.start(
      token,
      hints: ref.read(hintsEnabledProvider) && g.phase == GamePhase.playing,
      autoPlay: ref.read(autoPlayEnabledProvider),
      onHint: () {
        if (!sameTurn() || !ref.read(hintsEnabledProvider)) return;
        state = state.copyWith(hint: suggestCard(state.game, kHumanSeat));
      },
      onAuto: () {
        if (!sameTurn() || !ref.read(autoPlayEnabledProvider)) return;
        final n = state.game;
        if (n.phase == GamePhase.playing) {
          _play(kHumanSeat, state.hint ?? suggestCard(n, kHumanSeat));
        } else if (n.phase == GamePhase.bidding) {
          _bid(kHumanSeat, Bid.pass);
        }
      },
    );
  }

  void _recordStats(GameState before, GameState after) {
    if (before.phase != GamePhase.playing) return;
    if (after.phase != GamePhase.dealScored &&
        after.phase != GamePhase.matchOver) {
      return;
    }
    final stats = ref.read(statsProvider.notifier);
    stats.recordDeal(after.lastDeal!);
    if (after.phase == GamePhase.matchOver) {
      stats.recordMatch(won: after.winnerTeam == 0);
    }
  }

  void _bid(int seat, Bid bid) {
    if (seat == kHumanSeat) _turn.cancel();
    final next = BelotEngine.applyBid(state.game, seat, bid);
    if (next.phase == GamePhase.playing) _holdForDeal(12);
    state = state.copyWith(game: next);
    _schedule();
  }

  void _play(int seat, Card card) {
    final before = state.game;
    final after = BelotEngine.applyPlay(before, seat, card);
    if (seat == kHumanSeat) {
      _turn.cancel();
      state = state.copyWith(clearHint: true);
    }
    _recordStats(before, after);
    var bubbles = state.bubbles;
    final a = after.lastAnnouncement;
    if (a != null) {
      bubbles = {...bubbles, a.seat: a};
      _after(const Duration(milliseconds: 2200), () {
        if (state.bubbles[a.seat] == a) {
          state = state.copyWith(bubbles: {...state.bubbles}..remove(a.seat));
        }
      });
    }
    if (after.tricks.length > before.tricks.length) {
      state = state.copyWith(
        game: after,
        displayTrick: after.tricks.last,
        bubbles: bubbles,
      );
      _after(trickPause, () {
        state = state.copyWith(clearDisplayTrick: true);
        _schedule();
      });
    } else {
      state = state.copyWith(game: after, bubbles: bubbles);
      _schedule();
    }
  }

  // ------------------------------------------------------------ human API

  @override
  List<Bid> humanBids() => state.isHumanTurn
      ? BelotEngine.validBids(state.game, kHumanSeat)
      : const [];

  @override
  Set<Card> humanLegalCards() => state.isHumanTurn
      ? BelotEngine.getLegalMoves(state.game, kHumanSeat).toSet()
      : const {};

  @override
  void humanBid(Bid bid) {
    if (!humanBids().contains(bid)) return;
    _bid(kHumanSeat, bid);
  }

  @override
  void humanPlay(Card card) {
    if (!humanLegalCards().contains(card)) return;
    _play(kHumanSeat, card);
  }

  @override
  void nextDeal() {
    if (state.game.phase != GamePhase.dealScored) return;
    _holdForDeal(20);
    state = state.copyWith(
      game: BelotEngine.nextDeal(state.game),
      bubbles: const {},
    );
    _schedule();
  }

  @override
  void newMatch() {
    _cancelTimers();
    state = _start();
  }
}

final gameControllerProvider =
    NotifierProvider.autoDispose<GameController, TableState>(
      GameController.new,
    );
