class DrawingVersion {
  final String id;
  final String projectId;
  final String fileId;
  final int versionNumber;
  final String uploadedBy;
  final String? originalName;
  final String? sanitizedName;
  final int size;
  final DateTime? createdAt;

  const DrawingVersion({
    required this.id,
    required this.projectId,
    required this.fileId,
    required this.versionNumber,
    required this.uploadedBy,
    this.originalName,
    this.sanitizedName,
    this.size = 0,
    this.createdAt,
  });

  factory DrawingVersion.fromMap(Map<String, dynamic> data) {
    return DrawingVersion(
      id: data['id'] as String? ?? '',
      projectId: data['project_id'] as String? ?? '',
      fileId: data['file_id'] as String? ?? '',
      versionNumber: data['version_number'] as int? ?? 1,
      uploadedBy: data['uploaded_by'] as String? ?? '',
      originalName: data['original_name'] as String?,
      sanitizedName: data['sanitized_name'] as String?,
      size: data['size'] as int? ?? 0,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'])
          : null,
    );
  }
}
