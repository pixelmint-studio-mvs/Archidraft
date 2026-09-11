/// Enum representing the user roles in ARCHI DRAFT.
///
/// Ref: docs/01_project/USER_ROLES.md
/// - CLIENT: Project owner who submits and reviews work.
/// - DRAUGHTSMAN: Professional executing the architectural drafting.
/// - ADMIN: Platform administrator (backend-controlled, cannot self-create).
///
/// STUDENT is POST-MVP and not included here.
enum UserRole {
  client,
  draughtsman,
  admin;

  /// Converts a Firestore role string to a [UserRole] enum.
  ///
  /// Returns `null` if the string does not match any known role.
  static UserRole? fromString(String? role) {
    switch (role?.toUpperCase()) {
      case 'CLIENT':
        return UserRole.client;
      case 'DRAUGHTSMAN':
        return UserRole.draughtsman;
      case 'ADMIN':
        return UserRole.admin;
      default:
        return null;
    }
  }

  /// Converts this [UserRole] to its Firestore string representation.
  String toFirestoreString() {
    switch (this) {
      case UserRole.client:
        return 'CLIENT';
      case UserRole.draughtsman:
        return 'DRAUGHTSMAN';
      case UserRole.admin:
        return 'ADMIN';
    }
  }

  /// User-facing display name for this role.
  String get displayName {
    switch (this) {
      case UserRole.client:
        return 'Client';
      case UserRole.draughtsman:
        return 'Draughtsman';
      case UserRole.admin:
        return 'Administrator';
    }
  }
}
