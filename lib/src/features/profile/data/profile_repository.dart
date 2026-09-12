import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/domain/user_profile.dart';

/// Repository for Firestore profile CRUD operations.
///
/// Separated from [AuthRepository] for clean domain separation.
/// Profile updates are "Simple Operations" per SYSTEM_ARCHITECTURE.md,
/// using direct Firestore SDK writes protected by Security Rules.
class ProfileRepository {
  final FirebaseFirestore _firestore;

  ProfileRepository(this._firestore);

  /// Reference to the `users` collection.
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  /// Fetches the user profile for the given [uid].
  ///
  /// Returns `null` if the document does not exist.
  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromFirestore(doc);
  }

  /// Streams the user profile for real-time updates.
  ///
  /// Emits `null` if the document does not exist.
  Stream<UserProfile?> watchProfile(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  /// Updates the user profile with only the editable fields.
  ///
  /// Uses [UserProfile.toEditableFieldsMap()] which excludes
  /// immutable fields (id, email, role, createdAt).
  /// Security Rules enforce this server-side as well.
  Future<void> updateProfile(UserProfile profile) async {
    await _usersRef.doc(profile.id).update(profile.toEditableFieldsMap());
  }

  /// Checks if a profile exists for the given [uid].
  Future<bool> profileExists(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    return doc.exists;
  }

  /// Fetches all users with the DRAUGHTSMAN role.
  /// Used by Studio Admin for assignment.
  Future<List<UserProfile>> getDraughtsmen() async {
    final query = await _usersRef.where('role', isEqualTo: 'DRAUGHTSMAN').get();
    return query.docs.map((doc) => UserProfile.fromFirestore(doc)).toList();
  }
}
