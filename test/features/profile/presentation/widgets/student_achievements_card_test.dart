import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:archi_draft/src/features/profile/domain/student_achievement.dart';
import 'package:archi_draft/src/features/profile/providers/achievements_providers.dart';
import 'package:archi_draft/src/features/profile/presentation/widgets/student_achievements_card.dart';

void main() {
  final sampleAchievements = [
    StudentAchievement(
      id: 'first_lesson_completed',
      title: 'First Blueprint Step',
      description: 'Completed your first training lesson',
      category: 'LEARNING',
      icon: 'school_outlined',
      isUnlocked: true,
      unlockedAt: DateTime.utc(2026, 10, 6, 15, 30),
      currentProgress: 1,
      targetProgress: 1,
    ),
    StudentAchievement(
      id: 'first_practical_project_completed',
      title: 'Studio Ready',
      description: 'Completed your first practical project assignment',
      category: 'PRACTICAL',
      icon: 'assignment_turned_in_outlined',
      isUnlocked: false,
      unlockedAt: null,
      currentProgress: 0,
      targetProgress: 1,
    ),
  ];

  testWidgets(
      'StudentAchievementsCard renders unlocked and locked achievements correctly',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentAchievementsProvider.overrideWith(
            (ref) => sampleAchievements,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StudentAchievementsCard(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify header and count pill
    expect(find.text('STUDENT MILESTONES'), findsOneWidget);
    expect(find.text('Achievements & Progress Badges'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);

    // Verify unlocked achievement
    expect(find.text('First Blueprint Step'), findsOneWidget);
    expect(find.text('Completed your first training lesson'), findsOneWidget);
    expect(find.text('Unlocked'), findsOneWidget);
    expect(find.text('Earned 2026-10-06'), findsOneWidget);

    // Verify locked achievement
    expect(find.text('Studio Ready'), findsOneWidget);
    expect(find.text('Completed your first practical project assignment'),
        findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);
    expect(find.text('In Progress (0/1)'), findsOneWidget);
  });

  testWidgets(
      'StudentAchievementsCard renders safely without overflow on narrow width',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentAchievementsProvider.overrideWith(
            (ref) => sampleAchievements,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StudentAchievementsCard(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify content rendered without RenderFlex overflow exceptions
    expect(tester.takeException(), isNull);
    expect(find.text('First Blueprint Step'), findsOneWidget);
    expect(find.text('Studio Ready'), findsOneWidget);
  });

  testWidgets('StudentAchievementsCard displays loading indicator',
      (tester) async {
    final completer = Completer<List<StudentAchievement>>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentAchievementsProvider.overrideWith(
            (ref) => completer.future,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: StudentAchievementsCard(),
          ),
        ),
      ),
    );

    // Initial pump shows loading
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Resolve future so no pending timers or hanging futures remain
    completer.complete(sampleAchievements);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('StudentAchievementsCard displays error state and retries',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentAchievementsProvider.overrideWith(
            (ref) => Future.error(Exception('Network error')),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: StudentAchievementsCard(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Failed to load achievements'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
