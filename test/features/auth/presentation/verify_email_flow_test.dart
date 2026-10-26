import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';

import 'package:archi_draft/src/core/router/app_router.dart';
import 'package:archi_draft/src/features/auth/domain/user_profile.dart';
import 'package:archi_draft/src/features/auth/presentation/verify_email_screen.dart';
import 'package:archi_draft/src/features/auth/providers/auth_providers.dart';
import 'package:archi_draft/src/features/legal/domain/legal_document.dart';
import 'package:archi_draft/src/features/legal/domain/user_legal_status.dart';
import 'package:archi_draft/src/features/legal/providers/legal_providers.dart';
import 'package:archi_draft/src/features/projects/domain/assignment.dart';
import 'package:archi_draft/src/features/projects/providers/assignment_providers.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/domain/admin_dashboard_metrics.dart';
import 'package:archi_draft/src/features/projects/providers/admin_providers.dart';
import 'package:archi_draft/src/features/training/domain/training_module.dart';
import 'package:archi_draft/src/features/training/providers/training_providers.dart';
import 'package:archi_draft/src/features/notifications/providers/notification_providers.dart';
import 'package:archi_draft/src/features/notifications/domain/app_notification.dart';
import 'package:archi_draft/src/features/portfolio/providers/portfolio_providers.dart';
import 'package:archi_draft/src/features/profile/domain/student_metrics.dart';
import 'package:archi_draft/src/features/profile/providers/achievements_providers.dart';
import 'package:archi_draft/src/features/profile/providers/credentials_providers.dart';
import 'package:archi_draft/src/features/profile/providers/metrics_providers.dart';
import 'package:archi_draft/src/features/projects/domain/correction.dart';

class MockUser extends Mock implements User {
  @override
  final bool emailVerified;

  @override
  final String email;

  @override
  final String uid;

  MockUser({
    this.emailVerified = false,
    this.email = 'user@example.com',
    this.uid = 'usr-test-01',
  });
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

  const emptyLegalStatus = UserLegalStatus(
    userId: '',
    termsAccepted: false,
    reacceptanceRequired: false,
    privacyNoticeAcknowledged: false,
    optionalConsents: {},
    requiresAction: false,
    hasEffectiveTerms: true,
    missingMandatoryDocs: false,
  );

  const compliantLegalStatus = UserLegalStatus(
    userId: 'usr-test-01',
    termsAccepted: true,
    reacceptanceRequired: false,
    latestTermsVersion: '1.0.0',
    privacyNoticeAcknowledged: true,
    optionalConsents: {},
    requiresAction: false,
    hasEffectiveTerms: true,
    missingMandatoryDocs: false,
  );

  const engineerProfile = UserProfile(
    id: 'usr-test-01',
    email: 'engineer@example.com',
    name: 'Engineer Test',
    mobile: '9876543210',
    role: 'ENGINEER',
  );

  final draughtsmanProfile = UserProfile(
    id: 'usr-test-02',
    email: 'draughtsman@example.com',
    name: 'Draughtsman Test',
    mobile: '9876543210',
    role: 'DRAUGHTSMAN',
    dateOfBirth: DateTime(1995, 1, 1),
    address: 'Studio Street',
    qualification: 'Diploma in Civil',
  );

  const studentProfile = UserProfile(
    id: 'usr-test-03',
    email: 'student@example.com',
    name: 'Student Test',
    mobile: '9876543210',
    role: 'STUDENT',
  );

  const adminProfile = UserProfile(
    id: 'usr-test-04',
    email: 'admin@example.com',
    name: 'Admin Test',
    mobile: '9876543210',
    role: 'ADMIN',
  );

  group('Shared Authentication, Registration & Email Verification Flow Suite', () {
    testWidgets('1. An unverified authenticated user is routed to /verify-email', (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockUnverifiedUser = MockUser(emailVerified: false, email: 'eng@example.com');

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(AsyncValue.data(mockUnverifiedUser)),
          userProfileProvider.overrideWithValue(const AsyncValue.data(engineerProfile)),
          userLegalStatusProvider.overrideWithValue(const AsyncValue.data(compliantLegalStatus)),
          notificationsProvider.overrideWithValue(const AsyncValue.data(<AppNotification>[])),
          engineerProjectsProvider.overrideWithValue(const AsyncValue.data(<Project>[])),
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

      expect(router.state.matchedLocation, equals('/verify-email'));
      expect(find.byType(VerifyEmailScreen), findsOneWidget);
    });

    testWidgets('2. An unverified user cannot bypass verification to protected screens', (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockUnverifiedUser = MockUser(emailVerified: false, email: 'eng@example.com');

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(AsyncValue.data(mockUnverifiedUser)),
          userProfileProvider.overrideWithValue(const AsyncValue.data(engineerProfile)),
          userLegalStatusProvider.overrideWithValue(const AsyncValue.data(compliantLegalStatus)),
          notificationsProvider.overrideWithValue(const AsyncValue.data(<AppNotification>[])),
          engineerProjectsProvider.overrideWithValue(const AsyncValue.data(<Project>[])),
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

      // Attempt to access engineer projects directly
      router.go('/engineer/projects');
      await tester.pumpAndSettle();

      // Must be kept on /verify-email
      expect(router.state.matchedLocation, equals('/verify-email'));
    });

    testWidgets('3. Refresh and session restoration while on /verify-email does not bounce to landing', (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // In Flutter Web during reload, authState may start as loading or temporary unauthenticated
      final container = ProviderContainer(
        overrides: [
          // Simulate unauthenticated during initial token retrieval from IndexedDB
          authStateChangesProvider.overrideWithValue(const AsyncValue.data(null)),
          userProfileProvider.overrideWithValue(const AsyncValue.data(null)),
          userLegalStatusProvider.overrideWithValue(const AsyncValue.data(emptyLegalStatus)),
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

      // Navigate to /verify-email (as in browser reload of /#/verify-email)
      router.go('/verify-email');
      await tester.pumpAndSettle();

      // Since /verify-email is in publicPaths, it does NOT get redirected to /landing
      expect(router.state.matchedLocation, equals('/verify-email'));
    });

    testWidgets('4. Engineer: Once email is verified and terms accepted, routes to /engineer/projects', (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockVerifiedUser = MockUser(emailVerified: true, email: 'eng@example.com');

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(AsyncValue.data(mockVerifiedUser)),
          userProfileProvider.overrideWithValue(const AsyncValue.data(engineerProfile)),
          userLegalStatusProvider.overrideWithValue(const AsyncValue.data(compliantLegalStatus)),
          effectiveDocumentProvider('TERMS_AND_CONDITIONS').overrideWithValue(const AsyncValue.data(mockTermsDoc)),
          notificationsProvider.overrideWithValue(const AsyncValue.data(<AppNotification>[])),
          engineerProjectsProvider.overrideWithValue(const AsyncValue.data(<Project>[])),
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

      // Starting from /verify-email with verified status
      router.go('/verify-email');
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, equals('/engineer/projects'));
    });

    testWidgets('5. Draughtsman: Once email is verified, routes to /draughtsman/studio', (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockVerifiedUser = MockUser(emailVerified: true, email: 'draughtsman@example.com');

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(AsyncValue.data(mockVerifiedUser)),
          userProfileProvider.overrideWithValue(AsyncValue.data(draughtsmanProfile)),
          userLegalStatusProvider.overrideWithValue(const AsyncValue.data(compliantLegalStatus)),
          effectiveDocumentProvider('TERMS_AND_CONDITIONS').overrideWithValue(const AsyncValue.data(mockTermsDoc)),
          notificationsProvider.overrideWithValue(const AsyncValue.data(<AppNotification>[])),
          draughtsmanAssignmentsProvider.overrideWithValue(const AsyncValue.data(<Assignment>[])),
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

      router.go('/verify-email');
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, equals('/draughtsman/studio'));
    });

    testWidgets('6. Student: Once email is verified, routes to /student/dashboard', (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockVerifiedUser = MockUser(emailVerified: true, email: 'student@example.com');

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(AsyncValue.data(mockVerifiedUser)),
          userProfileProvider.overrideWithValue(const AsyncValue.data(studentProfile)),
          userLegalStatusProvider.overrideWithValue(const AsyncValue.data(compliantLegalStatus)),
          effectiveDocumentProvider('TERMS_AND_CONDITIONS').overrideWithValue(const AsyncValue.data(mockTermsDoc)),
          notificationsProvider.overrideWithValue(const AsyncValue.data(<AppNotification>[])),
          studentModulesProvider.overrideWithValue(const AsyncValue.data(<TrainingModule>[])),
          categoryProgressProvider.overrideWithValue(const AsyncValue.data(<TrainingCategoryProgress>[])),
          studentAssignmentsProvider.overrideWithValue(const AsyncValue.data(<Project>[])),
          studentCorrectionsProvider.overrideWith((ref) => <Correction>[]),
          studentActivityProvider.overrideWith((ref) => <Map<String, dynamic>>[]),
          studentPortfolioProvider.overrideWith((ref) => []),
          studentCredentialsProvider.overrideWith((ref) => []),
          studentAchievementsProvider.overrideWith((ref) => []),
          studentMetricsProvider.overrideWith((ref) => StudentMetrics(
                learning: [],
                practical: [],
                activity: ActivityMetric(completedProjects: 0, correctionRounds: 0),
              )),
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

      router.go('/verify-email');
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, equals('/student/dashboard'));
    });

    testWidgets('7. Admin: Verified admin routes to /admin/dashboard', (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockVerifiedUser = MockUser(emailVerified: true, email: 'admin@example.com');

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(AsyncValue.data(mockVerifiedUser)),
          userProfileProvider.overrideWithValue(const AsyncValue.data(adminProfile)),
          userLegalStatusProvider.overrideWithValue(const AsyncValue.data(compliantLegalStatus)),
          effectiveDocumentProvider('TERMS_AND_CONDITIONS').overrideWithValue(const AsyncValue.data(mockTermsDoc)),
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
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/verify-email');
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, equals('/admin/dashboard'));
    });

    testWidgets('8. Unauthenticated direct access to /login or /register redirects to /role-selection', (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(const AsyncValue.data(null)),
          userProfileProvider.overrideWithValue(const AsyncValue.data(null)),
          userLegalStatusProvider.overrideWithValue(const AsyncValue.data(emptyLegalStatus)),
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

      router.go('/login');
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, equals('/role-selection'));

      router.go('/register');
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, equals('/role-selection'));
    });
  });
}
