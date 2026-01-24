// Stub for shareable/clean branch. No real credentials.
// Run: dart run flutterfire_cli:flutterfire configure
// to generate a real firebase_options.dart from your Firebase project.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'your-api-key',
        appId: '1:000000000000:web:placeholder',
        messagingSenderId: '000000000000',
        projectId: 'your-project-id',
        storageBucket: 'your-project-id.firebasestorage.app',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'your-api-key',
          appId: '1:000000000000:android:placeholder',
          messagingSenderId: '000000000000',
          projectId: 'your-project-id',
          storageBucket: 'your-project-id.firebasestorage.app',
        );
      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: 'your-api-key',
          appId: '1:000000000000:ios:placeholder',
          messagingSenderId: '000000000000',
          projectId: 'your-project-id',
          storageBucket: 'your-project-id.firebasestorage.app',
          iosBundleId: 'com.example.app',
        );
      case TargetPlatform.macOS:
        return const FirebaseOptions(
          apiKey: 'your-api-key',
          appId: '1:000000000000:ios:placeholder',
          messagingSenderId: '000000000000',
          projectId: 'your-project-id',
          storageBucket: 'your-project-id.firebasestorage.app',
          iosBundleId: 'com.example.app',
        );
      default:
        return const FirebaseOptions(
          apiKey: 'your-api-key',
          appId: '1:000000000000:android:placeholder',
          messagingSenderId: '000000000000',
          projectId: 'your-project-id',
          storageBucket: 'your-project-id.firebasestorage.app',
        );
    }
  }
}
