import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/habits/models/habit_model.dart';
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
        .where('isActive', isEqualTo: true)
        .orderBy('habitOrder')
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
}
