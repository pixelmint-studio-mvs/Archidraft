import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:archi_draft/src/features/api/providers/api_providers.dart';
import '../data/achievements_repository.dart';
import '../domain/student_achievement.dart';

final achievementsRepositoryProvider = Provider<AchievementsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AchievementsRepository(apiClient);
});

final studentAchievementsProvider =
    FutureProvider.autoDispose<List<StudentAchievement>>((ref) {
  final repository = ref.watch(achievementsRepositoryProvider);
  return repository.getStudentAchievements();
});
