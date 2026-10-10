import '../../../shared/utils/date_parser.dart';

class ProjectMessage {
  final String id;
  final String projectId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String message;
  final String? attachmentFileId;
  final String? attachmentName;
  final int? attachmentSize;
  final String? attachmentType;
  final DateTime createdAt;

  const ProjectMessage({
    required this.id,
    required this.projectId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    this.attachmentFileId,
    this.attachmentName,
    this.attachmentSize,
    this.attachmentType,
    required this.createdAt,
  });

  bool get isVoiceNote {
    if (attachmentType != null && attachmentType!.startsWith('audio/')) {
      return true;
    }
    if (attachmentName != null) {
      final lower = attachmentName!.toLowerCase();
      if (lower.endsWith('.webm') ||
          lower.endsWith('.m4a') ||
          lower.endsWith('.mp3') ||
          lower.endsWith('.wav') ||
          lower.endsWith('.ogg') ||
          lower.endsWith('.aac')) {
        return true;
      }
    }
    final lowerMsg = message.toLowerCase();
    if (lowerMsg.startsWith('voice note') || lowerMsg.contains('voice note')) {
      return true;
    }
    return false;
  }

  bool get hasDocumentAttachment {
    if (attachmentFileId == null && attachmentName == null) return false;
    final name = (attachmentName ?? '').toLowerCase();
    final isAudio = (attachmentType != null && attachmentType!.startsWith('audio/')) ||
        name.endsWith('.webm') ||
        name.endsWith('.m4a') ||
        name.endsWith('.mp3') ||
        name.endsWith('.wav') ||
        name.endsWith('.ogg') ||
        name.endsWith('.aac');
    return !isAudio;
  }

  factory ProjectMessage.fromJson(Map<String, dynamic> json) {
    return ProjectMessage(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: (json['sender_name'] as String?) ?? 'User',
      senderRole: (json['sender_role'] as String?) ?? 'MEMBER',
      message: (json['message'] as String?) ?? '',
      attachmentFileId: json['attachment_file_id'] as String?,
      attachmentName: json['attachment_name'] as String?,
      attachmentSize: json['attachment_size'] as int?,
      attachmentType: json['attachment_type'] as String?,
      createdAt: DateParser.parse(json['created_at']) ?? DateTime.now(),
    );
  }
}
