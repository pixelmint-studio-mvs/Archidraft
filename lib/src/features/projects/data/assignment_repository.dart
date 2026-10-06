import '../domain/assignment.dart';
import '../../api/data/api_client.dart';

class AssignmentRepository {
  final ApiClient _apiClient;

  AssignmentRepository(this._apiClient);

  /// Fetches all assignments for the authenticated draughtsman.
  ///
  /// Throws a descriptive [Exception] on API or parse failure.
  /// Callers must distinguish between an empty list (success, zero assignments)
  /// and a thrown exception (API/auth/server error).
  Future<List<Assignment>> getAssignments() async {
    try {
      final response = await _apiClient.get('/api/assignments');
      if (response == null) return [];
      return (response as List).map((a) => Assignment.fromMap(a as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to load assignments from /api/assignments: $e');
    }
  }

  Future<Assignment> getAssignment(String id) async {
    try {
      final response = await _apiClient.get('/api/assignments/$id');
      return Assignment.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load assignment $id: $e');
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
        'actionId': ?actionId,
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
        'actionId': ?actionId,
        'reason': reason,
      },
    );
  }
}
