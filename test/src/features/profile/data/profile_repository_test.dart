import 'package:archi_draft/src/features/profile/data/profile_repository.dart';
import 'package:archi_draft/src/features/auth/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileRepository', () {
    group('isProfileComplete', () {
      test('should return false if name is empty', () {
        final profile = UserProfile(
          id: '1',
          name: '',
          email: 'test@test.com',
          role: 'DRAUGHTSMAN',
          mobile: '1234567890',
        );
        expect(ProfileRepository.isProfileComplete(profile), isFalse);
      });

      test('should return false if name is only whitespace', () {
        final profile = UserProfile(
          id: '1',
          name: '   ',
          email: 'test@test.com',
          role: 'DRAUGHTSMAN',
          mobile: '1234567890',
        );
        expect(ProfileRepository.isProfileComplete(profile), isFalse);
      });

      test('should return false if mobile is empty', () {
        final profile = UserProfile(
          id: '1',
          name: 'John Doe',
          email: 'test@test.com',
          role: 'DRAUGHTSMAN',
          mobile: '',
        );
        expect(ProfileRepository.isProfileComplete(profile), isFalse);
      });

      test('should return false if mobile is only whitespace', () {
        final profile = UserProfile(
          id: '1',
          name: 'John Doe',
          email: 'test@test.com',
          role: 'DRAUGHTSMAN',
          mobile: '   ',
        );
        expect(ProfileRepository.isProfileComplete(profile), isFalse);
      });

      test('should return true if name and mobile are valid', () {
        final profile = UserProfile(
          id: '1',
          name: 'John Doe',
          email: 'test@test.com',
          role: 'DRAUGHTSMAN',
          mobile: '1234567890',
        );
        expect(ProfileRepository.isProfileComplete(profile), isTrue);
      });
    });
  });
}
