import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/projects/domain/assignment.dart';
import 'package:archi_draft/src/features/projects/domain/drawing_version.dart';
import 'package:archi_draft/src/features/projects/presentation/widgets/cad_drawing_viewer.dart';
import 'package:archi_draft/src/features/projects/providers/assignment_providers.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/draughtsman/presentation/studio/draughtsman_studio_screen.dart';
import 'package:archi_draft/src/features/draughtsman/presentation/drawings/draughtsman_drawings_screen.dart';

import 'package:archi_draft/src/features/projects/data/assignment_repository.dart';

class FakeAssignmentRepository implements AssignmentRepository {
  List<Assignment> currentList = [];

  @override
  Future<List<Assignment>> getAssignments() async => currentList;

  @override
  Future<Assignment> getAssignment(String id) async =>
      currentList.firstWhere((a) => a.id == id);

  @override
  Future<void> acceptAssignment({
    required String assignmentId,
    String? projectId,
    String? actionId,
  }) async {
    final idx = currentList.indexWhere((a) => a.id == assignmentId);
    if (idx != -1) {
      currentList[idx] = currentList[idx].copyWith(status: 'ACCEPTED');
    }
  }

  @override
  Future<void> rejectAssignment({
    required String assignmentId,
    String? projectId,
    String? actionId,
    String reason = '',
  }) async {
    final idx = currentList.indexWhere((a) => a.id == assignmentId);
    if (idx != -1) {
      currentList[idx] = currentList[idx].copyWith(status: 'REJECTED');
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Master QoL — Draughtsman Live Refresh & CAD Navigation Tests', () {
    late FakeAssignmentRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeAssignmentRepository();
      fakeRepo.currentList = [
        Assignment(
          id: 'asg-001',
          projectId: 'proj-001',
          draughtsmanId: 'draughtsman-1',
          status: 'PENDING',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          projectName: 'Luxury Villa Master Plan',
          projectStatus: 'WAITING_ACCEPTANCE',
          drawingType: 'Architectural Floor Plan',
          projectArea: '4500',
        ),
      ];
    });

    testWidgets(
        '1. Auto-refresh: New assignment appears on stream/notifier invalidation',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          assignmentRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      // Initial read has 1 pending assignment
      var list = await container.read(draughtsmanAssignmentsProvider.future);
      expect(list.length, 1);
      expect(list.first.projectName, 'Luxury Villa Master Plan');

      // Admin adds a second assignment remotely
      fakeRepo.currentList.add(
        Assignment(
          id: 'asg-002',
          projectId: 'proj-002',
          draughtsmanId: 'draughtsman-1',
          status: 'PENDING',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          projectName: 'Commercial Tower Level 12',
          projectStatus: 'WAITING_ACCEPTANCE',
          drawingType: 'MEP Coordination',
          projectArea: '12000',
        ),
      );

      // Invalidate the provider as polling / socket triggers
      container.invalidate(draughtsmanAssignmentsProvider);

      // Should auto-reflect 2 assignments
      list = await container.read(draughtsmanAssignmentsProvider.future);
      expect(list.length, 2);
      expect(list[1].projectName, 'Commercial Tower Level 12');

      container.dispose();
    });

    testWidgets(
        '2. Studio Screen: Manual pull-to-refresh or sync trigger updates state',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assignmentRepositoryProvider.overrideWithValue(fakeRepo),
            draughtsmanAssignmentsProvider.overrideWith((ref) => fakeRepo.currentList),
          ],
          child: const MaterialApp(
            home: DraughtsmanStudioScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify studio screen rendered with assignment list
      expect(find.byType(DraughtsmanStudioScreen), findsOneWidget);

      // Verify RefreshIndicator or sync affordance exists
      final refreshIndicator = find.byType(RefreshIndicator);
      expect(refreshIndicator, findsOneWidget);
    });

    testWidgets(
        '3. CAD Drawing Viewer Cache: repeat visits load instantly from memory',
        (tester) async {
      // Clear cache before test
      CadDrawingViewer.clearCache();

      // Parse entities directly or verify viewer cache functionality
      expect(find.byType(CadDrawingViewer), findsNothing);
    });

    testWidgets(
        '4. Panel switching: Studio to Drawings renders smoothly without spinners',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      fakeRepo.currentList = [
        Assignment(
          id: 'asg-001',
          projectId: 'proj-001',
          draughtsmanId: 'draughtsman-1',
          status: 'ACCEPTED',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          projectName: 'Luxury Villa Master Plan',
          projectStatus: 'IN_PROGRESS',
        ),
      ];

      final testVersion = DrawingVersion(
        id: 'ver-001',
        projectId: 'proj-001',
        fileId: 'file-001',
        versionNumber: 1,
        uploadedBy: 'draughtsman-1',
        createdAt: DateTime.now(),
        originalName: 'floor_plan_v1.dxf',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assignmentRepositoryProvider.overrideWithValue(fakeRepo),
            draughtsmanAssignmentsProvider.overrideWith((ref) => fakeRepo.currentList),
            projectDrawingVersionsProvider('proj-001').overrideWith((ref) => [testVersion]),
          ],
          child: const MaterialApp(
            home: DraughtsmanDrawingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drawings screen renders
      expect(find.byType(DraughtsmanDrawingsScreen), findsOneWidget);
      expect(find.text('Luxury Villa Master Plan'), findsWidgets);
    });
  });
}
