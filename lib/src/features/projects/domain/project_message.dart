import '../../../shared/utils/date_parser.dart';

/// Domain model representing a message in the Project Collaboration Hub.
///
/// Ref: REFERENCE DESIGN/stitch_draughtsman_studio_os/collaboration_hub
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
  final String? attachmentContentType;
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
    String? attachmentContentType,
    String? attachmentType,
    required this.createdAt,
  }) : attachmentContentType = attachmentContentType ?? attachmentType;

  String? get attachmentType => attachmentContentType;

  bool get hasAttachment => attachmentFileId != null && attachmentFileId!.isNotEmpty;

  bool get isVoiceMessage {
    final lowerMsg = message.toLowerCase();
    if (lowerMsg.contains('voice note')) {
      return true;
    }
    if (!hasAttachment) {
      return false;
    }
    final ct = attachmentContentType?.toLowerCase() ?? '';
    if (ct.startsWith('audio/')) return true;
    final name = (attachmentName ?? '').toLowerCase();
    if (name.startsWith('voice_') ||
        name.startsWith('voice-') ||
        name.contains('voice_recording') ||
        name.contains('voice_note') ||
        name.startsWith('audio_')) {
      return true;
    }
    return name.endsWith('.webm') ||
        name.endsWith('.m4a') ||
        name.endsWith('.mp3') ||
        name.endsWith('.wav') ||
        name.endsWith('.aac') ||
        name.endsWith('.ogg');
  }

  bool get isVoiceNote => isVoiceMessage;

  bool get hasDocumentAttachment {
    if (!hasAttachment && attachmentName == null) return false;
    final ct = attachmentContentType?.toLowerCase() ?? '';
    if (ct.startsWith('audio/')) return false;
    final name = (attachmentName ?? '').toLowerCase();
    if (name.endsWith('.webm') ||
        name.endsWith('.m4a') ||
        name.endsWith('.mp3') ||
        name.endsWith('.wav') ||
        name.endsWith('.aac') ||
        name.endsWith('.ogg') ||
        name.startsWith('voice_note_')) {
      return false;
    }
    return true;
  }

  bool get isImageAttachment {
    if (!hasAttachment) return false;
    final ct = attachmentContentType?.toLowerCase() ?? '';
    if (ct.startsWith('image/')) return true;
    final name = (attachmentName ?? '').toLowerCase();
    return name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.webp') ||
        name.endsWith('.gif') ||
        name.endsWith('.bmp') ||
        name.endsWith('.avif');
  }

  bool get isCadAttachment {
    if (!hasAttachment) return false;
    final ct = attachmentContentType?.toLowerCase() ?? '';
    if (ct == 'application/acad' ||
        ct == 'application/dxf' ||
        ct == 'image/vnd.dwg' ||
        ct == 'image/vnd.dxf') {
      return true;
    }
    final name = (attachmentName ?? '').toLowerCase();
    return name.endsWith('.dwg') || name.endsWith('.dxf');
  }

  bool get isDxfAttachment {
    if (!hasAttachment) return false;
    final name = (attachmentName ?? '').toLowerCase();
    final ct = attachmentContentType?.toLowerCase() ?? '';
    return name.endsWith('.dxf') ||
        ct == 'application/dxf' ||
        ct == 'image/vnd.dxf';
  }

  bool get isDwgAttachment {
    if (!hasAttachment) return false;
    final name = (attachmentName ?? '').toLowerCase();
    final ct = attachmentContentType?.toLowerCase() ?? '';
    return name.endsWith('.dwg') ||
        ct == 'application/acad' ||
        ct == 'image/vnd.dwg';
  }

  bool get isFromEngineer => senderRole == 'ENGINEER' || senderRole == 'CLIENT';

  factory ProjectMessage.fromJson(Map<String, dynamic> json) {
    final rawTs = json['created_at'];
    DateTime parsedDate;
    if (rawTs is String) {
      parsedDate = DateParser.parse(rawTs) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final rawRole = json['sender_role']?.toString().toUpperCase() ?? 'ENGINEER';
    final normalizedRole = rawRole == 'CLIENT' ? 'ENGINEER' : rawRole;
    final contentType = json['attachment_content_type']?.toString() ??
        json['attachment_type']?.toString();

    return ProjectMessage(
      id: json['id']?.toString() ?? '',
      projectId: json['project_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? 'User',
      senderRole: normalizedRole,
      message: json['message']?.toString() ?? '',
      attachmentFileId: json['attachment_file_id']?.toString(),
      attachmentName: json['attachment_name']?.toString(),
      attachmentSize: json['attachment_size'] is int
          ? json['attachment_size'] as int
          : (json['attachment_size'] != null ? int.tryParse(json['attachment_size'].toString()) : null),
      attachmentContentType: contentType,
      createdAt: parsedDate,
    );
  }
}
