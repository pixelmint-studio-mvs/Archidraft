import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';

import 'package:archi_draft/src/core/router/app_router.dart';
import 'package:archi_draft/src/features/auth/domain/user_profile.dart';
import 'package:archi_draft/src/features/auth/providers/auth_providers.dart';
import 'package:archi_draft/src/features/legal/domain/legal_document.dart';
import 'package:archi_draft/src/features/legal/domain/user_legal_status.dart';
import 'package:archi_draft/src/features/legal/presentation/legal_onboarding_screen.dart';
import 'package:archi_draft/src/features/legal/providers/legal_providers.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/domain/admin_dashboard_metrics.dart';
import 'package:archi_draft/src/features/projects/providers/admin_providers.dart';
import 'package:archi_draft/src/features/notifications/providers/notification_providers.dart';
import 'package:archi_draft/src/features/notifications/domain/app_notification.dart';

class MockUser extends Mock implements User {
  final bool _emailVerified;
  final String _email;
  final String _uid;

  MockUser({
    bool emailVerified = true,
    String email = 'engineer@archi-draft.com',
    String uid = 'usr-eng-01',
  })  : _emailVerified = emailVerified, // ignore: prefer_initializing_formals
        _email = email, // ignore: prefer_initializing_formals
        _uid = uid; // ignore: prefer_initializing_formals

  @override
  bool get emailVerified => _emailVerified;

  @override
  String? get email => _email;

  @override
  String get uid => _uid;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mockTermsDoc = LegalDocument(
    id: 'doc-terms-v1',
    documentType: 'TERMS_AND_CONDITIONS',
    version: '1.0.0',
    title: 'Platform Terms and Conditions',
    content: '# Terms and Conditions v1.0',
    status: 'EFFECTIVE',
    isMandatory: true,
    effectiveAt: '2026-10-22T00:00:00Z',
  );

  const mockTermsDocV2 = LegalDocument(
    id: 'doc-terms-v2',
    documentType: 'TERMS_AND_CONDITIONS',
    version: '2.0.0',
    title: 'Platform Terms and Conditions v2',
    content: '# Terms and Conditions v2.0',
    status: 'EFFECTIVE',
    isMandatory: true,
    effectiveAt: '2026-10-22T00:00:00Z',
  );

  const mockPrivacyDoc = LegalDocument(
    id: 'doc-priv-v1',
    documentType: 'PRIVACY_POLICY',
    version: '1.0.0',
    title: 'Platform Privacy Notice',
    content: '# Privacy Notice',
    status: 'EFFECTIVE',
    isMandatory: false,
    effectiveAt: '2026-10-22T00:00:00Z',
  );

  const engineerProfile = UserProfile(
    id: 'usr-eng-01',
    email: 'engineer@archi-draft.com',
    name: 'Engineer One',
    mobile: '9876543210',
    role: 'ENGINEER',
  );

  const adminProfile = UserProfile(
    id: 'usr-adm-01',
    email: 'admin@archi-draft.com',
    name: 'Admin One',
    mobile: '9876543210',
    role: 'ADMIN',
  );

  group('GoRouter Legal Policy Acceptance Routing Suite', () {
    // 1. First-time user with unaccepted mandatory Terms
    testWidgets('1. First-time user with unaccepted mandatory Terms is redirected to /legal/onboarding', (tester) async {
      final mockUser = MockUser();
      const status = UserLegalStatus(
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
          userLegalStatusProvider.overrideWithValue(const AsyncValue.data(status)),
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

      // Attempt direct navigation to protected workspace route
      router.go('/engineer/projects');
      await tester.pumpAndSettle();

      // Guarded: redirected back to /legal/onboarding
      expect(router.state.matchedLocation, equals('/legal/onboarding'));
      expect(find.byType(LegalOnboardingScreen), findsOneWidget);
    });

    // 2. User who accepted the current effective Terms
    testWidgets('2. User who accepted current effective Terms is granted workspace access', (tester) async {
      final mockUser = MockUser();
      const status = UserLegalStatus(
        userId: 'usr-eng-01',
        termsAccepted: true,
        reacceptanceRequired: false,
        acceptedTermsVersion: '1.0.0',
        latestTermsVersion: '1.0.0',
        privacyNoticeAcknowledged: true,
        acknowledgedPrivacyVersion: '1.0.0',
        optionalConsents: {},
        requiresAction: false,
        hasEffectiveTerms: true,
        missingMandatoryDocs: false,
      );

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(AsyncValue.data(mockUser)),
          userProfileProvider.overrideWithValue(const AsyncValue.data(engineerProfile)),
          userLegalStatusProvider.overrideWithValue(const AsyncValue.data(status)),
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

      // Compliant user reaches their role workspace route
      expect(router.state.matchedLocation, equals('/engineer/projects'));
      expect(find.byType(LegalOnboardingScreen), findsNothing);
    });

    // 3. A newly effective mandatory Terms version
    testWidgets('3. User with outdated Terms version is redirected for re-acceptance', (tester) async {
      final mockUser = MockUser();
      const status = UserLegalStatus(
        userId: 'usr-eng-01',
        termsAccepted: false,
        reacceptanceRequired: true,
        acceptedTermsVersion: '1.0.0',
        latestTermsVersion: '2.0.0',
        privacyNoticeAcknowledged: true,
        optionalConsents: {},
        requiresAction: true,
        hasEffectiveTerms: true,
        missingMandatoryDocs: false,
      );

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(AsyncValue.data(mockUser)),
          userProfileProvider.overrideWithValue(const AsyncValue.data(engineerProfile)),
          userLegalStatusProvider.overrideWithValue(const AsyncValue.data(status)),
          effectiveDocumentProvider('TERMS_AND_CONDITIONS').overrideWithValue(const AsyncValue.data(mockTermsDocV2)),
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
      expect(find.text('Updated Platform Terms & Conditions'), findsOneWidget);

      // Attempt direct navigation to protected workspace route
      router.go('/engineer/projects');
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, equals('/legal/onboarding'));
    });

    // 4. Legal-status loading followed by a result requiring acceptance
    testWidgets('4. Legal-status loading followed by acceptance requirement', (tester) async {
      final mockUser = MockUser();
      final statusCompleter = Completer<UserLegalStatus>();

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(AsyncValue.data(mockUser)),
          userProfileProvider.overrideWithValue(const AsyncValue.data(engineerProfile)),
          userLegalStatusProvider.overrideWith((ref) => statusCompleter.future),
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
      await tester.pump();

      // While loading, user is held on /legal/onboarding (fail closed)
      expect(router.state.matchedLocation, equals('/legal/onboarding'));
      expect(find.text('Checking platform policy status...'), findsOneWidget);

      // Complete future with pending status
      statusCompleter.complete(const UserLegalStatus(
        userId: 'usr-eng-01',
        termsAccepted: false,
        reacceptanceRequired: false,
        latestTermsVersion: '1.0.0',
        privacyNoticeAcknowledged: false,
        optionalConsents: {},
        requiresAction: true,
        hasEffectiveTerms: true,
        missingMandatoryDocs: false,
      ));

      await tester.pumpAndSettle();

      // Router re-evaluates via notifier and keeps user on /legal/onboarding with Terms view
      expect(router.state.matchedLocation, equals('/legal/onboarding'));
      expect(find.text('Welcome to ARCHI DRAFT'), findsOneWidget);
    });

    // 5. Legal-status loading followed by an error
    testWidgets('5. Legal-status loading followed by error holds user in recoverable error state', (tester) async {
      final mockUser = MockUser();
      final statusCompleter = Completer<UserLegalStatus>();

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(AsyncValue.data(mockUser)),
          userProfileProvider.overrideWithValue(const AsyncValue.data(engineerProfile)),
          userLegalStatusProvider.overrideWith((ref) => statusCompleter.future),
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
      await tester.pump();

      expect(router.state.matchedLocation, equals('/legal/onboarding'));

      // Fail with network exception
      statusCompleter.completeError(Exception('Connection reset by peer (500)'));
      await tester.pumpAndSettle();

      // Guarded: stays on /legal/onboarding showing recoverable error widget
      expect(router.state.matchedLocation, equals('/legal/onboarding'));
      expect(find.text('Unable to reach legal policy service. Please check network connection.'), findsOneWidget);

      // Direct navigation attempt during error state is rejected
      router.go('/engineer/projects');
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, equals('/legal/onboarding'));
    });

    // 6. Direct navigation to protected workspace routes during loading or error
    testWidgets('6. Direct deep-link navigation during loading or error is blocked', (tester) async {
      final mockUser = MockUser();

      // Case A: Loading state
      final containerA = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(AsyncValue.data(mockUser)),
          userProfileProvider.overrideWithValue(const AsyncValue.data(engineerProfile)),
          userLegalStatusProvider.overrideWithValue(const AsyncValue.loading()),
          effectiveDocumentProvider('TERMS_AND_CONDITIONS').overrideWithValue(const AsyncValue.data(mockTermsDoc)),
          effectiveDocumentProvider('PRIVACY_POLICY').overrideWithValue(const AsyncValue.data(mockPrivacyDoc)),
          engineerProjectsProvider.overrideWithValue(const AsyncValue.data(<Project>[])),
          notificationsProvider.overrideWithValue(const AsyncValue.data(<AppNotification>[])),
        ],
      );
      addTearDown(containerA.dispose);

      final routerA = containerA.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: containerA,
          child: MaterialApp.router(routerConfig: routerA),
        ),
      );
      await tester.pump();

      routerA.go('/draughtsman/studio');
      await tester.pump();
      expect(routerA.state.matchedLocation, equals('/legal/onboarding'));

      // Case B: Error state
      final containerB = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(AsyncValue.data(mockUser)),
          userProfileProvider.overrideWithValue(const AsyncValue.data(engineerProfile)),
          userLegalStatusProvider.overrideWithValue(AsyncValue.error(Exception('503 Service Unavailable'), StackTrace.empty)),
          effectiveDocumentProvider('TERMS_AND_CONDITIONS').overrideWithValue(const AsyncValue.data(mockTermsDoc)),
          effectiveDocumentProvider('PRIVACY_POLICY').overrideWithValue(const AsyncValue.data(mockPrivacyDoc)),
          engineerProjectsProvider.overrideWithValue(const AsyncValue.data(<Project>[])),
          notificationsProvider.overrideWithValue(const AsyncValue.data(<AppNotification>[])),
        ],
      );
      addTearDown(containerB.dispose);

      final routerB = containerB.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: containerB,
          child: MaterialApp.router(routerConfig: routerB),
        ),
      );
      await tester.pumpAndSettle();

      routerB.go('/engineer/projects');
      await tester.pumpAndSettle();
      expect(routerB.state.matchedLocation, equals('/legal/onboarding'));
    });

    // 7. Logged-out or expired-session behavior
    testWidgets('7. Logged-out or expired session redirects from legal/protected routes to /landing', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(const AsyncValue.data(null)),
          userProfileProvider.overrideWithValue(const AsyncValue.data(null)),
          userLegalStatusProvider.overrideWithValue(AsyncValue.error(Exception('No user session'), StackTrace.empty)),
          effectiveDocumentProvider('TERMS_AND_CONDITIONS').overrideWithValue(const AsyncValue.data(null)),
          effectiveDocumentProvider('PRIVACY_POLICY').overrideWithValue(const AsyncValue.data(null)),
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

      expect(router.state.matchedLocation, equals('/landing'));

      // Attempting to visit /legal/onboarding without session redirects to /landing
      router.go('/legal/onboarding');
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, equals('/landing'));

      // Attempting to visit /engineer/projects without session redirects to /landing
      router.go('/engineer/projects');
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, equals('/landing'));
    });

    // 8. Optional consent declined or withdrawn
    testWidgets('8. Optional consent declined or withdrawn does not impede workspace access', (tester) async {
      final mockUser = MockUser();
      const status = UserLegalStatus(
        userId: 'usr-eng-01',
        termsAccepted: true,
        reacceptanceRequired: false,
        acceptedTermsVersion: '1.0.0',
        latestTermsVersion: '1.0.0',
        privacyNoticeAcknowledged: true,
        acknowledgedPrivacyVersion: '1.0.0',
        optionalConsents: {
          'MARKETING_COMMUNICATIONS': false,
          'PORTFOLIO_SHOWCASE': false,
        },
        requiresAction: false,
        hasEffectiveTerms: true,
        missingMandatoryDocs: false,
      );

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(AsyncValue.data(mockUser)),
          userProfileProvider.overrideWithValue(const AsyncValue.data(engineerProfile)),
          userLegalStatusProvider.overrideWithValue(const AsyncValue.data(status)),
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

      // User has full access to workspace despite declining optional consents
      expect(router.state.matchedLocation, equals('/engineer/projects'));
      expect(find.byType(LegalOnboardingScreen), findsNothing);
    });

    // 9. Missing mandatory legal documents
    testWidgets('9. Missing mandatory documents enforces maintenance mode for non-admin but permits admin access', (tester) async {
      const missingStatus = UserLegalStatus(
        userId: 'usr-test-01',
        termsAccepted: false,
        reacceptanceRequired: false,
        privacyNoticeAcknowledged: false,
        optionalConsents: {},
        requiresAction: false,
        hasEffectiveTerms: false,
        missingMandatoryDocs: true,
      );

      // Case A: Engineer user is held in maintenance mode
      final mockEngUser = MockUser(email: 'engineer@archi-draft.com', uid: 'usr-eng-01');
      final containerEng = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(AsyncValue.data(mockEngUser)),
          userProfileProvider.overrideWithValue(const AsyncValue.data(engineerProfile)),
          userLegalStatusProvider.overrideWithValue(const AsyncValue.data(missingStatus)),
          effectiveDocumentProvider('TERMS_AND_CONDITIONS').overrideWithValue(const AsyncValue.data(null)),
          effectiveDocumentProvider('PRIVACY_POLICY').overrideWithValue(const AsyncValue.data(null)),
          engineerProjectsProvider.overrideWithValue(const AsyncValue.data(<Project>[])),
          notificationsProvider.overrideWithValue(const AsyncValue.data(<AppNotification>[])),
        ],
      );
      addTearDown(containerEng.dispose);

      final routerEng = containerEng.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: containerEng,
          child: MaterialApp.router(routerConfig: routerEng),
        ),
      );
      await tester.pumpAndSettle();

      expect(routerEng.state.matchedLocation, equals('/legal/onboarding'));
      expect(find.text('Policy Maintenance in Progress'), findsOneWidget);
      expect(find.text('Check for Updates'), findsOneWidget);
      expect(find.text('Proceed to Workspace'), findsNothing);

      // Direct navigation to workspace is rejected
      routerEng.go('/engineer/projects');
      await tester.pumpAndSettle();
      expect(routerEng.state.matchedLocation, equals('/legal/onboarding'));

      // Case B: Administrator user is permitted to access /admin/dashboard to repair policies
      final mockAdminUser = MockUser(email: 'admin@archi-draft.com', uid: 'usr-adm-01');
      final containerAdmin = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(AsyncValue.data(mockAdminUser)),
          userProfileProvider.overrideWithValue(const AsyncValue.data(adminProfile)),
          userLegalStatusProvider.overrideWithValue(const AsyncValue.data(missingStatus)),
          effectiveDocumentProvider('TERMS_AND_CONDITIONS').overrideWithValue(const AsyncValue.data(null)),
          effectiveDocumentProvider('PRIVACY_POLICY').overrideWithValue(const AsyncValue.data(null)),
          notificationsProvider.overrideWithValue(const AsyncValue.data(<AppNotification>[])),
          adminDashboardMetricsProvider.overrideWithValue(
            const AsyncValue.data(
              AdminDashboardMetrics(
                totalProjects: 0,
                activeProjects: 0,
                projectsAwaitingAssignment: 0,
                projectsUnderClientReview: 0,
                completedProjects: 0,
                activeDraughtsmen: 0,
                pendingAssignments: 0,
              ),
            ),
          ),
        ],
      );
      addTearDown(containerAdmin.dispose);

      final routerAdmin = containerAdmin.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: containerAdmin,
          child: MaterialApp.router(routerConfig: routerAdmin),
        ),
      );
      await tester.pumpAndSettle();

      // Admin navigates to admin dashboard
      routerAdmin.go('/admin/dashboard');
      await tester.pumpAndSettle();

      // Admin console is accessible for recovery
      expect(routerAdmin.state.matchedLocation, equals('/admin/dashboard'));
    });
  });
}