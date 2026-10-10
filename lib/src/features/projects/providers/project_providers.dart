import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../api/providers/api_providers.dart';
import '../data/project_repository.dart';
import '../domain/project.dart';
import '../domain/correction.dart';
import '../domain/drawing_version.dart';
import '../domain/project_message.dart';

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

// ──────────────────────────────────────────
// ACTIVITY LOGS
// ──────────────────────────────────────────

final projectActivityLogsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((
  ref,
  projectId,
) {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.getActivityLogs(projectId);
});

// ──────────────────────────────────────────
// DRAUGHTSMAN SUMMARY (Insights)
// ──────────────────────────────────────────

final draughtsmanSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.getDraughtsmanSummary();
});

// ──────────────────────────────────────────
// PROJECT MESSAGES (Collaboration Hub)
// ──────────────────────────────────────────

final projectMessagesProvider = FutureProvider.family<List<ProjectMessage>, String>((
  ref,
  projectId,
) {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.getProjectMessages(projectId);
});

