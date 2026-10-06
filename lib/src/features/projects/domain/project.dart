import '../../../shared/utils/date_parser.dart';
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

  /// Identifier for the last critical action performed on this project.
  /// Used for idempotency.
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
    this.lastActionId,
  });

  /// Parses the [status] string into a [ProjectStatus] enum.
  ProjectStatus? get projectStatus => ProjectStatus.fromString(status);

  /// Parses the [drawingType] string into a [DrawingType] enum.
  DrawingType? get drawingTypeEnum => DrawingType.fromString(drawingType);

  /// Whether this project can be edited by the client.
  bool get isEditable => projectStatus?.isEditable ?? false;

  /// Creates a [Project] from a Map (API response).
  factory Project.fromMap(Map<String, dynamic> data) {
    return Project(
      projectId: data['id'] as String? ?? '',
      projectName: data['project_name'] as String? ?? '',
      projectAddress: data['project_address'] as String? ?? '',
      drawingName: data['drawing_name'] as String? ?? '',
      drawingType: data['drawing_type'] as String? ?? '',
      // project_area is TEXT in D1 schema — D1 returns it as a JSON string
      // (e.g. "1500.0"). Parse safely from String or num.
      projectArea: _parseDouble(data['project_area']),
      // estimated_amount is REAL in D1 — returned as JSON number when set,
      // null otherwise. Also guard against accidental string representation.
      estimatedAmount: _parseDouble(data['estimated_amount']),

      clientId: data['client_id'] as String? ?? '',
      assignedDraughtsmanId: data['draughtsman_id'] as String?,
      currentAssignmentId: data['current_assignment_id'] as String?,
      status: data['status'] as String? ?? 'DRAFT',
      correctionRound: data['correction_round'] as int? ?? 0,
      createdAt: DateParser.parse(data['created_at']),
      submittedAt: DateParser.parse(data['submitted_at']),
      completedAt: DateParser.parse(data['completed_at']),
      lastActionId: data['last_action_id'] as String?,
    );
  }

  /// Converts this [Project] to a map for initial creation via API.
  Map<String, dynamic> toFirestoreCreate() {
    return {
      'project_name': projectName,
      'project_address': projectAddress,
      'drawing_name': drawingName,
      'drawing_type': drawingType,
      'project_area': projectArea,
      'estimated_amount': estimatedAmount,
      'client_id': clientId,
    };
  }

  /// Returns a Map of only the client-editable fields for draft updates.
  Map<String, dynamic> toEditableFieldsMap() {
    return {
      'project_name': projectName,
      'project_address': projectAddress,
      'drawing_name': drawingName,
      'drawing_type': drawingType,
      'project_area': projectArea,
      'estimated_amount': estimatedAmount,
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
    String? lastActionId,
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
      lastActionId: lastActionId ?? this.lastActionId,
    );
  }
}

/// Helper to safely parse a double from either a num or a String.
/// D1 sometimes returns numeric TEXT columns as JSON strings.
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    // Also remove any accidental string formatting like " sqft" just in case
    // it was already incorrectly stored in the DB (like the test fixture).
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned);
  }
  return null;
}
