import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/message_repository.dart';
import '../domain/project_message.dart';

/// Provider fetching persisted messages for a specific project.
final projectMessagesProvider = FutureProvider.family<List<ProjectMessage>, String>((ref, projectId) async {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.getProjectMessages(projectId);
});

/// Controller handling message dispatch, attachment linking, and mutation states.
class MessageSenderController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<ProjectMessage?> sendMessage({
    required String projectId,
    required String text,
    String? attachmentFileId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && (attachmentFileId == null || attachmentFileId.isEmpty)) {
      state = AsyncValue.error('Cannot send empty message without attachment', StackTrace.current);
      return null;
    }

    if (state.isLoading) {
      return null; // Prevent duplicate sends while previous request is running
    }

    state = const AsyncValue.loading();
    try {
      final repository = ref.read(messageRepositoryProvider);
      final createdMessage = await repository.sendMessage(
        projectId: projectId,
        message: trimmed,
        attachmentFileId: attachmentFileId,
      );

      // Invalidate project messages so the UI updates with real persisted data
      ref.invalidate(projectMessagesProvider(projectId));

      state = const AsyncValue.data(null);
      return createdMessage;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final messageSenderControllerProvider = NotifierProvider<MessageSenderController, AsyncValue<void>>(
  MessageSenderController.new,
);
