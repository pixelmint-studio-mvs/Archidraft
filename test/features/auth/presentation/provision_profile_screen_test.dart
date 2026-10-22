import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/auth/presentation/provision_profile_screen.dart';

void main() {
  Widget buildTestWidget({Size size = const Size(800, 1000)}) {
    return ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: ProvisionProfileScreen(
            onProvisioned: () {},
          ),
        ),
      ),
    );
  }

  group('ProvisionProfileScreen UI Tests', () {
    testWidgets('renders all 3 account types: ENGINEER, DRAUGHTSMAN, STUDENT', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('ACCOUNT TYPE'), findsOneWidget);
      expect(find.text('ENGINEER'), findsOneWidget);
      expect(find.text('DRAUGHTSMAN'), findsOneWidget);
      expect(find.text('STUDENT'), findsOneWidget);
      expect(find.text('PROVISION PROFILE'), findsOneWidget);
    });

    testWidgets('DRAUGHTSMAN label is rendered without line wrapping', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final draughtsmanFinder = find.text('DRAUGHTSMAN');
      expect(draughtsmanFinder, findsOneWidget);

      final Text textWidget = tester.widget<Text>(draughtsmanFinder);
      expect(textWidget.maxLines, 1);
      expect(textWidget.softWrap, false);
    });

    testWidgets('role selection switches active segment', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap DRAUGHTSMAN
      await tester.tap(find.text('DRAUGHTSMAN'));
      await tester.pumpAndSettle();

      // Tap STUDENT
      await tester.tap(find.text('STUDENT'));
      await tester.pumpAndSettle();

      // Tap ENGINEER
      await tester.tap(find.text('ENGINEER'));
      await tester.pumpAndSettle();
    });
  });

  group('ProvisionProfileScreen Responsive Viewport Tests', () {
    final viewports = <String, Size>{
      '360x800': const Size(360, 800),
      '390x844': const Size(390, 844),
      '768x1024': const Size(768, 1024),
      '1920x1080': const Size(1920, 1080),
    };

    for (final entry in viewports.entries) {
      testWidgets('renders cleanly without overflow at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestWidget(size: entry.value));
        await tester.pumpAndSettle();

        expect(find.text('ACCOUNT TYPE'), findsOneWidget);
        expect(find.text('ENGINEER'), findsOneWidget);
        expect(find.text('DRAUGHTSMAN'), findsOneWidget);
        expect(find.text('STUDENT'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
