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

    test('TrainingModule category and type normalization logic', () {
      expect(TrainingModule.normalizeCategory('Reinforced Concrete Detailing'), 'Structural');
      expect(TrainingModule.normalizeCategory('concrete'), 'Structural');
      expect(TrainingModule.normalizeCategory('STRUCTURAL'), 'Structural');
      expect(TrainingModule.normalizeCategory('rcc detailing'), 'Structural');
      expect(TrainingModule.normalizeCategory('Architectural Drafting'), 'Architectural');
      expect(TrainingModule.normalizeCategory('Interior Space Planning'), 'Interior');
      expect(TrainingModule.normalizeCategory('Building Approval Codes'), 'Approval');
      expect(TrainingModule.normalizeCategory(null), 'Architectural');

      expect(TrainingModule.normalizeType('mock_project'), 'Mock Project');
      expect(TrainingModule.normalizeType('masterclass'), 'Masterclass');
      expect(TrainingModule.normalizeType('module'), 'Module');
      expect(TrainingModule.normalizeType(null), 'Module');

      final module = TrainingModule.fromMap({
        'id': 'mod_rc_01',
        'title': 'Reinforced Concrete Detailing',
        'category': 'Reinforced Concrete Detailing',
        'type': 'module',
        'status': 'in_progress',
        'progress': 0.5,
      });

      expect(module.category, 'Structural');
      expect(module.type, 'Module');
      expect(module.status, 'In Progress');
    });

    testWidgets('Reinforced Concrete Detailing module appears under Structural tab', (tester) async {
      final rccModule = TrainingModule.fromMap({
        'id': 'mod_rc_01',
        'title': 'Reinforced Concrete Detailing',
        'category': 'Reinforced Concrete Detailing',
        'type': 'module',
        'status': 'in_progress',
        'description': 'Advanced rebar placement and concrete detailing.',
      });

      final router = GoRouter(
        initialLocation: '/student/training',
        routes: [
          GoRoute(
            path: '/student/training',
            builder: (context, state) => const StudentTrainingScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        createTestApp(
          modules: [rccModule],
          progress: [
            const TrainingCategoryProgress(category: 'Structural', overallProgress: 0.5),
          ],
          assignments: [],
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      // Tap the Structural tab specifically
      await tester.tap(find.widgetWithText(Tab, 'Structural'));
      await tester.pumpAndSettle();

      // Should find the Reinforced Concrete Detailing module card in the Structural view
      expect(find.text('Reinforced Concrete Detailing'), findsWidgets);
      // Empty state for Structural must NOT be shown
      expect(find.text('No Modules in Structural'), findsNothing);
    });
  });
}
