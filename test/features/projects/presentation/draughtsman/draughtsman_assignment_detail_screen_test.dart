import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:archi_draft/src/features/projects/domain/assignment.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/domain/project_status.dart';
import 'package:archi_draft/src/features/projects/providers/assignment_providers.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/projects/data/assignment_repository.dart';
import 'package:archi_draft/src/features/projects/presentation/draughtsman/draughtsman_assignment_detail_screen.dart';

class FakeAssignmentRepository implements AssignmentRepository {
  int acceptCalls = 0;
  int rejectCalls = 0;
  Completer<void>? acceptCompleter;
  Completer<void>? rejectCompleter;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> acceptAssignment({
    required String assignmentId,
    required String projectId,
    required String actionId,
  }) async {
    acceptCalls++;
    if (acceptCompleter != null) {
      await acceptCompleter!.future;
    }
  }

  @override
  Future<void> rejectAssignment({
    required String assignmentId,
    required String projectId,
    required String actionId,
  }) async {
    rejectCalls++;
    if (rejectCompleter != null) {
      await rejectCompleter!.future;
    }
  }

  @override
  Future<List<Assignment>> getAssignments() async => [];
}

void main() {
  const testProjectId = 'prj_commercial_01';
  const testAssignmentId = 'asgn_dman_99';
  const testDraughtsmanId = 'dman_user_1';

  final pendingAssignment = Assignment(
    id: testAssignmentId,
    projectId: testProjectId,
    draughtsmanId: testDraughtsmanId,
    status: 'PENDING',
    projectName: 'Commercial Office Block',
    projectAddress: '100 Business Boulevard',
    drawingType: 'Structural Layout',
  );

  final testProject = Project(
    projectId: testProjectId,
    projectName: 'Commercial Office Block',
    projectAddress: '100 Business Boulevard',
    drawingName: 'Structural Layout Drawing',
    drawingType: 'Structural',
    clientId: 'client_corp_1',
    currentAssignmentId: testAssignmentId,
    status: ProjectStatus.waitingAcceptance.toFirestoreString(),
    isTrainingProject: 0,
  );

  group('DraughtsmanAssignmentDetailScreen Tests', () {
    testWidgets('Renders project info and pending accept/reject buttons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectProvider(testProjectId).overrideWith((ref) => testProject),
          ],
          child: MaterialApp(
            home: DraughtsmanAssignmentDetailScreen(assignment: pendingAssignment),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Assignment Details'), findsOneWidget);
      expect(find.text('Commercial Office Block'), findsOneWidget);
      expect(find.text('100 Business Boulevard'), findsOneWidget);
      expect(find.text('Structural'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });

    testWidgets('Shows CircularProgressIndicator and suppresses buttons when action is in progress', (tester) async {
      final fakeRepo = FakeAssignmentRepository();
      fakeRepo.acceptCompleter = Completer<void>();

      final router = GoRouter(
        initialLocation: '/draughtsman/assignments/$testAssignmentId',
        routes: [
          GoRoute(
            path: '/draughtsman/assignments/:assignmentId',
            builder: (context, state) => DraughtsmanAssignmentDetailScreen(
              assignment: pendingAssignment,
            ),
          ),
          GoRoute(
            path: '/draughtsman/workspace/:projectId',
            builder: (context, state) => const Scaffold(body: Text('Workspace Home')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assignmentRepositoryProvider.overrideWithValue(fakeRepo),
            projectProvider(testProjectId).overrideWith((ref) => testProject),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Accept to start async action
      await tester.tap(find.text('Accept'));
      await tester.pump(); // Frame update for loading state

      // While loading, CircularProgressIndicator is displayed and buttons are hidden/disabled
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Accept'), findsNothing);
      expect(find.text('Reject'), findsNothing);

      // Complete async execution
      fakeRepo.acceptCompleter!.complete();
      await tester.pumpAndSettle();

      expect(fakeRepo.acceptCalls, 1);
      expect(find.text('Workspace Home'), findsOneWidget);
    });

    test('Re-entrancy guard in controller rejects concurrent accept calls', () async {
      final fakeRepo = FakeAssignmentRepository();
      fakeRepo.acceptCompleter = Completer<void>();

      final container = ProviderContainer(
        overrides: [
          assignmentRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      final controller = container.read(draughtsmanActionsControllerProvider.notifier);

      // Trigger first call (will be delayed by completer)
      final future1 = controller.acceptAssignment(
        assignmentId: testAssignmentId,
        projectId: testProjectId,
      );

      // Attempt second call immediately while first is in-flight
      final result2 = await controller.acceptAssignment(
        assignmentId: testAssignmentId,
        projectId: testProjectId,
      );

      // The second call is blocked by the re-entrancy guard
      expect(result2, false);

      fakeRepo.acceptCompleter!.complete();
      final result1 = await future1;
      expect(result1, true);
      expect(fakeRepo.acceptCalls, 1);
    });

    test('Reject re-entrancy guard in controller rejects concurrent reject calls', () async {
      final fakeRepo = FakeAssignmentRepository();
      fakeRepo.rejectCompleter = Completer<void>();

      final container = ProviderContainer(
        overrides: [
          assignmentRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      final controller = container.read(draughtsmanActionsControllerProvider.notifier);

      // Trigger first call (will be delayed by completer)
      final future1 = controller.rejectAssignment(
        assignmentId: testAssignmentId,
        projectId: testProjectId,
      );

      // Attempt second call immediately while first is in-flight
      final result2 = await controller.rejectAssignment(
        assignmentId: testAssignmentId,
        projectId: testProjectId,
      );

      // The second call is blocked by the re-entrancy guard
      expect(result2, false);

      fakeRepo.rejectCompleter!.complete();
      final result1 = await future1;
      expect(result1, true);
      expect(fakeRepo.rejectCalls, 1);
    });

    testWidgets('Safe fallback navigation works when directly opened without previous route history', (tester) async {
      final router = GoRouter(
        initialLocation: '/draughtsman/assignments/$testAssignmentId',
        routes: [
          GoRoute(
            path: '/draughtsman/assignments/:assignmentId',
            builder: (context, state) => DraughtsmanAssignmentDetailScreen(
              assignment: pendingAssignment,
            ),
          ),
          GoRoute(
            path: '/draughtsman/studio',
            builder: (context, state) => const Scaffold(body: Text('Studio Home')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectProvider(testProjectId).overrideWith((ref) => testProject),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Assignment Details'), findsOneWidget);

      // Tap back button with empty back-stack
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // Successfully routed to /draughtsman/studio without popping off root or crashing
      expect(find.text('Studio Home'), findsOneWidget);
    });
  });
}
