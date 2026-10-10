import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/projects/domain/assignment.dart';
import 'package:archi_draft/src/features/projects/domain/drawing_version.dart';
import 'package:archi_draft/src/features/projects/providers/assignment_providers.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/projects/presentation/draughtsman/draughtsman_drawings_screen.dart';

void main() {
  final testAssignments = [
    Assignment(
      id: 'e80493d5-34e3-47d1-8c6a-9e983dd25b73',
      projectId: '71e348af-382e-4217-aa24-124a8e3458b1',
      draughtsmanId: 'd-01',
      projectName: 'Civic Center Pavilion',
      projectAddress: '100 Civic Center Blvd, Metropolitan',
      status: 'IN_PROGRESS',
      projectStatus: 'UNDER_CLIENT_REVIEW',
      assignedAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      drawingType: 'FLOOR_PLAN',
      correctionRound: 0,
    ),
    Assignment(
      id: 'a8424ed3-f6a7-442b-b6a6-ad79f4830367',
      projectId: 'proj-02',
      draughtsmanId: 'd-01',
      projectName: 'Harbor Tower Respec',
      projectAddress: '42 Ocean Way, Coastal Bay',
      status: 'IN_PROGRESS',
      projectStatus: 'IN_PROGRESS',
      assignedAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      drawingType: 'STRUCTURAL',
      correctionRound: 1,
    ),
  ];

  final testVersions = [
    DrawingVersion(
      id: 'v4',
      projectId: '71e348af-382e-4217-aa24-124a8e3458b1',
      fileId: 'file-04',
      versionNumber: 4,
      uploadedBy: 'Sarah Jenkins',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      originalName: 'Civic_Center_Pavilion_v4.dwg',
      size: 130023424, // ~124 MB
    ),
    DrawingVersion(
      id: 'v3',
      projectId: '71e348af-382e-4217-aa24-124a8e3458b1',
      fileId: 'file-03',
      versionNumber: 3,
      uploadedBy: 'Sarah Jenkins',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      originalName: 'Civic_Center_Pavilion_v3.dwg',
      size: 125829120, // ~120 MB
    ),
    DrawingVersion(
      id: 'v2',
      projectId: '71e348af-382e-4217-aa24-124a8e3458b1',
      fileId: 'file-02',
      versionNumber: 2,
      uploadedBy: 'Sarah Jenkins',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      originalName: 'Civic_Center_Pavilion_v2.dwg',
      size: 115343360,
    ),
    DrawingVersion(
      id: 'v1',
      projectId: '71e348af-382e-4217-aa24-124a8e3458b1',
      fileId: 'file-01',
      versionNumber: 1,
      uploadedBy: 'Sarah Jenkins',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      originalName: 'Civic_Center_Pavilion_v1.dwg',
      size: 110100480,
    ),
  ];

  final testLogs = [
    {
      'id': 'log-1',
      'project_id': '71e348af-382e-4217-aa24-124a8e3458b1',
      'action_type': 'VERSION_COMMITTED',
      'details': 'Adjusted load-bearing wall specifications on East wing.',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    },
    {
      'id': 'log-2',
      'project_id': '71e348af-382e-4217-aa24-124a8e3458b1',
      'action_type': 'COMMENT_ADDED',
      'details': '"Please verify the HVAC clearance in the central atrium." - M. Torres',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    },
    {
      'id': 'log-3',
      'project_id': '71e348af-382e-4217-aa24-124a8e3458b1',
      'action_type': 'VERSION_APPROVED',
      'details': 'Initial structural review passed.',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    },
  ];

  Widget buildTestableWidget({
    String? initialAssignmentId,
  }) {
    return ProviderScope(
      overrides: [
        draughtsmanAssignmentsProvider.overrideWith(
          (ref) => Future.value(testAssignments),
        ),
        projectDrawingVersionsProvider('71e348af-382e-4217-aa24-124a8e3458b1')
            .overrideWith((ref) => Future.value(testVersions)),
        projectActivityLogsProvider('71e348af-382e-4217-aa24-124a8e3458b1')
            .overrideWith((ref) => Future.value(testLogs)),
      ],
      child: MaterialApp(
        home: DraughtsmanDrawingsScreen(
          initialAssignmentId: initialAssignmentId,
        ),
      ),
    );
  }

  testWidgets(
      'Panel 7 Drawings renders successfully on Desktop (1280x800) matching authoritative reference',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Verify Version Control Header (reference lines 207-226)
    expect(find.text('PRJ-E80493D5'), findsOneWidget);
    expect(find.text('STATUS: REVIEW'), findsOneWidget);
    expect(find.text('Civic Center Pavilion'), findsWidgets);
    expect(find.text('View History'), findsOneWidget);
    expect(find.text('Review Details'), findsOneWidget);

    // Verify Toolbar controls
    expect(find.text('Split View'), findsOneWidget);
    expect(find.text('Overlay'), findsOneWidget);
    expect(find.byIcon(Icons.zoom_in_rounded), findsOneWidget);
    expect(find.byIcon(Icons.zoom_out_rounded), findsOneWidget);
    expect(find.byIcon(Icons.fit_screen_rounded), findsOneWidget);

    // Verify Comparison Viewers (Previous: v3 and Current: v4)
    expect(find.text('Previous: v3'), findsOneWidget);
    expect(find.text('Current: v4'), findsOneWidget);
    expect(find.text('DIFF HIGHLIGHT'), findsOneWidget);

    // Verify Details Card (reference lines 274-295)
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('AUTHOR'), findsOneWidget);
    expect(find.text('Sarah Jenkins'), findsOneWidget);
    expect(find.text('LAST MODIFIED'), findsOneWidget);
    expect(find.text('FILE SIZE & FORMAT'), findsOneWidget);
    expect(find.textContaining('.DWG'), findsOneWidget);
    expect(find.text('Download Drawing (v4)'), findsOneWidget);

    // Verify Activity Audit Card (reference lines 297-325)
    expect(find.text('Activity Audit'), findsOneWidget);
    expect(find.text('Version Committed'), findsWidgets);
    expect(find.text('Comment Added'), findsOneWidget);
    expect(
        find.text(
            '"Please verify the HVAC clearance in the central atrium." - M. Torres'),
        findsOneWidget);
  });

  testWidgets(
      'Panel 7 Drawings renders successfully on Mobile (400x800) with zero overflow',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Verify title and chips are rendered without RenderFlex overflow
    expect(find.text('PRJ-E80493D5'), findsOneWidget);
    expect(find.text('STATUS: REVIEW'), findsOneWidget);
    expect(find.text('Civic Center Pavilion'), findsWidgets);
    expect(find.text('View History'), findsOneWidget);
    expect(find.text('Split View'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Activity Audit'), findsOneWidget);

    // Verify no flutter exceptions or overflows occurred
    expect(tester.takeException(), isNull);
  });

  testWidgets('Can toggle between Split View and Overlay mode', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Initially in Split View
    expect(find.text('Previous: v3'), findsOneWidget);
    expect(find.text('Current: v4'), findsOneWidget);

    // Tap Overlay button
    await tester.tap(find.text('Overlay'));
    await tester.pumpAndSettle();

    // Overlay slider is now present
    expect(find.byType(Slider), findsOneWidget);
    expect(find.textContaining('OVERLAY: 50% Current (v4)'), findsOneWidget);

    // Tap Split View button back
    await tester.tap(find.text('Split View'));
    await tester.pumpAndSettle();

    expect(find.text('Previous: v3'), findsOneWidget);
    expect(find.text('Current: v4'), findsOneWidget);
  });

  testWidgets('Can open Version History modal sheet and inspect all revisions',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Tap View History button
    await tester.tap(find.text('View History'));
    await tester.pumpAndSettle();

    // Modal sheet opens
    expect(find.text('Version History'), findsOneWidget);
    expect(find.text('4 committed technical revisions'), findsOneWidget);
    expect(find.text('v4'), findsWidgets);
    expect(find.text('v3'), findsWidgets);
    expect(find.text('v2'), findsWidgets);
    expect(find.text('v1'), findsWidgets);
    expect(find.text('Civic_Center_Pavilion_v4.dwg'), findsOneWidget);
  });

  testWidgets('Can toggle to All Sets gallery view and back to inspection',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Tap All Sets button
    await tester.tap(find.text('All Sets (2)'));
    await tester.pumpAndSettle();

    // Gallery view opens
    expect(find.text('Drawings Library'), findsOneWidget);
    expect(find.text('2 drawing sets'), findsOneWidget);
    expect(find.text('Harbor Tower Respec'), findsOneWidget);

    // Tap Back to Inspection
    await tester.tap(find.text('Back to Inspection'));
    await tester.pumpAndSettle();

    expect(find.text('Civic Center Pavilion'), findsWidgets);
    expect(find.text('Split View'), findsOneWidget);
  });
}
