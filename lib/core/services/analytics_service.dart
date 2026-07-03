import 'package:posthog_flutter/posthog_flutter.dart';

class AnalyticsService {
  static Future<void> capture({
    required String eventName,
    Map<String, Object>? properties,
  }) async {
    await Posthog().capture(
      eventName: eventName,
      properties: properties,
    );
  }

  static Future<void> identify(String userId, Map<String, Object>? userProperties) async {
    await Posthog().identify(
      userId: userId,
      userProperties: userProperties,
    );
  }

  static Future<void> screen(String screenName) async {
    await Posthog().screen(screenName: screenName);
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