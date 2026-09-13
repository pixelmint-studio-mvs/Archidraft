class ProjectFile {
  final String id;
  final String projectId;
  final String uploadedBy;
  final String originalName;
  final String sanitizedName;
  final String objectKey;
  final String contentType;
  final int size;
  final String category;
  final String status;
  final DateTime createdAt;

  ProjectFile({
    required this.id,
    required this.projectId,
    required this.uploadedBy,
    required this.originalName,
    required this.sanitizedName,
    required this.objectKey,
    required this.contentType,
    required this.size,
    required this.category,
    required this.status,
    required this.createdAt,
  });

  factory ProjectFile.fromJson(Map<String, dynamic> json) {
    return ProjectFile(
      id: json['id'],
      projectId: json['project_id'],
      uploadedBy: json['uploaded_by'],
      originalName: json['original_name'],
      sanitizedName: json['sanitized_name'],
      objectKey: json['object_key'],
      contentType: json['content_type'],
      size: json['size'],
      category: json['category'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at'] + 'Z').toLocal(),
    );
  }
}
