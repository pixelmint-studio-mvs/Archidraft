import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/training/domain/training_module.dart';
import 'package:archi_draft/src/features/training/presentation/student_training_screen.dart';
import 'package:archi_draft/src/features/training/providers/training_providers.dart';

void main() {
  final sampleModule = const TrainingModule(
    id: 'mod_cad_01',
    title: 'Architectural CAD Essentials',
    description: 'Core architectural layouts and precision drafting.',
    category: 'Architectural',
    level: 'Beginner',
    progress: 40.0,
    status: 'In Progress',
    type: 'Module',
  );

  final sampleProgress = const TrainingCategoryProgress(
    category: 'Architectural',
    overallProgress: 0.33,
  );

  Widget createTestApp({
    required List<TrainingModule> modules,
    required List<TrainingCategoryProgress> progress,
    required List<Project> assignments,
    required GoRouter router,
  }) {
    return ProviderScope(
      overrides: [
        studentModulesProvider.overrideWith((ref) => modules),
        categoryProgressProvider.overrideWith((ref) => progress),
        studentAssignmentsProvider.overrideWith((ref) => assignments),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('StudentTrainingScreen Tests', () {
    testWidgets('Tapping Performance Insights icon in AppBar pushes /student/insights', (tester) async {
      String? pushedRoute;

      final router = GoRouter(
        initialLocation: '/student/training',
        routes: [
          GoRoute(
            path: '/student/training',
            builder: (context, state) => const StudentTrainingScreen(),
          ),
          GoRoute(
            path: '/student/insights',
            builder: (context, state) {
              pushedRoute = state.uri.toString();
              return const Scaffold(body: Text('Performance Insights Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        createTestApp(
          modules: [sampleModule],
          progress: [sampleProgress],
          assignments: [],
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Learning Hub'), findsOneWidget);
      expect(find.byIcon(Icons.insights_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.insights_outlined));
      await tester.pumpAndSettle();

      expect(pushedRoute, '/student/insights');
      expect(find.text('Performance Insights Screen'), findsOneWidget);
    });

    testWidgets('Tapping Continue Learning card pushes /student/training/:moduleId', (tester) async {
      String? pushedRoute;

      final router = GoRouter(
        initialLocation: '/student/training',
        routes: [
          GoRoute(
            path: '/student/training',
            builder: (context, state) => const StudentTrainingScreen(),
          ),
          GoRoute(
            path: '/student/training/:moduleId',
            builder: (context, state) {
              pushedRoute = state.uri.toString();
              return Scaffold(body: Text('Detail for ${state.pathParameters['moduleId']}'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        createTestApp(
          modules: [sampleModule],
          progress: [sampleProgress],
          assignments: [],
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      // Find the Continue Learning card with module title
      expect(find.text('Architectural CAD Essentials'), findsWidgets);

      await tester.tap(find.text('Architectural CAD Essentials').first);
      await tester.pumpAndSettle();

      expect(pushedRoute, '/student/training/mod_cad_01');
      expect(find.text('Detail for mod_cad_01'), findsOneWidget);
    });
  });
}
