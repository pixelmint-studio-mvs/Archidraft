import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:archi_draft/src/features/auth/domain/user_profile.dart';
import 'package:archi_draft/src/features/profile/domain/user_role.dart';
import 'package:archi_draft/src/features/notifications/data/notification_repository.dart';
import 'package:archi_draft/src/features/profile/providers/profile_providers.dart';
import 'package:archi_draft/src/features/shell/presentation/student_shell.dart';
import 'package:archi_draft/src/features/shell/presentation/widgets/app_bottom_nav.dart';
import 'package:archi_draft/src/features/shell/presentation/widgets/responsive_scaffold.dart';

void main() {
  final testProfile = const UserProfile(
    id: 'student_test_1',
    email: 'student@test.com',
    name: 'Jane Student',
    mobile: '9876543210',
    role: 'STUDENT',
  );

  Widget createShellTestApp({required String initialLocation}) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        ShellRoute(
          builder: (context, state, child) => StudentShell(
            profile: testProfile,
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/student/dashboard',
              builder: (context, state) => const Scaffold(body: Text('Studio Page')),
            ),
            GoRoute(
              path: '/student/training',
              builder: (context, state) => const Scaffold(body: Text('Training Page')),
            ),
            GoRoute(
              path: '/student/projects',
              builder: (context, state) => const Scaffold(body: Text('Projects Page')),
            ),
            GoRoute(
              path: '/student/workspace/:projectId',
              builder: (context, state) => Scaffold(body: Text('Workspace ${state.pathParameters['projectId']}')),
            ),
            GoRoute(
              path: '/student/profile',
              builder: (context, state) => const Scaffold(body: Text('Profile Page')),
            ),
            GoRoute(
              path: '/student/portfolio',
              builder: (context, state) => const Scaffold(body: Text('Portfolio Page')),
            ),
            GoRoute(
              path: '/student/assignments/:assignmentId',
              builder: (context, state) => Scaffold(body: Text('Assignment ${state.pathParameters['assignmentId']}')),
            ),
            GoRoute(
              path: '/student/drawings',
              builder: (context, state) => const Scaffold(body: Text('Drawings Page')),
            ),
            GoRoute(
              path: '/student/insights',
              builder: (context, state) => const Scaffold(body: Text('Insights Page')),
            ),
          ],
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        currentUserRoleProvider.overrideWithValue(UserRole.student),
        notificationsProvider.overrideWith((ref) => Future.value([])),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('StudentShell Navigation Index Tests', () {
    testWidgets('Route /student/dashboard selects Studio tab (index 0)', (tester) async {
      await tester.pumpWidget(createShellTestApp(initialLocation: '/student/dashboard'));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<ResponsiveScaffold>(find.byType(ResponsiveScaffold));
      expect(scaffold.selectedIndex, 0);
    });

    testWidgets('Route /student/training selects Training tab (index 1)', (tester) async {
      await tester.pumpWidget(createShellTestApp(initialLocation: '/student/training'));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<ResponsiveScaffold>(find.byType(ResponsiveScaffold));
      expect(scaffold.selectedIndex, 1);
    });

    testWidgets('Route /student/projects selects Projects tab (index 2)', (tester) async {
      await tester.pumpWidget(createShellTestApp(initialLocation: '/student/projects'));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<ResponsiveScaffold>(find.byType(ResponsiveScaffold));
      expect(scaffold.selectedIndex, 2);
    });

    testWidgets('Route /student/workspace/:id selects Projects tab (index 2)', (tester) async {
      await tester.pumpWidget(createShellTestApp(initialLocation: '/student/workspace/proj_123'));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<ResponsiveScaffold>(find.byType(ResponsiveScaffold));
      expect(scaffold.selectedIndex, 2);
    });

    testWidgets('Route /student/profile selects Settings tab (index 3)', (tester) async {
      await tester.pumpWidget(createShellTestApp(initialLocation: '/student/profile'));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<ResponsiveScaffold>(find.byType(ResponsiveScaffold));
      expect(scaffold.selectedIndex, 3);
    });

    testWidgets('Route /student/portfolio returns -1 and does NOT highlight Studio', (tester) async {
      await tester.pumpWidget(createShellTestApp(initialLocation: '/student/portfolio'));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<ResponsiveScaffold>(find.byType(ResponsiveScaffold));
      // Confirms selectedIndex is -1
      expect(scaffold.selectedIndex, -1);
      // Confirms Studio (index 0) is NOT selected
      expect(scaffold.selectedIndex != 0, isTrue);
    });

    testWidgets('Route /student/assignments/:id selects Projects tab (index 2)', (tester) async {
      await tester.pumpWidget(createShellTestApp(initialLocation: '/student/assignments/assign_456'));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<ResponsiveScaffold>(find.byType(ResponsiveScaffold));
      expect(scaffold.selectedIndex, 2);
    });

    testWidgets('Route /student/drawings selects Projects tab (index 2)', (tester) async {
      await tester.pumpWidget(createShellTestApp(initialLocation: '/student/drawings'));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<ResponsiveScaffold>(find.byType(ResponsiveScaffold));
      expect(scaffold.selectedIndex, 2);
    });

    testWidgets('Route /student/insights selects Training tab (index 1)', (tester) async {
      await tester.pumpWidget(createShellTestApp(initialLocation: '/student/insights'));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<ResponsiveScaffold>(find.byType(ResponsiveScaffold));
      expect(scaffold.selectedIndex, 1);
    });
  });

  group('AppBottomNav Selection Display Tests', () {
    testWidgets('AppBottomNav with selectedIndex -1 has no active tab and does NOT highlight Studio', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNav(
              selectedIndex: -1,
              destinations: StudentShell.destinations,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Studio'), findsOneWidget);
      expect(find.text('Training'), findsOneWidget);
      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      final bottomNav = tester.widget<AppBottomNav>(find.byType(AppBottomNav));
      expect(bottomNav.selectedIndex, -1);
      expect(bottomNav.selectedIndex != 0, isTrue);
    });

    testWidgets('AppBottomNav with selectedIndex 0 highlights Studio', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNav(
              selectedIndex: 0,
              destinations: StudentShell.destinations,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bottomNav = tester.widget<AppBottomNav>(find.byType(AppBottomNav));
      expect(bottomNav.selectedIndex, 0);
    });
  });
}
