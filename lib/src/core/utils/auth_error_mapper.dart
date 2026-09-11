import 'package:firebase_auth/firebase_auth.dart';

/// Maps [FirebaseAuthException] error codes to safe, user-facing messages.
///
/// Per ERROR_HANDLING.md: "Users must never see raw technical errors."
/// Per SECURITY_ARCHITECTURE.md: Do not reveal account existence
/// through differentiated error messages.
class AuthErrorMapper {
  AuthErrorMapper._();

  /// Returns a user-friendly error message for the given [exception].
  static String mapException(Object exception) {
    if (exception is FirebaseAuthException) {
      return _mapAuthCode(exception.code);
    }
    if (exception is FirebaseException) {
      return 'An unexpected error occurred. Please try again later.';
    }
    return 'An unexpected error occurred. Please try again later.';
  }

  static String _mapAuthCode(String code) {
    switch (code) {
      // Login errors — merged to prevent account enumeration
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid email or password. Please try again.';

      // Registration errors
      case 'email-already-in-use':
        return 'An account with this email already exists. Please log in or use a different email.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 8 characters with uppercase, lowercase, and a number.';
      case 'invalid-email':
        return 'Please enter a valid email address.';

      // Rate limiting
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again later.';

      // Network
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';

      // Account state
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';

      // Custom (from AuthRepository)
      case 'invalid-role':
        return 'Invalid registration role selected.';

      // Default
      default:
        return 'An unexpected error occurred. Please try again later.';
    }
  }
}
