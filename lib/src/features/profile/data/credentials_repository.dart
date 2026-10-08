import 'package:archi_draft/src/features/api/data/api_client.dart';
import '../domain/student_credential.dart';

class CredentialsRepository {
  final ApiClient _apiClient;

  CredentialsRepository(this._apiClient);

  Future<List<StudentCredential>> getStudentCredentials() async {
    final response = await _apiClient.get('/api/student/credentials');
    if (response is List) {
      return response
          .map((json) => StudentCredential.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> generateCertificate(String credentialId) async {
    await _apiClient.post('/api/student/credentials/$credentialId/certificate');
  }

  Future<void> downloadCertificate(String credentialId, String savePath) async {
    await _apiClient.downloadFileStream(
      '/api/student/credentials/$credentialId/certificate',
      savePath,
    );
  }
}
