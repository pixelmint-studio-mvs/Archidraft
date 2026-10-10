import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/projects/domain/assignment.dart';
import 'package:archi_draft/src/features/projects/providers/assignment_providers.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/projects/presentation/draughtsman/draughtsman_insights_screen.dart';

void main() {
  final testSummary = {
    'total_assignments': 10,
    'pending': 1,
    'in_progress': 4,
    'under_review': 2,
    'corrections': 1,
    'completed': 2,
    'rejected': 0,
  };

  final testAssignments = [
    Assignment(
      id: 'a-01',
      projectId: '71e348af-382e-4217-aa24-124a8e3458b1',
      draughtsmanId: 'd-01',
      projectName: 'Civic Center Pavilion',
      projectAddress: '100 Civic Center Blvd',
      status: 'IN_PROGRESS',
      projectStatus: 'UNDER_CLIENT_REVIEW',
      assignedAt: DateTime.now().subtract(const Duration(days: 10)),
      submittedAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      drawingType: 'FLOOR_PLAN',
      correctionRound: 0,
    ),
    Assignment(
      id: 'a-02',
      projectId: 'proj-02',
      draughtsmanId: 'd-01',
      projectName: 'Harbor Tower Respec',
      projectAddress: '42 Ocean Way',
      status: 'IN_PROGRESS',
      projectStatus: 'IN_PROGRESS',
      assignedAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      drawingType: 'STRUCTURAL',
      correctionRound: 1,
    ),
    Assignment(
      id: 'a-03',
      projectId: 'proj-03',
      draughtsmanId: 'd-01',
      projectName: 'Metro Station Canopy',
      status: 'COMPLETED',
      projectStatus: 'COMPLETED',
      assignedAt: DateTime.now().subtract(const Duration(days: 20)),
      submittedAt: DateTime.now().subtract(const Duration(days: 12)),
      approvedAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now().subtract(const Duration(days: 10)),
      drawingType: 'ELEVATION',
      correctionRound: 0,
    ),
  ];

  Widget createTestWidget({
    Size surfaceSize = const Size(1280, 800),
    Map<String, dynamic>? summaryOverride,
    List<Assignment>? assignmentsOverride,
  }) {
    return ProviderScope(
      overrides: [
        draughtsmanSummaryProvider.overrideWith(
          (ref) => Future.value(summaryOverride ?? testSummary),
        ),
        draughtsmanAssignmentsProvider.overrideWith(
          (ref) => Future.value(assignmentsOverride ?? testAssignments),
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: const SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: DraughtsmanInsightsScreen(),
          ),
        ),
      ),
    );
  }

  testWidgets('renders Desktop 1280x800 layout with executive metrics', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget(surfaceSize: const Size(1280, 800)));
    await tester.pumpAndSettle();

    // Verify Hero
    expect(find.text('Studio Overview'), findsOneWidget);
    expect(find.text('Welcome back to the executive suite. System vitals are optimal. Here is your current studio performance.'), findsOneWidget);
    expect(find.byKey(const Key('insights_refresh_vitals_button')), findsOneWidget);
    expect(find.byKey(const Key('insights_view_pipeline_button')), findsOneWidget);

    // Verify 3 Bento metric cards
    expect(find.text('COMPLETED OUTPUT'), findsOneWidget);
    expect(find.text('ACTIVE PROJECTS'), findsOneWidget);
    expect(find.text('PRODUCTIVITY'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // completed count
    expect(find.text('7'), findsOneWidget); // active count: 4 in_progress + 2 under_review + 1 corrections = 7
    expect(find.text('90%'), findsOneWidget); // productivity: (10 - 1)/10 = 90%

    // Verify Monthly Growth Chart & Submissions
    expect(find.text('Monthly Growth'), findsOneWidget);
    expect(find.text('Recent Submissions'), findsOneWidget);
    expect(find.text('Civic Center Pavilion'), findsOneWidget);
    expect(find.text('Harbor Tower Respec'), findsOneWidget);

    // Verify Pipeline Distribution
    expect(find.text('Pipeline Distribution & Velocity'), findsOneWidget);
    expect(find.textContaining('Avg Turnaround:'), findsOneWidget);

    // Verify Footer Signature
    expect(find.text('UI/UX Design & Product Experience crafted by PixelMint Studio MVS'), findsOneWidget);
  });

  testWidgets('renders Mobile 400x800 layout without overflow', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget(surfaceSize: const Size(400, 800)));
    await tester.pumpAndSettle();

    expect(find.text('Studio Overview'), findsOneWidget);
    expect(find.text('COMPLETED OUTPUT'), findsOneWidget);
    expect(find.text('ACTIVE PROJECTS'), findsOneWidget);
    expect(find.text('PRODUCTIVITY'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('interacts with time range filter', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget(surfaceSize: const Size(1280, 800)));
    await tester.pumpAndSettle();

    // Find and tap time range menu
    final menuFinder = find.byKey(const Key('insights_time_range_menu'));
    expect(menuFinder, findsOneWidget);
    await tester.tap(menuFinder);
    await tester.pumpAndSettle();

    // Select 'Last 12 Months'
    expect(find.text('Last 12 Months'), findsOneWidget);
    await tester.tap(find.text('Last 12 Months'));
    await tester.pumpAndSettle();

    expect(find.textContaining('assignments logged in last 12 months'), findsOneWidget);
  });

  testWidgets('renders clean empty state with zero data', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final emptySummary = {
      'total_assignments': 0,
      'pending': 0,
      'in_progress': 0,
      'under_review': 0,
      'corrections': 0,
      'completed': 0,
      'rejected': 0,
    };

    await tester.pumpWidget(createTestWidget(
      surfaceSize: const Size(1280, 800),
      summaryOverride: emptySummary,
      assignmentsOverride: [],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Studio Overview'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
    expect(find.text('100%'), findsOneWidget); // default productivity rate when no corrections
    expect(find.text('No submissions yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
