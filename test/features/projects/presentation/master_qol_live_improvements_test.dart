import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/projects/domain/project_status.dart';
import 'package:archi_draft/src/features/projects/presentation/widgets/project_status_chip.dart';
import 'package:archi_draft/src/features/notifications/domain/app_notification.dart';
import 'package:archi_draft/src/features/notifications/presentation/widgets/notification_ui_components.dart';

void main() {
  group('Master QoL & Live Workflow UI Standards Tests', () {
    testWidgets('1. ProjectStatusChip formats simple human language labels accurately', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                ProjectStatusChip(
                  status: ProjectStatus.underAdminReview,
                  useHumanLabel: true,
                ),
                ProjectStatusChip(
                  status: ProjectStatus.underEngineerReview,
                  useHumanLabel: true,
                ),
                ProjectStatusChip(
                  status: ProjectStatus.completed,
                  useHumanLabel: true,
                ),
                ProjectStatusChip(
                  status: ProjectStatus.inProgress,
                  correctionRound: 2,
                  useHumanLabel: true,
                ),
                ProjectStatusChip(
                  status: ProjectStatus.waitingAssignment,
                  useHumanLabel: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Waiting for Studio Review'), findsOneWidget);
      expect(find.text('Waiting for Your Review'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('Correction Round 2'), findsOneWidget);
      expect(find.text('Needs Draughtsman'), findsOneWidget);
    });

    testWidgets('2. ProjectStatusChip preserves database enum uppercase compatibility when flag is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                ProjectStatusChip(status: ProjectStatus.draft),
                ProjectStatusChip(status: ProjectStatus.submitted),
              ],
            ),
          ),
        ),
      );

      expect(find.text('DRAFT'), findsOneWidget);
      expect(find.text('SUBMITTED'), findsOneWidget);
    });

    testWidgets('3. NotificationItemCard supports onDismiss action callback', (tester) async {
      bool dismissed = false;
      final testNotification = AppNotification(
        id: 'notif-999',
        userId: 'user-1',
        projectId: 'proj-1',
        type: 'PROJECT_SUBMITTED',
        title: 'New Project Submitted',
        message: 'Your project brief is ready for review.',
        isRead: false,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationItemCard(
              notification: testNotification,
              onTap: () {},
              onDismiss: () {
                dismissed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('New Project Submitted'), findsOneWidget);
      final dismissBtn = find.byTooltip('Dismiss notification');
      expect(dismissBtn, findsOneWidget);

      await tester.tap(dismissBtn);
      await tester.pump();

      expect(dismissed, isTrue);
    });
  });
}

