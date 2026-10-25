// Firebase configuration for project `bulgarian-bridge-belotte-app`, in the
// format produced by `flutterfire configure` (written by hand from the
// project's registered app configs). These values identify the project and
// are not secrets; access is controlled by database.rules.json.
// ignore_for_file: lines_longer_than_80_chars
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for $defaultTargetPlatform.',
        );
    }
  }

  static const String _db =
      'https://bulgarian-bridge-belotte-app-default-rtdb.europe-west1.firebasedatabase.app';

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAy6U4bYQCqYESyDvCBhC0KLF34LW2_Qa4',
    appId: '1:308320746353:web:6733fbe3f620e71f6f54d0',
    messagingSenderId: '308320746353',
    projectId: 'bulgarian-bridge-belotte-app',
    authDomain: 'bulgarian-bridge-belotte-app.firebaseapp.com',
    databaseURL: _db,
    storageBucket: 'bulgarian-bridge-belotte-app.firebasestorage.app',
    measurementId: 'G-L2WZYQWQ8T',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA8NPeKjlu6tcINcDkFrgBmDwwZ06yuqUc',
    appId: '1:308320746353:android:a40af7bc2d253f036f54d0',
    messagingSenderId: '308320746353',
    projectId: 'bulgarian-bridge-belotte-app',
    databaseURL: _db,
    storageBucket: 'bulgarian-bridge-belotte-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDZ2fZzwawoLigj3H4Z0dF_fYey0VycNN0',
    appId: '1:308320746353:ios:a03918075b8ba6296f54d0',
    messagingSenderId: '308320746353',
    projectId: 'bulgarian-bridge-belotte-app',
    databaseURL: _db,
    storageBucket: 'bulgarian-bridge-belotte-app.firebasestorage.app',
    iosBundleId: 'bg.belot.bulgarianBridgeBelotteApp',
  );
}
