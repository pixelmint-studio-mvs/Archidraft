import 'package:archi_draft/src/features/projects/domain/assignment.dart';
import 'package:archi_draft/src/features/projects/domain/assignment_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Assignment.fromMap', () {
    final fullMap = {
      'id': 'assign-abc',
      'project_id': 'proj-123',
      'draughtsman_id': 'dman-uid-456',
      'status': 'PENDING',
      'created_at': '2026-09-17 15:29:32',
      'updated_at': '2026-10-04 15:51:22',
      'project_name': 'Test Villa',
      'project_address': '10 Baker St',
      'drawing_name': 'Ground Plan',
      'drawing_type': 'FLOOR_PLAN',
      'project_area': '1200',
      'project_status': 'WAITING_ACCEPTANCE',
      'correction_round': 0,
      'submitted_at': null,
      'approved_at': null,
      'assigned_at': '2026-09-17 15:29:32',
      'rejected_at': null,
      'cancelled_at': null,
    };

    test('parses all fields from a full API response', () {
      final assignment = Assignment.fromMap(fullMap);
      expect(assignment.id, 'assign-abc');
      expect(assignment.projectId, 'proj-123');
      expect(assignment.draughtsmanId, 'dman-uid-456');
      expect(assignment.status, 'PENDING');
      expect(assignment.projectName, 'Test Villa');
      expect(assignment.projectAddress, '10 Baker St');
      expect(assignment.drawingType, 'FLOOR_PLAN');
      expect(assignment.projectStatus, 'WAITING_ACCEPTANCE');
      expect(assignment.correctionRound, 0);
      expect(assignment.assignedAt, isNotNull);
    });

    test('assignmentStatus resolves correctly from status string', () {
      expect(Assignment.fromMap({...fullMap, 'status': 'PENDING'}).assignmentStatus, AssignmentStatus.pending);
      expect(Assignment.fromMap({...fullMap, 'status': 'ACCEPTED'}).assignmentStatus, AssignmentStatus.accepted);
      expect(Assignment.fromMap({...fullMap, 'status': 'REJECTED'}).assignmentStatus, AssignmentStatus.rejected);
      expect(Assignment.fromMap({...fullMap, 'status': 'COMPLETED'}).assignmentStatus, AssignmentStatus.completed);
    });

    test('displayProjectName falls back when name is null', () {
      final noName = Assignment.fromMap({...fullMap, 'project_name': null});
      expect(noName.displayProjectName, startsWith('Project '));
    });

    test('displayProjectName uses projectName when available', () {
      expect(Assignment.fromMap(fullMap).displayProjectName, 'Test Villa');
    });

    test('handles missing optional fields gracefully', () {
      final minimal = {'id': 'a', 'project_id': 'p', 'draughtsman_id': 'd', 'status': 'PENDING'};
      final assignment = Assignment.fromMap(minimal);
      expect(assignment.projectName, isNull);
      expect(assignment.createdAt, isNull);
    });

    test('isRevision is false when rejectedAt is null', () {
      expect(Assignment.fromMap(fullMap).isRevision, isFalse);
    });

    test('isRevision is true when rejectedAt set and project not completed', () {
      final revision = Assignment.fromMap({...fullMap, 'rejected_at': '2026-10-01 10:00:00', 'project_status': 'IN_PROGRESS'});
      expect(revision.isRevision, isTrue);
    });

    test('isRevision is false when project is COMPLETED', () {
      final completed = Assignment.fromMap({...fullMap, 'rejected_at': '2026-10-01 10:00:00', 'project_status': 'COMPLETED'});
      expect(completed.isRevision, isFalse);
    });
  });

  group('Assignment dashboard counter logic', () {
    final assignments = [
      Assignment.fromMap({'id': 'a1', 'project_id': 'p1', 'draughtsman_id': 'uid', 'status': 'PENDING'}),
      Assignment.fromMap({'id': 'a2', 'project_id': 'p2', 'draughtsman_id': 'uid', 'status': 'PENDING'}),
      Assignment.fromMap({'id': 'a3', 'project_id': 'p3', 'draughtsman_id': 'uid', 'status': 'ACCEPTED', 'project_status': 'IN_PROGRESS'}),
      Assignment.fromMap({'id': 'a4', 'project_id': 'p4', 'draughtsman_id': 'uid', 'status': 'ACCEPTED', 'project_status': 'UNDER_CLIENT_REVIEW'}),
      Assignment.fromMap({'id': 'a5', 'project_id': 'p5', 'draughtsman_id': 'uid', 'status': 'COMPLETED', 'project_status': 'COMPLETED'}),
    ];

    test('pending counter matches PENDING assignments', () {
      final count = assignments.where((a) => a.assignmentStatus == AssignmentStatus.pending).length;
      expect(count, 2);
    });

    test('inProgress counter matches ACCEPTED assignments', () {
      final count = assignments.where((a) => a.assignmentStatus == AssignmentStatus.accepted).length;
      expect(count, 2);
    });

    test('underReview counter matches UNDER_CLIENT_REVIEW project status', () {
      final count = assignments.where((a) => a.projectStatus == 'UNDER_CLIENT_REVIEW').length;
      expect(count, 1);
    });

    test('completed counter matches COMPLETED assignments or projects', () {
      final count = assignments.where(
        (a) => a.assignmentStatus == AssignmentStatus.completed || a.projectStatus == 'COMPLETED',
      ).length;
      expect(count, 1);
    });
  });

  group('Assignment draughtsman isolation', () {
    test('assignment preserves its draughtsman_id for ownership audit', () {
      const myUid = 'MZiLaSRIJkQ92H5gZi51LjL7sjh2';
      const otherUid = 'IhgkdRzpMaTRI14ZOQ0dphAK1642';
      final mine = Assignment.fromMap({'id': 'a1', 'project_id': 'p1', 'draughtsman_id': myUid, 'status': 'PENDING'});
      final other = Assignment.fromMap({'id': 'a2', 'project_id': 'p2', 'draughtsman_id': otherUid, 'status': 'ACCEPTED'});
      expect(mine.draughtsmanId, myUid);
      expect(other.draughtsmanId, otherUid);
      expect(mine.draughtsmanId, isNot(equals(other.draughtsmanId)));
    });
  });

  group('Assignment copyWith', () {
    test('copyWith status update preserves all other fields', () {
      final original = Assignment.fromMap({
        'id': 'assign-abc', 'project_id': 'proj-123',
        'draughtsman_id': 'dman-uid', 'status': 'PENDING', 'project_name': 'Test Villa',
      });
      final updated = original.copyWith(status: 'ACCEPTED');
      expect(updated.status, 'ACCEPTED');
      expect(updated.id, 'assign-abc');
      expect(updated.projectName, 'Test Villa');
    });
  });

  group('Assignment status filter', () {
    test('filter by PENDING returns only pending', () {
      final all = [
        Assignment.fromMap({'id': 'a1', 'project_id': 'p1', 'draughtsman_id': 'uid', 'status': 'PENDING'}),
        Assignment.fromMap({'id': 'a2', 'project_id': 'p2', 'draughtsman_id': 'uid', 'status': 'ACCEPTED'}),
        Assignment.fromMap({'id': 'a3', 'project_id': 'p3', 'draughtsman_id': 'uid', 'status': 'COMPLETED'}),
      ];
      final filtered = all.where((a) => a.assignmentStatus == AssignmentStatus.pending).toList();
      expect(filtered.length, 1);
      expect(filtered.first.id, 'a1');
    });
  });
}
