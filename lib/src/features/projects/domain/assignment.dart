import 'assignment_status.dart';
import '../../../shared/utils/date_parser.dart';

/// Represents a draughtsman assignment, optionally enriched with
/// joined project data when fetched via GET /api/assignments.
class Assignment {
  final String id;
  final String projectId;
  final String draughtsmanId;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined project fields (populated by GET /api/assignments JOIN query).
  // Only fields that exist in the projects schema (0001_schema.sql) are included.
  final String? projectName;
  final String? projectAddress;
  final String? drawingName;
  final String? drawingType;
  final String? projectArea;   // TEXT in schema
  final String? projectStatus;
  final int? correctionRound;  // from 0004_corrections.sql
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? assignedAt;
  final DateTime? rejectedAt;
  final DateTime? cancelledAt;

  const Assignment({
    required this.id,
    required this.projectId,
    required this.draughtsmanId,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.projectName,
    this.projectAddress,
    this.drawingName,
    this.drawingType,
    this.projectArea,
    this.projectStatus,
    this.correctionRound,
    this.submittedAt,
    this.approvedAt,
    this.assignedAt,
    this.rejectedAt,
    this.cancelledAt,
  });

  AssignmentStatus? get assignmentStatus => AssignmentStatus.fromString(status);

  /// Returns a display name for the project — uses projectName if available,
  /// falls back to a truncated projectId for clarity.
  String get displayProjectName =>
      (projectName != null && projectName!.isNotEmpty)
          ? projectName!
          : 'Project ${projectId.length >= 8 ? projectId.substring(0, 8) : projectId}';

  /// Whether this assignment is part of a correction cycle.
  bool get isRevision =>
      rejectedAt != null && projectStatus != 'COMPLETED' && projectStatus != 'CANCELLED';

  factory Assignment.fromMap(Map<String, dynamic> data) {
    return Assignment(
      id: data['id'] as String? ?? '',
      projectId: data['project_id'] as String? ?? '',
      draughtsmanId: data['draughtsman_id'] as String? ?? '',
      status: data['status'] as String? ?? 'PENDING',
      createdAt: DateParser.parse(data['created_at']),
      updatedAt: DateParser.parse(data['updated_at']),
      projectName: data['project_name'] as String?,
      projectAddress: data['project_address'] as String?,
      drawingName: data['drawing_name'] as String?,
      drawingType: data['drawing_type'] as String?,
      projectArea: data['project_area'] as String?,
      projectStatus: data['project_status'] as String?,
      correctionRound: data['correction_round'] as int?,
      submittedAt: DateParser.parse(data['submitted_at']),
      approvedAt: DateParser.parse(data['approved_at']),
      assignedAt: DateParser.parse(data['assigned_at']),
      rejectedAt: DateParser.parse(data['rejected_at']),
      cancelledAt: DateParser.parse(data['cancelled_at']),
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
      createdAt: createdAt,
      updatedAt: updatedAt,
      projectName: projectName,
      projectAddress: projectAddress,
      drawingName: drawingName,
      drawingType: drawingType,
      projectArea: projectArea,
      projectStatus: projectStatus,
      correctionRound: correctionRound,
      submittedAt: submittedAt,
      approvedAt: approvedAt,
      assignedAt: assignedAt,
      rejectedAt: rejectedAt,
      cancelledAt: cancelledAt,
    );
  }
}
