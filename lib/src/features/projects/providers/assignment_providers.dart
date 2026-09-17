import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../api/providers/api_providers.dart';
import '../data/assignment_repository.dart';
import '../domain/assignment.dart';
import 'project_providers.dart';

// ──────────────────────────────────────────
// REPOSITORY PROVIDER
// ──────────────────────────────────────────

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  return AssignmentRepository(ref.watch(apiClientProvider));
});

// ──────────────────────────────────────────
// DRAUGHTSMAN ASSIGNMENTS
// ──────────────────────────────────────────

final draughtsmanAssignmentsProvider = FutureProvider<List<Assignment>>((
  ref,
) async {
  final repository = ref.watch(assignmentRepositoryProvider);
  return repository.getAssignments();
});

// ──────────────────────────────────────────
// DRAUGHTSMAN ACTIONS CONTROLLER
// ──────────────────────────────────────────

final draughtsmanActionsControllerProvider =
    NotifierProvider<DraughtsmanActionsController, AsyncValue<void>>(
      DraughtsmanActionsController.new,
    );

class DraughtsmanActionsController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<bool> acceptAssignment({
    required String assignmentId,
    required String projectId,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(assignmentRepositoryProvider);
      final actionId = const Uuid().v4();

      await repository.acceptAssignment(
        assignmentId: assignmentId,
        projectId: projectId,
        actionId: actionId,
      );

      ref.invalidate(draughtsmanAssignmentsProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> rejectAssignment({
    required String assignmentId,
    required String projectId,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(assignmentRepositoryProvider);
      final actionId = const Uuid().v4();

      await repository.rejectAssignment(
        assignmentId: assignmentId,
        projectId: projectId,
        actionId: actionId,
      );

      ref.invalidate(draughtsmanAssignmentsProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> submitDrawing({required String projectId}) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(projectRepositoryProvider);
      final actionId = const Uuid().v4();

      await repository.submitDrawing(projectId: projectId, actionId: actionId);

      ref.invalidate(draughtsmanAssignmentsProvider);
      ref.invalidate(projectProvider(projectId));
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> uploadDrawingStream({
    required String projectId,
    required Stream<List<int>> stream,
    required int length,
    required String fileName,
    required String contentType,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(projectRepositoryProvider);
      final actionId = const Uuid().v4();

      await repository.uploadDrawingStream(
        projectId: projectId,
        stream: stream,
        length: length,
        fileName: fileName,
        contentType: contentType,
        actionId: actionId,
      );

      ref.invalidate(projectDrawingVersionsProvider(projectId));
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
