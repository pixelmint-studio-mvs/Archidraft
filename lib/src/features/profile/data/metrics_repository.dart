import 'package:archi_draft/src/features/api/data/api_client.dart';
import '../domain/student_metrics.dart';

class MetricsRepository {
  final ApiClient _apiClient;

  MetricsRepository(this._apiClient);

  Future<StudentMetrics> getStudentMetrics() async {
    final response = await _apiClient.get('/api/student/metrics');
    return StudentMetrics.fromJson(response as Map<String, dynamic>);
  }
}
