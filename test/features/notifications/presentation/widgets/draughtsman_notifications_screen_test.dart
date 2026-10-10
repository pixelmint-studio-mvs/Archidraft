import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/notifications/domain/app_notification.dart';
import 'package:archi_draft/src/features/notifications/providers/notification_providers.dart';
import 'package:archi_draft/src/features/notifications/presentation/notifications_screen.dart';
import 'package:archi_draft/src/features/projects/domain/assignment.dart';
import 'package:archi_draft/src/features/projects/providers/assignment_providers.dart';

void main() {
  final testAssignments = [
    Assignment(
      id: 'assign-001',
      projectId: 'proj-001',
      draughtsmanId: 'draughtsman-001',
      projectName: 'Civic Center Pavilion',
      projectAddress: '100 Civic Center Blvd',
      status: 'IN_PROGRESS',
      projectStatus: 'IN_PROGRESS',
      assignedAt: DateTime.now().subtract(const Duration(days: 3)),
      drawingType: 'FLOOR_PLAN',
      correctionRound: 0,
    ),
  ];

  final testNotifications = [
    AppNotification(
      id: 'notif-001',
      userId: 'draughtsman-001',
      type: 'CHAT_MESSAGE',
      title: 'Remark from Engineer Sarah J.',
      message: 'Please review structural footing callout at Grid Line B.',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    AppNotification(
      id: 'notif-002',
      userId: 'draughtsman-001',
      type: 'CORRECTION_REQUESTED',
      title: 'Correction Requested: Civic Center Pavilion',
      message: 'Scale ratio must be adjusted to 1:50 on Sheet A-02.',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'notif-003',
      userId: 'draughtsman-001',
      type: 'PROJECT_APPROVED',
      title: 'Drawing Approved: Harbor Tower Respec',
      message: 'Client has signed off on the revised elevation drawings.',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  Widget createTestWidget({
    Size surfaceSize = const Size(1280, 800),
    List<AppNotification>? notificationsOverride,
    List<Assignment>? assignmentsOverride,
    Future<List<AppNotification>> Function(Ref ref)? customNotificationProvider,
  }) {
    return ProviderScope(
      overrides: [
        if (customNotificationProvider != null)
          notificationsProvider.overrideWith(customNotificationProvider)
        else
          notificationsProvider.overrideWith(
            (ref) => Future.value(notificationsOverride ?? testNotifications),
          ),
        draughtsmanAssignmentsProvider.overrideWith(
          (ref) => Future.value(assignmentsOverride ?? testAssignments),
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: const SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: DraughtsmanNotificationsScreen(),
          ),
        ),
      ),
    );
  }

  group('DraughtsmanNotificationsScreen Widget Tests', () {
    testWidgets('renders Desktop 1280x800 layout with headers, filters and notifications', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(surfaceSize: const Size(1280, 800)));
      await tester.pumpAndSettle();

      // Header card elements
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('2 UNREAD'), findsOneWidget);
      expect(find.text('Mark All as Read'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);

      // Filter chips
      expect(find.text('All (3)'), findsOneWidget);
      expect(find.text('Unread (2)'), findsOneWidget);
      expect(find.text('Reviews (2)'), findsOneWidget);
      expect(find.text('Remarks (1)'), findsOneWidget);

      // Notification cards
      expect(find.text('Remark from Engineer Sarah J.'), findsOneWidget);
      expect(find.text('Correction Requested: Civic Center Pavilion'), findsOneWidget);
      expect(find.text('Drawing Approved: Harbor Tower Respec'), findsOneWidget);
    });

    testWidgets('renders Mobile 400x800 layout with zero RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(surfaceSize: const Size(400, 800)));
      await tester.pumpAndSettle();

      // Header and content still visible without error
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('2 UNREAD'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('filters by Unread, Remarks, and back to All', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially all 3 are displayed
      expect(find.text('Remark from Engineer Sarah J.'), findsOneWidget);
      expect(find.text('Correction Requested: Civic Center Pavilion'), findsOneWidget);
      expect(find.text('Drawing Approved: Harbor Tower Respec'), findsOneWidget);

      // Tap 'Unread (2)' filter
      await tester.tap(find.text('Unread (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Remark from Engineer Sarah J.'), findsOneWidget);
      expect(find.text('Correction Requested: Civic Center Pavilion'), findsOneWidget);
      expect(find.text('Drawing Approved: Harbor Tower Respec'), findsNothing);

      // Tap 'Remarks (1)' filter
      await tester.tap(find.text('Remarks (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Remark from Engineer Sarah J.'), findsOneWidget);
      expect(find.text('Correction Requested: Civic Center Pavilion'), findsNothing);

      // Tap 'All (3)' filter
      await tester.tap(find.text('All (3)'));
      await tester.pumpAndSettle();

      expect(find.text('Drawing Approved: Harbor Tower Respec'), findsOneWidget);
    });

    testWidgets('renders Empty State when no notifications exist', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(notificationsOverride: []));
      await tester.pumpAndSettle();

      expect(find.text('ALL CAUGHT UP'), findsOneWidget);
      expect(find.text('No Notifications Found'), findsOneWidget);
      expect(find.textContaining('You have no notifications'), findsOneWidget);
    });

    testWidgets('renders Error State with retry button on failure', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(
        customNotificationProvider: (ref) => Future.error(Exception('Network timeout')),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load notifications.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('mark all as read button triggers provider and displays feedback', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      var markAllCalled = false;

      final container = ProviderScope(
        overrides: [
          notificationsProvider.overrideWith(
            (ref) => Future.value(testNotifications),
          ),
          draughtsmanAssignmentsProvider.overrideWith(
            (ref) => Future.value(testAssignments),
          ),
          markAllNotificationsReadProvider.overrideWith((ref) async {
            markAllCalled = true;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DraughtsmanNotificationsScreen()),
        ),
      );

      await tester.pumpWidget(container);
      await tester.pumpAndSettle();

      final markAllBtn = find.byKey(const Key('notifications_mark_all_read_button'));
      expect(markAllBtn, findsOneWidget);

      await tester.tap(markAllBtn);
      await tester.pumpAndSettle();

      expect(markAllCalled, isTrue);
      expect(find.text('All notifications marked as read.'), findsOneWidget);
    });

    testWidgets('handles unsupported or incomplete payload safely without crash', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final weirdNotification = AppNotification(
        id: 'notif-999',
        userId: 'draughtsman-001',
        type: 'UNKNOWN_TYPE_XYZ',
        title: '',
        message: '',
        isRead: false,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(
        notificationsOverride: [weirdNotification],
        assignmentsOverride: [],
      ));
      await tester.pumpAndSettle();

      // Card renders sanitized tag and falls back gracefully
      expect(find.text('UNKNOWN TYPE XYZ'), findsOneWidget);
    });
  });
}
