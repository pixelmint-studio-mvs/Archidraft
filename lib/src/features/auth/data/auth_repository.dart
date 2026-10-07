import 'package:firebase_auth/firebase_auth.dart';

import '../domain/user_profile.dart';
import '../../api/data/api_client.dart';

/// Repository handling all Firebase Authentication and API user profile ops.
class AuthRepository {
  final FirebaseAuth _auth;
  final ApiClient _apiClient;

  AuthRepository(this._auth, this._apiClient);

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String mobile,
    required String role,
  }) async {
    if (role != 'ENGINEER' && role != 'DRAUGHTSMAN' && role != 'STUDENT') {
      throw FirebaseAuthException(
        code: 'invalid-role',
        message: 'Invalid role. Only ENGINEER, DRAUGHTSMAN, and STUDENT are permitted.',
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
      try {
        await user.sendEmailVerification();
      } catch (emailErr) {
        // Ignored
      }

      // Call Cloudflare API to save user
      // Note: the ApiClient automatically includes the Firebase token in the header.
      // So the API will extract `uid` from the token and create the user in D1.
      await _apiClient.post('/api/users', body: {
        'email': email.trim(),
        'name': name.trim(),
        'mobile': mobile.trim(),
        'role': role,
      });
      
    } catch (e) {
      await user.delete();
      rethrow;
    }

    return credential;
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<bool> reloadUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final response = await _apiClient.get('/api/users/me');
      return UserProfile.fromMap(response);
    } catch (e) {
      // Return null immediately. We will handle missing profiles in the UI.
      return null;
    }
  }

  Future<void> provisionLocalProfile({
    required String name,
    required String mobile,
    required String role,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Cannot provision profile: No Firebase user is signed in.');
    }

    await _apiClient.post('/api/users', body: {
      'email': user.email ?? 'unknown@example.com',
      'name': name.trim(),
      'mobile': mobile.trim(),
      'role': role,
    });
  }
}
