import 'package:flutter_test/flutter_test.dart';

import 'package:nudge/features/ai_coach/services/coach_insights.dart';
import 'package:nudge/features/habits/models/completion_model.dart';
import 'package:nudge/features/habits/models/habit_model.dart';

/// The behavioral signals fed into the AI coach's context. Pure math over
/// habit history — if these are wrong the coach personalizes on lies.
void main() {
  final now = DateTime(2026, 7, 10, 15); // a Friday

  HabitModel habit(String name, {int daysOld = 60, int order = 0}) => HabitModel(
        name: name,
        timeOfDay: 'morning',
        reminderStyle: 'soft_nudge',
        color: '0xFF7862E8',
        emoji: '✅',
        habitOrder: order,
        createdAt: now.subtract(Duration(days: daysOld)),
      );

  CompletionModel done(HabitModel h, int daysAgo) => CompletionModel(
        habitId: h.id,
        completedAt: DateTime(now.year, now.month, now.day - daysAgo, 10),
      );

  test('empty history → no best day, no trend, nothing missed for new habits', () {
    final h = habit('Meditate', daysOld: 1);
    final insights = CoachInsights.compute(habits: [h], completions: [], now: now);
    expect(insights.bestDayOfWeek, isNull);
    expect(insights.weekOverWeekDelta, 0.0);
    // Habit is only 1 day old — too new to count as "missed".
    expect(insights.recentlyMissedHabits, isEmpty);
  });

  test('best day reflects the weekday with the highest completion rate', () {
    final h = habit('Journal');
    // Complete on the last four Wednesdays (2026-07-08 is a Wednesday,
    // 2 days before the reference Friday).
    final completions = [
      for (int week = 0; week < 4; week++) done(h, 2 + week * 7),
    ];
    final insights =
        CoachInsights.compute(habits: [h], completions: completions, now: now);
    expect(insights.bestDayOfWeek, 'Wednesday');
  });

  test('week-over-week delta is positive when this week beats last week', () {
    final h = habit('Walk');
    // This week (days 0-6): 6 completions. Last week (days 7-13): 1.
    final completions = [
      for (int d = 0; d < 6; d++) done(h, d),
      done(h, 10),
    ];
    final insights =
        CoachInsights.compute(habits: [h], completions: completions, now: now);
    expect(insights.weekOverWeekDelta, greaterThan(0));
  });

  test('habits untouched for 3 days are flagged, capped at 3, in habit order', () {
    final kept = habit('Meds', order: 0);
    final missedHabits =
        List.generate(4, (i) => habit('Missed ${i + 1}', order: i + 1));
    // "Meds" done today; the other four never done.
    final insights = CoachInsights.compute(
      habits: [kept, ...missedHabits],
      completions: [done(kept, 0)],
      now: now,
    );
    expect(insights.recentlyMissedHabits, ['Missed 1', 'Missed 2', 'Missed 3']);
  });

  test('a habit completed yesterday is not "missed"', () {
    final h = habit('Stretch');
    final insights =
        CoachInsights.compute(habits: [h], completions: [done(h, 1)], now: now);
    expect(insights.recentlyMissedHabits, isEmpty);
  });

  test('inactive habits are never flagged as missed', () {
    final h = HabitModel(
      name: 'Paused habit',
      timeOfDay: 'morning',
      reminderStyle: 'soft_nudge',
      color: '0xFF7862E8',
      emoji: '⏸️',
      isActive: false,
      createdAt: now.subtract(const Duration(days: 60)),
    );
    final insights = CoachInsights.compute(habits: [h], completions: [], now: now);
    expect(insights.recentlyMissedHabits, isEmpty);
  });
}
