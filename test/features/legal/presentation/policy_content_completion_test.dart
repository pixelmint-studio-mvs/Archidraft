import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/legal/data/authoritative_policy_content.dart';
import 'package:archi_draft/src/features/legal/domain/legal_document.dart';
import 'package:archi_draft/src/features/legal/presentation/legal_onboarding_screen.dart';
import 'package:archi_draft/src/features/legal/providers/legal_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Authoritative Policy Content Integrity & Safeguard Tests', () {
    test('1. Terms and Conditions text contains expected authoritative clauses', () {
      expect(kAuthoritativeTermsAndConditionsContent, contains('PLATFORM TERMS AND CONDITIONS'));
      expect(kAuthoritativeTermsAndConditionsContent, contains('1. PLATFORM SCOPE AND SERVICES'));
      expect(kAuthoritativeTermsAndConditionsContent, contains('4. PROFESSIONAL AND ROLE-SPECIFIC RESPONSIBILITIES'));
      expect(kAuthoritativeTermsAndConditionsContent, contains('Client / Consulting Engineer Responsibilities'));
      expect(kAuthoritativeTermsAndConditionsContent, contains('Draughtsman Responsibilities'));
      expect(kAuthoritativeTermsAndConditionsContent, contains('Student Responsibilities'));
      expect(kAuthoritativeTermsAndConditionsContent, contains('8. REVISION CYCLES AND SCOPE BOUNDARIES'));
      expect(kAuthoritativeTermsAndConditionsContent, contains('6. INTELLECTUAL PROPERTY AND CAD OWNERSHIP'));
      expect(kAuthoritativeTermsAndConditionsContent, contains('12. GRIEVANCE REDRESSAL AND GOVERNING LAW'));
      expect(kAuthoritativeTermsVersion, equals('1.0.0'));
      expect(kAuthoritativeTermsTitle, equals('Platform Terms and Conditions'));
    });

    test('2. Privacy Policy text contains expected authoritative clauses', () {
      expect(kAuthoritativePrivacyPolicyContent, contains('PRIVACY POLICY & DATA PROTECTION NOTICE'));
      expect(kAuthoritativePrivacyPolicyContent, contains('1. DATA FIDUCIARY IDENTITY'));
      expect(kAuthoritativePrivacyPolicyContent, contains('DPDP Act'));
      expect(kAuthoritativePrivacyPolicyContent, contains('3. CATEGORIES OF PERSONAL DATA COLLECTED'));
      expect(kAuthoritativePrivacyPolicyContent, contains('6. STATUTORY LOG RETENTION VS. OPERATIONAL ARCHIVES'));
      expect(kAuthoritativePrivacyPolicyContent, contains('7. SAFEGUARDS FOR STUDENT USERS AND MINORS (<18 YEARS)'));
      expect(kAuthoritativePrivacyPolicyContent, contains('9. HOW TO EXERCISE YOUR RIGHTS & GRIEVANCE REDRESSAL'));
      expect(kAuthoritativePrivacyVersion, equals('1.0.0'));
      expect(kAuthoritativePrivacyTitle, equals('Privacy Policy & Data Protection Notice'));
    });

    testWidgets('3. Pre-login onboarding screen populates and displays authoritative Terms and Privacy Policy', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
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
              preLoginRole: 'ENGINEER',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Headers and Version Badges
      expect(find.text(kAuthoritativeTermsTitle), findsOneWidget);
      expect(find.text('v1.0.0'), findsNWidgets(2)); // Both Terms and Privacy preview badges

      // Verify Terms content is populated and displayed
      expect(find.textContaining('1. PLATFORM SCOPE AND SERVICES'), findsOneWidget);

      // Privacy tile starts collapsed by default
      expect(find.text(kAuthoritativePrivacyTitle), findsOneWidget);

      // Expand Privacy tile
      final privacyTile = find.widgetWithText(ExpansionTile, kAuthoritativePrivacyTitle);
      await tester.tap(privacyTile);
      await tester.pumpAndSettle();

      // Verify Privacy Policy content is readable when expanded
      expect(find.textContaining('1. DATA FIDUCIARY IDENTITY'), findsOneWidget);
      expect(find.textContaining('DPDP Act'), findsWidgets);
    });

    testWidgets('4. Placeholder or trivial server content falls back to authoritative policy content', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const trivialTermsDoc = LegalDocument(
        id: 'doc-terms-trivial',
        documentType: 'TERMS_AND_CONDITIONS',
        version: '1.0.0',
        title: 'Platform Terms',
        content: '# Terms and Conditions', // Trivial server placeholder
        status: 'EFFECTIVE',
        isMandatory: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectiveDocumentProvider('TERMS_AND_CONDITIONS').overrideWith((ref) => Future.value(trivialTermsDoc)),
            effectiveDocumentProvider('PRIVACY_POLICY').overrideWith((ref) => Future.value(null)),
          ],
          child: const MaterialApp(
            home: LegalOnboardingScreen(
              isPreLogin: true,
              preLoginRole: 'DRAUGHTSMAN',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify full authoritative text is displayed rather than the 22-character placeholder
      expect(find.textContaining('4.2. Draughtsman Responsibilities'), findsOneWidget);
      expect(find.textContaining('6. INTELLECTUAL PROPERTY AND CAD OWNERSHIP'), findsOneWidget);
    });

    testWidgets('5. Consent behavior, checkboxes, and optional preference defaults remain strictly intact', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
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
              preLoginRole: 'STUDENT',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Checkboxes exist
      expect(find.byType(CheckboxListTile), findsNWidgets(2));

      // Optional preference switches exist and default to OFF
      final switches = tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).toList();
      expect(switches.length, equals(2));
      expect(switches[0].value, isFalse, reason: 'Marketing communications must default to OFF');
      expect(switches[1].value, isFalse, reason: 'Portfolio showcase must default to OFF');

      // Agree button disabled until Terms checkbox is checked
      final buttonFinder = find.widgetWithText(ElevatedButton, 'Agree & Continue to Login');
      expect(buttonFinder, findsOneWidget);
      var button = tester.widget<ElevatedButton>(buttonFinder);
      expect(button.onPressed, isNull);

      // Tap Terms checkbox
      final termsCheckbox = find.byType(CheckboxListTile).first;
      await tester.tap(termsCheckbox);
      await tester.pumpAndSettle();

      // Button is now enabled
      button = tester.widget<ElevatedButton>(buttonFinder);
      expect(button.onPressed, isNotNull);
    });
  });
}
