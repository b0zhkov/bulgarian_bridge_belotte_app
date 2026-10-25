import 'dart:async';

import 'package:clock/clock.dart';

import 'db.dart';
import 'room_client.dart';

/// One player waiting in `queue/{uid}`.
class QueueEntry {
  const QueueEntry({
    required this.uid,
    required this.name,
    this.avatar,
    this.rating,
    required this.joinedAt,
    required this.beat,
    this.room,
  });

  final String uid;
  final String name;
  final String? avatar;
  final int? rating;

  /// Server time the player entered the queue.
  final int joinedAt;

  /// Server time of the last heartbeat.
  final int beat;

  /// Room code once a matchmaker claimed this player.
  final String? room;

  static QueueEntry? fromMap(String uid, Object? v) {
    if (v is! Map) return null;
    final n = v['n'], t = v['t'], h = v['h'];
    if (n is! String || t is! num || h is! num) return null;
    return QueueEntry(
      uid: uid,
      name: n,
      avatar: v['a'] as String?,
      rating: (v['r'] as num?)?.toInt(),
      joinedAt: t.toInt(),
      beat: h.toInt(),
      room: v['room'] as String?,
    );
  }

  static List<QueueEntry> parseAll(Object? v) => [
    if (v is Map)
      for (final e in v.entries) ?QueueEntry.fromMap(e.key as String, e.value),
  ];
}

/// Pure matchmaking rules (unit-tested).
class QuickLogic {
  const QuickLogic._();

  static const players = 4;

  /// Entries with a heartbeat within [staleMs] of [now] that nobody has
  /// claimed yet, oldest first (ties by uid).
  static List<QueueEntry> fresh(
    List<QueueEntry> all,
    int now, {
    int staleMs = 20000,
  }) {
    final l =
        all.where((e) => e.room == null && e.beat >= now - staleMs).toList()
          ..sort((a, b) {
            final c = a.joinedAt.compareTo(b.joinedAt);
            return c != 0 ? c : a.uid.compareTo(b.uid);
          });
    return l;
  }

  /// The players [me] should match now, [me] first, or null to keep
  /// waiting. The oldest fresh player is the matchmaker: it acts as soon as
  /// four players wait or when its own wait is over ([timeUp]). Anyone
  /// whose wait plus a grace period is over ([overdue]) acts too, so a
  /// silent matchmaker cannot stall the queue (claims are transactional,
  /// so two matchmakers never get the same player).
  static List<QueueEntry>? batch(
    List<QueueEntry> fresh,
    String me, {
    required bool timeUp,
    required bool overdue,
  }) {
    final i = fresh.indexWhere((e) => e.uid == me);
    if (i < 0) return null;
    final leader = i == 0;
    if (!(leader && (fresh.length >= players || timeUp)) && !overdue) {
      return null;
    }
    final others = [
      for (final e in fresh)
        if (e.uid != me) e,
    ];
    return [fresh[i], ...others.take(players - 1)];
  }
}

enum QuickPhase { searching, starting, matched, failed, cancelled }

/// Client-side matchmaking over the realtime database (no server code):
/// * every searching player keeps `queue/{uid}` = {n, a, r, t, h} with a
///   heartbeat `h` (server time) and an onDisconnect delete;
/// * the matchmaker ([QuickLogic.batch]) creates a quick-match room,
///   claims its own entry and then each other player's `room` field with a
///   transaction (a player is claimed at most once);
/// * claimed players see `room` on their entry and join that room;
/// * the host waits briefly for them and starts with random seats; the
///   missing places are bots (absent claimed players get a reserved seat).
class QuickMatcher {
  QuickMatcher(
    this.db, {
    required this.name,
    this.avatar,
    this.rating,
    this.onChange,
    this.codeGen,
  });

  final Db db;
  final String name;
  final String? avatar;
  final int? rating;
  final String Function()? codeGen;
  void Function()? onChange;

  static Duration wait = const Duration(seconds: 30);
  static Duration grace = const Duration(seconds: 10);
  static Duration heartbeat = const Duration(seconds: 5);
  static Duration joinWait = const Duration(seconds: 8);
  static int staleMs = 20000;

  QuickPhase phase = QuickPhase.searching;
  List<QueueEntry> entries = const [];
  DateTime? _startedAt;

  /// Room code once matched; [hostClient] is set when this player created
  /// the room (and is its host).
  String? matchedCode;
  RoomClient? hostClient;

  StreamSubscription<Object?>? _sub;
  Timer? _beat;
  Timer? _tick;
  bool _busy = false;

  String get uid => db.uid;
  String get _me => 'queue/$uid';

  int get _myBeat => entries.where((e) => e.uid == uid).firstOrNull?.beat ?? 0;

  List<QueueEntry> get freshEntries =>
      QuickLogic.fresh(entries, _myBeat, staleMs: staleMs);

  /// Players found so far (including this one), at most 4.
  int get found {
    final n = freshEntries.length;
    return n < 1 ? 1 : (n > 4 ? 4 : n);
  }

  Duration get elapsed =>
      _startedAt == null ? Duration.zero : clock.now().difference(_startedAt!);

  int get secondsLeft {
    final s = (wait - elapsed).inMilliseconds / 1000;
    return s <= 0 ? 0 : s.ceil();
  }

  Future<void> start() async {
    _startedAt = clock.now();
    await db.onDisconnectUpdate('queue', {uid: null});
    await db.set(_me, {
      'n': name,
      'a': ?avatar,
      'r': ?rating,
      't': const ServerTimestamp(),
      'h': const ServerTimestamp(),
    });
    _sub = db.watch('queue').listen(_onQueue, onError: (_) {});
    _beat = Timer.periodic(heartbeat, (_) {
      if (phase == QuickPhase.searching) {
        db.set('$_me/h', const ServerTimestamp()).catchError((_) {});
      }
    });
    _tick = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _evaluate();
      onChange?.call();
    });
  }

  void _onQueue(Object? v) {
    entries = QueueEntry.parseAll(v);
    final mine = entries.where((e) => e.uid == uid).firstOrNull;
    if (phase == QuickPhase.searching &&
        !_busy &&
        mine?.room != null &&
        hostClient == null) {
      // Another player's matchmaker picked us.
      matchedCode = mine!.room;
      phase = QuickPhase.matched;
      _stopTimers();
      _removeEntry();
    }
    _evaluate();
    onChange?.call();
  }

  void _evaluate() {
    if (phase != QuickPhase.searching || _busy) return;
    final b = QuickLogic.batch(
      freshEntries,
      uid,
      timeUp: elapsed >= wait,
      overdue: elapsed >= wait + grace,
    );
    if (b != null) _makeMatch(b);
  }

  Future<void> _makeMatch(List<QueueEntry> batch) async {
    _busy = true;
    phase = QuickPhase.starting;
    onChange?.call();
    RoomClient? c;
    try {
      c = await RoomClient.create(
        db,
        name: name,
        avatar: avatar,
        quick: true,
        codeGen: codeGen,
      );
      final code = c.code;
      // Claim ourselves first: if another matchmaker was faster, use its
      // room instead.
      final self = await db
          .claim('$_me/room', (cur) => cur == null, code)
          .catchError((_) => false);
      if (!self) {
        await c.leave();
        final mine = await db.get('$_me/room');
        if (mine is String) {
          matchedCode = mine;
          phase = QuickPhase.matched;
        } else {
          phase = QuickPhase.searching;
          _busy = false;
        }
        onChange?.call();
        if (phase == QuickPhase.matched) {
          _stopTimers();
          _removeEntry();
        }
        return;
      }
      matchedCode = code;
      hostClient = c;
      final players = <({String uid, String name})>[(uid: uid, name: name)];
      for (final e in batch.skip(1)) {
        final ok = await db
            .claim('queue/${e.uid}/room', (cur) => cur == null, code)
            .catchError((_) => false);
        if (ok) players.add((uid: e.uid, name: e.name));
      }
      _stopTimers();
      _removeEntry();
      // Give the claimed players a moment to connect.
      final until = clock.now().add(joinWait);
      while (clock.now().isBefore(until) &&
          !players.every((p) => c!.members[p.uid]?.online == true)) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      while (c.host == null && clock.now().isBefore(until)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      await c.startQuick(players);
      phase = QuickPhase.matched;
    } catch (_) {
      await c?.leave();
      hostClient = null;
      matchedCode = null;
      phase = QuickPhase.failed;
      _stopTimers();
      _removeEntry();
    }
    onChange?.call();
  }

  void _stopTimers() {
    _beat?.cancel();
    _tick?.cancel();
    _sub?.cancel();
  }

  void _removeEntry() {
    db.set(_me, null).catchError((_) {});
    db.cancelOnDisconnect('queue').catchError((_) {});
  }

  /// Leaves the queue (no-op once matched).
  Future<void> cancel() async {
    if (phase == QuickPhase.matched) return;
    phase = QuickPhase.cancelled;
    _stopTimers();
    try {
      await db.cancelOnDisconnect('queue');
      await db.set(_me, null);
    } catch (_) {}
  }

  void dispose() => _stopTimers();
}
