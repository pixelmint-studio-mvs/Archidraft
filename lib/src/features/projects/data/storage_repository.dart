import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/data/api_client.dart';

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StorageRepository(apiClient);
});

class ProjectFile {
  final String id;
  final String projectId;
  final String fileName;
  final int fileSize;
  final String r2Path;
  final DateTime uploadedAt;

  ProjectFile({
    required this.id,
    required this.projectId,
    required this.fileName,
    required this.fileSize,
    required this.r2Path,
    required this.uploadedAt,
  });

  factory ProjectFile.fromJson(Map<String, dynamic> json) {
    return ProjectFile(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as int? ?? 0,
      r2Path: json['r2Path'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }
}

class StorageRepository {
  final ApiClient _apiClient;

  StorageRepository(this._apiClient);

  /// Uploads a file to a specific project.
  /// 
  /// The [category] can be 'client_uploads', 'draughtsman_versions', etc.
  Future<ProjectFile> uploadFile({
    required String projectId,
    required String fileName,
    String? filePath,
    List<int>? fileBytes,
    String category = 'client_uploads',
  }) async {
    final response = await _apiClient.postMultipart(
      '/storage/upload/$projectId',
      fileName: fileName,
      filePath: filePath,
      fileBytes: fileBytes,
      category: category,
    );

    // After uploading, fetch the latest list or return the new file info
    // The backend returns `{ success: true, file: { ... } }` but the returned file object is partial.
    // It's better to fetch the list or map it if we need the full object.
    // We'll just construct a basic ProjectFile from the response.
    final fileData = response['file'];
    return ProjectFile(
      id: fileData['id'],
      projectId: projectId,
      fileName: fileData['fileName'],
      fileSize: 0, // Not returned in the immediate response, could be added
      r2Path: fileData['r2Path'],
      uploadedAt: DateTime.now(),
    );
  }

  /// Lists all files for a project
  Future<List<ProjectFile>> getProjectFiles(String projectId) async {
    final response = await _apiClient.get('/storage/list/$projectId');
    final files = (response as List).cast<Map<String, dynamic>>();
    return files.map((json) => ProjectFile.fromJson(json)).toList();
  }
}
