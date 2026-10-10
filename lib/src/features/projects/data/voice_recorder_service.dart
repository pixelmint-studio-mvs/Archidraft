import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'voice_recorder_service_io.dart'
    if (dart.library.html) 'voice_recorder_service_web.dart';

export 'voice_recorder_service_interface.dart';

final voiceRecorderServiceProvider = Provider<VoiceRecorderService>((ref) {
  final service = createPlatformVoiceRecorderService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
