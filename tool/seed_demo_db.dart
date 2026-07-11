// Builds a demo nudge.db for Play Store screenshots: 4 habits with ~4 weeks
// of believable history (Wednesdays strong, this week better than last),
// recent moods, focus sessions, and a short coach conversation.
//
// Usage: dart run tool/seed_demo_db.dart <output-path>
// Then push to the device and copy into /data/data/com.app.nudge/databases/.
import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

Future<void> main(List<String> args) async {
  final out = args.isNotEmpty ? args[0] : 'nudge_demo.db';
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;
  await factory.deleteDatabase(out);

  final db = await factory.openDatabase(out,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, v) async {
          await db.execute('''
            CREATE TABLE habits (
              id TEXT PRIMARY KEY, name TEXT NOT NULL, timeOfDay TEXT NOT NULL,
              reminderStyle TEXT NOT NULL, isActive INTEGER NOT NULL,
              createdAt TEXT NOT NULL, color TEXT NOT NULL, emoji TEXT NOT NULL,
              aiBreakdownEnabled INTEGER NOT NULL, habit_order INTEGER
            )''');
          await db.execute('''
            CREATE TABLE completions (
              id TEXT PRIMARY KEY, habitId TEXT NOT NULL, completedAt TEXT NOT NULL,
              note TEXT, moodScore INTEGER,
              FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE
            )''');
          await db.execute('''
            CREATE TABLE moods (
              id TEXT PRIMARY KEY, score INTEGER NOT NULL, note TEXT, createdAt TEXT NOT NULL
            )''');
          await db.execute('''
            CREATE TABLE focus_sessions (
              id TEXT PRIMARY KEY, duration INTEGER NOT NULL, taskName TEXT, startedAt TEXT NOT NULL
            )''');
          await db.execute('''
            CREATE TABLE chat_messages (
              id TEXT PRIMARY KEY, text TEXT NOT NULL, isUser INTEGER NOT NULL, createdAt TEXT NOT NULL
            )''');
        },
      ));

  const uuid = Uuid();
  final now = DateTime.now();
  DateTime day(int daysAgo, [int hour = 9]) =>
      DateTime(now.year, now.month, now.day, hour).subtract(Duration(days: daysAgo));

  Future<String> habit(String name, String tod, String color, String emoji,
      int order, int createdDaysAgo) async {
    final id = uuid.v4();
    await db.insert('habits', {
      'id': id, 'name': name, 'timeOfDay': tod, 'reminderStyle': 'soft_nudge',
      'isActive': 1, 'createdAt': day(createdDaysAgo).toIso8601String(),
      'color': color, 'emoji': emoji, 'aiBreakdownEnabled': 1, 'habit_order': order,
    });
    return id;
  }

  Future<void> done(String habitId, int daysAgo, [int hour = 9]) async {
    await db.insert('completions', {
      'id': uuid.v4(), 'habitId': habitId,
      'completedAt': day(daysAgo, hour).toIso8601String(),
    });
  }

  final water = await habit('Drink a glass of water', 'morning', '#7862E8', '💧', 0, 30);
  final meds = await habit('Take medication', 'morning', '#10B981', '💊', 1, 30);
  final walk = await habit('10-minute walk', 'afternoon', '#E8A87C', '🚶', 2, 24);
  final read = await habit('Wind-down reading', 'evening', '#6FA8DC', '📖', 3, 18);

  // Water: 12-day live streak + scattered earlier days.
  for (var d = 0; d <= 11; d++) {
    await done(water, d, 8);
  }
  for (final d in [13, 14, 16, 17, 19, 20, 21, 24, 27]) {
    await done(water, d, 8);
  }

  // Meds: 5-day streak, mostly consistent with a few gaps; today done.
  for (var d = 0; d <= 4; d++) {
    await done(meds, d, 8);
  }
  for (final d in [6, 7, 8, 10, 11, 13, 14, 15, 17, 20, 21, 22, 24, 25, 27]) {
    await done(meds, d, 9);
  }

  // Walk: strong on Wednesdays (and improving this week); not done today yet.
  for (var d = 1; d <= 23; d++) {
    final date = day(d);
    final isWednesday = date.weekday == DateTime.wednesday;
    final thisWeek = d <= 6;
    if (isWednesday || (thisWeek && d % 2 == 1) || (!thisWeek && d % 4 == 1)) {
      await done(walk, d, 15);
    }
  }

  // Reading: 3-day streak, patchy before; not done today yet.
  for (var d = 1; d <= 3; d++) {
    await done(read, d, 21);
  }
  for (final d in [5, 6, 9, 12, 13, 16]) {
    await done(read, d, 21);
  }

  // Moods this week — bright, average ≈ 4.3.
  for (final e in [
    [0, 4], [1, 5], [2, 4], [3, 4], [4, 3], [5, 5], [6, 5],
  ]) {
    await db.insert('moods', {
      'id': uuid.v4(), 'score': e[1], 'note': null,
      'createdAt': day(e[0], 10).toIso8601String(),
    });
  }

  // Focus sessions: a few this week, one earlier today.
  for (final e in [
    [0, 25, 'Clear inbox'], [1, 25, 'Study session'], [3, 45, 'Deep work'], [5, 25, 'Tidy desk'],
  ]) {
    await db.insert('focus_sessions', {
      'id': uuid.v4(), 'duration': (e[1] as int) * 60, 'taskName': e[2],
      'startedAt': day(e[0] as int, 11).toIso8601String(),
    });
  }

  // A short coach conversation in the product voice (yesterday evening).
  final chat = [
    [1, "I keep putting off cleaning my desk. It's been 3 days and I feel awful about it."],
    [0, "Three days just means the task grew teeth — that happens to every ADHD brain, and it says nothing about you. Let's shrink it: put ONE thing back where it belongs, then you're allowed to stop. Starting is usually the whole battle."],
    [1, "Okay… that actually worked. I ended up doing the whole desk!"],
    [0, "Look at you! That's the momentum effect — action creates motivation, not the other way around. You're on a 12-day water streak too, so this week is genuinely building. Want to ride the energy into a 10-minute focus session?"],
  ];
  var t = DateTime(now.year, now.month, now.day - 1, 19, 12);
  for (final m in chat) {
    await db.insert('chat_messages', {
      'id': '${t.microsecondsSinceEpoch}_${m[0] == 1 ? 'u' : 'a'}',
      'text': m[1] as String, 'isUser': m[0] as int,
      'createdAt': t.toIso8601String(),
    });
    t = t.add(const Duration(minutes: 2));
  }

  await db.close();
  stdout.writeln('Seeded $out');
}
