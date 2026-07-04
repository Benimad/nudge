import 'dart:ui' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';

/// Handle FCM messages in the background (top-level function required by Firebase).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final notif = message.notification;
  if (notif == null) return;
  await NotificationService().showNotification(
    id: message.hashCode,
    title: notif.title ?? 'Nudge',
    body: notif.body ?? '',
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    tz.initializeTimeZones();

    // --- Local notifications ---
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('🔔 Notification tapped: ${details.payload}');
      },
    );

    // --- FCM ---
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (Android 13+)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 FCM permission: ${settings.authorizationStatus}');

    // Fetch token
    _fcmToken = await _fcm.getToken();
    debugPrint('🔔 FCM token: $_fcmToken');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      final notif = message.notification;
      if (notif != null) {
        showNotification(
          id: message.hashCode,
          title: notif.title ?? 'Nudge',
          body: notif.body ?? '',
        );
      }
    });

    // Subscribe to habit reminders topic
    await _fcm.subscribeToTopic('habit_reminders');
  }

  // ── Show immediate notification ─────────────────────────────────────────────

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details(),
      payload: payload,
    );
  }

  // ── Schedule daily habit reminder ───────────────────────────────────────────

  Future<void> scheduleHabitReminders({
    required String habitId,
    required String title,
    required String body,
    required List<int> reminderTimes, // minutes since midnight
    int? transitionWarningMinutes,
  }) async {
    await cancelHabitNotifications(habitId);

    final scheduleMode = await canScheduleExactAlarms()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < reminderTimes.length; i++) {
      final totalMinutes = reminderTimes[i];
      final hour = totalMinutes ~/ 60;
      final minute = totalMinutes % 60;

      var scheduledDate = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Main reminder
      await _localNotifications.zonedSchedule(
        id: _id(habitId, i, false),
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: _details(),
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // Pre-warning
      if (transitionWarningMinutes != null && transitionWarningMinutes > 0) {
        final warningDate =
            scheduledDate.subtract(Duration(minutes: transitionWarningMinutes));
        if (warningDate.isAfter(now)) {
          await _localNotifications.zonedSchedule(
            id: _id(habitId, i, true),
            title: '⏰ Starting soon: $title',
            body: 'In $transitionWarningMinutes minutes',
            scheduledDate: warningDate,
            notificationDetails: _details(),
            androidScheduleMode: scheduleMode,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        }
      }
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  int _id(String habitId, int index, bool isWarning) {
    final base = habitId.hashCode.abs() % 1000000;
    return base + (index % 100) * 10 + (isWarning ? 1 : 0);
  }

  NotificationDetails _details() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'habit_reminders',
        'Habit Reminders',
        channelDescription: 'Daily habit reminder nudges',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF574EB1),
        enableVibration: true,
        playSound: true,
      ),
    );
  }

  Future<void> cancelHabitNotifications(String habitId) async {
    for (int i = 0; i < 5; i++) {
      await _localNotifications.cancel(id: _id(habitId, i, false));
      await _localNotifications.cancel(id: _id(habitId, i, true));
    }
  }

  Future<void> cancelAll() async => _localNotifications.cancelAll();

  Future<bool> requestPermission() async {
    final result = await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return result ?? true;
  }

  /// Android 12+ revokes exact-alarm scheduling by default. Reminders still
  /// fire without it (see [scheduleHabitReminders]'s inexact fallback) but
  /// may drift by minutes under Doze. Non-Android platforms and pre-12
  /// devices report true here since the restriction doesn't apply to them.
  Future<bool> canScheduleExactAlarms() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return true;
    return await androidPlugin.canScheduleExactNotifications() ?? true;
  }

  /// Opens the system "Alarms & reminders" settings page so the user can
  /// grant exact-alarm scheduling. No-op on platforms/versions that don't
  /// need it.
  Future<void> requestExactAlarmPermission() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestExactAlarmsPermission();
  }
}