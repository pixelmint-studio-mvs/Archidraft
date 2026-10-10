import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/projects/domain/assignment.dart';
import 'package:archi_draft/src/features/projects/domain/drawing_version.dart';
import 'package:archi_draft/src/features/projects/providers/assignment_providers.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/projects/presentation/draughtsman/draughtsman_studio_screen.dart';

void main() {
  final testAssignment = Assignment(
    id: 'test-assign-01',
    projectId: 'test-proj-01',
    draughtsmanId: 'd-01',
    projectName: 'Draughtsman Portal TEST Project - TEST_FIXTURE_2026',
    projectAddress: '123 Test Street, Dev City',
    status: 'IN_PROGRESS',
    projectStatus: 'UNDER_CLIENT_REVIEW',
    assignedAt: DateTime.now(),
    drawingType: 'FLOOR_PLAN',
    correctionRound: 1,
  );

  final testVersions = [
    DrawingVersion(
      id: 'v2',
      projectId: 'test-proj-01',
      fileId: 'file-2',
      versionNumber: 2,
      uploadedBy: 'user-01',
      createdAt: DateTime.now(),
    ),
    DrawingVersion(
      id: 'v1',
      projectId: 'test-proj-01',
      fileId: 'file-1',
      versionNumber: 1,
      uploadedBy: 'user-01',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  testWidgets('Studio screen renders without overflow when Version History expands (Desktop 1280x800)', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          draughtsmanAssignmentsProvider.overrideWith((ref) => Future.value([testAssignment])),
          projectDrawingVersionsProvider('test-proj-01').overrideWith((ref) => Future.value(testVersions)),
        ],
        child: const MaterialApp(
          home: DraughtsmanStudioScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial render (collapsed)
    expect(find.text('Version History'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Click Version History to expand
    await tester.tap(find.text('Version History'));
    await tester.pumpAndSettle();

    // Verify expanded version rows are visible
    expect(find.text('v2.0 (Current)'), findsOneWidget);
    expect(find.text('v1.0'), findsOneWidget);

    // CRITICAL: Verify NO Flutter layout overflow exception
    expect(tester.takeException(), isNull);
  });

  testWidgets('Studio screen renders without overflow on Mobile (400x800)', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          draughtsmanAssignmentsProvider.overrideWith((ref) => Future.value([testAssignment])),
          projectDrawingVersionsProvider('test-proj-01').overrideWith((ref) => Future.value(testVersions)),
        ],
        child: const MaterialApp(
          home: DraughtsmanStudioScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Tap Version History on mobile
    await tester.tap(find.text('Version History'));
    await tester.pumpAndSettle();

    expect(find.text('v2.0 (Current)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Studio screen renders without overflow with multiple revisions (5 versions)', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final fiveVersions = List.generate(
      5,
      (i) => DrawingVersion(
        id: 'v${5 - i}',
        projectId: 'test-proj-01',
        fileId: 'file-${5 - i}',
        versionNumber: 5 - i,
        uploadedBy: 'user-01',
        createdAt: DateTime.now().subtract(Duration(days: i)),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          draughtsmanAssignmentsProvider.overrideWith((ref) => Future.value([testAssignment])),
          projectDrawingVersionsProvider('test-proj-01').overrideWith((ref) => Future.value(fiveVersions)),
        ],
        child: const MaterialApp(
          home: DraughtsmanStudioScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Expand Version History
    await tester.tap(find.text('Version History'));
    await tester.pumpAndSettle();

    expect(find.text('v5.0 (Current)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
