import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:archi_draft/src/features/api/providers/api_providers.dart';
import 'package:archi_draft/src/features/portfolio/data/portfolio_repository.dart';
import 'package:archi_draft/src/features/portfolio/domain/portfolio_project.dart';

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PortfolioRepository(apiClient: apiClient);
});

final studentPortfolioProvider = FutureProvider.autoDispose<List<PortfolioProject>>((ref) async {
  final repo = ref.watch(portfolioRepositoryProvider);
  return await repo.getPortfolio();
});
