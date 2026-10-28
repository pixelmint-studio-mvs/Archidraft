import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:archi_draft/src/features/engineer/presentation/engineer_activity_screen.dart';
import 'package:archi_draft/src/features/projects/domain/activity_log.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createWidgetUnderTest({required List overrides}) {
    return ProviderScope(
      overrides: overrides.cast(),
      child: const MaterialApp(
        home: Scaffold(
          body: EngineerActivityScreen(),
        ),
      ),
    );
  }

  group('EngineerActivityScreen Widget Tests', () {
    testWidgets('Renders empty state with Refresh Feed button when no activities exist', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          overrides: [
            engineerActivityLogsProvider.overrideWith((ref) => Future.value([])),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Activity Feed'), findsOneWidget);
      expect(find.text('Track real-time actions and lifecycle updates across your engineering projects.'), findsOneWidget);
      expect(find.text('No Activity Yet'), findsOneWidget);
      expect(find.text('Activities will appear here as your projects are created, reviewed, and updated.'), findsOneWidget);
      expect(find.text('Refresh Feed'), findsOneWidget);
    });

    testWidgets('Renders activity list items with distinct timestamps for different events', (tester) async {
      final time1 = DateTime.utc(2026, 10, 26, 20, 44, 17).toLocal();
      final time2 = DateTime.utc(2026, 10, 26, 17, 42, 7).toLocal();
      final formattedTime1 = DateFormat('MMM d, y • h:mm a').format(time1);
      final formattedTime2 = DateFormat('MMM d, y • h:mm a').format(time2);

      final sampleActivities = [
        ActivityLog(
          id: 'act-001',
          projectId: 'prj-101',
          projectName: 'Cybernetic Medical Center',
          actionType: 'ASSIGNMENT_ACCEPTED',
          actorId: 'draught-01',
          actorRole: 'DRAUGHTSMAN',
          details: 'User accepted the assignment.',
          createdAt: time1,
        ),
        ActivityLog(
          id: 'act-002',
          projectId: 'prj-102',
          projectName: 'MVS-1 Villa',
          actionType: 'PROJECT_COMPLETED',
          actorId: 'eng-01',
          actorRole: 'ENGINEER',
          details: 'Engineer approved the final drawing.',
          createdAt: time2,
        ),
      ];

      await tester.pumpWidget(
        createWidgetUnderTest(
          overrides: [
            engineerActivityLogsProvider.overrideWith((ref) => Future.value(sampleActivities)),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Activity Feed'), findsOneWidget);
      expect(find.text('No Activity Yet'), findsNothing);
      expect(find.text('User accepted the assignment.'), findsOneWidget);
      expect(find.text('Engineer approved the final drawing.'), findsOneWidget);

      // Verify that distinct formatted timestamps are rendered in the subtitles
      expect(find.textContaining(formattedTime1), findsOneWidget);
      expect(find.textContaining(formattedTime2), findsOneWidget);
      expect(formattedTime1, isNot(equals(formattedTime2)));
    });

    testWidgets('Renders Date unavailable when timestamp is null or invalid without falling back to DateTime.now()', (tester) async {
      final sampleActivities = [
        ActivityLog(
          id: 'act-003',
          projectId: 'prj-103',
          projectName: 'Unknown Date Tower',
          actionType: 'PROJECT_SUBMITTED',
          actorId: 'eng-01',
          actorRole: 'ENGINEER',
          details: 'Project submitted without valid date',
          createdAt: null,
        ),
      ];

      await tester.pumpWidget(
        createWidgetUnderTest(
          overrides: [
            engineerActivityLogsProvider.overrideWith((ref) => Future.value(sampleActivities)),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Activity Feed'), findsOneWidget);
      expect(find.textContaining('Date unavailable'), findsOneWidget);
    });

    testWidgets('Renders error widget when loading activity logs fails', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          overrides: [
            engineerActivityLogsProvider.overrideWith((ref) => Future.error(Exception('Connection refused'))),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Activity Feed'), findsOneWidget);
      expect(find.text('Failed to load activity logs.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
