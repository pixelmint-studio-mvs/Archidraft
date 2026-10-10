// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'app_audio_player_interface.dart';

class WebAppAudioPlayer implements AppAudioPlayer {
  html.AudioElement? _audio;
  String? _objectUrl;

  final StreamController<Duration> _positionCtrl = StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationCtrl = StreamController<Duration>.broadcast();
  final StreamController<AppPlayerState> _stateCtrl = StreamController<AppPlayerState>.broadcast();

  StreamSubscription? _timeSub;
  StreamSubscription? _durSub;
  StreamSubscription? _endedSub;
  StreamSubscription? _playSub;
  StreamSubscription? _pauseSub;

  AppPlayerState _state = AppPlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  AppPlayerState get playerState => _state;

  @override
  Duration get position => _position;

  @override
  Duration get duration => _duration;

  @override
  Stream<Duration> get onPositionChanged => _positionCtrl.stream;

  @override
  Stream<Duration> get onDurationChanged => _durationCtrl.stream;

  @override
  Stream<AppPlayerState> get onPlayerStateChanged => _stateCtrl.stream;

  void _cleanupListeners() {
    _timeSub?.cancel();
    _durSub?.cancel();
    _endedSub?.cancel();
    _playSub?.cancel();
    _pauseSub?.cancel();
  }

  @override
  Future<void> setSourceBytes(Uint8List bytes, String mimeType) async {
    _cleanupListeners();

    if (_objectUrl != null) {
      html.Url.revokeObjectUrl(_objectUrl!);
      _objectUrl = null;
    }

    final blob = html.Blob([bytes], mimeType);
    _objectUrl = html.Url.createObjectUrlFromBlob(blob);

    _audio?.pause();
    _audio = html.AudioElement()
      ..src = _objectUrl!
      ..preload = 'auto';
    _audio!.load();

    _audio!.onError.listen((_) {
      final err = _audio?.error;
      debugPrint('WebAppAudioPlayer audio error: code=${err?.code}, message=${err?.message}');
      _state = AppPlayerState.stopped;
      _stateCtrl.add(_state);
    });

    _durSub = _audio!.onDurationChange.listen((_) {
      final d = _audio?.duration;
      if (d != null && !d.isNaN && !d.isInfinite) {
        _duration = Duration(milliseconds: (d * 1000).toInt());
        _durationCtrl.add(_duration);
      }
    });

    _timeSub = _audio!.onTimeUpdate.listen((_) {
      final t = _audio?.currentTime;
      if (t != null && !t.isNaN) {
        _position = Duration(milliseconds: (t * 1000).toInt());
        _positionCtrl.add(_position);
      }
    });

    _playSub = _audio!.onPlay.listen((_) {
      _state = AppPlayerState.playing;
      _stateCtrl.add(_state);
    });

    _pauseSub = _audio!.onPause.listen((_) {
      if (_state != AppPlayerState.completed) {
        _state = AppPlayerState.paused;
        _stateCtrl.add(_state);
      }
    });

    _endedSub = _audio!.onEnded.listen((_) {
      _state = AppPlayerState.completed;
      _position = Duration.zero;
      _stateCtrl.add(_state);
      _positionCtrl.add(_position);
    });

    _state = AppPlayerState.stopped;
    _stateCtrl.add(_state);
  }

  @override
  Future<void> play() async {
    try {
      final playFuture = _audio?.play();
      if (playFuture != null) {
        await playFuture;
      }
    } catch (e) {
      debugPrint('WebAppAudioPlayer play error: $e');
      _state = AppPlayerState.stopped;
      _stateCtrl.add(_state);
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    _audio?.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    if (_audio != null) {
      _audio!.currentTime = position.inMilliseconds / 1000.0;
      _position = position;
      _positionCtrl.add(_position);
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    if (_audio != null) {
      _audio!.playbackRate = speed;
    }
  }

  @override
  Future<void> dispose() async {
    _cleanupListeners();
    _audio?.pause();
    _audio?.src = '';
    _audio = null;

    if (_objectUrl != null) {
      html.Url.revokeObjectUrl(_objectUrl!);
      _objectUrl = null;
    }

    _positionCtrl.close();
    _durationCtrl.close();
    _stateCtrl.close();
  }
}

AppAudioPlayer createPlatformAudioPlayer() => WebAppAudioPlayer();
