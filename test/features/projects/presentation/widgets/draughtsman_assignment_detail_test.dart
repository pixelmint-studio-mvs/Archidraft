import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/projects/domain/assignment.dart';
import 'package:archi_draft/src/features/projects/domain/drawing_version.dart';
import 'package:archi_draft/src/features/projects/providers/assignment_providers.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/projects/presentation/draughtsman/draughtsman_assignment_detail_screen.dart';

void main() {
  final testAssignment = Assignment(
    id: 'test-assign-01',
    projectId: 'test-proj-01',
    draughtsmanId: 'd-01',
    projectName: 'Draughtsman Portal TEST Project - TEST_FIXTURE_2026',
    projectAddress: '123 Test Street, Dev City',
    status: 'IN_PROGRESS',
    projectStatus: 'UNDER_CLIENT_REVIEW',
    assignedAt: DateTime.now().subtract(const Duration(days: 2)),
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

  final testLogs = [
    {
      'id': 'log-1',
      'project_id': 'test-proj-01',
      'action_type': 'DRAWING_SUBMITTED',
      'details': 'Submitted version 2 for client review',
      'timestamp': DateTime.now().toIso8601String(),
    },
    {
      'id': 'log-2',
      'project_id': 'test-proj-01',
      'action_type': 'FILE_UPLOADED',
      'details': 'Uploaded v2 revised blueprint drawing',
      'timestamp': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
    },
    {
      'id': 'log-3',
      'project_id': 'test-proj-01',
      'action_type': 'ASSIGNMENT_ACCEPTED',
      'details': 'Draughtsman accepted the assignment',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    },
  ];

  Widget buildTestableWidget({Size size = const Size(1280, 800)}) {
    return ProviderScope(
      overrides: [
        assignmentProvider('test-assign-01').overrideWith(
          (ref) => Future.value(testAssignment),
        ),
        projectDrawingVersionsProvider('test-proj-01').overrideWith(
          (ref) => Future.value(testVersions),
        ),
        projectActivityLogsProvider('test-proj-01').overrideWith(
          (ref) => Future.value(testLogs),
        ),
      ],
      child: const MaterialApp(
        home: DraughtsmanAssignmentDetailScreen(assignmentId: 'test-assign-01'),
      ),
    );
  }

  testWidgets('Assignment Detail renders successfully on Desktop (1280x800) with zero overflow', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('Draughtsman Portal TEST Project - TEST_FIXTURE_2026'), findsWidgets);
    expect(find.text('PROJECT WORKFLOW'), findsOneWidget);
    expect(find.text('Split View'), findsOneWidget);
    expect(find.text('Overlay'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Activity Audit'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Assignment Detail renders successfully on Mobile (400x800) with zero overflow', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget(size: const Size(400, 800)));
    await tester.pumpAndSettle();

    expect(find.text('Draughtsman Portal TEST Project - TEST_FIXTURE_2026'), findsWidgets);
    expect(find.text('PROJECT WORKFLOW'), findsOneWidget);
    expect(find.text('Split View'), findsOneWidget);
    expect(find.text('Overlay'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Can toggle between Split View and Overlay mode without errors', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    final overlayButton = find.text('Overlay');
    expect(overlayButton, findsOneWidget);
    await tester.tap(overlayButton);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final splitButton = find.text('Split View');
    expect(splitButton, findsOneWidget);
    await tester.tap(splitButton);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
