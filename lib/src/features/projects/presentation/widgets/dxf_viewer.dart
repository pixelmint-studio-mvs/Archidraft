import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../api/providers/api_providers.dart';
import '../../data/file_repository.dart';

/// 2D DXF Vector Entities
abstract class DxfEntity {}

class DxfLine extends DxfEntity {
  final double x1, y1, x2, y2;
  DxfLine(this.x1, this.y1, this.x2, this.y2);
}

class DxfCircle extends DxfEntity {
  final double cx, cy, radius;
  DxfCircle(this.cx, this.cy, this.radius);
}

class DxfArc extends DxfEntity {
  final double cx, cy, radius, startAngle, endAngle;
  DxfArc(this.cx, this.cy, this.radius, this.startAngle, this.endAngle);
}

class DxfPolyline extends DxfEntity {
  final List<Offset> points;
  final bool isClosed;
  DxfPolyline(this.points, this.isClosed);
}

class DxfPointEntity extends DxfEntity {
  final double x, y;
  DxfPointEntity(this.x, this.y);
}

class DxfTextEntity extends DxfEntity {
  final double x, y;
  final double height;
  final double rotation; // In degrees counterclockwise in CAD
  final String text;
  final int hAlign; // 0=left, 1=center, 2=right
  final int vAlign; // 0=baseline, 1=bottom, 2=middle, 3=top

  DxfTextEntity({
    required this.x,
    required this.y,
    required this.height,
    required this.rotation,
    required this.text,
    this.hAlign = 0,
    this.vAlign = 0,
  });
}

/// Parsed DXF Drawing Model
class DxfDrawing {
  final List<DxfEntity> entities;
  final Rect bounds;

  DxfDrawing({required this.entities, required this.bounds});

  static DxfDrawing parse(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    final entities = <DxfEntity>[];

    bool inEntities = false;
    int i = 0;

    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;

    void updateBounds(double x, double y) {
      if (x.isFinite && y.isFinite) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }

    while (i < lines.length - 1) {
      final code = int.tryParse(lines[i].trim()) ?? -1;
      final val = lines[i + 1].trim();
      i += 2;

      if (code == 0 && val == 'SECTION') {
        if (i < lines.length - 1 && lines[i].trim() == '2' && lines[i + 1].trim() == 'ENTITIES') {
          inEntities = true;
          i += 2;
        }
      } else if (code == 0 && val == 'ENDSEC') {
        inEntities = false;
      } else if (code == 0 && val == 'EOF') {
        break;
      } else if (inEntities && code == 0) {
        final entityType = val;
        final entityCodes = <int, List<String>>{};

        // Collect group codes for this entity
        while (i < lines.length - 1) {
          final nextCode = int.tryParse(lines[i].trim()) ?? -1;
          final nextVal = lines[i + 1].trim();
          if (nextCode == 0) break; // Next entity starts
          i += 2;
          entityCodes.putIfAbsent(nextCode, () => []).add(nextVal);
        }

        double? getD(int c) {
          final l = entityCodes[c];
          return (l != null && l.isNotEmpty) ? double.tryParse(l.first) : null;
        }

        String? getS(int c) {
          final l = entityCodes[c];
          return (l != null && l.isNotEmpty) ? l.first : null;
        }

        if (entityType == 'LINE') {
          final x1 = getD(10) ?? 0;
          final y1 = getD(20) ?? 0;
          final x2 = getD(11) ?? 0;
          final y2 = getD(21) ?? 0;
          entities.add(DxfLine(x1, y1, x2, y2));
          updateBounds(x1, y1);
          updateBounds(x2, y2);
        } else if (entityType == 'CIRCLE') {
          final cx = getD(10) ?? 0;
          final cy = getD(20) ?? 0;
          final r = getD(40) ?? 1;
          entities.add(DxfCircle(cx, cy, r));
          updateBounds(cx - r, cy - r);
          updateBounds(cx + r, cy + r);
        } else if (entityType == 'ARC') {
          final cx = getD(10) ?? 0;
          final cy = getD(20) ?? 0;
          final r = getD(40) ?? 1;
          final sa = getD(50) ?? 0;
          final ea = getD(51) ?? 360;
          entities.add(DxfArc(cx, cy, r, sa, ea));
          updateBounds(cx - r, cy - r);
          updateBounds(cx + r, cy + r);
        } else if (entityType == 'LWPOLYLINE') {
          final xs = entityCodes[10] ?? [];
          final ys = entityCodes[20] ?? [];
          final flags = getD(70)?.toInt() ?? 0;
          final pts = <Offset>[];
          final count = math.min(xs.length, ys.length);
          for (int p = 0; p < count; p++) {
            final px = double.tryParse(xs[p]) ?? 0;
            final py = double.tryParse(ys[p]) ?? 0;
            pts.add(Offset(px, py));
            updateBounds(px, py);
          }
          if (pts.isNotEmpty) {
            entities.add(DxfPolyline(pts, (flags & 1) == 1));
          }
        } else if (entityType == 'POINT') {
          final px = getD(10) ?? 0;
          final py = getD(20) ?? 0;
          entities.add(DxfPointEntity(px, py));
          updateBounds(px, py);
        } else if (entityType == 'TEXT' || entityType == 'MTEXT') {
          final hAlign = getD(72)?.toInt() ?? 0;
          final vAlign = getD(73)?.toInt() ?? 0;
          // In DXF, if group 72 or 73 is non-zero, group 11/21 is the alignment point
          final useSecond = (hAlign != 0 || vAlign != 0) && entityCodes.containsKey(11);
          final px = useSecond ? (getD(11) ?? getD(10) ?? 0) : (getD(10) ?? 0);
          final py = useSecond ? (getD(21) ?? getD(20) ?? 0) : (getD(20) ?? 0);
          final h = (getD(40) ?? 0) > 0 ? getD(40)! : 200.0;
          final rot = getD(50) ?? 0.0;

          final prefixChunks = entityCodes[3] ?? [];
          final mainChunk = getS(1) ?? '';
          final rawText = prefixChunks.join('') + mainChunk;
          final cleanText = _cleanDxfText(rawText);

          if (cleanText.isNotEmpty) {
            entities.add(DxfTextEntity(
              x: px,
              y: py,
              height: h,
              rotation: rot,
              text: cleanText,
              hAlign: hAlign,
              vAlign: vAlign,
            ));
            // Update bounds so Fit to Drawing covers text as well
            final approxW = cleanText.length * h * 0.6;
            updateBounds(px, py);
            updateBounds(px + approxW, py + h);
          }
        }
      }
    }

    if (minX == double.infinity) {
      minX = 0;
      minY = 0;
      maxX = 100;
      maxY = 100;
    }

    final width = (maxX - minX).abs() < 1e-4 ? 10.0 : (maxX - minX);
    final height = (maxY - minY).abs() < 1e-4 ? 10.0 : (maxY - minY);

    return DxfDrawing(
      entities: entities,
      bounds: Rect.fromLTWH(minX, minY, width, height),
    );
  }

  static String _cleanDxfText(String raw) {
    var s = raw;
    s = s.replaceAll(RegExp(r'\\[Pp]'), '\n');
    s = s.replaceAll('%%c', 'Ø').replaceAll('%%C', 'Ø');
    s = s.replaceAll('%%d', '°').replaceAll('%%D', '°');
    s = s.replaceAll('%%p', '±').replaceAll('%%P', '±');
    s = s.replaceAll('%%u', '').replaceAll('%%U', '');
    s = s.replaceAll('%%o', '').replaceAll('%%O', '');
    s = s.replaceAllMapped(RegExp(r'\{([^{}]*)\}'), (m) => m.group(1) ?? '');
    s = s.replaceAll(RegExp(r'\\[A-Za-z0-9]+;'), '');
    s = s.replaceAll(RegExp(r'\\f[^;]+;'), '');
    s = s.replaceAll(r'\~', ' ');
    return s.trim();
  }
}

/// CustomPainter that renders 2D CAD vector entities
class DxfPainter extends CustomPainter {
  final DxfDrawing drawing;
  final Color lineColor;
  final Color backgroundColor;

  DxfPainter({
    required this.drawing,
    this.lineColor = const Color(0xFF00E5FF),
    this.backgroundColor = const Color(0xFF0A192F),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (drawing.entities.isEmpty) return;

    final bounds = drawing.bounds;
    final padding = 20.0;
    final availW = size.width - padding * 2;
    final availH = size.height - padding * 2;

    if (availW <= 0 || availH <= 0 || bounds.width <= 0 || bounds.height <= 0) return;

    final scaleX = availW / bounds.width;
    final scaleY = availH / bounds.height;
    final scale = math.min(scaleX, scaleY);

    final offsetX = padding + (availW - bounds.width * scale) / 2;
    final offsetY = padding + (availH - bounds.height * scale) / 2;

    Offset toCanvas(double x, double y) {
      // Invert Y axis for CAD standard coordinates (Y points up in CAD)
      final cx = offsetX + (x - bounds.left) * scale;
      final cy = offsetY + (bounds.bottom - y) * scale;
      return Offset(cx, cy);
    }

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    for (final entity in drawing.entities) {
      if (entity is DxfLine) {
        canvas.drawLine(toCanvas(entity.x1, entity.y1), toCanvas(entity.x2, entity.y2), paint);
      } else if (entity is DxfCircle) {
        final center = toCanvas(entity.cx, entity.cy);
        canvas.drawCircle(center, entity.radius * scale, paint);
      } else if (entity is DxfArc) {
        final center = toCanvas(entity.cx, entity.cy);
        final r = entity.radius * scale;
        // Angles in DXF are counterclockwise degrees from positive X axis
        final startRad = -entity.startAngle * math.pi / 180;
        final sweepRad = -(entity.endAngle - entity.startAngle) * math.pi / 180;
        final rect = Rect.fromCircle(center: center, radius: r);
        canvas.drawArc(rect, startRad, sweepRad, false, paint);
      } else if (entity is DxfPolyline) {
        if (entity.points.length >= 2) {
          final path = Path();
          final start = toCanvas(entity.points.first.dx, entity.points.first.dy);
          path.moveTo(start.dx, start.dy);
          for (int p = 1; p < entity.points.length; p++) {
            final pt = toCanvas(entity.points[p].dx, entity.points[p].dy);
            path.lineTo(pt.dx, pt.dy);
          }
          if (entity.isClosed) {
            path.close();
          }
          canvas.drawPath(path, paint);
        }
      } else if (entity is DxfPointEntity) {
        final pt = toCanvas(entity.x, entity.y);
        canvas.drawCircle(pt, 2.0, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
      } else if (entity is DxfTextEntity) {
        if (entity.text.isEmpty) continue;
        final fontSize = entity.height * scale;
        // Don't render sub-pixel microscopic text
        if (fontSize < 1.0) continue;

        final textSpan = TextSpan(
          text: entity.text,
          style: TextStyle(
            color: const Color(0xFF64FFDA), // Bright cyan/teal for clear CAD annotation readability
            fontSize: fontSize,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        );
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        final basePt = toCanvas(entity.x, entity.y);

        // Horizontal alignment offset
        double dx = 0.0;
        if (entity.hAlign == 1) {
          dx = -tp.width / 2; // Center
        } else if (entity.hAlign == 2) {
          dx = -tp.width; // Right
        }

        // Vertical alignment offset:
        // In CAD, basePt is the baseline insertion point.
        // On canvas, Y points down, so baseline is at basePt.dy.
        // TextPainter draws from top-left, so top-left is (basePt.dx, basePt.dy - tp.height).
        double dy = -tp.height;
        if (entity.vAlign == 3) {
          dy = 0.0; // Top
        } else if (entity.vAlign == 2) {
          dy = -tp.height / 2; // Middle
        }

        if (entity.rotation == 0.0) {
          tp.paint(canvas, Offset(basePt.dx + dx, basePt.dy + dy));
        } else {
          canvas.save();
          canvas.translate(basePt.dx, basePt.dy);
          // Invert CAD counterclockwise rotation for inverted Y canvas
          canvas.rotate(-entity.rotation * math.pi / 180);
          tp.paint(canvas, Offset(dx, dy));
          canvas.restore();
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant DxfPainter oldDelegate) =>
      oldDelegate.drawing != drawing || oldDelegate.lineColor != lineColor;
}

/// Full interactive modal dialog for viewing 2D DXF CAD files
class DxfViewerDialog extends ConsumerStatefulWidget {
  final String fileId;
  final String fileName;

  const DxfViewerDialog({
    super.key,
    required this.fileId,
    required this.fileName,
  });

  @override
  ConsumerState<DxfViewerDialog> createState() => _DxfViewerDialogState();
}

class _DxfViewerDialogState extends ConsumerState<DxfViewerDialog> {
  DxfDrawing? _drawing;
  bool _isLoading = true;
  String? _error;
  final TransformationController _transController = TransformationController();

  @override
  void initState() {
    super.initState();
    _fetchAndParseDxf();
  }

  @override
  void dispose() {
    _transController.dispose();
    super.dispose();
  }

  Future<void> _fetchAndParseDxf() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final raw = await apiClient.downloadBinary('/api/files/${widget.fileId}/download');
      final text = String.fromCharCodes(raw);

      final parsed = DxfDrawing.parse(text);
      if (parsed.entities.isEmpty) {
        throw Exception('No 2D vector drawing entities found in DXF file');
      }

      if (mounted) {
        setState(() {
          _drawing = parsed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load CAD drawing: $e';
        });
      }
    }
  }

  void _resetZoom() {
    _transController.value = Matrix4.identity();
  }

  void _zoomIn() {
    _zoomAroundCenter(1.3);
  }

  void _zoomOut() {
    _zoomAroundCenter(0.77);
  }

  void _zoomAroundCenter(double factor) {
    final size = MediaQuery.of(context).size;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final matrix = _transController.value.clone();

    final translationToCenter = Matrix4.translationValues(cx, cy, 0);
    final scaleMatrix = Matrix4.diagonal3Values(factor, factor, 1.0);
    final translationBack = Matrix4.translationValues(-cx, -cy, 0);

    setState(() {
      _transController.value = translationToCenter * scaleMatrix * translationBack * matrix;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF07111E),
      child: Scaffold(
        backgroundColor: const Color(0xFF07111E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0B192C),
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            tooltip: 'Close viewer',
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
                child: const Text(
                  '2D Vector CAD',
                  style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold),
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
              onPressed: () {
                ref.read(fileRepositoryProvider).downloadFile(
                      widget.fileId,
                      widget.fileName,
                      openInBrowser: false,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Downloading ${widget.fileName}...')),
                );
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00E5FF)),
                    SizedBox(height: 16),
                    Text('Parsing CAD vector drawing...', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _fetchAndParseDxf,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      // Interactive Vector Drawing Canvas
                      InteractiveViewer(
                        transformationController: _transController,
                        minScale: 0.1,
                        maxScale: 20.0,
                        boundaryMargin: const EdgeInsets.all(500),
                        child: SizedBox.expand(
                          child: CustomPaint(
                            painter: DxfPainter(drawing: _drawing!),
                          ),
                        ),
                      ),

                      // Floating Statistics Card
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final textEntities = _drawing!.entities.whereType<DxfTextEntity>().length;
                            final geomEntities = _drawing!.entities.length - textEntities;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B192C).withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.layers_outlined, color: Color(0xFF00E5FF), size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$geomEntities geometry · $textEntities text labels | Fit to Drawing',
                                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // Floating Zoom & Pan Controls
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              color: const Color(0xFF0B192C),
                              borderRadius: BorderRadius.circular(8),
                              elevation: 4,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: _zoomIn,
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.add_rounded, color: Color(0xFF00E5FF), size: 22),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Material(
                              color: const Color(0xFF0B192C),
                              borderRadius: BorderRadius.circular(8),
                              elevation: 4,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: _zoomOut,
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.remove_rounded, color: Color(0xFF00E5FF), size: 22),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Material(
                              color: const Color(0xFF0B192C),
                              borderRadius: BorderRadius.circular(8),
                              elevation: 4,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: _resetZoom,
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.fit_screen_rounded, color: Color(0xFF00E5FF), size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
