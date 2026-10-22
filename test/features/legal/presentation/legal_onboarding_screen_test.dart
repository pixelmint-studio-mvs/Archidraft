import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/legal/domain/legal_document.dart';
import 'package:archi_draft/src/features/legal/domain/user_legal_status.dart';
import 'package:archi_draft/src/features/legal/presentation/legal_onboarding_screen.dart';
import 'package:archi_draft/src/features/legal/providers/legal_providers.dart';

void main() {
  group('LegalOnboardingScreen Widget & Consent Isolation Tests', () {
    final mockTermsDoc = const LegalDocument(
      id: 'doc-terms-v1',
      documentType: 'TERMS_AND_CONDITIONS',
      version: '1.0.0',
      title: 'Platform Terms and Conditions',
      content: 'ARCHI DRAFT Platform terms and user obligations...',
      status: 'EFFECTIVE',
      isMandatory: true,
      effectiveAt: '2026-10-22 00:00:00',
    );

    final mockPrivacyDoc = const LegalDocument(
      id: 'doc-priv-v1',
      documentType: 'PRIVACY_POLICY',
      version: '1.0.0',
      title: 'Platform Privacy Notice',
      content: 'Personal data notice under DPDP Act 2023...',
      status: 'EFFECTIVE',
      isMandatory: false,
      effectiveAt: '2026-10-22 00:00:00',
    );

    final mockPendingLegalStatus = const UserLegalStatus(
      userId: 'test-user-01',
      termsAccepted: false,
      reacceptanceRequired: false,
      latestTermsVersion: '1.0.0',
      privacyNoticeAcknowledged: false,
      optionalConsents: {},
      requiresAction: true,
      hasEffectiveTerms: true,
      missingMandatoryDocs: false,
    );

    testWidgets('Renders onboarding screen with Terms, Privacy Notice, and optional switches defaulting to OFF', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userLegalStatusProvider.overrideWith((ref) => Future.value(mockPendingLegalStatus)),
            effectiveDocumentProvider('TERMS_AND_CONDITIONS').overrideWith((ref) => Future.value(mockTermsDoc)),
            effectiveDocumentProvider('PRIVACY_POLICY').overrideWith((ref) => Future.value(mockPrivacyDoc)),
          ],
          child: const MaterialApp(
            home: LegalOnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen Header
      expect(find.text('Welcome to ARCHI DRAFT'), findsOneWidget);

      // Verify Documents
      expect(find.text('Platform Terms and Conditions'), findsOneWidget);
      expect(find.text('Platform Privacy Notice'), findsOneWidget);

      // Verify Checkboxes
      expect(find.byType(CheckboxListTile), findsNWidgets(2));

      // Verify Optional Switches start with false / OFF
      final switches = tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).toList();
      expect(switches.length, equals(2));
      expect(switches[0].value, isFalse, reason: 'Marketing consent must default to OFF');
      expect(switches[1].value, isFalse, reason: 'Portfolio showcase consent must default to OFF');

      // Verify Button is initially disabled because termsAgreed is false
      final elevatedButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(elevatedButton.onPressed, isNull);
    });

    testWidgets('Tapping Terms checkbox enables Agree & Enter Workspace button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userLegalStatusProvider.overrideWith((ref) => Future.value(mockPendingLegalStatus)),
            effectiveDocumentProvider('TERMS_AND_CONDITIONS').overrideWith((ref) => Future.value(mockTermsDoc)),
            effectiveDocumentProvider('PRIVACY_POLICY').overrideWith((ref) => Future.value(mockPrivacyDoc)),
          ],
          child: const MaterialApp(
            home: LegalOnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Terms checkbox
      final termsCheckbox = find.byType(CheckboxListTile).first;
      await tester.tap(termsCheckbox);
      await tester.pumpAndSettle();

      // Button should now be active
      final elevatedButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(elevatedButton.onPressed, isNotNull);
    });

    testWidgets('Gracefully renders maintenance card when mandatory terms are missing', (WidgetTester tester) async {
      const mockMissingDocsStatus = UserLegalStatus(
        userId: 'test-user-01',
        termsAccepted: false,
        reacceptanceRequired: false,
        privacyNoticeAcknowledged: false,
        optionalConsents: {},
        requiresAction: false,
        hasEffectiveTerms: false,
        missingMandatoryDocs: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userLegalStatusProvider.overrideWith((ref) => Future.value(mockMissingDocsStatus)),
            effectiveDocumentProvider('TERMS_AND_CONDITIONS').overrideWith((ref) => Future.value(null)),
            effectiveDocumentProvider('PRIVACY_POLICY').overrideWith((ref) => Future.value(null)),
          ],
          child: const MaterialApp(
            home: LegalOnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Policy Maintenance in Progress'), findsOneWidget);
      expect(find.text('Check for Updates'), findsOneWidget);
    });
  });
}
