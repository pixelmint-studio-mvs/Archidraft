// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

final Map<String, String> _registeredPdfBlobUrls = {};

Widget buildPlatformPdfViewer({
  required Uint8List bytes,
  required String fileName,
  required String fileId,
  VoidCallback? onDownload,
}) {
  final viewType = 'archi-draft-pdf-viewer-$fileId';

  if (!_registeredPdfBlobUrls.containsKey(viewType)) {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    _registeredPdfBlobUrls[viewType] = url;

    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = '$url#toolbar=1&navpanes=1&scrollbar=1&view=FitH'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = '#07111E';
        return iframe;
      },
    );
  }

  return HtmlElementView(viewType: viewType);
}
