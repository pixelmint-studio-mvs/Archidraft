// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'package:http/http.dart' as http;
import 'dart:html' as html;

Future<void> saveFileStream(
  http.ByteStream stream,
  String savePath, {
  bool openInBrowser = false,
  String? contentType,
}) async {
  // Read into memory on web
  final bytes = await stream.toBytes();

  // Resolve MIME type from response contentType or filename extension
  String mimeType = contentType?.split(';').first.trim().toLowerCase() ?? '';
  if (mimeType.isEmpty || mimeType == 'application/octet-stream') {
    final ext = savePath.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        mimeType = 'image/png';
        break;
      case 'jpg':
      case 'jpeg':
        mimeType = 'image/jpeg';
        break;
      case 'pdf':
        mimeType = 'application/pdf';
        break;
      case 'dwg':
        mimeType = 'application/acad';
        break;
      case 'dxf':
        mimeType = 'application/dxf';
        break;
      case 'zip':
        mimeType = 'application/zip';
        break;
      default:
        mimeType = 'application/octet-stream';
    }
  }

  // Create Blob with authoritative MIME type
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);

  // Check if browser natively supports inline preview/rendering
  final isPreviewable = mimeType.startsWith('image/') || mimeType == 'application/pdf';

  if (openInBrowser && isPreviewable) {
    html.window.open(url, '_blank');
    // Delay revocation to give the newly opened tab time to load the object URL
    Future.delayed(const Duration(minutes: 2), () {
      html.Url.revokeObjectUrl(url);
    });
  } else {
    // For formats that cannot render natively in browser (DWG, DXF, ZIP, octet-stream),
    // or when the action is Download: trigger browser download.
    // NEVER render arbitrary binary content as UTF-8 or plain text!
    html.AnchorElement(href: url)
      ..setAttribute("download", savePath)
      ..click();
    Future.delayed(const Duration(seconds: 30), () {
      html.Url.revokeObjectUrl(url);
    });
  }
}
