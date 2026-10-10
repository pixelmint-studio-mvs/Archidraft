import 'dart:typed_data';

enum MicrophonePermissionResult {
  granted,
  denied,
  permanentlyDenied,
  unavailable,
}

class VoiceRecordingResult {
  final Uint8List bytes;
  final String path;
  final String extension;
  final String contentType;
  final Duration duration;

  VoiceRecordingResult({
    required this.bytes,
    required this.path,
    required this.extension,
    required this.contentType,
    required this.duration,
  });
}

abstract class VoiceRecorderService {
  Future<MicrophonePermissionResult> checkAndRequestPermission() async {
    final hasPerm = await hasPermission();
    return hasPerm ? MicrophonePermissionResult.granted : MicrophonePermissionResult.denied;
  }

  Future<bool> hasPermission();
  Future<void> startRecording();
  Future<VoiceRecordingResult?> stopRecording(Duration elapsedDuration);
  Future<void> cancelRecording();
  Future<void> dispose();
}
