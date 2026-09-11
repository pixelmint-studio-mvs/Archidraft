import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('returns error when null', () {
      expect(Validators.email(null), isNotNull);
    });

    test('returns error when empty', () {
      expect(Validators.email(''), isNotNull);
    });

    test('returns error when whitespace only', () {
      expect(Validators.email('   '), isNotNull);
    });

    test('returns error for invalid email format', () {
      expect(Validators.email('notanemail'), isNotNull);
      expect(Validators.email('missing@'), isNotNull);
      expect(Validators.email('@domain.com'), isNotNull);
      expect(Validators.email('user@'), isNotNull);
    });

    test('returns null for valid email', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('user.name+tag@domain.co.uk'), isNull);
    });
  });

  group('Validators.password', () {
    test('returns error when null', () {
      expect(Validators.password(null), isNotNull);
    });

    test('returns error when empty', () {
      expect(Validators.password(''), isNotNull);
    });

    test('returns error when too short', () {
      expect(Validators.password('Aa1'), isNotNull);
      expect(Validators.password('Aa1bcde'), isNotNull); // 7 chars
    });

    test('returns error when missing uppercase', () {
      expect(Validators.password('abcdefg1'), isNotNull);
    });

    test('returns error when missing lowercase', () {
      expect(Validators.password('ABCDEFG1'), isNotNull);
    });

    test('returns error when missing digit', () {
      expect(Validators.password('Abcdefgh'), isNotNull);
    });

    test('returns null for valid password', () {
      expect(Validators.password('Abcdefg1'), isNull);
      expect(Validators.password('StrongP4ss!'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('returns error when null', () {
      expect(Validators.confirmPassword(null, 'password'), isNotNull);
    });

    test('returns error when empty', () {
      expect(Validators.confirmPassword('', 'password'), isNotNull);
    });

    test('returns error when passwords do not match', () {
      expect(Validators.confirmPassword('different', 'password'), isNotNull);
    });

    test('returns null when passwords match', () {
      expect(Validators.confirmPassword('password', 'password'), isNull);
    });
  });

  group('Validators.name', () {
    test('returns error when null', () {
      expect(Validators.name(null), isNotNull);
    });

    test('returns error when empty', () {
      expect(Validators.name(''), isNotNull);
    });

    test('returns error when too short', () {
      expect(Validators.name('A'), isNotNull);
    });

    test('returns error when too long', () {
      expect(Validators.name('A' * 101), isNotNull);
    });

    test('returns null for valid name', () {
      expect(Validators.name('John Doe'), isNull);
      expect(Validators.name('Ab'), isNull); // exactly 2
    });
  });

  group('Validators.mobile', () {
    test('returns error when null', () {
      expect(Validators.mobile(null), isNotNull);
    });

    test('returns error when empty', () {
      expect(Validators.mobile(''), isNotNull);
    });

    test('returns error when too few digits', () {
      expect(Validators.mobile('12345'), isNotNull);
    });

    test('returns null for valid mobile', () {
      expect(Validators.mobile('1234567890'), isNull);
      expect(Validators.mobile('+91 98765 43210'), isNull);
    });
  });

  group('Validators.required', () {
    test('returns error when null', () {
      expect(Validators.required(null), isNotNull);
    });

    test('returns error when empty', () {
      expect(Validators.required(''), isNotNull);
    });

    test('returns null when non-empty', () {
      expect(Validators.required('value'), isNull);
    });

    test('uses custom field name in error', () {
      final result = Validators.required(null, 'Email');
      expect(result, contains('Email'));
    });
  });
}
