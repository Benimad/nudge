import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../habits/controllers/home_controller.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/services/analytics_service.dart';
import '../services/presence_service.dart';

class BodyDoublingController extends GetxController with WidgetsBindingObserver {
  static const int _sessionEndNotifId = 9100;

  var isSessionActive = false.obs;
  var isPaused = false.obs;
  var taskName = ''.obs;
  var totalSeconds = 1500.obs;
  var remainingSeconds = 1500.obs;

  /// Wall-clock end time. The countdown is derived from this rather than a pure
  /// tick counter, so a session survives the app being backgrounded or dozed —
  /// on resume we recompute the true remaining time.
  DateTime? _endTime;

  /// Real people in focus mode right now (Firestore presence, self included).
  /// Starts at 1 — you — and only moves when a live count actually arrives,
  /// so the number is never invented.
  var communityCount = 1.obs;

  Timer? _timer;
  final PresenceService _presence = PresenceService();

  var sessionsCompletedToday = 0.obs;
  var totalFocusMinutesWeek = 0.obs;

  var currentEncouragement = ''.obs;
  var showEncouragement = false.obs;
  final _tipShown = <String>{};

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadFocusStats();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the background: snap the countdown to reality.
    if (state == AppLifecycleState.resumed &&
        isSessionActive.value &&
        !isPaused.value &&
        _endTime != null) {
      final left = _endTime!.difference(DateTime.now()).inSeconds;
      if (left <= 0) {
        _completeSession();
      } else {
        remainingSeconds.value = left;
      }
    }
  }

  Future<void> _loadFocusStats() async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    totalFocusMinutesWeek.value =
        await DatabaseHelper.instance.getTotalFocusMinutesSince(weekStart);
    sessionsCompletedToday.value =
        await DatabaseHelper.instance.getSessionsCountForDate(now);
  }

  @override
  void onClose() {
    _timer?.cancel();
    _presence.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  void startSession(String task, int minutes) {
    _tipShown.clear();
    taskName.value = task;
    totalSeconds.value = minutes * 60;
    remainingSeconds.value = totalSeconds.value;
    isSessionActive.value = true;
    communityCount.value = 1;
    _endTime = DateTime.now().add(Duration(seconds: totalSeconds.value));
    _presence.start(onCount: (count) => communityCount.value = count);
    HapticFeedback.mediumImpact();

    // Fire even if the app is closed when the timer ends.
    NotificationService().scheduleOneOff(
      id: _sessionEndNotifId,
      title: 'Focus session complete 🎉',
      body: 'You focused for $minutes minutes. Great work!',
      when: _endTime!,
    );

    _startTicker();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
        _checkEncouragement();
      } else {
        _completeSession();
      }
    });
  }

  void _checkEncouragement() {
    int elapsed = totalSeconds.value - remainingSeconds.value;

    if (!_tipShown.contains('start') && elapsed >= 300) {
      _showTip("You started. That's the hardest part.");
      _tipShown.add('start');
    } else if (!_tipShown.contains('half') && elapsed >= totalSeconds.value ~/ 2) {
      _showTip("You're halfway there. Keep going.");
      _tipShown.add('half');
    } else if (!_tipShown.contains('end') && remainingSeconds.value <= 300 && remainingSeconds.value > 0) {
      _showTip("Almost done. Finish strong.");
      _tipShown.add('end');
    }
  }

  void _showTip(String message) {
    currentEncouragement.value = message;
    showEncouragement.value = true;
    Future.delayed(const Duration(seconds: 4), () {
      showEncouragement.value = false;
    });
  }

  void _completeSession() async {
    _timer?.cancel();
    _endTime = null;
    _presence.stop();
    isSessionActive.value = false;
    isPaused.value = false;
    sessionsCompletedToday.value++;
    int minutes = totalSeconds.value ~/ 60;
    totalFocusMinutesWeek.value += minutes;

    await DatabaseHelper.instance.insertFocusSession(
      durationSeconds: totalSeconds.value,
      taskName: taskName.value,
    );
    unawaited(AnalyticsService.logFocusSessionCompleted(minutes));

    // Add dopamine points (50 bonus)
    Get.find<HomeController>().addPoints(50);

    HapticFeedback.heavyImpact();
    // Trigger celebration in UI via snackbar
    Get.snackbar(
      'Session complete!',
      'You focused for $minutes minutes. Great work!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF006C4E),
      colorText: Colors.white,
    );
  }

  void pauseResumeSession() {
    if (isPaused.value) {
      // Resume — re-anchor the wall clock to the remaining time.
      isPaused.value = false;
      _endTime = DateTime.now().add(Duration(seconds: remainingSeconds.value));
      NotificationService().scheduleOneOff(
        id: _sessionEndNotifId,
        title: 'Focus session complete 🎉',
        body: 'You focused for ${totalSeconds.value ~/ 60} minutes. Great work!',
        when: _endTime!,
      );
      _startTicker();
    } else if (isSessionActive.value) {
      // Pause — freeze the clock and cancel the pending end notification.
      _timer?.cancel();
      _endTime = null;
      NotificationService().cancelId(_sessionEndNotifId);
      isPaused.value = true;
    }
    update();
  }

  void endSession() {
    _timer?.cancel();
    _endTime = null;
    NotificationService().cancelId(_sessionEndNotifId);
    _presence.stop();
    isSessionActive.value = false;
    isPaused.value = false;
  }

  String get formattedTime {
    int minutes = remainingSeconds.value ~/ 60;
    int seconds = remainingSeconds.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  double get progress => remainingSeconds.value / totalSeconds.value;
}
