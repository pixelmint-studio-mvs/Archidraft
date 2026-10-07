import 'package:archi_draft/src/features/profile/domain/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRole', () {
    test('fromString parses correctly', () {
      expect(UserRole.fromString('ENGINEER'), UserRole.engineer);
      expect(UserRole.fromString('engineer'), UserRole.engineer);
      expect(UserRole.fromString('STUDENT'), UserRole.student);
      expect(UserRole.fromString('DRAUGHTSMAN'), UserRole.draughtsman);
      expect(UserRole.fromString('ADMIN'), UserRole.admin);
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('UNKNOWN'), isNull);
      expect(UserRole.fromString(null), isNull);
    });

    test('toFirestoreString converts correctly', () {
      expect(UserRole.engineer.toFirestoreString(), 'ENGINEER');
      expect(UserRole.student.toFirestoreString(), 'STUDENT');
      expect(UserRole.draughtsman.toFirestoreString(), 'DRAUGHTSMAN');
      expect(UserRole.admin.toFirestoreString(), 'ADMIN');
    });

    test('displayName returns user friendly name', () {
      expect(UserRole.engineer.displayName, 'Engineer');
      expect(UserRole.student.displayName, 'Student');
      expect(UserRole.draughtsman.displayName, 'Draughtsman');
      expect(UserRole.admin.displayName, 'Administrator');
    });
  });
}
