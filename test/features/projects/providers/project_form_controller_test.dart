import 'package:archi_draft/src/features/projects/providers/project_form_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectFormState', () {
    test('initial state is valid', () {
      const state = ProjectFormState();
      expect(state.currentStep, 0);
      expect(state.totalSteps, 4);
      expect(state.isStep1Valid, false); // Empty fields
    });

    test('isReadyForSubmission returns true when all required steps are valid', () {
      const state = ProjectFormState(
        projectName: 'Valid Name',
        projectAddress: '123 Main St',
        drawingName: 'Ground Floor',
        drawingType: 'FLOOR_PLAN',
        projectArea: '1500',
      );

      expect(state.isStep1Valid, true);
      expect(state.isStep2Valid, true);
      expect(state.isStep3Valid, true);
      expect(state.isReadyForSubmission, true);
    });

    test('isReadyForSubmission returns false if any required field is invalid', () {
      const state = ProjectFormState(
        projectName: 'Valid Name',
        projectAddress: '123 Main St',
        drawingName: '', // Invalid
        drawingType: 'FLOOR_PLAN',
        projectArea: '1500',
      );

      expect(state.isStep2Valid, false);
      expect(state.isReadyForSubmission, false);
    });
  });
}
