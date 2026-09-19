import '../../api/data/api_client.dart';
import '../domain/training_module.dart';

class TrainingRepository {
  final ApiClient _apiClient;

  TrainingRepository(this._apiClient);

  /// Fetches all training modules for the current student.
  Future<List<TrainingModule>> getStudentModules() async {
    try {
      final response = await _apiClient.get('/api/student/training/modules');
      
      if (response != null && response is List) {
        return response
            .map((data) => TrainingModule.fromMap(data as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      // Fallback to mock data if endpoint is not implemented
      return _getMockModules();
    }
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
      final mockModules = _getMockModules();
      final module = mockModules.where((m) => m.id == moduleId).firstOrNull;
      if (module != null) return module;
      rethrow;
    }
  }

  /// Fetches progress summaries per category (e.g. Architectural, Structural)
  Future<List<TrainingCategoryProgress>> getCategoryProgress() async {
    try {
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
    } catch (e) {
      // Fallback to mock data
      return [
        const TrainingCategoryProgress(category: 'Architectural', overallProgress: 0.35),
        const TrainingCategoryProgress(category: 'Structural', overallProgress: 0.10),
        const TrainingCategoryProgress(category: 'Interior', overallProgress: 0.0),
        const TrainingCategoryProgress(category: 'Approval', overallProgress: 0.0),
      ];
    }
  }

  List<TrainingModule> _getMockModules() {
    return const [
      TrainingModule(
        id: 'mock_1',
        title: 'Residential Floor Plan Basics',
        category: 'Architectural',
        type: 'Mock Project',
        level: 'Beginner',
        description: 'Learn the fundamentals of drafting a standard residential floor plan.',
        status: 'In Progress',
        progress: 0.4,
        durationOrFormat: '2 hours • Interactive',
      ),
      TrainingModule(
        id: 'mock_2',
        title: 'Advanced Elevation Detailing',
        category: 'Architectural',
        type: 'Mock Project',
        level: 'Advanced',
        description: 'Master the art of detailed elevations for commercial buildings.',
        status: 'Not Started',
        progress: 0.0,
        isLocked: true,
        prerequisites: 'Residential Floor Plan Basics',
      ),
      TrainingModule(
        id: 'mock_3',
        title: 'Load-Bearing Wall Analysis',
        category: 'Structural',
        type: 'Module',
        level: 'Intermediate',
        description: 'Identify and draft load-bearing structural elements.',
        status: 'Completed',
        progress: 1.0,
        score: 92,
      ),
    ];
  }
}
