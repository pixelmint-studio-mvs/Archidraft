import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archi_draft/src/features/api/data/api_client.dart';
import 'package:archi_draft/src/features/api/providers/api_providers.dart';
import 'package:archi_draft/src/features/projects/presentation/widgets/cad_drawing_viewer.dart';

class FakeCadApiClient extends Fake implements ApiClient {
  final Map<String, Uint8List> mockResponses;

  FakeCadApiClient(this.mockResponses);

  @override
  Future<Uint8List> downloadBinary(String path) async {
    if (mockResponses.containsKey(path)) {
      return mockResponses[path]!;
    }
    throw Exception('404 Not Found: $path');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CadDrawingViewer Widget Tests', () {
    testWidgets('Renders real DWG drawing geometry preview with zoom & pan controls', (tester) async {
      final dwgFile = File('assets/images/architectural_-_annotation_scaling_and_multileaders.dwg');
      expect(dwgFile.existsSync(), isTrue);
      final dwgBytes = dwgFile.readAsBytesSync();

      final fakeClient = FakeCadApiClient({
        '/api/files/test-dwg-file-id/download': dwgBytes,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(fakeClient),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CadDrawingViewer(
                fileId: 'test-dwg-file-id',
                fileName: 'architectural_-_annotation_scaling_and_multileaders.dwg',
                fileSize: 188992,
                versionNumber: 1,
              ),
            ),
          ),
        ),
      );

      // Loading state
      expect(find.text('Loading CAD drawing geometry...'), findsOneWidget);

      await tester.pumpAndSettle();

      // Verified DWG header and badge
      expect(find.text('AutoCAD DWG \u2022 Geometry Preview'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsWidgets);
      expect(find.byType(Image), findsOneWidget);

      // Verify zoom and fit controls
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      expect(find.byIcon(Icons.fit_screen_rounded), findsOneWidget);

      // Test Zoom In interaction
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      // Test Zoom Out interaction
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pumpAndSettle();

      // Test Reset / Fit interaction
      await tester.tap(find.byIcon(Icons.fit_screen_rounded));
      await tester.pumpAndSettle();
    });

    testWidgets('Renders 2D DXF vector drawing with custom painter', (tester) async {
      const sampleDxf = '''0
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
150.0
21
100.0
0
CIRCLE
10
250.0
20
200.0
40
50.0
0
ENDSEC
0
EOF''';
      final dxfBytes = Uint8List.fromList(utf8.encode(sampleDxf));

      final fakeClient = FakeCadApiClient({
        '/api/files/test-dxf-file-id/download': dxfBytes,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(fakeClient),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CadDrawingViewer(
                fileId: 'test-dxf-file-id',
                fileName: 'floorplan_sheet_a1.dxf',
                fileSize: 1024,
                versionNumber: 2,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('AutoCAD DXF \u2022 2D Vector CAD'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsWidgets);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('Displays clear error state and download fallback for unsupported files', (tester) async {
      final corruptBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);

      final fakeClient = FakeCadApiClient({
        '/api/files/test-corrupt-file-id/download': corruptBytes,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(fakeClient),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CadDrawingViewer(
                fileId: 'test-corrupt-file-id',
                fileName: 'unknown_document.xyz',
                fileSize: 4,
                versionNumber: 1,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Preview unavailable for .xyz format'), findsOneWidget);
      expect(find.text('Download Original File'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Renders PDF vector sheet drawing with embedded viewer and controls', (tester) async {
      final pdfBytes = Uint8List.fromList(utf8.encode('%PDF-1.4 mock pdf content for architectural blueprint'));

      final fakeClient = FakeCadApiClient({
        '/api/files/test-pdf-file-id/download': pdfBytes,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(fakeClient),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CadDrawingViewer(
                fileId: 'test-pdf-file-id',
                fileName: 'site_plan_approval.pdf',
                fileSize: 1024,
                versionNumber: 3,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('PDF Document \u2022 Vector Sheet'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf_rounded), findsWidgets);
      expect(find.text('site_plan_approval.pdf'), findsOneWidget);
    });
  });
}