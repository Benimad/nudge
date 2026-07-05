import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Thin wrapper around PostHog. Configured entirely from Dart via
/// `--dart-define=POSTHOG_API_KEY=phc_...` (and optionally POSTHOG_HOST);
/// native auto-init is disabled in AndroidManifest/Info.plist. When no key is
/// provided (local dev builds), every call is a silent no-op so analytics can
/// never break the app.
class AnalyticsService {
  static const String _apiKey = String.fromEnvironment('POSTHOG_API_KEY', defaultValue: '');
  static const String _host =
      String.fromEnvironment('POSTHOG_HOST', defaultValue: 'https://us.i.posthog.com');

  static bool _enabled = false;

  static Future<void> init() async {
    if (_apiKey.isEmpty) {
      debugPrint('ℹ️ Analytics disabled (no POSTHOG_API_KEY provided)');
      return;
    }
    final config = PostHogConfig(_apiKey)
      ..host = _host
      ..captureApplicationLifecycleEvents = true
      ..debug = kDebugMode;
    await Posthog().setup(config);
    _enabled = true;
  }

  static Future<void> capture({
    required String eventName,
    Map<String, Object>? properties,
  }) async {
    if (!_enabled) return;
    try {
      await Posthog().capture(eventName: eventName, properties: properties);
    } catch (e) {
      debugPrint('Analytics capture failed: $e');
    }
  }

  static Future<void> identify(String userId, Map<String, Object>? userProperties) async {
    if (!_enabled) return;
    try {
      await Posthog().identify(userId: userId, userProperties: userProperties);
    } catch (e) {
      debugPrint('Analytics identify failed: $e');
    }
  }

  static Future<void> screen(String screenName) async {
    if (!_enabled) return;
    try {
      await Posthog().screen(screenName: screenName);
    } catch (e) {
      debugPrint('Analytics screen failed: $e');
    }
  }

  static Future<void> logHabitCompleted(String title, int points) async {
    await capture(
      eventName: 'habit_completed',
      properties: {
        'habit_title': title,
        'points_awarded': points,
      },
    );
  }

  static Future<void> logEmergencyModeActivated() async {
    await capture(eventName: 'emergency_mode_activated');
  }
}
