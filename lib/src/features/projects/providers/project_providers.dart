import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../../core/network/api_client.dart';
import '../data/project_repository.dart';
import '../domain/project.dart';

// ──────────────────────────────────────────
// REPOSITORY PROVIDER
// ──────────────────────────────────────────

/// Provides the [ProjectRepository] with injected ApiClient.
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(
    ref.watch(apiClientProvider),
  );
});

// ──────────────────────────────────────────
// CLIENT PROJECTS STREAM (MIGRATED TO REST API)
// ──────────────────────────────────────────

/// Fetches the authenticated client's projects.
///
/// Returns an empty list if user is not authenticated.
final clientProjectsProvider = FutureProvider<List<Project>>((ref) async {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  if (user == null) return [];

  final repository = ref.watch(projectRepositoryProvider);
  return await repository.getClientProjects(user.uid);
});

// ──────────────────────────────────────────
// SINGLE PROJECT (MIGRATED TO REST API)
// ──────────────────────────────────────────

/// Fetches a single project by ID.
final projectProvider =
    FutureProvider.family<Project?, String>((ref, projectId) async {
  final repository = ref.watch(projectRepositoryProvider);
  return await repository.getProject(projectId);
});
