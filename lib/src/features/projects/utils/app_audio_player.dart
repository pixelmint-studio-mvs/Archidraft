export 'app_audio_player_interface.dart';

import 'app_audio_player_interface.dart';
import 'app_audio_player_io.dart'
    if (dart.library.html) 'app_audio_player_web.dart' as impl;

AppAudioPlayer createAppAudioPlayer() => impl.createPlatformAudioPlayer();
