import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the user's profile data stored in Firestore `users/{uid}`.
///
/// This model maps to the schema defined in DATA_ARCHITECTURE.md.
/// Only fields required for Phase 3 (Authentication) are included.
/// Optional profile fields (qualification, dateOfBirth, address, etc.)
/// will be added in Phase 4 (User Profiles).
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

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.role,
    this.createdAt,
  });

  /// Creates a [UserProfile] from a Firestore document snapshot.
  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserProfile(
      id: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      mobile: data['mobile'] as String? ?? '',
      role: data['role'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts this [UserProfile] to a Map for Firestore writes.
  ///
  /// Uses [FieldValue.serverTimestamp()] for `createdAt` to ensure
  /// the timestamp is set by the server, not the client.
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
