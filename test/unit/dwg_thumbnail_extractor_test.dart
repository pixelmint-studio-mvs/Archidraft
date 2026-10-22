import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

Uint8List? extractDwgThumbnail(Uint8List bytes) {
  if (bytes.length < 100) return null;

  final headerStr = String.fromCharCodes(bytes.sublist(0, 4));
  if (headerStr != 'AC10' && headerStr != 'AC1.' && headerStr != 'AC15') {
    return null;
  }

  final maxScan = math.min(bytes.length - 40, 100000);
  for (int i = 0; i < maxScan; i++) {
    if (bytes[i] == 0x28 && bytes[i + 1] == 0x00 && bytes[i + 2] == 0x00 && bytes[i + 3] == 0x00) {
      final byteData = ByteData.sublistView(bytes, i);
      final biWidth = byteData.getInt32(4, Endian.little);
      final biHeight = byteData.getInt32(8, Endian.little);
      final biPlanes = byteData.getInt16(12, Endian.little);
      final biBitCount = byteData.getInt16(14, Endian.little);
      final biCompression = byteData.getInt32(16, Endian.little);

      if (biWidth >= 32 &&
          biWidth <= 4096 &&
          biHeight.abs() >= 32 &&
          biHeight.abs() <= 4096 &&
          biPlanes == 1 &&
          (biBitCount == 8 || biBitCount == 24 || biBitCount == 32) &&
          biCompression == 0) {
        final paletteColors = (biBitCount <= 8) ? (1 << biBitCount) : 0;
        final paletteSize = paletteColors * 4;
        final rowSize = ((biBitCount * biWidth + 31) ~/ 32) * 4;
        final imageSize = rowSize * biHeight.abs();
        final dibTotalSize = 40 + paletteSize + imageSize;

        if (i + dibTotalSize <= bytes.length) {
          final bmpBytes = Uint8List(14 + dibTotalSize);
          final bfh = ByteData.sublistView(bmpBytes, 0, 14);
          bfh.setUint8(0, 0x42); // 'B'
          bfh.setUint8(1, 0x4D); // 'M'
          bfh.setUint32(2, 14 + dibTotalSize, Endian.little);
          bfh.setUint16(6, 0, Endian.little);
          bfh.setUint16(8, 0, Endian.little);
          bfh.setUint32(10, 14 + 40 + paletteSize, Endian.little);

          bmpBytes.setRange(14, 14 + dibTotalSize, bytes.sublist(i, i + dibTotalSize));
          return bmpBytes;
        }
      }
    }
  }
  return null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Extracts valid BMP thumbnail from real AutoCAD AC1021 DWG file and decodes with Flutter engine', () async {
    final dwgFile = File('assets/images/architectural_-_annotation_scaling_and_multileaders.dwg');
    expect(dwgFile.existsSync(), isTrue);

    final bytes = dwgFile.readAsBytesSync();
    expect(bytes.length, equals(188992));

    final bmpBytes = extractDwgThumbnail(bytes);
    expect(bmpBytes, isNotNull);
    expect(bmpBytes!.length, equals(42806));

    // Verify BMP decodes cleanly in Flutter engine image codec
    final codec = await ui.instantiateImageCodec(bmpBytes);
    final frame = await codec.getNextFrame();
    expect(frame.image.width, equals(256));
    expect(frame.image.height, equals(163));
  });
}
