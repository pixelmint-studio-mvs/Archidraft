import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/domain/project_message.dart';
import 'package:archi_draft/src/features/projects/presentation/collaboration_hub_screen.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/projects/providers/message_providers.dart';

void main() {
  const testProjectId = '79c7f5b1-b96d-4db3-8987-b2743e092aa3';

  final testProject = Project(
    projectId: testProjectId,
    projectName: 'Test Engineer Project',
    projectAddress: '123 Main St',
    drawingName: 'Floor Plan',
    drawingType: 'Architectural',
    clientId: '0IGksIGWRoaR4drnjT1hAkTvT7g1',
    status: 'IN_PROGRESS',
    assignedDraughtsmanId: 'draughtsman-uid-1',
  );

  final testMessages = [
    ProjectMessage(
      id: 'msg-1',
      projectId: testProjectId,
      senderId: '0IGksIGWRoaR4drnjT1hAkTvT7g1',
      senderName: 'Sarah J.',
      senderRole: 'ENGINEER',
      message: 'Please check the column placement on grid B-2.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ProjectMessage(
      id: 'msg-2',
      projectId: testProjectId,
      senderId: 'draughtsman-uid-1',
      senderName: 'Alex Draughtsman',
      senderRole: 'DRAUGHTSMAN',
      message: 'Adjusted and attached updated sheet.',
      attachmentFileId: 'file-123',
      attachmentName: 'Sheet_B2_revised.pdf',
      attachmentSize: 1048576,
      attachmentContentType: 'application/pdf',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  testWidgets('CollaborationHubScreen renders messages, sender badges, and composer', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectProvider(testProjectId).overrideWith((ref) => Future.value(testProject)),
          projectMessagesProvider(testProjectId).overrideWith((ref) => Future.value(testMessages)),
        ],
        child: const MaterialApp(
          home: CollaborationHubScreen(projectId: testProjectId),
        ),
      ),
    );

    // Initial pump and settle
    await tester.pumpAndSettle();

    // Verify header elements
    expect(find.text('Collaboration Hub'), findsOneWidget);
    expect(find.textContaining('79C7F5B1'), findsOneWidget);
    expect(find.text('Test Engineer Project'), findsOneWidget);

    // Verify messages render
    expect(find.text('Please check the column placement on grid B-2.'), findsOneWidget);
    expect(find.text('Adjusted and attached updated sheet.'), findsOneWidget);

    // Verify sender roles
    expect(find.text('Engineer'), findsOneWidget);
    expect(find.text('Draughtsman'), findsOneWidget);

    // Verify attachment renders
    expect(find.text('Sheet_B2_revised.pdf'), findsOneWidget);

    // Verify composer elements
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);
  });

  testWidgets('CollaborationHubScreen renders empty state when no messages', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectProvider(testProjectId).overrideWith((ref) => Future.value(testProject)),
          projectMessagesProvider(testProjectId).overrideWith((ref) => Future.value([])),
        ],
        child: const MaterialApp(
          home: CollaborationHubScreen(projectId: testProjectId),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No messages yet'), findsOneWidget);
    expect(find.textContaining('Start the conversation with your assigned draughtsman'), findsOneWidget);
  });
}
