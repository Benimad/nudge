import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return UserProfile(
      id: user.uid,
      displayName: user.displayName ?? 'Nudger',
      brainType: BrainType.notSure.name,
      isPremium: false,
      totalDopaminePoints: 0,
    );
  }

  bool _googleSignInInitialized = false;

  Future<UserCredential> signInWithGoogle() async {
    try {
      // google_sign_in v7: initialize once before use.
      if (!_googleSignInInitialized) {
        await GoogleSignIn.instance.initialize();
        _googleSignInInitialized = true;
      }

      // Trigger the interactive Google Sign-In flow (throws if cancelled).
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate(scopeHint: ['email']);

      // idToken comes from the authentication object.
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // accessToken is obtained separately via the authorization client in v7.
      final GoogleSignInClientAuthorization authz =
          await googleUser.authorizationClient.authorizeScopes(['email']);

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: authz.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential cred;
      final existingUser = _auth.currentUser;
      if (existingUser != null && existingUser.isAnonymous) {
        // Preserve the anonymous UID by linking Google onto it, rather than
        // replacing it — Firestore data and the RevenueCat entitlement are
        // both keyed by uid, so swapping identities here would orphan them.
        try {
          cred = await existingUser.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            // This Google account is already tied to a different Firebase
            // user (e.g. signed in on another device before). Fall back to
            // that existing account instead of failing the sign-in.
            cred = await _auth.signInWithCredential(credential);
          } else {
            rethrow;
          }
        }
      } else {
        cred = await _auth.signInWithCredential(credential);
      }

      if (cred.user != null) {
        await _syncIdentity(cred.user!.uid);
      }

      return cred;
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  Future<UserCredential> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    if (cred.user != null) {
      await _syncIdentity(cred.user!.uid);
    }
    return cred;
  }

  Future<void> _syncIdentity(String userId) async {
    await Posthog().identify(userId: userId);
    await Purchases.logIn(userId);
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      Purchases.logOut(),
    ]);
  }
}
