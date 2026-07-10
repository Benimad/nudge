import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('nudge.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // v1 databases predate the moods table (it was added to _createDB without a
  // version bump, so installs from before the mood check-in never got it).
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS moods (
          id TEXT PRIMARY KEY,
          score INTEGER NOT NULL,
          note TEXT,
          createdAt TEXT NOT NULL
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const boolType = 'INTEGER NOT NULL';
    const intType = 'INTEGER';

    await db.execute('''
      CREATE TABLE habits (
        id $idType,
        name $textType,
        timeOfDay TEXT NOT NULL,
        reminderStyle TEXT NOT NULL,
        isActive $boolType,
        createdAt TEXT NOT NULL,
        color TEXT NOT NULL,
        emoji TEXT NOT NULL,
        aiBreakdownEnabled $boolType,
        habit_order $intType
      )
    ''');

    await db.execute('''
      CREATE TABLE completions (
        id $idType,
        habitId TEXT NOT NULL,
        completedAt TEXT NOT NULL,
        note TEXT,
        moodScore INTEGER,
        FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE moods (
        id $idType,
        score INTEGER NOT NULL,
        note TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE focus_sessions (
        id $idType,
        duration INTEGER NOT NULL,
        taskName TEXT,
        startedAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE chat_messages (
        id $idType,
        text TEXT NOT NULL,
        isUser INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // Delete all data (privacy/data removal)
  Future<void> deleteAllData() async {
    final db = await instance.database;
    await db.delete('habits');
    await db.delete('completions');
    await db.delete('moods');
    await db.delete('focus_sessions');
    await db.delete('chat_messages');
  }
  Future<int> insertHabit(Map<String, dynamic> habit) async {
    final db = await instance.database;
    return await db.insert('habits', habit, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllHabits() async {
    final db = await instance.database;
    return await db.query('habits', orderBy: 'habit_order ASC');
  }

  Future<int> updateHabit(Map<String, dynamic> habit) async {
    final db = await instance.database;
    return await db.update(
      'habits',
      habit,
      where: 'id = ?',
      whereArgs: [habit['id']],
    );
  }

  Future<int> deleteHabit(String id) async {
    final db = await instance.database;
    return await db.delete(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> insertFocusSession({
    required int durationSeconds,
    String? taskName,
  }) async {
    final db = await instance.database;
    await db.insert('focus_sessions', {
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'duration': durationSeconds,
      'taskName': taskName,
      'startedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<int> getTotalFocusMinutesSince(DateTime since) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(duration) as total FROM focus_sessions WHERE startedAt >= ?',
      [since.toIso8601String()],
    );
    final totalSeconds = Sqflite.firstIntValue(result) ?? 0;
    return totalSeconds ~/ 60;
  }

  Future<void> insertMood({required int score, String? note}) async {
    final db = await instance.database;
    await db.insert('moods', {
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'score': score,
      'note': note,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// Average mood (1–5) since [since], or null if nothing logged.
  Future<double?> getAverageMoodSince(DateTime since) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT AVG(score) as avg FROM moods WHERE createdAt >= ?',
      [since.toIso8601String()],
    );
    final avg = result.first['avg'];
    return avg == null ? null : (avg as num).toDouble();
  }

  Future<int> getSessionsCountForDate(DateTime date) async {
    final db = await instance.database;
    final start = DateTime(date.year, date.month, date.day).toIso8601String();
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM focus_sessions WHERE startedAt BETWEEN ? AND ?',
      [start, end],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
