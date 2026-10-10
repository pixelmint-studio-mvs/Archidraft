import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/projects/domain/assignment.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/domain/drawing_version.dart';
import 'package:archi_draft/src/features/projects/providers/assignment_providers.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/projects/providers/file_providers.dart';
import 'package:archi_draft/src/features/projects/presentation/draughtsman/draughtsman_workspace_screen.dart';

void main() {
  final testAssignment = Assignment(
    id: 'test-assign-ws-01',
    projectId: 'test-proj-ws-01',
    draughtsmanId: 'd-01',
    projectName: 'Oslo Opera House Extension - CAD Workspace',
    projectAddress: '123 Harbor Front, Oslo',
    status: 'ACCEPTED',
    projectStatus: 'IN_PROGRESS',
    assignedAt: DateTime.now().subtract(const Duration(days: 3)),
    drawingType: 'ARCHITECTURAL_DRAFTING',
    correctionRound: 0,
  );

  final testProject = Project(
    projectId: 'test-proj-ws-01',
    clientId: 'c-01',
    projectName: 'Oslo Opera House Extension - CAD Workspace',
    projectAddress: '123 Harbor Front, Oslo',
    drawingName: 'Floor Plan Level 2',
    drawingType: 'ARCHITECTURAL_DRAFTING',
    status: 'IN_PROGRESS',
    projectArea: 14500.0,
    correctionRound: 0,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  );

  final testVersions = [
    DrawingVersion(
      id: 'v2',
      projectId: 'test-proj-ws-01',
      fileId: 'file-2',
      versionNumber: 2,
      uploadedBy: 'd-01',
      createdAt: DateTime.now(),
    ),
    DrawingVersion(
      id: 'v1',
      projectId: 'test-proj-ws-01',
      fileId: 'file-1',
      versionNumber: 1,
      uploadedBy: 'd-01',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  final testLogs = [
    {
      'id': 'log-1',
      'project_id': 'test-proj-ws-01',
      'action_type': 'DRAWING_SUBMITTED',
      'details': 'Submitted version 2 for client review',
      'timestamp': DateTime.now().toIso8601String(),
    },
    {
      'id': 'log-2',
      'project_id': 'test-proj-ws-01',
      'action_type': 'FILE_UPLOADED',
      'details': 'Uploaded v2 revised blueprint drawing',
      'timestamp': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
    },
  ];

  Widget buildTestableWidget({Size size = const Size(1280, 800)}) {
    return ProviderScope(
      overrides: [
        assignmentProvider('test-assign-ws-01').overrideWith(
          (ref) => Future.value(testAssignment),
        ),
        projectProvider('test-proj-ws-01').overrideWith(
          (ref) => Future.value(testProject),
        ),
        projectDrawingVersionsProvider('test-proj-ws-01').overrideWith(
          (ref) => Future.value(testVersions),
        ),
        projectActivityLogsProvider('test-proj-ws-01').overrideWith(
          (ref) => Future.value(testLogs),
        ),
        projectCorrectionsProvider('test-proj-ws-01').overrideWith(
          (ref) => Future.value([]),
        ),
        projectFilesProvider('test-proj-ws-01').overrideWith(
          (ref) => Future.value([]),
        ),
      ],
      child: const MaterialApp(
        home: DraughtsmanWorkspaceScreen(assignmentId: 'test-assign-ws-01'),
      ),
    );
  }

  testWidgets('Workspace renders on Desktop (1280x800) with zero overflow', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('WORKSPACE CANVAS'), findsOneWidget);
    expect(find.text('Split View'), findsOneWidget);
    expect(find.text('Overlay'), findsOneWidget);
    expect(find.text('Details & Specifications'), findsOneWidget);
    expect(find.text('UPLOAD REVISION DRAWING'), findsOneWidget);
    expect(find.text('VERSION HISTORY'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Workspace renders on Mobile (400x800) with zero overflow', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget(size: const Size(400, 800)));
    await tester.pumpAndSettle();

    expect(find.text('WORKSPACE CANVAS'), findsOneWidget);
    expect(find.text('Split View'), findsOneWidget);
    expect(find.text('Overlay'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Can toggle Split View and Overlay mode in Workspace', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    final overlayBtn = find.text('Overlay');
    expect(overlayBtn, findsOneWidget);
    await tester.tap(overlayBtn);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final splitBtn = find.text('Split View');
    expect(splitBtn, findsOneWidget);
    await tester.tap(splitBtn);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Can switch tabs between Workspace, Specs and Timeline', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    final specsTab = find.text('OVERVIEW & SPECS');
    expect(specsTab, findsOneWidget);
    await tester.tap(specsTab);
    await tester.pumpAndSettle();

    expect(find.text('PROJECT SPECIFICATIONS'), findsOneWidget);
    expect(find.text('Oslo Opera House Extension - CAD Workspace'), findsAtLeastNWidgets(1));
    expect(find.text('Floor Plan Level 2'), findsOneWidget);
    expect(find.text('14500.0 sq ft'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('Round 0'), findsOneWidget);
    expect(find.text('CLIENT REFERENCE FILES'), findsOneWidget);
    expect(find.text('No reference files attached by client.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final timelineTab = find.text('TIMELINE & AUDIT');
    expect(timelineTab, findsOneWidget);
    await tester.tap(timelineTab);
    await tester.pumpAndSettle();

    expect(find.text('ACTIVITY AUDIT'), findsOneWidget);
    expect(find.text('Drawing Submitted'), findsOneWidget);
    expect(find.text('File Uploaded'), findsOneWidget);
    expect(find.text('Submitted version 2 for client review'), findsOneWidget);
    expect(find.text('Uploaded v2 revised blueprint drawing'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Overview tab and Timeline tab render with initialTab parameter', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Deep link to timeline tab directly
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assignmentProvider('test-assign-ws-01').overrideWith(
            (ref) => Future.value(testAssignment),
          ),
          projectProvider('test-proj-ws-01').overrideWith(
            (ref) => Future.value(testProject),
          ),
          projectDrawingVersionsProvider('test-proj-ws-01').overrideWith(
            (ref) => Future.value(testVersions),
          ),
          projectActivityLogsProvider('test-proj-ws-01').overrideWith(
            (ref) => Future.value(testLogs),
          ),
          projectCorrectionsProvider('test-proj-ws-01').overrideWith(
            (ref) => Future.value([]),
          ),
          projectFilesProvider('test-proj-ws-01').overrideWith(
            (ref) => Future.value([]),
          ),
        ],
        child: const MaterialApp(
          home: DraughtsmanWorkspaceScreen(
            assignmentId: 'test-assign-ws-01',
            initialTab: 'timeline',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ACTIVITY AUDIT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Timeline tab handles empty activity logs gracefully', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assignmentProvider('test-assign-ws-01').overrideWith(
            (ref) => Future.value(testAssignment),
          ),
          projectProvider('test-proj-ws-01').overrideWith(
            (ref) => Future.value(testProject),
          ),
          projectDrawingVersionsProvider('test-proj-ws-01').overrideWith(
            (ref) => Future.value(testVersions),
          ),
          projectActivityLogsProvider('test-proj-ws-01').overrideWith(
            (ref) => Future.value([]),
          ),
          projectCorrectionsProvider('test-proj-ws-01').overrideWith(
            (ref) => Future.value([]),
          ),
          projectFilesProvider('test-proj-ws-01').overrideWith(
            (ref) => Future.value([]),
          ),
        ],
        child: const MaterialApp(
          home: DraughtsmanWorkspaceScreen(
            assignmentId: 'test-assign-ws-01',
            initialTab: 'timeline',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ACTIVITY AUDIT'), findsOneWidget);
    expect(find.text('No Activity Yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
