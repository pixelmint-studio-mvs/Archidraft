import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';

import 'package:archi_draft/src/core/router/app_router.dart';
import 'package:archi_draft/src/features/auth/domain/user_profile.dart';
import 'package:archi_draft/src/features/auth/providers/auth_providers.dart';
import 'package:archi_draft/src/features/auth/data/auth_repository.dart';
import 'package:archi_draft/src/features/legal/domain/legal_document.dart';
import 'package:archi_draft/src/features/legal/domain/user_legal_status.dart';
import 'package:archi_draft/src/features/legal/providers/legal_providers.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/notifications/providers/notification_providers.dart';
import 'package:archi_draft/src/features/notifications/domain/app_notification.dart';

class FakeAuthRepository extends Fake implements AuthRepository {
  final Future<void> Function()? onSignOut;
  FakeAuthRepository({this.onSignOut});

  @override
  Future<void> signOut() async {
    if (onSignOut != null) {
      await onSignOut!();
    }
  }

  @override
  Stream<User?> authStateChanges() => const Stream.empty();
}

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mockTermsDoc = LegalDocument(
    id: 'doc-terms-v1',
    documentType: 'TERMS_AND_CONDITIONS',
    version: '1.0.0',
    title: 'Platform Terms and Conditions',
    content: '# Terms and Conditions Content for Archi Draft',
    status: 'EFFECTIVE',
    isMandatory: true,
    effectiveAt: '2026-10-22T00:00:00Z',
  );

  const mockPrivacyDoc = LegalDocument(
    id: 'doc-priv-v1',
    documentType: 'PRIVACY_POLICY',
    version: '1.0.0',
    title: 'Platform Privacy Notice',
    content: '# Privacy Notice Content',
    status: 'EFFECTIVE',
    isMandatory: false,
    effectiveAt: '2026-10-22T00:00:00Z',
  );

  const engineerProfile = UserProfile(
    id: 'usr-eng-01',
    email: 'engineer@archidraft.test',
    name: 'Engineer Alice',
    mobile: '9876543210',
    role: 'ENGINEER',
  );

  ProviderContainer createContainer({
    User? currentUser,
    UserProfile? currentProfile,
    Stream<User?>? authStream,
    Future<void> Function()? onSignOut,
  }) {
    return ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(onSignOut: onSignOut)),
        if (authStream != null)
          authStateChangesProvider.overrideWith((ref) => authStream)
        else
          authStateChangesProvider.overrideWithValue(AsyncValue.data(currentUser)),
        userProfileProvider.overrideWithValue(AsyncValue.data(currentProfile)),
        effectiveDocumentProvider('TERMS_AND_CONDITIONS').overrideWithValue(const AsyncValue.data(mockTermsDoc)),
        effectiveDocumentProvider('PRIVACY_POLICY').overrideWithValue(const AsyncValue.data(mockPrivacyDoc)),
        userLegalStatusProvider.overrideWithValue(AsyncValue.data(UserLegalStatus(
          userId: currentUser?.uid ?? '',
          termsAccepted: true,
          reacceptanceRequired: false,
          privacyNoticeAcknowledged: true,
          optionalConsents: const {},
          requiresAction: false,
        ))),
        engineerProjectsProvider.overrideWithValue(const AsyncValue.data(<Project>[])),
        notificationsProvider.overrideWithValue(const AsyncValue.data(<AppNotification>[])),
      ],
    );
  }

  group('Terms & Conditions Pre-Login Navigation Flow Suite', () {
    testWidgets('1. Landing page opens correctly', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = createContainer();
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
      expect(find.text('Precision.\nDesign.\nDelivery.'), findsOneWidget);
      expect(find.text('Start Submission'), findsOneWidget);
    });

    testWidgets('2. Selecting Engineer opens Terms & Conditions before Engineer Login', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = createContainer();
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/role-selection');
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, equals('/role-selection'));

      // Tap Engineer role card
      await tester.tap(find.text('Engineer'));
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify on /terms-and-conditions with Engineer role
      expect(router.state.matchedLocation, equals('/terms-and-conditions'));
      expect(find.text('Welcome to ARCHI DRAFT'), findsOneWidget);
      expect(find.text('Agree & Continue to Login'), findsOneWidget);
      expect(find.text('Decline & Return to Role Selection'), findsOneWidget);

      final termsState = container.read(preLoginTermsProvider);
      expect(termsState.role, equals('ENGINEER'));
      expect(termsState.accepted, isFalse);
    });

    testWidgets('3. Selecting Draughtsman opens Terms & Conditions before Draughtsman Login', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = createContainer();
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/role-selection');
      await tester.pumpAndSettle();

      // Tap Draughtsman role card
      await tester.tap(find.text('Draughtsman'));
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify on /terms-and-conditions with Draughtsman role
      expect(router.state.matchedLocation, equals('/terms-and-conditions'));
      final termsState = container.read(preLoginTermsProvider);
      expect(termsState.role, equals('DRAUGHTSMAN'));
      expect(termsState.accepted, isFalse);
    });

    testWidgets('4. Selecting Student opens Terms & Conditions before Student Login', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = createContainer();
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/role-selection');
      await tester.pumpAndSettle();

      // Tap Student role card
      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify on /terms-and-conditions with Student role
      expect(router.state.matchedLocation, equals('/terms-and-conditions'));
      final termsState = container.read(preLoginTermsProvider);
      expect(termsState.role, equals('STUDENT'));
      expect(termsState.accepted, isFalse);
    });

    testWidgets('5. Accepting terms opens the correct role-specific login screen', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = createContainer();
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/role-selection');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Engineer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // On Terms screen, Continue is disabled until checked
      final agreeBtnFinder = find.widgetWithText(ElevatedButton, 'Agree & Continue to Login');
      expect(tester.widget<ElevatedButton>(agreeBtnFinder).onPressed, isNull);

      // Check the mandatory terms checkbox
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();

      expect(tester.widget<ElevatedButton>(agreeBtnFinder).onPressed, isNotNull);

      // Tap Agree & Continue
      await tester.tap(agreeBtnFinder);
      await tester.pumpAndSettle();

      // Should arrive at /login
      expect(router.state.matchedLocation, equals('/login'));
      final termsState = container.read(preLoginTermsProvider);
      expect(termsState.accepted, isTrue);
      expect(termsState.role, equals('ENGINEER'));
    });

    testWidgets('6. Declining terms does not open login and returns to role selection', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = createContainer();
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/role-selection');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Engineer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, equals('/terms-and-conditions'));

      // Tap Decline & Return
      await tester.tap(find.text('Decline & Return to Role Selection'));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, equals('/role-selection'));
      final termsState = container.read(preLoginTermsProvider);
      expect(termsState.accepted, isFalse);
    });

    testWidgets('7. Returning to role selection and choosing another role shows terms screen again with new role', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = createContainer();
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Select Engineer
      router.go('/role-selection');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Engineer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(container.read(preLoginTermsProvider).role, equals('ENGINEER'));

      // 2. Return to role selection
      await tester.tap(find.text('Back to Role Selection'));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, equals('/role-selection'));

      // 3. Select Student
      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, equals('/terms-and-conditions'));
      final termsState = container.read(preLoginTermsProvider);
      expect(termsState.role, equals('STUDENT'));
      expect(termsState.accepted, isFalse);
    });

    testWidgets('8. Logging out returns user to landing page and resets acceptance state', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockUser = MockUser();
      final container = createContainer(
        currentUser: mockUser,
        currentProfile: engineerProfile,
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

      expect(router.state.matchedLocation, equals('/engineer/projects'));

      // Set simulated pre-login terms state
      container.read(preLoginTermsProvider.notifier).acceptTerms(role: 'ENGINEER');
      expect(container.read(preLoginTermsProvider).accepted, isTrue);

      // Sign out via controller resets acceptance state
      await container.read(authControllerProvider.notifier).signOut();
      await tester.pumpAndSettle();

      expect(container.read(preLoginTermsProvider).accepted, isFalse);
      expect(container.read(preLoginTermsProvider).role, isNull);

      // Auth state update redirects logged-out user to landing page
      container.updateOverrides([
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        authStateChangesProvider.overrideWithValue(const AsyncValue.data(null)),
        userProfileProvider.overrideWithValue(const AsyncValue.data(null)),
        effectiveDocumentProvider('TERMS_AND_CONDITIONS').overrideWithValue(const AsyncValue.data(mockTermsDoc)),
        effectiveDocumentProvider('PRIVACY_POLICY').overrideWithValue(const AsyncValue.data(mockPrivacyDoc)),
        userLegalStatusProvider.overrideWithValue(AsyncValue.error(Exception('No user session'), StackTrace.empty)),
        engineerProjectsProvider.overrideWithValue(const AsyncValue.data(<Project>[])),
        notificationsProvider.overrideWithValue(const AsyncValue.data(<AppNotification>[])),
      ]);
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, equals('/landing'));
    });

    testWidgets('9. Selecting a role after logout shows Terms & Conditions again', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = createContainer();
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // User selects a role after logout
      router.go('/role-selection');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Draughtsman'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, equals('/terms-and-conditions'));
      expect(container.read(preLoginTermsProvider).accepted, isFalse);
    });

    testWidgets('10. A stale acceptance flag cannot bypass the terms screen', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = createContainer();
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Select role A
      container.read(preLoginTermsProvider.notifier).selectRole('ENGINEER');
      container.read(preLoginTermsProvider.notifier).acceptTerms(role: 'ENGINEER');
      expect(container.read(preLoginTermsProvider).accepted, isTrue);

      // Switching to role B immediately invalidates acceptance!
      container.read(preLoginTermsProvider.notifier).selectRole('DRAUGHTSMAN');
      expect(container.read(preLoginTermsProvider).accepted, isFalse);
      expect(container.read(preLoginTermsProvider).role, equals('DRAUGHTSMAN'));

      // Direct navigation to /login without accepting role B is blocked
      router.go('/login');
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, equals('/role-selection'));
    });

    testWidgets('11. The selected role is not lost or incorrectly substituted during navigation', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = createContainer();
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/role-selection');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(container.read(preLoginTermsProvider).role, equals('STUDENT'));

      // Agree to terms
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agree & Continue to Login'));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, equals('/login'));
      expect(container.read(preLoginTermsProvider).role, equals('STUDENT'));
    });

    testWidgets('12. Existing authentication, role permissions, and dashboard routing continue to work', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockUser = MockUser();
      final container = createContainer(
        currentUser: mockUser,
        currentProfile: engineerProfile,
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

      // Logged in engineer goes straight to engineer projects dashboard
      expect(router.state.matchedLocation, equals('/engineer/projects'));
    });

    testWidgets('13. Direct navigation cannot bypass the terms gate', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = createContainer();
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Unauthenticated attempt to directly visit /login without accepted terms
      router.go('/login');
      await tester.pumpAndSettle();

      // Guarded: redirected to /role-selection
      expect(router.state.matchedLocation, equals('/role-selection'));

      // Unauthenticated attempt to directly visit /terms-and-conditions without role
      router.go('/terms-and-conditions');
      await tester.pumpAndSettle();

      // Guarded: redirected to /role-selection
      expect(router.state.matchedLocation, equals('/role-selection'));
    });

    testWidgets('14. Back navigation does not produce a loop or expose an unintended screen', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = createContainer();
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/role-selection');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Engineer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, equals('/terms-and-conditions'));

      // Back navigation returns directly to /role-selection
      await tester.tap(find.text('Back to Role Selection'));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, equals('/role-selection'));

      // Back navigation from role selection returns to /landing
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, equals('/landing'));
    });
  });
}
