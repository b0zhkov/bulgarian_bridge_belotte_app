import 'dart:async';

import 'db.dart';

/// In-memory realtime database shared by several fake clients. Used by
/// tests to simulate multiple players, disconnects and host migration
/// without any network. Security rules are not modelled.
class MemoryDbServer {
  Map<String, Object?> _root = {};
  int now = 1000;
  final List<_Listener> _listeners = [];
  final Map<String, MemoryDb> _clients = {};

  MemoryDb client(String uid) => _clients[uid] ??= MemoryDb._(this, uid);

  static List<String> _split(String path) =>
      path.split('/').where((e) => e.isNotEmpty).toList();

  Object? read(String path) {
    Object? cur = _root;
    for (final k in _split(path)) {
      if (cur is! Map) return null;
      cur = cur[k];
    }
    return _copy(cur);
  }

  static Object? _copy(Object? v) {
    if (v is Map) return {for (final e in v.entries) e.key: _copy(e.value)};
    if (v is List) return [for (final x in v) _copy(x)];
    return v;
  }

  Object? _resolve(String path, Object? v) {
    if (v is ServerTimestamp) return now++;
    if (v is Increment) return ((read(path) as num?) ?? 0).toInt() + v.delta;
    if (v is Map) {
      return {
        for (final e in v.entries)
          if (e.value != null)
            e.key as String: _resolve('$path/${e.key}', e.value),
      };
    }
    return v;
  }

  void _write(String path, Object? value) {
    final keys = _split(path);
    final resolved = _resolve(path, value);
    if (keys.isEmpty) {
      _root = (resolved as Map<String, Object?>?) ?? {};
      return;
    }
    final stack = <Map<String, Object?>>[_root];
    var cur = _root;
    for (final k in keys.sublist(0, keys.length - 1)) {
      final next = cur[k];
      if (next is Map<String, Object?>) {
        cur = next;
      } else {
        if (resolved == null) return;
        final m = <String, Object?>{};
        cur[k] = m;
        cur = m;
      }
      stack.add(cur);
    }
    if (resolved == null || (resolved is Map && resolved.isEmpty)) {
      cur.remove(keys.last);
    } else {
      cur[keys.last] = resolved;
    }
    // Prune empty parents.
    for (var i = stack.length - 1; i > 0; i--) {
      if (stack[i].isEmpty) stack[i - 1].remove(keys[i - 1]);
    }
  }

  void applyUpdate(Map<String, Object?> values) {
    final paths = <String>[];
    for (final e in values.entries) {
      _write(e.key, e.value);
      paths.add(e.key);
    }
    _notify(paths);
  }

  void _notify(List<String> paths) {
    for (final l in List.of(_listeners)) {
      if (!l.client.isConnected) continue;
      final touched = paths.any(
        (p) =>
            p == l.path ||
            p.startsWith('${l.path}/') ||
            l.path.startsWith('$p/') ||
            l.path.isEmpty,
      );
      if (!touched) continue;
      final v = read(l.path);
      if (_deepEq(v, l.last)) continue;
      l.last = v;
      scheduleMicrotask(() {
        if (!l.ctrl.isClosed) l.ctrl.add(v);
      });
    }
  }

  static bool _deepEq(Object? a, Object? b) {
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final k in a.keys) {
        if (!b.containsKey(k) || !_deepEq(a[k], b[k])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEq(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }

  /// Simulates the network dropping for [uid]: onDisconnect writes run and
  /// the client stops receiving events until [reconnect].
  void disconnect(String uid) {
    final c = _clients[uid]!;
    if (!c.isConnected) return;
    c.isConnected = false;
    c._conn.add(false);
    final ops = Map.of(c._onDisconnect);
    c._onDisconnect.clear();
    for (final e in ops.entries) {
      applyUpdate({
        for (final v in e.value.entries) '${e.key}/${v.key}': v.value,
      });
    }
  }

  void reconnect(String uid) {
    final c = _clients[uid]!;
    if (c.isConnected) return;
    c.isConnected = true;
    c._conn.add(true);
    for (final l in _listeners.where((l) => l.client == c)) {
      final v = read(l.path);
      if (!_deepEq(v, l.last)) {
        l.last = v;
        l.ctrl.add(v);
      }
    }
  }
}

class _Listener {
  _Listener(this.client, this.path, this.ctrl, this.last);
  final MemoryDb client;
  final String path;
  final StreamController<Object?> ctrl;
  Object? last;
}

class MemoryDb implements Db {
  MemoryDb._(this.server, this.uid);
  final MemoryDbServer server;
  @override
  final String uid;
  bool isConnected = true;
  final Map<String, Map<String, Object?>> _onDisconnect = {};
  final StreamController<bool> _conn = StreamController<bool>.broadcast();

  void _check() {
    if (!isConnected) throw StateError('offline');
  }

  @override
  Stream<Object?> watch(String path) {
    late _Listener l;
    final ctrl = StreamController<Object?>(
      onCancel: () => server._listeners.remove(l),
    );
    l = _Listener(this, path, ctrl, server.read(path));
    server._listeners.add(l);
    final first = l.last;
    scheduleMicrotask(() => ctrl.add(first));
    return ctrl.stream;
  }

  @override
  Future<Object?> get(String path) async {
    _check();
    return server.read(path);
  }

  @override
  Future<void> set(String path, Object? value) async {
    _check();
    server.applyUpdate({path: value});
  }

  @override
  Future<void> update(Map<String, Object?> values) async {
    _check();
    server.applyUpdate(values);
  }

  @override
  Future<bool> claim(
    String path,
    bool Function(Object? current) test,
    Object value,
  ) async {
    _check();
    if (!test(server.read(path))) return false;
    server.applyUpdate({path: value});
    return true;
  }

  @override
  Future<void> onDisconnectUpdate(
    String base,
    Map<String, Object?> values,
  ) async {
    _onDisconnect[base] = {...?_onDisconnect[base], ...values};
  }

  @override
  Future<void> cancelOnDisconnect(String base) async {
    _onDisconnect.remove(base);
  }

  @override
  Stream<bool> get connected async* {
    yield isConnected;
    yield* _conn.stream;
  }
}
