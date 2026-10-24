import 'package:flutter/foundation.dart';

@immutable
class ProjectComment {
  final String id;
  final String projectId;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String content;
  final String? attachmentName;
  final String? attachmentSize;
  final String? attachmentType;
  final DateTime createdAt;

  const ProjectComment({
    required this.id,
    required this.projectId,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.content,
    this.attachmentName,
    this.attachmentSize,
    this.attachmentType,
    required this.createdAt,
  });

  factory ProjectComment.fromJson(Map<String, dynamic> json) {
    return ProjectComment(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String,
      authorRole: json['author_role'] as String,
      content: json['content'] as String,
      attachmentName: json['attachment_name'] as String?,
      attachmentSize: json['attachment_size'] as String?,
      attachmentType: json['attachment_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
