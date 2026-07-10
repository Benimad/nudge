import '../../habits/models/completion_model.dart';
import '../../habits/models/habit_model.dart';

/// Behavioral signals derived from real habit history, computed in one pure
/// pass so both the AI coach context and tests can use them. This is what
/// makes the coach's personalization deepen with use: the more history the
/// user builds, the more specific these get.
class CoachInsights {
  /// Weekday name with the highest completion rate over the last 28 days,
  /// or null when there isn't enough signal yet (no completions at all).
  final String? bestDayOfWeek;

  /// This week's average completion rate minus last week's (-1.0 … 1.0).
  final double weekOverWeekDelta;

  /// Names of active habits with zero completions in the last 3 days
  /// (only habits old enough to have been missable), max 3.
  final List<String> recentlyMissedHabits;

  const CoachInsights({
    required this.bestDayOfWeek,
    required this.weekOverWeekDelta,
    required this.recentlyMissedHabits,
  });

  static const _weekdayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  static CoachInsights compute({
    required List<HabitModel> habits,
    required List<CompletionModel> completions,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());

    final byDay = <DateTime, Set<String>>{};
    for (final c in completions) {
      byDay.putIfAbsent(_dateOnly(c.completedAt), () => {}).add(c.habitId);
    }

    int activeCountOn(DateTime day) {
      final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);
      return habits.where((h) => h.isActive && !h.createdAt.isAfter(endOfDay)).length;
    }

    double rateOn(DateTime day) {
      final active = activeCountOn(day);
      if (active == 0) return 0.0;
      return (byDay[day]?.length ?? 0) / active;
    }

    // Best weekday over the last 28 days.
    final sums = List<double>.filled(7, 0);
    final counts = List<int>.filled(7, 0);
    var anyCompletion = false;
    for (int i = 0; i < 28; i++) {
      final day = today.subtract(Duration(days: i));
      final rate = rateOn(day);
      if ((byDay[day]?.isNotEmpty ?? false)) anyCompletion = true;
      sums[day.weekday - 1] += rate;
      counts[day.weekday - 1]++;
    }
    String? bestDay;
    double bestRate = 0;
    for (int w = 0; w < 7; w++) {
      final avg = counts[w] == 0 ? 0.0 : sums[w] / counts[w];
      if (avg > bestRate) {
        bestRate = avg;
        bestDay = _weekdayNames[w];
      }
    }
    if (!anyCompletion) bestDay = null;

    // Week-over-week: last 7 days (ending today) vs the 7 before that.
    double avgRange(DateTime start, int days) {
      double sum = 0;
      for (int i = 0; i < days; i++) {
        sum += rateOn(start.add(Duration(days: i)));
      }
      return sum / days;
    }

    final thisWeek = avgRange(today.subtract(const Duration(days: 6)), 7);
    final lastWeek = avgRange(today.subtract(const Duration(days: 13)), 7);

    // Missed lately: active, old enough, and untouched for the last 3 days.
    final missed = <String>[];
    final missableSince = today.subtract(const Duration(days: 3));
    final sorted = [...habits]..sort((a, b) => a.habitOrder.compareTo(b.habitOrder));
    for (final h in sorted) {
      if (!h.isActive || h.createdAt.isAfter(missableSince)) continue;
      final touched = List.generate(3, (i) => today.subtract(Duration(days: i)))
          .any((d) => byDay[d]?.contains(h.id) ?? false);
      if (!touched) missed.add(h.name);
      if (missed.length == 3) break;
    }

    return CoachInsights(
      bestDayOfWeek: bestDay,
      weekOverWeekDelta: thisWeek - lastWeek,
      recentlyMissedHabits: missed,
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
