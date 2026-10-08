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

  ProjectMessage({
    required this.id,
    required this.projectId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    this.attachmentFileId,
    this.attachmentName,
    this.attachmentSize,
    this.attachmentContentType,
    required this.createdAt,
  });

  bool get hasAttachment => attachmentFileId != null && attachmentFileId!.isNotEmpty;

  bool get isFromEngineer => senderRole == 'ENGINEER' || senderRole == 'CLIENT';

  factory ProjectMessage.fromJson(Map<String, dynamic> json) {
    final rawTs = json['created_at']?.toString() ?? '';
    DateTime parsedDate;
    if (rawTs.endsWith('Z')) {
      parsedDate = DateTime.tryParse(rawTs)?.toLocal() ?? DateTime.now();
    } else {
      parsedDate = DateTime.tryParse('${rawTs}Z')?.toLocal() ?? DateTime.now();
    }

    final rawRole = json['sender_role']?.toString().toUpperCase() ?? 'ENGINEER';
    final normalizedRole = rawRole == 'CLIENT' ? 'ENGINEER' : rawRole;

    return ProjectMessage(
      id: json['id']?.toString() ?? '',
      projectId: json['project_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? 'User',
      senderRole: normalizedRole,
      message: json['message']?.toString() ?? '',
      attachmentFileId: json['attachment_file_id']?.toString(),
      attachmentName: json['attachment_name']?.toString(),
      attachmentSize: json['attachment_size'] is int ? json['attachment_size'] as int : null,
      attachmentContentType: json['attachment_content_type']?.toString(),
      createdAt: parsedDate,
    );
  }
}
