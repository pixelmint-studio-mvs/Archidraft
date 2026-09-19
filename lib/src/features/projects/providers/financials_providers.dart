import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/providers/api_providers.dart';
import '../data/financials_repository.dart';
import '../domain/financials.dart';

final financialsRepositoryProvider = Provider<FinancialsRepository>((ref) {
  return FinancialsRepository(ref.watch(apiClientProvider));
});

final projectFinancialsProvider =
    FutureProvider.family<ProjectFinancials, String>((ref, projectId) async {
      final repository = ref.watch(financialsRepositoryProvider);
      return repository.getProjectFinancials(projectId);
    });
