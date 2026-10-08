import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/data/api_client.dart';
import '../../api/providers/api_providers.dart';
import '../domain/project_message.dart';

class MessageRepository {
  final ApiClient _apiClient;

  MessageRepository(this._apiClient);

  Future<List<ProjectMessage>> getProjectMessages(String projectId) async {
    final response = await _apiClient.get('/api/projects/$projectId/messages');
    if (response is List) {
      return response.map((json) => ProjectMessage.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<ProjectMessage> sendMessage({
    required String projectId,
    required String message,
    String? attachmentFileId,
  }) async {
    final body = <String, dynamic>{
      'message': message,
      if (attachmentFileId != null && attachmentFileId.isNotEmpty)
        'attachment_file_id': attachmentFileId,
    };

    final response = await _apiClient.post(
      '/api/projects/$projectId/messages',
      body: body,
    );

    return ProjectMessage.fromJson(response as Map<String, dynamic>);
  }
}

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MessageRepository(apiClient);
});
