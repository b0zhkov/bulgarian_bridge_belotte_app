import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';

import '../core/rules/rules.dart';
import 'db.dart';
import 'host_driver.dart';
import 'room_logic.dart';
import 'room_models.dart';

enum RoomConnection { connecting, active, notFound, closed, error }

/// One player's connection to a room: presence, subscriptions, host
/// election and intents. When this player is the host it also runs the
/// [HostDriver].
class RoomClient {
  RoomClient(this.db, this.code, {required this.name, this.onChange});

  final Db db;
  final String code;
  String name;
  void Function()? onChange;

  RoomConnection connection = RoomConnection.connecting;
  RoomMeta? meta;
  Map<String, Member> members = {};
  List<Seat>? seats;

  /// Public game state (absolute seats) with this player's hand filled in.
  GameState? game;
  List<int> handCounts = const [];
  int version = 0;
  Set<String> ready = {};
  List<Card> _hand = const [];
  HostDriver? host;
  bool _everSawMeta = false;
  bool _left = false;
  int _nonce = 0;
  final List<StreamSubscription<Object?>> _subs = [];
  StreamSubscription<bool>? _connSub;

  String get uid => db.uid;
  String get _room => 'rooms/$code';
  bool get isHost => meta?.host == uid;
  int? get mySeat => RoomLogic.seatOf(seats, uid);
  Member? get me => members[uid];

  /// Seated and the hand matches the public state (no half-applied update).
  bool get handInSync =>
      mySeat != null &&
      handCounts.length == 4 &&
      handCounts[mySeat!] == _hand.length;

  // ------------------------------------------------------------ factory

  /// Creates a new room with a fresh code and joins it as host.
  static Future<RoomClient> create(
    Db db, {
    required String name,
    String Function()? codeGen,
    void Function()? onChange,
  }) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      final code = (codeGen ?? generateRoomCode)();
      final existing = RoomMeta.fromMap(await db.get('rooms/$code/meta'));
      if (existing != null) {
        if (existing.onlineCount > 0) continue;
        await _deleteRoom(db, code); // abandoned room, reuse the code
      }
      await db.set('rooms/$code', {
        'meta': {
          'host': db.uid,
          'status': 'lobby',
          'bots': {'0': 0, '1': 0},
          'onlineCount': 0,
          'matchNo': 0,
          'createdAt': const ServerTimestamp(),
        },
        'members': {
          db.uid: {
            'n': name,
            'j': const ServerTimestamp(),
            'o': false,
            't': 0,
            'ta': const ServerTimestamp(),
          },
        },
      });
      final c = RoomClient(db, code, name: name, onChange: onChange);
      await c._connect();
      return c;
    }
    throw StateError('Could not allocate a room code');
  }

  /// Joins (or re-joins) an existing room. Returns a client whose
  /// [connection] is [RoomConnection.notFound]/[RoomConnection.closed] if
  /// the code is unknown or the room was abandoned.
  static Future<RoomClient> join(
    Db db,
    String code, {
    required String name,
    void Function()? onChange,
  }) async {
    final c = RoomClient(db, code, name: name, onChange: onChange);
    final meta = RoomMeta.fromMap(await db.get('rooms/$code/meta'));
    if (meta == null) {
      c.connection = RoomConnection.notFound;
      return c;
    }
    if (meta.onlineCount <= 0) {
      await _deleteRoom(db, code);
      c.connection = RoomConnection.closed;
      return c;
    }
    final mine = await db.get('rooms/$code/members/${db.uid}');
    if (mine is Map) {
      await db.update({'rooms/$code/members/${db.uid}/n': name});
    } else {
      await db.set('rooms/$code/members/${db.uid}', {
        'n': name,
        'j': const ServerTimestamp(),
        'o': false,
        't': -1,
      });
    }
    await c._connect();
    return c;
  }

  static Future<void> _deleteRoom(Db db, String code) async {
    try {
      await db.update({'rooms/$code': null, 'hostState/$code': null});
    } catch (_) {}
  }

  // ------------------------------------------------------------ wiring

  Future<void> _connect() async {
    _connSub = db.connected.listen((online) async {
      if (!online || _left) return;
      try {
        await db.onDisconnectUpdate(_room, {
          'members/$uid/o': false,
          'meta/onlineCount': const Increment(-1),
        });
        if (_left) return;
        await db.update({
          '$_room/members/$uid/o': true,
          '$_room/meta/onlineCount': const Increment(1),
        });
      } catch (_) {}
    });
    _subs.add(db.watch('$_room/meta').listen(_onMeta, onError: _onError));
    _subs.add(db.watch('$_room/members').listen(_onMembers, onError: _onError));
    _subs.add(db.watch('$_room/seats').listen(_onSeats, onError: _onError));
    _subs.add(db.watch('$_room/pub').listen(_onPub, onError: _onError));
    _subs.add(db.watch('$_room/hands/$uid').listen(_onHand, onError: _onError));
  }

  void _onError(Object e) {
    // Permission errors appear when the room is deleted under us.
    if (_left) return;
    if (connection == RoomConnection.active ||
        connection == RoomConnection.connecting) {
      connection = _everSawMeta ? RoomConnection.closed : RoomConnection.error;
      _notify();
    }
  }

  void _notify() => onChange?.call();

  void _onMeta(Object? v) {
    final m = RoomMeta.fromMap(v);
    if (m == null) {
      if (_everSawMeta) {
        connection = RoomConnection.closed;
        _stopHost();
      }
      _notify();
      return;
    }
    _everSawMeta = true;
    meta = m;
    connection = RoomConnection.active;
    host?.onMeta(m);
    _syncHostRole();
    _notify();
  }

  void _onMembers(Object? v) {
    members = Member.parseAll(v);
    host?.onMembers(members);
    _syncHostRole();
    _notify();
  }

  void _onSeats(Object? v) {
    seats = Seat.decodeAll(v);
    _rebuildGame();
    _notify();
  }

  Map? _pub;
  void _onPub(Object? v) {
    if (v is String) {
      final m = jsonDecode(v) as Map;
      _pub = m;
      version = (m['v'] as num).toInt();
      ready = {for (final u in (m['ready'] as List? ?? const [])) u as String};
      handCounts = StateCodec.handCounts(m['g'] as Map);
    } else {
      _pub = null;
      ready = {};
      handCounts = const [];
    }
    _rebuildGame();
    _notify();
  }

  void _onHand(Object? v) {
    _hand = v is String
        ? [for (final c in jsonDecode(v) as List) Card.parse(c as String)]
        : const [];
    _rebuildGame();
    _notify();
  }

  void _rebuildGame() {
    final p = _pub;
    if (p == null) {
      game = null;
      return;
    }
    final seat = mySeat;
    game = StateCodec.decodeGameState(
      p['g'] as Map,
      hands: seat == null ? const {} : {seat: _hand},
    );
  }

  /// Keeps exactly one host: claim the role when the current host is gone
  /// and this player is the earliest-joined online member; run the
  /// [HostDriver] while holding it.
  void _syncHostRole() {
    final m = meta;
    if (m == null || _left) return;
    if (m.host == uid) {
      if (host == null) {
        final h = HostDriver(db, code)
          ..onMeta(m)
          ..members = members;
        host = h;
        h.start().then((_) => h.onMembers(members));
      }
      return;
    }
    _stopHost();
    if (members.isEmpty || members[uid]?.online != true) return;
    if (RoomLogic.electHost(members, m.host) == uid) {
      final old = m.host;
      db
          .claim('$_room/meta/host', (cur) => cur == old, uid)
          .catchError((_) => false);
    }
  }

  void _stopHost() {
    host?.dispose();
    host = null;
  }

  // ------------------------------------------------------------ actions

  Future<void> setTeam(int team) async {
    if (!RoomLogic.canJoinTeam(members, uid, team)) return;
    await db.update({
      '$_room/members/$uid/t': team,
      '$_room/members/$uid/ta': const ServerTimestamp(),
    });
  }

  /// During a match: preferred team for taking a bot seat (no cap; the
  /// host assigns seats at the end of the deal).
  Future<void> chooseWaitingTeam(int team) => db.update({
    '$_room/members/$uid/t': team,
    '$_room/members/$uid/ta': const ServerTimestamp(),
  });

  Future<void> addBots() async => host?.addBots();

  Future<bool> startMatch() async => await host?.startMatch() ?? false;

  int _nextNonce() {
    final t = clock.now().millisecondsSinceEpoch;
    _nonce = t > _nonce ? t : _nonce + 1;
    return _nonce;
  }

  Future<void> sendIntent(String kind, String? value, {int? version}) => db.set(
    '$_room/intents/$uid',
    Intent(
      nonce: _nextNonce(),
      kind: kind,
      version: version ?? this.version,
      value: value,
    ).toMap(),
  );

  Future<void> bid(Bid b) => sendIntent('bid', StateCodec.bid(b));
  Future<void> play(Card c) => sendIntent('play', c.code);
  Future<void> markReady() =>
      sendIntent('ready', null, version: game?.dealNumber ?? 0);

  /// Leaves the room: hands the host role over, deletes the room when this
  /// was the last player online.
  Future<void> leave() async {
    if (_left) return;
    _left = true;
    final h = host;
    await h?.flush();
    _stopHost();
    for (final s in _subs) {
      s.cancel();
    }
    _connSub?.cancel();
    try {
      await db.cancelOnDisconnect(_room);
      final others = Map.of(members)..remove(uid);
      final anyoneOnline = others.values.any((m) => m.online);
      if (!anyoneOnline) {
        await _deleteRoom(db, code);
      } else {
        if (meta?.host == uid) {
          final next = RoomLogic.electHost(others, null);
          if (next != null) await db.set('$_room/meta/host', next);
        }
        await db.update({
          '$_room/members/$uid': null,
          '$_room/meta/onlineCount': const Increment(-1),
        });
      }
    } catch (_) {}
  }

  /// Stops listening without telling the server (simulated crash / tests).
  void detach() {
    _left = true;
    _stopHost();
    for (final s in _subs) {
      s.cancel();
    }
    _connSub?.cancel();
  }
}
