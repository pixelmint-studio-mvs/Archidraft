import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/project_repository.dart';
import '../domain/project.dart';

// ──────────────────────────────────────────
// REPOSITORY PROVIDER
// ──────────────────────────────────────────

/// Provides the [ProjectRepository] with injected Firestore and Functions.
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(
    ref.watch(firestoreProvider),
    FirebaseFunctions.instance,
  );
});

// ──────────────────────────────────────────
// CLIENT PROJECTS STREAM
// ──────────────────────────────────────────

/// Real-time stream of the authenticated client's projects.
///
/// Automatically invalidates when auth state changes.
/// Returns an empty list if user is not authenticated.
final clientProjectsProvider = StreamProvider<List<Project>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  if (user == null) return Stream.value([]);

  final repository = ref.watch(projectRepositoryProvider);
  return repository.watchClientProjects(user.uid);
});

// ──────────────────────────────────────────
// SINGLE PROJECT
// ──────────────────────────────────────────

/// Fetches a single project by ID.
final projectProvider =
    FutureProvider.family<Project?, String>((ref, projectId) {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.getProject(projectId);
});
