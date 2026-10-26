import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/shared/widgets/hexagonal_monogram_3d_viewer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HexagonalMonogram3DViewer Rotation Policy & Reduced Motion Tests', () {
    testWidgets('renders under default policy (respectReducedMotion: false)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HexagonalMonogram3DViewer(
              width: 80,
              height: 80,
              autoRotate: true,
              rotationSpeed: '36deg',
            ),
          ),
        ),
      );

      expect(find.byType(HexagonalMonogram3DViewer), findsOneWidget);
      final viewerWidget = tester.widget<HexagonalMonogram3DViewer>(
        find.byType(HexagonalMonogram3DViewer),
      );
      expect(viewerWidget.autoRotate, isTrue);
      expect(viewerWidget.respectReducedMotion, isFalse);
    });

    testWidgets(
        'default policy preserves autoRotate=true even when MediaQuery.disableAnimations is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: HexagonalMonogram3DViewer(
                width: 80,
                height: 80,
                autoRotate: true,
                respectReducedMotion: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(HexagonalMonogram3DViewer), findsOneWidget);
      final viewerWidget = tester.widget<HexagonalMonogram3DViewer>(
        find.byType(HexagonalMonogram3DViewer),
      );
      expect(viewerWidget.autoRotate, isTrue);
      expect(viewerWidget.respectReducedMotion, isFalse);
    });

    testWidgets(
        'explicit respectReducedMotion: true respects MediaQuery.disableAnimations',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: HexagonalMonogram3DViewer(
                width: 80,
                height: 80,
                autoRotate: true,
                respectReducedMotion: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(HexagonalMonogram3DViewer), findsOneWidget);
      final viewerWidget = tester.widget<HexagonalMonogram3DViewer>(
        find.byType(HexagonalMonogram3DViewer),
      );
      expect(viewerWidget.autoRotate, isTrue);
      expect(viewerWidget.respectReducedMotion, isTrue);
    });

    testWidgets('renders fallback image when asset loading throws error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HexagonalMonogram3DViewer(
              width: 60,
              height: 60,
              assetPath: 'invalid/nonexistent/model.glb',
              fallbackImagePath: 'assets/images/draughtsman_logo.jpeg',
            ),
          ),
        ),
      );

      expect(find.byType(HexagonalMonogram3DViewer), findsOneWidget);
    });
  });
}
