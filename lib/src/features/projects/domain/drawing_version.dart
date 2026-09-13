import 'project_file.dart';

class DrawingVersion {
  final String id;
  final String projectId;
  final String fileId;
  final int versionNumber;
  final String uploadedBy;
  final String? correctionId;
  final DateTime createdAt;
  
  // Joined fields from files table
  final String? originalName;
  final String? sanitizedName;
  final int? size;

  const DrawingVersion({
    required this.id,
    required this.projectId,
    required this.fileId,
    required this.versionNumber,
    required this.uploadedBy,
    this.correctionId,
    required this.createdAt,
    this.originalName,
    this.sanitizedName,
    this.size,
  });

  factory DrawingVersion.fromJson(Map<String, dynamic> json) {
    return DrawingVersion(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      fileId: json['file_id'] as String,
      versionNumber: json['version_number'] as int,
      uploadedBy: json['uploaded_by'] as String,
      correctionId: json['correction_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      originalName: json['original_name'] as String?,
      sanitizedName: json['sanitized_name'] as String?,
      size: json['size'] as int?,
    );
  }
}
