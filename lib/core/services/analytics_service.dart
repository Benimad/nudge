import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around PostHog. Configured entirely from Dart via
/// `--dart-define=POSTHOG_API_KEY=phc_...` (and optionally POSTHOG_HOST);
/// native auto-init is disabled in AndroidManifest/Info.plist. When no key is
/// provided (local dev builds), every call is a silent no-op so analytics can
/// never break the app.
///
/// Privacy: analytics are suppressed entirely when the user is in Offline mode
/// or has opted out, and event payloads never include habit names, note text,
/// or AI conversation content — only coarse, non-identifying counters.
class AnalyticsService {
  static const String _apiKey = String.fromEnvironment('POSTHOG_API_KEY', defaultValue: '');
  static const String _host =
      String.fromEnvironment('POSTHOG_HOST', defaultValue: 'https://us.i.posthog.com');

  static bool _enabled = false;
  static bool _suppressed = false; // offline mode or explicit opt-out

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
    await refreshPrivacyPrefs();
  }

  /// Re-reads the offline-mode / opt-out prefs. Call after the user toggles
  /// either, so tracking stops (or resumes) immediately without a restart.
  static Future<void> refreshPrivacyPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offline = prefs.getBool('offline_mode') ?? false;
      final optedOut = prefs.getBool('analytics_opt_out') ?? false;
      _suppressed = offline || optedOut;
    } catch (_) {
      _suppressed = false;
    }
  }

  static bool get _live => _enabled && !_suppressed;

  static Future<void> capture({
    required String eventName,
    Map<String, Object>? properties,
  }) async {
    if (!_live) return;
    try {
      await Posthog().capture(eventName: eventName, properties: properties);
    } catch (e) {
      debugPrint('Analytics capture failed: $e');
    }
  }

  static Future<void> identify(String userId, Map<String, Object>? userProperties) async {
    if (!_live) return;
    try {
      await Posthog().identify(userId: userId, userProperties: userProperties);
    } catch (e) {
      debugPrint('Analytics identify failed: $e');
    }
  }

  static Future<void> screen(String screenName) async {
    if (!_live) return;
    try {
      await Posthog().screen(screenName: screenName);
    } catch (e) {
      debugPrint('Analytics screen failed: $e');
    }
  }

  // ── Domain events (payloads are deliberately content-free) ───────────────────

  /// Note: intentionally does NOT send the habit name — habit titles like
  /// "Take medication" are health-adjacent and never leave the device.
  static Future<void> logHabitCompleted({required int pointsAwarded}) async {
    await capture(
      eventName: 'habit_completed',
      properties: {'points_awarded': pointsAwarded},
    );
  }

  static Future<void> logAiMessageSent() async {
    await capture(eventName: 'ai_message_sent');
  }

  static Future<void> logFocusSessionCompleted(int minutes) async {
    await capture(eventName: 'focus_session_completed', properties: {'minutes': minutes});
  }

  static Future<void> logEmergencyModeActivated() async {
    await capture(eventName: 'emergency_mode_activated');
  }
}
