import 'package:cloud_firestore/cloud_firestore.dart';

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
///   correctionRound, submittedAt, completedAt
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

  /// Timestamp when the project was completed. Set in later phases.
  final DateTime? completedAt;

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
  });

  /// Parses the [status] string into a [ProjectStatus] enum.
  ProjectStatus? get projectStatus => ProjectStatus.fromString(status);

  /// Parses the [drawingType] string into a [DrawingType] enum.
  DrawingType? get drawingTypeEnum => DrawingType.fromString(drawingType);

  /// Whether this project can be edited by the client.
  bool get isEditable => projectStatus?.isEditable ?? false;

  /// Creates a [Project] from a Firestore document snapshot.
  factory Project.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Project(
      projectId: doc.id,
      projectName: data['projectName'] as String? ?? '',
      projectAddress: data['projectAddress'] as String? ?? '',
      drawingName: data['drawingName'] as String? ?? '',
      drawingType: data['drawingType'] as String? ?? '',
      projectArea: (data['projectArea'] as num?)?.toDouble(),
      estimatedAmount: (data['estimatedAmount'] as num?)?.toDouble(),
      clientId: data['clientId'] as String? ?? '',
      assignedDraughtsmanId: data['assignedDraughtsmanId'] as String?,
      currentAssignmentId: data['currentAssignmentId'] as String?,
      status: data['status'] as String? ?? 'DRAFT',
      correctionRound: data['correctionRound'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts this [Project] to a Firestore map for initial creation.
  ///
  /// Uses [FieldValue.serverTimestamp()] for `createdAt`.
  /// Sets `status` to DRAFT and `correctionRound` to 0.
  Map<String, dynamic> toFirestoreCreate() {
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
      'createdAt': FieldValue.serverTimestamp(),
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
    );
  }
}
