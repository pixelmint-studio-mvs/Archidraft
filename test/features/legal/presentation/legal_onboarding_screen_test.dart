import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/api/data/api_client.dart';
import 'package:archi_draft/src/features/legal/data/legal_repository.dart';
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

    testWidgets('Submission failure displays mapped error message and allows safe retry', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool shouldFail = true;
      final recordedCalls = <Map<String, dynamic>>[];

      final fakeApiClient = FakeApiClient(
        onPost: (path, {body}) {
          recordedCalls.add({'path': path, 'body': body});
          if (shouldFail && path == '/api/legal/acknowledge-privacy') {
            throw Exception('API Error: 400 - {"error":"Target Privacy Notice is not currently effective or does not exist","code":"INVALID_DOCUMENT"}');
          }
          return {'success': true};
        },
        onGet: (path, {queryParams}) {
          if (path == '/api/users/me/legal-status') {
            return {
              'userId': 'test-user-01',
              'termsAccepted': !shouldFail,
              'reacceptanceRequired': false,
              'privacyNoticeAcknowledged': !shouldFail,
              'optionalConsents': {},
              'requiresAction': shouldFail,
              'hasEffectiveTerms': true,
              'missingMandatoryDocs': false,
            };
          }
          return {'documents': []};
        },
      );

      final fakeRepo = LegalRepository(fakeApiClient);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            legalRepositoryProvider.overrideWithValue(fakeRepo),
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

      // Tap Agree & Enter Workspace
      final button = find.widgetWithText(ElevatedButton, 'Agree & Enter Workspace');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      // Verify that error is mapped and displayed on screen, NOT masked as network dropout
      expect(find.textContaining('Legal policy service error'), findsOneWidget);
      expect(find.textContaining('API Error: 400'), findsOneWidget);

      // Verify button is re-enabled so user can retry safely
      final retryButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(retryButton.onPressed, isNotNull);

      // Retry after service issue is resolved
      shouldFail = false;
      await tester.tap(button);
      await tester.pumpAndSettle();

      // Verify all required calls were made
      final postPaths = recordedCalls.map((c) => c['path']).toList();
      expect(postPaths, contains('/api/legal/accept-terms'));
      expect(postPaths, contains('/api/legal/acknowledge-privacy'));
      expect(postPaths, contains('/api/legal/consent'));
    });
  });
}

class FakeApiClient extends Fake implements ApiClient {
  final Map<String, dynamic> Function(String path, {Map<String, dynamic>? body})? onPost;
  final Map<String, dynamic> Function(String path, {Map<String, String>? queryParams})? onGet;

  FakeApiClient({this.onPost, this.onGet});

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    if (onPost != null) {
      return onPost!(path, body: body);
    }
    return {'success': true};
  }

  @override
  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    if (onGet != null) {
      return onGet!(path, queryParams: queryParams);
    }
    return {'success': true};
  }
}
