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
    List<int>? proofBytes,
    String? proofFileName,
    String? proofDocumentType,
  }) async {
    if (role != 'ENGINEER' && role != 'DRAUGHTSMAN' && role != 'STUDENT') {
      throw FirebaseAuthException(
        code: 'invalid-role',
        message: 'Invalid role. Only ENGINEER, DRAUGHTSMAN, and STUDENT are permitted.',
      );
    }

    UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (authErr) {
      if (authErr.code == 'email-already-in-use') {
        // Safe recovery for existing Firebase accounts created by broken prior attempts:
        // Sign in with the provided credentials and complete registration persistence.
        try {
          credential = await _auth.signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
        } catch (_) {
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Failed to create account.',
      );
    }

    try {

      if (proofBytes != null && proofBytes.isNotEmpty) {
        // Upload proof document securely
        final ext = (proofFileName != null && proofFileName.contains('.'))
            ? proofFileName.split('.').last.toLowerCase()
            : 'pdf';
        String contentType = 'application/pdf';
        if (ext == 'png') {
          contentType = 'image/png';
        } else if (ext == 'jpg' || ext == 'jpeg') {
          contentType = 'image/jpeg';
        }

        final actionId = DateTime.now().millisecondsSinceEpoch.toString();
        final proofResponse = await _apiClient.postFileStream(
          '/api/registration/proof',
          Stream.value(proofBytes),
          proofBytes.length,
          fileName: proofFileName ?? 'proof_document.pdf',
          contentType: contentType,
          actionId: actionId,
        );

        final docType = proofDocumentType ??
            (role == 'STUDENT'
                ? 'STUDENT_ID'
                : (role == 'DRAUGHTSMAN'
                    ? 'QUALIFICATION_CERTIFICATE'
                    : 'DEGREE_CERTIFICATE'));

        await _apiClient.post('/api/registration/submit', body: {
          'name': name.trim(),
          'email': email.trim(),
          'role': role,
          'mobile': mobile.trim(),
          'proof_file_id': proofResponse['file_id'] ?? actionId,
          'proof_file_name': proofResponse['file_name'] ?? (proofFileName ?? 'proof_document.pdf'),
          'proof_file_size': proofResponse['file_size'] ?? proofBytes.length,
          'proof_content_type': proofResponse['content_type'] ?? contentType,
          'proof_object_key': proofResponse['object_key'],
          'proof_document_type': docType,
        });
      } else {
        // Fallback for tests or legacy callers without proof
        await _apiClient.post('/api/users', body: {
          'email': email.trim(),
          'name': name.trim(),
          'mobile': mobile.trim(),
          'role': role,
        });
      }
    } catch (e) {
      if (e.toString().contains('409') || e.toString().contains('already exists')) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'An account with this email address already exists. Please log in or use a different email.',
        );
      }
      rethrow;
    }

    return credential;
  }

  Future<Map<String, dynamic>?> getRegistrationStatus() async {
    try {
      final response = await _apiClient.get('/api/registration/status');
      return response is Map<String, dynamic> ? response : null;
    } catch (_) {
      return null;
    }
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
      // If the backend returns a 404 (user genuinely not in D1), return null.
      // SECURITY: Never recreate a profile with a default role.
      if (e.toString().contains('404')) {
        return null;
      }
      // For network errors, connection failures, or server 500s, rethrow so Riverpod enters
      // an AsyncError state with a retry option.
      rethrow;
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

  Future<void> provisionProfileWithProof({
    required String name,
    required String mobile,
    required String role,
    required List<int> proofBytes,
    required String proofFileName,
    String? proofDocumentType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Cannot provision profile: No Firebase user is signed in.');
    }

    final email = user.email ?? 'unknown@example.com';

    // Upload proof document securely
    final ext = (proofFileName.contains('.'))
        ? proofFileName.split('.').last.toLowerCase()
        : 'pdf';
    String contentType = 'application/pdf';
    if (ext == 'png') {
      contentType = 'image/png';
    } else if (ext == 'jpg' || ext == 'jpeg') {
      contentType = 'image/jpeg';
    }

    final actionId = DateTime.now().millisecondsSinceEpoch.toString();
    final proofResponse = await _apiClient.postFileStream(
      '/api/registration/proof',
      Stream.value(proofBytes),
      proofBytes.length,
      fileName: proofFileName,
      contentType: contentType,
      actionId: actionId,
    );

    final docType = proofDocumentType ??
        (role == 'STUDENT'
            ? 'STUDENT_ID'
            : (role == 'DRAUGHTSMAN'
                ? 'QUALIFICATION_CERTIFICATE'
                : 'DEGREE_CERTIFICATE'));

    await _apiClient.post('/api/registration/submit', body: {
      'name': name.trim(),
      'email': email.trim(),
      'role': role,
      'mobile': mobile.trim(),
      'proof_file_id': proofResponse['file_id'] ?? actionId,
      'proof_file_name': proofResponse['file_name'] ?? proofFileName,
      'proof_file_size': proofResponse['file_size'] ?? proofBytes.length,
      'proof_content_type': proofResponse['content_type'] ?? contentType,
      'proof_object_key': proofResponse['object_key'],
      'proof_document_type': docType,
    });
  }
}
