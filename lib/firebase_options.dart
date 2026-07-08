import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web is not supported by this app.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS not configured. Run flutterfire configure or add GoogleService-Info.plist.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'macOS is not supported by this app.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'Windows is not supported by this app.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Linux is not supported by this app.',
        );
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Fuchsia is not supported by this app.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD7swUB6yivd9NijkFZhojSd8VQoz5uWjc',
    appId: '1:987575896775:android:05a1ecdd7f5c8c89eb0ce2',
    messagingSenderId: '987575896775',
    projectId: 'mi-app-mobile-8fd75',
    storageBucket: 'mi-app-mobile-8fd75.firebasestorage.app',
  );
}
