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

  Future<void> updateProfile(UserProfile profile) async {
    await _apiClient.post('/api/users', body: profile.toMap());
  }

  Future<bool> profileExists(String uid) async {
    final profile = await getProfile(uid);
    return profile != null;
  }

  Future<List<UserProfile>> getDraughtsmen() async {
    try {
      final responseDraughtsmen = await _apiClient.get(
        '/api/users',
        queryParams: {'role': 'DRAUGHTSMAN'},
      );
      final responseStudents = await _apiClient.get(
        '/api/users',
        queryParams: {'role': 'STUDENT'},
      );
      final d = (responseDraughtsmen as List).map((u) => UserProfile.fromMap(u)).toList();
      final s = (responseStudents as List).map((u) => UserProfile.fromMap(u)).toList();
      return [...d, ...s];
    } catch (e) {
      return [];
    }
  }
}
