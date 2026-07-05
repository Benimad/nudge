import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nudge/core/database/database_helper.dart';
import 'package:nudge/features/habits/models/completion_model.dart';
import 'package:nudge/features/habits/models/habit_model.dart';
import 'package:nudge/features/habits/repositories/habit_repository.dart';

/// Unit tests for the streak/completion math — the emotional core of the
/// product. Runs the real repository against a real SQLite database via
/// sqflite_common_ffi (no mocks), so what's asserted here is what ships.
void main() {
  late HabitRepository repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    repo = HabitRepository();
    // DatabaseHelper is a process-wide singleton — wipe between tests.
    await DatabaseHelper.instance.deleteAllData();
  });

  HabitModel habit({String name = 'Take medication', int order = 0}) => HabitModel(
        name: name,
        timeOfDay: 'morning',
        reminderStyle: 'soft_nudge',
        color: '0xFF7862E8',
        emoji: '💊',
        habitOrder: order,
      );

  DateTime daysAgo(int n, {int hour = 10}) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour).subtract(Duration(days: n));
  }

  Future<void> complete(String habitId, DateTime when) async {
    final result =
        await repo.completeHabit(CompletionModel(habitId: habitId, completedAt: when));
    expect(result.isSuccess, isTrue);
  }

  group('streak calculation', () {
    test('no completions → streak 0', () async {
      final h = habit();
      await repo.createHabit(h);
      expect(await repo.getStreakForHabit(h.id), 0);
    });

    test('completed today only → streak 1', () async {
      final h = habit();
      await repo.createHabit(h);
      await complete(h.id, daysAgo(0));
      expect(await repo.getStreakForHabit(h.id), 1);
    });

    test('three consecutive days ending today → streak 3', () async {
      final h = habit();
      await repo.createHabit(h);
      for (final n in [0, 1, 2]) {
        await complete(h.id, daysAgo(n));
      }
      expect(await repo.getStreakForHabit(h.id), 3);
    });

    test("today not yet done, yesterday + day before done → streak 2 (grace period)", () async {
      final h = habit();
      await repo.createHabit(h);
      await complete(h.id, daysAgo(1));
      await complete(h.id, daysAgo(2));
      expect(await repo.getStreakForHabit(h.id), 2);
    });

    test('a missed day breaks the streak', () async {
      final h = habit();
      await repo.createHabit(h);
      await complete(h.id, daysAgo(0));
      // gap at daysAgo(1)
      await complete(h.id, daysAgo(2));
      await complete(h.id, daysAgo(3));
      expect(await repo.getStreakForHabit(h.id), 1);
    });

    test('multiple completions on the same day count once', () async {
      final h = habit();
      await repo.createHabit(h);
      await complete(h.id, daysAgo(0, hour: 8));
      await complete(h.id, daysAgo(0, hour: 20));
      expect(await repo.getStreakForHabit(h.id), 1);
    });

    test('streaks are per habit', () async {
      final a = habit(name: 'A');
      final b = habit(name: 'B', order: 1);
      await repo.createHabit(a);
      await repo.createHabit(b);
      await complete(a.id, daysAgo(0));
      await complete(a.id, daysAgo(1));
      await complete(b.id, daysAgo(0));
      expect(await repo.getStreakForHabit(a.id), 2);
      expect(await repo.getStreakForHabit(b.id), 1);
    });
  });

  group('completion rate', () {
    test('no habits → 0.0', () async {
      expect(await repo.getCompletionRateForDate(DateTime.now()), 0.0);
    });

    test('1 of 2 active habits completed → 0.5', () async {
      final a = habit(name: 'A');
      final b = habit(name: 'B', order: 1);
      await repo.createHabit(a);
      await repo.createHabit(b);
      await complete(a.id, daysAgo(0));
      expect(await repo.getCompletionRateForDate(DateTime.now()), 0.5);
    });

    test('duplicate completions of one habit do not inflate the rate', () async {
      final a = habit(name: 'A');
      final b = habit(name: 'B', order: 1);
      await repo.createHabit(a);
      await repo.createHabit(b);
      await complete(a.id, daysAgo(0, hour: 8));
      await complete(a.id, daysAgo(0, hour: 20));
      expect(await repo.getCompletionRateForDate(DateTime.now()), 0.5);
    });

    test('average over a range with one perfect and one empty day', () async {
      final h = habit();
      await repo.createHabit(h);
      await complete(h.id, daysAgo(1));
      final avg = await repo.getAverageCompletionRateForRange(
        DateTime.now().subtract(const Duration(days: 1)),
        DateTime.now(),
      );
      expect(avg, closeTo(0.5, 0.001));
    });
  });

  group('undo and totals', () {
    test('deleting a completion resets the streak', () async {
      final h = habit();
      await repo.createHabit(h);
      await complete(h.id, daysAgo(0));
      expect(await repo.getStreakForHabit(h.id), 1);

      final result = await repo.deleteCompletion(h.id, DateTime.now());
      expect(result.isSuccess, isTrue);
      expect(await repo.getStreakForHabit(h.id), 0);
    });

    test('total wins counts every completion ever', () async {
      final h = habit();
      await repo.createHabit(h);
      await complete(h.id, daysAgo(0));
      await complete(h.id, daysAgo(1));
      await complete(h.id, daysAgo(5));
      expect(await repo.getTotalWins(), 3);
    });
  });
}
