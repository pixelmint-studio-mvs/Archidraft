import 'package:archi_draft/src/features/projects/data/assignment_repository.dart';
import 'package:archi_draft/src/features/projects/providers/assignment_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'assignment_providers_test.mocks.dart';

@GenerateMocks([AssignmentRepository])
void main() {
  group('DraughtsmanActionsController', () {
    late ProviderContainer container;
    late MockAssignmentRepository mockRepository;

    setUp(() {
      mockRepository = MockAssignmentRepository();
      container = ProviderContainer(
        overrides: [
          assignmentRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('acceptAssignment success', () async {
      when(mockRepository.acceptAssignment(
        assignmentId: anyNamed('assignmentId'),
        projectId: anyNamed('projectId'),
        actionId: anyNamed('actionId'),
      )).thenAnswer((_) async => {});

      final controller = container.read(draughtsmanActionsControllerProvider.notifier);
      
      // Before action, state should be AsyncData
      expect(container.read(draughtsmanActionsControllerProvider), isA<AsyncData>());

      final success = await controller.acceptAssignment(
        assignmentId: 'assign_123',
        projectId: 'proj_123',
      );

      expect(success, isTrue);
      expect(container.read(draughtsmanActionsControllerProvider), isA<AsyncData>());
      verify(mockRepository.acceptAssignment(
        assignmentId: 'assign_123',
        projectId: 'proj_123',
        actionId: anyNamed('actionId'),
      )).called(1);
    });

    test('acceptAssignment error', () async {
      when(mockRepository.acceptAssignment(
        assignmentId: anyNamed('assignmentId'),
        projectId: anyNamed('projectId'),
        actionId: anyNamed('actionId'),
      )).thenThrow(Exception('Failed to accept'));

      final controller = container.read(draughtsmanActionsControllerProvider.notifier);
      
      final success = await controller.acceptAssignment(
        assignmentId: 'assign_123',
        projectId: 'proj_123',
      );

      expect(success, isFalse);
      expect(container.read(draughtsmanActionsControllerProvider), isA<AsyncError>());
    });
    
    test('rejectAssignment success', () async {
      when(mockRepository.rejectAssignment(
        assignmentId: anyNamed('assignmentId'),
        projectId: anyNamed('projectId'),
        actionId: anyNamed('actionId'),
      )).thenAnswer((_) async => {});

      final controller = container.read(draughtsmanActionsControllerProvider.notifier);
      
      final success = await controller.rejectAssignment(
        assignmentId: 'assign_456',
        projectId: 'proj_456',
      );

      expect(success, isTrue);
      expect(container.read(draughtsmanActionsControllerProvider), isA<AsyncData>());
      verify(mockRepository.rejectAssignment(
        assignmentId: 'assign_456',
        projectId: 'proj_456',
        actionId: anyNamed('actionId'),
      )).called(1);
    });

    test('rejectAssignment error', () async {
      when(mockRepository.rejectAssignment(
        assignmentId: anyNamed('assignmentId'),
        projectId: anyNamed('projectId'),
        actionId: anyNamed('actionId'),
      )).thenThrow(Exception('Failed to reject'));

      final controller = container.read(draughtsmanActionsControllerProvider.notifier);
      
      final success = await controller.rejectAssignment(
        assignmentId: 'assign_456',
        projectId: 'proj_456',
      );

      expect(success, isFalse);
      expect(container.read(draughtsmanActionsControllerProvider), isA<AsyncError>());
    });
  });
}
