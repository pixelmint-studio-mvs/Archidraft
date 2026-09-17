import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../api/providers/api_providers.dart';
import '../data/project_repository.dart';
import '../domain/project.dart';
import '../domain/project_status.dart';
import '../domain/correction.dart';
import '../domain/drawing_version.dart';

// ──────────────────────────────────────────
// REPOSITORY PROVIDER
// ──────────────────────────────────────────

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(apiClientProvider));
});

// ──────────────────────────────────────────
// CLIENT PROJECTS
// ──────────────────────────────────────────

/// Fetches the authenticated client's projects.
final clientProjectsProvider = FutureProvider<List<Project>>((ref) async {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  if (user == null) return [];

  final repository = ref.watch(projectRepositoryProvider);
  return repository.getClientProjects();
});

// ──────────────────────────────────────────
// CLIENT DASHBOARD STATS
// ──────────────────────────────────────────

class ClientDashboardStats {
  final int total;
  final int active;
  final int pendingReview;
  final int completed;

  const ClientDashboardStats({
    required this.total,
    required this.active,
    required this.pendingReview,
    required this.completed,
  });
}

final clientDashboardStatsProvider = Provider<AsyncValue<ClientDashboardStats>>((ref) {
  final projectsAsync = ref.watch(clientProjectsProvider);
  return projectsAsync.whenData((projects) {
    final active = projects
        .where((p) =>
            p.projectStatus == ProjectStatus.submitted ||
            p.projectStatus == ProjectStatus.waitingAssignment ||
            p.projectStatus == ProjectStatus.waitingAcceptance ||
            p.projectStatus == ProjectStatus.inProgress)
        .length;
    final pendingReview = projects
        .where((p) => p.projectStatus == ProjectStatus.underClientReview)
        .length;
    final completed = projects
        .where((p) => p.projectStatus == ProjectStatus.completed)
        .length;
    return ClientDashboardStats(
      total: projects.length,
      active: active,
      pendingReview: pendingReview,
      completed: completed,
    );
  });
});

// ──────────────────────────────────────────
final projectProvider = FutureProvider.family<Project?, String>((
  ref,
  projectId,
) {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.getProject(projectId);
});

final projectDrawingVersionsProvider = FutureProvider.family<List<DrawingVersion>, String>((
  ref,
  projectId,
) {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.getDrawingVersions(projectId);
});

final projectCorrectionsProvider = FutureProvider.family<List<Correction>, String>((
  ref,
  projectId,
) {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.getCorrections(projectId);
});
