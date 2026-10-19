import 'package:archi_draft/src/features/projects/domain/assignment_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AssignmentStatus', () {
    test('fromString parses known values correctly', () {
      expect(AssignmentStatus.fromString('PENDING'), equals(AssignmentStatus.pending));
      expect(AssignmentStatus.fromString('ACCEPTED'), equals(AssignmentStatus.accepted));
      expect(AssignmentStatus.fromString('REJECTED'), equals(AssignmentStatus.rejected));
      expect(AssignmentStatus.fromString('REPLACED'), equals(AssignmentStatus.replaced));
      expect(AssignmentStatus.fromString('COMPLETED'), equals(AssignmentStatus.completed));
    });

    test('fromString parses lowercase values correctly', () {
      expect(AssignmentStatus.fromString('pending'), equals(AssignmentStatus.pending));
      expect(AssignmentStatus.fromString('accepted'), equals(AssignmentStatus.accepted));
    });

    test('fromString falls back to pending for unknown values', () {
      expect(AssignmentStatus.fromString('UNKNOWN_STATE'), equals(AssignmentStatus.pending));
      expect(AssignmentStatus.fromString(''), equals(AssignmentStatus.pending));
    });

    test('displayName returns user-friendly string', () {
      expect(AssignmentStatus.pending.displayName, equals('Pending'));
      expect(AssignmentStatus.accepted.displayName, equals('Accepted'));
      expect(AssignmentStatus.rejected.displayName, equals('Rejected'));
      expect(AssignmentStatus.replaced.displayName, equals('Replaced'));
      expect(AssignmentStatus.completed.displayName, equals('Completed'));
    });
  });
}
