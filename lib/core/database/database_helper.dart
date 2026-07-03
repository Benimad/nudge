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
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
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

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
