/// Represents the user's profile data stored in Firestore `users/{uid}`.
///
/// This model maps to the schema defined in DATA_ARCHITECTURE.md.
/// Phase 3 fields: id, name, email, mobile, role, createdAt.
/// Phase 4 additions: qualification, dateOfBirth, address, companyName,
/// collegeName, proofDocument, updatedAt.
class UserProfile {
  /// Firebase Auth UID — also the Firestore document ID.
  final String id;

  /// User's display name.
  final String name;

  /// User's email address (denormalized from Firebase Auth for queries).
  final String email;

  /// User's mobile phone number.
  final String mobile;

  /// User role: 'CLIENT' or 'DRAUGHTSMAN'.
  /// Set once at registration. Cannot be modified by the user.
  final String role;

  /// Timestamp when the profile was created.
  final DateTime? createdAt;

  // ──────────────────────────────────────────
  // PHASE 4 — Optional profile fields
  // Per DATA_ARCHITECTURE.md: role-specific, user-editable
  // ──────────────────────────────────────────

  /// Professional qualification (DRAUGHTSMAN only).
  final String? qualification;

  /// User's date of birth (all roles, optional).
  final DateTime? dateOfBirth;

  /// User's address (all roles, optional).
  final String? address;

  /// Company name (CLIENT only, optional).
  final String? companyName;

  /// College name (DRAUGHTSMAN only, optional).
  final String? collegeName;

  /// Proof document URL (DRAUGHTSMAN only, optional).
  /// Upload functionality deferred to Phase 10 (File Storage).
  final String? proofDocument;

  /// Timestamp when the profile was last updated.
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.role,
    this.createdAt,
    this.qualification,
    this.dateOfBirth,
    this.address,
    this.companyName,
    this.collegeName,
    this.proofDocument,
    this.updatedAt,
  });

  /// Creates a [UserProfile] from a Map (API response).
  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      mobile: data['mobile'] as String? ?? '',
      role: data['role'] as String? ?? '',
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'])
          : null,
      qualification: data['qualification'] as String?,
      dateOfBirth: data['date_of_birth'] != null ? DateTime.tryParse(data['date_of_birth']) : null,
      address: data['address'] as String?,
      companyName: data['company_name'] as String?,
      collegeName: data['college_name'] as String?,
      proofDocument: data['proof_document'] as String?,
      updatedAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at'])
          : null,
    );
  }

  /// Converts this [UserProfile] to a Map for API writes.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'role': role,
    };
  }

  /// Returns a Map of only the user-editable fields for profile updates.
  Map<String, dynamic> toEditableFieldsMap() {
    final map = <String, dynamic>{
      'name': name,
      'mobile': mobile,
    };
    if (qualification != null) map['qualification'] = qualification;
    if (dateOfBirth != null) map['date_of_birth'] = dateOfBirth!.toIso8601String();
    if (address != null) map['address'] = address;
    if (companyName != null) map['company_name'] = companyName;
    if (collegeName != null) map['college_name'] = collegeName;
    return map;
  }

  /// Creates a copy of this [UserProfile] with the given fields replaced.
  UserProfile copyWith({
    String? name,
    String? mobile,
    String? qualification,
    DateTime? dateOfBirth,
    String? address,
    String? companyName,
    String? collegeName,
    String? proofDocument,
  }) {
    return UserProfile(
      id: id,
      email: email,
      role: role,
      createdAt: createdAt,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      qualification: qualification ?? this.qualification,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      companyName: companyName ?? this.companyName,
      collegeName: collegeName ?? this.collegeName,
      proofDocument: proofDocument ?? this.proofDocument,
      updatedAt: updatedAt,
    );
  }
}
