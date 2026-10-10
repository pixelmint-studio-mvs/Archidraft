import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/projects/data/voice_recorder_service.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/domain/project_message.dart';
import 'package:archi_draft/src/features/projects/presentation/collaboration_hub_screen.dart';
import 'package:archi_draft/src/features/projects/presentation/widgets/voice_message_player.dart';
import 'package:archi_draft/src/features/projects/presentation/widgets/voice_recorder_bar.dart';
import 'package:archi_draft/src/features/projects/providers/message_providers.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';

class TestMockVoiceRecorderService implements VoiceRecorderService {
  bool recordingActive = false;

  @override
  Future<MicrophonePermissionResult> checkAndRequestPermission() async => MicrophonePermissionResult.granted;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<void> startRecording() async {
    recordingActive = true;
  }

  @override
  Future<VoiceRecordingResult?> stopRecording(Duration elapsedDuration) async {
    recordingActive = false;
    return VoiceRecordingResult(
      bytes: Uint8List.fromList([1, 2, 3, 4]),
      path: 'test://path.webm',
      extension: 'webm',
      contentType: 'audio/webm',
      duration: const Duration(seconds: 5),
    );
  }

  @override
  Future<void> cancelRecording() async {
    recordingActive = false;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  const testProjectId = 'proj-voice-test-1';

  final testProject = Project(
    projectId: testProjectId,
    projectName: 'Voice Message Project',
    projectAddress: '456 Ocean Ave',
    drawingName: 'Section View',
    drawingType: 'Structural',
    clientId: 'engineer-uid-1',
    status: 'IN_PROGRESS',
    assignedDraughtsmanId: 'draughtsman-uid-1',
  );

  final testVoiceMessage = ProjectMessage(
    id: 'msg-voice-1',
    projectId: testProjectId,
    senderId: 'engineer-uid-1',
    senderName: 'Sarah Engineer',
    senderRole: 'ENGINEER',
    message: '',
    attachmentFileId: 'audio-file-123',
    attachmentName: 'voice_note_1.webm',
    attachmentSize: 32000,
    attachmentContentType: 'audio/webm',
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
  );

  final testDocMessage = ProjectMessage(
    id: 'msg-doc-1',
    projectId: testProjectId,
    senderId: 'draughtsman-uid-1',
    senderName: 'Mark Draughtsman',
    senderRole: 'DRAUGHTSMAN',
    message: 'Here is the PDF drawing.',
    attachmentFileId: 'doc-file-456',
    attachmentName: 'drawing_rev1.pdf',
    attachmentSize: 1048576,
    attachmentContentType: 'application/pdf',
    createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
  );

  testWidgets('CollaborationHubScreen shows mic button and renders VoiceMessagePlayer for voice notes', (tester) async {
    final mockRecorder = TestMockVoiceRecorderService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          voiceRecorderServiceProvider.overrideWithValue(mockRecorder),
          projectProvider(testProjectId).overrideWith((ref) => Future.value(testProject)),
          projectMessagesProvider(testProjectId).overrideWith((ref) => Future.value([testVoiceMessage, testDocMessage])),
        ],
        child: const MaterialApp(
          home: CollaborationHubScreen(projectId: testProjectId),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify microphone button is present in the composer
    final micButtonFinder = find.byTooltip('Record voice message');
    expect(micButtonFinder, findsOneWidget);

    // Verify VoiceMessagePlayer is rendered for the audio message
    expect(find.byType(VoiceMessagePlayer), findsOneWidget);
    expect(find.text('Voice note'), findsOneWidget);

    // Verify standard document message still renders standard attachment card
    expect(find.text('drawing_rev1.pdf'), findsOneWidget);
    expect(find.text('Here is the PDF drawing.'), findsOneWidget);
  });

  testWidgets('Tapping microphone transitions composer to VoiceRecorderBar recording state', (tester) async {
    final mockRecorder = TestMockVoiceRecorderService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          voiceRecorderServiceProvider.overrideWithValue(mockRecorder),
          projectProvider(testProjectId).overrideWith((ref) => Future.value(testProject)),
          projectMessagesProvider(testProjectId).overrideWith((ref) => Future.value([])),
        ],
        child: const MaterialApp(
          home: CollaborationHubScreen(projectId: testProjectId),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap the microphone button
    final micButton = find.byTooltip('Record voice message');
    expect(micButton, findsOneWidget);
    await tester.tap(micButton);
    await tester.pump();

    // Verify VoiceRecorderBar is visible in recording state
    expect(find.byType(VoiceRecorderBar), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);
    expect(find.byTooltip('Cancel & Discard'), findsOneWidget);
    expect(find.byTooltip('Review before sending'), findsOneWidget);

    // Tap discard
    await tester.tap(find.byTooltip('Cancel & Discard'));
    await tester.pump();

    // Verify returned to idle composer
    expect(find.text('0:00'), findsNothing);
    expect(find.byTooltip('Record voice message'), findsOneWidget);
  });
}
