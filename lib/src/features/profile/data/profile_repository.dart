import '../../auth/domain/user_profile.dart';
import '../../api/data/api_client.dart';

/// Repository for profile CRUD operations using API.
class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository(this._apiClient);

  Future<UserProfile?> getProfile(String uid) async {
    try {
      final response = await _apiClient.get('/api/users/me');
      return UserProfile.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Updates the profile with only user-editable fields.
  ///
  /// Uses PATCH /api/users/me to avoid overwriting protected fields
  /// (e.g., role) via the creation endpoint.
  Future<void> updateProfile(UserProfile profile) async {
    await _apiClient.patch('/api/users/me', body: profile.toEditableFieldsMap());
  }

  Future<bool> profileExists(String uid) async {
    final profile = await getProfile(uid);
    return profile != null;
  }

  Future<List<UserProfile>> getDraughtsmen() async {
    try {
      final response = await _apiClient.get('/api/users', queryParams: {'role': 'DRAUGHTSMAN'});
      return (response as List).map((u) => UserProfile.fromMap(u)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Returns true if the draughtsman profile has the minimum required fields.
  ///
  /// Criteria: [name] and [mobile] must be non-empty.
  /// Optional fields (qualification, collegeName, etc.) do not gate access.
  static bool isProfileComplete(UserProfile profile) {
    return profile.name.trim().isNotEmpty && profile.mobile.trim().isNotEmpty;
  }
}

