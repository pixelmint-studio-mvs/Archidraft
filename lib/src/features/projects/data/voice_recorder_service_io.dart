import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../utils/file_bytes_reader.dart';
import 'voice_recorder_service_interface.dart';

export 'voice_recorder_service_interface.dart';

class IOVoiceRecorderService implements VoiceRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String _currentExt = 'm4a';
  String _currentContentType = 'audio/mp4';

  @override
  Future<MicrophonePermissionResult> checkAndRequestPermission() async {
    try {
      final hasPerm = await _recorder.hasPermission();
      if (hasPerm) {
        return MicrophonePermissionResult.granted;
      } else {
        return MicrophonePermissionResult.denied;
      }
    } catch (e) {
      debugPrint('IO microphone permission check error: $e');
      return MicrophonePermissionResult.denied;
    }
  }

  @override
  Future<bool> hasPermission() async {
    final res = await checkAndRequestPermission();
    return res == MicrophonePermissionResult.granted;
  }

  @override
  Future<void> startRecording() async {
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _currentExt = 'm4a';
    _currentContentType = 'audio/mp4';

    const config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      bitRate: 128000,
      sampleRate: 44100,
    );
    await _recorder.start(config, path: filePath);
  }

  @override
  Future<VoiceRecordingResult?> stopRecording(Duration elapsedDuration) async {
    final path = await _recorder.stop();
    if (path == null || path.isEmpty) {
      return null;
    }

    final bytes = await readFileBytes(path);
    if (bytes.isEmpty) {
      return null;
    }

    return VoiceRecordingResult(
      bytes: bytes,
      path: path,
      extension: _currentExt,
      contentType: _currentContentType,
      duration: elapsedDuration,
    );
  }

  @override
  Future<void> cancelRecording() async {
    try {
      await _recorder.cancel();
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    try {
      await _recorder.dispose();
    } catch (_) {}
  }
}

VoiceRecorderService createPlatformVoiceRecorderService() => IOVoiceRecorderService();
