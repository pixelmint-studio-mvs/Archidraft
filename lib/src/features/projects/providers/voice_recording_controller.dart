import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/file_repository.dart';
import '../data/voice_recorder_service.dart';
import 'message_providers.dart';

enum VoicePermissionStatus {
  undecided,
  requesting,
  granted,
  denied,
  permanentlyDenied,
  unavailable,
}

enum VoiceRecordingStatus {
  idle,
  requestingPermission,
  recording,
  recorded,
  uploading,
  failure,
}

enum VoiceErrorType {
  none,
  permissionDenied,
  permissionBlocked,
  micUnavailable,
  initFailed,
  emptyAudio,
  uploadFailed,
}

class VoiceRecordingState {
  final VoiceRecordingStatus status;
  final VoicePermissionStatus permissionStatus;
  final VoiceErrorType errorType;
  final Duration elapsedDuration;
  final VoiceRecordingResult? result;
  final String? errorMessage;

  const VoiceRecordingState({
    this.status = VoiceRecordingStatus.idle,
    this.permissionStatus = VoicePermissionStatus.undecided,
    this.errorType = VoiceErrorType.none,
    this.elapsedDuration = Duration.zero,
    this.result,
    this.errorMessage,
  });

  bool get isIdle => status == VoiceRecordingStatus.idle;
  bool get isRequestingPermission => status == VoiceRecordingStatus.requestingPermission;
  bool get isRecording => status == VoiceRecordingStatus.recording;
  bool get isRecorded => status == VoiceRecordingStatus.recorded;
  bool get isUploading => status == VoiceRecordingStatus.uploading;
  bool get hasFailure => status == VoiceRecordingStatus.failure;
  bool get isBlocked => errorType == VoiceErrorType.permissionBlocked;
  bool get isPermissionDenied => errorType == VoiceErrorType.permissionDenied;

  VoiceRecordingState copyWith({
    VoiceRecordingStatus? status,
    VoicePermissionStatus? permissionStatus,
    VoiceErrorType? errorType,
    Duration? elapsedDuration,
    VoiceRecordingResult? result,
    String? errorMessage,
  }) {
    return VoiceRecordingState(
      status: status ?? this.status,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      errorType: errorType ?? this.errorType,
      elapsedDuration: elapsedDuration ?? this.elapsedDuration,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class VoiceRecordingController extends Notifier<VoiceRecordingState> {
  Timer? _timer;

  @override
  VoiceRecordingState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const VoiceRecordingState();
  }

  void clearFailure() {
    if (state.hasFailure) {
      state = state.copyWith(
        status: VoiceRecordingStatus.idle,
        errorType: VoiceErrorType.none,
        errorMessage: null,
      );
    }
  }

  Future<bool> startRecording() async {
    if (state.isRecording || state.isUploading || state.isRequestingPermission) return false;

    // Transition to requestingPermission
    state = state.copyWith(
      status: VoiceRecordingStatus.requestingPermission,
      permissionStatus: VoicePermissionStatus.requesting,
      errorType: VoiceErrorType.none,
      errorMessage: null,
    );

    final service = ref.read(voiceRecorderServiceProvider);
    final permResult = await service.checkAndRequestPermission();

    switch (permResult) {
      case MicrophonePermissionResult.denied:
        state = state.copyWith(
          status: VoiceRecordingStatus.failure,
          permissionStatus: VoicePermissionStatus.denied,
          errorType: VoiceErrorType.permissionDenied,
          errorMessage: 'Microphone permission denied. Click the microphone button to try again.',
        );
        return false;

      case MicrophonePermissionResult.permanentlyDenied:
        state = state.copyWith(
          status: VoiceRecordingStatus.failure,
          permissionStatus: VoicePermissionStatus.permanentlyDenied,
          errorType: VoiceErrorType.permissionBlocked,
          errorMessage: 'Microphone access is blocked by browser settings. In Chrome, click the site settings icon (tune/lock icon in address bar), set Microphone to "Allow", then click Try Again.',
        );
        return false;

      case MicrophonePermissionResult.unavailable:
        state = state.copyWith(
          status: VoiceRecordingStatus.failure,
          permissionStatus: VoicePermissionStatus.unavailable,
          errorType: VoiceErrorType.micUnavailable,
          errorMessage: 'No microphone found. Please connect or enable an audio input device.',
        );
        return false;

      case MicrophonePermissionResult.granted:
        state = state.copyWith(
          permissionStatus: VoicePermissionStatus.granted,
        );
        break;
    }

    try {
      await service.startRecording();
      _timer?.cancel();
      state = state.copyWith(
        status: VoiceRecordingStatus.recording,
        elapsedDuration: Duration.zero,
        errorType: VoiceErrorType.none,
        errorMessage: null,
      );

      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (state.isRecording) {
          state = state.copyWith(
            elapsedDuration: Duration(seconds: t.tick),
          );
        }
      });
      return true;
    } catch (e) {
      state = state.copyWith(
        status: VoiceRecordingStatus.failure,
        errorType: VoiceErrorType.initFailed,
        errorMessage: 'Failed to start recording: $e',
      );
      return false;
    }
  }

  Future<void> stopRecording() async {
    if (!state.isRecording) return;
    _timer?.cancel();

    final service = ref.read(voiceRecorderServiceProvider);
    final elapsed = state.elapsedDuration;

    try {
      final res = await service.stopRecording(elapsed);
      if (res == null || res.bytes.isEmpty) {
        state = state.copyWith(
          status: VoiceRecordingStatus.failure,
          errorType: VoiceErrorType.emptyAudio,
          errorMessage: 'No audio recorded. Please record for at least 1 second.',
        );
        return;
      }

      state = state.copyWith(
        status: VoiceRecordingStatus.recorded,
        result: res,
        errorType: VoiceErrorType.none,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: VoiceRecordingStatus.failure,
        errorType: VoiceErrorType.initFailed,
        errorMessage: 'Failed to stop recording: $e',
      );
    }
  }

  Future<void> cancelOrDiscard() async {
    _timer?.cancel();
    final service = ref.read(voiceRecorderServiceProvider);
    await service.cancelRecording();
    state = const VoiceRecordingState(status: VoiceRecordingStatus.idle);
  }

  Future<bool> sendVoiceMessage(String projectId) async {
    final recording = state.result;
    if (recording == null || state.isUploading) return false;

    state = state.copyWith(
      status: VoiceRecordingStatus.uploading,
      errorMessage: null,
    );

    try {
      final actionId = const Uuid().v4();
      final ext = recording.extension;
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final contentType = recording.contentType;

      final fileRepo = ref.read(fileRepositoryProvider);
      final uploadedFile = await fileRepo.uploadFile(
        projectId: projectId,
        category: 'chat_attachment',
        fileName: fileName,
        contentType: contentType,
        stream: Stream.value(recording.bytes),
        length: recording.bytes.length,
        actionId: actionId,
      );

      final messageSender = ref.read(messageSenderControllerProvider.notifier);
      await messageSender.sendMessage(
        projectId: projectId,
        text: '',
        attachmentFileId: uploadedFile.id,
      );

      // Invalidate project messages
      ref.invalidate(projectMessagesProvider(projectId));

      // Reset recording state
      state = const VoiceRecordingState(status: VoiceRecordingStatus.idle);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: VoiceRecordingStatus.failure,
        errorType: VoiceErrorType.uploadFailed,
        errorMessage: 'Failed to send voice message: $e',
      );
      return false;
    }
  }
}

final voiceRecordingControllerProvider =
    NotifierProvider<VoiceRecordingController, VoiceRecordingState>(
  VoiceRecordingController.new,
);
