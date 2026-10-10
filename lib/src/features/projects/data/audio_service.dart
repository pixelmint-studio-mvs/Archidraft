import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_service_io.dart'
    if (dart.library.html) 'audio_service_web.dart' as platform_audio;

enum RecordingState {
  idle,
  recording,
  stopped,
  permissionDenied,
  unsupported,
  error,
}

enum PlaybackState {
  idle,
  loading,
  playing,
  paused,
  completed,
  error,
}

class RecordedAudio {
  final Uint8List bytes;
  final String mimeType;
  final String fileExtension;
  final Duration duration;
  final String? previewUrl;

  const RecordedAudio({
    required this.bytes,
    required this.mimeType,
    required this.fileExtension,
    required this.duration,
    this.previewUrl,
  });
}

abstract class AudioRecorderService {
  RecordingState get state;
  Stream<RecordingState> get stateStream;
  Duration get duration;
  Stream<Duration> get durationStream;
  double get amplitude; // Normalized 0.0 to 1.0
  Stream<double> get amplitudeStream;

  Future<bool> hasPermission();
  Future<void> startRecording();
  Future<RecordedAudio?> stopRecording();
  Future<void> cancelRecording();
  void dispose();
}

abstract class AudioPlayerService {
  PlaybackState get state;
  Stream<PlaybackState> get stateStream;
  Duration get position;
  Stream<Duration> get positionStream;
  Duration get duration;
  Stream<Duration> get durationStream;
  String? get errorMessage;

  Future<void> loadFromBytes(Uint8List bytes, {String mimeType = 'audio/webm'});
  Future<void> loadFromUrl(String url);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> stop();
  void dispose();
}

AudioRecorderService createPlatformRecorder() => platform_audio.createAudioRecorder();
AudioPlayerService createPlatformPlayer() => platform_audio.createAudioPlayer();

final audioRecorderProvider = Provider<AudioRecorderService>((ref) {
  final recorder = createPlatformRecorder();
  ref.onDispose(() => recorder.dispose());
  return recorder;
});

/// Shared notifier tracking which voice note is currently actively playing
class ActiveAudioIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setActive(String? id) => state = id;
}

final activeAudioIdProvider = NotifierProvider<ActiveAudioIdNotifier, String?>(
  ActiveAudioIdNotifier.new,
);
