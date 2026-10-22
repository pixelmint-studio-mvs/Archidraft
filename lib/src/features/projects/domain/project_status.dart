/// Enum representing the locked project statuses in ARCHI DRAFT.
///
/// Ref: docs/02_architecture/STATE_MACHINES.md
/// Supported roles: Engineer, Draughtsman, Student, Admin.
/// Replaces the legacy CLIENT review concept with the canonical Engineer review state.
enum ProjectStatus {
  draft,
  submitted,
  waitingAssignment,
  waitingAcceptance,
  inProgress,
  underEngineerReview,
  completed,
  cancelled;

  /// Backward-compatibility alias for legacy code/tests.
  static const ProjectStatus underClientReview = ProjectStatus.underEngineerReview;

  /// Converts a backend/database status string to a [ProjectStatus] enum.
  ///
  /// Supports both canonical [UNDER_ENGINEER_REVIEW] and legacy [UNDER_CLIENT_REVIEW].
  /// Returns `null` if the string does not match any known status.
  static ProjectStatus? fromString(String? status) {
    switch (status) {
      case 'DRAFT':
        return ProjectStatus.draft;
      case 'SUBMITTED':
        return ProjectStatus.submitted;
      case 'WAITING_ASSIGNMENT':
        return ProjectStatus.waitingAssignment;
      case 'WAITING_ACCEPTANCE':
        return ProjectStatus.waitingAcceptance;
      case 'IN_PROGRESS':
        return ProjectStatus.inProgress;
      case 'UNDER_ENGINEER_REVIEW':
      case 'UNDER_CLIENT_REVIEW':
        return ProjectStatus.underEngineerReview;
      case 'COMPLETED':
        return ProjectStatus.completed;
      case 'CANCELLED':
        return ProjectStatus.cancelled;
      default:
        return null;
    }
  }

  /// Converts this [ProjectStatus] to its canonical Worker/database string representation.
  String toFirestoreString() {
    switch (this) {
      case ProjectStatus.draft:
        return 'DRAFT';
      case ProjectStatus.submitted:
        return 'SUBMITTED';
      case ProjectStatus.waitingAssignment:
        return 'WAITING_ASSIGNMENT';
      case ProjectStatus.waitingAcceptance:
        return 'WAITING_ACCEPTANCE';
      case ProjectStatus.inProgress:
        return 'IN_PROGRESS';
      case ProjectStatus.underEngineerReview:
        return 'UNDER_ENGINEER_REVIEW';
      case ProjectStatus.completed:
        return 'COMPLETED';
      case ProjectStatus.cancelled:
        return 'CANCELLED';
    }
  }

  /// User-facing display name for this status.
  String get displayName {
    switch (this) {
      case ProjectStatus.draft:
        return 'Draft';
      case ProjectStatus.submitted:
        return 'Submitted';
      case ProjectStatus.waitingAssignment:
        return 'Waiting Assignment';
      case ProjectStatus.waitingAcceptance:
        return 'Waiting Acceptance';
      case ProjectStatus.inProgress:
        return 'In Progress';
      case ProjectStatus.underEngineerReview:
        return 'Under Engineer Review';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Whether this status allows engineer editing of project fields.
  bool get isEditable => this == ProjectStatus.draft;

  /// Whether this status is a terminal state.
  bool get isTerminal =>
      this == ProjectStatus.completed || this == ProjectStatus.cancelled;
}
