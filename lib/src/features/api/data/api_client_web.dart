// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'package:http/http.dart' as http;
import 'dart:html' as html;

Future<void> saveFileStream(http.ByteStream stream, String savePath) async {
  // Read into memory on web, convert to blob, and trigger download
  final bytes = await stream.toBytes();
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  html.AnchorElement(href: url)
    ..setAttribute("download", savePath)
    ..click();
    
  html.Url.revokeObjectUrl(url);
}
