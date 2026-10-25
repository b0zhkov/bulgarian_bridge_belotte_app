/// Minimal realtime-database surface used by online play. The Firebase
/// implementation lives in `firebase_db.dart`; tests use `MemoryDb`.
library;

/// Placeholder resolved by the backend to its clock (ms since epoch).
class ServerTimestamp {
  const ServerTimestamp();
}

/// Placeholder resolved by the backend to `current + delta`.
class Increment {
  const Increment(this.delta);
  final int delta;
}

abstract class Db {
  /// The signed-in (anonymous) user id.
  String get uid;

  /// Emits the value at [path] now and on every change (null when absent).
  Stream<Object?> watch(String path);

  Future<Object?> get(String path);

  Future<void> set(String path, Object? value);

  /// Multi-path update relative to the root; null deletes.
  Future<void> update(Map<String, Object?> values);

  /// Atomically writes [value] at [path] if [test] accepts the current
  /// value. Returns whether it was written.
  Future<bool> claim(
    String path,
    bool Function(Object? current) test,
    Object value,
  );

  /// Registers a multi-path update (relative to [base]) the server applies
  /// when this client disconnects.
  Future<void> onDisconnectUpdate(String base, Map<String, Object?> values);
  Future<void> cancelOnDisconnect(String base);

  /// Connection state to the backend.
  Stream<bool> get connected;
}
