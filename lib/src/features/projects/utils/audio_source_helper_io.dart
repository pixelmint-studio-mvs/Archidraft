import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

Source createAudioSource(Uint8List bytes, String mimeType, {void Function(String url)? onUrlCreated}) {
  return BytesSource(bytes, mimeType: mimeType);
}

void releaseAudioUrl(String? url) {
  // No-op on IO / non-web platforms
}
