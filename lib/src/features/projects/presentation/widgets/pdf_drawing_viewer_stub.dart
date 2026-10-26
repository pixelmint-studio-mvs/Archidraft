import 'dart:typed_data';
import 'package:flutter/material.dart';

Widget buildPlatformPdfViewer({
  required Uint8List bytes,
  required String fileName,
  required String fileId,
  VoidCallback? onDownload,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.picture_as_pdf_rounded, size: 64, color: Color(0xFF00E5FF)),
          const SizedBox(height: 16),
          Text(
            fileName,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${(bytes.length / 1024).toStringAsFixed(1)} KB • PDF Architectural Document',
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
          ),
          if (onDownload != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Download PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: const Color(0xFF07111E),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
