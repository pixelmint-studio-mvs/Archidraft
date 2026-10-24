import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';

import 'package:archi_draft/src/core/router/app_router.dart';
import 'package:archi_draft/src/features/api/data/api_client.dart';
import 'package:archi_draft/src/features/api/providers/api_providers.dart';
import 'package:archi_draft/src/features/auth/domain/user_profile.dart';
import 'package:archi_draft/src/features/auth/providers/auth_providers.dart';
import 'package:archi_draft/src/features/legal/data/authoritative_policy_content.dart';
import 'package:archi_draft/src/features/legal/data/legal_repository.dart';
import 'package:archi_draft/src/features/legal/domain/legal_document.dart';
import 'package:archi_draft/src/features/legal/domain/user_legal_status.dart';
import 'package:archi_draft/src/features/legal/presentation/legal_onboarding_screen.dart';
import 'package:archi_draft/src/features/legal/providers/legal_providers.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/notifications/providers/notification_providers.dart';
import 'package:archi_draft/src/features/notifications/domain/app_notification.dart';

class MockUser extends Mock implements User {
  @override
  final bool emailVerified;
  @override
  final String email;
  @override
  final String uid;

  MockUser({
    this.emailVerified = true,
    this.email = 'engineer@archidraft.test',
    this.uid = 'usr-eng-01',
  });
}

class FakeApiClient extends Fake implements ApiClient {
  final Map<String, dynamic> Function(String path, {Map<String, String>? queryParams})? onGet;
  final Map<String, dynamic> Function(String path, {Map<String, dynamic>? body})? onPost;

  FakeApiClient({this.onGet, this.onPost});

  @override
  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    if (onGet != null) {
      return onGet!(path, queryParams: queryParams);
    }
    throw Exception('API Error: 404 - Not Found');
  }

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    if (onPost != null) {
      return onPost!(path, body: body);
    }
    return {'success': true};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mockTermsDoc = LegalDocument(
    id: 'doc-terms-v1',
    documentType: 'TERMS_AND_CONDITIONS',
    version: '1.0.0',
    title: 'Platform Terms and Conditions',
    content: '# Terms and Conditions',
    status: 'EFFECTIVE',
    isMandatory: true,
    effectiveAt: '2026-10-24T00:00:00Z',
  );

  const mockPrivacyDoc = LegalDocument(
    id: 'doc-priv-v1',
    documentType: 'PRIVACY_POLICY',
    version: '1.0.0',
    title: 'Platform Privacy Notice',
    content: '# Privacy Policy Content',
    status: 'EFFECTIVE',
    isMandatory: false,
    effectiveAt: '2026-10-24T00:00:00Z',
  );

  const engineerProfile = UserProfile(
    id: 'usr-eng-01',
    email: 'engineer@archidraft.test',
    name: 'Engineer Alice',
    mobile: '9876543210',
    role: 'ENGINEER',
  );

  group('Post-Login Legal Policy Service Investigation & Regression Tests', () {
    test('1. Terms placeholder fallback: trivial # Terms and Conditions content falls back to authoritative content', () async {
      final fakeApi = FakeApiClient(onGet: (path, {queryParams}) {
        if (path.contains('/api/legal/documents/TERMS_AND_CONDITIONS/current')) {
          return {
            'document': {
              'id': 'doc-terms-staging',
              'document_type': 'TERMS_AND_CONDITIONS',
              'version': '1.0.0',
              'title': 'Platform Terms and Conditions',
              'content': '# Terms and Conditions',
              'status': 'EFFECTIVE',
              'is_mandatory': 1,
            }
          };
        }
        throw Exception('API Error: 404 - Not Found');
      });

      final repo = LegalRepository(fakeApi);
      final doc = await repo.getDocument('TERMS_AND_CONDITIONS');

      expect(doc, isNotNull);
      expect(doc!.id, equals('doc-terms-staging'));
      expect(doc.version, equals('1.0.0'));
      expect(doc.content, equals(kAuthoritativeTermsAndConditionsContent));
      expect(doc.content.length, greaterThan(100));
    });

    test('2. Privacy 404 NO_EFFECTIVE_VERSION fallback: returns bundled authoritative privacy document', () async {
      final fakeApi = FakeApiClient(onGet: (path, {queryParams}) {
        if (path.contains('/api/legal/documents/PRIVACY_POLICY/current')) {
          throw Exception('API Error: 404 - {"error":"No effective document found","code":"NO_EFFECTIVE_VERSION"}');
        }
        throw Exception('API Error: 404');
      });

      final repo = LegalRepository(fakeApi);
      final doc = await repo.getDocument('PRIVACY_POLICY');

      expect(doc, isNotNull);
      expect(doc!.documentType, equals('PRIVACY_POLICY'));
      expect(doc.content, equals(kAuthoritativePrivacyPolicyContent));
      expect(doc.version, equals('1.0.0'));
    });

    test('3. Distinguish genuine network failures from HTTP/application errors', () {
      // Network connectivity failures
      expect(
        LegalOnboardingScreen.mapLegalErrorMessage(Exception('SocketException: Connection refused (OS Error: Connection refused, errno = 111)')),
        equals('Unable to reach legal policy service. Please check network connection.'),
      );
      expect(
        LegalOnboardingScreen.mapLegalErrorMessage(Exception('ClientException: XMLHttpRequest error.')),
        equals('Unable to reach legal policy service. Please check network connection.'),
      );
      expect(
        LegalOnboardingScreen.mapLegalErrorMessage(Exception('Connection reset by peer (500)')),
        equals('Unable to reach legal policy service. Please check network connection.'),
      );
      expect(
        LegalOnboardingScreen.mapLegalErrorMessage(TimeoutException('Request timed out')),
        equals('Unable to reach legal policy service. Please check network connection.'),
      );

      // HTTP / Application level errors
      final http404 = LegalOnboardingScreen.mapLegalErrorMessage(Exception('API Error: 404 - {"error":"User not found"}'));
      expect(http404, contains('Legal policy service error'));
      expect(http404, isNot(equals('Unable to reach legal policy service. Please check network connection.')));

      final http500 = LegalOnboardingScreen.mapLegalErrorMessage(Exception('API Error: 500 - Internal Server Error'));
      expect(http500, contains('Legal policy service error'));
    });

    test('4. userLegalStatusProvider safely returns default unauthenticated status before login without throwing', () async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(const AsyncValue.data(null)),
        ],
      );
      addTearDown(container.dispose);

      final status = await container.read(userLegalStatusProvider.future);
      expect(status.userId, isEmpty);
      expect(status.termsAccepted, isFalse);
      expect(status.requiresAction, isFalse);
      expect(status.missingMandatoryDocs, isFalse);
    });

    test('5. userLegalStatusProvider reactively fetches legal status when auth state emits user', () async {
      final authController = StreamController<User?>();
      addTearDown(authController.close);

      final fakeApi = FakeApiClient(onGet: (path, {queryParams}) {
        if (path.contains('/api/users/me/legal-status')) {
          return {
            'userId': 'usr-eng-01',
            'termsAccepted': true,
            'reacceptanceRequired': false,
            'acceptedTermsVersion': '1.0.0',
            'latestTermsVersion': '1.0.0',
            'privacyNoticeAcknowledged': true,
            'requiresAction': false,
            'hasEffectiveTerms': true,
            'missingMandatoryDocs': false,
          };
        }
        throw Exception('API Error: 404');
      });

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => authController.stream),
          apiClientProvider.overrideWithValue(fakeApi),
        ],
      );
      addTearDown(container.dispose);

      final statusList = <UserLegalStatus>[];
      container.listen<AsyncValue<UserLegalStatus>>(
        userLegalStatusProvider,
        (previous, next) {
          if (next.hasValue) statusList.add(next.value!);
        },
        fireImmediately: true,
      );

      // 1. Initial unauthenticated state
      authController.add(null);
      await pumpEventQueue();
      expect(statusList.last.userId, isEmpty);

      // 2. User logs in
      final mockUser = MockUser();
      authController.add(mockUser);
      await pumpEventQueue();

      expect(statusList.last.userId, equals('usr-eng-01'));
      expect(statusList.last.termsAccepted, isTrue);
      expect(statusList.last.requiresAction, isFalse);
    });

    testWidgets('6. Successful authentication with valid legal state routes directly to role dashboard without returning to /legal/onboarding', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockUser = MockUser();
      const compliantStatus = UserLegalStatus(
        userId: 'usr-eng-01',
        termsAccepted: true,
        reacceptanceRequired: false,
        acceptedTermsVersion: '1.0.0',
        latestTermsVersion: '1.0.0',
        privacyNoticeAcknowledged: true,
        optionalConsents: {},
        requiresAction: false,
        hasEffectiveTerms: true,
        missingMandatoryDocs: false,
      );

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(AsyncValue.data(mockUser)),
          userProfileProvider.overrideWithValue(const AsyncValue.data(engineerProfile)),
          userLegalStatusProvider.overrideWithValue(const AsyncValue.data(compliantStatus)),
          effectiveDocumentProvider('TERMS_AND_CONDITIONS').overrideWithValue(const AsyncValue.data(mockTermsDoc)),
          effectiveDocumentProvider('PRIVACY_POLICY').overrideWithValue(const AsyncValue.data(mockPrivacyDoc)),
          engineerProjectsProvider.overrideWithValue(const AsyncValue.data(<Project>[])),
          notificationsProvider.overrideWithValue(const AsyncValue.data(<AppNotification>[])),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Directly on engineer projects dashboard
      expect(router.state.matchedLocation, equals('/engineer/projects'));
      expect(find.byType(LegalOnboardingScreen), findsNothing);
    });

    testWidgets('7. Authenticated user requiring action lands on onboarding screen with form enabled, NOT service error', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockUser = MockUser();
      const pendingStatus = UserLegalStatus(
        userId: 'usr-eng-01',
        termsAccepted: false,
        reacceptanceRequired: false,
        latestTermsVersion: '1.0.0',
        privacyNoticeAcknowledged: false,
        optionalConsents: {},
        requiresAction: true,
        hasEffectiveTerms: true,
        missingMandatoryDocs: false,
      );

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(AsyncValue.data(mockUser)),
          userProfileProvider.overrideWithValue(const AsyncValue.data(engineerProfile)),
          userLegalStatusProvider.overrideWithValue(const AsyncValue.data(pendingStatus)),
          effectiveDocumentProvider('TERMS_AND_CONDITIONS').overrideWithValue(const AsyncValue.data(mockTermsDoc)),
          effectiveDocumentProvider('PRIVACY_POLICY').overrideWithValue(const AsyncValue.data(mockPrivacyDoc)),
          engineerProjectsProvider.overrideWithValue(const AsyncValue.data(<Project>[])),
          notificationsProvider.overrideWithValue(const AsyncValue.data(<AppNotification>[])),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, equals('/legal/onboarding'));
      expect(find.byType(LegalOnboardingScreen), findsOneWidget);
      expect(find.text('Welcome to ARCHI DRAFT'), findsOneWidget);
      expect(find.text('Agree & Enter Workspace'), findsOneWidget);
      expect(find.text('Unable to reach legal policy service. Please check network connection.'), findsNothing);
    });

    testWidgets('8. HTTP error from legal status displays differentiated service error, not generic network error', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockUser = MockUser();

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(AsyncValue.data(mockUser)),
          userProfileProvider.overrideWithValue(const AsyncValue.data(engineerProfile)),
          userLegalStatusProvider.overrideWithValue(AsyncValue.error(
            Exception('API Error: 500 - {"error":"D1 query execution failed"}'),
            StackTrace.empty,
          )),
          effectiveDocumentProvider('TERMS_AND_CONDITIONS').overrideWithValue(const AsyncValue.data(mockTermsDoc)),
          effectiveDocumentProvider('PRIVACY_POLICY').overrideWithValue(const AsyncValue.data(mockPrivacyDoc)),
          engineerProjectsProvider.overrideWithValue(const AsyncValue.data(<Project>[])),
          notificationsProvider.overrideWithValue(const AsyncValue.data(<AppNotification>[])),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, equals('/legal/onboarding'));
      expect(find.textContaining('Legal policy service error'), findsOneWidget);
      expect(find.text('Unable to reach legal policy service. Please check network connection.'), findsNothing);
    });

    testWidgets('9. Optional preferences remain OFF by default and do not block entering workspace', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockUser = MockUser();
      const pendingStatus = UserLegalStatus(
        userId: 'usr-eng-01',
        termsAccepted: false,
        reacceptanceRequired: false,
        latestTermsVersion: '1.0.0',
        privacyNoticeAcknowledged: false,
        optionalConsents: {},
        requiresAction: true,
        hasEffectiveTerms: true,
        missingMandatoryDocs: false,
      );

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(AsyncValue.data(mockUser)),
          userProfileProvider.overrideWithValue(const AsyncValue.data(engineerProfile)),
          userLegalStatusProvider.overrideWithValue(const AsyncValue.data(pendingStatus)),
          effectiveDocumentProvider('TERMS_AND_CONDITIONS').overrideWithValue(const AsyncValue.data(mockTermsDoc)),
          effectiveDocumentProvider('PRIVACY_POLICY').overrideWithValue(const AsyncValue.data(mockPrivacyDoc)),
          engineerProjectsProvider.overrideWithValue(const AsyncValue.data(<Project>[])),
          notificationsProvider.overrideWithValue(const AsyncValue.data(<AppNotification>[])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LegalOnboardingScreen(isPreLogin: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check switches
      final switches = tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).toList();
      expect(switches.length, equals(2));
      expect(switches[0].value, isFalse);
      expect(switches[1].value, isFalse);

      // Agreeing only to Terms is sufficient to enable Enter Workspace button
      final termsCheckbox = find.byType(CheckboxListTile).first;
      await tester.tap(termsCheckbox);
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });
  });
}
