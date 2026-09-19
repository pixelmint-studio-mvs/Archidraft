import '../domain/project.dart';
import '../domain/correction.dart';
import '../domain/drawing_version.dart';
import '../../api/data/api_client.dart';

/// Repository for project CRUD operations.
///
/// Uses Cloudflare Worker API for all operations.
class ProjectRepository {
  final ApiClient _apiClient;

  ProjectRepository(this._apiClient);

  Future<String> createDraft(Project project) async {
    final response = await _apiClient.post(
      '/api/projects',
      body: project.toFirestoreCreate(),
    );
    return response['id'];
  }

  Future<void> updateDraft(Project project) async {
    await _apiClient.post(
      '/api/projects',
      body: {'id': project.projectId, ...project.toEditableFieldsMap()},
    );
  }

  Future<Project?> getProject(String projectId) async {
    try {
      final response = await _apiClient.get('/api/projects'); // the API returns all, we should really add a /api/projects/:id route. I'll filter here for now.
      final projects = (response as List)
          .map((p) => Project.fromMap(p))
          .toList();
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
    await _apiClient.post(
      '/api/projects/submit',
      body: {'projectId': projectId, 'actionId': actionId},
    );
  }

  Future<List<Project>> getProjectsByStatus(String status) async {
    final response = await _apiClient.get(
      '/api/projects',
      queryParams: {'status': status},
    );
    return (response as List).map((p) => Project.fromMap(p)).toList();
  }

  Future<void> approveProject({
    required String projectId,
    required String actionId,
  }) async {
    await _apiClient.post(
      '/api/projects/approve',
      body: {'projectId': projectId, 'actionId': actionId},
    );
  }

  Future<void> rejectProject({
    required String projectId,
    required String actionId,
    required String reason,
  }) async {
    await _apiClient.post(
      '/api/projects/reject',
      body: {'projectId': projectId, 'actionId': actionId, 'reason': reason},
    );
  }

  Future<void> assignDraughtsman({
    required String projectId,
    required String actionId,
    required String draughtsmanId,
  }) async {
    await _apiClient.post(
      '/api/projects/assign',
      body: {
        'projectId': projectId,
        'actionId': actionId,
        'draughtsmanId': draughtsmanId,
      },
    );
  }

  Future<void> reassignDraughtsman({
    required String projectId,
    required String actionId,
    required String draughtsmanId,
  }) async {
    await _apiClient.post(
      '/api/projects/reassign',
      body: {
        'projectId': projectId,
        'actionId': actionId,
        'draughtsmanId': draughtsmanId,
      },
    );
  }

  Future<void> submitDrawing({
    required String projectId,
    required String actionId,
  }) async {
    await _apiClient.post(
      '/api/projects/submit-drawing',
      body: {'projectId': projectId, 'actionId': actionId},
    );
  }

  Future<void> approveFinal({
    required String projectId,
    required String actionId,
  }) async {
    await _apiClient.post(
      '/api/projects/approve-final',
      body: {'projectId': projectId, 'actionId': actionId},
    );
  }

  Future<void> requestCorrection({
    required String projectId,
    required String actionId,
    required String correctionId, // Note: not used by backend currently
    required String targetVersionId,
    required String description,
  }) async {
    await _apiClient.post(
      '/api/projects/request-correction',
      body: {
        'projectId': projectId,
        'actionId': actionId,
        'targetVersionId': targetVersionId,
        'description': description,
      },
    );
  }

  Future<void> startCorrection({
    required String projectId,
    required String correctionId,
    required String actionId,
  }) async {
    await _apiClient.post(
      '/api/projects/$projectId/corrections/$correctionId/start',
      body: {'actionId': actionId},
    );
  }


  Future<List<DrawingVersion>> getDrawingVersions(String projectId) async {
    final response = await _apiClient.get('/api/projects/$projectId/drawing_versions');
    if (response is List) {
      return response.map((json) => DrawingVersion.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<Correction>> getCorrections(String projectId) async {
    final response = await _apiClient.get('/api/projects/$projectId/corrections');
    if (response is List) {
      return response.map((json) => Correction.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> cancelProject({
    required String projectId,
    required String actionId,
  }) async {
    await _apiClient.post(
      '/api/projects/cancel',
      body: {'projectId': projectId, 'actionId': actionId},
    );
  }
}
