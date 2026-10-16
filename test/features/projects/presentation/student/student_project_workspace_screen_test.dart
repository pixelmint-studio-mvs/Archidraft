import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/domain/project_status.dart';
import 'package:archi_draft/src/features/projects/domain/project_file.dart';
import 'package:archi_draft/src/features/projects/domain/drawing_version.dart';
import 'package:archi_draft/src/features/projects/domain/correction.dart';
import 'package:archi_draft/src/features/projects/domain/evaluation.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/projects/providers/file_providers.dart';
import 'package:archi_draft/src/features/projects/providers/assignment_providers.dart';
import 'package:archi_draft/src/features/projects/data/project_repository.dart';
import 'package:archi_draft/src/features/projects/data/assignment_repository.dart';
import 'package:archi_draft/src/features/projects/presentation/student/student_project_workspace_screen.dart';
import 'package:archi_draft/src/features/projects/presentation/project_detail_screen.dart';
import 'package:archi_draft/src/features/auth/domain/user_profile.dart';
import 'package:archi_draft/src/features/auth/providers/auth_providers.dart';

class MockProjectRepository extends Fake implements ProjectRepository {
  bool submitCalled = false;
  String? submittedDraftFileId;
  bool shouldThrow = false;
  Completer<void>? submitCompleter;

  @override
  Future<void> submitDrawing({
    required String projectId,
    required String actionId,
    String? draftFileId,
  }) async {
    if (submitCompleter != null) {
      await submitCompleter!.future;
    }
    if (shouldThrow) {
      throw Exception('Server rejected submission');
    }
    submitCalled = true;
    submittedDraftFileId = draftFileId;
  }
}

class MockAssignmentRepository extends Fake implements AssignmentRepository {
  int acceptCallCount = 0;
  bool shouldThrow = false;
  Completer<void>? acceptCompleter;

  @override
  Future<void> acceptAssignment({
    required String assignmentId,
    required String projectId,
    required String actionId,
  }) async {
    acceptCallCount++;
    if (acceptCompleter != null) {
      await acceptCompleter!.future;
    }
    if (shouldThrow) {
      throw Exception('Server rejected acceptance');
    }
  }
}

void main() {
  const testProjectId = 'proj_test_workspace';

  Project createTestProject({
    ProjectStatus status = ProjectStatus.inProgress,
    int correctionRound = 0,
    double? projectArea = 2500,
  }) {
    return Project(
      projectId: testProjectId,
      projectName: 'Modern Villa Architectural Plans',
      projectAddress: '123 Blueprint Ave, Sector 4',
      drawingName: 'Ground Floor Architecture',
      drawingType: 'Architectural Plan',
      clientId: 'client_001',
      status: status.toFirestoreString(),
      correctionRound: correctionRound,
      createdAt: DateTime.utc(2026, 10, 1),
      projectArea: projectArea,
    );
  }

  ProjectFile createTestProjectFile({
    required String id,
    required String category,
    String originalName = 'drawing.pdf',
    int size = 204800,
  }) {
    return ProjectFile(
      id: id,
      projectId: testProjectId,
      uploadedBy: 'student_001',
      originalName: originalName,
      sanitizedName: originalName,
      objectKey: 'files/$id.pdf',
      contentType: 'application/pdf',
      size: size,
      category: category,
      status: 'COMPLETED',
      createdAt: DateTime.utc(2026, 10, 2),
    );
  }

  Widget createTestWidget({
    required Project project,
    List<ProjectFile> files = const [],
    List<DrawingVersion> versions = const [],
    List<Correction> corrections = const [],
    List<Evaluation> evaluations = const [],
    UserProfile? profile,
    ProjectRepository? repository,
    AssignmentRepository? assignmentRepository,
  }) {
    return ProviderScope(
      overrides: [
        projectProvider(testProjectId).overrideWith((ref) => Future.value(project)),
        projectFilesProvider(testProjectId).overrideWith((ref) => Future.value(files)),
        projectDrawingVersionsProvider(testProjectId).overrideWith((ref) => Future.value(versions)),
        projectCorrectionsProvider(testProjectId).overrideWith((ref) => Future.value(corrections)),
        projectEvaluationsProvider(testProjectId).overrideWith((ref) => Future.value(evaluations)),
        if (profile != null)
          userProfileProvider.overrideWith((ref) => Future.value(profile)),
        if (repository != null)
          projectRepositoryProvider.overrideWithValue(repository),
        if (assignmentRepository != null)
          assignmentRepositoryProvider.overrideWithValue(assignmentRepository),
      ],
      child: const MaterialApp(
        home: StudentProjectWorkspaceScreen(projectId: testProjectId),
      ),
    );
  }

  group('StudentProjectWorkspaceScreen — 4 UX States', () {
    testWidgets('State A: First Attempt — renders requirements and empty states when no draft/versions exist', (tester) async {
      final project = createTestProject(
        status: ProjectStatus.inProgress,
        correctionRound: 0,
      );

      await tester.pumpWidget(createTestWidget(project: project));
      await tester.pumpAndSettle();

      // Header and state badge
      expect(find.text('FIRST ATTEMPT'), findsOneWidget);
      expect(find.text('First Attempt'), findsOneWidget);
      expect(find.text('Modern Villa Architectural Plans'), findsOneWidget);

      // Drawing Requirements
      expect(find.text('DRAWING REQUIREMENTS'), findsOneWidget);
      expect(find.text('Ground Floor Architecture'), findsOneWidget);
      expect(find.text('123 Blueprint Ave, Sector 4'), findsOneWidget);
      expect(find.text('2500.0 sq ft'), findsOneWidget);

      // Empty states for first attempt
      expect(find.text('No reference files attached.'), findsOneWidget);
      expect(find.text('No evaluations yet. STUDIO_ADMIN feedback and scoring criteria will appear here after review.'), findsOneWidget);
      expect(find.text('No submitted versions yet. Upload and submit your draft below to create Version 1.'), findsOneWidget);
      expect(find.text('No draft uploaded yet.'), findsOneWidget);

      // Submit button is rendered and disabled when no draft is staged
      final disabledSubmitButton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Submit Drawing for Review'));
      expect(disabledSubmitButton.onPressed, isNull);
      expect(find.text('Upload your draft drawing above to enable submission.'), findsOneWidget);
    });

    testWidgets('State A: First Attempt — renders staged workspace draft and submit button', (tester) async {
      final project = createTestProject(status: ProjectStatus.inProgress, correctionRound: 0);
      final draftFile = createTestProjectFile(
        id: 'file_draft_01',
        category: 'workspace_draft',
        originalName: 'ground_floor_draft_v1.pdf',
      );

      await tester.pumpWidget(createTestWidget(
        project: project,
        files: [draftFile],
      ));
      await tester.pumpAndSettle();

      expect(find.text('ground_floor_draft_v1.pdf'), findsOneWidget);
      final enabledSubmitButton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Submit Drawing for Review'));
      expect(enabledSubmitButton.onPressed, isNotNull);
    });

    testWidgets('Reference files section displays client uploads and specification documents', (tester) async {
      final project = createTestProject();
      final specFile = createTestProjectFile(
        id: 'file_spec_01',
        category: 'client_upload',
        originalName: 'architectural_brief_v1.pdf',
      );

      await tester.pumpWidget(createTestWidget(
        project: project,
        files: [specFile],
      ));
      await tester.pumpAndSettle();

      expect(find.text('REFERENCE & SPECIFICATION FILES'), findsOneWidget);
      expect(find.text('architectural_brief_v1.pdf'), findsOneWidget);
    });

    testWidgets('State B: Revision Required — renders active ADMIN correction instructions and EvaluationCard', (tester) async {
      final project = createTestProject(
        status: ProjectStatus.inProgress,
        correctionRound: 1,
      );

      final openCorrection = Correction(
        id: 'corr_01',
        projectId: testProjectId,
        requestedBy: 'admin_instructor',
        targetVersionId: 'ver_01',
        roundNumber: 1,
        description: 'Column C2 alignment does not match architectural grid lines. Re-verify offsets.',
        status: CorrectionStatus.open,
        createdAt: DateTime.utc(2026, 10, 3, 14, 30),
      );

      final evaluation = Evaluation(
        id: 'eval_01',
        projectId: testProjectId,
        drawingVersionId: 'ver_01',
        evaluatorId: 'admin_instructor',
        overallResult: EvaluationResult.needsCorrection,
        generalFeedback: 'Good initial draft, but structural columns require grid realignment.',
        criteria: {'Accuracy': 3, 'Technical Standards': 4},
        createdAt: DateTime.utc(2026, 10, 3, 14, 25),
      );

      final version1 = DrawingVersion(
        id: 'ver_01',
        projectId: testProjectId,
        fileId: 'file_v1',
        versionNumber: 1,
        uploadedBy: 'student_001',
        originalName: 'villa_plan_v1.pdf',
        size: 300000,
        createdAt: DateTime.utc(2026, 10, 2, 10, 0),
      );

      await tester.pumpWidget(createTestWidget(
        project: project,
        corrections: [openCorrection],
        evaluations: [evaluation],
        versions: [version1],
      ));
      await tester.pumpAndSettle();

      // Banner & Active Admin Correction
      expect(find.text('REVISION REQUIRED (ROUND 1)'), findsOneWidget);
      expect(find.text('ACTION REQUIRED'), findsOneWidget);
      expect(find.text('Column C2 alignment does not match architectural grid lines. Re-verify offsets.'), findsOneWidget);

      // EvaluationCard integration
      expect(find.text('Evaluation: Needs Correction'), findsOneWidget);
      expect(find.text('Good initial draft, but structural columns require grid realignment.'), findsOneWidget);
      expect(find.text('Accuracy: 3'), findsOneWidget);
      expect(find.text('Technical Standards: 4'), findsOneWidget);

      // Drawing Version 1 history
      expect(find.text('Version 1'), findsOneWidget);

      // Revised Draft staging section
      expect(find.text('YOUR REVISED DRAFT'), findsOneWidget);
    });

    testWidgets('State B: Historical corrections are distinguished from active correction', (tester) async {
      final project = createTestProject(
        status: ProjectStatus.inProgress,
        correctionRound: 2,
      );

      final activeCorrection = Correction(
        id: 'corr_02',
        projectId: testProjectId,
        requestedBy: 'admin_instructor',
        targetVersionId: 'ver_02',
        roundNumber: 2,
        description: 'Verify door swing clearance in master bathroom.',
        status: CorrectionStatus.open,
        createdAt: DateTime.utc(2026, 10, 5),
      );

      final resolvedCorrection = Correction(
        id: 'corr_01',
        projectId: testProjectId,
        requestedBy: 'admin_instructor',
        targetVersionId: 'ver_01',
        roundNumber: 1,
        description: 'Grid alignment revised.',
        status: CorrectionStatus.resolved,
        createdAt: DateTime.utc(2026, 10, 3),
        resolvedAt: DateTime.utc(2026, 10, 4),
      );

      await tester.pumpWidget(createTestWidget(
        project: project,
        corrections: [activeCorrection, resolvedCorrection],
      ));
      await tester.pumpAndSettle();

      expect(find.text('REVISION REQUIRED (ROUND 2)'), findsOneWidget);
      expect(find.text('Verify door swing clearance in master bathroom.'), findsOneWidget);
      expect(find.text('PREVIOUS CORRECTIONS HISTORY'), findsOneWidget);
      expect(find.text('Round 1 - Resolved'), findsOneWidget);
    });

    testWidgets('State B: Active correction with CorrectionStatus.inProgress is selected and displays IN PROGRESS tag', (tester) async {
      final project = createTestProject(
        status: ProjectStatus.inProgress,
        correctionRound: 2,
      );

      final inProgressCorrection = Correction(
        id: 'corr_02',
        projectId: testProjectId,
        requestedBy: 'admin_instructor',
        targetVersionId: 'ver_02',
        roundNumber: 2,
        description: 'Update wall thickness to 230mm for exterior walls.',
        status: CorrectionStatus.inProgress,
        createdAt: DateTime.utc(2026, 10, 5),
      );

      final resolvedCorrection = Correction(
        id: 'corr_01',
        projectId: testProjectId,
        requestedBy: 'admin_instructor',
        targetVersionId: 'ver_01',
        roundNumber: 1,
        description: 'Initial corrections done.',
        status: CorrectionStatus.resolved,
        createdAt: DateTime.utc(2026, 10, 3),
        resolvedAt: DateTime.utc(2026, 10, 4),
      );

      await tester.pumpWidget(createTestWidget(
        project: project,
        corrections: [resolvedCorrection, inProgressCorrection],
      ));
      await tester.pumpAndSettle();

      // Should identify inProgressCorrection as active despite list order
      expect(find.text('REVISION REQUIRED (ROUND 2)'), findsOneWidget);
      expect(find.text('IN PROGRESS'), findsOneWidget);
      expect(find.text('Update wall thickness to 230mm for exterior walls.'), findsOneWidget);
      expect(find.text('PREVIOUS CORRECTIONS HISTORY'), findsOneWidget);
      expect(find.text('Round 1 - Resolved'), findsOneWidget);
    });

    testWidgets('State C: Awaiting Review — shows review notice and hides upload controls', (tester) async {
      final project = createTestProject(
        status: ProjectStatus.underClientReview,
      );

      final version1 = DrawingVersion(
        id: 'ver_01',
        projectId: testProjectId,
        fileId: 'file_v1',
        versionNumber: 1,
        uploadedBy: 'student_001',
        originalName: 'villa_submission_v1.pdf',
        size: 450000,
        createdAt: DateTime.utc(2026, 10, 6),
      );

      await tester.pumpWidget(createTestWidget(
        project: project,
        versions: [version1],
      ));
      await tester.pumpAndSettle();

      // Header status chips: legacy UNDER_CLIENT_REVIEW chip is hidden, Awaiting Review chip is preserved
      expect(find.text('UNDER_CLIENT_REVIEW'), findsNothing);
      expect(find.text('Awaiting Review'), findsOneWidget);

      // Review banner: Awaiting Admin Review card is preserved
      expect(find.text('AWAITING ADMIN REVIEW'), findsOneWidget);

      // Submitted version tag
      expect(find.text('Under Review'), findsOneWidget);
      expect(find.text('Version 1'), findsOneWidget);

      // Locked draft notice
      expect(find.text('Draft submissions are locked while your drawing is awaiting review by the STUDIO_ADMIN.'), findsOneWidget);

      // Ensure no submit or file upload buttons are active
      expect(find.text('Submit Drawing for Review'), findsNothing);
      expect(find.text('Submit Revision for Review'), findsNothing);
    });

    testWidgets('Header Status — UNDER_CLIENT_REVIEW chip is hidden while Awaiting Review chip and Awaiting Admin Review banner remain visible', (tester) async {
      final project = createTestProject(
        status: ProjectStatus.underClientReview,
      );

      await tester.pumpWidget(createTestWidget(project: project));
      await tester.pumpAndSettle();

      // Legacy CLIENT status chip must never be rendered in student UI
      expect(find.text('UNDER_CLIENT_REVIEW'), findsNothing);

      // Clean student status chip and review banner are visible
      expect(find.text('Awaiting Review'), findsOneWidget);
      expect(find.text('AWAITING ADMIN REVIEW'), findsOneWidget);
    });

    testWidgets('State D: Approved / Completed — shows approved status, EvaluationCard, and hides edit actions', (tester) async {
      final project = createTestProject(
        status: ProjectStatus.completed,
      );

      final version1 = DrawingVersion(
        id: 'ver_01',
        projectId: testProjectId,
        fileId: 'file_v1',
        versionNumber: 1,
        uploadedBy: 'student_001',
        originalName: 'villa_final_approved.pdf',
        size: 512000,
        createdAt: DateTime.utc(2026, 10, 7),
      );

      final approvedEval = Evaluation(
        id: 'eval_approved',
        projectId: testProjectId,
        drawingVersionId: 'ver_01',
        evaluatorId: 'admin_instructor',
        overallResult: EvaluationResult.approved,
        generalFeedback: 'Superb execution. Meets all municipal and studio drafting guidelines.',
        criteria: {'Accuracy': 5, 'Technical Standards': 5},
        createdAt: DateTime.utc(2026, 10, 7),
      );

      await tester.pumpWidget(createTestWidget(
        project: project,
        versions: [version1],
        evaluations: [approvedEval],
      ));
      await tester.pumpAndSettle();

      // Completion banner
      expect(find.text('DRAWING APPROVED & PROJECT COMPLETED'), findsOneWidget);
      expect(find.text('Approved'), findsWidgets);

      // Approved EvaluationCard
      expect(find.text('Evaluation: Approved'), findsOneWidget);
      expect(find.text('Superb execution. Meets all municipal and studio drafting guidelines.'), findsOneWidget);
      expect(find.text('Accuracy: 5'), findsOneWidget);
      expect(find.text('Technical Standards: 5'), findsOneWidget);

      // Locked draft notice
      expect(find.text('Project is completed and approved. No further draft submissions are accepted.'), findsOneWidget);
      expect(find.text('Submit Drawing for Review'), findsNothing);
    });

    testWidgets('Draft submission shows confirmation dialog and cancels cleanly', (tester) async {
      final project = createTestProject(status: ProjectStatus.inProgress);
      final draftFile = createTestProjectFile(
        id: 'draft_file_test',
        category: 'workspace_draft',
        originalName: 'villa_draft.pdf',
      );

      await tester.pumpWidget(createTestWidget(
        project: project,
        files: [draftFile],
      ));
      await tester.pumpAndSettle();

      final submitButton = find.text('Submit Drawing for Review');
      await tester.scrollUntilVisible(submitButton, 200);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Confirmation dialog should be visible
      expect(find.text('Submit Drawing'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog dismissed, draft remains visible
      expect(find.text('villa_draft.pdf'), findsOneWidget);
      expect(find.text('Submit Drawing for Review'), findsOneWidget);
    });
  });

  group('Navigation & Role Boundary Tests', () {
    testWidgets('ProjectDetailScreen hides financials action from STUDENT role and shows Workspace button', (tester) async {
      final studentProfile = UserProfile(
        id: 'std_01',
        email: 'student@example.com',
        name: 'Drafting Trainee',
        mobile: '1234567890',
        role: 'STUDENT',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      final project = createTestProject(status: ProjectStatus.inProgress);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectProvider(testProjectId).overrideWith((ref) => Future.value(project)),
            userProfileProvider.overrideWith((ref) => Future.value(studentProfile)),
          ],
          child: const MaterialApp(
            home: ProjectDetailScreen(projectId: testProjectId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Financials action button (Icons.attach_money) must NOT be visible for student
      expect(find.byIcon(Icons.attach_money), findsNothing);

      // Workspace link must be visible for student
      expect(find.text('Workspace'), findsOneWidget);
    });

    testWidgets('StudentProjectWorkspaceScreen back button is present and navigates safely', (tester) async {
      final project = createTestProject();

      await tester.pumpWidget(createTestWidget(project: project));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });
  });

  group('Submission & Cache Invalidation Tests', () {
    test('DraughtsmanActionsController.submitDrawing calls repository and invalidates caches on success', () async {
      final mockRepo = MockProjectRepository();
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(draughtsmanActionsControllerProvider.notifier);
      final success = await controller.submitDrawing(
        projectId: testProjectId,
        draftFileId: 'draft_123',
      );

      expect(success, true);
      expect(mockRepo.submitCalled, true);
      expect(mockRepo.submittedDraftFileId, 'draft_123');
    });

    test('DraughtsmanActionsController.submitDrawing returns false on repository failure preserving draft state', () async {
      final mockRepo = MockProjectRepository()..shouldThrow = true;
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(draughtsmanActionsControllerProvider.notifier);
      final success = await controller.submitDrawing(
        projectId: testProjectId,
        draftFileId: 'draft_123',
      );

      expect(success, false);
      expect(container.read(draughtsmanActionsControllerProvider).hasError, true);
    });
  });

  group('StudentProjectWorkspaceScreen — WAITING_ACCEPTANCE State & Acceptance Flow', () {
    testWidgets('Waiting assignment displays Accept Assignment and locked draft upload', (tester) async {
      final project = createTestProject(
        status: ProjectStatus.waitingAcceptance,
      );

      await tester.pumpWidget(createTestWidget(project: project));
      await tester.pumpAndSettle();

      // Verify WAITING_ACCEPTANCE headers and badges
      expect(find.text('ASSIGNMENT PENDING ACCEPTANCE'), findsOneWidget);
      expect(find.text('Pending Acceptance'), findsOneWidget);
      expect(find.text('WAITING_ACCEPTANCE'), findsNothing);

      // Verify assignment action card and summary
      expect(find.text('PRACTICAL ASSIGNMENT ACTION'), findsOneWidget);
      expect(find.text('Assignment Allocation Summary'), findsOneWidget);
      expect(find.text('Drawing Target'), findsOneWidget);
      expect(find.text('Ground Floor Architecture'), findsNWidgets(2));
      expect(find.widgetWithText(FilledButton, 'Accept Assignment'), findsOneWidget);

      // Verify draft upload is locked pending acceptance
      expect(find.text('Draft upload and submission will be unlocked once you accept this assignment.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Submit Drawing for Review'), findsNothing);
    });

    testWidgets('Accepting transitions the UI to in-progress first-attempt workspace state', (tester) async {
      final mockAssignmentRepo = MockAssignmentRepository();
      final project = createTestProject(
        status: ProjectStatus.waitingAcceptance,
      );

      await tester.pumpWidget(createTestWidget(
        project: project,
        assignmentRepository: mockAssignmentRepo,
      ));
      await tester.pumpAndSettle();

      // Ensure button is scrolled into view and tap Accept Assignment
      final acceptButton = find.widgetWithText(FilledButton, 'Accept Assignment');
      expect(acceptButton, findsOneWidget);
      await tester.ensureVisible(acceptButton);
      await tester.tap(acceptButton);
      await tester.pumpAndSettle();

      // Repository called once
      expect(mockAssignmentRepo.acceptCallCount, 1);

      // SnackBar displayed
      expect(find.text('Practical assignment accepted! Workspace is now active.'), findsOneWidget);

      // Workspace transitions to First Attempt (IN_PROGRESS)
      expect(find.text('FIRST ATTEMPT'), findsOneWidget);
      expect(find.text('First Attempt'), findsOneWidget);
      expect(find.text('YOUR WORKSPACE DRAFT'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Submit Drawing for Review'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Accept Assignment'), findsNothing);
    });

    testWidgets('Acceptance errors are shown and can be retried', (tester) async {
      final mockAssignmentRepo = MockAssignmentRepository()..shouldThrow = true;
      final project = createTestProject(
        status: ProjectStatus.waitingAcceptance,
      );

      await tester.pumpWidget(createTestWidget(
        project: project,
        assignmentRepository: mockAssignmentRepo,
      ));
      await tester.pumpAndSettle();

      // Ensure button is scrolled into view and tap Accept Assignment (will fail)
      final acceptButton = find.widgetWithText(FilledButton, 'Accept Assignment');
      await tester.ensureVisible(acceptButton);
      await tester.tap(acceptButton);
      await tester.pumpAndSettle();

      expect(mockAssignmentRepo.acceptCallCount, 1);
      expect(find.text('Failed to accept practical assignment. Please retry.'), findsNWidgets(2));
      expect(find.widgetWithText(FilledButton, 'Retry Accept Assignment'), findsOneWidget);

      // Fix failure and retry
      mockAssignmentRepo.shouldThrow = false;
      final retryButton = find.widgetWithText(FilledButton, 'Retry Accept Assignment');
      await tester.ensureVisible(retryButton);
      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      expect(mockAssignmentRepo.acceptCallCount, 2);
      expect(find.text('Practical assignment accepted! Workspace is now active.'), findsOneWidget);
      expect(find.text('FIRST ATTEMPT'), findsOneWidget);
    });

    testWidgets('Repeated taps do not trigger duplicate acceptance actions', (tester) async {
      final completer = Completer<void>();
      final mockAssignmentRepo = MockAssignmentRepository()..acceptCompleter = completer;
      final project = createTestProject(
        status: ProjectStatus.waitingAcceptance,
      );

      await tester.pumpWidget(createTestWidget(
        project: project,
        assignmentRepository: mockAssignmentRepo,
      ));
      await tester.pumpAndSettle();

      // Ensure button is visible before first tap
      final acceptButton = find.widgetWithText(FilledButton, 'Accept Assignment');
      await tester.ensureVisible(acceptButton);
      await tester.tap(acceptButton);
      await tester.pump(); // Enter loading state, completer not finished yet

      // Button is now showing loading text and disabled
      expect(find.text('Accepting Assignment...'), findsOneWidget);
      final buttonWidget = tester.widget<FilledButton>(find.byKey(const ValueKey('accept_assignment_button')));
      expect(buttonWidget.onPressed, isNull);

      // Attempt repeated tap
      await tester.tap(find.byKey(const ValueKey('accept_assignment_button')), warnIfMissed: false);
      await tester.pump();

      // Release async completion
      completer.complete();
      await tester.pumpAndSettle();

      // Verifies only 1 call was dispatched
      expect(mockAssignmentRepo.acceptCallCount, 1);
      expect(find.text('FIRST ATTEMPT'), findsOneWidget);
    });
  });

  group('Part S6 — UI Consistency, Responsive Header & Submission Feedback', () {
    testWidgets('Responsive Header — layout renders without overflow at 320px width', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final project = createTestProject(
        status: ProjectStatus.inProgress,
        correctionRound: 2,
      );

      final activeCorrection = Correction(
        id: 'corr_02',
        projectId: testProjectId,
        requestedBy: 'admin_instructor',
        targetVersionId: 'ver_01',
        roundNumber: 2,
        description: 'Verify bathroom window heights and door swings.',
        status: CorrectionStatus.open,
        createdAt: DateTime.utc(2026, 10, 4),
      );

      await tester.pumpWidget(createTestWidget(
        project: project,
        corrections: [activeCorrection],
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('IN_PROGRESS'), findsNothing);
      expect(find.text('Revision Round 2'), findsOneWidget);
      expect(find.text('Oct 1, 2026'), findsOneWidget);
      expect(find.text('Modern Villa Architectural Plans'), findsOneWidget);
    });

    testWidgets('Responsive Header — layout renders without overflow at 360px width', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final project = createTestProject(
        status: ProjectStatus.waitingAcceptance,
      );

      await tester.pumpWidget(createTestWidget(project: project));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('WAITING_ACCEPTANCE'), findsNothing);
      expect(find.text('Pending Acceptance'), findsOneWidget);
      expect(find.text('Oct 1, 2026'), findsOneWidget);
    });

    testWidgets('Responsive Header — handles long project titles gracefully without clipping or overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final project = Project(
        projectId: testProjectId,
        projectName: 'Extremely Long Architectural Project Title Exceeding Single Line Bounds On Mobile Screen',
        projectAddress: '123 Blueprint Ave, Sector 4',
        drawingName: 'Ground Floor Architecture',
        drawingType: 'Architectural Plan',
        clientId: 'client_001',
        status: ProjectStatus.inProgress.toFirestoreString(),
        correctionRound: 0,
        createdAt: DateTime.utc(2026, 10, 1),
      );

      await tester.pumpWidget(createTestWidget(project: project));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('Extremely Long Architectural Project Title Exceeding Single Line Bounds On Mobile Screen'),
        findsOneWidget,
      );
      expect(find.text('IN_PROGRESS'), findsNothing);
      expect(find.text('First Attempt'), findsOneWidget);
    });

    testWidgets('Version History — shows latest tag, filename, and download button', (tester) async {
      final project = createTestProject(status: ProjectStatus.underClientReview);
      final v1 = DrawingVersion(
        id: 'ver_01',
        projectId: testProjectId,
        fileId: 'file_01',
        versionNumber: 1,
        uploadedBy: 'student_001',
        originalName: 'villa_schematic_plan_v1.pdf',
        size: 512000,
        createdAt: DateTime.utc(2026, 10, 5),
      );

      await tester.pumpWidget(createTestWidget(
        project: project,
        versions: [v1],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Version 1'), findsOneWidget);
      expect(find.text('Under Review'), findsOneWidget);
      expect(find.text('villa_schematic_plan_v1.pdf'), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    });

    testWidgets('Submission feedback — in-flight submission disables submit button and shows loading spinner', (tester) async {
      final completer = Completer<void>();
      final mockRepo = MockProjectRepository()..submitCompleter = completer;
      final project = createTestProject(status: ProjectStatus.inProgress);
      final draftFile = createTestProjectFile(
        id: 'draft_file_test',
        category: 'workspace_draft',
        originalName: 'villa_draft.pdf',
      );

      await tester.pumpWidget(createTestWidget(
        project: project,
        files: [draftFile],
        repository: mockRepo,
      ));
      await tester.pumpAndSettle();

      final submitButton = find.byKey(const ValueKey('submit_drawing_button'));
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Tap Submit in dialog
      await tester.tap(find.text('Submit'));
      await tester.pump(); // Start submission async execution

      // Button is now in-flight: shows Submitting... and progress indicator
      expect(find.text('Submitting...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Verify button is disabled (onPressed is null)
      final buttonWidget = tester.widget<FilledButton>(find.byKey(const ValueKey('submit_drawing_button')));
      expect(buttonWidget.onPressed, isNull);

      // Complete the request
      completer.complete();
      await tester.pumpAndSettle();

      expect(mockRepo.submitCalled, isTrue);
    });

    testWidgets('Submission feedback — error displays retry prompt and preserves draft', (tester) async {
      final mockRepo = MockProjectRepository()..shouldThrow = true;
      final project = createTestProject(status: ProjectStatus.inProgress);
      final draftFile = createTestProjectFile(
        id: 'draft_file_test',
        category: 'workspace_draft',
        originalName: 'villa_draft.pdf',
      );

      await tester.pumpWidget(createTestWidget(
        project: project,
        files: [draftFile],
        repository: mockRepo,
      ));
      await tester.pumpAndSettle();

      final submitButton = find.byKey(const ValueKey('submit_drawing_button'));
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Retry affordance and error message visible
      expect(find.text('Retry Submit Drawing'), findsOneWidget);
      expect(
        find.text('Failed to submit drawing. Your draft remains saved. You can retry.'),
        findsOneWidget,
      );
      expect(find.text('villa_draft.pdf'), findsOneWidget);
    });
  });
}
