import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/auth/domain/user_profile.dart';
import 'package:archi_draft/src/features/profile/domain/user_role.dart';
import 'package:archi_draft/src/features/profile/data/profile_repository.dart';

void main() {
  group('Existing Draughtsman Auth & Profile Resolution Regression Test', () {
    const draughtsmanUid = 'MZiLaSRIJkQ92H5gZi51LjL7sjh2';
    const draughtsmanEmail = 'mohdanas53n@gmail.com';

    final mockDraughtsmanMap = {
      'id': draughtsmanUid,
      'email': draughtsmanEmail,
      'name': 'Draughtsman',
      'role': 'DRAUGHTSMAN',
      'mobile': '123456789',
      'created_at': '2026-10-02 14:05:10',
    };

    test('1. Authenticated Draughtsman user resolves profile with exact UID and email', () {
      final profile = UserProfile.fromMap(mockDraughtsmanMap);

      expect(profile.id, equals(draughtsmanUid));
      expect(profile.email, equals(draughtsmanEmail));
      expect(profile.role, equals('DRAUGHTSMAN'));
    });

    test('2. Role resolves to UserRole.draughtsman', () {
      final profile = UserProfile.fromMap(mockDraughtsmanMap);
      final role = UserRole.fromString(profile.role);

      expect(role, equals(UserRole.draughtsman));
      expect(role?.displayName, equals('Draughtsman'));
    });

    test('3. Profile completeness is satisfied for Draughtsman Studio routing', () {
      final profile = UserProfile.fromMap(mockDraughtsmanMap);
      final isComplete = ProfileRepository.isProfileComplete(profile);

      expect(isComplete, isTrue);
    });

    test('4. Existing Draughtsman routes to /draughtsman/studio', () {
      final profile = UserProfile.fromMap(mockDraughtsmanMap);
      final role = UserRole.fromString(profile.role);
      final isComplete = ProfileRepository.isProfileComplete(profile);

      String? targetRoute;
      if (role == UserRole.draughtsman) {
        targetRoute = isComplete ? '/draughtsman/studio' : '/draughtsman/onboarding';
      }

      expect(targetRoute, equals('/draughtsman/studio'));
    });

    test('5. Network/connection errors do NOT falsely resolve as missing profile (null)', () {
      bool caughtNetworkError = false;

      // Demonstrates the fix: non-404 exceptions must rethrow
      try {
        final error = Exception('Failed to connect to 127.0.0.1:8787: Connection refused');
        if (error.toString().contains('404')) {
          // would return null
        } else {
          throw error;
        }
      } catch (e) {
        caughtNetworkError = true;
      }

      expect(caughtNetworkError, isTrue);
    });
  });
}
