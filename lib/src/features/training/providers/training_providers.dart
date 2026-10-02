import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/providers/api_providers.dart';
import '../../projects/domain/correction.dart';
import '../../projects/domain/project.dart';
import '../data/training_repository.dart';
import '../domain/lesson.dart';
import '../domain/training_module.dart';

/// Provides the TrainingRepository instance.
final trainingRepositoryProvider = Provider<TrainingRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TrainingRepository(apiClient);
});

/// Fetches all training modules for the authenticated student.
final studentModulesProvider = FutureProvider<List<TrainingModule>>((ref) async {
  final repository = ref.watch(trainingRepositoryProvider);
  return repository.getStudentModules();
});

/// Fetches progress summaries per category for the authenticated student.
final categoryProgressProvider = FutureProvider<List<TrainingCategoryProgress>>((ref) async {
  final repository = ref.watch(trainingRepositoryProvider);
  return repository.getCategoryProgress();
});

/// Fetches details for a specific training module.
final moduleDetailProvider = FutureProvider.family<TrainingModule, String>((ref, moduleId) async {
  final repository = ref.watch(trainingRepositoryProvider);
  return repository.getModuleDetails(moduleId);
});

/// Fetches assignments for the authenticated student.
final studentAssignmentsProvider = FutureProvider.autoDispose<List<Project>>((ref) async {
  final repository = ref.watch(trainingRepositoryProvider);
  final assignments = await repository.getStudentAssignments();
  return assignments.map((data) => Project.fromMap(data as Map<String, dynamic>)).toList();
});

/// Fetches all pending corrections for the authenticated student's training projects.
final studentCorrectionsProvider = FutureProvider.autoDispose<List<Correction>>((ref) async {
  final repository = ref.watch(trainingRepositoryProvider);
  final data = await repository.getStudentCorrections();
  return data.map((json) => Correction.fromJson(json as Map<String, dynamic>)).toList();
});

/// Fetches recent activity for the authenticated student's training projects.
final studentActivityProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(trainingRepositoryProvider);
  final data = await repository.getStudentActivity();
  return data.map((e) => e as Map<String, dynamic>).toList();
});

/// Fetches lessons for a specific module.
final moduleLessonsProvider = FutureProvider.family<List<Lesson>, String>((ref, moduleId) async {
  final repository = ref.watch(trainingRepositoryProvider);
  return repository.getModuleLessons(moduleId);
});

/// Fetches details for a specific lesson.
final lessonDetailProvider = FutureProvider.family<Lesson, String>((ref, lessonId) async {
  final repository = ref.watch(trainingRepositoryProvider);
  return repository.getLesson(lessonId);
});
