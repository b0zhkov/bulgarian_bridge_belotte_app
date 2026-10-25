import '../core/constants/deal_timing.dart';
import '../core/agents/bot_agent.dart';
import '../core/agents/bot_runner.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:clock/clock.dart';

import '../core/agents/hint.dart';
import '../core/agents/player_agent.dart';
import '../core/rules/rules.dart';
import 'db.dart';
import 'room_logic.dart';
import 'room_models.dart';

/// Authoritative game loop run by the room host's client.
///
/// Holds the full [GameState] (with every hand), validates player intents
/// with the pure engine, drives bots and writes:
/// * `rooms/{code}/pub`   – public state (no hands, no seed),
/// * `rooms/{code}/hands/{uid}` – each seated human's own cards,
/// * `rooms/{code}/seats` – who sits where (humans / bots),
/// * `hostState/{code}`   – full state, readable only by the host, so a
///   new host can take over seamlessly.
class HostDriver {
  HostDriver(
    this.db,
    this.code, {
    PlayerAgent Function(int seat)? agent,
    Random? rnd,
  }) : _agentFactory = agent,
       _rnd = rnd ?? Random();

  final Db db;
  final String code;

  /// Overrides the bots (tests); default: [BotAgent] at the room's level.
  final PlayerAgent Function(int seat)? _agentFactory;
  final Random _rnd;
  final Map<int, PlayerAgent> _agents = {};

  /// Bots pause between [botDelay] and twice that (0.6–1.2 s) before acting.
  static Duration botDelay = const Duration(milliseconds: 600);
  static Duration trickPause = const Duration(milliseconds: 1400);
  static Duration redealPause = const Duration(milliseconds: 1800);
  static Duration dealEndTimeout = const Duration(seconds: 20);
  static Duration matchEndTimeout = const Duration(seconds: 30);

  /// Safety net so a match never stalls on an idle player whose own
  /// auto-play is switched off.
  static Duration turnTimeout = const Duration(seconds: 90);

  GameState? game;
  List<Seat>? seats;
  int version = 0;
  final Set<String> ready = {};
  final Map<String, int> seen = {};
  final Set<String> _handOwners = {};
  Map<String, Member> members = {};
  RoomMeta? meta;
  DateTime? _holdUntil;
  Timer? _timer;
  StreamSubscription<Object?>? _intentSub;
  bool _disposed = false;
  bool _started = false;
  Future<void> _queue = Future.value();

  String get _room => 'rooms/$code';

  /// Loads any running match (after a host migration) and starts listening
  /// to intents.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    final hs = await db.get('hostState/$code');
    if (hs is String) {
      final m = jsonDecode(hs) as Map;
      game = StateCodec.decodeGameState(m['g'] as Map);
      version = (m['v'] as num).toInt();
      (m['seen'] as Map? ?? const {}).forEach(
        (k, v) => seen[k as String] = (v as num).toInt(),
      );
      _handOwners.addAll([
        for (final u in (m['h'] as List? ?? const [])) u as String,
      ]);
      ready.addAll([
        for (final u in (m['r'] as List? ?? const [])) u as String,
      ]);
      seats = Seat.decodeAll(await db.get('$_room/seats'));
    }
    if (_disposed) return;
    _intentSub = db.watch('$_room/intents').listen(_onIntents);
    if (game != null && seats != null) {
      _reconcilePresence(force: true);
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _intentSub?.cancel();
  }

  Future<void> flush() => _queue;

  void onMeta(RoomMeta m) => meta = m;

  void onMembers(Map<String, Member> m) {
    members = m;
    if (_disposed) return;
    if (game != null && seats != null) {
      _reconcilePresence();
    } else if (meta?.status != RoomStatus.playing) {
      final fix = RoomLogic.normalizeTeams(members);
      if (fix.isNotEmpty) {
        _write({
          for (final e in fix.entries)
            '$_room/members/${e.key}/t': e.value ?? -1,
        });
      }
    }
  }

  void _reconcilePresence({bool force = false}) {
    final g = game!;
    final next = RoomLogic.applyPresence(seats!, members, g.dealNumber);
    if (!force && _listEq(next, seats!)) return;
    seats = next;
    _publish();
    _schedule();
  }

  static bool _listEq(List<Seat> a, List<Seat> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // ----------------------------------------------------------- lobby

  PlayerAgent _agentFor(int seat) => _agents[seat] ??=
      _agentFactory?.call(seat) ??
      BotAgent(
        meta?.botLevel ?? BotLevel.medium,
        seed: (game?.seed ?? 0) + seat,
      );

  Future<void> setBotLevel(BotLevel level) {
    _agents.clear();
    return _write({'$_room/meta/lvl': level.name});
  }

  Future<void> addBots() => _write({
    '$_room/meta/bots': {
      '0': RoomLogic.fillBots(members)[0],
      '1': RoomLogic.fillBots(members)[1],
    },
  });

  Future<bool> startMatch() async {
    final m = meta;
    if (m == null || !RoomLogic.canStart(members, m.bots)) return false;
    seats = RoomLogic.seatsFromTeams(members);
    game = BelotEngine.newMatch(
      seed: _rnd.nextInt(1 << 31),
      firstDealer: _rnd.nextInt(4),
    );
    version++;
    ready.clear();
    _holdUntil = clock.now().add(DealTiming.hold(20));
    _agents.clear();
    _publish(extra: {'$_room/meta/status': 'playing'});
    _schedule();
    await _queue;
    return true;
  }

  // ----------------------------------------------------------- intents

  void _onIntents(Object? v) {
    if (_disposed || v is! Map) return;
    for (final e in v.entries) {
      final uid = e.key as String;
      final i = Intent.fromMap(e.value);
      if (i == null || i.nonce <= (seen[uid] ?? 0)) continue;
      seen[uid] = i.nonce;
      handleIntent(uid, i);
    }
  }

  /// Applies one intent (public for tests).
  void handleIntent(String uid, Intent i) {
    final g = game;
    if (g == null || seats == null) return;
    final seat = RoomLogic.seatOf(seats, uid);
    if (seat == null) return;
    if (i.kind == 'ready') {
      if ((g.phase == GamePhase.dealScored || g.phase == GamePhase.matchOver) &&
          i.version == g.dealNumber &&
          ready.add(uid)) {
        _publish();
        _schedule();
      }
      return;
    }
    if (_holding) return;
    final next = RoomLogic.applyIntent(g, seat, i, version: version);
    if (next != null) _apply(next);
  }

  bool get _holding => _holdUntil != null && clock.now().isBefore(_holdUntil!);

  void _apply(GameState next) {
    final before = game!;
    game = next;
    version++;
    if (next.tricks.length > before.tricks.length) {
      _holdUntil = clock.now().add(trickPause);
    } else if (before.phase == GamePhase.bidding &&
        next.phase == GamePhase.playing) {
      // The last three cards are being dealt on every client.
      _holdUntil = clock.now().add(DealTiming.hold(12));
    }
    _publish();
    _schedule();
  }

  // ----------------------------------------------------------- loop

  Duration get _holdLeft {
    final h = _holdUntil;
    if (h == null) return Duration.zero;
    final d = h.difference(clock.now());
    return d.isNegative ? Duration.zero : d;
  }

  List<String> get _seatedOnlineHumans => [
    for (final s in seats ?? const <Seat>[])
      if (!s.bot && members[s.uid]?.online == true) s.uid!,
  ];

  bool get _allReady => _seatedOnlineHumans.every(ready.contains);

  void _schedule() {
    _timer?.cancel();
    final g = game;
    if (_disposed || g == null || seats == null) return;
    switch (g.phase) {
      case GamePhase.bidding:
      case GamePhase.playing:
        final seat = g.currentSeat;
        final token = version;
        if (seats![seat].bot) {
          final agent = _agentFor(seat);
          // Hard bots think (off the UI thread) during the pause.
          final pending =
              g.phase == GamePhase.playing &&
                  agent is BotAgent &&
                  agent.level == BotLevel.hard
              ? chooseBotPlay(agent, g, seat)
              : null;
          _timer = Timer(
            botDelay * (1 + _rnd.nextDouble()) + _holdLeft,
            () => _autoAct(token, seat, pending),
          );
        } else {
          _timer = Timer(turnTimeout + _holdLeft, () => _autoAct(token, seat));
        }
      case GamePhase.allPassed:
        _timer = Timer(redealPause, _nextDeal);
      case GamePhase.dealScored:
        _timer = Timer(
          _allReady ? const Duration(milliseconds: 400) : dealEndTimeout,
          _nextDeal,
        );
      case GamePhase.matchOver:
        _timer = Timer(
          _allReady ? const Duration(milliseconds: 400) : matchEndTimeout,
          toLobby,
        );
    }
  }

  Future<void> _autoAct(int token, int seat, [Future<Card>? pending]) async {
    var g = game;
    if (_disposed || g == null || version != token || g.currentSeat != seat) {
      return;
    }
    if (_holding) {
      _schedule();
      return;
    }
    if (pending != null) {
      final card = await pending;
      g = game;
      if (_disposed || g == null || version != token) return;
      if (!seats![seat].bot) {
        // The player came back while the bot was thinking.
        _schedule();
        return;
      }
      _apply(BelotEngine.applyPlay(g, seat, card));
      return;
    }
    final agent = _agentFor(seat);
    final GameState next;
    if (g.phase == GamePhase.bidding) {
      next = BelotEngine.applyBid(
        g,
        seat,
        seats![seat].bot ? agent.chooseBid(g, seat) : Bid.pass,
      );
    } else if (g.phase == GamePhase.playing) {
      next = BelotEngine.applyPlay(
        g,
        seat,
        seats![seat].bot ? agent.choosePlay(g, seat) : suggestCard(g, seat),
      );
    } else {
      return;
    }
    _apply(next);
  }

  void _nextDeal() {
    final g = game;
    if (_disposed || g == null) return;
    if (g.phase != GamePhase.dealScored && g.phase != GamePhase.allPassed) {
      return;
    }
    seats = RoomLogic.assignWaiting(seats!, members);
    game = BelotEngine.nextDeal(g);
    version++;
    ready.clear();
    _holdUntil = clock.now().add(DealTiming.hold(20));
    _publish();
    _schedule();
  }

  /// Match over: everybody goes back to the team-selection lobby.
  Future<void> toLobby() async {
    if (_disposed) return;
    _timer?.cancel();
    // Lobby teams reflect where everybody sat in the finished match.
    final teams = <String, Object?>{
      for (var i = 0; i < 4; i++)
        if (seats != null &&
            !seats![i].bot &&
            members.containsKey(seats![i].uid))
          '$_room/members/${seats![i].uid}/t': i % 2,
    };
    game = null;
    seats = null;
    ready.clear();
    _handOwners.clear();
    await _write({
      '$_room/meta/status': 'lobby',
      '$_room/meta/matchNo': (meta?.matchNo ?? 0) + 1,
      '$_room/pub': null,
      '$_room/seats': null,
      '$_room/hands': null,
      'hostState/$code': null,
      ...teams,
    });
  }

  // ----------------------------------------------------------- writes

  void _publish({Map<String, Object?> extra = const {}}) {
    final g = game!;
    final s = seats!;
    final owners = <String>{
      for (final x in s)
        if (!x.bot) x.uid!,
    };
    final update = <String, Object?>{
      '$_room/pub': jsonEncode({
        'v': version,
        'g': StateCodec.encodeGameState(g, full: false),
        'ready': ready.toList(),
      }),
      '$_room/seats': Seat.encodeAll(s),
      for (var i = 0; i < 4; i++)
        if (!s[i].bot)
          '$_room/hands/${s[i].uid}': jsonEncode(StateCodec.cards(g.hands[i])),
      for (final u in _handOwners.difference(owners)) '$_room/hands/$u': null,
      'hostState/$code': jsonEncode({
        'g': StateCodec.encodeGameState(g),
        'v': version,
        'seen': seen,
        'h': owners.toList(),
        'r': ready.toList(),
      }),
      ...extra,
    };
    _handOwners
      ..clear()
      ..addAll(owners);
    _write(update);
  }

  Future<void> _write(Map<String, Object?> update) {
    _queue = _queue.then((_) async {
      if (_disposed) return;
      try {
        await db.update(update);
      } catch (_) {
        // Lost connection or host role; the next host resumes from the
        // last state that made it to the server.
      }
    });
    return _queue;
  }
}
