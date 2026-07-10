import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nudge/core/database/database_helper.dart';

/// Regression test for the v1 → v2 migration: v1 installs predate the moods
/// table, and before the migration existed every mood write — and worse,
/// Settings → "Delete all data" — threw "no such table: moods" on upgraded
/// devices. Runs in its own file because DatabaseHelper is a process-wide
/// singleton and this test must own the very first open.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('v1 database without moods table upgrades cleanly', () async {
    // Recreate a genuine v1 install at the exact path DatabaseHelper opens:
    // the original schema, no moods table.
    final path = join(await databaseFactory.getDatabasesPath(), 'nudge.db');
    await databaseFactory.deleteDatabase(path);
    final v1 = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE habits (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              timeOfDay TEXT NOT NULL,
              reminderStyle TEXT NOT NULL,
              isActive INTEGER NOT NULL,
              createdAt TEXT NOT NULL,
              color TEXT NOT NULL,
              emoji TEXT NOT NULL,
              aiBreakdownEnabled INTEGER NOT NULL,
              habit_order INTEGER
            )
          ''');
          await db.execute('''
            CREATE TABLE completions (
              id TEXT PRIMARY KEY,
              habitId TEXT NOT NULL,
              completedAt TEXT NOT NULL,
              note TEXT,
              moodScore INTEGER,
              FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            CREATE TABLE focus_sessions (
              id TEXT PRIMARY KEY,
              duration INTEGER NOT NULL,
              taskName TEXT,
              startedAt TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE chat_messages (
              id TEXT PRIMARY KEY,
              text TEXT NOT NULL,
              isUser INTEGER NOT NULL,
              createdAt TEXT NOT NULL
            )
          ''');
        },
      ),
    );
    await v1.close();

    // First DatabaseHelper open runs the v2 migration.
    await DatabaseHelper.instance.insertMood(score: 4, note: 'post-upgrade');
    final avg = await DatabaseHelper.instance.getAverageMoodSince(DateTime(2000));
    expect(avg, 4.0);

    // The privacy-critical path: this threw on v1 files before the migration.
    await DatabaseHelper.instance.deleteAllData();
    expect(await DatabaseHelper.instance.getAverageMoodSince(DateTime(2000)), isNull);
  });
}
