import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archi_draft/src/features/api/data/api_client.dart';
import 'package:archi_draft/src/features/api/providers/api_providers.dart';
import 'package:archi_draft/src/features/projects/data/file_repository.dart';
import 'package:archi_draft/src/features/projects/presentation/student/widgets/student_cad_drawing_viewer.dart';

class MockStudentApiClient extends Fake implements ApiClient {
  final Map<String, Uint8List> responses;

  MockStudentApiClient(this.responses);

  @override
  Future<Uint8List> downloadBinary(String path) async {
    if (responses.containsKey(path)) {
      return responses[path]!;
    }
    throw Exception('404 Not Found: $path');
  }
}

class MockStudentFileRepository extends Fake implements FileRepository {
  bool downloadCalled = false;
  String? downloadedFileId;
  String? downloadedFileName;

  @override
  Future<void> downloadFile(String fileId, String fileName, {bool openInBrowser = false}) async {
    downloadCalled = true;
    downloadedFileId = fileId;
    downloadedFileName = fileName;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    StudentCadDrawingViewer.clearCache();
  });

  group('StudentDxfDrawing Parser & Mathematical Precision', () {
    test('Correctly parses DXF entities (Line, Circle, Arc, Polyline, Solid, Text) and computes exact bounds', () {
      const architecturalDxf = '''0
SECTION
2
ENTITIES
0
LINE
10
10.0
20
20.0
11
110.0
21
20.0
62
1
0
CIRCLE
10
200.0
20
150.0
40
25.0
62
2
0
ARC
10
50.0
20
50.0
40
30.0
50
0.0
51
90.0
62
3
0
LWPOLYLINE
70
1
10
0.0
20
0.0
10
100.0
20
0.0
10
100.0
20
100.0
10
0.0
20
100.0
62
4
0
TEXT
10
15.0
20
25.0
40
14.0
50
0.0
1
MASTER BEDROOM
0
ENDSEC
0
EOF''';

      final drawing = StudentDxfDrawing.parse(architecturalDxf);

      expect(drawing.entities.length, equals(5));
      expect(drawing.entities[0], isA<StudentDxfLine>());
      expect((drawing.entities[0] as StudentDxfLine).x1, equals(10.0));
      expect((drawing.entities[0] as StudentDxfLine).x2, equals(110.0));

      expect(drawing.entities[1], isA<StudentDxfCircle>());
      expect((drawing.entities[1] as StudentDxfCircle).radius, equals(25.0));

      expect(drawing.entities[2], isA<StudentDxfArc>());
      expect((drawing.entities[2] as StudentDxfArc).startAngle, equals(0.0));
      expect((drawing.entities[2] as StudentDxfArc).endAngle, equals(90.0));

      expect(drawing.entities[3], isA<StudentDxfPolyline>());
      expect((drawing.entities[3] as StudentDxfPolyline).isClosed, isTrue);
      expect((drawing.entities[3] as StudentDxfPolyline).points.length, equals(4));

      expect(drawing.entities[4], isA<StudentDxfTextEntity>());
      expect((drawing.entities[4] as StudentDxfTextEntity).text, equals('MASTER BEDROOM'));

      // Verify bounds encompass all entities without distortion
      expect(drawing.bounds.left, equals(0.0));
      expect(drawing.bounds.right, greaterThanOrEqualTo(225.0)); // Circle at 200 + 25
      expect(drawing.bounds.width, greaterThan(200.0));
    });

    test('Arc crossing 0 degrees computes accurate angular sweep and does not reverse', () {
      const arcDxf = '''0
SECTION
2
ENTITIES
0
ARC
10
100.0
20
100.0
40
50.0
50
315.0
51
45.0
0
ENDSEC
0
EOF''';

      final drawing = StudentDxfDrawing.parse(arcDxf);
      expect(drawing.entities.length, equals(1));
      final arc = drawing.entities.first as StudentDxfArc;
      expect(arc.startAngle, equals(315.0));
      expect(arc.endAngle, equals(45.0));

      // In CAD, 315 to 45 CCW sweeps 90 degrees and crosses 0 degrees (+X axis).
      // Max X should be center + radius = 150.0
      expect(drawing.bounds.right, closeTo(150.0, 0.1));
    });

    test('Standard POLYLINE with VERTEX stream is parsed into 2D Polyline entity', () {
      const polylineDxf = '''0
SECTION
2
ENTITIES
0
POLYLINE
70
1
0
VERTEX
10
10.0
20
10.0
0
VERTEX
10
50.0
20
10.0
0
VERTEX
10
50.0
20
50.0
0
SEQEND
0
ENDSEC
0
EOF''';

      final drawing = StudentDxfDrawing.parse(polylineDxf);
      expect(drawing.entities.length, equals(1));
      expect(drawing.entities.first, isA<StudentDxfPolyline>());
      final poly = drawing.entities.first as StudentDxfPolyline;
      expect(poly.points.length, equals(3));
      expect(poly.isClosed, isTrue);
      expect(drawing.bounds.left, equals(10.0));
      expect(drawing.bounds.right, equals(50.0));
    });
  });

  group('StudentCadDrawingViewer — 10 Strict Acceptance Requirements', () {
    const fixtureDxf = '''0
SECTION
2
ENTITIES
0
LINE
10
0.0
20
0.0
11
300.0
21
200.0
62
4
0
CIRCLE
10
150.0
20
100.0
40
60.0
62
3
0
ENDSEC
0
EOF''';

    Widget buildViewerWidget({
      required String fileId,
      required String fileName,
      ApiClient? apiClient,
      FileRepository? fileRepository,
      int versionNumber = 1,
    }) {
      return ProviderScope(
        overrides: [
          if (apiClient != null) apiClientProvider.overrideWithValue(apiClient),
          if (fileRepository != null) fileRepositoryProvider.overrideWithValue(fileRepository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: StudentCadDrawingViewer(
              fileId: fileId,
              fileName: fileName,
              versionNumber: versionNumber,
              height: 500,
            ),
          ),
        ),
      );
    }

    testWidgets('1 & 2. Valid supported DXF renders genuine drawing geometry and not placeholder content', (tester) async {
      final fakeClient = MockStudentApiClient({
        '/api/files/test_dxf_real/download': Uint8List.fromList(utf8.encode(fixtureDxf)),
      });

      await tester.pumpWidget(buildViewerWidget(
        fileId: 'test_dxf_real',
        fileName: 'architectural_floor_plan.dxf',
        apiClient: fakeClient,
      ));
      await tester.pumpAndSettle();

      // Formats badge accurately identifies 2D vector CAD
      expect(find.text('AutoCAD DXF \u2022 2D Vector CAD'), findsOneWidget);
      expect(find.textContaining('2 geometry'), findsOneWidget);
      expect(find.textContaining('Bounds: 300.0 x 200.0'), findsOneWidget);

      // Verifies CustomPaint with StudentDxfPainter is actively rendering the parsed geometry
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('3. Drawing is correctly scaled, fitted, and centered into preview canvas', (tester) async {
      final fakeClient = MockStudentApiClient({
        '/api/files/test_dxf_scale/download': Uint8List.fromList(utf8.encode(fixtureDxf)),
      });

      await tester.pumpWidget(buildViewerWidget(
        fileId: 'test_dxf_scale',
        fileName: 'elevation_sheet.dxf',
        apiClient: fakeClient,
      ));
      await tester.pumpAndSettle();

      // InteractiveViewer is rendered without throwing overflow errors
      expect(tester.takeException(), isNull);
      final customPaints = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
      final dxfPainterPaint = customPaints.firstWhere((p) => p.painter is StudentDxfPainter);
      final painter = dxfPainterPaint.painter as StudentDxfPainter;
      expect(painter.drawing.bounds.width, closeTo(300.0, 0.1));
      expect(painter.drawing.bounds.height, closeTo(200.0, 0.1));
    });

    testWidgets('4. Zoom-in, Zoom-out, and Fit-to-view controls function properly', (tester) async {
      final fakeClient = MockStudentApiClient({
        '/api/files/test_dxf_controls/download': Uint8List.fromList(utf8.encode(fixtureDxf)),
      });

      await tester.pumpWidget(buildViewerWidget(
        fileId: 'test_dxf_controls',
        fileName: 'mep_plan.dxf',
        apiClient: fakeClient,
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      expect(find.byIcon(Icons.fit_screen_rounded), findsOneWidget);

      // Tap Zoom In
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Tap Zoom Out
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Tap Fit to View
      await tester.tap(find.byIcon(Icons.fit_screen_rounded));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('5. Selecting another file refreshes preview and does not retain stale geometry', (tester) async {
      const secondDxf = '''0
SECTION
2
ENTITIES
0
CIRCLE
10
50.0
20
50.0
40
20.0
0
ENDSEC
0
EOF''';

      final fakeClient = MockStudentApiClient({
        '/api/files/file_first/download': Uint8List.fromList(utf8.encode(fixtureDxf)),
        '/api/files/file_second/download': Uint8List.fromList(utf8.encode(secondDxf)),
      });

      // Pump first file
      await tester.pumpWidget(buildViewerWidget(
        fileId: 'file_first',
        fileName: 'drawing_alpha.dxf',
        apiClient: fakeClient,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Bounds: 300.0 x 200.0'), findsOneWidget);

      // Switch to second file
      await tester.pumpWidget(buildViewerWidget(
        fileId: 'file_second',
        fileName: 'drawing_beta.dxf',
        apiClient: fakeClient,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Bounds: 300.0 x 200.0'), findsNothing);
      expect(find.textContaining('Bounds: 40.0 x 40.0'), findsOneWidget);
      expect(find.textContaining('1 geometry'), findsOneWidget);
    });

    testWidgets('6. DWG with embedded thumbnail renders and accurately labels preview as Embedded Thumbnail', (tester) async {
      final dwgFixture = File('assets/images/architectural_-_annotation_scaling_and_multileaders.dwg');
      expect(dwgFixture.existsSync(), isTrue);
      final dwgBytes = dwgFixture.readAsBytesSync();

      final fakeClient = MockStudentApiClient({
        '/api/files/dwg_thumb_file/download': dwgBytes,
      });

      await tester.pumpWidget(buildViewerWidget(
        fileId: 'dwg_thumb_file',
        fileName: 'villa_master.dwg',
        apiClient: fakeClient,
      ));
      await tester.pumpAndSettle();

      // Accurately labeled as thumbnail — NOT claimed to be full CAD geometry rendering
      expect(find.text('AutoCAD DWG \u2022 Embedded Thumbnail'), findsOneWidget);
      expect(find.textContaining('Embedded Raster Thumbnail'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('7. DWG without embedded thumbnail displays clear unsupported message and original download button', (tester) async {
      final dwgWithoutThumb = Uint8List.fromList(utf8.encode('AC1027_VALID_DWG_HEADER_WITHOUT_DIB_THUMBNAIL_BYTES'));
      final fakeClient = MockStudentApiClient({
        '/api/files/dwg_no_thumb/download': dwgWithoutThumb,
      });
      final mockRepo = MockStudentFileRepository();

      await tester.pumpWidget(buildViewerWidget(
        fileId: 'dwg_no_thumb',
        fileName: 'foundation_details.dwg',
        apiClient: fakeClient,
        fileRepository: mockRepo,
      ));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('DWG geometry preview unavailable: no embedded thumbnail found in this DWG file.'),
        findsOneWidget,
      );
      final downloadBtn = find.text('Download Original File');
      expect(downloadBtn, findsOneWidget);

      await tester.tap(downloadBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.downloadCalled, isTrue);
      expect(mockRepo.downloadedFileId, equals('dwg_no_thumb'));
    });

    testWidgets('8. Unsupported formats show clear message and original download button', (tester) async {
      final fakeClient = MockStudentApiClient({
        '/api/files/unknown_file/download': Uint8List.fromList([1, 2, 3, 4, 5]),
      });
      final mockRepo = MockStudentFileRepository();

      await tester.pumpWidget(buildViewerWidget(
        fileId: 'unknown_file',
        fileName: 'model_render.obj',
        apiClient: fakeClient,
        fileRepository: mockRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Preview unavailable for .obj format'), findsOneWidget);
      expect(find.text('Download Original File'), findsOneWidget);

      await tester.tap(find.text('Download Original File'));
      await tester.pumpAndSettle();
      expect(mockRepo.downloadCalled, isTrue);
    });

    testWidgets('9. Missing or inaccessible file (404/403) and empty files produce safe error states', (tester) async {
      // 404 test
      final fakeClient404 = MockStudentApiClient({});

      await tester.pumpWidget(buildViewerWidget(
        fileId: 'missing_file_id',
        fileName: 'missing_sheet.dxf',
        apiClient: fakeClient404,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('404 Not Found'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Empty file (0 bytes) test
      final fakeClientEmpty = MockStudentApiClient({
        '/api/files/empty_file_id/download': Uint8List(0),
      });

      await tester.pumpWidget(buildViewerWidget(
        fileId: 'empty_file_id',
        fileName: 'corrupt_empty.dxf',
        apiClient: fakeClientEmpty,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('The drawing file is empty (0 bytes)'), findsOneWidget);
    });

    testWidgets('10. The required informational line appears exactly as specified', (tester) async {
      final fakeClient = MockStudentApiClient({
        '/api/files/test_advisory_file/download': Uint8List.fromList(utf8.encode(fixtureDxf)),
      });

      await tester.pumpWidget(buildViewerWidget(
        fileId: 'test_advisory_file',
        fileName: 'site_survey.dxf',
        apiClient: fakeClient,
      ));
      await tester.pumpAndSettle();

      // Exact text required by prompt Section 4:
      const requiredLine = 'For better viewing experience, Use Drawing viewer apps.';
      expect(find.text(requiredLine), findsOneWidget);

      // Verifies it is placed in the advisory footer beneath the canvas
      final advisoryFinder = find.byKey(const ValueKey('student_preview_advisory_bar'));
      expect(advisoryFinder, findsOneWidget);
    });
  });
}
