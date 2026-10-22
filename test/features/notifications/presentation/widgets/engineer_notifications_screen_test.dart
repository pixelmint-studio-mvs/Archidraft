import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/auth/domain/user_profile.dart';
import 'package:archi_draft/src/features/auth/providers/auth_providers.dart';
import 'package:archi_draft/src/features/notifications/domain/app_notification.dart';
import 'package:archi_draft/src/features/notifications/providers/notification_providers.dart';
import 'package:archi_draft/src/features/notifications/presentation/notifications_screen.dart';

void main() {
  final testEngineer = UserProfile(
    id: 'engineer-001',
    email: 'testengineer@archidraft.test',
    name: 'Chief Engineer Sarah J.',
    mobile: '+1234567890',
    role: 'ENGINEER',
  );

  final testNotifications = [
    AppNotification(
      id: 'notif-001',
      userId: 'engineer-001',
      projectId: 'proj-101',
      type: 'CHAT_MESSAGE',
      title: 'Remark from Draughtsman Alice',
      message: 'Grid lines 4-C adjusted per local zoning setback rules.',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    AppNotification(
      id: 'notif-002',
      userId: 'engineer-001',
      projectId: 'proj-102',
      type: 'DRAWING_SUBMITTED',
      title: 'Drawing Submitted: Civic Center Foundation',
      message: 'New revision Rev-2 uploaded for engineering approval.',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'notif-003',
      userId: 'engineer-001',
      projectId: 'proj-103',
      type: 'PROJECT_APPROVED',
      title: 'Structural Signoff Complete',
      message: 'Harbor Tower Respec approved for municipal permit issuance.',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  Widget createTestWidget({
    Size surfaceSize = const Size(1280, 800),
    List<AppNotification>? notificationsOverride,
    Future<List<AppNotification>> Function(Ref ref)? customNotificationProvider,
  }) {
    return ProviderScope(
      overrides: [
        userProfileProvider.overrideWith((ref) => Future.value(testEngineer)),
        if (customNotificationProvider != null)
          notificationsProvider.overrideWith(customNotificationProvider)
        else
          notificationsProvider.overrideWith(
            (ref) => Future.value(notificationsOverride ?? testNotifications),
          ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: const SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: NotificationsScreen(),
          ),
        ),
      ),
    );
  }

  group('Engineer NotificationsScreen Widget Tests', () {
    testWidgets('renders Desktop 1280x800 layout matching Draughtsman visual design', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(surfaceSize: const Size(1280, 800)));
      await tester.pumpAndSettle();

      // Header card elements
      expect(find.text('Notifications'), findsWidgets);
      expect(find.text('2 UNREAD'), findsOneWidget);
      expect(find.text('Mark All as Read'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
      expect(find.text('Direct notifications on project milestones, draughtsman submissions, and review actions.'), findsOneWidget);

      // Filter chips
      expect(find.text('All (3)'), findsOneWidget);
      expect(find.text('Unread (2)'), findsOneWidget);
      expect(find.text('Reviews (2)'), findsOneWidget);
      expect(find.text('Remarks (1)'), findsOneWidget);

      // Notification cards
      expect(find.text('Remark from Draughtsman Alice'), findsOneWidget);
      expect(find.text('Drawing Submitted: Civic Center Foundation'), findsOneWidget);
      expect(find.text('Structural Signoff Complete'), findsOneWidget);

      // Category tags
      expect(find.text('REMARK'), findsOneWidget);
      expect(find.text('SUBMISSION'), findsOneWidget);
      expect(find.text('APPROVED'), findsOneWidget);
    });

    testWidgets('renders Mobile 400x800 layout with zero RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(surfaceSize: const Size(400, 800)));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsWidgets);
      expect(find.text('2 UNREAD'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('filters notifications accurately between Unread, Reviews, Remarks, and All', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Filter Unread
      await tester.tap(find.text('Unread (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Remark from Draughtsman Alice'), findsOneWidget);
      expect(find.text('Drawing Submitted: Civic Center Foundation'), findsOneWidget);
      expect(find.text('Structural Signoff Complete'), findsNothing);

      // Filter Remarks
      await tester.tap(find.text('Remarks (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Remark from Draughtsman Alice'), findsOneWidget);
      expect(find.text('Drawing Submitted: Civic Center Foundation'), findsNothing);

      // Filter Reviews
      await tester.tap(find.text('Reviews (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Drawing Submitted: Civic Center Foundation'), findsOneWidget);
      expect(find.text('Structural Signoff Complete'), findsOneWidget);
      expect(find.text('Remark from Draughtsman Alice'), findsNothing);

      // Back to All
      await tester.tap(find.text('All (3)'));
      await tester.pumpAndSettle();

      expect(find.text('Remark from Draughtsman Alice'), findsOneWidget);
      expect(find.text('Drawing Submitted: Civic Center Foundation'), findsOneWidget);
      expect(find.text('Structural Signoff Complete'), findsOneWidget);
    });

    testWidgets('renders Empty State with Back to Dashboard action', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(notificationsOverride: []));
      await tester.pumpAndSettle();

      expect(find.text('ALL CAUGHT UP'), findsOneWidget);
      expect(find.text('No Notifications Found'), findsOneWidget);
      expect(find.text('Back to Dashboard'), findsOneWidget);
    });

    testWidgets('renders Error State with retry button on failure', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(
        customNotificationProvider: (ref) => Future.error(Exception('Connection timed out')),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load notifications.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Mark All as Read button triggers provider and shows feedback SnackBar', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      var markAllTriggered = false;

      final container = ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => Future.value(testEngineer)),
          notificationsProvider.overrideWith(
            (ref) => Future.value(testNotifications),
          ),
          markAllNotificationsReadProvider.overrideWith((ref) async {
            markAllTriggered = true;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: NotificationsScreen()),
        ),
      );

      await tester.pumpWidget(container);
      await tester.pumpAndSettle();

      final markAllBtn = find.byKey(const Key('notifications_mark_all_read_button'));
      expect(markAllBtn, findsOneWidget);

      await tester.tap(markAllBtn);
      await tester.pumpAndSettle();

      expect(markAllTriggered, isTrue);
      expect(find.text('All notifications marked as read.'), findsOneWidget);
    });
  });
}
