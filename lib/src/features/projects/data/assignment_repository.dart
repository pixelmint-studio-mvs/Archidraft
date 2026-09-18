import '../domain/assignment.dart';
import '../../api/data/api_client.dart';

class AssignmentRepository {
  final ApiClient _apiClient;

  AssignmentRepository(this._apiClient);

  Future<List<Assignment>> getAssignments() async {
    try {
      final response = await _apiClient.get('/api/assignments');
      return (response as List).map((a) => Assignment.fromMap(a)).toList();
    } catch (e, st) {
      print('Error parsing assignments: $e\n$st');
      return [];
    }
  }

  Future<void> acceptAssignment({
    required String assignmentId,
    required String projectId,
    required String actionId,
  }) async {
    await _apiClient.post(
      '/api/assignments/accept',
      body: {
        'assignmentId': assignmentId,
        'projectId': projectId,
        'actionId': actionId,
      },
    );
  }

  Future<void> rejectAssignment({
    required String assignmentId,
    required String projectId,
    required String actionId,
  }) async {
    await _apiClient.post(
      '/api/assignments/reject',
      body: {
        'assignmentId': assignmentId,
        'projectId': projectId,
        'actionId': actionId,
      },
    );
  }
}
