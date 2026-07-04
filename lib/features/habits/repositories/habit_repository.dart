import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/habit_model.dart';
import '../models/completion_model.dart';

class Result<T> {
  final T? data;
  final String? error;
  bool get isSuccess => error == null;

  Result.success(this.data) : error = null;
  Result.failure(this.error) : data = null;
}

class HabitRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Result<String>> createHabit(HabitModel habit) async {
    try {
      final db = await _dbHelper.database;
      await db.insert('habits', habit.toMap());
      return Result.success(habit.id);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<bool>> updateHabit(HabitModel habit) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        'habits',
        habit.toMap(),
        where: 'id = ?',
        whereArgs: [habit.id],
      );
      return Result.success(true);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<bool>> deleteHabit(String id) async {
    try {
      final db = await _dbHelper.database;
      await db.delete('habits', where: 'id = ?', whereArgs: [id]);
      return Result.success(true);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<HabitModel>>> getAllHabits() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('habits', orderBy: 'habit_order ASC');
      return Result.success(maps.map((m) => HabitModel.fromMap(m)).toList());
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<CompletionModel>>> getCompletionsForDate(DateTime date) async {
    try {
      final db = await _dbHelper.database;
      final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
      
      final List<Map<String, dynamic>> maps = await db.query(
        'completions',
        where: 'completedAt BETWEEN ? AND ?',
        whereArgs: [startOfDay, endOfDay],
      );
      return Result.success(maps.map((m) => CompletionModel.fromMap(m)).toList());
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<bool>> completeHabit(CompletionModel completion) async {
    try {
      final db = await _dbHelper.database;
      await db.insert('completions', completion.toMap());
      return Result.success(true);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<int> getStreakForHabit(String habitId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'completions',
        where: 'habitId = ?',
        whereArgs: [habitId],
        orderBy: 'completedAt DESC',
      );

      if (maps.isEmpty) return 0;

      final List<DateTime> completionDates = maps
          .map((m) => DateTime.parse(m['completedAt']))
          .map((d) => DateTime(d.year, d.month, d.day))
          .toSet()
          .toList();

      int streak = 0;
      DateTime checkDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      if (!completionDates.contains(checkDate)) {
        checkDate = checkDate.subtract(const Duration(days: 1));
      }

      while (completionDates.contains(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }

      return streak;
    } catch (e) {
      return 0;
    }
  }

  Future<Result<bool>> deleteCompletion(String habitId, DateTime date) async {
    try {
      final db = await _dbHelper.database;
      final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
      await db.delete(
        'completions',
        where: 'habitId = ? AND completedAt BETWEEN ? AND ?',
        whereArgs: [habitId, startOfDay, endOfDay],
      );
      return Result.success(true);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<double> getCompletionRateForDate(DateTime date) async {
    final habitsResult = await getAllHabits();
    if (!habitsResult.isSuccess || habitsResult.data!.isEmpty) return 0.0;

    final activeHabits = habitsResult.data!.where((h) => h.isActive).toList();
    if (activeHabits.isEmpty) return 0.0;

    final completionsResult = await getCompletionsForDate(date);
    if (!completionsResult.isSuccess) return 0.0;

    // Deduplicate completions by habitId
    final uniqueHabitIds = completionsResult.data!
        .map((c) => c.habitId)
        .toSet();

    return uniqueHabitIds.length / activeHabits.length;
  }

  /// Average daily completion rate across an inclusive date range, used to
  /// bucket the stats chart into weeks/months for longer time ranges.
  Future<double> getAverageCompletionRateForRange(DateTime start, DateTime end) async {
    final dayCount = end.difference(start).inDays + 1;
    if (dayCount <= 0) return 0.0;
    final rates = await Future.wait(
      List.generate(dayCount, (i) => getCompletionRateForDate(start.add(Duration(days: i)))),
    );
    return rates.reduce((a, b) => a + b) / rates.length;
  }

  Future<int> getTotalWins() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM completions');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// All completions ever recorded, in one query. Used by StatsController to
  /// compute rates/streaks/insights in memory instead of one DB query per day.
  Future<List<CompletionModel>> getAllCompletions() async {
    final db = await _dbHelper.database;
    final maps = await db.query('completions');
    return maps.map((m) => CompletionModel.fromMap(m)).toList();
  }
}
