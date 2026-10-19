import '../domain/project.dart';
import '../domain/correction.dart';
import '../domain/drawing_version.dart';
import '../domain/activity_log.dart';
import '../domain/project_message.dart';
import '../../api/data/api_client.dart';

/// Repository for project CRUD operations.
class ProjectRepository {
  final ApiClient _apiClient;

  ProjectRepository(this._apiClient);

  Future<Project> createProject({
    required String projectName,
    required String projectAddress,
    required String drawingName,
    required String drawingType,
    required double projectArea,
    double? estimatedAmount,
    required String actionId,
  }) async {
    final response = await _apiClient.post(
      '/api/projects',
      body: {
        'projectName': projectName,
        'projectAddress': projectAddress,
        'drawingName': drawingName,
        'drawingType': drawingType,
        'projectArea': projectArea,
        'estimatedAmount': estimatedAmount,
        'actionId': actionId,
      },
    );
    return Project.fromMap(response);
  }

  Future<Project?> getProject(String projectId) async {
    try {
      final response = await _apiClient.get('/api/projects/$projectId');
      return Project.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('404')) return null;
      if (msg.contains('403')) {
        throw Exception('You do not have permission to access this project.');
      }
      rethrow;
    }
  }

  Future<List<Project>> getEngineerProjects() async {
    final response = await _apiClient.get('/api/projects');
    return (response as List).map((p) => Project.fromMap(p)).toList();
  }

  Future<List<Project>> getClientProjects() => getEngineerProjects();

  Future<void> submitProject({
    required String projectId,
    required String actionId,
  }) async {
    await _apiClient.post(
      '/api/projects/submit',
      body: {
        'projectId': projectId,
        'actionId': actionId,
      },
    );
  }

  Future<void> approveProject({
    required String projectId,
    required String actionId,
  }) async {
    await _apiClient.post(
      '/api/projects/approve',
      body: {
        'projectId': projectId,
        'actionId': actionId,
      },
    );
  }

  Future<void> rejectProject({
    required String projectId,
    required String reason,
    required String actionId,
  }) async {
    await _apiClient.post(
      '/api/projects/reject',
      body: {
        'projectId': projectId,
        'reason': reason,
        'actionId': actionId,
      },
    );
  }

  Future<void> assignDraughtsman({
    required String projectId,
    required String draughtsmanId,
    String? draughtsmanName,
    required String actionId,
  }) async {
    await _apiClient.post(
      '/api/projects/assign',
      body: {
        'projectId': projectId,
        'draughtsmanId': draughtsmanId,
        'draughtsmanName': draughtsmanName,
        'actionId': actionId,
      },
    );
  }

  Future<void> acceptAssignment({
    required String projectId,
    required String actionId,
  }) async {
    await _apiClient.post(
      '/api/projects/accept',
      body: {
        'projectId': projectId,
        'actionId': actionId,
      },
    );
  }

  Future<void> rejectAssignment({
    required String projectId,
    required String actionId,
  }) async {
    await _apiClient.post(
      '/api/projects/reject-assignment',
      body: {
        'projectId': projectId,
        'actionId': actionId,
      },
    );
  }

  Future<void> submitDrawing({
    required String projectId,
    required String actionId,
  }) async {
    await _apiClient.post(
      '/api/projects/submit-drawing',
      body: {
        'projectId': projectId,
        'actionId': actionId,
      },
    );
  }

  Future<void> requestCorrection({
    required String projectId,
    required String correctionId,
    required String targetVersionId,
    required String description,
    required String actionId,
  }) async {
    await _apiClient.post(
      '/api/projects/request-correction',
      body: {
        'projectId': projectId,
        'correctionId': correctionId,
        'targetVersionId': targetVersionId,
        'description': description,
        'actionId': actionId,
      },
    );
  }

  Future<void> resolveCorrection({
    required String correctionId,
    required String actionId,
  }) async {
    await _apiClient.post(
      '/api/projects/resolve-correction',
      body: {
        'correctionId': correctionId,
        'actionId': actionId,
      },
    );
  }

  Future<void> approveFinal({
    required String projectId,
    required String actionId,
  }) async {
    await _apiClient.post(
      '/api/projects/approve-final',
      body: {
        'projectId': projectId,
        'actionId': actionId,
      },
    );
  }

  Future<List<DrawingVersion>> getDrawingVersions(String projectId) async {
    final response = await _apiClient.get('/api/projects/$projectId/drawing_versions');
    if (response is List) {
      return response.map((data) => DrawingVersion.fromMap(data)).toList();
    }
    return [];
  }

  Future<List<Correction>> getCorrections(String projectId) async {
    final response = await _apiClient.get('/api/projects/$projectId/corrections');
    if (response is List) {
      return response.map((data) => Correction.fromMap(data)).toList();
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

  Future<List<ActivityLog>> fetchActivityLogs(String projectId) async {
    final response = await _apiClient.get('/api/projects/$projectId/activity');
    if (response is List) {
      return response.map((json) => ActivityLog.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getActivityLogs(String projectId) async {
    final response = await _apiClient.get('/api/projects/$projectId/activity');
    if (response is List) {
      return response.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<List<ActivityLog>> fetchEngineerActivityLogs() async {
    final response = await _apiClient.get('/api/activity');
    if (response is List) {
      return response.map((json) => ActivityLog.fromJson(json)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getDraughtsmanSummary() async {
    final response = await _apiClient.get('/api/draughtsman/summary');
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {
      'total_assignments': 0,
      'pending': 0,
      'in_progress': 0,
      'under_review': 0,
      'completed': 0,
      'rejected': 0,
    };
  }

  Future<List<ProjectMessage>> getProjectMessages(String projectId) async {
    final response = await _apiClient.get('/api/projects/$projectId/messages');
    if (response is List) {
      return response.map((json) => ProjectMessage.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<ProjectMessage> sendProjectMessage({
    required String projectId,
    required String message,
    String? attachmentFileId,
  }) async {
    final payload = <String, dynamic>{'message': message};
    if (attachmentFileId != null) {
      payload['attachment_file_id'] = attachmentFileId;
    }
    final response = await _apiClient.post(
      '/api/projects/$projectId/messages',
      body: payload,
    );
    return ProjectMessage.fromJson(response as Map<String, dynamic>);
  }
  Future<void> uploadDrawingStream({
    required String projectId,
    required Stream<List<int>> stream,
    required int length,
    required String fileName,
    required String contentType,
    required String actionId,
  }) async {
    await _apiClient.postFileStream(
      '/api/projects/$projectId/files?category=draughtsman_version',
      stream,
      length,
      fileName: fileName,
      contentType: contentType,
      actionId: actionId,
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

  Future<List<Project>> getProjectsByStatus(String status) async {
    final response = await _apiClient.get(
      '/api/projects',
      queryParams: {'status': status},
    );
    return (response as List).map((p) => Project.fromMap(p)).toList();
  }

  Future<Map<String, dynamic>> getDashboardMetrics() async {
    final response = await _apiClient.get('/api/admin/dashboard');
    return response as Map<String, dynamic>;
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

}
