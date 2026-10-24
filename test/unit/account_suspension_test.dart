import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/auth/domain/user_profile.dart';
import 'package:archi_draft/src/features/api/data/api_client.dart';

void main() {
  group('UserProfile Account Suspension Contract', () {
    test('isSuspended is true when status is SUSPENDED', () {
      final profile = UserProfile(
        id: 'usr-1',
        name: 'Suspended Draughtsman',
        email: 'suspended@example.com',
        mobile: '1234567890',
        role: 'DRAUGHTSMAN',
        status: 'SUSPENDED',
      );
      expect(profile.isSuspended, isTrue);
    });

    test('isSuspended is false when status is ACTIVE', () {
      final profile = UserProfile(
        id: 'usr-2',
        name: 'Active Draughtsman',
        email: 'active@example.com',
        mobile: '1234567890',
        role: 'DRAUGHTSMAN',
        status: 'ACTIVE',
      );
      expect(profile.isSuspended, isFalse);
    });

    test('isSuspended is false when status is null (legacy default)', () {
      final profile = UserProfile(
        id: 'usr-3',
        name: 'Legacy User',
        email: 'legacy@example.com',
        mobile: '1234567890',
        role: 'CLIENT',
        status: null,
      );
      expect(profile.isSuspended, isFalse);
    });

    test('fromMap deserializes status correctly', () {
      final json = {
        'id': 'usr-4',
        'name': 'Suspended Engineer',
        'email': 'engineer@example.com',
        'mobile': '9876543210',
        'role': 'CLIENT',
        'status': 'SUSPENDED',
      };
      final profile = UserProfile.fromMap(json);
      expect(profile.status, 'SUSPENDED');
      expect(profile.isSuspended, isTrue);
    });

    test('toMap preserves status field', () {
      final profile = UserProfile(
        id: 'usr-5',
        name: 'Active Engineer',
        email: 'eng@example.com',
        mobile: '9876543210',
        role: 'CLIENT',
        status: 'ACTIVE',
      );
      final json = profile.toMap();
      expect(json['status'], 'ACTIVE');
    });
  });

  group('AccountSuspendedException Contract', () {
    test('retains suspension message and formats cleanly', () {
      final ex = AccountSuspendedException('Your account has been administratively suspended.');
      expect(ex.message, 'Your account has been administratively suspended.');
      expect(ex.code, 'ACCOUNT_SUSPENDED');
      expect(ex.toString(), 'Your account has been administratively suspended.');
    });
  });
}
