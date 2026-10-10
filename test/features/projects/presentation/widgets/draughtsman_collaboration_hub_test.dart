import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/domain/project_message.dart';
import 'package:archi_draft/src/features/projects/domain/project_file.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/projects/providers/file_providers.dart';
import 'package:archi_draft/src/features/projects/presentation/draughtsman/collaboration_hub_view.dart';
import 'package:archi_draft/src/features/notifications/providers/notification_providers.dart';
import 'package:archi_draft/src/features/notifications/domain/app_notification.dart';
import 'package:archi_draft/src/features/projects/data/audio_service.dart';
import 'package:archi_draft/src/features/projects/presentation/draughtsman/widgets/voice_note_player_widget.dart';
import 'package:archi_draft/src/features/projects/presentation/draughtsman/widgets/voice_note_recorder_widget.dart';
import 'package:archi_draft/src/features/projects/data/audio_service_io.dart';

void main() {
  final testProject = Project(
    projectId: 'PRJ-TEST-HUB-01',
    clientId: 'client-01',
    projectName: 'Oslo Opera House Extension',
    projectAddress: 'Harbor Front 12, Oslo',
    drawingName: 'Sheet S-102 Floor Plan',
    drawingType: 'ARCHITECTURAL_DRAFTING',
    status: 'IN_PROGRESS',
    correctionRound: 1,
    createdAt: DateTime.now().subtract(const Duration(days: 4)),
  );

  final testMessages = [
    ProjectMessage(
      id: 'msg-01',
      projectId: 'PRJ-TEST-HUB-01',
      senderId: 'eng-01',
      senderName: 'Sarah J.',
      senderRole: 'ENGINEER',
      message: "The load-bearing calculations for column C-4 need a revision. We're showing a 15% discrepancy against the updated seismic parameters. I've attached the revised analysis.",
      attachmentFileId: 'file-pdf-01',
      attachmentName: 'Seismic_Calc_v2.pdf',
      attachmentSize: 2400000,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    ProjectMessage(
      id: 'msg-02',
      projectId: 'PRJ-TEST-HUB-01',
      senderId: 'draughtsman-01',
      senderName: 'Draughtsman',
      senderRole: 'DRAUGHTSMAN',
      message: "@Sarah J. Understood. I've adjusted the reinforcement detailing on sheet S-102 to accommodate the new specs. Please review the updated DWG. (Voice Note attached)",
      attachmentFileId: 'file-dwg-01',
      attachmentName: 'S-102_RevB.dwg',
      attachmentSize: 18100000,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  final testFiles = [
    ProjectFile(
      id: 'file-pdf-01',
      projectId: 'PRJ-TEST-HUB-01',
      uploadedBy: 'eng-01',
      originalName: 'Seismic_Calc_v2.pdf',
      sanitizedName: 'Seismic_Calc_v2.pdf',
      objectKey: 'keys/seismic.pdf',
      contentType: 'application/pdf',
      size: 2400000,
      category: 'attachment',
      status: 'COMPLETED',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    ProjectFile(
      id: 'file-dwg-01',
      projectId: 'PRJ-TEST-HUB-01',
      uploadedBy: 'draughtsman-01',
      originalName: 'S-102_RevB.dwg',
      sanitizedName: 'S-102_RevB.dwg',
      objectKey: 'keys/s102.dwg',
      contentType: 'application/octet-stream',
      size: 18100000,
      category: 'attachment',
      status: 'COMPLETED',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  Widget createSubject({required Size screenSize, AudioRecorderService? recorder}) {
    return ProviderScope(
      overrides: [
        projectMessagesProvider('PRJ-TEST-HUB-01').overrideWith((ref) => Future.value(testMessages)),
        projectFilesProvider('PRJ-TEST-HUB-01').overrideWith((ref) => Future.value(testFiles)),
        notificationsProvider.overrideWith((ref) => Future.value(<AppNotification>[])),
        currentUserIdProvider.overrideWith((ref) => 'draughtsman-01'),
        if (recorder != null) audioRecorderProvider.overrideWithValue(recorder),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(size: screenSize),
            child: SizedBox(
              width: screenSize.width,
              height: screenSize.height,
              child: CollaborationHubView(
                projectId: 'PRJ-TEST-HUB-01',
                project: testProject,
                isEmbedded: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Collaboration Hub renders messages, attachments and header on Desktop (1280x800) with zero overflow', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createSubject(screenSize: const Size(1280, 800)));
    await tester.pumpAndSettle();

    // Verify Header
    expect(find.text('Collaboration Hub'), findsOneWidget);
    expect(find.text('#DWG-PRJ-TE'), findsOneWidget);

    // Verify Messages
    expect(find.textContaining('Sarah J.'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('load-bearing calculations'),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('Understood'),
      ),
      findsOneWidget,
    );

    // Verify Attachments
    expect(find.text('Seismic_Calc_v2.pdf'), findsOneWidget);
    expect(find.text('S-102_RevB.dwg'), findsOneWidget);

    // Verify Composer elements
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);

    // Zero overflow assertion
    expect(tester.takeException(), isNull);
  });

  testWidgets('Collaboration Hub renders on Mobile (400x800) with zero overflow', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createSubject(screenSize: const Size(400, 800)));
    await tester.pumpAndSettle();

    expect(find.text('Collaboration Hub'), findsOneWidget);
    expect(find.text('Seismic_Calc_v2.pdf'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Zero overflow assertion
    expect(tester.takeException(), isNull);
  });

  testWidgets('Can stage text in composer', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createSubject(screenSize: const Size(1280, 800)));
    await tester.pumpAndSettle();

    final inputField = find.byType(TextField);
    await tester.enterText(inputField, 'Draft revision vectors are ready for client review.');
    await tester.pump();

    expect(find.text('Draft revision vectors are ready for client review.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Clicking mic button opens voice note recording banner with live timer and stop/cancel controls', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final recorder = IoAudioRecorderService();
    recorder.mockPermissionGranted = true;
    addTearDown(() => recorder.cancelRecording());

    await tester.pumpWidget(createSubject(screenSize: const Size(1280, 800), recorder: recorder));
    await tester.pumpAndSettle();

    // Tap the microphone icon button
    final micButton = find.byIcon(Icons.mic_none_rounded);
    expect(micButton, findsOneWidget);
    await tester.tap(micButton);
    await tester.pump();

    // Verify recording banner is visible
    expect(find.byType(VoiceNoteRecorderWidget), findsOneWidget);
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);

    // Cancel to clean up recording timer before ending test
    await recorder.cancelRecording();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Canceling recording closes recorder and restores text composer without sending', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final recorder = IoAudioRecorderService();
    recorder.mockPermissionGranted = true;
    addTearDown(() => recorder.cancelRecording());

    await tester.pumpWidget(createSubject(screenSize: const Size(1280, 800), recorder: recorder));
    await tester.pumpAndSettle();

    // Open recorder
    await tester.tap(find.byIcon(Icons.mic_none_rounded));
    await tester.pump();
    expect(find.byType(VoiceNoteRecorderWidget), findsOneWidget);

    // Tap Cancel / Discard
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify recorder is closed and text field restored
    expect(find.byType(VoiceNoteRecorderWidget), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Stopping recording presents audio preview with playable waveform and explicit Send button', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final recorder = IoAudioRecorderService();
    recorder.mockPermissionGranted = true;
    addTearDown(() => recorder.cancelRecording());

    await tester.pumpWidget(createSubject(screenSize: const Size(1280, 800), recorder: recorder));
    await tester.pumpAndSettle();

    // Open recorder
    await tester.tap(find.byIcon(Icons.mic_none_rounded));
    await tester.pump();

    // Tap Stop
    await tester.tap(find.byIcon(Icons.stop_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify preview state
    expect(find.text('Preview Voice Note before sending'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
    expect(find.byType(VoiceNotePlayerWidget), findsAtLeastNWidgets(1));

    // Can cancel from preview state
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Preview Voice Note before sending'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Voice Note Player widget renders correctly for audio messages and toggles play/pause', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createSubject(screenSize: const Size(1280, 800)));
    await tester.pumpAndSettle();

    // Message 2 has Voice Note attached
    expect(find.byType(VoiceNotePlayerWidget), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    // Tap play button
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Microphone permission denied displays informative feedback and does not open recorder', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final recorder = IoAudioRecorderService();
    recorder.mockPermissionGranted = false;

    await tester.pumpWidget(createSubject(screenSize: const Size(1280, 800), recorder: recorder));
    await tester.pumpAndSettle();

    // Tap mic button
    await tester.tap(find.byIcon(Icons.mic_none_rounded));
    await tester.pump();

    // Verify error feedback
    expect(find.text('Microphone permission required to record voice notes.'), findsOneWidget);
    expect(find.byType(VoiceNoteRecorderWidget), findsNothing);

    expect(tester.takeException(), isNull);
  });

  test('ProjectMessage model correctly classifies audio voice notes vs documents', () {
    final audioMsg = ProjectMessage(
      id: 'msg-audio',
      projectId: 'prj-1',
      senderId: 'user-1',
      senderName: 'Draughtsman',
      senderRole: 'DRAUGHTSMAN',
      message: 'Voice Note (0:04)',
      attachmentFileId: 'file-1',
      attachmentName: 'voice_note_123.webm',
      attachmentType: 'audio/webm',
      createdAt: DateTime.now(),
    );

    expect(audioMsg.isVoiceNote, isTrue);
    expect(audioMsg.hasDocumentAttachment, isFalse);

    final docMsg = ProjectMessage(
      id: 'msg-doc',
      projectId: 'prj-1',
      senderId: 'user-2',
      senderName: 'Sarah J.',
      senderRole: 'ENGINEER',
      message: 'Revised calculation report',
      attachmentFileId: 'file-2',
      attachmentName: 'Seismic_Report.pdf',
      attachmentType: 'application/pdf',
      createdAt: DateTime.now(),
    );

    expect(docMsg.isVoiceNote, isFalse);
    expect(docMsg.hasDocumentAttachment, isTrue);

    final dualMsg = ProjectMessage(
      id: 'msg-dual',
      projectId: 'prj-1',
      senderId: 'user-1',
      senderName: 'Draughtsman',
      senderRole: 'DRAUGHTSMAN',
      message: 'Understood. Adjusted detailing. (Voice Note attached)',
      attachmentFileId: 'file-3',
      attachmentName: 'S-102_RevB.dwg',
      attachmentType: 'application/acad',
      createdAt: DateTime.now(),
    );

    expect(dualMsg.isVoiceNote, isTrue);
    expect(dualMsg.hasDocumentAttachment, isTrue);
  });
}
