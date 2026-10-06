import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../auth/domain/user_profile.dart';
import '../../profile/providers/profile_providers.dart';
import '../domain/project.dart';
import 'project_providers.dart';

// ──────────────────────────────────────────
// ADMIN PROJECT STREAMS
// ──────────────────────────────────────────

/// Stream of projects in SUBMITTED state (Pending Approval)
final pendingProjectsProvider = FutureProvider<List<Project>>((ref) async {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.getProjectsByStatus('SUBMITTED');
});

/// Stream of projects in WAITING_ASSIGNMENT state
final unassignedProjectsProvider = FutureProvider<List<Project>>((ref) async {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.getProjectsByStatus('WAITING_ASSIGNMENT');
});

/// Stream of projects in WAITING_ACCEPTANCE state (assigned, pending draughtsman acceptance)
final waitingAcceptanceProjectsProvider = FutureProvider<List<Project>>((ref) async {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.getProjectsByStatus('WAITING_ACCEPTANCE');
});

/// Stream of projects in IN_PROGRESS state
final activeProjectsProvider = FutureProvider<List<Project>>((ref) async {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.getProjectsByStatus('IN_PROGRESS');
});

// ──────────────────────────────────────────
// DRAUGHTSMEN LIST
// ──────────────────────────────────────────

/// Future provider of all draughtsmen available for assignment
final draughtsmenListProvider = FutureProvider<List<UserProfile>>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getDraughtsmen();
});

// ──────────────────────────────────────────
// ADMIN ACTIONS CONTROLLER
// ──────────────────────────────────────────

final adminActionsControllerProvider =
    NotifierProvider<AdminActionsController, AsyncValue<void>>(
      AdminActionsController.new,
    );

class AdminActionsController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<bool> approveProject(String projectId) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(projectRepositoryProvider);
      final actionId = const Uuid().v4();

      await repository.approveProject(projectId: projectId, actionId: actionId);

      // Refresh dashboard lists so the project moves from Pending → Unassigned.
      ref.invalidate(pendingProjectsProvider);
      ref.invalidate(unassignedProjectsProvider);
      ref.invalidate(projectProvider(projectId));

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> rejectProject({
    required String projectId,
    required String reason,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(projectRepositoryProvider);
      final actionId = const Uuid().v4();

      await repository.rejectProject(
        projectId: projectId,
        actionId: actionId,
        reason: reason,
      );

      // Refresh dashboard so the rejected project leaves Pending tab.
      ref.invalidate(pendingProjectsProvider);
      ref.invalidate(projectProvider(projectId));

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> assignDraughtsman({
    required String projectId,
    required String draughtsmanId,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(projectRepositoryProvider);
      final actionId = const Uuid().v4();

      await repository.assignDraughtsman(
        projectId: projectId,
        actionId: actionId,
        draughtsmanId: draughtsmanId,
      );

      // Refresh dashboard so project moves Unassigned → Active, and
      // draughtsman portal picks up the new assignment on next load.
      ref.invalidate(unassignedProjectsProvider);
      ref.invalidate(activeProjectsProvider);
      ref.invalidate(projectProvider(projectId));

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> reassignDraughtsman({
    required String projectId,
    required String draughtsmanId,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(projectRepositoryProvider);
      final actionId = const Uuid().v4();

      await repository.reassignDraughtsman(
        projectId: projectId,
        actionId: actionId,
        draughtsmanId: draughtsmanId,
      );

      // Refresh dashboard and project detail after reassignment.
      ref.invalidate(activeProjectsProvider);
      ref.invalidate(projectProvider(projectId));

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
