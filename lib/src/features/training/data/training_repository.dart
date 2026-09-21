import '../../api/data/api_client.dart';
import '../domain/training_module.dart';

class TrainingRepository {
  final ApiClient _apiClient;

  TrainingRepository(this._apiClient);

  /// Fetches all training modules for the current student.
  Future<List<TrainingModule>> getStudentModules() async {
    final response = await _apiClient.get('/api/student/training/modules');
    
    if (response != null && response is List) {
      return response
          .map((data) => TrainingModule.fromMap(data as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Fetches details for a specific training module.
  Future<TrainingModule> getModuleDetails(String moduleId) async {
    try {
      final response = await _apiClient.get('/api/student/training/modules/$moduleId');
      
      if (response != null && response is Map<String, dynamic>) {
        return TrainingModule.fromMap(response);
      }
      throw Exception('Module not found or invalid format');
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches progress summaries per category (e.g. Architectural, Structural)
  Future<List<TrainingCategoryProgress>> getCategoryProgress() async {
    final response = await _apiClient.get('/api/student/training/progress');
    
    if (response != null && response is List) {
      return response.map((data) {
        final map = data as Map<String, dynamic>;
        return TrainingCategoryProgress(
          category: map['category'] as String? ?? 'General',
          overallProgress: (map['overall_progress'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    }
    return [];
  }

  /// Fetches training projects assigned to the student
  Future<List<dynamic>> getStudentAssignments() async {
    final response = await _apiClient.get('/api/student/assignments');
    if (response != null && response is List) {
      return response;
    }
    return [];
  }

  /// Posts module completion progress.
  Future<void> postStudentProgress(String moduleId, String status, int? score) async {
    await _apiClient.post(
      '/api/student/training/progress',
      body: {
        'module_id': moduleId,
        'status': status,
        'score': score,
      },
    );
  }
}
