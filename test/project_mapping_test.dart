import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';

void main() {
  test('Mapping test', () {
    final data = {
      "id": "PROJ_TRAIN_1",
      "project_name": "Residential Ground Floor Plan",
      "project_address": "Plot 12, Phase 1",
      "drawing_name": "Ground Floor Plan",
      "drawing_type": "Architectural",
      "project_area": "1500 sqft",
      "estimated_amount": null,
      "client_id": "TEST_UID_CLIENT",
      "draughtsman_id": null,
      "current_assignment_id": "S_ASSIGN_1",
      "status": "IN_PROGRESS",
      "correction_round": 1,
      "created_at": null,
      "submitted_at": null,
      "completed_at": null,
      "last_action_id": null,
      "training_module_id": "MOD_ARCH_4",
      "is_training_project": 1
    };

    try {
      final project = Project.fromMap(data);
      print('Success! ${project.projectId}');
    } catch (e, stack) {
      print('Error: $e');
      print(stack);
      rethrow;
    }
  });
}
