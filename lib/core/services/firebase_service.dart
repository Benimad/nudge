import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

class FirebaseService {
  static bool _initialized = false;

  static Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      try {
        Firebase.app();
        _initialized = true;
        return true;
      } catch (_) {}

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _initialized = true;
      debugPrint('✅ Firebase initialized');
      return true;
    } catch (e) {
      debugPrint('⚠️ Firebase not configured yet — running without it. $e');
      return false;
    }
  }

  static bool get isInitialized => _initialized;
}
