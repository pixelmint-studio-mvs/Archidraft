import 'package:archi_draft/src/features/api/data/api_client.dart';
import '../domain/student_achievement.dart';

class AchievementsRepository {
  final ApiClient _apiClient;

  AchievementsRepository(this._apiClient);

  Future<List<StudentAchievement>> getStudentAchievements() async {
    final response = await _apiClient.get('/api/student/achievements');
    if (response is Map<String, dynamic> && response['achievements'] is List) {
      return (response['achievements'] as List)
          .map((json) => StudentAchievement.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
