import 'dart:async';
import 'dart:typed_data';
import 'audio_service.dart';

AudioRecorderService createAudioRecorder() => IoAudioRecorderService();
AudioPlayerService createAudioPlayer() => IoAudioPlayerService();

class IoAudioRecorderService implements AudioRecorderService {
  RecordingState _state = RecordingState.idle;
  Duration _duration = Duration.zero;
  double _amplitude = 0.0;
  Timer? _timer;

  final _stateController = StreamController<RecordingState>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _amplitudeController = StreamController<double>.broadcast();

  bool mockPermissionGranted = true;
  bool mockUnsupported = false;

  @override
  RecordingState get state => _state;

  @override
  Stream<RecordingState> get stateStream => _stateController.stream;

  @override
  Duration get duration => _duration;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  double get amplitude => _amplitude;

  @override
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  @override
  Future<bool> hasPermission() async {
    return mockPermissionGranted;
  }

  @override
  Future<void> startRecording() async {
    if (mockUnsupported) {
      _setState(RecordingState.unsupported);
      return;
    }
    if (!mockPermissionGranted) {
      _setState(RecordingState.permissionDenied);
      return;
    }

    _duration = Duration.zero;
    _setState(RecordingState.recording);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      _duration += const Duration(milliseconds: 100);
      if (!_durationController.isClosed) {
        _durationController.add(_duration);
      }
      _amplitude = 0.5;
      if (!_amplitudeController.isClosed) {
        _amplitudeController.add(_amplitude);
      }
    });
  }

  @override
  Future<RecordedAudio?> stopRecording() async {
    _timer?.cancel();
    _setState(RecordingState.stopped);
    // Return sample audio bytes for testing
    return RecordedAudio(
      bytes: Uint8List.fromList([0x1A, 0x45, 0xDF, 0xA3, 0x01, 0x02, 0x03]),
      mimeType: 'audio/webm',
      fileExtension: 'webm',
      duration: _duration > Duration.zero ? _duration : const Duration(seconds: 4),
    );
  }

  @override
  Future<void> cancelRecording() async {
    _timer?.cancel();
    _duration = Duration.zero;
    _setState(RecordingState.idle);
  }

  void _setState(RecordingState s) {
    _state = s;
    if (!_stateController.isClosed) {
      _stateController.add(s);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stateController.close();
    _durationController.close();
    _amplitudeController.close();
  }
}

class IoAudioPlayerService implements AudioPlayerService {
  PlaybackState _state = PlaybackState.idle;
  Duration _position = Duration.zero;
  final Duration _duration = const Duration(seconds: 12);
  String? _errorMessage;
  Timer? _progressTimer;

  final _stateController = StreamController<PlaybackState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();

  @override
  PlaybackState get state => _state;

  @override
  Stream<PlaybackState> get stateStream => _stateController.stream;

  @override
  Duration get position => _position;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Duration get duration => _duration;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  String? get errorMessage => _errorMessage;

  @override
  Future<void> loadFromBytes(Uint8List bytes, {String mimeType = 'audio/webm'}) async {
    _setState(PlaybackState.loading);
    await Future.delayed(const Duration(milliseconds: 50));
    _position = Duration.zero;
    _setState(PlaybackState.idle);
  }

  @override
  Future<void> loadFromUrl(String url) async {
    _setState(PlaybackState.loading);
    await Future.delayed(const Duration(milliseconds: 50));
    _position = Duration.zero;
    _setState(PlaybackState.idle);
  }

  @override
  Future<void> play() async {
    _setState(PlaybackState.playing);
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      if (_position < _duration) {
        _position += const Duration(milliseconds: 200);
        if (!_positionController.isClosed) {
          _positionController.add(_position);
        }
      } else {
        _progressTimer?.cancel();
        _setState(PlaybackState.completed);
      }
    });
  }

  @override
  Future<void> pause() async {
    _progressTimer?.cancel();
    _setState(PlaybackState.paused);
  }

  @override
  Future<void> seek(Duration position) async {
    _position = position;
    if (!_positionController.isClosed) {
      _positionController.add(_position);
    }
  }

  @override
  Future<void> stop() async {
    _progressTimer?.cancel();
    _position = Duration.zero;
    _setState(PlaybackState.idle);
  }

  void _setState(PlaybackState s) {
    _state = s;
    if (!_stateController.isClosed) {
      _stateController.add(s);
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _stateController.close();
    _positionController.close();
    _durationController.close();
  }
}
