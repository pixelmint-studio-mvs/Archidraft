import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/providers/project_form_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectFormState', () {
    test('initial state is valid', () {
      const state = ProjectFormState();
      expect(state.currentStep, 0);
      expect(state.totalSteps, 4);
      expect(state.isStep1Valid, false); // Empty fields
    });

    test('isReadyForSubmission returns true when all required steps are valid with ARCHITECTURAL', () {
      const state = ProjectFormState(
        projectName: 'Valid Name',
        projectAddress: '123 Main St',
        drawingName: 'Ground Floor',
        drawingType: 'ARCHITECTURAL',
        projectArea: '1500',
      );

      expect(state.isStep1Valid, true);
      expect(state.isStep2Valid, true);
      expect(state.isStep3Valid, true);
      expect(state.isReadyForSubmission, true);
    });

    test('isReadyForSubmission returns true when drawingType is Architectural', () {
      const state = ProjectFormState(
        projectName: 'Valid Name',
        projectAddress: '123 Main St',
        drawingName: 'Ground Floor',
        drawingType: 'Architectural',
        projectArea: '1500',
      );

      expect(state.isStep2Valid, true);
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

  group('ProjectFormController - Draft loading & Category Normalization', () {
    test('loadDraft normalizes Architectural to canonical ARCHITECTURAL', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const draftProject = Project(
        projectId: 'proj-123',
        projectName: 'Villa Drafting',
        projectAddress: '42 Skyline Ave',
        drawingName: 'Front Elevation',
        drawingType: 'Architectural',
        clientId: 'eng-1',
        status: 'DRAFT',
      );

      container.read(projectFormControllerProvider.notifier).loadDraft(draftProject);
      final state = container.read(projectFormControllerProvider);

      expect(state.projectId, equals('proj-123'));
      expect(state.drawingType, equals('ARCHITECTURAL'));
    });

    test('loadDraft preserves unrecognized legacy value gracefully', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const legacyProject = Project(
        projectId: 'proj-legacy',
        projectName: 'Historic Vault',
        projectAddress: '1 Old Road',
        drawingName: 'Survey',
        drawingType: 'LEGACY_UNRECOGNIZED_SCHEME',
        clientId: 'eng-1',
        status: 'DRAFT',
      );

      container.read(projectFormControllerProvider.notifier).loadDraft(legacyProject);
      final state = container.read(projectFormControllerProvider);

      expect(state.drawingType, equals('LEGACY_UNRECOGNIZED_SCHEME'));
    });

    test('updateDrawingType normalizes category selections', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(projectFormControllerProvider.notifier);
      controller.updateDrawingType('Architectural');
      expect(container.read(projectFormControllerProvider).drawingType, equals('ARCHITECTURAL'));

      controller.updateDrawingType('FLOOR_PLAN');
      expect(container.read(projectFormControllerProvider).drawingType, equals('FLOOR_PLAN'));
    });
  });
}
