import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:archi_draft/src/features/api/providers/api_providers.dart';
import '../data/metrics_repository.dart';
import '../domain/student_metrics.dart';

final metricsRepositoryProvider = Provider<MetricsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MetricsRepository(apiClient);
});

final studentMetricsProvider = FutureProvider.autoDispose<StudentMetrics>((ref) {
  final repository = ref.watch(metricsRepositoryProvider);
  return repository.getStudentMetrics();
});
