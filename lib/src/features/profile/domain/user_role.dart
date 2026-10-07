/// Enum representing the user roles in ARCHI DRAFT.
///
/// Ref: docs/01_project/USER_ROLES.md
/// - ENGINEER: Professional who submits and reviews structural drawings.
/// - DRAUGHTSMAN: Professional executing the architectural drafting.
/// - STUDENT: Student role for learning.
/// - ADMIN: Platform administrator (backend-controlled, cannot self-create).
enum UserRole {
  engineer,
  draughtsman,
  student,
  admin;

  /// Converts a Firestore role string to a [UserRole] enum.
  ///
  /// Returns `null` if the string does not match any known role.
  static UserRole? fromString(String? role) {
    switch (role?.toUpperCase()) {
      case 'ENGINEER':
        return UserRole.engineer;
      case 'DRAUGHTSMAN':
        return UserRole.draughtsman;
      case 'STUDENT':
        return UserRole.student;
      case 'ADMIN':
        return UserRole.admin;
      default:
        return null;
    }
  }

  /// Converts this [UserRole] to its Firestore string representation.
  String toFirestoreString() {
    switch (this) {
      case UserRole.engineer:
        return 'ENGINEER';
      case UserRole.draughtsman:
        return 'DRAUGHTSMAN';
      case UserRole.student:
        return 'STUDENT';
      case UserRole.admin:
        return 'ADMIN';
    }
  }

  /// User-facing display name for this role.
  String get displayName {
    switch (this) {
      case UserRole.engineer:
        return 'Engineer';
      case UserRole.draughtsman:
        return 'Draughtsman';
      case UserRole.student:
        return 'Student';
      case UserRole.admin:
        return 'Administrator';
    }
  }
}
