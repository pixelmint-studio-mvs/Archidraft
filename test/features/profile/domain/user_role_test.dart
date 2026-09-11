import '../../../../lib/src/features/profile/domain/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRole', () {
    test('fromString parses correctly', () {
      expect(UserRole.fromString('CLIENT'), UserRole.client);
      expect(UserRole.fromString('client'), UserRole.client);
      expect(UserRole.fromString('DRAUGHTSMAN'), UserRole.draughtsman);
      expect(UserRole.fromString('ADMIN'), UserRole.admin);
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('UNKNOWN'), isNull);
      expect(UserRole.fromString(null), isNull);
    });

    test('toFirestoreString converts correctly', () {
      expect(UserRole.client.toFirestoreString(), 'CLIENT');
      expect(UserRole.draughtsman.toFirestoreString(), 'DRAUGHTSMAN');
      expect(UserRole.admin.toFirestoreString(), 'ADMIN');
    });

    test('displayName returns user friendly name', () {
      expect(UserRole.client.displayName, 'Client');
      expect(UserRole.draughtsman.displayName, 'Draughtsman');
      expect(UserRole.admin.displayName, 'Administrator');
    });
  });
}
