import 'assignment_status.dart';

class Assignment {
  final String id;
  final String projectId;
  final String draughtsmanId;
  final String status;
  final String? projectName;
  final String? projectAddress;
  final String? drawingType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Assignment({
    required this.id,
    required this.projectId,
    required this.draughtsmanId,
    required this.status,
    this.projectName,
    this.projectAddress,
    this.drawingType,
    this.createdAt,
    this.updatedAt,
  });

  AssignmentStatus? get assignmentStatus => AssignmentStatus.fromString(status);

  factory Assignment.fromMap(Map<String, dynamic> data) {
    return Assignment(
      id: data['id'] as String? ?? '',
      projectId: data['project_id'] as String? ?? '',
      draughtsmanId: data['draughtsman_id'] as String? ?? '',
      status: data['status'] as String? ?? 'PENDING',
      projectName: data['project_name'] as String?,
      projectAddress: data['project_address'] as String?,
      drawingType: data['drawing_type'] as String?,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'])
          : null,
      updatedAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'draughtsman_id': draughtsmanId,
      'status': status,
    };
  }

  Assignment copyWith({String? status}) {
    return Assignment(
      id: id,
      projectId: projectId,
      draughtsmanId: draughtsmanId,
      status: status ?? this.status,
      projectName: projectName,
      projectAddress: projectAddress,
      drawingType: drawingType,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
