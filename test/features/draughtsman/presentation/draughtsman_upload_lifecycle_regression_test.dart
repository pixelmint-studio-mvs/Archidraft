import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/projects/domain/assignment.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/domain/project_file.dart';
import 'package:archi_draft/src/features/projects/domain/project_status.dart';
import 'package:archi_draft/src/features/projects/providers/assignment_providers.dart';
import 'package:archi_draft/src/features/projects/providers/file_providers.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/draughtsman/presentation/workspace/draughtsman_workspace_screen.dart';

void main() {
  group('Draughtsman Upload Lifecycle & Submission Prevention Regression Tests', () {
    testWidgets('1. Project in UNDER_ADMIN_REVIEW renders "Waiting for Studio Review" and disables submit', (tester) async {
      const testProject = Project(
        projectId: 'prj-test-1',
        projectName: 'Villa Master Plan',
        projectAddress: '101 Palm Way',
        drawingName: 'Ground Floor Plan',
        drawingType: 'ARCHITECTURAL',
        clientId: 'eng-1',
        status: 'UNDER_ADMIN_REVIEW',
      );

      const testAssignment = Assignment(
        id: 'asg-test-1',
        projectId: 'prj-test-1',
        draughtsmanId: 'drg-1',
        status: 'ACCEPTED',
        projectStatus: 'UNDER_ADMIN_REVIEW',
      );

      final container = ProviderContainer(
        overrides: [
          projectProvider('prj-test-1').overrideWith((ref) => Future.value(testProject)),
          assignmentProvider('asg-test-1').overrideWith((ref) => Future.value(testAssignment)),
          projectFilesProvider('prj-test-1').overrideWith((ref) => Future.value([
            ProjectFile(
              id: 'file-1',
              projectId: 'prj-test-1',
              uploadedBy: 'drg-1',
              originalName: 'master_plan.dxf',
              sanitizedName: 'master_plan.dxf',
              objectKey: 'projects/prj-test-1/draughtsman_version/master_plan.dxf',
              contentType: 'application/dxf',
              size: 2048,
              category: 'draughtsman_version',
              status: 'COMPLETED',
              createdAt: DateTime.now(),
            ),
          ])),
          projectCorrectionsProvider('prj-test-1').overrideWith((ref) => Future.value([])),
          projectDrawingVersionsProvider('prj-test-1').overrideWith((ref) => Future.value([])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DraughtsmanWorkspaceScreen(assignmentId: 'asg-test-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify "Waiting for Studio Review" is displayed
      expect(find.text('Waiting for Studio Review'), findsWidgets);

      // Verify that upload is locked while under review
      expect(find.text('Upload locked while under review'), findsOneWidget);

      // Verify that no active "Submit for Studio Review" FilledButton is clickable
      final submitButton = find.widgetWithText(FilledButton, 'Submit for Studio Review');
      expect(submitButton, findsNothing);
    });

    testWidgets('2. Project in UNDER_ADMIN_REVIEW after correction renders "Resubmitted — Waiting for Studio Review"', (tester) async {
      const testProject = Project(
        projectId: 'prj-test-corr',
        projectName: 'Tower Elevation Rev',
        projectAddress: '202 Skyline Blvd',
        drawingName: 'North Elevation',
        drawingType: 'ARCHITECTURAL',
        clientId: 'eng-1',
        status: 'UNDER_ADMIN_REVIEW',
        correctionRound: 1,
      );

      const testAssignment = Assignment(
        id: 'asg-test-corr',
        projectId: 'prj-test-corr',
        draughtsmanId: 'drg-1',
        status: 'ACCEPTED',
        projectStatus: 'UNDER_ADMIN_REVIEW',
        correctionRound: 1,
      );

      final container = ProviderContainer(
        overrides: [
          projectProvider('prj-test-corr').overrideWith((ref) => Future.value(testProject)),
          assignmentProvider('asg-test-corr').overrideWith((ref) => Future.value(testAssignment)),
          projectFilesProvider('prj-test-corr').overrideWith((ref) => Future.value([
            ProjectFile(
              id: 'file-corr-1',
              projectId: 'prj-test-corr',
              uploadedBy: 'drg-1',
              originalName: 'tower_elevation_v2.dxf',
              sanitizedName: 'tower_elevation_v2.dxf',
              objectKey: 'projects/prj-test-corr/draughtsman_version/tower_elevation_v2.dxf',
              contentType: 'application/dxf',
              size: 2048,
              category: 'draughtsman_version',
              status: 'COMPLETED',
              createdAt: DateTime.now(),
            ),
          ])),
          projectCorrectionsProvider('prj-test-corr').overrideWith((ref) => Future.value([])),
          projectDrawingVersionsProvider('prj-test-corr').overrideWith((ref) => Future.value([])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DraughtsmanWorkspaceScreen(assignmentId: 'asg-test-corr'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify "Resubmitted — Waiting for Studio Review" is rendered for correction
      expect(find.text('Resubmitted — Waiting for Studio Review'), findsWidgets);
      expect(find.text('Upload locked while under review'), findsOneWidget);

      // Ensure no active submit button is clickable
      final submitButton = find.widgetWithText(FilledButton, 'Submit Corrected Drawing');
      expect(submitButton, findsNothing);
    });

    testWidgets('3. Project state transition to UNDER_ADMIN_REVIEW reactively updates workspace controls', (tester) async {
      var currentProject = const Project(
        projectId: 'prj-live-1',
        projectName: 'Dynamic Transition Project',
        projectAddress: '303 River Road',
        drawingName: 'Section Detail',
        drawingType: 'ARCHITECTURAL',
        clientId: 'eng-1',
        status: 'IN_PROGRESS',
      );

      var currentAssignment = const Assignment(
        id: 'asg-live-1',
        projectId: 'prj-live-1',
        draughtsmanId: 'drg-1',
        status: 'ACCEPTED',
        projectStatus: 'IN_PROGRESS',
      );

      final container = ProviderContainer(
        overrides: [
          projectProvider('prj-live-1').overrideWith((ref) => Future.value(currentProject)),
          assignmentProvider('asg-live-1').overrideWith((ref) => Future.value(currentAssignment)),
          projectFilesProvider('prj-live-1').overrideWith((ref) => Future.value([
            ProjectFile(
              id: 'file-live-1',
              projectId: 'prj-live-1',
              uploadedBy: 'drg-1',
              originalName: 'dynamic_plan.dxf',
              sanitizedName: 'dynamic_plan.dxf',
              objectKey: 'projects/prj-live-1/draughtsman_version/dynamic_plan.dxf',
              contentType: 'application/dxf',
              size: 2048,
              category: 'draughtsman_version',
              status: 'COMPLETED',
              createdAt: DateTime.now(),
            ),
          ])),
          projectCorrectionsProvider('prj-live-1').overrideWith((ref) => Future.value([])),
          projectDrawingVersionsProvider('prj-live-1').overrideWith((ref) => Future.value([])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DraughtsmanWorkspaceScreen(assignmentId: 'asg-live-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially in progress with completed drawing -> "Submit for Studio Review" is shown
      expect(find.text('Submit for Studio Review'), findsOneWidget);

      // Simulate successful upload endpoint transitioning project to UNDER_ADMIN_REVIEW
      currentProject = currentProject.copyWith(status: 'UNDER_ADMIN_REVIEW');
      currentAssignment = const Assignment(
        id: 'asg-live-1',
        projectId: 'prj-live-1',
        draughtsmanId: 'drg-1',
        status: 'ACCEPTED',
        projectStatus: 'UNDER_ADMIN_REVIEW',
      );

      container.invalidate(projectProvider('prj-live-1'));
      container.invalidate(assignmentProvider('asg-live-1'));
      await tester.pumpAndSettle();

      // Must now show "Waiting for Studio Review" and lock upload without sending redundant submit
      expect(find.text('Waiting for Studio Review'), findsWidgets);
      expect(find.text('Upload locked while under review'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Submit for Studio Review'), findsNothing);
    });
  });
}
