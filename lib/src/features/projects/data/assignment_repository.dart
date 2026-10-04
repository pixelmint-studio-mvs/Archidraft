import '../domain/assignment.dart';
import '../../api/data/api_client.dart';

class AssignmentRepository {
  final ApiClient _apiClient;

  AssignmentRepository(this._apiClient);

  Future<List<Assignment>> getAssignments() async {
    try {
      final response = await _apiClient.get('/api/assignments');
      return (response as List).map((a) => Assignment.fromMap(a)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Assignment> getAssignment(String id) async {
    try {
      final response = await _apiClient.get('/api/assignments/$id');
      return Assignment.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> acceptAssignment({
    required String assignmentId,
    String? actionId,
  }) async {
    await _apiClient.post(
      '/api/assignments/accept',
      body: {
        'assignmentId': assignmentId,
        if (actionId != null) 'actionId': actionId,
      },
    );
  }

  Future<void> rejectAssignment({
    required String assignmentId,
    String? actionId,
    String reason = '',
  }) async {
    await _apiClient.post(
      '/api/assignments/reject',
      body: {
        'assignmentId': assignmentId,
        if (actionId != null) 'actionId': actionId,
        'reason': reason,
      },
    );
  }
}
