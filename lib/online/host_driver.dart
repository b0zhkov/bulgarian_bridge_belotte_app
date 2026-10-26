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
import 'rating.dart';
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

  /// Minimum quick-match length for a rated result (tests may lower it).
  static Duration minMatch = kMinMatch;
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
      // A previous host may have crashed before writing the result.
      if (game!.phase == GamePhase.matchOver) _writeRatingResults();
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
    return _begin(RoomLogic.seatsFromTeams(members));
  }

  /// Quick match: [players] in queue order (the host first) get random
  /// seats; players who have not connected yet get a reserved bot seat
  /// and take it over as soon as they arrive.
  Future<bool> startQuick(List<({String uid, String name})> players) {
    return _begin(
      RoomLogic.quickSeats([
        for (final p in players)
          (
            uid: p.uid,
            name: members[p.uid]?.name ?? p.name,
            present: members[p.uid]?.online == true,
          ),
      ], _rnd),
    );
  }

  Future<bool> _begin(List<Seat> s) async {
    seats = s;
    _ratedMatch = null;
    _startedAt = clock.now();
    game = BelotEngine.newMatch(
      seed: _rnd.nextInt(1 << 31),
      firstDealer: _rnd.nextInt(4),
    );
    version++;
    ready.clear();
    _holdUntil = clock.now().add(DealTiming.hold(20) + DealTiming.pageIn);
    _agents.clear();
    _publish(
      extra: {
        '$_room/meta/status': 'playing',
        if (meta?.quick == true) ...{
          '$_room/meta/st': const ServerTimestamp(),
          '$_room/meta/ur': null,
        },
      },
    );
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

  String? _ratedMatch;

  /// Quick rooms: the host writes every rated player's Elo change once
  /// the match is over (humans seated and online at the end).
  /// When this host started the current match (null after a migration:
  /// then `meta/st` is used).
  DateTime? _startedAt;

  /// How long the current match has lasted, as far as this host knows.
  Duration? get _matchLength {
    final st = _startedAt;
    if (st != null) return clock.now().difference(st);
    final s = meta?.startedAt;
    if (s == null) return null;
    return Duration(milliseconds: clock.now().millisecondsSinceEpoch - s);
  }

  void _writeRatingResults() {
    final m = meta;
    final g = game;
    final s = seats;
    if (m == null || !m.quick || g == null || s == null) return;
    if (g.phase != GamePhase.matchOver || g.winnerTeam == null) return;
    final id = m.matchId;
    if (_ratedMatch == id) return;
    _ratedMatch = id;
    final uids = RoomLogic.ratedUids(s, members);
    final winner = g.winnerTeam!;
    final len = _matchLength;
    _queue = _queue.then((_) async {
      if (_disposed) return;
      final rs = RatingService(db);
      UnratedReason? why;
      if (!bothTeamsHuman(uids)) {
        why = UnratedReason.bots;
      } else if (len != null && len < minMatch) {
        why = UnratedReason.short;
      } else {
        try {
          await rs.writeResults(code, id, uids, winner);
        } catch (_) {
          // Rejected by the rules: most likely the server saw a shorter
          // match than this host's clock.
          why = len != null && len < minMatch + const Duration(minutes: 1)
              ? UnratedReason.short
              : UnratedReason.failed;
        }
      }
      if (why == null) return;
      try {
        await rs.markUnrated(code, id, why);
      } catch (_) {}
    });
  }

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
    if (next.phase == GamePhase.matchOver &&
        before.phase != GamePhase.matchOver) {
      _writeRatingResults();
    }
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
