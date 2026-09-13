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
      expect(editable['project_name'], 'Test Project');
      expect(editable['project_address'], '123 Main St');
      expect(editable['drawing_name'], 'Ground Floor');
      expect(editable['drawing_type'], 'FLOOR_PLAN');
      expect(editable['project_area'], 1500);
      expect(editable['estimated_amount'], 5000);
      
      // Should NOT contain server-controlled or immutable fields
      expect(editable.containsKey('id'), false);
      expect(editable.containsKey('client_id'), false);
      expect(editable.containsKey('status'), false);
    });

    test('toFirestoreCreate sets initial defaults', () {
      final createMap = testProject.toFirestoreCreate();
      
      expect(createMap['project_name'], 'Test Project');
      expect(createMap['client_id'], 'client-123');
      expect(createMap.containsKey('status'), false);
      expect(createMap.containsKey('correction_round'), false);
      expect(createMap.containsKey('created_at'), false);
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
