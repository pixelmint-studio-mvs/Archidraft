import 'dart:convert';
import '../domain/project.dart';
import '../../../core/network/api_client.dart';

/// Repository for project CRUD operations interacting with Cloudflare Workers.
class ProjectRepository {
  final ApiClient _apiClient;

  ProjectRepository(this._apiClient);

  // ──────────────────────────────────────────
  // SIMPLE OPERATIONS (REST API)
  // ──────────────────────────────────────────

  /// Creates a new project draft in Cloudflare D1.
  /// Returns the auto-generated project ID.
  Future<String> createDraft(Project project) async {
    final response = await _apiClient.post(
      '/projects',
      body: project.toEditableFieldsMap(),
    );
    final data = jsonDecode(response.body);
    return data['projectId'] as String;
  }

  /// Updates only the client-editable fields of a draft project.
  Future<void> updateDraft(Project project) async {
    await _apiClient.patch(
      '/projects/${project.projectId}',
      body: project.toEditableFieldsMap(),
    );
  }

  /// Fetches a single project by its ID.
  Future<Project?> getProject(String projectId) async {
    try {
      final response = await _apiClient.get('/projects/$projectId');
      final data = jsonDecode(response.body);
      return Project.fromJson(data);
    } catch (e) {
      // Typically API returns 404 which ApiClient turns into Exception, or 
      // we can handle specific HTTP status codes if we inspect ApiClient more closely.
      return null; // Return null if not found
    }
  }

  /// Fetches the client's projects.
  Future<List<Project>> getClientProjects(String clientId) async {
    final response = await _apiClient.get('/projects');
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ──────────────────────────────────────────
  // CRITICAL OPERATIONS (REST API Actions)
  // ──────────────────────────────────────────

  Future<void> submitProject({
    required String projectId,
    required String actionId,
  }) async {
    await _apiClient.post(
      '/projects/$projectId/actions',
      body: {'action': 'submit', 'actionId': actionId},
    );
  }

  Future<void> cancelProject({
    required String projectId,
    required String actionId,
  }) async {
    await _apiClient.post(
      '/projects/$projectId/actions',
      body: {'action': 'cancel', 'actionId': actionId},
    );
  }

  // ──────────────────────────────────────────
  // ADMIN OPERATIONS (REST API)
  // ──────────────────────────────────────────

  Future<List<Project>> getProjectsByStatus(String status) async {
    final response = await _apiClient.get('/projects?status=$status');
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> approveProject({
    required String projectId,
    required String actionId,
  }) async {
    await _apiClient.post(
      '/projects/$projectId/actions',
      body: {'action': 'approve', 'actionId': actionId},
    );
  }

  Future<void> rejectProject({
    required String projectId,
    required String actionId,
    required String reason,
  }) async {
    await _apiClient.post(
      '/projects/$projectId/actions',
      body: {'action': 'reject', 'actionId': actionId, 'reason': reason},
    );
  }

  Future<void> assignDraughtsman({
    required String projectId,
    required String actionId,
    required String draughtsmanId,
  }) async {
    await _apiClient.post(
      '/projects/$projectId/actions',
      body: {'action': 'assign', 'actionId': actionId, 'draughtsmanId': draughtsmanId},
    );
  }
}
