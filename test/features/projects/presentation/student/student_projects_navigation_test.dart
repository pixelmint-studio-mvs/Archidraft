import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/domain/project_status.dart';
import 'package:archi_draft/src/features/training/providers/training_providers.dart';
import 'package:archi_draft/src/features/projects/presentation/student/student_projects_screen.dart';

void main() {
  Project createProject({
    required String id,
    required String name,
    required ProjectStatus status,
    int correctionRound = 0,
  }) {
    return Project(
      projectId: id,
      projectName: name,
      projectAddress: '10 Industrial Area, Phase 2',
      drawingName: 'Section Elevation',
      drawingType: 'Architectural Plan',
      clientId: 'client_alpha',
      status: status.toFirestoreString(),
      correctionRound: correctionRound,
      isTrainingProject: 1,
    );
  }

  group('StudentProjectsScreen Navigation Tests', () {
    testWidgets('Tapping Featured card pushes /student/workspace/:id across all project states', (tester) async {
      final waitingProject = createProject(
        id: 'proj_waiting_01',
        name: 'Waiting Acceptance Assignment',
        status: ProjectStatus.waitingAcceptance,
      );
      final secondProject = createProject(
        id: 'proj_active_02',
        name: 'Second In Progress Assignment',
        status: ProjectStatus.inProgress,
      );

      String? pushedRoute;

      final router = GoRouter(
        initialLocation: '/student/projects',
        routes: [
          GoRoute(
            path: '/student/projects',
            builder: (context, state) => const StudentProjectsScreen(),
          ),
          GoRoute(
            path: '/student/workspace/:projectId',
            builder: (context, state) {
              pushedRoute = state.uri.toString();
              return Scaffold(body: Text('Workspace for ${state.pathParameters['projectId']}'));
            },
          ),
          GoRoute(
            path: '/student/projects/:projectId',
            builder: (context, state) {
              pushedRoute = state.uri.toString();
              return const Scaffold(body: Text('ProjectDetailScreen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentAssignmentsProvider.overrideWith((ref) => [waitingProject, secondProject]),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the featured "Needs Attention" card
      expect(find.text('Waiting Acceptance Assignment'), findsOneWidget);
      expect(find.text('Needs Attention'), findsOneWidget);

      // Tap the featured project card
      await tester.tap(find.text('Waiting Acceptance Assignment'));
      await tester.pumpAndSettle();

      // Verifies route pushed is /student/workspace/:projectId, NOT /student/projects/:projectId
      expect(pushedRoute, '/student/workspace/proj_waiting_01');
      expect(find.text('Workspace for proj_waiting_01'), findsOneWidget);
    });

    testWidgets('Tapping List Item pushes /student/workspace/:id', (tester) async {
      final activeProject = createProject(
        id: 'proj_item_01',
        name: 'Featured In Progress',
        status: ProjectStatus.inProgress,
      );
      final secondProject = createProject(
        id: 'proj_item_02',
        name: 'List Item Project',
        status: ProjectStatus.underClientReview,
      );

      String? pushedRoute;

      final router = GoRouter(
        initialLocation: '/student/projects',
        routes: [
          GoRoute(
            path: '/student/projects',
            builder: (context, state) => const StudentProjectsScreen(),
          ),
          GoRoute(
            path: '/student/workspace/:projectId',
            builder: (context, state) {
              pushedRoute = state.uri.toString();
              return Scaffold(body: Text('Workspace for ${state.pathParameters['projectId']}'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentAssignmentsProvider.overrideWith((ref) => [activeProject, secondProject]),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the second project list item
      expect(find.text('List Item Project'), findsOneWidget);

      // Tap list item
      await tester.tap(find.text('List Item Project'));
      await tester.pumpAndSettle();

      expect(pushedRoute, '/student/workspace/proj_item_02');
      expect(find.text('Workspace for proj_item_02'), findsOneWidget);
    });

    testWidgets('Tapping Drawings Library AppBar action pushes /student/drawings', (tester) async {
      String? pushedRoute;

      final router = GoRouter(
        initialLocation: '/student/projects',
        routes: [
          GoRoute(
            path: '/student/projects',
            builder: (context, state) => const StudentProjectsScreen(),
          ),
          GoRoute(
            path: '/student/drawings',
            builder: (context, state) {
              pushedRoute = state.uri.toString();
              return const Scaffold(body: Text('Drawings Library Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentAssignmentsProvider.overrideWith((ref) => []),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pumpAndSettle();

      expect(pushedRoute, '/student/drawings');
      expect(find.text('Drawings Library Screen'), findsOneWidget);
    });
  });
}
