import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the currently active audio playback ID (message ID or preview ID).
/// When another player starts, any listening player automatically pauses.
class ActiveAudioNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setActive(String? id) {
    state = id;
  }
}

final activeAudioPlayerIdProvider = NotifierProvider<ActiveAudioNotifier, String?>(
  ActiveAudioNotifier.new,
);
