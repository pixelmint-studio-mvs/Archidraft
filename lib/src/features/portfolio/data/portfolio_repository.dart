import 'package:archi_draft/src/features/api/data/api_client.dart';
import 'package:archi_draft/src/features/portfolio/domain/portfolio_project.dart';

class PortfolioRepository {
  final ApiClient apiClient;

  PortfolioRepository({required this.apiClient});

  Future<List<PortfolioProject>> getPortfolio() async {
    final response = await apiClient.get('/api/student/portfolio');
    final list = response['portfolio'] as List<dynamic>;
    return list.map((e) => PortfolioProject.fromJson(e)).toList();
  }
}
