import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';

import 'package:archi_draft/src/core/router/app_router.dart';
import 'package:archi_draft/src/features/auth/domain/user_profile.dart';
import 'package:archi_draft/src/features/auth/presentation/register_screen.dart';
import 'package:archi_draft/src/features/auth/presentation/registration_confirmation_screen.dart';
import 'package:archi_draft/src/features/auth/providers/auth_providers.dart';
import 'package:archi_draft/src/features/legal/domain/user_legal_status.dart';
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
    this.email = 'applicant@example.com',
    this.uid = 'usr-pending-01',
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const compliantLegalStatus = UserLegalStatus(
    userId: 'usr-pending-01',
    termsAccepted: true,
    reacceptanceRequired: false,
    latestTermsVersion: '1.0.0',
    privacyNoticeAcknowledged: true,
    optionalConsents: {},
    requiresAction: false,
    hasEffectiveTerms: true,
    missingMandatoryDocs: false,
  );

  const pendingEngineerProfile = UserProfile(
    id: 'usr-pending-01',
    email: 'engineer.pending@example.com',
    name: 'Pending Engineer',
    mobile: '9876543210',
    role: 'ENGINEER',
    verificationStatus: 'PENDING',
  );

  const rejectedStudentProfile = UserProfile(
    id: 'usr-rejected-02',
    email: 'student.rejected@example.com',
    name: 'Rejected Student',
    mobile: '9876543211',
    role: 'STUDENT',
    verificationStatus: 'REJECTED',
    rejectionReason: 'The uploaded student ID has expired.',
  );

  const approvedEngineerProfile = UserProfile(
    id: 'usr-approved-03',
    email: 'engineer.approved@example.com',
    name: 'Approved Engineer',
    mobile: '9876543212',
    role: 'ENGINEER',
    verificationStatus: 'APPROVED',
  );

  group('Registration Verification, Confirmation & Role-Specific Proof Suite', () {
    testWidgets(
        '1. Confirmation screen displays exact required text and PENDING REVIEW state',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          userProfileProvider.overrideWithValue(
            const AsyncValue.data(pendingEngineerProfile),
          ),
          registrationStatusProvider.overrideWithValue(
            const AsyncValue.data({
              'status': 'PENDING',
              'name': 'Pending Engineer',
              'email': 'engineer.pending@example.com',
              'role': 'ENGINEER',
            }),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RegistrationConfirmationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify EXACT required text
      expect(
        find.text(
          'Your Registration has been sent, Status Will Be updated soon',
        ),
        findsOneWidget,
      );

      // Verify status badge
      expect(find.text('PENDING REVIEW'), findsOneWidget);

      // Verify applicant information
      expect(find.text('Applicant: Pending Engineer'), findsOneWidget);
      expect(find.text('Email: engineer.pending@example.com'), findsOneWidget);
      expect(find.text('Applied Role: ENGINEER'), findsOneWidget);

      // Verify explanatory points
      expect(find.text('Submission Received'), findsOneWidget);
      expect(find.text('Manual Admin Review'), findsOneWidget);
      expect(find.text('Access Restricted Until Approval'), findsOneWidget);
      expect(find.text('REFRESH STATUS'), findsOneWidget);
      expect(find.text('SIGN OUT'), findsOneWidget);
    });

    testWidgets(
        '2. Confirmation screen displays REJECTED status with rejection notice and reason',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          userProfileProvider.overrideWithValue(
            const AsyncValue.data(rejectedStudentProfile),
          ),
          registrationStatusProvider.overrideWithValue(
            const AsyncValue.data({
              'status': 'REJECTED',
              'name': 'Rejected Student',
              'email': 'student.rejected@example.com',
              'role': 'STUDENT',
              'rejection_reason': 'The uploaded student ID has expired.',
            }),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RegistrationConfirmationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('REJECTED'), findsOneWidget);
      expect(find.text('Registration Not Approved'), findsOneWidget);
      expect(
        find.text('Reason: The uploaded student ID has expired.'),
        findsOneWidget,
      );
    });

    testWidgets(
        '3. Confirmation screen displays APPROVED status with prompt to proceed',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          userProfileProvider.overrideWithValue(
            const AsyncValue.data(approvedEngineerProfile),
          ),
          registrationStatusProvider.overrideWithValue(
            const AsyncValue.data({
              'status': 'APPROVED',
              'name': 'Approved Engineer',
              'email': 'engineer.approved@example.com',
              'role': 'ENGINEER',
            }),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RegistrationConfirmationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('APPROVED'), findsOneWidget);
      expect(find.text('Registration Approved!'), findsOneWidget);
      expect(find.text('PROCEED TO ARCHI DRAFT'), findsOneWidget);
    });

    testWidgets(
        '4. Router restricts pending user from accessing protected features and keeps them on /registration-confirmation',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockUser = MockUser(
        emailVerified: true,
        email: 'engineer.pending@example.com',
        uid: 'usr-pending-01',
      );

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            AsyncValue.data(mockUser),
          ),
          userProfileProvider.overrideWithValue(
            const AsyncValue.data(pendingEngineerProfile),
          ),
          registrationStatusProvider.overrideWithValue(
            const AsyncValue.data({
              'status': 'PENDING',
              'name': 'Pending Engineer',
              'email': 'engineer.pending@example.com',
              'role': 'ENGINEER',
            }),
          ),
          userLegalStatusProvider.overrideWithValue(
            const AsyncValue.data(compliantLegalStatus),
          ),
          notificationsProvider.overrideWithValue(
            const AsyncValue.data(<AppNotification>[]),
          ),
          engineerProjectsProvider.overrideWithValue(
            const AsyncValue.data(<Project>[]),
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

      // Directly verify that initial redirect leads to registration confirmation
      expect(router.state.matchedLocation, equals('/registration-confirmation'));
      expect(find.byType(RegistrationConfirmationScreen), findsOneWidget);

      // Attempt to navigate to protected engineer workspace
      router.go('/engineer/projects');
      await tester.pumpAndSettle();

      // Must be kept on /registration-confirmation
      expect(router.state.matchedLocation, equals('/registration-confirmation'));
      expect(find.byType(RegistrationConfirmationScreen), findsOneWidget);
    });

    testWidgets(
        '5. Router restricts rejected user from accessing protected features',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockUser = MockUser(
        emailVerified: true,
        email: 'student.rejected@example.com',
        uid: 'usr-rejected-02',
      );

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            AsyncValue.data(mockUser),
          ),
          userProfileProvider.overrideWithValue(
            const AsyncValue.data(rejectedStudentProfile),
          ),
          registrationStatusProvider.overrideWithValue(
            const AsyncValue.data({
              'status': 'REJECTED',
              'name': 'Rejected Student',
              'email': 'student.rejected@example.com',
              'role': 'STUDENT',
              'rejection_reason': 'The uploaded student ID has expired.',
            }),
          ),
          userLegalStatusProvider.overrideWithValue(
            const AsyncValue.data(compliantLegalStatus),
          ),
          notificationsProvider.overrideWithValue(
            const AsyncValue.data(<AppNotification>[]),
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

      expect(router.state.matchedLocation, equals('/registration-confirmation'));

      // Attempt to access student dashboard
      router.go('/student/dashboard');
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, equals('/registration-confirmation'));
    });

    testWidgets(
        '6. RegisterScreen displays Engineer-specific required proof upload label',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RegisterScreen(role: 'ENGINEER'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('REQUIRED PROOF UPLOAD'), findsOneWidget);
      expect(
        find.text('Engineering degree or relevant qualification certificate'),
        findsOneWidget,
      );
      expect(find.text('CHOOSE DOCUMENT'), findsOneWidget);
    });

    testWidgets(
        '7. RegisterScreen displays Draughtsman-specific required proof upload label',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RegisterScreen(role: 'DRAUGHTSMAN'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('REQUIRED PROOF UPLOAD'), findsOneWidget);
      expect(
        find.text(
          'Draughtsmanship degree, diploma, or relevant qualification certificate',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        '8. RegisterScreen displays Student-specific required proof upload label',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RegisterScreen(role: 'STUDENT'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('REQUIRED PROOF UPLOAD'), findsOneWidget);
      expect(find.text('Valid Student ID card'), findsOneWidget);
    });

    testWidgets(
        '9. RegisterScreen enforces mandatory proof document validation on submit',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RegisterScreen(role: 'ENGINEER'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter valid fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Er. Jane Doe'),
        'Jane Engineer',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'name@firm.com'),
        'jane@firm.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '+91 98765 43210'),
        '+919876543210',
      );
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'Min 8 chars, uppercase, lowercase, number',
        ),
        'SecurePassword123!',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Re-enter your password'),
        'SecurePassword123!',
      );

      // Attempt to submit WITHOUT uploading proof document
      await tester.tap(find.text('CREATE ACCOUNT'));
      await tester.pumpAndSettle();

      // Verify that validation error message is displayed
      expect(
        find.text(
          'Please upload your Engineering degree or relevant qualification certificate.',
        ),
        findsAtLeastNWidgets(1),
      );
    });
  });
}
