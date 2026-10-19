import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/auth/presentation/landing_screen.dart';

void main() {
  testWidgets('LandingScreen renders exact reference copy, statistics, and CTA',
      (WidgetTester tester) async {
    // Set test surface size
    tester.view.physicalSize = const Size(1280, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LandingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Headline
    expect(find.text('Precision.\nDesign.\nDelivery.'), findsOneWidget);

    // 2. Subtitle
    expect(
      find.text(
        'Rigorous engineering software for architects and structural designers.',
      ),
      findsOneWidget,
    );

    // 3. CTA button
    expect(find.text('Start Submission'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

    // 4. Exact Reference Statistics
    expect(find.text('PROJECTS ACTIVE'), findsOneWidget);
    expect(find.text('1,204'), findsOneWidget);
    expect(find.text('+12% this week'), findsOneWidget);
    expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);

    expect(find.text('DRAWINGS VERIFIED'), findsOneWidget);
    expect(find.text('8.4k'), findsOneWidget);

    expect(find.text('ENGINEERS JOINED'), findsOneWidget);
    expect(find.text('450+'), findsOneWidget);

    // 5. Watermark icon
    expect(find.byIcon(Icons.architecture_outlined), findsOneWidget);

    // 6. Footer credit
    expect(
      find.text(
        'UI/UX Design & Product Experience crafted by PixelMint Studio MVS',
      ),
      findsOneWidget,
    );

    // 7. Top-right login action
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
  });
}
