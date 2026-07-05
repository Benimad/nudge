import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Real presence for body-doubling sessions, backed by `presence/{uid}`
/// heartbeat docs in Firestore (see firestore.rules).
///
/// While a session runs we write our own heartbeat every [_heartbeat] and
/// poll an aggregate count of everyone whose heartbeat is fresher than
/// [_staleAfter]. Every call is best-effort: with no network or no Firebase
/// the service just reports nothing and the UI keeps its last value — the
/// focus timer itself never depends on this.
class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  static const _heartbeat = Duration(seconds: 60);
  static const _staleAfter = Duration(minutes: 3);

  Timer? _heartbeatTimer;
  Timer? _countTimer;

  String? get _uid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null; // Firebase not initialized
    }
  }

  DocumentReference<Map<String, dynamic>>? get _myDoc {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('presence').doc(uid);
  }

  /// Start heartbeating and reporting live counts through [onCount].
  /// The first count arrives quickly so the UI doesn't sit on a stale number.
  void start({required void Function(int count) onCount}) {
    stop();
    _beat();
    _heartbeatTimer = Timer.periodic(_heartbeat, (_) => _beat());
    _fetchCount(onCount);
    _countTimer = Timer.periodic(_heartbeat, (_) => _fetchCount(onCount));
  }

  /// Stop heartbeating and remove our presence doc (best-effort).
  void stop() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _countTimer?.cancel();
    _countTimer = null;
    _myDoc?.delete().catchError((e) {
      debugPrint('Presence cleanup failed (ignored): $e');
    });
  }

  Future<void> _beat() async {
    try {
      await _myDoc?.set({
        'lastSeen': FieldValue.serverTimestamp(),
        'inSession': true,
      });
    } catch (e) {
      debugPrint('Presence heartbeat failed (ignored): $e');
    }
  }

  Future<void> _fetchCount(void Function(int) onCount) async {
    try {
      final cutoff = Timestamp.fromDate(DateTime.now().subtract(_staleAfter));
      final snap = await FirebaseFirestore.instance
          .collection('presence')
          .where('lastSeen', isGreaterThan: cutoff)
          .count()
          .get();
      final count = snap.count;
      if (count != null && count > 0) onCount(count);
    } catch (e) {
      debugPrint('Presence count failed (ignored): $e');
    }
  }
}
