import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'project_providers.dart';

// ──────────────────────────────────────────
// CLIENT PROJECT ACTIONS CONTROLLER
// ──────────────────────────────────────────

/// Provider for the [ClientProjectController].
///
/// Manages client-triggered project actions (cancel project).
/// Follows the same pattern as [AdminActionsController].
final clientProjectControllerProvider =
    NotifierProvider<ClientProjectController, AsyncValue<void>>(
        ClientProjectController.new);

/// Controller for client-side critical project actions.
///
/// Uses Cloud Functions via [ProjectRepository] for state mutations.
/// Generates a UUID `actionId` for idempotency per BACKEND_ACTIONS.md.
class ClientProjectController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  /// Cancels a project via the `cancelProject` Cloud Function.
  ///
  /// Preconditions (enforced by Cloud Function):
  /// - Caller is authenticated and is the project owner.
  /// - Project status is DRAFT or SUBMITTED.
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> cancelProject(String projectId) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(projectRepositoryProvider);
      final actionId = const Uuid().v4();

      await repository.cancelProject(
        projectId: projectId,
        actionId: actionId,
      );

      ref.invalidate(clientProjectsProvider);
      ref.invalidate(projectProvider(projectId));

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> requestCorrection({
    required String projectId,
    required String targetVersionId,
    required String description,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(projectRepositoryProvider);
      final actionId = const Uuid().v4();
      final correctionId = const Uuid().v4();

      await repository.requestCorrection(
        projectId: projectId,
        actionId: actionId,
        correctionId: correctionId, // Passed to match repository signature
        targetVersionId: targetVersionId,
        description: description,
      );

      ref.invalidate(projectProvider(projectId));
      ref.invalidate(projectCorrectionsProvider(projectId));

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
