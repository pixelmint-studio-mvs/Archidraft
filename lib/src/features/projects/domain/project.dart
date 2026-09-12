

import 'drawing_type.dart';
import 'project_status.dart';

/// Represents a project in the ARCHI DRAFT system.
///
/// Maps to the `projects/{projectId}` Firestore collection.
/// Ref: docs/02_architecture/DATA_ARCHITECTURE.md
///
/// Field classifications:
/// - Immutable: projectId, clientId, createdAt
/// - Server-controlled: status, assignedDraughtsmanId, currentAssignmentId,
///   correctionRound, submittedAt, completedAt, approvedAt, assignedAt,
///   cancelledAt, rejectionReason, draughtsmanName, draughtsmanId, lastActionId
/// - Client-editable (when status=DRAFT): projectName, projectAddress,
///   drawingName, drawingType, projectArea, estimatedAmount
class Project {
  /// Firestore document ID.
  final String projectId;

  /// Name/title of the project.
  final String projectName;

  /// Physical address/location of the project.
  final String projectAddress;

  /// Name of the drawing requested.
  final String drawingName;

  /// Type of drawing (e.g., Floor Plan, Elevation).
  final String drawingType;

  /// Project area in square feet.
  final double? projectArea;

  /// Client's budget estimate (optional).
  final double? estimatedAmount;

  /// UID of the Client who owns this project. Immutable, derived from auth.
  final String clientId;

  /// UID of the assigned Draughtsman. Server-controlled.
  /// Note: The backend writes this as both `draughtsmanId` and
  /// `assignedDraughtsmanId` depending on the Cloud Function.
  /// [fromFirestore] reads whichever is present.
  final String? assignedDraughtsmanId;

  /// ID of the current active assignment. Server-controlled.
  final String? currentAssignmentId;

  /// Current project status string (matches ProjectStatus enum).
  final String status;

  /// Number of correction rounds used. Server-controlled, starts at 0.
  final int correctionRound;

  /// Timestamp when the project was created. Immutable.
  final DateTime? createdAt;

  /// Timestamp when the project was submitted. Set by submitProject().
  final DateTime? submittedAt;

  /// Timestamp when the project was completed. Set by approveFinal().
  final DateTime? completedAt;

  /// Timestamp when the project was approved by admin. Set by approveProject().
  final DateTime? approvedAt;

  /// Timestamp when a draughtsman was assigned. Set by assignDraughtsman().
  final DateTime? assignedAt;

  /// Timestamp when the project was cancelled. Set by cancelProject().
  final DateTime? cancelledAt;

  /// Reason provided by admin when rejecting a project. Set by rejectProject().
  final String? rejectionReason;

  /// Display name of the assigned draughtsman. Set by assignDraughtsman().
  final String? draughtsmanName;

  /// Last processed action ID for idempotency. Server-controlled.
  final String? lastActionId;

  const Project({
    required this.projectId,
    required this.projectName,
    required this.projectAddress,
    required this.drawingName,
    required this.drawingType,
    this.projectArea,
    this.estimatedAmount,
    required this.clientId,
    this.assignedDraughtsmanId,
    this.currentAssignmentId,
    required this.status,
    this.correctionRound = 0,
    this.createdAt,
    this.submittedAt,
    this.completedAt,
    this.approvedAt,
    this.assignedAt,
    this.cancelledAt,
    this.rejectionReason,
    this.draughtsmanName,
    this.lastActionId,
  });

  /// Parses the [status] string into a [ProjectStatus] enum.
  ProjectStatus? get projectStatus => ProjectStatus.fromString(status);

  /// Parses the [drawingType] string into a [DrawingType] enum.
  DrawingType? get drawingTypeEnum => DrawingType.fromString(drawingType);

  /// Whether this project can be edited by the client.
  bool get isEditable => projectStatus?.isEditable ?? false;

  /// Whether this project can be cancelled by the client.
  /// Only DRAFT and SUBMITTED projects are cancellable per cancelProject().
  bool get isCancellable {
    final s = projectStatus;
    return s == ProjectStatus.draft || s == ProjectStatus.submitted;
  }

  /// Creates a [Project] from a JSON object (Cloudflare backend response).
  factory Project.fromJson(Map<String, dynamic> data) {
    return Project(
      projectId: data['id'] ?? data['projectId'] ?? '',
      projectName: data['projectName'] as String? ?? '',
      projectAddress: data['projectAddress'] as String? ?? '',
      drawingName: data['drawingName'] as String? ?? '',
      drawingType: data['drawingType'] as String? ?? '',
      projectArea: (data['projectArea'] as num?)?.toDouble(),
      estimatedAmount: (data['estimatedAmount'] as num?)?.toDouble(),
      clientId: data['clientId'] as String? ?? '',
      assignedDraughtsmanId: data['assignedDraughtsmanId'] as String?
          ?? data['draughtsmanId'] as String?,
      currentAssignmentId: data['currentAssignmentId'] as String?,
      status: data['status'] as String? ?? 'DRAFT',
      correctionRound: data['correctionRound'] as int? ?? 0,
      createdAt: data['createdAt'] != null ? DateTime.tryParse(data['createdAt']) : null,
      submittedAt: data['submittedAt'] != null ? DateTime.tryParse(data['submittedAt']) : null,
      completedAt: data['completedAt'] != null ? DateTime.tryParse(data['completedAt']) : null,
      approvedAt: data['approvedAt'] != null ? DateTime.tryParse(data['approvedAt']) : null,
      assignedAt: data['assignedAt'] != null ? DateTime.tryParse(data['assignedAt']) : null,
      cancelledAt: data['cancelledAt'] != null ? DateTime.tryParse(data['cancelledAt']) : null,
      rejectionReason: data['rejectionReason'] as String?,
      draughtsmanName: data['draughtsmanName'] as String?,
      lastActionId: data['lastActionId'] as String?,
    );
  }

  /// Converts this [Project] to a map for initial creation via REST API.
  ///
  /// Sets `status` to DRAFT and `correctionRound` to 0.
  Map<String, dynamic> toJsonCreate() {
    return {
      'projectName': projectName,
      'projectAddress': projectAddress,
      'drawingName': drawingName,
      'drawingType': drawingType,
      'projectArea': projectArea,
      'estimatedAmount': estimatedAmount,
      'clientId': clientId,
      'status': 'DRAFT',
      'correctionRound': 0,
    };
  }

  /// Returns a Map of only the client-editable fields for draft updates.
  ///
  /// Does NOT include immutable or server-controlled fields.
  Map<String, dynamic> toEditableFieldsMap() {
    return {
      'projectName': projectName,
      'projectAddress': projectAddress,
      'drawingName': drawingName,
      'drawingType': drawingType,
      'projectArea': projectArea,
      'estimatedAmount': estimatedAmount,
    };
  }

  /// Creates a copy with the given fields replaced.
  Project copyWith({
    String? projectName,
    String? projectAddress,
    String? drawingName,
    String? drawingType,
    double? projectArea,
    double? estimatedAmount,
    String? status,
  }) {
    return Project(
      projectId: projectId,
      projectName: projectName ?? this.projectName,
      projectAddress: projectAddress ?? this.projectAddress,
      drawingName: drawingName ?? this.drawingName,
      drawingType: drawingType ?? this.drawingType,
      projectArea: projectArea ?? this.projectArea,
      estimatedAmount: estimatedAmount ?? this.estimatedAmount,
      clientId: clientId,
      assignedDraughtsmanId: assignedDraughtsmanId,
      currentAssignmentId: currentAssignmentId,
      status: status ?? this.status,
      correctionRound: correctionRound,
      createdAt: createdAt,
      submittedAt: submittedAt,
      completedAt: completedAt,
      approvedAt: approvedAt,
      assignedAt: assignedAt,
      cancelledAt: cancelledAt,
      rejectionReason: rejectionReason,
      draughtsmanName: draughtsmanName,
      lastActionId: lastActionId,
    );
  }
}
