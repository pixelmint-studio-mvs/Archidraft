import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/api/data/api_client.dart';
import 'package:archi_draft/src/features/projects/data/project_repository.dart';

class MockApiClient extends Fake implements ApiClient {
  String? lastPostPath;
  Map<String, dynamic>? lastPostBody;

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    lastPostPath = path;
    lastPostBody = body;
    return {'success': true};
  }
}

void main() {
  group('ProjectRepository assignment route contracts', () {
    late MockApiClient mockApiClient;
    late ProjectRepository repository;

    setUp(() {
      mockApiClient = MockApiClient();
      repository = ProjectRepository(mockApiClient);
    });

    test('acceptAssignment invokes /api/assignments/accept with valid payload', () async {
      await repository.acceptAssignment(
        projectId: 'proj_123',
        actionId: 'action_abc',
        assignmentId: 'asgn_456',
      );

      expect(mockApiClient.lastPostPath, equals('/api/assignments/accept'));
      expect(mockApiClient.lastPostBody, equals({
        'projectId': 'proj_123',
        'assignmentId': 'asgn_456',
        'actionId': 'action_abc',
      }));
    });

    test('rejectAssignment invokes /api/assignments/reject with valid payload', () async {
      await repository.rejectAssignment(
        projectId: 'proj_123',
        actionId: 'action_xyz',
        assignmentId: 'asgn_456',
        reason: 'Capacity full',
      );

      expect(mockApiClient.lastPostPath, equals('/api/assignments/reject'));
      expect(mockApiClient.lastPostBody, equals({
        'projectId': 'proj_123',
        'assignmentId': 'asgn_456',
        'actionId': 'action_xyz',
        'reason': 'Capacity full',
      }));
    });
  });
}
