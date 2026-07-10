import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ai_coach/services/ai_service.dart';
import '../../habits/models/habit_model.dart';
import '../../habits/repositories/habit_repository.dart';
import '../../../core/database/database_helper.dart';

/// Loads all stats data in a single batched pass (one habits query, one
/// completions query) and computes every derived metric — daily/weekly
/// completion rates, streaks, chart buckets, AI insight inputs — in memory.
/// Switching the chart time range never re-hits the database.
class StatsController extends GetxController {
  final HabitRepository _repository = HabitRepository();

  static const List<String> weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const List<String> _fullWeekdayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  static const List<String> monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  final isLoading = true.obs;
  final weekCompletion = 0.0.obs;
  final bestStreak = 0.obs;
  final totalWins = 0.obs;
  final chartData = <double>[].obs;
  final chartLabels = <String>[].obs;
  final selectedTimeRange = 'Week'.obs;
  final aiInsight = ''.obs;

  List<HabitModel> _habits = [];
  final Map<DateTime, Set<String>> _completionsByDay = {};

  @override
  void onInit() {
    super.onInit();
    loadStats();
  }

  Future<void> loadStats() async {
    isLoading.value = true;

    final habitsResult = await _repository.getAllHabits();
    _habits = habitsResult.isSuccess ? habitsResult.data! : [];

    final completions = await _repository.getAllCompletions();
    _completionsByDay.clear();
    for (final c in completions) {
      final day = _dateOnly(c.completedAt);
      _completionsByDay.putIfAbsent(day, () => {}).add(c.habitId);
    }
    totalWins.value = completions.length;

    _recomputeOverallStats();
    _recomputeChart(selectedTimeRange.value);
    await _loadAiInsight();

    isLoading.value = false;
  }

  void setTimeRange(String range) {
    if (selectedTimeRange.value == range) return;
    selectedTimeRange.value = range;
    _recomputeChart(range);
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  int _activeHabitCountOn(DateTime day) {
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);
    return _habits.where((h) => h.isActive && !h.createdAt.isAfter(endOfDay)).length;
  }

  double _completionRateForDate(DateTime date) {
    final activeCount = _activeHabitCountOn(date);
    if (activeCount == 0) return 0.0;
    final completed = _completionsByDay[_dateOnly(date)] ?? const {};
    return completed.length / activeCount;
  }

  double _averageCompletionRateForRange(DateTime start, DateTime end) {
    final dayCount = end.difference(start).inDays + 1;
    if (dayCount <= 0) return 0.0;
    double sum = 0;
    for (int i = 0; i < dayCount; i++) {
      sum += _completionRateForDate(start.add(Duration(days: i)));
    }
    return sum / dayCount;
  }

  void _recomputeOverallStats() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekRates = List.generate(7, (i) => _completionRateForDate(monday.add(Duration(days: i))));
    weekCompletion.value = weekRates.reduce((a, b) => a + b) / weekRates.length;
    bestStreak.value = _computeBestStreak();
  }

  int _computeBestStreak() {
    if (_habits.isEmpty) return 0;
    final today = _dateOnly(DateTime.now());
    int best = 0;
    for (final habit in _habits) {
      var checkDate = today;
      if (!(_completionsByDay[checkDate]?.contains(habit.id) ?? false)) {
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
      int streak = 0;
      while (_completionsByDay[checkDate]?.contains(habit.id) ?? false) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
      if (streak > best) best = streak;
    }
    return best;
  }

  void _recomputeChart(String range) {
    final now = DateTime.now();

    if (range == 'Month') {
      final data = <double>[];
      for (int i = 3; i >= 0; i--) {
        final bucketEnd = now.subtract(Duration(days: i * 7));
        final bucketStart = bucketEnd.subtract(const Duration(days: 6));
        data.add(_averageCompletionRateForRange(bucketStart, bucketEnd));
      }
      chartData.value = data;
      chartLabels.value = const ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4'];
      return;
    }

    if (range == '3 Months' || range == 'Year') {
      final monthCount = range == 'Year' ? 12 : 3;
      final data = <double>[];
      final labels = <String>[];
      for (int i = monthCount - 1; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final monthStart = DateTime(monthDate.year, monthDate.month, 1);
        final monthEnd = DateTime(monthDate.year, monthDate.month + 1, 0);
        data.add(_averageCompletionRateForRange(monthStart, monthEnd));
        labels.add(monthLabels[monthDate.month - 1]);
      }
      chartData.value = data;
      chartLabels.value = labels;
      return;
    }

    // Week (default)
    final monday = now.subtract(Duration(days: now.weekday - 1));
    chartData.value = List.generate(7, (i) => _completionRateForDate(monday.add(Duration(days: i))));
    chartLabels.value = weekdayLabels;
  }

  String? _bestDayOfWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final rates = List.generate(7, (i) => _completionRateForDate(monday.add(Duration(days: i))));
    double best = 0;
    int bestIndex = -1;
    for (int i = 0; i < rates.length; i++) {
      if (rates[i] > best) {
        best = rates[i];
        bestIndex = i;
      }
    }
    return bestIndex == -1 ? null : _fullWeekdayNames[bestIndex];
  }

  double _weekOverWeekImprovement() {
    final now = DateTime.now();
    final thisMonday = now.subtract(Duration(days: now.weekday - 1));
    final lastMonday = thisMonday.subtract(const Duration(days: 7));
    final thisWeek = _averageCompletionRateForRange(thisMonday, thisMonday.add(const Duration(days: 6)));
    final lastWeek = _averageCompletionRateForRange(lastMonday, lastMonday.add(const Duration(days: 6)));
    return thisWeek - lastWeek;
  }

  Future<void> _loadAiInsight() async {
    final now = DateTime.now();
    final avgMood = await DatabaseHelper.instance
        .getAverageMoodSince(now.subtract(const Duration(days: 7)));
    String? moodNote;
    if (avgMood != null) {
      if (avgMood >= 4) {
        moodNote = 'Your mood has been bright this week — a great time to lean into momentum.';
      } else if (avgMood <= 2.5) {
        moodNote = 'Mood has been low lately. Be extra gentle with yourself — tiny wins still count double.';
      }
    }

    final stats = {
      'completion_rate': weekCompletion.value,
      'best_day': _bestDayOfWeek() ?? 'unknown',
      'streak': bestStreak.value,
      'improvement': _weekOverWeekImprovement(),
      if (moodNote != null) 'mood_note': moodNote,
    };

    // Template insight first — instant, always available.
    final coach = AiCoachService();
    aiInsight.value = coach.getWeeklyInsight(stats);

    // Then upgrade to a model-written one when live AI is available. Cached
    // per day + per stats snapshot so this costs at most one call a day, and
    // failures silently keep the template.
    try {
      final prefs = await SharedPreferences.getInstance();
      final offline = prefs.getBool('offline_mode') ?? false;
      if (offline || !coach.isLiveAi) return;
      final sig = '${_dateOnly(now)}|${(weekCompletion.value * 100).round()}|'
          '${bestStreak.value}|${totalWins.value}';
      if (prefs.getString('weekly_insight_sig') == sig) {
        final cached = prefs.getString('weekly_insight_text');
        if (cached != null && cached.isNotEmpty) {
          aiInsight.value = cached;
          return;
        }
      }
      final text = await coach.generateWeeklyInsight(stats);
      aiInsight.value = text;
      await prefs.setString('weekly_insight_sig', sig);
      await prefs.setString('weekly_insight_text', text);
    } catch (_) {
      // Keep the template insight.
    }
  }

  Future<void> refreshInsight() async {
    await _loadAiInsight();
  }
}
