import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/projects/domain/activity_log.dart';

void main() {
  group('ActivityLog Domain Model & Parsing Tests', () {
    test('Correctly parses ISO-8601 timestamp ending in Z without double-Z corruption', () {
      final json = {
        'id': 'act-001',
        'project_id': 'prj-100',
        'project_name': 'Commercial Complex',
        'action_type': 'PROJECT_SUBMITTED',
        'actor_id': 'eng-01',
        'actor_role': 'CLIENT',
        'details': 'Client submitted project brief.',
        'timestamp': '2026-10-26T20:46:15Z',
      };

      final log = ActivityLog.fromJson(json);

      expect(log.id, equals('act-001'));
      expect(log.projectId, equals('prj-100'));
      expect(log.projectName, equals('Commercial Complex'));
      expect(log.actionType, equals('PROJECT_SUBMITTED'));
      expect(log.actorRole, equals('ENGINEER')); // Normalized from CLIENT
      expect(log.details, equals('Client submitted project brief.'));
      expect(log.createdAt, isNotNull);
      expect(log.createdAt!.toUtc().year, equals(2026));
      expect(log.createdAt!.toUtc().month, equals(10));
      expect(log.createdAt!.toUtc().day, equals(26));
      expect(log.createdAt!.toUtc().hour, equals(20));
      expect(log.createdAt!.toUtc().minute, equals(46));
      expect(log.createdAt!.toUtc().second, equals(15));
    });

    test('Correctly parses SQL space-separated timestamp string', () {
      final json = {
        'id': 'act-002',
        'project_id': 'prj-101',
        'action_type': 'DRAWING_SUBMITTED',
        'actor_id': 'draughtsman-01',
        'actor_role': 'DRAUGHTSMAN',
        'details': 'Draughtsman submitted drawing.',
        'timestamp': '2026-10-25 14:30:00',
      };

      final log = ActivityLog.fromJson(json);

      expect(log.id, equals('act-002'));
      expect(log.createdAt, isNotNull);
      expect(log.createdAt!.toUtc().year, equals(2026));
      expect(log.createdAt!.toUtc().month, equals(10));
      expect(log.createdAt!.toUtc().day, equals(25));
    });

    test('Falls back gracefully to created_at when timestamp is null', () {
      final json = {
        'id': 'act-003',
        'project_id': 'prj-102',
        'action_type': 'CORRECTION_REQUESTED',
        'actor_id': 'eng-01',
        'actor_role': 'ENGINEER',
        'details': 'Correction requested',
        'created_at': '2026-10-24T10:00:00Z',
      };

      final log = ActivityLog.fromJson(json);

      expect(log.id, equals('act-003'));
      expect(log.createdAt, isNotNull);
      expect(log.createdAt!.toUtc().year, equals(2026));
      expect(log.createdAt!.toUtc().month, equals(10));
      expect(log.createdAt!.toUtc().day, equals(24));
    });

    test('Invalid or missing timestamps return null explicitly and do NOT become DateTime.now()', () {
      final jsonMissing = {
        'id': 'act-004a',
        'project_id': 'prj-103',
        'action_type': 'PROJECT_COMPLETED',
        'actor_id': 'eng-01',
        'actor_role': 'ENGINEER',
        'details': 'Completed without timestamp',
      };

      final jsonInvalid = {
        'id': 'act-004b',
        'project_id': 'prj-103',
        'action_type': 'PROJECT_COMPLETED',
        'actor_id': 'eng-01',
        'actor_role': 'ENGINEER',
        'details': 'Completed with invalid timestamp',
        'timestamp': 'not-a-valid-date-string',
      };

      final jsonEmpty = {
        'id': 'act-004c',
        'project_id': 'prj-103',
        'action_type': 'PROJECT_COMPLETED',
        'actor_id': 'eng-01',
        'actor_role': 'ENGINEER',
        'details': 'Completed with empty timestamp',
        'timestamp': '   ',
      };

      final logMissing = ActivityLog.fromJson(jsonMissing);
      final logInvalid = ActivityLog.fromJson(jsonInvalid);
      final logEmpty = ActivityLog.fromJson(jsonEmpty);

      expect(logMissing.createdAt, isNull, reason: 'Missing timestamp must produce null, not DateTime.now()');
      expect(logInvalid.createdAt, isNull, reason: 'Corrupt timestamp must produce null, not DateTime.now()');
      expect(logEmpty.createdAt, isNull, reason: 'Empty timestamp must produce null, not DateTime.now()');
    });

    test('Two activity events with different timestamps preserve their distinct respective times', () {
      final item1 = ActivityLog.fromJson({
        'id': 'act-1',
        'project_id': 'p1',
        'action_type': 'ASSIGNMENT_ACCEPTED',
        'actor_id': 'u1',
        'actor_role': 'DRAUGHTSMAN',
        'details': 'Draughtsman accepted',
        'timestamp': '2026-10-26T20:46:15Z',
      });

      final item2 = ActivityLog.fromJson({
        'id': 'act-2',
        'project_id': 'p1',
        'action_type': 'DRAWING_SUBMITTED',
        'actor_id': 'u1',
        'actor_role': 'DRAUGHTSMAN',
        'details': 'Drawing submitted',
        'timestamp': '2026-10-26T17:40:15Z',
      });

      expect(item1.createdAt, isNotNull);
      expect(item2.createdAt, isNotNull);
      expect(item1.createdAt, isNot(equals(item2.createdAt)));
      expect(item1.createdAt!.difference(item2.createdAt!).inMinutes, equals(186));
    });

    test('Supports map serialization and indexing operator', () {
      final log = ActivityLog(
        id: 'act-005',
        projectId: 'prj-105',
        projectName: 'Residential Villa',
        actionType: 'FILE_UPLOADED',
        actorId: 'eng-01',
        actorRole: 'ENGINEER',
        details: 'Uploaded file',
        createdAt: DateTime.utc(2026, 10, 26, 12, 0, 0),
      );

      final map = log.toMap();
      expect(map['id'], equals('act-005'));
      expect(map['project_name'], equals('Residential Villa'));
      expect(log['project_id'], equals('prj-105'));
      expect(log['action_type'], equals('FILE_UPLOADED'));
      expect(log['unknown_key'], isNull);
    });
  });
}
