/// Enum representing the locked project statuses in ARCHI DRAFT.
///
/// Ref: docs/02_architecture/STATE_MACHINES.md
/// These names and their backend string representations are IMMUTABLE.
/// Do NOT add, remove, or rename values without explicit architectural approval.
enum ProjectStatus {
  draft,
  submitted,
  waitingAssignment,
  waitingAcceptance,
  inProgress,
  underClientReview,
  completed,
  cancelled;

  /// Converts a Firestore status string to a [ProjectStatus] enum.
  ///
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
      case 'UNDER_CLIENT_REVIEW':
        return ProjectStatus.underClientReview;
      case 'COMPLETED':
        return ProjectStatus.completed;
      case 'CANCELLED':
        return ProjectStatus.cancelled;
      default:
        return null;
    }
  }

  /// Converts this [ProjectStatus] to its exact Firestore string representation.
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
      case ProjectStatus.underClientReview:
        return 'UNDER_CLIENT_REVIEW';
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
      case ProjectStatus.underClientReview:
        return 'Under Review';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Whether this status allows client editing of project fields.
  bool get isEditable => this == ProjectStatus.draft;

  /// Whether this status is a terminal state.
  bool get isTerminal =>
      this == ProjectStatus.completed || this == ProjectStatus.cancelled;
}
