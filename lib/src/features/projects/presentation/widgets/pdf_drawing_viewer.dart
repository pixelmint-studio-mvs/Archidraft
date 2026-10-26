import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'pdf_drawing_viewer_stub.dart'
    if (dart.library.ui_web) 'pdf_drawing_viewer_web.dart';

class PdfDrawingViewer extends StatelessWidget {
  final Uint8List bytes;
  final String fileName;
  final String fileId;
  final VoidCallback? onDownload;

  const PdfDrawingViewer({
    super.key,
    required this.bytes,
    required this.fileName,
    required this.fileId,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return buildPlatformPdfViewer(
      bytes: bytes,
      fileName: fileName,
      fileId: fileId,
      onDownload: onDownload,
    );
  }
}
