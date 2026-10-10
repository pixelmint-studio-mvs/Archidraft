// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

Source createAudioSource(Uint8List bytes, String mimeType, {void Function(String url)? onUrlCreated}) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  onUrlCreated?.call(url);
  return UrlSource(url);
}

void releaseAudioUrl(String? url) {
  if (url != null && url.startsWith('blob:')) {
    html.Url.revokeObjectUrl(url);
  }
}
