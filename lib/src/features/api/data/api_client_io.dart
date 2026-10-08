import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> saveFileStream(
  http.ByteStream stream,
  String savePath, {
  bool openInBrowser = false,
}) async {
  final file = File(savePath);
  if (!file.parent.existsSync()) {
    await file.parent.create(recursive: true);
  }
  final sink = file.openWrite(mode: FileMode.writeOnly);
  await stream.pipe(sink);
  await sink.flush();
  await sink.close();
}
