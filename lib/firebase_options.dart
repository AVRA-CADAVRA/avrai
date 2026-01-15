// Firebase configuration for SPOTS app
// Values extracted from Android/iOS configs
// For web, some values may need to be obtained from Firebase Console
// Run `flutterfire configure` to regenerate with all platform-specific values

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // Web configuration - projectId is critical for Analytics
      // Note: For production, get web-specific apiKey and appId from Firebase Console
      return const FirebaseOptions(
        apiKey:
            'AIzaSyAyVtejIzdA94AwHSgyo2o18g-2wB5-qrs', // Android API key (use web-specific if available)
        appId: '1:790357806819:web:c660dc01837241d253ffd6', // Web app ID format
        messagingSenderId: '790357806819', // GCM Sender ID
        projectId:
            'spots-app-adea5', // Critical: fixes Analytics "Missing App configuration value: projectId"
        storageBucket: 'spots-app-adea5.firebasestorage.app',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'AIzaSyAyVtejIzdA94AwHSgyo2o18g-2wB5-qrs',
          appId: '1:790357806819:android:c660dc01837241d253ffd6',
          messagingSenderId: '790357806819',
          projectId: 'spots-app-adea5',
          storageBucket: 'spots-app-adea5.firebasestorage.app',
        );
      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: 'AIzaSyBruEqo9VBO82RYUtRzbS00_t97taO2T2Y',
          appId: '1:790357806819:ios:4e274b840993d24653ffd6',
          messagingSenderId: '790357806819',
          projectId: 'spots-app-adea5',
          storageBucket: 'spots-app-adea5.firebasestorage.app',
          iosBundleId: 'com.avrai.app',
        );
      case TargetPlatform.macOS:
        return const FirebaseOptions(
          apiKey: 'AIzaSyBruEqo9VBO82RYUtRzbS00_t97taO2T2Y',
          appId: '1:790357806819:ios:4e274b840993d24653ffd6',
          messagingSenderId: '790357806819',
          projectId: 'spots-app-adea5',
          storageBucket: 'spots-app-adea5.firebasestorage.app',
          iosBundleId: 'com.avrai.app',
        );
      default:
        return const FirebaseOptions(
          apiKey: 'AIzaSyAyVtejIzdA94AwHSgyo2o18g-2wB5-qrs',
          appId: '1:790357806819:android:c660dc01837241d253ffd6',
          messagingSenderId: '790357806819',
          projectId: 'spots-app-adea5',
          storageBucket: 'spots-app-adea5.firebasestorage.app',
        );
    }
  }
}
