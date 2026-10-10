import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/projects/data/file_repository.dart';
import 'package:archi_draft/src/features/projects/data/message_repository.dart';
import 'package:archi_draft/src/features/projects/data/voice_recorder_service.dart';
import 'package:archi_draft/src/features/projects/domain/project_file.dart';
import 'package:archi_draft/src/features/projects/domain/project_message.dart';
import 'package:archi_draft/src/features/projects/providers/voice_recording_controller.dart';

class FakeVoiceRecorderService implements VoiceRecorderService {
  MicrophonePermissionResult permissionResult = MicrophonePermissionResult.granted;
  bool isRecording = false;
  VoiceRecordingResult? recordingToReturn;
  bool throwOnStart = false;

  @override
  Future<MicrophonePermissionResult> checkAndRequestPermission() async => permissionResult;

  @override
  Future<bool> hasPermission() async =>
      permissionResult == MicrophonePermissionResult.granted;

  @override
  Future<void> startRecording() async {
    if (throwOnStart) throw Exception('Recorder initialization failed');
    isRecording = true;
  }

  @override
  Future<VoiceRecordingResult?> stopRecording(Duration elapsedDuration) async {
    isRecording = false;
    return recordingToReturn;
  }

  @override
  Future<void> cancelRecording() async {
    isRecording = false;
  }

  @override
  Future<void> dispose() async {}
}

class FakeFileRepository extends Fake implements FileRepository {
  bool uploadShouldFail = false;
  ProjectFile? lastUploadedFile;
  String? lastCategory;

  @override
  Future<ProjectFile> uploadFile({
    required String projectId,
    required String category,
    required String fileName,
    required String contentType,
    required Stream<List<int>> stream,
    required int length,
    required String actionId,
  }) async {
    if (uploadShouldFail) throw Exception('Network upload failed');
    lastCategory = category;
    final file = ProjectFile(
      id: actionId,
      projectId: projectId,
      uploadedBy: 'engineer-uid',
      originalName: fileName,
      sanitizedName: fileName,
      objectKey: 'projects/$projectId/chat_attachment/$fileName',
      contentType: contentType,
      size: length,
      category: category,
      status: 'COMPLETED',
      createdAt: DateTime.now(),
    );
    lastUploadedFile = file;
    return file;
  }
}

class FakeMessageRepository extends Fake implements MessageRepository {
  ProjectMessage? lastSentMessage;

  @override
  Future<ProjectMessage> sendMessage({
    required String projectId,
    required String message,
    String? attachmentFileId,
  }) async {
    final msg = ProjectMessage(
      id: 'sent-msg-id',
      projectId: projectId,
      senderId: 'engineer-uid',
      senderName: 'Test Engineer',
      senderRole: 'ENGINEER',
      message: message,
      attachmentFileId: attachmentFileId,
      createdAt: DateTime.now(),
    );
    lastSentMessage = msg;
    return msg;
  }
}

void main() {
  group('VoiceRecordingController Tests', () {
    late FakeVoiceRecorderService fakeRecorder;
    late FakeFileRepository fakeFileRepo;
    late FakeMessageRepository fakeMessageRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRecorder = FakeVoiceRecorderService();
      fakeFileRepo = FakeFileRepository();
      fakeMessageRepo = FakeMessageRepository();

      container = ProviderContainer(
        overrides: [
          voiceRecorderServiceProvider.overrideWithValue(fakeRecorder),
          fileRepositoryProvider.overrideWithValue(fakeFileRepo),
          messageRepositoryProvider.overrideWithValue(fakeMessageRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is idle', () {
      final state = container.read(voiceRecordingControllerProvider);
      expect(state.isIdle, isTrue);
      expect(state.isRecording, isFalse);
      expect(state.isRecorded, isFalse);
      expect(state.isUploading, isFalse);
    });

    test('startRecording transitions to recording state when permission is granted', () async {
      final controller = container.read(voiceRecordingControllerProvider.notifier);
      final ok = await controller.startRecording();

      expect(ok, isTrue);
      expect(fakeRecorder.isRecording, isTrue);

      final state = container.read(voiceRecordingControllerProvider);
      expect(state.isRecording, isTrue);
      expect(state.status, VoiceRecordingStatus.recording);
    });

    test('startRecording transitions to failure when permission is denied', () async {
      fakeRecorder.permissionResult = MicrophonePermissionResult.denied;
      final controller = container.read(voiceRecordingControllerProvider.notifier);
      final ok = await controller.startRecording();

      expect(ok, isFalse);
      expect(fakeRecorder.isRecording, isFalse);

      final state = container.read(voiceRecordingControllerProvider);
      expect(state.hasFailure, isTrue);
      expect(state.isPermissionDenied, isTrue);
      expect(state.errorMessage, contains('permission denied'));
    });

    test('startRecording transitions to blocked state when permission is permanently denied', () async {
      fakeRecorder.permissionResult = MicrophonePermissionResult.permanentlyDenied;
      final controller = container.read(voiceRecordingControllerProvider.notifier);
      final ok = await controller.startRecording();

      expect(ok, isFalse);
      final state = container.read(voiceRecordingControllerProvider);
      expect(state.hasFailure, isTrue);
      expect(state.isBlocked, isTrue);
      expect(state.errorMessage, contains('blocked'));
    });

    test('startRecording transitions to unavailable state when microphone is missing', () async {
      fakeRecorder.permissionResult = MicrophonePermissionResult.unavailable;
      final controller = container.read(voiceRecordingControllerProvider.notifier);
      final ok = await controller.startRecording();

      expect(ok, isFalse);
      final state = container.read(voiceRecordingControllerProvider);
      expect(state.hasFailure, isTrue);
      expect(state.errorType, VoiceErrorType.micUnavailable);
      expect(state.errorMessage, contains('No microphone found'));
    });

    test('clearFailure resets error and retry after permission grant succeeds', () async {
      fakeRecorder.permissionResult = MicrophonePermissionResult.denied;
      final controller = container.read(voiceRecordingControllerProvider.notifier);
      await controller.startRecording();
      expect(container.read(voiceRecordingControllerProvider).hasFailure, isTrue);

      controller.clearFailure();
      expect(container.read(voiceRecordingControllerProvider).isIdle, isTrue);

      // Now grant permission
      fakeRecorder.permissionResult = MicrophonePermissionResult.granted;
      final ok = await controller.startRecording();
      expect(ok, isTrue);
      expect(container.read(voiceRecordingControllerProvider).isRecording, isTrue);
    });

    test('startRecording handles recorder initialization exception', () async {
      fakeRecorder.throwOnStart = true;
      final controller = container.read(voiceRecordingControllerProvider.notifier);
      final success = await controller.startRecording();

      expect(success, isFalse);
      final state = container.read(voiceRecordingControllerProvider);
      expect(state.hasFailure, isTrue);
      expect(state.errorType, VoiceErrorType.initFailed);
      expect(state.errorMessage, contains('Failed to start recording'));
    });

    test('startRecording prevents double starts while already recording', () async {
      final controller = container.read(voiceRecordingControllerProvider.notifier);
      await controller.startRecording();
      final secondTry = await controller.startRecording();

      expect(secondTry, isFalse);
    });

    test('stopRecording transitions to recorded state with audio result', () async {
      final controller = container.read(voiceRecordingControllerProvider.notifier);
      await controller.startRecording();

      final fakeBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      fakeRecorder.recordingToReturn = VoiceRecordingResult(
        bytes: fakeBytes,
        path: 'blob:http://localhost:8787/test-audio',
        extension: 'webm',
        contentType: 'audio/webm',
        duration: const Duration(seconds: 4),
      );

      await controller.stopRecording();

      final state = container.read(voiceRecordingControllerProvider);
      expect(state.isRecorded, isTrue);
      expect(state.status, VoiceRecordingStatus.recorded);
      expect(state.result, isNotNull);
      expect(state.result!.bytes, fakeBytes);
      expect(state.result!.extension, 'webm');
      expect(state.result!.contentType, 'audio/webm');
    });

    test('stopRecording handles empty audio with failure state', () async {
      final controller = container.read(voiceRecordingControllerProvider.notifier);
      await controller.startRecording();

      fakeRecorder.recordingToReturn = null;
      await controller.stopRecording();

      final state = container.read(voiceRecordingControllerProvider);
      expect(state.hasFailure, isTrue);
      expect(state.errorMessage, contains('No audio recorded'));
    });

    test('cancelOrDiscard resets state to idle', () async {
      final controller = container.read(voiceRecordingControllerProvider.notifier);
      await controller.startRecording();
      await controller.cancelOrDiscard();

      final state = container.read(voiceRecordingControllerProvider);
      expect(state.isIdle, isTrue);
      expect(fakeRecorder.isRecording, isFalse);
    });

    test('sendVoiceMessage uploads audio and creates project message with attachment', () async {
      final controller = container.read(voiceRecordingControllerProvider.notifier);
      await controller.startRecording();

      final fakeBytes = Uint8List.fromList([10, 20, 30, 40]);
      fakeRecorder.recordingToReturn = VoiceRecordingResult(
        bytes: fakeBytes,
        path: 'blob:http://localhost:8787/rec',
        extension: 'webm',
        contentType: 'audio/webm',
        duration: const Duration(seconds: 3),
      );
      await controller.stopRecording();

      final success = await controller.sendVoiceMessage('test-project-id');
      expect(success, isTrue);

      // Verify file upload parameters
      expect(fakeFileRepo.lastCategory, 'chat_attachment');
      expect(fakeFileRepo.lastUploadedFile, isNotNull);
      expect(fakeFileRepo.lastUploadedFile!.contentType, 'audio/webm');
      expect(fakeFileRepo.lastUploadedFile!.size, 4);

      // Verify message parameters (no text, attachment linked)
      expect(fakeMessageRepo.lastSentMessage, isNotNull);
      expect(fakeMessageRepo.lastSentMessage!.message, isEmpty);
      expect(fakeMessageRepo.lastSentMessage!.attachmentFileId, fakeFileRepo.lastUploadedFile!.id);

      // State is reset to idle
      final state = container.read(voiceRecordingControllerProvider);
      expect(state.isIdle, isTrue);
    });

    test('sendVoiceMessage failure preserves recording for retry', () async {
      fakeFileRepo.uploadShouldFail = true;

      final controller = container.read(voiceRecordingControllerProvider.notifier);
      await controller.startRecording();

      final fakeBytes = Uint8List.fromList([1, 2, 3]);
      fakeRecorder.recordingToReturn = VoiceRecordingResult(
        bytes: fakeBytes,
        path: 'blob:http://localhost:8787/rec',
        extension: 'webm',
        contentType: 'audio/webm',
        duration: const Duration(seconds: 2),
      );
      await controller.stopRecording();

      final success = await controller.sendVoiceMessage('test-project-id');
      expect(success, isFalse);

      final state = container.read(voiceRecordingControllerProvider);
      expect(state.hasFailure, isTrue);
      expect(state.errorMessage, contains('Failed to send voice message'));
      // The recording bytes must be preserved for retry!
      expect(state.result, isNotNull);
      expect(state.result!.bytes, fakeBytes);

      // Now retry with network fixed
      fakeFileRepo.uploadShouldFail = false;
      final retrySuccess = await controller.sendVoiceMessage('test-project-id');
      expect(retrySuccess, isTrue);

      final finalState = container.read(voiceRecordingControllerProvider);
      expect(finalState.isIdle, isTrue);
    });
  });
}
