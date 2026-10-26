import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/projects/domain/assignment.dart';
import 'package:archi_draft/src/features/projects/domain/drawing_version.dart';
import 'package:archi_draft/src/features/projects/providers/assignment_providers.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/draughtsman/presentation/studio/draughtsman_studio_screen.dart';
import 'package:archi_draft/src/features/draughtsman/presentation/drawings/draughtsman_drawings_screen.dart';

void main() {
  group('Status Consistency & Filter Separation Tests', () {
    final completedProjectWithPriorCorrections = Assignment(
      id: '04a15e15-317d-46bb-846e-9dcdb5e2fa6d',
      projectId: '5b31d807-8295-4859-9941-ee47b9352e5c',
      draughtsmanId: 'draughtsman-1',
      projectName: 'MVS-1',
      projectAddress: 'Plot 4, Silicon Valley',
      status: 'COMPLETED',
      projectStatus: 'COMPLETED',
      correctionRound: 1, // Past correction round occurred
      assignedAt: DateTime.now().subtract(const Duration(days: 10)),
      approvedAt: DateTime.now().subtract(const Duration(hours: 1)),
      drawingType: 'ARCHITECTURAL',
    );

    final activeCorrectionProject = Assignment(
      id: 'corr-01',
      projectId: 'proj-corr-01',
      draughtsmanId: 'draughtsman-1',
      projectName: 'MVS-2 Corrections',
      status: 'ACCEPTED',
      projectStatus: 'IN_PROGRESS',
      correctionRound: 2,
      assignedAt: DateTime.now().subtract(const Duration(days: 3)),
      drawingType: 'STRUCTURAL',
    );

    final underReviewProject = Assignment(
      id: 'rev-01',
      projectId: 'proj-rev-01',
      draughtsmanId: 'draughtsman-1',
      projectName: 'MVS-3 Under Review',
      status: 'ACCEPTED',
      projectStatus: 'UNDER_ENGINEER_REVIEW',
      correctionRound: 1,
      assignedAt: DateTime.now().subtract(const Duration(days: 4)),
      drawingType: 'MEP',
    );

    final awaitingInitialSubmissionProject = Assignment(
      id: 'init-01',
      projectId: 'proj-init-01',
      draughtsmanId: 'draughtsman-1',
      projectName: 'MVS-4 New Project',
      status: 'PENDING',
      projectStatus: 'ASSIGNED',
      correctionRound: 0,
      assignedAt: DateTime.now().subtract(const Duration(hours: 2)),
      drawingType: 'ARCHITECTURAL',
    );

    testWidgets(
        'Case 1 & 8: Completed project with past corrections shows Completed status and View Project, excluded from Corrections filter',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            draughtsmanAssignmentsProvider.overrideWith(
              (ref) => Future.value([
                completedProjectWithPriorCorrections,
                activeCorrectionProject,
                underReviewProject,
                awaitingInitialSubmissionProject,
              ]),
            ),
          ],
          child: const MaterialApp(
            home: DraughtsmanStudioScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify filter tabs are rendered
      expect(find.text('All Active'), findsOneWidget);
      expect(find.text('Corrections'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      // Verify count badges: New has 1, In Progress has 1, Corrections has 1, Completed has 1
      expect(find.text('1'), findsNWidgets(4));

      // Initially in 'All Active' tab: MVS-2 (active correction) is present, MVS-1 (completed) is excluded
      expect(find.text('MVS-2 Corrections'), findsOneWidget);
      expect(find.text('MVS-1'), findsNothing);

      // Tap "Corrections" filter tab
      await tester.tap(find.text('Corrections'));
      await tester.pumpAndSettle();

      // Only the genuine active correction project appears in the Corrections tab
      expect(find.text('MVS-2 Corrections'), findsOneWidget);
      expect(find.text('Review Correction'), findsOneWidget);
      expect(find.text('MVS-1'), findsNothing);

      // Tap "Completed" filter tab
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      // MVS-1 appears under Completed tab with View Project button, NOT Review Correction
      expect(find.text('MVS-1'), findsOneWidget);
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('View Project'), findsOneWidget);
      expect(find.text('Review Correction'), findsNothing);
    });

    testWidgets(
        'Case 3: Under review project is excluded from active correction queue',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            draughtsmanAssignmentsProvider.overrideWith(
              (ref) => Future.value([underReviewProject]),
            ),
          ],
          child: const MaterialApp(
            home: DraughtsmanStudioScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Review'), findsWidgets);
      expect(find.text('Review Correction'), findsNothing);

      // Tap "Corrections" filter tab - should be empty
      await tester.tap(find.text('Corrections'));
      await tester.pumpAndSettle();

      expect(find.text('MVS-3 Under Review'), findsNothing);
    });
  });

  group('Split-View & Drawing Revision Integrity Tests', () {
    final v1 = DrawingVersion(
      id: 'ver-1',
      projectId: '5b31d807-8295-4859-9941-ee47b9352e5c',
      fileId: 'file-01',
      versionNumber: 1,
      uploadedBy: 'Sarah Jenkins',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      originalName: 'MVS1_Rev1.dwg',
      size: 5242880,
    );

    final v2 = DrawingVersion(
      id: 'ver-2',
      projectId: '5b31d807-8295-4859-9941-ee47b9352e5c',
      fileId: 'file-02',
      versionNumber: 2,
      uploadedBy: 'Sarah Jenkins',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      originalName: 'MVS1_Rev2.dwg',
      size: 5342880,
    );

    final mvs1Assignment = Assignment(
      id: '04a15e15-317d-46bb-846e-9dcdb5e2fa6d',
      projectId: '5b31d807-8295-4859-9941-ee47b9352e5c',
      draughtsmanId: 'draughtsman-1',
      projectName: 'MVS-1',
      status: 'COMPLETED',
      projectStatus: 'COMPLETED',
      correctionRound: 1,
      drawingType: 'ARCHITECTURAL',
    );

    testWidgets(
        'Dual revisions render Previous: v1 on Left and Current: v2 on Right',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            draughtsmanAssignmentsProvider.overrideWith(
              (ref) => Future.value([mvs1Assignment]),
            ),
            projectDrawingVersionsProvider('5b31d807-8295-4859-9941-ee47b9352e5c')
                .overrideWith((ref) => Future.value([v2, v1])),
            projectActivityLogsProvider('5b31d807-8295-4859-9941-ee47b9352e5c')
                .overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp(
            home: DraughtsmanDrawingsScreen(
              initialAssignmentId: mvs1Assignment.id,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Split View shows Previous v1 and Current v2
      expect(find.text('Previous: v1'), findsOneWidget);
      expect(find.text('Current: v2'), findsOneWidget);
      expect(find.text('DIFF HIGHLIGHT'), findsOneWidget);
    });

    testWidgets(
        'Single revision project displays Initial State placeholder for previous panel',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            draughtsmanAssignmentsProvider.overrideWith(
              (ref) => Future.value([mvs1Assignment]),
            ),
            projectDrawingVersionsProvider('5b31d807-8295-4859-9941-ee47b9352e5c')
                .overrideWith((ref) => Future.value([v1])), // Only 1 version
            projectActivityLogsProvider('5b31d807-8295-4859-9941-ee47b9352e5c')
                .overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp(
            home: DraughtsmanDrawingsScreen(
              initialAssignmentId: mvs1Assignment.id,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Left panel shows honest initial state placeholder rather than a duplicated or unrelated drawing
      expect(find.text('Initial State (Rev 1)'), findsOneWidget);
      expect(find.text('No prior revision exists for this project.'), findsOneWidget);
      expect(find.text('Current: v1'), findsOneWidget);
    });
  });
}
