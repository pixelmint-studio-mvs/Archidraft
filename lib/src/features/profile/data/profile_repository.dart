import '../../../core/network/api_client.dart';

import '../../auth/domain/user_profile.dart';

/// Repository for Firestore profile CRUD operations.
///
/// Separated from [AuthRepository] for clean domain separation.
/// Profile updates are "Simple Operations" per SYSTEM_ARCHITECTURE.md,
/// using direct Firestore SDK writes protected by Security Rules.
class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository(this._apiClient);

  /// Fetches the user profile for the given [uid].
  ///
  /// Returns `null` if the document does not exist.
  Future<UserProfile?> getProfile(String uid) async {
    try {
      final data = await _apiClient.get('/api/users/$uid');
      return UserProfile.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Updates the user profile with only the editable fields.
  Future<void> updateProfile(UserProfile profile) async {
    await _apiClient.patch(
      '/api/users/${profile.id}',
      body: profile.toEditableFieldsMap(),
    );
  }

  /// Checks if a profile exists for the given [uid].
  Future<bool> profileExists(String uid) async {
    try {
      await _apiClient.get('/api/users/$uid');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetches all users with the DRAUGHTSMAN role.
  Future<List<UserProfile>> getDraughtsmen() async {
    final List<dynamic> data = await _apiClient.get('/api/users/role/draughtsmen');
    return data.map((json) => UserProfile.fromJson(json)).toList();
  }
}
