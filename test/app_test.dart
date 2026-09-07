import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:archi_draft/main.dart';

void main() {
  testWidgets('ArchiDraftApp renders without crashing', (
    WidgetTester tester,
  ) async {
    // Build the app inside ProviderScope (matching main.dart).
    await tester.pumpWidget(
      const ProviderScope(child: ArchiDraftApp()),
    );

    // Verify the app title text is present on the home screen.
    expect(find.text('Archi Draft'), findsWidgets);

    // Verify the welcome message is displayed.
    expect(find.text('Welcome to Archi Draft'), findsOneWidget);
  });

  testWidgets('ArchiDraftApp uses Material 3', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ArchiDraftApp()),
    );

    // Verify Material 3 is active by checking the MaterialApp.router exists.
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme?.useMaterial3, isTrue);
  });
}
