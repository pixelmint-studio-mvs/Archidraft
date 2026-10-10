import 'dart:async';
import 'package:flutter/foundation.dart';

enum AppPlayerState {
  stopped,
  playing,
  paused,
  completed,
}

abstract class AppAudioPlayer {
  Future<void> setSourceBytes(Uint8List bytes, String mimeType);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);
  Future<void> dispose();

  Stream<Duration> get onPositionChanged;
  Stream<Duration> get onDurationChanged;
  Stream<AppPlayerState> get onPlayerStateChanged;

  AppPlayerState get playerState;
  Duration get position;
  Duration get duration;
}
