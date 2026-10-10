import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'app_audio_player_interface.dart';

class IoAppAudioPlayer implements AppAudioPlayer {
  final ap.AudioPlayer _player = ap.AudioPlayer();

  final StreamController<Duration> _positionCtrl = StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationCtrl = StreamController<Duration>.broadcast();
  final StreamController<AppPlayerState> _stateCtrl = StreamController<AppPlayerState>.broadcast();

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;

  AppPlayerState _state = AppPlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  IoAppAudioPlayer() {
    _posSub = _player.onPositionChanged.listen((p) {
      _position = p;
      _positionCtrl.add(p);
    });

    _durSub = _player.onDurationChanged.listen((d) {
      _duration = d;
      _durationCtrl.add(d);
    });

    _stateSub = _player.onPlayerStateChanged.listen((s) {
      switch (s) {
        case ap.PlayerState.playing:
          _state = AppPlayerState.playing;
          break;
        case ap.PlayerState.paused:
          _state = AppPlayerState.paused;
          break;
        case ap.PlayerState.completed:
          _state = AppPlayerState.completed;
          _position = Duration.zero;
          _positionCtrl.add(Duration.zero);
          break;
        case ap.PlayerState.stopped:
        case ap.PlayerState.disposed:
          _state = AppPlayerState.stopped;
          break;
      }
      _stateCtrl.add(_state);
    });
  }

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

  @override
  Future<void> setSourceBytes(Uint8List bytes, String mimeType) async {
    await _player.setSource(ap.BytesSource(bytes, mimeType: mimeType));
  }

  @override
  Future<void> play() async {
    await _player.resume();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setPlaybackRate(speed);
  }

  @override
  Future<void> dispose() async {
    await _posSub?.cancel();
    await _durSub?.cancel();
    await _stateSub?.cancel();
    await _player.dispose();
    await _positionCtrl.close();
    await _durationCtrl.close();
    await _stateCtrl.close();
  }
}

AppAudioPlayer createPlatformAudioPlayer() => IoAppAudioPlayer();
