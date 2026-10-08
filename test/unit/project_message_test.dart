import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/projects/domain/project_message.dart';

void main() {
  group('ProjectMessage Domain Model', () {
    test('parses JSON with all fields including attachment', () {
      final json = {
        'id': 'msg-123',
        'project_id': 'proj-456',
        'sender_id': 'user-789',
        'sender_name': 'Sarah J.',
        'sender_role': 'ENGINEER',
        'message': 'Please review the updated calculations.',
        'attachment_file_id': 'file-999',
        'attachment_name': 'Calculations_v2.pdf',
        'attachment_size': 2457600,
        'attachment_content_type': 'application/pdf',
        'created_at': '2026-10-08 14:00:00',
      };

      final message = ProjectMessage.fromJson(json);

      expect(message.id, 'msg-123');
      expect(message.projectId, 'proj-456');
      expect(message.senderId, 'user-789');
      expect(message.senderName, 'Sarah J.');
      expect(message.senderRole, 'ENGINEER');
      expect(message.message, 'Please review the updated calculations.');
      expect(message.hasAttachment, isTrue);
      expect(message.attachmentFileId, 'file-999');
      expect(message.attachmentName, 'Calculations_v2.pdf');
      expect(message.attachmentSize, 2457600);
      expect(message.attachmentContentType, 'application/pdf');
      expect(message.isFromEngineer, isTrue);
    });

    test('normalizes legacy CLIENT role to ENGINEER', () {
      final json = {
        'id': 'msg-124',
        'project_id': 'proj-456',
        'sender_id': 'user-789',
        'sender_name': 'Sarah J.',
        'sender_role': 'CLIENT',
        'message': 'Hello Draughtsman',
        'created_at': '2026-10-08 14:05:00Z',
      };

      final message = ProjectMessage.fromJson(json);

      expect(message.senderRole, 'ENGINEER');
      expect(message.isFromEngineer, isTrue);
      expect(message.hasAttachment, isFalse);
    });

    test('distinguishes Draughtsman role from Engineer', () {
      final json = {
        'id': 'msg-125',
        'project_id': 'proj-456',
        'sender_id': 'draughtsman-1',
        'sender_name': 'Alex M.',
        'sender_role': 'DRAUGHTSMAN',
        'message': 'Revisions uploaded for review.',
        'created_at': '2026-10-08 14:10:00',
      };

      final message = ProjectMessage.fromJson(json);

      expect(message.senderRole, 'DRAUGHTSMAN');
      expect(message.isFromEngineer, isFalse);
    });

    test('handles fallback when timestamp is null or malformed', () {
      final json = {
        'id': 'msg-126',
        'project_id': 'proj-456',
        'sender_id': 'user-789',
        'sender_name': 'Sarah J.',
        'sender_role': 'ENGINEER',
        'message': 'Test fallback',
        'created_at': null,
      };

      final message = ProjectMessage.fromJson(json);

      expect(message.id, 'msg-126');
      expect(message.createdAt, isA<DateTime>());
    });
  });
}
