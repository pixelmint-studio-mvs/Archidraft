import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../api/providers/api_providers.dart';
import '../../../data/file_repository.dart';
import '../../widgets/pdf_drawing_viewer.dart';

/// Pure-Dart utility to extract embedded AutoCAD thumbnail bitmap (DIB)
/// from standard AutoCAD DWG binary files (AC1012 through AC1032).
///
/// Prepend standard 14-byte BITMAPFILEHEADER to produce a 100% valid BMP
/// image directly decodable by Flutter's built-in image codec.
Uint8List? extractStudentDwgThumbnail(Uint8List bytes) {
  if (bytes.length < 100) return null;

  // Validate standard AutoCAD DWG header (e.g. AC1021, AC1024, AC1027, AC1032, etc.)
  final headerStr = String.fromCharCodes(bytes.sublist(0, 4));
  if (headerStr != 'AC10' && headerStr != 'AC1.' && headerStr != 'AC15') {
    return null;
  }

  // Scan for DIB header (BITMAPINFOHEADER where biSize == 40 (0x28, 0x00, 0x00, 0x00))
  final maxScan = math.min(bytes.length - 40, 100000);
  for (int i = 0; i < maxScan; i++) {
    if (bytes[i] == 0x28 &&
        bytes[i + 1] == 0x00 &&
        bytes[i + 2] == 0x00 &&
        bytes[i + 3] == 0x00) {
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

/// Helper to map standard AutoCAD Color Index (ACI) to high-contrast Colors.
Color studentDxfAciColor(int? aci, {Color defaultColor = const Color(0xFF00E5FF)}) {
  if (aci == null) return defaultColor;
  switch (aci) {
    case 1:
      return const Color(0xFFFF5252); // Red
    case 2:
      return const Color(0xFFFFD600); // Yellow
    case 3:
      return const Color(0xFF00E676); // Green
    case 4:
      return const Color(0xFF00E5FF); // Cyan
    case 5:
      return const Color(0xFF448AFF); // Blue
    case 6:
      return const Color(0xFFFF4081); // Magenta
    case 7:
      return const Color(0xFFFFFFFF); // White / light
    case 8:
      return const Color(0xFF9E9E9E); // Gray
    case 9:
      return const Color(0xFFB0BEC5); // Light Gray
    default:
      return defaultColor;
  }
}

/// Base class for 2D DXF vector entities.
abstract class StudentDxfEntity {
  final Color color;
  const StudentDxfEntity({this.color = const Color(0xFF00E5FF)});
}

class StudentDxfLine extends StudentDxfEntity {
  final double x1, y1, x2, y2;
  const StudentDxfLine(this.x1, this.y1, this.x2, this.y2, {super.color});
}

class StudentDxfCircle extends StudentDxfEntity {
  final double cx, cy, radius;
  const StudentDxfCircle(this.cx, this.cy, this.radius, {super.color});
}

class StudentDxfArc extends StudentDxfEntity {
  final double cx, cy, radius, startAngle, endAngle;
  const StudentDxfArc(this.cx, this.cy, this.radius, this.startAngle, this.endAngle, {super.color});
}

class StudentDxfPolyline extends StudentDxfEntity {
  final List<Offset> points;
  final bool isClosed;
  const StudentDxfPolyline(this.points, this.isClosed, {super.color});
}

class StudentDxfSolid extends StudentDxfEntity {
  final List<Offset> points;
  const StudentDxfSolid(this.points, {super.color});
}

class StudentDxfEllipse extends StudentDxfEntity {
  final double cx, cy, mx, my, ratio, startParam, endParam;
  const StudentDxfEllipse(
    this.cx,
    this.cy,
    this.mx,
    this.my,
    this.ratio,
    this.startParam,
    this.endParam, {
    super.color,
  });
}

class StudentDxfPointEntity extends StudentDxfEntity {
  final double x, y;
  const StudentDxfPointEntity(this.x, this.y, {super.color});
}

class StudentDxfTextEntity extends StudentDxfEntity {
  final double x, y;
  final double height;
  final double rotation; // In degrees counterclockwise in CAD
  final String text;
  final int hAlign; // 0=left, 1=center, 2=right
  final int vAlign; // 0=baseline, 1=bottom, 2=middle, 3=top

  const StudentDxfTextEntity({
    required this.x,
    required this.y,
    required this.height,
    required this.rotation,
    required this.text,
    this.hAlign = 0,
    this.vAlign = 0,
    super.color = const Color(0xFF64FFDA),
  });
}

/// Parsed DXF Drawing Model with accurate bounding box calculation.
class StudentDxfDrawing {
  final List<StudentDxfEntity> entities;
  final Rect bounds;

  const StudentDxfDrawing({required this.entities, required this.bounds});

  static StudentDxfDrawing parse(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    final entities = <StudentDxfEntity>[];

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

    bool angleBetween(double a, double start, double end) {
      final an = (a % 360 + 360) % 360;
      final sn = (start % 360 + 360) % 360;
      final en = (end % 360 + 360) % 360;
      if (sn <= en) {
        return an >= sn && an <= en;
      } else {
        return an >= sn || an <= en;
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

        final colorIndex = getD(62)?.toInt();
        final entityColor = studentDxfAciColor(colorIndex);

        if (entityType == 'LINE') {
          final x1 = getD(10) ?? 0;
          final y1 = getD(20) ?? 0;
          final x2 = getD(11) ?? 0;
          final y2 = getD(21) ?? 0;
          entities.add(StudentDxfLine(x1, y1, x2, y2, color: entityColor));
          updateBounds(x1, y1);
          updateBounds(x2, y2);
        } else if (entityType == 'CIRCLE') {
          final cx = getD(10) ?? 0;
          final cy = getD(20) ?? 0;
          final r = getD(40) ?? 1;
          entities.add(StudentDxfCircle(cx, cy, r, color: entityColor));
          updateBounds(cx - r, cy - r);
          updateBounds(cx + r, cy + r);
        } else if (entityType == 'ARC') {
          final cx = getD(10) ?? 0;
          final cy = getD(20) ?? 0;
          final r = getD(40) ?? 1;
          final sa = getD(50) ?? 0;
          final ea = getD(51) ?? 360;
          entities.add(StudentDxfArc(cx, cy, r, sa, ea, color: entityColor));

          // Start and end points
          final saRad = sa * math.pi / 180.0;
          final eaRad = ea * math.pi / 180.0;
          updateBounds(cx + r * math.cos(saRad), cy + r * math.sin(saRad));
          updateBounds(cx + r * math.cos(eaRad), cy + r * math.sin(eaRad));

          // Check cardinal extrema inside arc sweep
          if (angleBetween(0, sa, ea)) updateBounds(cx + r, cy);
          if (angleBetween(90, sa, ea)) updateBounds(cx, cy + r);
          if (angleBetween(180, sa, ea)) updateBounds(cx - r, cy);
          if (angleBetween(270, sa, ea)) updateBounds(cx, cy - r);
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
            entities.add(StudentDxfPolyline(pts, (flags & 1) == 1, color: entityColor));
          }
        } else if (entityType == 'POLYLINE') {
          // Standard DXF 2D polyline followed by VERTEX entities until SEQEND
          final flags = getD(70)?.toInt() ?? 0;
          final isClosed = (flags & 1) == 1;
          final pts = <Offset>[];

          while (i < lines.length - 1) {
            final nextCode = int.tryParse(lines[i].trim()) ?? -1;
            final nextVal = lines[i + 1].trim();
            if (nextCode == 0) {
              if (nextVal == 'SEQEND') {
                i += 2;
                break;
              } else if (nextVal == 'VERTEX') {
                i += 2;
                final vCodes = <int, String>{};
                while (i < lines.length - 1) {
                  final vCode = int.tryParse(lines[i].trim()) ?? -1;
                  final vVal = lines[i + 1].trim();
                  if (vCode == 0) break;
                  i += 2;
                  vCodes[vCode] = vVal;
                }
                final vx = double.tryParse(vCodes[10] ?? '') ?? 0;
                final vy = double.tryParse(vCodes[20] ?? '') ?? 0;
                pts.add(Offset(vx, vy));
                updateBounds(vx, vy);
                continue;
              } else {
                break; // Another entity starts
              }
            }
            i += 2;
          }

          if (pts.isNotEmpty) {
            entities.add(StudentDxfPolyline(pts, isClosed, color: entityColor));
          }
        } else if (entityType == 'SOLID' || entityType == 'TRACE' || entityType == '3DFACE') {
          final x1 = getD(10) ?? 0;
          final y1 = getD(20) ?? 0;
          final x2 = getD(11) ?? 0;
          final y2 = getD(21) ?? 0;
          final x3 = getD(12) ?? 0;
          final y3 = getD(22) ?? 0;
          final x4 = getD(13);
          final y4 = getD(23);

          updateBounds(x1, y1);
          updateBounds(x2, y2);
          updateBounds(x3, y3);

          final pts = <Offset>[Offset(x1, y1), Offset(x2, y2)];
          if (x4 != null && y4 != null) {
            // Standard DXF SOLID vertex ordering is 1, 2, 4, 3
            updateBounds(x4, y4);
            pts.add(Offset(x4, y4));
            pts.add(Offset(x3, y3));
          } else {
            pts.add(Offset(x3, y3));
          }
          entities.add(StudentDxfSolid(pts, color: entityColor));
        } else if (entityType == 'ELLIPSE') {
          final cx = getD(10) ?? 0;
          final cy = getD(20) ?? 0;
          final mx = getD(11) ?? 1;
          final my = getD(21) ?? 0;
          final ratio = getD(40) ?? 1.0;
          final sp = getD(41) ?? 0.0;
          final ep = getD(42) ?? 2 * math.pi;

          entities.add(StudentDxfEllipse(cx, cy, mx, my, ratio, sp, ep, color: entityColor));
          final majorLen = math.sqrt(mx * mx + my * my);
          updateBounds(cx - majorLen, cy - majorLen);
          updateBounds(cx + majorLen, cy + majorLen);
        } else if (entityType == 'POINT') {
          final px = getD(10) ?? 0;
          final py = getD(20) ?? 0;
          entities.add(StudentDxfPointEntity(px, py, color: entityColor));
          updateBounds(px, py);
        } else if (entityType == 'TEXT' || entityType == 'MTEXT') {
          final hAlign = getD(72)?.toInt() ?? 0;
          final vAlign = getD(73)?.toInt() ?? 0;
          final useSecond = (hAlign != 0 || vAlign != 0) && entityCodes.containsKey(11);
          final px = useSecond ? (getD(11) ?? getD(10) ?? 0) : (getD(10) ?? 0);
          final py = useSecond ? (getD(21) ?? getD(20) ?? 0) : (getD(20) ?? 0);
          final h = (getD(40) ?? 0) > 0 ? getD(40)! : 12.0;
          final rot = getD(50) ?? 0.0;

          final prefixChunks = entityCodes[3] ?? [];
          final mainChunk = getS(1) ?? '';
          final rawText = prefixChunks.join('') + mainChunk;
          final cleanText = _cleanDxfText(rawText);

          if (cleanText.isNotEmpty) {
            entities.add(StudentDxfTextEntity(
              x: px,
              y: py,
              height: h,
              rotation: rot,
              text: cleanText,
              hAlign: hAlign,
              vAlign: vAlign,
              color: entityColor,
            ));
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

    return StudentDxfDrawing(
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

/// CustomPainter rendering 2D CAD vector entities on high-contrast blueprint canvas.
class StudentDxfPainter extends CustomPainter {
  final StudentDxfDrawing drawing;
  final Color defaultLineColor;

  StudentDxfPainter({
    required this.drawing,
    this.defaultLineColor = const Color(0xFF00E5FF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (drawing.entities.isEmpty) return;

    final bounds = drawing.bounds;
    const padding = 24.0;
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

    final basePaint = Paint()
      ..color = defaultLineColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    for (final entity in drawing.entities) {
      final paint = Paint()
        ..color = entity.color
        ..strokeWidth = basePaint.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      if (entity is StudentDxfLine) {
        canvas.drawLine(toCanvas(entity.x1, entity.y1), toCanvas(entity.x2, entity.y2), paint);
      } else if (entity is StudentDxfCircle) {
        final center = toCanvas(entity.cx, entity.cy);
        canvas.drawCircle(center, entity.radius * scale, paint);
      } else if (entity is StudentDxfArc) {
        final center = toCanvas(entity.cx, entity.cy);
        final r = entity.radius * scale;

        // In CAD, arcs sweep counterclockwise from startAngle to endAngle.
        double sweepDeg = entity.endAngle - entity.startAngle;
        while (sweepDeg <= 0) {
          sweepDeg += 360.0;
        }
        while (sweepDeg > 360.0) {
          sweepDeg -= 360.0;
        }

        // On an inverted-Y canvas:
        // Angle theta in CAD corresponds to -theta on canvas.
        // Counterclockwise rotation (+sweep) in CAD corresponds to -sweep on canvas.
        final startRad = -entity.startAngle * math.pi / 180.0;
        final sweepRad = -sweepDeg * math.pi / 180.0;

        final rect = Rect.fromCircle(center: center, radius: r);
        canvas.drawArc(rect, startRad, sweepRad, false, paint);
      } else if (entity is StudentDxfPolyline) {
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
      } else if (entity is StudentDxfSolid) {
        if (entity.points.length >= 3) {
          final path = Path();
          final p0 = toCanvas(entity.points[0].dx, entity.points[0].dy);
          path.moveTo(p0.dx, p0.dy);
          for (int p = 1; p < entity.points.length; p++) {
            final pt = toCanvas(entity.points[p].dx, entity.points[p].dy);
            path.lineTo(pt.dx, pt.dy);
          }
          path.close();
          canvas.drawPath(path, paint..style = PaintingStyle.fill..color = entity.color.withValues(alpha: 0.3));
          canvas.drawPath(path, paint..style = PaintingStyle.stroke..color = entity.color);
        }
      } else if (entity is StudentDxfEllipse) {
        final center = toCanvas(entity.cx, entity.cy);
        final majorLen = math.sqrt(entity.mx * entity.mx + entity.my * entity.my) * scale;
        final minorLen = majorLen * entity.ratio;
        final rotRad = math.atan2(entity.my, entity.mx);

        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(-rotRad); // Invert rotation for canvas Y
        final rect = Rect.fromCenter(center: Offset.zero, width: majorLen * 2, height: minorLen * 2);
        canvas.drawOval(rect, paint);
        canvas.restore();
      } else if (entity is StudentDxfPointEntity) {
        final pt = toCanvas(entity.x, entity.y);
        canvas.drawCircle(pt, 2.0, paint..style = PaintingStyle.fill);
      } else if (entity is StudentDxfTextEntity) {
        if (entity.text.isEmpty) continue;
        final fontSize = entity.height * scale;
        if (fontSize < 1.0) continue;

        final textSpan = TextSpan(
          text: entity.text,
          style: TextStyle(
            color: entity.color,
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

        double dx = 0.0;
        if (entity.hAlign == 1) {
          dx = -tp.width / 2;
        } else if (entity.hAlign == 2) {
          dx = -tp.width;
        }

        double dy = -tp.height;
        if (entity.vAlign == 3) {
          dy = 0.0;
        } else if (entity.vAlign == 2) {
          dy = -tp.height / 2;
        }

        if (entity.rotation == 0.0) {
          tp.paint(canvas, Offset(basePt.dx + dx, basePt.dy + dy));
        } else {
          canvas.save();
          canvas.translate(basePt.dx, basePt.dy);
          canvas.rotate(-entity.rotation * math.pi / 180);
          tp.paint(canvas, Offset(dx, dy));
          canvas.restore();
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant StudentDxfPainter oldDelegate) =>
      oldDelegate.drawing != drawing || oldDelegate.defaultLineColor != defaultLineColor;
}

class _CachedStudentDrawingData {
  final Uint8List? dwgBmpBytes;
  final StudentDxfDrawing? dxfDrawing;
  final Uint8List? rawImageBytes;
  final Uint8List? pdfBytes;
  final bool isDxf;
  final bool isDwg;
  final bool isRasterImage;
  final bool isPdf;
  final String formatBadge;
  final String formatDetails;

  const _CachedStudentDrawingData({
    this.dwgBmpBytes,
    this.dxfDrawing,
    this.rawImageBytes,
    this.pdfBytes,
    required this.isDxf,
    required this.isDwg,
    required this.isRasterImage,
    required this.isPdf,
    required this.formatBadge,
    required this.formatDetails,
  });
}

/// Dedicated, stabilized Drawing Viewer for the Student Panel.
///
/// Ensures genuine drawing content rendering for supported formats without
/// placeholder geometry or misleading thumbnails, provides interactive zoom/pan,
/// displays informative fallback states with download buttons for unsupported formats,
/// and includes the required viewing advisory text.
class StudentCadDrawingViewer extends ConsumerStatefulWidget {
  final String fileId;
  final String fileName;
  final int? fileSize;
  final int versionNumber;
  final VoidCallback? onDownload;
  final double height;
  final bool isDialog;

  const StudentCadDrawingViewer({
    super.key,
    required this.fileId,
    required this.fileName,
    this.fileSize,
    this.versionNumber = 1,
    this.onDownload,
    this.height = 480,
    this.isDialog = false,
  });

  static void clearCache() => _StudentCadDrawingViewerState.clearCache();

  @override
  ConsumerState<StudentCadDrawingViewer> createState() => _StudentCadDrawingViewerState();
}

class _StudentCadDrawingViewerState extends ConsumerState<StudentCadDrawingViewer> {
  static final Map<String, _CachedStudentDrawingData> _drawingCache = {};

  static void clearCache() {
    _drawingCache.clear();
  }

  bool _isLoading = true;
  String? _error;
  Uint8List? _dwgBmpBytes;
  StudentDxfDrawing? _dxfDrawing;
  Uint8List? _rawImageBytes;
  Uint8List? _pdfBytes;
  bool _isDxf = false;
  bool _isDwg = false;
  bool _isRasterImage = false;
  bool _isPdf = false;
  String _formatBadge = '';
  String _formatDetails = '';
  final TransformationController _transController = TransformationController();

  @override
  void initState() {
    super.initState();
    _loadDrawing();
  }

  @override
  void didUpdateWidget(covariant StudentCadDrawingViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileId != widget.fileId || oldWidget.fileName != widget.fileName) {
      _transController.value = Matrix4.identity();
      _loadDrawing();
    }
  }

  @override
  void dispose() {
    _transController.dispose();
    super.dispose();
  }

  Future<void> _loadDrawing() async {
    // Fast path: reuse parsed drawing from memory cache instantly
    if (_drawingCache.containsKey(widget.fileId)) {
      final cached = _drawingCache[widget.fileId]!;
      setState(() {
        _isLoading = false;
        _error = null;
        _dwgBmpBytes = cached.dwgBmpBytes;
        _dxfDrawing = cached.dxfDrawing;
        _rawImageBytes = cached.rawImageBytes;
        _pdfBytes = cached.pdfBytes;
        _isDxf = cached.isDxf;
        _isDwg = cached.isDwg;
        _isRasterImage = cached.isRasterImage;
        _isPdf = cached.isPdf;
        _formatBadge = cached.formatBadge;
        _formatDetails = cached.formatDetails;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _dwgBmpBytes = null;
      _dxfDrawing = null;
      _rawImageBytes = null;
      _pdfBytes = null;
      _isDxf = false;
      _isDwg = false;
      _isRasterImage = false;
      _isPdf = false;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final rawList = await apiClient.downloadBinary('/api/files/${widget.fileId}/download');
      if (rawList.isEmpty) {
        throw Exception('The drawing file is empty (0 bytes).');
      }
      final raw = Uint8List.fromList(rawList);

      final ext = widget.fileName.split('.').last.toLowerCase();
      final isDwgExt = ext == 'dwg';
      final isDxfExt = ext == 'dxf';
      final isRasterExt = ext == 'png' || ext == 'jpg' || ext == 'jpeg' || ext == 'webp';
      final isPdfExt = ext == 'pdf';

      // 1. DWG Drawing
      if (isDwgExt || (raw.length >= 4 && String.fromCharCodes(raw.sublist(0, 4)).startsWith('AC'))) {
        _isDwg = true;
        final bmp = extractStudentDwgThumbnail(raw);
        if (bmp != null) {
          final verStr = raw.length >= 6 ? String.fromCharCodes(raw.sublist(0, 6)) : 'AC1021';
          _dwgBmpBytes = bmp;
          _formatBadge = 'AutoCAD DWG \u2022 Embedded Thumbnail';
          _formatDetails = 'AutoCAD $verStr \u2022 Embedded Raster Thumbnail';
        } else {
          throw Exception(
            'DWG geometry preview unavailable: no embedded thumbnail found in this DWG file. '
            'Full DWG vector parsing is not supported in the app viewer. '
            'You can download the original DWG drawing below to inspect in AutoCAD or a dedicated drawing viewer app.'
          );
        }
      }
      // 2. DXF Vector CAD
      else if (isDxfExt ||
          (raw.length >= 20 &&
              utf8.decode(raw.sublist(0, math.min(raw.length, 100)), allowMalformed: true).contains('SECTION'))) {
        _isDxf = true;
        final text = utf8.decode(raw, allowMalformed: true);
        final parsed = StudentDxfDrawing.parse(text);
        if (parsed.entities.isEmpty) {
          throw Exception('No 2D vector CAD entities found in DXF file');
        }
        _dxfDrawing = parsed;
        final textCount = parsed.entities.whereType<StudentDxfTextEntity>().length;
        final geomCount = parsed.entities.length - textCount;
        _formatBadge = 'AutoCAD DXF \u2022 2D Vector CAD';
        _formatDetails =
            '$geomCount geometry \u2022 $textCount text labels \u2022 Bounds: ${parsed.bounds.width.toStringAsFixed(1)} x ${parsed.bounds.height.toStringAsFixed(1)}';
      }
      // 3. PDF Document
      else if (isPdfExt || (raw.length >= 4 && String.fromCharCodes(raw.sublist(0, 4)) == '%PDF')) {
        _isPdf = true;
        _pdfBytes = raw;
        _formatBadge = 'PDF Document \u2022 Vector Sheet';
        _formatDetails = 'PDF \u2022 ${raw.length} bytes \u2022 Technical Drawing Sheet';
      }
      // 4. Raster Image
      else if (isRasterExt) {
        _isRasterImage = true;
        _rawImageBytes = raw;
        _formatBadge = 'Raster Image Preview';
        _formatDetails = '${ext.toUpperCase()} \u2022 ${raw.length} bytes';
      }
      // 5. Unsupported Format
      else {
        throw Exception(
          'Preview unavailable for .$ext format. Supported formats: .dwg, .dxf, .pdf, .png, .jpg, .jpeg. '
          'You can download the source file below.'
        );
      }

      // Populate memory cache for instant future rendering
      _drawingCache[widget.fileId] = _CachedStudentDrawingData(
        dwgBmpBytes: _dwgBmpBytes,
        dxfDrawing: _dxfDrawing,
        rawImageBytes: _rawImageBytes,
        pdfBytes: _pdfBytes,
        isDxf: _isDxf,
        isDwg: _isDwg,
        isRasterImage: _isRasterImage,
        isPdf: _isPdf,
        formatBadge: _formatBadge,
        formatDetails: _formatDetails,
      );

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
                    _formatBadge.isEmpty ? 'Student CAD Preview' : _formatBadge,
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
          body: Column(
            children: [
              Expanded(child: _buildViewerContent(context)),
              _buildAdvisoryFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvisoryFooter() {
    return Container(
      key: const ValueKey('student_preview_advisory_bar'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0B192C),
        border: Border(
          top: BorderSide(
            color: Color(0x3300E5FF),
            width: 1.0,
          ),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: Color(0xFF00E5FF),
          ),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'For better viewing experience, Use Drawing viewer apps.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
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
      child: Column(
        children: [
          // Main drawing canvas area
          Expanded(
            child: Stack(
              children: [
                // Background Drafting Grid
                Positioned.fill(
                  child: CustomPaint(
                    painter: _StudentCadViewerGridPainter(),
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
                                _isDwg
                                    ? Icons.architecture_rounded
                                    : (_isDxf
                                        ? Icons.polyline_rounded
                                        : (_isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded)),
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
                      if (!widget.isDialog && !_isLoading && _error == null)
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
          ),

          // Informational line placed visibly and unobtrusively in the preview footer
          _buildAdvisoryFooter(),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.preview_outlined, size: 36, color: Colors.white54),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _loadDrawing,
                    icon: const Icon(Icons.refresh, size: 14),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: const Color(0xFF07111E),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.onDownload ?? () {
                      ref.read(fileRepositoryProvider).downloadFile(widget.fileId, widget.fileName, openInBrowser: false);
                    },
                    icon: const Icon(Icons.download, size: 14),
                    label: const Text('Download Original File'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // 1. DWG Drawing (Embedded Thumbnail)
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
            painter: StudentDxfPainter(drawing: _dxfDrawing!),
          ),
        ),
      );
    }

    // 3. PDF Document
    if (_isPdf && _pdfBytes != null) {
      return PdfDrawingViewer(
        bytes: _pdfBytes!,
        fileName: widget.fileName,
        fileId: widget.fileId,
        onDownload: widget.onDownload ?? () {
          ref.read(fileRepositoryProvider).downloadFile(widget.fileId, widget.fileName, openInBrowser: false);
        },
      );
    }

    // 4. Raster Image
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

    return Center(
      child: Text(
        'Unable to display drawing preview for ${widget.fileName}',
        style: const TextStyle(color: Colors.white60, fontSize: 13),
      ),
    );
  }
}

/// Subtle drafting grid for student CAD viewer background.
class _StudentCadViewerGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintMinor = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    final paintMajor = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.07)
      ..strokeWidth = 1.0;

    const step = 24.0;
    for (double x = 0; x <= size.width; x += step) {
      final isMajor = (x / step).round() % 4 == 0;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), isMajor ? paintMajor : paintMinor);
    }

    for (double y = 0; y <= size.height; y += step) {
      final isMajor = (y / step).round() % 4 == 0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), isMajor ? paintMajor : paintMinor);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
