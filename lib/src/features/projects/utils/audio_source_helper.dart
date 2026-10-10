import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

import 'audio_source_helper_io.dart'
    if (dart.library.html) 'audio_source_helper_web.dart' as impl;

Source createAudioSource(
  Uint8List bytes,
  String mimeType, {
  void Function(String url)? onUrlCreated,
}) {
  return impl.createAudioSource(bytes, mimeType, onUrlCreated: onUrlCreated);
}

void releaseAudioUrl(String? url) {
  impl.releaseAudioUrl(url);
}
