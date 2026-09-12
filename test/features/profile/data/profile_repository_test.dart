import 'package:archi_draft/src/features/auth/domain/user_profile.dart';
import 'package:archi_draft/src/features/profile/data/profile_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late ProfileRepository repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = ProfileRepository(fakeFirestore);
  });

  group('ProfileRepository', () {
    const testUid = 'user123';
    
    final testProfile = UserProfile(
      id: testUid,
      name: 'John Doe',
      email: 'john@example.com',
      mobile: '+1234567890',
      role: 'CLIENT',
    );

    test('getProfile returns null when document does not exist', () async {
      final profile = await repository.getProfile('nonexistent');
      expect(profile, isNull);
    });

    test('getProfile returns UserProfile when document exists', () async {
      await fakeFirestore.collection('users').doc(testUid).set(testProfile.toFirestore());

      final profile = await repository.getProfile(testUid);
      expect(profile, isNotNull);
      expect(profile!.id, testUid);
      expect(profile.name, 'John Doe');
      expect(profile.role, 'CLIENT');
    });

    test('updateProfile only updates editable fields', () async {
      // 1. Initial profile
      await fakeFirestore.collection('users').doc(testUid).set(testProfile.toFirestore());

      // 2. Updated profile with mutable and immutable changes
      final updatedProfile = testProfile.copyWith(
        name: 'Jane Doe', // Mutable
        mobile: '+0987654321', // Mutable
        address: '123 Fake St', // Mutable Phase 4 field
      );

      // We manually attempt to change email (immutable)
      final maliciousProfile = UserProfile(
        id: updatedProfile.id,
        name: updatedProfile.name,
        email: 'hacker@example.com', // Immutable change attempt
        mobile: updatedProfile.mobile,
        role: 'ADMIN', // Immutable change attempt
        address: updatedProfile.address,
      );

      // 3. Update using repository (which uses toEditableFieldsMap)
      await repository.updateProfile(maliciousProfile);

      // 4. Verify results
      final result = await repository.getProfile(testUid);
      
      expect(result!.name, 'Jane Doe');
      expect(result.mobile, '+0987654321');
      expect(result.address, '123 Fake St');
      
      // Verify immutable fields were NOT changed by toEditableFieldsMap
      expect(result.email, 'john@example.com');
      expect(result.role, 'CLIENT');
    });
  });
}
