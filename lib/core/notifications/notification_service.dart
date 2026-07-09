import 'dart:ui' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static const _loudChannelId = 'habit_reminders';
  static const _silentChannelId = 'habit_reminders_silent';

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    // iOS/macOS: we request permission explicitly later, so don't prompt on init.
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('🔔 Notification tapped: ${details.payload}');
      },
    );

    await _createChannels();

    // --- FCM ---
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    final settings = await _fcm.requestPermission(alert: true, badge: true, sound: true);
    debugPrint('🔔 FCM permission: ${settings.authorizationStatus}');
    _fcmToken = await _fcm.getToken();

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

    // Respect Offline mode: don't subscribe to the broadcast topic (which would
    // let the server push to this device) when the user asked to stay local.
    await applyOfflinePreference();
  }

  /// Subscribes/unsubscribes the broadcast reminders topic based on Offline
  /// mode. Call again whenever the user toggles it.
  Future<void> applyOfflinePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offline = prefs.getBool('offline_mode') ?? false;
      if (offline) {
        await _fcm.unsubscribeFromTopic('habit_reminders');
      } else {
        await _fcm.subscribeToTopic('habit_reminders');
      }
    } catch (e) {
      debugPrint('FCM topic update failed (ignored): $e');
    }
  }

  Future<void> _createChannels() async {
    final android = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    await android.createNotificationChannel(const AndroidNotificationChannel(
      _loudChannelId,
      'Habit Reminders',
      description: 'Gentle daily habit reminder nudges',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      _silentChannelId,
      'Quiet Reminders (vibrate only)',
      description: 'Discreet vibrate-only nudges — no sound',
      importance: Importance.high,
      playSound: false,
      enableVibration: true,
    ));
  }

  // ── Show immediate notification ─────────────────────────────────────────────

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool silent = false,
  }) async {
    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details(silent: silent),
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
    bool silent = false,
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

      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _localNotifications.zonedSchedule(
        id: _id(habitId, i, false),
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: _details(silent: silent),
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      if (transitionWarningMinutes != null && transitionWarningMinutes > 0) {
        final warningDate = scheduledDate.subtract(Duration(minutes: transitionWarningMinutes));
        if (warningDate.isAfter(now)) {
          await _localNotifications.zonedSchedule(
            id: _id(habitId, i, true),
            title: '⏰ Starting soon: $title',
            body: 'In $transitionWarningMinutes minutes',
            scheduledDate: warningDate,
            notificationDetails: _details(silent: silent),
            androidScheduleMode: scheduleMode,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        }
      }
    }
  }

  /// One-shot notification at a specific wall-clock time (e.g. focus-session
  /// end). Fires even if the app is backgrounded or killed.
  Future<void> scheduleOneOff({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    final scheduled = tz.TZDateTime.from(when, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;
    final mode = await canScheduleExactAlarms()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    await _localNotifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: _details(),
      androidScheduleMode: mode,
    );
  }

  Future<void> cancelId(int id) async => _localNotifications.cancel(id: id);

  // ── Helpers ─────────────────────────────────────────────────────────────────

  int _id(String habitId, int index, bool isWarning) {
    final base = habitId.hashCode.abs() % 1000000;
    return base * 100 + (index % 50) * 2 + (isWarning ? 1 : 0);
  }

  NotificationDetails _details({bool silent = false}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        silent ? _silentChannelId : _loudChannelId,
        silent ? 'Quiet Reminders (vibrate only)' : 'Habit Reminders',
        channelDescription: 'Daily habit reminder nudges',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF7862E8),
        enableVibration: true,
        playSound: !silent,
      ),
      iOS: DarwinNotificationDetails(presentSound: !silent),
    );
  }

  Future<void> cancelHabitNotifications(String habitId) async {
    for (int i = 0; i < 50; i++) {
      await _localNotifications.cancel(id: _id(habitId, i, false));
      await _localNotifications.cancel(id: _id(habitId, i, true));
    }
  }

  Future<void> cancelAll() async => _localNotifications.cancelAll();

  Future<bool> requestPermission() async {
    final android = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? true;
    }
    final ios = _localNotifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? true;
    }
    return true;
  }

  /// Android 12+ revokes exact-alarm scheduling by default. Reminders still fire
  /// without it (inexact fallback) but may drift under Doze.
  Future<bool> canScheduleExactAlarms() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return true;
    return await androidPlugin.canScheduleExactNotifications() ?? true;
  }

  Future<void> requestExactAlarmPermission() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestExactAlarmsPermission();
  }
}
