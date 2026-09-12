/// Represents the user's profile data stored in Cloudflare D1 `users` table.
///
/// This model maps to the schema defined in DATA_ARCHITECTURE.md.
/// Phase 3 fields: id, name, email, mobile, role, created_at.
/// Phase 4 additions: qualification, dateOfBirth, address, companyName,
/// collegeName, proofDocument, updated_at.
class UserProfile {
  /// Firebase Auth UID — also the D1 id.
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

  /// Creates a [UserProfile] from a JSON map.
  factory UserProfile.fromJson(Map<String, dynamic> data) {
    return UserProfile(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      mobile: data['mobile'] as String? ?? '',
      role: data['role'] as String? ?? '',
      createdAt: data['created_at'] != null ? DateTime.parse(data['created_at']) : null,
      qualification: data['qualification'] as String?,
      dateOfBirth: data['dateOfBirth'] != null ? DateTime.parse(data['dateOfBirth']) : null,
      address: data['address'] as String?,
      companyName: data['companyName'] as String?,
      collegeName: data['collegeName'] as String?,
      proofDocument: data['proofDocument'] as String?,
      updatedAt: data['updated_at'] != null ? DateTime.parse(data['updated_at']) : null,
    );
  }

  /// Converts this [UserProfile] to a JSON Map for API writes.
  Map<String, dynamic> toJson() {
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
    if (dateOfBirth != null) map['dateOfBirth'] = dateOfBirth!.toIso8601String();
    if (address != null) map['address'] = address;
    if (companyName != null) map['companyName'] = companyName;
    if (collegeName != null) map['collegeName'] = collegeName;
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
