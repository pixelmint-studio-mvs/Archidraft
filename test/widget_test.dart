import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archi_draft/src/core/utils/auth_error_mapper.dart';

/// Basic smoke tests for the ARCHI DRAFT app.
///
/// Note: Full widget tests for auth screens require Riverpod overrides
/// and Firebase mocking. These tests verify non-Firebase utility classes.
void main() {
  group('AuthErrorMapper', () {
    test('maps invalid-credential to safe message', () {
      final message = AuthErrorMapper.mapException(
        FirebaseAuthException(code: 'invalid-credential'),
      );
      expect(message, contains('Invalid email or password'));
    });

    test('maps email-already-in-use', () {
      final message = AuthErrorMapper.mapException(
        FirebaseAuthException(code: 'email-already-in-use'),
      );
      expect(message, contains('already exists'));
    });

    test('maps weak-password', () {
      final message = AuthErrorMapper.mapException(
        FirebaseAuthException(code: 'weak-password'),
      );
      expect(message, contains('too weak'));
    });

    test('maps network-request-failed', () {
      final message = AuthErrorMapper.mapException(
        FirebaseAuthException(code: 'network-request-failed'),
      );
      expect(message, contains('internet'));
    });

    test('maps too-many-requests', () {
      final message = AuthErrorMapper.mapException(
        FirebaseAuthException(code: 'too-many-requests'),
      );
      expect(message, contains('Too many'));
    });

    test('maps user-disabled', () {
      final message = AuthErrorMapper.mapException(
        FirebaseAuthException(code: 'user-disabled'),
      );
      expect(message, contains('disabled'));
    });

    test('maps unknown errors to generic message', () {
      final message = AuthErrorMapper.mapException(
        FirebaseAuthException(code: 'some-unknown-code'),
      );
      expect(message, contains('unexpected error'));
    });

    test('does not reveal user-not-found separately', () {
      final message = AuthErrorMapper.mapException(
        FirebaseAuthException(code: 'user-not-found'),
      );
      // Should be same generic "Invalid email or password" — no enumeration
      expect(message, contains('Invalid email or password'));
    });

    test('handles non-Firebase exceptions', () {
      final message = AuthErrorMapper.mapException(Exception('random'));
      expect(message, contains('unexpected error'));
    });
  });
}
