import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/habits/models/habit_model.dart';

/// Syncs local habits & completions to Firestore for cross-device access.
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
        .where('isActive', isEqualTo: true)
        .orderBy('habitOrder')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => HabitModel.fromMap(d.data()))
            .toList());
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

  // ── User Profile ─────────────────────────────────────────────────────────────

  Future<void> saveUserProfile(Map<String, dynamic> data) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }
}
