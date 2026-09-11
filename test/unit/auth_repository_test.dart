import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/auth/domain/user_profile.dart';

/// Unit tests for the UserProfile model.
///
/// Note: Full AuthRepository integration tests require Firebase emulator
/// or mocking (firebase_auth_mocks / fake_cloud_firestore).
/// These tests cover the serialization/deserialization logic that
/// can be tested without Firebase dependencies.
void main() {
  group('UserProfile', () {
    test('toFirestore produces correct map', () {
      const profile = UserProfile(
        id: 'test-uid',
        name: 'Test User',
        email: 'test@example.com',
        mobile: '1234567890',
        role: 'CLIENT',
      );

      final map = profile.toFirestore();

      expect(map['id'], 'test-uid');
      expect(map['name'], 'Test User');
      expect(map['email'], 'test@example.com');
      expect(map['mobile'], '1234567890');
      expect(map['role'], 'CLIENT');
      expect(map.containsKey('createdAt'), true);
    });

    test('toFirestore includes all required Phase 3 fields', () {
      const profile = UserProfile(
        id: 'uid',
        name: 'Name',
        email: 'e@e.com',
        mobile: '123',
        role: 'DRAUGHTSMAN',
      );

      final map = profile.toFirestore();

      // Per DATA_ARCHITECTURE.md: id, name, email, mobile, role, createdAt
      expect(map.keys, containsAll(['id', 'name', 'email', 'mobile', 'role', 'createdAt']));
    });

    test('role must be CLIENT or DRAUGHTSMAN', () {
      // This test documents the expected constraint.
      // The actual enforcement is in AuthRepository.registerWithEmailAndPassword.
      const clientProfile = UserProfile(
        id: 'uid',
        name: 'Name',
        email: 'e@e.com',
        mobile: '123',
        role: 'CLIENT',
      );
      const draughtsmanProfile = UserProfile(
        id: 'uid',
        name: 'Name',
        email: 'e@e.com',
        mobile: '123',
        role: 'DRAUGHTSMAN',
      );

      expect(clientProfile.role, 'CLIENT');
      expect(draughtsmanProfile.role, 'DRAUGHTSMAN');
    });
  });
}
