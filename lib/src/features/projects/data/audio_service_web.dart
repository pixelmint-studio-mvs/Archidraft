// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'audio_service.dart';

AudioRecorderService createAudioRecorder() => WebAudioRecorderService();
AudioPlayerService createAudioPlayer() => WebAudioPlayerService();

class WebAudioRecorderService implements AudioRecorderService {
  RecordingState _state = RecordingState.idle;
  Duration _duration = Duration.zero;
  double _amplitude = 0.0;

  Timer? _timer;
  html.MediaStream? _mediaStream;
  html.MediaRecorder? _mediaRecorder;
  final List<html.Blob> _chunks = [];
  String _selectedMime = 'audio/webm';
  String _fileExtension = 'webm';

  final _stateController = StreamController<RecordingState>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _amplitudeController = StreamController<double>.broadcast();

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
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> startRecording() async {
    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) {
      _setState(RecordingState.unsupported);
      return;
    }

    try {
      final stream = await mediaDevices.getUserMedia({'audio': true});
      _mediaStream = stream;

      // Determine best audio mime type supported by this browser
      if (html.MediaRecorder.isTypeSupported('audio/webm;codecs=opus')) {
        _selectedMime = 'audio/webm;codecs=opus';
        _fileExtension = 'webm';
      } else if (html.MediaRecorder.isTypeSupported('audio/webm')) {
        _selectedMime = 'audio/webm';
        _fileExtension = 'webm';
      } else if (html.MediaRecorder.isTypeSupported('audio/mp4')) {
        _selectedMime = 'audio/mp4';
        _fileExtension = 'm4a';
      } else if (html.MediaRecorder.isTypeSupported('audio/ogg')) {
        _selectedMime = 'audio/ogg';
        _fileExtension = 'ogg';
      } else {
        _selectedMime = 'audio/webm';
        _fileExtension = 'webm';
      }

      _chunks.clear();
      _mediaRecorder = html.MediaRecorder(stream, {'mimeType': _selectedMime});
      _mediaRecorder!.addEventListener('dataavailable', (event) {
        if (event is html.BlobEvent && event.data != null && event.data!.size > 0) {
          _chunks.add(event.data!);
        }
      });

      _duration = Duration.zero;
      _mediaRecorder!.start(100); // 100ms chunks
      _setState(RecordingState.recording);

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
        _duration += const Duration(milliseconds: 100);
        if (!_durationController.isClosed) {
          _durationController.add(_duration);
        }

        // Smooth normalized dynamic amplitude waveform during recording
        final waveCycle = (_duration.inMilliseconds % 1200) / 1200.0;
        _amplitude = (0.3 + 0.5 * (waveCycle < 0.5 ? waveCycle * 2 : (1.0 - waveCycle) * 2)).clamp(0.0, 1.0);
        if (!_amplitudeController.isClosed) {
          _amplitudeController.add(_amplitude);
        }
      });
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('notallowederror') ||
          errStr.contains('permission') ||
          errStr.contains('denied')) {
        _setState(RecordingState.permissionDenied);
      } else if (errStr.contains('notfounderror') || errStr.contains('device')) {
        _setState(RecordingState.unsupported);
      } else {
        _setState(RecordingState.error);
      }
    }
  }

  @override
  Future<RecordedAudio?> stopRecording() async {
    _timer?.cancel();
    if (_mediaRecorder == null || _mediaRecorder!.state == 'inactive') {
      _cleanupStream();
      _setState(RecordingState.stopped);
      return null;
    }

    final completer = Completer<RecordedAudio?>();

    void onStopHandler(html.Event _) async {
      try {
        final blob = html.Blob(_chunks, _selectedMime);
        final reader = html.FileReader();
        reader.readAsArrayBuffer(blob);
        await reader.onLoadEnd.first;

        Uint8List bytes;
        final res = reader.result;
        if (res is ByteBuffer) {
          bytes = res.asUint8List();
        } else if (res is Uint8List) {
          bytes = res;
        } else {
          bytes = Uint8List(0);
        }

        final objectUrl = html.Url.createObjectUrlFromBlob(blob);
        final recorded = RecordedAudio(
          bytes: bytes,
          mimeType: _selectedMime.split(';').first,
          fileExtension: _fileExtension,
          duration: _duration > Duration.zero ? _duration : const Duration(seconds: 1),
          previewUrl: objectUrl,
        );

        _setState(RecordingState.stopped);
        completer.complete(recorded);
      } catch (e) {
        _setState(RecordingState.error);
        completer.completeError(e);
      } finally {
        _cleanupStream();
      }
    }

    _mediaRecorder!.addEventListener('stop', onStopHandler);
    _mediaRecorder!.stop();

    return completer.future;
  }

  @override
  Future<void> cancelRecording() async {
    _timer?.cancel();
    try {
      if (_mediaRecorder != null && _mediaRecorder!.state != 'inactive') {
        _mediaRecorder!.stop();
      }
    } catch (_) {}
    _chunks.clear();
    _cleanupStream();
    _duration = Duration.zero;
    _setState(RecordingState.idle);
  }

  void _cleanupStream() {
    if (_mediaStream != null) {
      for (final track in _mediaStream!.getTracks()) {
        track.stop();
      }
      _mediaStream = null;
    }
  }

  void _setState(RecordingState s) {
    _state = s;
    if (!_stateController.isClosed) {
      _stateController.add(s);
    }
  }

  @override
  void dispose() {
    cancelRecording();
    _stateController.close();
    _durationController.close();
    _amplitudeController.close();
  }
}

class WebAudioPlayerService implements AudioPlayerService {
  PlaybackState _state = PlaybackState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _errorMessage;
  String? _currentObjectUrl;

  final html.AudioElement _audio = html.AudioElement();

  final _stateController = StreamController<PlaybackState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();

  final List<StreamSubscription> _subscriptions = [];

  WebAudioPlayerService() {
    _setupListeners();
  }

  void _setupListeners() {
    _subscriptions.add(_audio.onCanPlay.listen((_) {
      _updateDuration();
      if (_state == PlaybackState.loading) {
        _setState(PlaybackState.idle);
      }
    }));

    _subscriptions.add(_audio.onLoadedMetadata.listen((_) {
      _updateDuration();
    }));

    _subscriptions.add(_audio.onTimeUpdate.listen((_) {
      final posMs = (_audio.currentTime * 1000).round();
      _position = Duration(milliseconds: posMs);
      if (!_positionController.isClosed) {
        _positionController.add(_position);
      }
      _updateDuration();
    }));

    _subscriptions.add(_audio.onPlay.listen((_) {
      _setState(PlaybackState.playing);
    }));

    _subscriptions.add(_audio.onPause.listen((_) {
      final cur = _audio.currentTime;
      final dur = _audio.duration;
      if (dur > 0 && cur >= dur - 0.1) {
        _setState(PlaybackState.completed);
      } else {
        _setState(PlaybackState.paused);
      }
    }));

    _subscriptions.add(_audio.onEnded.listen((_) {
      _position = _duration;
      if (!_positionController.isClosed) {
        _positionController.add(_position);
      }
      _setState(PlaybackState.completed);
    }));

    _subscriptions.add(_audio.onError.listen((_) {
      _errorMessage = 'Audio playback failed';
      _setState(PlaybackState.error);
    }));
  }

  void _updateDuration() {
    final dur = _audio.duration;
    if (!dur.isNaN && !dur.isInfinite && dur > 0) {
      _duration = Duration(milliseconds: (dur * 1000).round());
      if (!_durationController.isClosed) {
        _durationController.add(_duration);
      }
    }
  }

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
    _revokeUrl();
    try {
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      _currentObjectUrl = url;
      _audio.src = url;
      _audio.load();
    } catch (e) {
      _errorMessage = 'Failed to load audio: $e';
      _setState(PlaybackState.error);
    }
  }

  @override
  Future<void> loadFromUrl(String url) async {
    _setState(PlaybackState.loading);
    _revokeUrl();
    try {
      _audio.src = url;
      _audio.load();
    } catch (e) {
      _errorMessage = 'Failed to load audio: $e';
      _setState(PlaybackState.error);
    }
  }

  @override
  Future<void> play() async {
    try {
      if (_state == PlaybackState.completed) {
        _audio.currentTime = 0;
      }
      await _audio.play();
    } catch (e) {
      _errorMessage = 'Play request failed: $e';
      _setState(PlaybackState.error);
    }
  }

  @override
  Future<void> pause() async {
    try {
      _audio.pause();
    } catch (_) {}
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      _audio.currentTime = position.inMilliseconds / 1000.0;
      _position = position;
      _positionController.add(_position);
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    try {
      _audio.pause();
      _audio.currentTime = 0;
      _position = Duration.zero;
      _setState(PlaybackState.idle);
    } catch (_) {}
  }

  void _revokeUrl() {
    if (_currentObjectUrl != null) {
      try {
        html.Url.revokeObjectUrl(_currentObjectUrl!);
      } catch (_) {}
      _currentObjectUrl = null;
    }
  }

  void _setState(PlaybackState s) {
    _state = s;
    if (!_stateController.isClosed) {
      _stateController.add(s);
    }
  }

  @override
  void dispose() {
    stop();
    _revokeUrl();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _stateController.close();
    _positionController.close();
    _durationController.close();
  }
}
