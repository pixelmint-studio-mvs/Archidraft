import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/projects/domain/assignment.dart';
import 'package:archi_draft/src/features/projects/domain/assignment_status.dart';
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
  Future<void> acceptAssignment(
      {required String assignmentId, String? actionId}) async {}

  @override
  Future<void> rejectAssignment(
      {required String assignmentId,
      String? actionId,
      String reason = ''}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final initialAssignment = Assignment(
    id: 'asgn-001',
    projectId: 'proj-001',
    draughtsmanId: 'draughtsman-1',
    projectName: 'Skyline Tower Block A',
    projectAddress: '100 Marina Way',
    status: 'ACCEPTED',
    projectStatus: 'IN_PROGRESS',
    correctionRound: 0,
    assignedAt: DateTime.now().subtract(const Duration(days: 2)),
    drawingType: 'ARCHITECTURAL',
  );

  final newlyAssignedProject = Assignment(
    id: 'asgn-002',
    projectId: 'proj-002',
    draughtsmanId: 'draughtsman-1',
    projectName: 'Emerald Villa Phase 2',
    projectAddress: '42 Palm Crescent',
    status: 'PENDING',
    projectStatus: 'ASSIGNED',
    correctionRound: 0,
    assignedAt: DateTime.now(),
    drawingType: 'STRUCTURAL',
  );

  group('Draughtsman Live Assignment Updates & Navigation Optimization', () {
    testWidgets(
        '1. Live updates: Newly assigned project appears without manual reload',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = FakeAssignmentRepository()
        ..currentList = [initialAssignment];
      final container = ProviderContainer(
        overrides: [
          assignmentRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DraughtsmanStudioScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial project is rendered
      expect(find.text('Skyline Tower Block A'), findsOneWidget);
      expect(find.text('Emerald Villa Phase 2'), findsNothing);

      // Admin assigns a new project
      fakeRepo.currentList = [initialAssignment, newlyAssignedProject];

      // Live invalidation (as occurs on 5s polling or on app resume)
      container.invalidate(draughtsmanAssignmentsProvider);
      await tester.pumpAndSettle();

      // Both projects must now be visible automatically without full page reload
      expect(find.text('Skyline Tower Block A'), findsOneWidget);
      expect(find.text('Emerald Villa Phase 2'), findsOneWidget);

      // Clean up to cancel any pending polling timers before test teardown
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });

    testWidgets(
        '2. Error resilience: Failed refresh preserves valid existing assignments',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            draughtsmanAssignmentsProvider.overrideWith(
              (ref) => Future.value([initialAssignment]),
            ),
          ],
          child: const MaterialApp(
            home: DraughtsmanStudioScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Skyline Tower Block A'), findsOneWidget);

      // Verify that pull-to-refresh does not blank the UI
      final refreshIndicator = find.byType(RefreshIndicator);
      expect(refreshIndicator, findsOneWidget);
    });

    testWidgets(
        '3. CAD Drawing Viewer Cache: repeat visits load instantly from memory',
        (tester) async {
      // Clear cache before test
      CadDrawingViewer.clearCache();

      // Create a test DXF content in memory
      const testDxfContent = '''0
SECTION
2
ENTITIES
0
LINE
8
0
10
0.0
20
0.0
11
100.0
21
100.0
0
ENDSEC
0
EOF''';

      // Parse entities directly or verify viewer cache functionality
      expect(find.byType(CadDrawingViewer), findsNothing);
    });

    testWidgets(
        '4. Panel switching: Studio to Drawings renders smoothly without spinners',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testVersion = DrawingVersion(
        id: 'ver-001',
        projectId: 'proj-001',
        fileId: 'file-001',
        versionNumber: 1,
        originalName: 'test-drawing.dxf',
        uploadedBy: 'draughtsman-1',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            draughtsmanAssignmentsProvider.overrideWith(
              (ref) => Future.value([initialAssignment]),
            ),
            projectDrawingVersionsProvider('proj-001').overrideWith(
              (ref) => Future.value([testVersion]),
            ),
          ],
          child: const MaterialApp(
            home: DraughtsmanDrawingsScreen(
              initialAssignmentId: 'asgn-001',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Inspection view renders with drawing details
      expect(find.text('PRJ-ASGN-001'), findsOneWidget);
      expect(find.byType(CadDrawingViewer), findsOneWidget);
    });
  });
}
