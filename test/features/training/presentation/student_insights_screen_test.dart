import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:archi_draft/src/features/training/domain/training_module.dart';
import 'package:archi_draft/src/features/training/presentation/student_insights_screen.dart';
import 'package:archi_draft/src/features/training/providers/training_providers.dart';

void main() {
  final sampleProgressList = <TrainingCategoryProgress>[
    const TrainingCategoryProgress(
      category: 'Architectural',
      overallProgress: 0.67,
    ),
    const TrainingCategoryProgress(
      category: 'Structural',
      overallProgress: 0.50,
    ),
  ];

  Widget createTestWidget({
    required AsyncValue<List<TrainingCategoryProgress>> progressState,
    GoRouter? router,
  }) {
    if (router != null) {
      return ProviderScope(
        overrides: [
          categoryProgressProvider.overrideWith((ref) => progressState.value ?? []),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    return ProviderScope(
      overrides: [
        categoryProgressProvider.overrideWith((ref) {
          if (progressState.hasError) {
            throw progressState.error!;
          }
          return progressState.value ?? [];
        }),
      ],
      child: const MaterialApp(
        home: StudentInsightsScreen(),
      ),
    );
  }

  group('StudentInsightsScreen Tests', () {
    testWidgets('Renders empty state when category progress list is empty', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          progressState: const AsyncValue.data([]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Performance Insights'), findsWidgets);
      expect(find.text('No Data Yet'), findsOneWidget);
      expect(find.text('Complete training modules to see your insights.'), findsOneWidget);
      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
    });

    testWidgets('Renders progress overview and category cards when populated', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          progressState: AsyncValue.data(sampleProgressList),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Overall Training Completion'), findsOneWidget);
      expect(find.text('Category Mastery'), findsOneWidget);
      expect(find.text('Architectural'), findsOneWidget);
      expect(find.text('Structural'), findsOneWidget);
      expect(find.text('67%'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('AppBar back button falls back to /student/training when cannot pop', (tester) async {
      String? currentPath;
      final router = GoRouter(
        initialLocation: '/student/insights',
        routes: [
          GoRoute(
            path: '/student/training',
            builder: (context, state) {
              currentPath = state.uri.toString();
              return const Scaffold(body: Text('Training Hub'));
            },
          ),
          GoRoute(
            path: '/student/insights',
            builder: (context, state) {
              currentPath = state.uri.toString();
              return const StudentInsightsScreen();
            },
          ),
        ],
      );

      await tester.pumpWidget(
        createTestWidget(
          progressState: AsyncValue.data(sampleProgressList),
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(currentPath, '/student/insights');
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(currentPath, '/student/training');
      expect(find.text('Training Hub'), findsOneWidget);
    });

    testWidgets('Renders error UI when provider has error', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          progressState: AsyncValue.error('Server unavailable', StackTrace.empty),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to load insights'), findsOneWidget);
      expect(find.textContaining('Server unavailable'), findsOneWidget);
    });
  });
}
