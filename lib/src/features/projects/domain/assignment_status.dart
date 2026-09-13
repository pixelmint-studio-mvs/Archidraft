enum AssignmentStatus {
  pending,
  accepted,
  rejected,
  replaced,
  completed;

  static AssignmentStatus? fromString(String? status) {
    switch (status) {
      case 'PENDING':
        return AssignmentStatus.pending;
      case 'ACCEPTED':
        return AssignmentStatus.accepted;
      case 'REJECTED':
        return AssignmentStatus.rejected;
      case 'REPLACED':
        return AssignmentStatus.replaced;
      case 'COMPLETED':
        return AssignmentStatus.completed;
      default:
        return null;
    }
  }

  String toFirestoreString() {
    switch (this) {
      case AssignmentStatus.pending:
        return 'PENDING';
      case AssignmentStatus.accepted:
        return 'ACCEPTED';
      case AssignmentStatus.rejected:
        return 'REJECTED';
      case AssignmentStatus.replaced:
        return 'REPLACED';
      case AssignmentStatus.completed:
        return 'COMPLETED';
    }
  }

  String get displayName {
    switch (this) {
      case AssignmentStatus.pending:
        return 'Pending';
      case AssignmentStatus.accepted:
        return 'Accepted';
      case AssignmentStatus.rejected:
        return 'Rejected';
      case AssignmentStatus.replaced:
        return 'Replaced';
      case AssignmentStatus.completed:
        return 'Completed';
    }
  }
}
