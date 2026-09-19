import 'package:archi_draft/src/features/projects/domain/project_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectValidators', () {
    test('projectName validation', () {
      expect(ProjectValidators.projectName(''), 'Project name is required');
      expect(ProjectValidators.projectName('  '), 'Project name is required');
      expect(
        ProjectValidators.projectName('ab'),
        'Project name must be at least 3 characters',
      );
      expect(ProjectValidators.projectName('Valid Name'), null);
    });

    test('projectArea validation', () {
      expect(ProjectValidators.projectArea(''), 'Project area is required');
      expect(
        ProjectValidators.projectArea('abc'),
        'Please enter a valid number',
      );
      expect(
        ProjectValidators.projectArea('-5'),
        'Project area must be greater than 0',
      );
      expect(
        ProjectValidators.projectArea('0'),
        'Project area must be greater than 0',
      );
      expect(
        ProjectValidators.projectArea('2000000'),
        'Project area cannot exceed 1000000 sq ft',
      );
      expect(ProjectValidators.projectArea('1500.5'), null);
    });

    test('estimatedAmount validation (optional)', () {
      expect(ProjectValidators.estimatedAmount(''), null);
      expect(ProjectValidators.estimatedAmount('  '), null);
      expect(
        ProjectValidators.estimatedAmount('abc'),
        'Please enter a valid amount',
      );
      expect(
        ProjectValidators.estimatedAmount('-500'),
        'Amount must be greater than 0',
      );
      expect(ProjectValidators.estimatedAmount('5000'), null);
    });

    test('isReadyForSubmission checks all required fields', () {
      // Incomplete
      expect(
        ProjectValidators.isReadyForSubmission(
          projectName: '',
          projectAddress: '123 Main St',
          drawingName: 'Ground Floor',
          drawingType: 'FLOOR_PLAN',
          projectArea: 1500,
        ),
        false,
      );

      // Invalid Area
      expect(
        ProjectValidators.isReadyForSubmission(
          projectName: 'Valid Name',
          projectAddress: '123 Main St',
          drawingName: 'Ground Floor',
          drawingType: 'FLOOR_PLAN',
          projectArea: -10,
        ),
        false,
      );

      // Valid
      expect(
        ProjectValidators.isReadyForSubmission(
          projectName: 'Valid Name',
          projectAddress: '123 Main St',
          drawingName: 'Ground Floor',
          drawingType: 'FLOOR_PLAN',
          projectArea: 1500,
        ),
        true,
      );
    });
  });
}
