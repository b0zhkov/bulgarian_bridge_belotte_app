import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../firebase_options.dart';
import 'db.dart';

/// [Db] backed by Firebase Realtime Database with anonymous auth.
class FirebaseDb implements Db {
  FirebaseDb._(this._db, this.uid);
  final FirebaseDatabase _db;
  @override
  final String uid;

  static FirebaseDb? _instance;

  /// Initialises Firebase (once), signs in anonymously and returns the db.
  static Future<FirebaseDb> connect() async {
    final existing = _instance;
    if (existing != null) return existing;
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser ?? (await auth.signInAnonymously()).user!;
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
    );
    return _instance = FirebaseDb._(db, user.uid);
  }

  static Object? _out(Object? v) {
    if (v is ServerTimestamp) return ServerValue.timestamp;
    if (v is Increment) return ServerValue.increment(v.delta);
    if (v is Map) {
      return {for (final e in v.entries) e.key.toString(): _out(e.value)};
    }
    return v;
  }

  static Object? _in(Object? v) {
    if (v is Map) {
      return {for (final e in v.entries) e.key.toString(): _in(e.value)};
    }
    if (v is List) return [for (final x in v) _in(x)];
    return v;
  }

  @override
  Stream<Object?> watch(String path) =>
      _db.ref(path).onValue.map((e) => _in(e.snapshot.value));

  @override
  Future<Object?> get(String path) async =>
      _in((await _db.ref(path).get()).value);

  @override
  Future<void> set(String path, Object? value) =>
      _db.ref(path).set(_out(value));

  @override
  Future<void> update(Map<String, Object?> values) =>
      _db.ref().update({for (final e in values.entries) e.key: _out(e.value)});

  @override
  Future<bool> claim(
    String path,
    bool Function(Object? current) test,
    Object value,
  ) async {
    final r = await _db.ref(path).runTransaction((cur) {
      if (!test(_in(cur))) return Transaction.abort();
      return Transaction.success(_out(value));
    }, applyLocally: false);
    return r.committed;
  }

  @override
  Future<void> onDisconnectUpdate(String base, Map<String, Object?> values) =>
      _db.ref(base).onDisconnect().update({
        for (final e in values.entries) e.key: _out(e.value),
      });

  @override
  Future<void> cancelOnDisconnect(String base) =>
      _db.ref(base).onDisconnect().cancel();

  @override
  Stream<bool> get connected =>
      _db.ref('.info/connected').onValue.map((e) => e.snapshot.value == true);
}
