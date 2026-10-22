import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../api/providers/api_providers.dart';
import '../../data/file_repository.dart';
import 'dxf_viewer.dart';

/// Pure-Dart utility to extract embedded AutoCAD thumbnail bitmap (DIB)
/// from standard AutoCAD DWG binary files (AC1012 through AC1032).
///
/// Prepend standard 14-byte BITMAPFILEHEADER to produce a 100% valid BMP
/// image directly decodeable by Flutter's built-in image codec.
Uint8List? extractDwgThumbnail(Uint8List bytes) {
  if (bytes.length < 100) return null;

  // Validate standard AutoCAD DWG header (e.g. AC1021, AC1024, AC1027, AC1032, etc.)
  final headerStr = String.fromCharCodes(bytes.sublist(0, 4));
  if (headerStr != 'AC10' && headerStr != 'AC1.' && headerStr != 'AC15') {
    return null;
  }

  // Scan for DIB header (BITMAPINFOHEADER where biSize == 40 (0x28, 0x00, 0x00, 0x00))
  final maxScan = math.min(bytes.length - 40, 100000);
  for (int i = 0; i < maxScan; i++) {
    if (bytes[i] == 0x28 && bytes[i + 1] == 0x00 && bytes[i + 2] == 0x00 && bytes[i + 3] == 0x00) {
      final byteData = ByteData.sublistView(bytes, i);
      final biWidth = byteData.getInt32(4, Endian.little);
      final biHeight = byteData.getInt32(8, Endian.little);
      final biPlanes = byteData.getInt16(12, Endian.little);
      final biBitCount = byteData.getInt16(14, Endian.little);
      final biCompression = byteData.getInt32(16, Endian.little);

      // Validate reasonable image dimensions and standard bit counts
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

/// CAD Drawing Viewer supporting DWG, DXF, and raster preview formats
/// with interactive zoom, pan, fit-to-view, error handling, and download.
class CadDrawingViewer extends ConsumerStatefulWidget {
  final String fileId;
  final String fileName;
  final int? fileSize;
  final int versionNumber;
  final VoidCallback? onDownload;
  final double height;

  const CadDrawingViewer({
    super.key,
    required this.fileId,
    required this.fileName,
    this.fileSize,
    required this.versionNumber,
    this.onDownload,
    this.height = 440,
  });

  @override
  ConsumerState<CadDrawingViewer> createState() => _CadDrawingViewerState();
}

class _CadDrawingViewerState extends ConsumerState<CadDrawingViewer> {
  bool _isLoading = true;
  String? _error;
  Uint8List? _dwgBmpBytes;
  DxfDrawing? _dxfDrawing;
  Uint8List? _rawImageBytes;
  bool _isDxf = false;
  bool _isDwg = false;
  bool _isRasterImage = false;
  String _formatBadge = '';
  String _formatDetails = '';
  final TransformationController _transController = TransformationController();

  @override
  void initState() {
    super.initState();
    _loadDrawing();
  }

  @override
  void didUpdateWidget(covariant CadDrawingViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileId != widget.fileId) {
      _loadDrawing();
    }
  }

  @override
  void dispose() {
    _transController.dispose();
    super.dispose();
  }

  Future<void> _loadDrawing() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _dwgBmpBytes = null;
      _dxfDrawing = null;
      _rawImageBytes = null;
      _isDxf = false;
      _isDwg = false;
      _isRasterImage = false;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final rawList = await apiClient.downloadBinary('/api/files/${widget.fileId}/download');
      if (rawList.isEmpty) {
        throw Exception('File stream returned 0 bytes');
      }
      final raw = Uint8List.fromList(rawList);

      final ext = widget.fileName.split('.').last.toLowerCase();
      final isDwgExt = ext == 'dwg';
      final isDxfExt = ext == 'dxf';
      final isRasterExt = ext == 'png' || ext == 'jpg' || ext == 'jpeg' || ext == 'webp';

      // 1. DWG Drawing
      if (isDwgExt || (raw.length >= 4 && String.fromCharCodes(raw.sublist(0, 4)).startsWith('AC'))) {
        _isDwg = true;
        final bmp = extractDwgThumbnail(raw);
        if (bmp != null) {
          final verStr = raw.length >= 6 ? String.fromCharCodes(raw.sublist(0, 6)) : 'AC1021';
          _dwgBmpBytes = bmp;
          _formatBadge = 'AutoCAD DWG \u2022 Geometry Preview';
          _formatDetails = 'AutoCAD $verStr \u2022 Embedded Drawing Geometry';
        } else {
          throw Exception(
            'DWG geometry preview unavailable: no embedded thumbnail found in this DWG file. '
            'You can download the original DWG drawing below to inspect in AutoCAD.'
          );
        }
      }
      // 2. DXF Vector CAD
      else if (isDxfExt || (raw.length >= 20 && utf8.decode(raw.sublist(0, math.min(raw.length, 100)), allowMalformed: true).contains('SECTION'))) {
        _isDxf = true;
        final text = utf8.decode(raw, allowMalformed: true);
        final parsed = DxfDrawing.parse(text);
        if (parsed.entities.isEmpty) {
          throw Exception('No 2D vector CAD entities found in DXF file');
        }
        _dxfDrawing = parsed;
        final textCount = parsed.entities.whereType<DxfTextEntity>().length;
        final geomCount = parsed.entities.length - textCount;
        _formatBadge = 'AutoCAD DXF \u2022 2D Vector CAD';
        _formatDetails = '$geomCount geometry \u2022 $textCount text labels \u2022 Bounds: ${parsed.bounds.width.toStringAsFixed(1)} x ${parsed.bounds.height.toStringAsFixed(1)}';
      }
      // 3. Raster Image
      else if (isRasterExt) {
        _isRasterImage = true;
        _rawImageBytes = raw;
        _formatBadge = 'Raster Image Preview';
        _formatDetails = '${ext.toUpperCase()} \u2022 ${raw.length} bytes';
      }
      // 4. Unsupported Format
      else {
        throw Exception(
          'Preview unavailable for .$ext format. Supported formats: .dwg, .dxf, .png, .jpg, .jpeg. '
          'You can download the source file below.'
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _resetZoom() {
    setState(() {
      _transController.value = Matrix4.identity();
    });
  }

  void _zoomIn() {
    _zoomAroundCenter(1.3);
  }

  void _zoomOut() {
    _zoomAroundCenter(0.77);
  }

  void _zoomAroundCenter(double factor) {
    final matrix = _transController.value.clone();
    final scaleMatrix = Matrix4.diagonal3Values(factor, factor, 1.0);
    setState(() {
      _transController.value = matrix * scaleMatrix;
    });
  }

  void _openFullscreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF07111E),
        child: Scaffold(
          backgroundColor: const Color(0xFF07111E),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0B192C),
            elevation: 2,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              tooltip: 'Close fullscreen',
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                const Icon(Icons.architecture_rounded, color: Color(0xFF00E5FF), size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.fileName,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatBadge.isEmpty ? 'CAD Viewer' : _formatBadge,
                    style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.fit_screen_rounded, color: Colors.white),
                tooltip: 'Fit to drawing',
                onPressed: _resetZoom,
              ),
              IconButton(
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                tooltip: 'Download file',
                onPressed: widget.onDownload ?? () {
                  ref.read(fileRepositoryProvider).downloadFile(widget.fileId, widget.fileName, openInBrowser: false);
                },
              ),
            ],
          ),
          body: _buildViewerContent(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF07111E),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.25), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Drafting Grid
          Positioned.fill(
            child: CustomPaint(
              painter: _CadGridPainter(),
            ),
          ),

          // Main Viewer Content
          Positioned.fill(
            child: _buildViewerContent(context),
          ),

          // Top Info Banner & Fullscreen Action
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!_isLoading && _error == null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B192C).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isDwg ? Icons.architecture_rounded : (_isDxf ? Icons.polyline_rounded : Icons.image_rounded),
                          color: const Color(0xFF00E5FF),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatBadge,
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox.shrink(),

                // Fullscreen button
                if (!_isLoading && _error == null)
                  Material(
                    color: const Color(0xFF0B192C).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => _openFullscreen(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.fullscreen_rounded, color: Color(0xFF00E5FF), size: 18),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Floating Details & Controls
          if (!_isLoading && _error == null) ...[
            // Format details badge
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B192C).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.2)),
                ),
                child: Text(
                  _formatDetails,
                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
            ),

            // Zoom & Fit Controls
            Positioned(
              bottom: 12,
              right: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildControlButton(icon: Icons.add_rounded, tooltip: 'Zoom In', onTap: _zoomIn),
                  const SizedBox(width: 6),
                  _buildControlButton(icon: Icons.remove_rounded, tooltip: 'Zoom Out', onTap: _zoomOut),
                  const SizedBox(width: 6),
                  _buildControlButton(icon: Icons.fit_screen_rounded, tooltip: 'Fit to View', onTap: _resetZoom),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF0B192C),
      borderRadius: BorderRadius.circular(6),
      elevation: 2,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: const Color(0xFF00E5FF), size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildViewerContent(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF00E5FF)),
            SizedBox(height: 16),
            Text(
              'Loading CAD drawing geometry...',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace'),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.preview_outlined, size: 48, color: Colors.white54),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _loadDrawing,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: const Color(0xFF07111E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: widget.onDownload ?? () {
                      ref.read(fileRepositoryProvider).downloadFile(widget.fileId, widget.fileName, openInBrowser: false);
                    },
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download Original File'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // 1. DWG Drawing
    if (_isDwg && _dwgBmpBytes != null) {
      return InteractiveViewer(
        transformationController: _transController,
        minScale: 0.1,
        maxScale: 20.0,
        boundaryMargin: const EdgeInsets.all(200),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Image.memory(
              _dwgBmpBytes!,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      );
    }

    // 2. DXF Vector CAD
    if (_isDxf && _dxfDrawing != null) {
      return InteractiveViewer(
        transformationController: _transController,
        minScale: 0.1,
        maxScale: 20.0,
        boundaryMargin: const EdgeInsets.all(500),
        child: SizedBox.expand(
          child: CustomPaint(
            painter: DxfPainter(drawing: _dxfDrawing!),
          ),
        ),
      );
    }

    // 3. Raster Image
    if (_isRasterImage && _rawImageBytes != null) {
      return InteractiveViewer(
        transformationController: _transController,
        minScale: 0.1,
        maxScale: 10.0,
        boundaryMargin: const EdgeInsets.all(200),
        child: Center(
          child: Image.memory(
            _rawImageBytes!,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return const Center(child: Text('Empty drawing', style: TextStyle(color: Colors.white54)));
  }
}

/// Subtle Blueprint CAD Grid Background
class _CadGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintMinor = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.04)
      ..strokeWidth = 0.5;

    final paintMajor = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    const step = 20.0;
    for (double x = 0; x <= size.width; x += step) {
      final isMajor = (x / step).round() % 5 == 0;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), isMajor ? paintMajor : paintMinor);
    }

    for (double y = 0; y <= size.height; y += step) {
      final isMajor = (y / step).round() % 5 == 0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), isMajor ? paintMajor : paintMinor);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}