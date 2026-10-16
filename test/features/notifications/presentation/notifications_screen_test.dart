import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:archi_draft/src/features/auth/domain/user_profile.dart';
import 'package:archi_draft/src/features/auth/providers/auth_providers.dart';
import 'package:archi_draft/src/features/notifications/domain/notification_model.dart';
import 'package:archi_draft/src/features/notifications/data/notification_repository.dart';
import 'package:archi_draft/src/features/notifications/presentation/notifications_screen.dart';

class FakeNotificationRepository implements NotificationRepository {
  @override
  Future<List<NotificationModel>> fetchNotifications() async => [];

  @override
  Future<void> markAsRead(String id) async {}
}

void main() {
  final testNotification = NotificationModel(
    id: 'notif_01',
    userId: 'user_student_1',
    projectId: 'proj_hybrid_01',
    type: 'CORRECTION_REQUESTED',
    title: 'Correction Requested',
    message: 'Review comments and upload a new draft revision.',
    isRead: false,
    createdAt: DateTime.utc(2026, 10, 10, 12, 0),
  );

  Widget createTestApp({
    required UserProfile profile,
    required List<NotificationModel> notifications,
    required GoRouter router,
  }) {
    return ProviderScope(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(FakeNotificationRepository()),
        userProfileProvider.overrideWith((ref) => profile),
        notificationsProvider.overrideWith((ref) => notifications),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('NotificationsScreen Role Routing Tests', () {
    testWidgets('Tapping notification as STUDENT routes to /student/workspace/:id', (tester) async {
      String? routedLocation;

      final studentProfile = const UserProfile(
        id: 'user_student_1',
        name: 'Alice Student',
        email: 'alice@example.com',
        mobile: '1234567890',
        role: 'STUDENT',
      );

      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/student/workspace/:projectId',
            builder: (context, state) {
              routedLocation = state.uri.toString();
              return Scaffold(body: Text('Workspace for ${state.pathParameters['projectId']}'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        createTestApp(
          profile: studentProfile,
          notifications: [testNotification],
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Correction Requested'), findsOneWidget);

      await tester.tap(find.text('Correction Requested'));
      await tester.pumpAndSettle();

      expect(routedLocation, '/student/workspace/proj_hybrid_01');
      expect(find.text('Workspace for proj_hybrid_01'), findsOneWidget);
    });

    testWidgets('Tapping notification as CLIENT routes to /client/projects/:id', (tester) async {
      String? routedLocation;

      final clientProfile = const UserProfile(
        id: 'user_client_1',
        name: 'Charlie Client',
        email: 'charlie@example.com',
        mobile: '1234567890',
        role: 'CLIENT',
      );

      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/client/projects/:projectId',
            builder: (context, state) {
              routedLocation = state.uri.toString();
              return Scaffold(body: Text('Client Project ${state.pathParameters['projectId']}'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        createTestApp(
          profile: clientProfile,
          notifications: [testNotification],
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Correction Requested'));
      await tester.pumpAndSettle();

      expect(routedLocation, '/client/projects/proj_hybrid_01');
      expect(find.text('Client Project proj_hybrid_01'), findsOneWidget);
    });

    testWidgets('Tapping notification as DRAUGHTSMAN routes to /draughtsman/workspace/:id', (tester) async {
      String? routedLocation;

      final draughtsmanProfile = const UserProfile(
        id: 'user_draughtsman_1',
        name: 'Dan Draughtsman',
        email: 'dan@example.com',
        mobile: '1234567890',
        role: 'DRAUGHTSMAN',
      );

      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/draughtsman/workspace/:projectId',
            builder: (context, state) {
              routedLocation = state.uri.toString();
              return Scaffold(body: Text('Draughtsman Workspace ${state.pathParameters['projectId']}'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        createTestApp(
          profile: draughtsmanProfile,
          notifications: [testNotification],
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Correction Requested'));
      await tester.pumpAndSettle();

      expect(routedLocation, '/draughtsman/workspace/proj_hybrid_01');
      expect(find.text('Draughtsman Workspace proj_hybrid_01'), findsOneWidget);
    });

    testWidgets('Tapping DRAUGHTSMAN_ASSIGNED notification as DRAUGHTSMAN routes to /draughtsman/assignments/:projectId', (tester) async {
      String? routedLocation;

      final draughtsmanProfile = const UserProfile(
        id: 'user_draughtsman_1',
        name: 'Dan Draughtsman',
        email: 'dan@example.com',
        mobile: '1234567890',
        role: 'DRAUGHTSMAN',
      );

      final assignedNotification = NotificationModel(
        id: 'notif_asgn_01',
        userId: 'user_draughtsman_1',
        projectId: 'proj_commercial_01',
        type: 'DRAUGHTSMAN_ASSIGNED',
        title: 'New Commercial Assignment',
        message: 'You have been assigned to Commercial Office Block.',
        isRead: false,
        createdAt: DateTime.utc(2026, 10, 10, 12, 0),
      );

      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/draughtsman/assignments/:assignmentId',
            builder: (context, state) {
              routedLocation = state.uri.toString();
              return Scaffold(body: Text('Assignment Screen ${state.pathParameters['assignmentId']}'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        createTestApp(
          profile: draughtsmanProfile,
          notifications: [assignedNotification],
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Commercial Assignment'));
      await tester.pumpAndSettle();

      expect(routedLocation, '/draughtsman/assignments/proj_commercial_01');
      expect(find.text('Assignment Screen proj_commercial_01'), findsOneWidget);
    });

    testWidgets('Tapping WAITING_ACCEPTANCE notification as DRAUGHTSMAN routes to /draughtsman/assignments/:projectId', (tester) async {
      String? routedLocation;

      final draughtsmanProfile = const UserProfile(
        id: 'user_draughtsman_1',
        name: 'Dan Draughtsman',
        email: 'dan@example.com',
        mobile: '1234567890',
        role: 'DRAUGHTSMAN',
      );

      final waitingNotification = NotificationModel(
        id: 'notif_wait_01',
        userId: 'user_draughtsman_1',
        projectId: 'proj_commercial_01',
        type: 'WAITING_ACCEPTANCE',
        title: 'Assignment Awaiting Acceptance',
        message: 'Please review and accept assignment.',
        isRead: false,
        createdAt: DateTime.utc(2026, 10, 10, 12, 0),
      );

      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/draughtsman/assignments/:assignmentId',
            builder: (context, state) {
              routedLocation = state.uri.toString();
              return Scaffold(body: Text('Assignment Screen ${state.pathParameters['assignmentId']}'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        createTestApp(
          profile: draughtsmanProfile,
          notifications: [waitingNotification],
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Assignment Awaiting Acceptance'));
      await tester.pumpAndSettle();

      expect(routedLocation, '/draughtsman/assignments/proj_commercial_01');
      expect(find.text('Assignment Screen proj_commercial_01'), findsOneWidget);
    });

    testWidgets('Empty notifications list renders "No notifications"', (tester) async {
      final studentProfile = const UserProfile(
        id: 'user_student_1',
        name: 'Alice Student',
        email: 'alice@example.com',
        mobile: '1234567890',
        role: 'STUDENT',
      );

      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        createTestApp(
          profile: studentProfile,
          notifications: [],
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No notifications'), findsOneWidget);
    });

    testWidgets('Back button safely falls back to /student/dashboard for student', (tester) async {
      String? currentPath;
      final studentProfile = const UserProfile(
        id: 'user_student_1',
        name: 'Alice Student',
        email: 'alice@example.com',
        mobile: '1234567890',
        role: 'STUDENT',
      );

      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/student/dashboard',
            builder: (context, state) {
              currentPath = state.uri.toString();
              return const Scaffold(body: Text('Student Dashboard'));
            },
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) {
              currentPath = state.uri.toString();
              return const NotificationsScreen();
            },
          ),
        ],
      );

      await tester.pumpWidget(
        createTestApp(
          profile: studentProfile,
          notifications: [testNotification],
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(currentPath, '/notifications');
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(currentPath, '/student/dashboard');
      expect(find.text('Student Dashboard'), findsOneWidget);
    });

    testWidgets('Tapping notification as ADMIN routes to /admin/projects/:id', (tester) async {
      String? routedLocation;

      final adminProfile = const UserProfile(
        id: 'user_admin_1',
        name: 'Admin User',
        email: 'admin@example.com',
        mobile: '1234567890',
        role: 'ADMIN',
      );

      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/admin/projects/:projectId',
            builder: (context, state) {
              routedLocation = state.uri.toString();
              return Scaffold(body: Text('Admin Project ${state.pathParameters['projectId']}'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        createTestApp(
          profile: adminProfile,
          notifications: [testNotification],
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Correction Requested'));
      await tester.pumpAndSettle();

      expect(routedLocation, '/admin/projects/proj_hybrid_01');
      expect(find.text('Admin Project proj_hybrid_01'), findsOneWidget);
    });

    testWidgets('Tapping notification as STUDIO_ADMIN routes to /admin/projects/:id', (tester) async {
      String? routedLocation;

      final studioAdminProfile = const UserProfile(
        id: 'user_admin_2',
        name: 'Studio Admin User',
        email: 'studioadmin@example.com',
        mobile: '1234567890',
        role: 'STUDIO_ADMIN',
      );

      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/admin/projects/:projectId',
            builder: (context, state) {
              routedLocation = state.uri.toString();
              return Scaffold(body: Text('Admin Project ${state.pathParameters['projectId']}'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        createTestApp(
          profile: studioAdminProfile,
          notifications: [testNotification],
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Correction Requested'));
      await tester.pumpAndSettle();

      expect(routedLocation, '/admin/projects/proj_hybrid_01');
      expect(find.text('Admin Project proj_hybrid_01'), findsOneWidget);
    });

    testWidgets('Tapping notification as ADMIN with missing projectId falls back to /admin/dashboard', (tester) async {
      String? routedLocation;

      final adminProfile = const UserProfile(
        id: 'user_admin_1',
        name: 'Admin User',
        email: 'admin@example.com',
        mobile: '1234567890',
        role: 'ADMIN',
      );

      final noProjectNotification = NotificationModel(
        id: 'notif_no_proj',
        userId: 'user_admin_1',
        projectId: null,
        type: 'SYSTEM_ALERT',
        title: 'System Alert',
        message: 'System maintenance scheduled.',
        isRead: false,
        createdAt: DateTime.utc(2026, 10, 10, 12, 0),
      );

      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) {
              routedLocation = state.uri.toString();
              return const Scaffold(body: Text('Admin Dashboard'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        createTestApp(
          profile: adminProfile,
          notifications: [noProjectNotification],
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('System Alert'));
      await tester.pumpAndSettle();

      expect(routedLocation, '/admin/dashboard');
      expect(find.text('Admin Dashboard'), findsOneWidget);
    });

    testWidgets('Back button safely falls back to /admin/dashboard for ADMIN', (tester) async {
      String? currentPath;
      final adminProfile = const UserProfile(
        id: 'user_admin_1',
        name: 'Admin User',
        email: 'admin@example.com',
        mobile: '1234567890',
        role: 'ADMIN',
      );

      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) {
              currentPath = state.uri.toString();
              return const Scaffold(body: Text('Admin Dashboard'));
            },
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) {
              currentPath = state.uri.toString();
              return const NotificationsScreen();
            },
          ),
        ],
      );

      await tester.pumpWidget(
        createTestApp(
          profile: adminProfile,
          notifications: [testNotification],
          router: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(currentPath, '/notifications');
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(currentPath, '/admin/dashboard');
      expect(find.text('Admin Dashboard'), findsOneWidget);
    });
  });
}
