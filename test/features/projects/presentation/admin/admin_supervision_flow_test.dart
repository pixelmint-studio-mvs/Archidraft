import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:archi_draft/src/features/auth/domain/user_profile.dart';
import 'package:archi_draft/src/features/projects/domain/drawing_version.dart';
import 'package:archi_draft/src/features/projects/domain/evaluation.dart';
import 'package:archi_draft/src/features/projects/domain/correction.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/presentation/admin/admin_projects_screen.dart';
import 'package:archi_draft/src/features/projects/presentation/admin/admin_project_detail_screen.dart';
import 'package:archi_draft/src/features/projects/providers/admin_providers.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';

void main() {
  final testTrainingProject = Project(
    projectId: 'proj_train_test_01',
    projectName: 'Academic Studio Hospital',
    projectAddress: 'Campus Block C',
    drawingName: 'Level 1 Floor Plan',
    drawingType: 'Floor Plan',
    clientId: 'SUPERVISOR_ADMIN_01',
    assignedDraughtsmanId: 'STUDENT_ALICE_01',
    currentAssignmentId: 'SA_TEST_01',
    status: 'UNDER_CLIENT_REVIEW',
    isTrainingProject: 1,
    trainingModuleId: 'MOD_ARCH_01',
    correctionRound: 0,
    createdAt: DateTime.utc(2026, 10, 10, 10, 0),
  );

  final testDrawingVersion = DrawingVersion(
    id: 'ver_test_01',
    projectId: 'proj_train_test_01',
    versionNumber: 1,
    fileId: 'file_dwg_01',
    uploadedBy: 'STUDENT_ALICE_01',
    createdAt: DateTime.utc(2026, 10, 11, 14, 0),
  );

  final testCandidateStudent = const UserProfile(
    id: 'STUDENT_BOB_02',
    name: 'Bob Student',
    email: 'bob@example.com',
    mobile: '9876543210',
    role: 'STUDENT',
  );

  final testCandidateDraughtsman = const UserProfile(
    id: 'DMAN_CHARLIE_01',
    name: 'Charlie Draughtsman',
    email: 'charlie@example.com',
    mobile: '9876543211',
    role: 'DRAUGHTSMAN',
  );

  Widget createDetailTestApp({
    Project? project,
    List<DrawingVersion> versions = const [],
    List<Evaluation> evaluations = const [],
    List<Correction> corrections = const [],
    List<UserProfile> availableUsers = const [],
  }) {
    return ProviderScope(
      overrides: [
        projectProvider('proj_train_test_01').overrideWith(
          (ref) async => project,
        ),
        projectDrawingVersionsProvider('proj_train_test_01').overrideWith(
          (ref) async => versions,
        ),
        projectEvaluationsProvider('proj_train_test_01').overrideWith(
          (ref) async => evaluations,
        ),
        projectCorrectionsProvider('proj_train_test_01').overrideWith(
          (ref) async => corrections,
        ),
        draughtsmenListProvider.overrideWith(
          (ref) async => availableUsers,
        ),
      ],
      child: const MaterialApp(
        home: AdminProjectDetailScreen(projectId: 'proj_train_test_01'),
      ),
    );
  }

  group('AdminProjectsScreen Supervision Tests', () {
    testWidgets('Renders 5 tabs including Under Review tab', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectsByStatusProvider('SUBMITTED').overrideWith(
              (ref) async => const [],
            ),
            projectsByStatusProvider('WAITING_ASSIGNMENT').overrideWith(
              (ref) async => const [],
            ),
            projectsByStatusProvider('IN_PROGRESS').overrideWith(
              (ref) async => const [],
            ),
            projectsByStatusProvider('UNDER_CLIENT_REVIEW').overrideWith(
              (ref) async => [testTrainingProject],
            ),
            projectsByStatusProvider('COMPLETED').overrideWith(
              (ref) async => const [],
            ),
          ],
          child: const MaterialApp(home: AdminProjectsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Unassigned'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Under Review'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      // Tap Under Review tab
      await tester.tap(find.text('Under Review'));
      await tester.pumpAndSettle();

      expect(find.text('Academic Studio Hospital'), findsOneWidget);
    });

    testWidgets('Empty state displays "No projects found in this state." in tab', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectsByStatusProvider('SUBMITTED').overrideWith(
              (ref) async => const [],
            ),
            projectsByStatusProvider('WAITING_ASSIGNMENT').overrideWith(
              (ref) async => const [],
            ),
            projectsByStatusProvider('IN_PROGRESS').overrideWith(
              (ref) async => const [],
            ),
            projectsByStatusProvider('UNDER_CLIENT_REVIEW').overrideWith(
              (ref) async => const [],
            ),
            projectsByStatusProvider('COMPLETED').overrideWith(
              (ref) async => const [],
            ),
          ],
          child: const MaterialApp(home: AdminProjectsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No projects found in this state.'), findsOneWidget);
    });
  });

  group('AdminProjectDetailScreen Student Review Tests', () {
    testWidgets('Displays training assignment details and drawing versions', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createDetailTestApp(
          project: testTrainingProject,
          versions: [testDrawingVersion],
          availableUsers: [testCandidateStudent, testCandidateDraughtsman],
        ),
      );
      await tester.pumpAndSettle();

      // Verify header and project title
      expect(find.text('Academic Studio Hospital'), findsWidgets);

      // Verify Training section
      expect(find.text('TRAINING ASSIGNMENT'), findsOneWidget);
      expect(find.text('STUDENT_ALICE_01'), findsOneWidget);
      expect(find.text('MOD_ARCH_01'), findsOneWidget);

      // Verify Drawing version info
      expect(find.text('DRAWING VERSIONS & SUBMISSIONS'), findsOneWidget);
      expect(find.text('Version 1 (Latest)'), findsOneWidget);

      // Verify Evaluation buttons for UNDER_CLIENT_REVIEW status
      expect(find.text('Request Correction'), findsOneWidget);
      expect(find.text('Approve Submission'), findsOneWidget);
    });

    testWidgets('Tapping Request Correction opens EvaluationDialog', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createDetailTestApp(
          project: testTrainingProject,
          versions: [testDrawingVersion],
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Request Correction'));
      await tester.tap(find.text('Request Correction'));
      await tester.pumpAndSettle();

      expect(find.text('Evaluate Drawing'), findsOneWidget);
      expect(find.text('Accuracy'), findsWidgets);
      expect(find.text('Technical Standards'), findsWidgets);
      expect(find.text('Submit Evaluation'), findsOneWidget);
    });

    testWidgets('Tapping Approve Submission opens EvaluationDialog in approval mode', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createDetailTestApp(
          project: testTrainingProject,
          versions: [testDrawingVersion],
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Approve Submission'));
      await tester.tap(find.text('Approve Submission'));
      await tester.pumpAndSettle();

      expect(find.text('Evaluate Drawing'), findsOneWidget);
      expect(find.text('Submit Evaluation'), findsOneWidget);
    });

    testWidgets('Displays previous evaluations and corrections when present', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final existingEvaluation = Evaluation(
        id: 'eval_01',
        projectId: 'proj_train_test_01',
        drawingVersionId: 'ver_test_01',
        evaluatorId: 'SUPERVISOR_ADMIN_01',
        overallResult: EvaluationResult.needsCorrection,
        generalFeedback: 'Adjust grid spacing',
        criteria: {'Accuracy': 3, 'Technical Standards': 2},
        createdAt: DateTime.utc(2026, 10, 11, 15, 0),
      );

      final existingCorrection = Correction(
        id: 'corr_01',
        projectId: 'proj_train_test_01',
        requestedBy: 'SUPERVISOR_ADMIN_01',
        targetVersionId: 'ver_test_01',
        roundNumber: 1,
        description: 'Adjust grid spacing on west wing',
        status: CorrectionStatus.open,
        createdAt: DateTime.utc(2026, 10, 11, 15, 0),
      );

      await tester.pumpWidget(
        createDetailTestApp(
          project: testTrainingProject,
          versions: [testDrawingVersion],
          evaluations: [existingEvaluation],
          corrections: [existingCorrection],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EVALUATIONS'), findsOneWidget);
      expect(find.text('Evaluation: Needs Correction'), findsOneWidget);
      expect(find.text('Adjust grid spacing'), findsOneWidget);

      expect(find.text('CORRECTIONS HISTORY'), findsOneWidget);
      expect(find.text('Round 1 - Open'), findsOneWidget);
      expect(find.textContaining('Adjust grid spacing on west wing'), findsOneWidget);
    });

    testWidgets('Assign dialog on training project only lists STUDENT candidates', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final unassignedTrainProject = Project(
        projectId: 'proj_train_test_01',
        projectName: 'Unassigned Studio Project',
        projectAddress: 'Site 1',
        drawingName: 'Plan',
        drawingType: 'Floor Plan',
        clientId: 'ADMIN_01',
        status: 'WAITING_ASSIGNMENT',
        isTrainingProject: 1,
      );

      await tester.pumpWidget(
        createDetailTestApp(
          project: unassignedTrainProject,
          availableUsers: [testCandidateStudent, testCandidateDraughtsman],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Assign Student'), findsOneWidget);

      await tester.ensureVisible(find.text('Assign Student'));
      await tester.tap(find.text('Assign Student'));
      await tester.pumpAndSettle();

      expect(find.text('Assign Student'), findsWidgets);
      // Student candidate is visible
      expect(find.text('Bob Student'), findsOneWidget);
      // Draughtsman candidate is filtered out
      expect(find.text('Charlie Draughtsman'), findsNothing);
    });
  });
}
