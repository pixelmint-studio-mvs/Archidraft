import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/user_profile.dart';

/// Repository handling all Firebase Authentication and Firestore
/// user profile operations.
///
/// This is the single data-layer class for authentication.
/// No Firebase logic should exist outside this repository.
///
/// Ref: SYSTEM_ARCHITECTURE.md — "Simple Operations" (direct Firestore SDK).
/// User profile creation is a single-document write, appropriate for
/// client-side execution per the approved architecture.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  /// Stream of authentication state changes.
  ///
  /// Emits the current [User] when logged in, or `null` when logged out.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// The currently authenticated Firebase user, or `null`.
  User? get currentUser => _auth.currentUser;

  // ──────────────────────────────────────────
  // REGISTRATION
  // ──────────────────────────────────────────

  /// Registers a new user with email and password, then creates
  /// a Firestore profile at `users/{uid}`.
  ///
  /// If Firestore profile creation fails after Firebase Auth account
  /// creation, the Auth account is deleted to prevent orphaned accounts.
  ///
  /// Throws [FirebaseAuthException] on auth failure.
  /// Throws [FirebaseException] on Firestore failure (after cleanup).
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String mobile,
    required String role,
  }) async {
    // Validate role — only CLIENT and DRAUGHTSMAN are permitted.
    // Per SECURITY_ARCHITECTURE.md: "Normal registration must never create an ADMIN."
    if (role != 'CLIENT' && role != 'DRAUGHTSMAN') {
      throw FirebaseAuthException(
        code: 'invalid-role',
        message: 'Invalid role. Only CLIENT and DRAUGHTSMAN are permitted.',
      );
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Failed to create account.',
      );
    }

    try {
      // Send email verification
      await user.sendEmailVerification();

      // Create Firestore user profile
      final profile = UserProfile(
        id: user.uid,
        name: name.trim(),
        email: email.trim(),
        mobile: mobile.trim(),
        role: role,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(profile.toFirestore());
    } catch (e) {
      // Cleanup: delete the Firebase Auth account if Firestore write fails
      // to prevent orphaned auth accounts without profiles.
      await user.delete();
      rethrow;
    }

    return credential;
  }

  // ──────────────────────────────────────────
  // LOGIN
  // ──────────────────────────────────────────

  /// Signs in with email and password.
  ///
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ──────────────────────────────────────────
  // LOGOUT
  // ──────────────────────────────────────────

  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ──────────────────────────────────────────
  // EMAIL VERIFICATION
  // ──────────────────────────────────────────

  /// Sends a verification email to the current user.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Reloads the current user's data from Firebase to refresh
  /// `emailVerified` status.
  ///
  /// Returns `true` if the email is now verified.
  Future<bool> reloadUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // ──────────────────────────────────────────
  // PASSWORD RESET
  // ──────────────────────────────────────────

  /// Sends a password reset email.
  ///
  /// Per SECURITY_ARCHITECTURE.md and ERROR_HANDLING.md:
  /// The caller should always show a generic success message regardless
  /// of whether the email exists, to prevent account enumeration.
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ──────────────────────────────────────────
  // USER PROFILE
  // ──────────────────────────────────────────

  /// Fetches the Firestore user profile for the given [uid].
  ///
  /// Returns `null` if the profile does not exist.
  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromFirestore(doc);
  }
}
