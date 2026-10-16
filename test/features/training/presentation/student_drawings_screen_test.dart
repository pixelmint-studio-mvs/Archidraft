import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/domain/project_status.dart';
import 'package:archi_draft/src/features/training/presentation/student_drawings_screen.dart';
import 'package:archi_draft/src/features/training/providers/training_providers.dart';

void main() {
  final sampleProject = Project(
    projectId: 'proj_draw_01',
    projectName: 'Tokyo Commercial Complex HVAC',
    projectAddress: '1-1 Marunouchi, Chiyoda, Tokyo',
    drawingName: 'HVAC-Duct-L1',
    drawingType: 'HVAC Ducting',
    clientId: 'admin_studio',
    status: ProjectStatus.inProgress.toFirestoreString(),
    correctionRound: 1,
    trainingModuleId: 'mod_hybrid',
    currentAssignmentId: 'asg_hybrid_01',
    isTrainingProject: 1,
  );

  Widget createTestWidget({
    required AsyncValue<List<Project>> assignmentsState,
    GoRouter? router,
  }) {
    if (router != null) {
      return ProviderScope(
        overrides: [
          studentAssignmentsProvider.overrideWith((ref) => assignmentsState.value ?? []),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    return ProviderScope(
      overrides: [
        studentAssignmentsProvider.overrideWith((ref) {
          if (assignmentsState.hasError) {
            throw assignmentsState.error!;
          }
          return assignmentsState.value ?? [];
        }),
      ],
      child: const MaterialApp(
        home: StudentDrawingsScreen(),
      ),
    );
  }

  group('StudentDrawingsScreen Tests', () {
    testWidgets('Renders empty state when assignments list is empty', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          assignmentsState: const AsyncValue.data([]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Drawings Library'), findsWidgets);
      expect(find.text('No Drawings Yet'), findsOneWidget);
      expect(find.text('Your training assignments will appear here.'), findsOneWidget);
      expect(find.byIcon(Icons.layers_clear), findsOneWidget);
    });

    testWidgets('Renders drawings list and tapping drawing pushes /student/workspace/:id', (tester) async {
      String? pushedRoute;
      final router = GoRouter(
        initialLocation: '/student/drawings',
        routes: [
          GoRoute(
            path: '/student/drawings',
            builder: (context, state) => const StudentDrawingsScreen(),
          ),
          GoRoute(
            path: '/student/workspace/:projectId',
            builder: (context, state) {
              pushedRoute = state.uri.toString();
              return Scaffold(body: Text('Workspace ${state.pathParameters['projectId']}'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        createTestWidget(
          assignmentsState: AsyncValue.data([sampleProject]),
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tokyo Commercial Complex HVAC'), findsOneWidget);

      await tester.tap(find.text('Tokyo Commercial Complex HVAC'));
      await tester.pumpAndSettle();

      expect(pushedRoute, '/student/workspace/proj_draw_01');
      expect(find.text('Workspace proj_draw_01'), findsOneWidget);
    });

    testWidgets('AppBar back button falls back to /student/projects when cannot pop', (tester) async {
      String? currentPath;
      final router = GoRouter(
        initialLocation: '/student/drawings',
        routes: [
          GoRoute(
            path: '/student/projects',
            builder: (context, state) {
              currentPath = state.uri.toString();
              return const Scaffold(body: Text('Projects Tab'));
            },
          ),
          GoRoute(
            path: '/student/drawings',
            builder: (context, state) {
              currentPath = state.uri.toString();
              return const StudentDrawingsScreen();
            },
          ),
        ],
      );

      await tester.pumpWidget(
        createTestWidget(
          assignmentsState: AsyncValue.data([sampleProject]),
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(currentPath, '/student/drawings');
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(currentPath, '/student/projects');
      expect(find.text('Projects Tab'), findsOneWidget);
    });

    testWidgets('Renders error UI when provider has error', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          assignmentsState: AsyncValue.error('Network failure', StackTrace.empty),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to load drawings'), findsOneWidget);
      expect(find.textContaining('Network failure'), findsOneWidget);
    });
  });
}
