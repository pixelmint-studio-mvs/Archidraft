import 'dart:typed_data';
import 'file_bytes_reader_io.dart'
    if (dart.library.html) 'file_bytes_reader_web.dart' as impl;

Future<Uint8List> readFileBytes(String path) => impl.readFileBytes(path);
