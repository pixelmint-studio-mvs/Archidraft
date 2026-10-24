import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/legal/presentation/legal_onboarding_screen.dart';
import 'package:archi_draft/src/features/legal/presentation/widgets/legal_markdown_viewer.dart';
import 'package:archi_draft/src/features/legal/providers/legal_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Legal Policy Typography & Markdown Rendering Tests', () {
    testWidgets('1. LegalMarkdownViewer renders body text in bold with AppTypography.bodySm font', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LegalMarkdownViewer(
                markdown: '''# Test Title
## 1. Test Section
This is a bold body paragraph explaining terms.
- Bullet item one with **important** text.
- Bullet item two.
''',
                isBold: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the viewer
      expect(find.byType(LegalMarkdownViewer), findsOneWidget);

      // Verify headings
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('1. Test Section'), findsOneWidget);

      // Verify no raw markdown asterisks or bullet dashes appear in rendered text
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      for (final tw in textWidgets) {
        if (tw.textSpan != null) {
          tw.textSpan!.visitChildren((span) {
            if (span is TextSpan && span.text != null) {
              expect(span.text!.contains('**'), isFalse, reason: 'Raw ** in ${span.text}');
              expect(span.style?.fontWeight, anyOf(equals(FontWeight.w700), equals(FontWeight.w900)));
            }
            return true;
          });
        }
      }
    });

    testWidgets('2. Pre-login onboarding screen renders both policy expandable sections with bold body typography', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectiveDocumentProvider('TERMS_AND_CONDITIONS').overrideWith((ref) => Future.value(null)),
            effectiveDocumentProvider('PRIVACY_POLICY').overrideWith((ref) => Future.value(null)),
          ],
          child: const MaterialApp(
            home: LegalOnboardingScreen(
              isPreLogin: true,
              preLoginRole: 'engineer',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Terms tile starts expanded by default
      expect(find.byType(LegalMarkdownViewer), findsOneWidget);

      // Expand Privacy Policy tile
      final privacyFinder = find.widgetWithText(ExpansionTile, 'Privacy Policy');
      expect(privacyFinder, findsOneWidget);
      await tester.tap(privacyFinder);
      await tester.pumpAndSettle();

      // Both expansion tiles now have mounted LegalMarkdownViewer instances
      expect(find.byType(LegalMarkdownViewer), findsNWidgets(2));

      // Verify that raw ** is completely absent from all rendered text spans
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      int boldBodySpanCount = 0;
      for (final tw in textWidgets) {
        if (tw.textSpan != null) {
          tw.textSpan!.visitChildren((span) {
            if (span is TextSpan && span.text != null && span.text!.trim().isNotEmpty) {
              expect(span.text!.contains('**'), isFalse, reason: 'Found raw ** in span: "${span.text}"');
              if (span.style?.fontWeight == FontWeight.w700 || span.style?.fontWeight == FontWeight.w900) {
                boldBodySpanCount++;
              }
            }
            return true;
          });
        }
      }
      expect(boldBodySpanCount, greaterThan(20), reason: 'Expected multiple bold spans in rendered policy sections');

      // Verify substantive clauses are present in rendered output
      expect(find.text('ARCHI DRAFT — TERMS & CONDITIONS'), findsOneWidget);
      expect(find.text('ARCHI DRAFT — PRIVACY POLICY'), findsOneWidget);
      expect(find.text('1. INTRODUCTION AND ACCEPTANCE'), findsOneWidget);
      expect(find.text('1. INTRODUCTION AND ORGANIZATION IDENTITY'), findsOneWidget);

      // Verify draft status is present and unapproved
      expect(find.textContaining('DOCUMENT STATUS:'), findsWidgets);
      expect(find.textContaining('DRAFT — NOT APPROVED FOR PRODUCTION'), findsWidgets);
    });

    testWidgets('3. Unrelated UI elements, badges, checkboxes, and preferences remain unchanged', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectiveDocumentProvider('TERMS_AND_CONDITIONS').overrideWith((ref) => Future.value(null)),
            effectiveDocumentProvider('PRIVACY_POLICY').overrideWith((ref) => Future.value(null)),
          ],
          child: const MaterialApp(
            home: LegalOnboardingScreen(
              isPreLogin: true,
              preLoginRole: 'draughtsman',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check version badges
      expect(find.text('v1.0.0'), findsNWidgets(2));

      // Check section titles
      expect(find.text('Terms and Conditions'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);

      // Check checkboxes
      expect(find.byType(CheckboxListTile), findsNWidgets(2));
      final termsCb = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile).first);
      expect(termsCb.value, isFalse);

      // Check switches (default off)
      expect(find.byType(SwitchListTile), findsNWidgets(2));
      for (final s in tester.widgetList<SwitchListTile>(find.byType(SwitchListTile))) {
        expect(s.value, isFalse);
      }

      // Check pre-login action button
      expect(find.text('Agree & Continue to Login'), findsOneWidget);
    });
  });
}
