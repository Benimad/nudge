import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit_model.dart';
import '../models/completion_model.dart';
import '../repositories/habit_repository.dart';
import '../screens/celebration_screen.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/app_settings.dart';
import '../../../core/services/firestore_service.dart';
import '../../settings/services/subscription_service.dart';
import '../../../core/notifications/notification_service.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  final HabitRepository _repository = HabitRepository();

  final habits = <HabitModel>[].obs;
  final completions = <String, bool>{}.obs;
  final streaks = <String, int>{}.obs;
  final isLoading = true.obs;
  final todayProgress = 0.0.obs;
  final userName = 'Friend'.obs;
  final dopaminePoints = 0.obs;

  Timer? _paralysisTimer;
  final showParalysisBanner = false.obs;
  final _lastActivityTime = DateTime.now().obs;
  bool _isForeground = true;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    refreshData();
    _initParalysisDetection();
  }

  @override
  void onClose() {
    _paralysisTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    // Returning to the app counts as activity, so we never fire a "stuck?"
    // nudge the instant someone reopens it after time away.
    if (_isForeground) resetParalysisTimer();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    userName.value = prefs.getString('user_name') ?? 'Friend';
    dopaminePoints.value = prefs.getInt('dopamine_points') ?? 0;
  }

  /// Checked fresh (not cached) before every Firestore write so a toggle
  /// flipped in Settings takes effect immediately, no restart needed.
  Future<bool> _isOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('offline_mode') ?? false;
  }

  Future<void> refreshData() async {
    isLoading.value = true;
    await _loadUserData(); // pick up a name/points set during onboarding
    final habitsResult = await _repository.getAllHabits();
    final completionsResult = await _repository.getCompletionsForDate(DateTime.now());

    if (habitsResult.isSuccess) {
      habits.assignAll(habitsResult.data!);
    }

    if (completionsResult.isSuccess) {
      completions.clear();
      for (var c in completionsResult.data!) {
        completions[c.habitId] = true;
      }
    }

    _calculateProgress();
    await _loadStreaks();
    isLoading.value = false;
  }

  /// Loads streaks for all habits in parallel and caches them reactively,
  /// so list items never trigger per-rebuild database queries.
  Future<void> _loadStreaks() async {
    final entries = await Future.wait(
      habits.map((h) async => MapEntry(h.id, await _repository.getStreakForHabit(h.id))),
    );
    streaks.assignAll(Map.fromEntries(entries));
  }

  void _calculateProgress() {
    if (habits.isEmpty) {
      todayProgress.value = 0.0;
      return;
    }
    final activeHabits = habits.where((h) => h.isActive).toList();
    if (activeHabits.isEmpty) {
      todayProgress.value = 0.0;
      return;
    }
    final completedCount = activeHabits.where((h) => completions[h.id] == true).length;
    todayProgress.value = completedCount / activeHabits.length;
  }

  bool isCompleted(String habitId) {
    return completions[habitId] == true;
  }

  int getStreak(String habitId) {
    return streaks[habitId] ?? 0;
  }

  Future<void> addHabit(HabitModel habit) async {
    final activeHabits = habits.where((h) => h.isActive).length;
    if (activeHabits >= 5) {
      final isPro = await SubscriptionService().isPro();
      if (!isPro) {
        Get.toNamed('/paywall');
        return;
      }
    }
    final result = await _repository.createHabit(habit);
    if (result.isSuccess) {
      habits.add(habit);
      _calculateProgress();
      // Schedule reminder if applicable
      await _scheduleReminderIfNeeded(habit);
      if (!await _isOfflineMode()) {
        unawaited(FirestoreService().upsertHabit(habit));
      }
    } else {
      Get.snackbar('Error', 'Failed to create habit', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _scheduleReminderIfNeeded(HabitModel habit) async {
    if (habit.reminderStyle == 'none') return;
    final prefs = await SharedPreferences.getInstance();

    // Honor the user's own morning/evening reminder times (set in onboarding or
    // Settings) instead of a hardcoded map, so per-habit reminders line up with
    // the times they actually chose.
    final morning = _prefMinutes(prefs.getString('morning_reminder')) ?? 8 * 60;
    final evening = _prefMinutes(prefs.getString('evening_reminder')) ?? 20 * 60;
    final Map<String, int> timeMap = {
      'morning': morning,
      'afternoon': 14 * 60,
      'evening': evening,
      'night': 21 * 60,
      'anytime': morning,
    };
    final reminderTime = timeMap[habit.timeOfDay] ?? morning;

    try {
      await NotificationService().scheduleHabitReminders(
        habitId: habit.id,
        title: 'Nudge: ${habit.name}',
        body: 'Time for your ${habit.name} habit!',
        reminderTimes: [reminderTime],
        transitionWarningMinutes: 10,
        // "Vibrate only" routes through the silent channel (no sound).
        silent: habit.reminderStyle == 'vibrate',
      );
    } catch (e) {
      debugPrint('Failed to schedule reminder: $e');
    }
  }

  int? _prefMinutes(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  Future<void> updateHabit(HabitModel habit) async {
    final result = await _repository.updateHabit(habit);
    if (result.isSuccess) {
      final index = habits.indexWhere((h) => h.id == habit.id);
      if (index >= 0) {
        habits[index] = habit;
      }
      // Re-schedule with the (possibly changed) time-of-day / reminder style.
      await _scheduleReminderIfNeeded(habit);
      if (!await _isOfflineMode()) {
        unawaited(FirestoreService().upsertHabit(habit));
      }
    } else {
      Get.snackbar('Error', 'Failed to update habit', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> deleteHabit(String id) async {
    final result = await _repository.deleteHabit(id);
    if (result.isSuccess) {
      habits.removeWhere((h) => h.id == id);
      completions.remove(id);
      streaks.remove(id);
      _calculateProgress();
      await NotificationService().cancelHabitNotifications(id);
      if (!await _isOfflineMode()) {
        unawaited(FirestoreService().deleteHabit(id));
      }
    } else {
      Get.snackbar('Error', 'Failed to delete habit', snackPosition: SnackPosition.BOTTOM);
    }
  }

  final _lastToggle = <String, DateTime>{};

  Future<void> toggleHabit(HabitModel habit) async {
    resetParalysisTimer();

    // Debounce rapid repeat taps on the same habit (spec: 500ms).
    final now = DateTime.now();
    final last = _lastToggle[habit.id];
    if (last != null && now.difference(last).inMilliseconds < 500) return;
    _lastToggle[habit.id] = now;

    final currentlyCompleted = completions[habit.id] == true;
    // Capture whether the day was already complete BEFORE this toggle, so the
    // all-done bonus is granted exactly once per crossing and reversed on
    // uncheck — no more farming points by toggling the last habit.
    final wasDayComplete = todayProgress.value >= 1.0;

    if (currentlyCompleted) {
      // Uncheck path
      completions[habit.id] = false;
      _calculateProgress();
      final crossedBelow = wasDayComplete && todayProgress.value < 1.0;
      final delta = 10 + (crossedBelow ? 25 : 0);
      dopaminePoints.value -= delta;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('dopamine_points', dopaminePoints.value);

      final result = await _repository.deleteCompletion(habit.id, DateTime.now());
      if (!result.isSuccess) {
        // Revert optimistic update on failure
        completions[habit.id] = true;
        dopaminePoints.value += delta;
        _calculateProgress();
        Get.snackbar('Error', 'Failed to undo completion', snackPosition: SnackPosition.BOTTOM);
      } else {
        final newStreak = await _repository.getStreakForHabit(habit.id);
        streaks[habit.id] = newStreak;
        if (!await _isOfflineMode()) {
          unawaited(FirestoreService().deleteCompletion(habit.id, DateTime.now()));
          unawaited(FirestoreService().updateDopaminePoints(dopaminePoints.value));
        }
      }
      return;
    }

    // Check path
    completions[habit.id] = true;
    _calculateProgress();
    HapticFeedback.mediumImpact();

    final dayComplete = todayProgress.value >= 1.0;
    final justCompletedDay = dayComplete && !wasDayComplete;
    final earned = 10 + (justCompletedDay ? 25 : 0);
    dopaminePoints.value += earned;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dopamine_points', dopaminePoints.value);

    final completion = CompletionModel(habitId: habit.id);
    final result = await _repository.completeHabit(completion);

    if (!result.isSuccess) {
      // Revert optimistic update on failure.
      completions[habit.id] = false;
      dopaminePoints.value -= earned;
      _calculateProgress();
      Get.snackbar('Error', 'Failed to save completion', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Analytics — content-free (no habit name leaves the device).
    unawaited(AnalyticsService.logHabitCompleted(pointsAwarded: earned));

    // Update cached streak for this habit only (no full reload).
    final newStreak = await _repository.getStreakForHabit(habit.id);
    streaks[habit.id] = newStreak;
    if (!await _isOfflineMode()) {
      unawaited(FirestoreService().recordCompletion(habit.id, DateTime.now()));
      unawaited(FirestoreService().updateDopaminePoints(dopaminePoints.value));
    }

    // Full-screen celebration is reserved for genuinely meaningful moments so
    // it stays a reward, not a per-tap interruption. Everyday check-offs get
    // the inline check-circle animation instead.
    // Sensory-safe / reduce-motion users never get the full-screen takeover.
    if (!AppSettings.instance.reduceMotion.value &&
        _shouldCelebrate(newStreak: newStreak, dayComplete: dayComplete)) {
      Get.to(() => CelebrationScreen(streak: newStreak), fullscreenDialog: true);
    }
  }

  /// Meaningful moments: finishing the whole day, a first-ever completion, or a
  /// streak milestone (weekly for the first month, then every 25 days).
  bool _shouldCelebrate({required int newStreak, required bool dayComplete}) {
    if (dayComplete) return true;
    if (newStreak == 1) return true;
    const milestones = {3, 7, 14, 21, 30};
    if (milestones.contains(newStreak)) return true;
    return newStreak > 30 && newStreak % 25 == 0;
  }

  void addPoints(int points) {
    dopaminePoints.value += points;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('dopamine_points', dopaminePoints.value);
    });
    unawaited(_isOfflineMode().then((offline) {
      if (!offline) FirestoreService().updateDopaminePoints(dopaminePoints.value);
    }));
  }

  void _initParalysisDetection() {
    _paralysisTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // Only detect paralysis while the app is actually open and in use. A
      // false "you're stuck" ping while someone is happily working elsewhere is
      // exactly the shame the brand promises never to cause.
      if (!_isForeground) return;
      final now = DateTime.now();
      if (now.hour >= 8 && now.hour <= 22) {
        if (!showParalysisBanner.value &&
            now.difference(_lastActivityTime.value).inMinutes >= 35) {
          showParalysisBanner.value = true;
          NotificationService().showNotification(
            id: 9001,
            title: 'Feeling stuck?',
            body: "No pressure — want to turn one thing into a tiny step together?",
          );
        }
      }
    });
  }

  /// Marks the user as active, resetting the paralysis-mode inactivity clock.
  /// Called both from habit interactions and from a global tap/scroll
  /// listener (see main.dart) so navigating or scrolling anywhere in the app
  /// also counts as activity, not just checking off a habit.
  void resetParalysisTimer() {
    _lastActivityTime.value = DateTime.now();
    showParalysisBanner.value = false;
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
