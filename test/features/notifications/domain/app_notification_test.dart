import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/notifications/domain/app_notification.dart';

void main() {
  group('AppNotification Domain Model', () {
    test('parses correctly from valid Map with integer is_read', () {
      final map = {
        'id': 'notif-123',
        'user_id': 'user-456',
        'type': 'CHAT_MESSAGE',
        'title': 'New Message',
        'message': 'Engineer Sarah J. left a remark on Pavillion.',
        'is_read': 1,
        'created_at': '2026-10-09T06:30:00Z',
      };

      final notif = AppNotification.fromMap(map);

      expect(notif.id, 'notif-123');
      expect(notif.userId, 'user-456');
      expect(notif.type, 'CHAT_MESSAGE');
      expect(notif.title, 'New Message');
      expect(notif.message, 'Engineer Sarah J. left a remark on Pavillion.');
      expect(notif.isRead, isTrue);
      expect(notif.createdAt, isA<DateTime>());
    });

    test('parses correctly from Map with boolean is_read', () {
      final map = {
        'id': 'notif-456',
        'user_id': 'user-789',
        'type': 'CORRECTION_REQUESTED',
        'title': 'Correction Requested',
        'message': 'Revise structural footing callouts.',
        'is_read': false,
        'created_at': '2026-10-08T12:00:00Z',
      };

      final notif = AppNotification.fromMap(map);

      expect(notif.id, 'notif-456');
      expect(notif.isRead, isFalse);
      expect(notif.type, 'CORRECTION_REQUESTED');
    });

    test('handles missing or null fields gracefully with defaults', () {
      final map = <String, dynamic>{};

      final notif = AppNotification.fromMap(map);

      expect(notif.id, '');
      expect(notif.userId, '');
      expect(notif.type, '');
      expect(notif.title, '');
      expect(notif.message, '');
      expect(notif.isRead, isFalse);
      expect(notif.createdAt, isA<DateTime>());
    });

    test('copyWith creates updated copies correctly', () {
      final original = AppNotification(
        id: 'n-1',
        userId: 'u-1',
        type: 'ASSIGNMENT',
        title: 'New Assignment',
        message: 'Assigned to Project Alpha',
        isRead: false,
        createdAt: DateTime(2026, 10, 1),
      );

      final updated = original.copyWith(isRead: true);

      expect(updated.id, original.id);
      expect(updated.isRead, isTrue);
      expect(original.isRead, isFalse);
    });

    test('toMap serializes properly', () {
      final notif = AppNotification(
        id: 'n-2',
        userId: 'u-2',
        type: 'DRAWING_APPROVED',
        title: 'Drawing Approved',
        message: 'Version 2 has been approved.',
        isRead: true,
        createdAt: DateTime.utc(2026, 10, 5, 10, 0),
      );

      final map = notif.toMap();

      expect(map['id'], 'n-2');
      expect(map['user_id'], 'u-2');
      expect(map['type'], 'DRAWING_APPROVED');
      expect(map['is_read'], 1);
      expect(map['created_at'], '2026-10-05T10:00:00.000Z');
    });
  });
}
