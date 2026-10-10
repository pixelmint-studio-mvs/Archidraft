import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/projects/domain/project_message.dart';

void main() {
  group('ProjectMessage Voice Message Tests', () {
    test('isVoiceMessage returns true for audio MIME types', () {
      final msg = ProjectMessage(
        id: 'msg-1',
        projectId: 'proj-1',
        senderId: 'user-1',
        senderName: 'Test Engineer',
        senderRole: 'ENGINEER',
        message: '',
        attachmentFileId: 'file-1',
        attachmentName: 'voice_note.bin',
        attachmentSize: 10240,
        attachmentContentType: 'audio/webm',
        createdAt: DateTime.now(),
      );

      expect(msg.hasAttachment, isTrue);
      expect(msg.isVoiceMessage, isTrue);
    });

    test('isVoiceMessage returns true for audio file extensions even with generic MIME', () {
      final audioExtensions = ['webm', 'm4a', 'mp3', 'wav', 'aac', 'ogg'];
      for (final ext in audioExtensions) {
        final msg = ProjectMessage(
          id: 'msg-$ext',
          projectId: 'proj-1',
          senderId: 'user-1',
          senderName: 'Test Engineer',
          senderRole: 'ENGINEER',
          message: '',
          attachmentFileId: 'file-$ext',
          attachmentName: 'voice_recording.$ext',
          attachmentSize: 10240,
          attachmentContentType: 'application/octet-stream',
          createdAt: DateTime.now(),
        );

        expect(msg.isVoiceMessage, isTrue, reason: 'Failed for extension: $ext');
      }
    });

    test('isVoiceMessage returns false for non-audio attachments', () {
      final nonAudioFiles = [
        ('sheet.pdf', 'application/pdf'),
        ('plan.dwg', 'application/acad'),
        ('site.dxf', 'application/dxf'),
        ('photo.png', 'image/png'),
        ('scan.jpg', 'image/jpeg'),
        ('archive.zip', 'application/zip'),
      ];

      for (final (name, mime) in nonAudioFiles) {
        final msg = ProjectMessage(
          id: 'msg-$name',
          projectId: 'proj-1',
          senderId: 'user-1',
          senderName: 'Test Engineer',
          senderRole: 'ENGINEER',
          message: 'Here is the file',
          attachmentFileId: 'file-doc',
          attachmentName: name,
          attachmentSize: 20480,
          attachmentContentType: mime,
          createdAt: DateTime.now(),
        );

        expect(msg.isVoiceMessage, isFalse, reason: 'Failed for $name ($mime)');
      }
    });

    test('isVoiceMessage returns false when there is no attachment', () {
      final msg = ProjectMessage(
        id: 'msg-text',
        projectId: 'proj-1',
        senderId: 'user-1',
        senderName: 'Test Engineer',
        senderRole: 'ENGINEER',
        message: 'This is just a text message.',
        createdAt: DateTime.now(),
      );

      expect(msg.hasAttachment, isFalse);
      expect(msg.isVoiceMessage, isFalse);
    });

    test('voice message can be parsed from JSON without text', () {
      final json = {
        'id': 'msg-v1',
        'project_id': 'proj-1',
        'sender_id': 'user-1',
        'sender_name': 'Engineer John',
        'sender_role': 'ENGINEER',
        'message': '',
        'attachment_file_id': 'audio-file-1',
        'attachment_name': 'voice_123.webm',
        'attachment_size': 45678,
        'attachment_content_type': 'audio/webm',
        'created_at': '2026-10-10T12:00:00Z',
      };

      final msg = ProjectMessage.fromJson(json);
      expect(msg.id, 'msg-v1');
      expect(msg.message, isEmpty);
      expect(msg.hasAttachment, isTrue);
      expect(msg.isVoiceMessage, isTrue);
      expect(msg.attachmentContentType, 'audio/webm');
      expect(msg.attachmentSize, 45678);
    });
  });
}
