import '../domain/project.dart';
import '../../api/data/api_client.dart';

/// Repository for project CRUD operations.
///
/// Uses Cloudflare Worker API for all operations.
class ProjectRepository {
  final ApiClient _apiClient;

  ProjectRepository(this._apiClient);

  Future<String> createDraft(Project project) async {
    final response = await _apiClient.post('/api/projects', body: project.toFirestoreCreate());
    return response['id'];
  }

  Future<void> updateDraft(Project project) async {
    await _apiClient.post('/api/projects', body: {
      'id': project.projectId,
      ...project.toEditableFieldsMap(),
    });
  }

  Future<Project?> getProject(String projectId) async {
    try {
      final response = await _apiClient.get('/api/projects'); // the API returns all, we should really add a /api/projects/:id route. I'll filter here for now.
      final projects = (response as List).map((p) => Project.fromMap(p)).toList();
      return projects.firstWhere((p) => p.projectId == projectId);
    } catch (e) {
      return null;
    }
  }

  Future<List<Project>> getClientProjects() async {
    final response = await _apiClient.get('/api/projects');
    return (response as List).map((p) => Project.fromMap(p)).toList();
  }

  Future<void> submitProject({
    required String projectId,
    required String actionId,
  }) async {
    await _apiClient.post('/api/projects/submit', body: {
      'projectId': projectId,
      'actionId': actionId,
    });
  }

  Future<List<Project>> getProjectsByStatus(String status) async {
    final response = await _apiClient.get('/api/projects', queryParams: {'status': status});
    return (response as List).map((p) => Project.fromMap(p)).toList();
  }

  Future<void> approveProject({
    required String projectId,
    required String actionId,
  }) async {
    await _apiClient.post('/api/projects/approve', body: {
      'projectId': projectId,
      'actionId': actionId,
    });
  }

  Future<void> rejectProject({
    required String projectId,
    required String actionId,
    required String reason,
  }) async {
    await _apiClient.post('/api/projects/reject', body: {
      'projectId': projectId,
      'actionId': actionId,
      'reason': reason,
    });
  }

  Future<void> assignDraughtsman({
    required String projectId,
    required String actionId,
    required String draughtsmanId,
  }) async {
    await _apiClient.post('/api/projects/assign', body: {
      'projectId': projectId,
      'actionId': actionId,
      'draughtsmanId': draughtsmanId,
    });
  }

  Future<void> reassignDraughtsman({
    required String projectId,
    required String actionId,
    required String draughtsmanId,
  }) async {
    await _apiClient.post('/api/projects/reassign', body: {
      'projectId': projectId,
      'actionId': actionId,
      'draughtsmanId': draughtsmanId,
    });
  }
}
