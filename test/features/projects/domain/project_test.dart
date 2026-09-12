import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Project Model', () {
    final testProject = Project(
      projectId: 'proj-123',
      projectName: 'Test Project',
      projectAddress: '123 Main St',
      drawingName: 'Ground Floor',
      drawingType: 'FLOOR_PLAN',
      projectArea: 1500,
      estimatedAmount: 5000,
      clientId: 'client-123',
      status: 'DRAFT',
      correctionRound: 0,
    );

    test('toEditableFieldsMap only includes editable fields', () {
      final editable = testProject.toEditableFieldsMap();
      
      expect(editable.length, 6);
      expect(editable['projectName'], 'Test Project');
      expect(editable['projectAddress'], '123 Main St');
      expect(editable['drawingName'], 'Ground Floor');
      expect(editable['drawingType'], 'FLOOR_PLAN');
      expect(editable['projectArea'], 1500);
      expect(editable['estimatedAmount'], 5000);
      
      // Should NOT contain server-controlled or immutable fields
      expect(editable.containsKey('projectId'), false);
      expect(editable.containsKey('clientId'), false);
      expect(editable.containsKey('status'), false);
    });

    test('toFirestoreCreate sets initial defaults', () {
      final createMap = testProject.toFirestoreCreate();
      
      expect(createMap['projectName'], 'Test Project');
      expect(createMap['clientId'], 'client-123');
      expect(createMap['status'], 'DRAFT');
      expect(createMap['correctionRound'], 0);
      expect(createMap.containsKey('createdAt'), true);
    });

    test('copyWith updates specified fields', () {
      final updated = testProject.copyWith(
        projectName: 'Updated Name',
        status: 'SUBMITTED',
      );
      
      expect(updated.projectName, 'Updated Name');
      expect(updated.status, 'SUBMITTED');
      
      // Unchanged fields remain the same
      expect(updated.projectId, 'proj-123');
      expect(updated.clientId, 'client-123');
    });
  });
}
