import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CAD Viewer Viewport-Centered Zoom Math & Clamping Tests', () {
    test('1. Centered zoom scales around (cx, cy) without shifting center point', () {
      const cx = 300.0;
      const cy = 200.0;
      const factor = 1.3;

      final currentMatrix = Matrix4.identity();
      final currentScale = currentMatrix.storage[0].abs() > 0.0001
          ? currentMatrix.storage[0].abs()
          : currentMatrix.getMaxScaleOnAxis();
      final targetScale = (currentScale * factor).clamp(0.1, 25.0);
      final actualFactor = targetScale / currentScale;

      final translationToCenter = Matrix4.translationValues(cx, cy, 0);
      final scaleMatrix = Matrix4.diagonal3Values(actualFactor, actualFactor, 1.0);
      final translationBack = Matrix4.translationValues(-cx, -cy, 0);

      final newMatrix = translationToCenter * scaleMatrix * translationBack * currentMatrix;

      // 1. 2D Scale must equal factor
      expect(newMatrix.storage[0].abs(), closeTo(1.3, 0.001));

      // 2. The center point (cx, cy) transformed through newMatrix must remain at (cx, cy)
      final transformedCenter = MatrixUtils.transformPoint(newMatrix, const Offset(cx, cy));
      expect(transformedCenter.dx, closeTo(cx, 0.001));
      expect(transformedCenter.dy, closeTo(cy, 0.001));
    });

    test('2. Centered zoom out decreases scale while maintaining center', () {
      const cx = 400.0;
      const cy = 300.0;
      const factor = 0.77;

      final currentMatrix = Matrix4.identity();
      final currentScale = currentMatrix.storage[0].abs() > 0.0001
          ? currentMatrix.storage[0].abs()
          : currentMatrix.getMaxScaleOnAxis();
      final targetScale = (currentScale * factor).clamp(0.1, 25.0);
      final actualFactor = targetScale / currentScale;

      final translationToCenter = Matrix4.translationValues(cx, cy, 0);
      final scaleMatrix = Matrix4.diagonal3Values(actualFactor, actualFactor, 1.0);
      final translationBack = Matrix4.translationValues(-cx, -cy, 0);

      final newMatrix = translationToCenter * scaleMatrix * translationBack * currentMatrix;

      expect(newMatrix.storage[0].abs(), closeTo(0.77, 0.001));

      final transformedCenter = MatrixUtils.transformPoint(newMatrix, const Offset(cx, cy));
      expect(transformedCenter.dx, closeTo(cx, 0.001));
      expect(transformedCenter.dy, closeTo(cy, 0.001));
    });

    test('3. Zoom scale clamps to maximum limit (25.0)', () {
      var currentMatrix = Matrix4.identity();
      const cx = 250.0;
      const cy = 200.0;

      // Zoom in 20 times with factor 1.3
      for (int i = 0; i < 20; i++) {
        final currentScale = currentMatrix.storage[0].abs() > 0.0001
            ? currentMatrix.storage[0].abs()
            : currentMatrix.getMaxScaleOnAxis();
        final targetScale = (currentScale * 1.3).clamp(0.1, 25.0);
        final actualFactor = targetScale / currentScale;
        if ((actualFactor - 1.0).abs() < 0.001) break;

        final translationToCenter = Matrix4.translationValues(cx, cy, 0);
        final scaleMatrix = Matrix4.diagonal3Values(actualFactor, actualFactor, 1.0);
        final translationBack = Matrix4.translationValues(-cx, -cy, 0);
        currentMatrix = translationToCenter * scaleMatrix * translationBack * currentMatrix;
      }

      expect(currentMatrix.storage[0].abs(), closeTo(25.0, 0.001));
      expect(currentMatrix.storage[0].abs(), lessThanOrEqualTo(25.0));
    });

    test('4. Zoom scale clamps to minimum limit (0.1)', () {
      var currentMatrix = Matrix4.identity();
      const cx = 250.0;
      const cy = 200.0;

      // Zoom out 20 times with factor 0.77
      for (int i = 0; i < 20; i++) {
        final currentScale = currentMatrix.storage[0].abs() > 0.0001
            ? currentMatrix.storage[0].abs()
            : currentMatrix.getMaxScaleOnAxis();
        final targetScale = (currentScale * 0.77).clamp(0.1, 25.0);
        final actualFactor = targetScale / currentScale;
        if ((actualFactor - 1.0).abs() < 0.001) break;

        final translationToCenter = Matrix4.translationValues(cx, cy, 0);
        final scaleMatrix = Matrix4.diagonal3Values(actualFactor, actualFactor, 1.0);
        final translationBack = Matrix4.translationValues(-cx, -cy, 0);
        currentMatrix = translationToCenter * scaleMatrix * translationBack * currentMatrix;
      }

      expect(currentMatrix.storage[0].abs(), closeTo(0.1, 0.001));
      expect(currentMatrix.storage[0].abs(), greaterThanOrEqualTo(0.1));
    });
  });

  group('InteractiveViewer External Controller Wiring Tests', () {
    testWidgets('5. TransformationController controls InteractiveViewer zoom programmatically', (tester) async {
      final controller = TransformationController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 400,
              child: InteractiveViewer(
                transformationController: controller,
                minScale: 0.1,
                maxScale: 25.0,
                child: Container(
                  width: 500,
                  height: 400,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      expect(controller.value.storage[0].abs(), equals(1.0));

      // Zoom in programmatically
      const cx = 250.0;
      const cy = 200.0;
      const factor = 1.3;
      final tIn = Matrix4.translationValues(cx, cy, 0);
      final s = Matrix4.diagonal3Values(factor, factor, 1.0);
      final tOut = Matrix4.translationValues(-cx, -cy, 0);
      controller.value = tIn * s * tOut * controller.value;

      await tester.pump();
      expect(controller.value.storage[0].abs(), closeTo(1.3, 0.001));

      // Reset
      controller.value = Matrix4.identity();
      await tester.pump();
      expect(controller.value.storage[0].abs(), equals(1.0));
    });

    testWidgets('6. Fullscreen modal dialog dismisses cleanly without breaking root navigator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    useRootNavigator: true,
                    builder: (dialogContext) => Dialog.fullscreen(
                      child: Scaffold(
                        appBar: AppBar(
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: 'Exit fullscreen',
                              onPressed: () => Navigator.of(dialogContext).pop(),
                            ),
                          ],
                        ),
                        body: const Center(child: Text('Fullscreen CAD Canvas')),
                      ),
                    ),
                  );
                },
                child: const Text('Open Fullscreen'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Open Fullscreen'), findsOneWidget);
      expect(find.text('Fullscreen CAD Canvas'), findsNothing);

      // Open fullscreen
      await tester.tap(find.text('Open Fullscreen'));
      await tester.pumpAndSettle();

      expect(find.text('Fullscreen CAD Canvas'), findsOneWidget);
      expect(find.byTooltip('Exit fullscreen'), findsOneWidget);

      // Dismiss fullscreen
      await tester.tap(find.byTooltip('Exit fullscreen'));
      await tester.pumpAndSettle();

      expect(find.text('Fullscreen CAD Canvas'), findsNothing);
      expect(find.text('Open Fullscreen'), findsOneWidget);
    });
  });
}
