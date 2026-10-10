import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

Future<Uint8List> readFileBytes(String path) async {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    final response = await http.get(Uri.parse(path));
    return response.bodyBytes;
  }
  final file = File(path);
  return await file.readAsBytes();
}
