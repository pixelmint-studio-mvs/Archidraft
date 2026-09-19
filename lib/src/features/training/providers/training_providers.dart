import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/providers/api_providers.dart';
import '../data/training_repository.dart';
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
