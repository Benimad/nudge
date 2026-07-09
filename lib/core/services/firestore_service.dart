import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/habits/models/habit_model.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';

/// Mirrors local habits, completions, and profile to Firestore for
/// cross-device access and backup. Local SQLite/SharedPreferences remain the
/// source of truth for reads inside the app — this is a best-effort,
/// fire-and-forget write-through cache, not a bidirectional sync engine.
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Habit CRUD ──────────────────────────────────────────────────────────────

  Future<void> upsertHabit(HabitModel habit) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('habits')
        .doc(habit.id)
        .set(habit.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteHabit(String habitId) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('habits')
        .doc(habitId)
        .delete();
  }

  Stream<List<HabitModel>> habitsStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .collection('habits')
        .where('isActive', isEqualTo: 1)
        .orderBy('habit_order')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => HabitModel.fromMap(d.data())).toList());
  }

  // ── Completions ─────────────────────────────────────────────────────────────

  Future<void> recordCompletion(String habitId, DateTime date) async {
    final uid = _uid;
    if (uid == null) return;
    final dateStr = date.toIso8601String().substring(0, 10);
    await _db
        .collection('users')
        .doc(uid)
        .collection('completions')
        .doc('${habitId}_$dateStr')
        .set({
      'habitId': habitId,
      'date': dateStr,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCompletion(String habitId, DateTime date) async {
    final uid = _uid;
    if (uid == null) return;
    final dateStr = date.toIso8601String().substring(0, 10);
    await _db
        .collection('users')
        .doc(uid)
        .collection('completions')
        .doc('${habitId}_$dateStr')
        .delete();
  }

  // ── User Profile ─────────────────────────────────────────────────────────────

  Future<void> saveUserProfile(UserProfile profile) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  Future<UserProfile?> getUserProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return null;
    return UserProfile.fromMap(data);
  }

  Stream<UserProfile?> streamUserProfile() {
    final uid = _uid;
    if (uid == null) return Stream.value(null);
    return _db.collection('users').doc(uid).snapshots().map(
        (doc) => doc.data() == null ? null : UserProfile.fromMap(doc.data()!));
  }

  Future<void> updateDopaminePoints(int totalPoints) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .set({'totalDopaminePoints': totalPoints}, SetOptions(merge: true));
  }

  // ── Restore (cloud → local) ──────────────────────────────────────────────────

  /// Hydrates the local SQLite database from the user's cloud mirror. Used on a
  /// fresh install after the user signs back in, so their habits and history
  /// come back. Returns the number of habits restored (0 if nothing to do).
  /// Best-effort and idempotent — safe to run more than once.
  Future<int> restoreFromCloud() async {
    final uid = _uid;
    if (uid == null) return 0;
    final userRef = _db.collection('users').doc(uid);
    final db = await DatabaseHelper.instance.database;

    int restored = 0;
    final habitsSnap = await userRef.collection('habits').get();
    for (final doc in habitsSnap.docs) {
      try {
        final habit = HabitModel.fromMap(doc.data());
        await db.insert('habits', habit.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
        restored++;
      } catch (_) {
        // Skip any malformed remote doc rather than abort the whole restore.
      }
    }

    final compSnap = await userRef.collection('completions').get();
    for (final doc in compSnap.docs) {
      final data = doc.data();
      final habitId = data['habitId'] as String?;
      final dateStr = data['date'] as String?;
      if (habitId == null || dateStr == null) continue;
      final completedAt = DateTime.tryParse('${dateStr}T12:00:00') ?? DateTime.now();
      try {
        await db.insert(
          'completions',
          {
            'id': '${habitId}_$dateStr',
            'habitId': habitId,
            'completedAt': completedAt.toIso8601String(),
            'note': null,
            'moodScore': null,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (_) {
        // FK violation (habit not restored) — skip this completion.
      }
    }
    return restored;
  }

  // ── Full account deletion (local caller also wipes SQLite) ────────────────────

  /// Deletes the user's entire cloud mirror: every habit, completion, the
  /// profile doc, and the presence heartbeat. Honors the privacy-policy promise
  /// that "Delete all data" removes the cloud copy too. Best-effort.
  Future<void> deleteAllCloudData() async {
    final uid = _uid;
    if (uid == null) return;
    final userRef = _db.collection('users').doc(uid);
    for (final sub in ['habits', 'completions']) {
      final snap = await userRef.collection(sub).get();
      for (final d in snap.docs) {
        await d.reference.delete();
      }
    }
    await userRef.delete().catchError((_) {});
    await _db.collection('presence').doc(uid).delete().catchError((_) {});
  }
}
