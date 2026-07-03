// File generated manually from google-services.json
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBK0krzxEE8cGhnXQvh0jgCXt6uKMMZSFs',
    appId: '1:345123252542:android:2f3575687acdd90a31646f',
    messagingSenderId: '345123252542',
    projectId: 'gen-lang-client-0020138286',
    storageBucket: 'gen-lang-client-0020138286.firebasestorage.app',
  );
}
