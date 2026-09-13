import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/data/api_client.dart';
import '../domain/project_file.dart';
import '../../api/providers/api_providers.dart';

class FileRepository {
  final ApiClient _apiClient;

  FileRepository(this._apiClient);

  Future<List<ProjectFile>> getProjectFiles(String projectId) async {
    final response = await _apiClient.get('/api/projects/$projectId/files');
    if (response is List) {
      return response.map((json) => ProjectFile.fromJson(json)).toList();
    }
    return [];
  }

  Future<ProjectFile> uploadFile({
    required String projectId,
    required String category,
    required String fileName,
    required String contentType,
    required Stream<List<int>> stream,
    required int length,
    required String actionId,
  }) async {
    final response = await _apiClient.postFileStream(
      '/api/projects/$projectId/files?category=$category',
      stream,
      length,
      fileName: fileName,
      contentType: contentType,
      actionId: actionId,
    );
    return ProjectFile.fromJson(response);
  }

  Future<void> downloadFile(String fileId, String savePath) async {
    return await _apiClient.downloadFileStream(
      '/api/files/$fileId/download',
      savePath,
    );
  }
}

final fileRepositoryProvider = Provider<FileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FileRepository(apiClient);
});
