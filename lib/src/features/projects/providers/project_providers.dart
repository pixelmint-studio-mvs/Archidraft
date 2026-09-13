import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../api/providers/api_providers.dart';
import '../data/project_repository.dart';
import '../domain/project.dart';

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
// SINGLE PROJECT
// ──────────────────────────────────────────

final projectProvider = FutureProvider.family<Project?, String>((
  ref,
  projectId,
) {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.getProject(projectId);
});
