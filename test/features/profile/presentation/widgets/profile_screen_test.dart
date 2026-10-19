import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/auth/domain/user_profile.dart';
import 'package:archi_draft/src/features/auth/providers/auth_providers.dart';
import 'package:archi_draft/src/features/profile/presentation/profile_screen.dart';
import 'package:archi_draft/src/features/profile/providers/profile_providers.dart';
import 'package:archi_draft/src/features/profile/data/profile_repository.dart';

class _FakeProfileRepository extends Fake implements ProfileRepository {
  UserProfile? lastUpdated;
  bool shouldFail = false;

  @override
  Future<void> updateProfile(UserProfile profile) async {
    if (shouldFail) {
      throw Exception('Network error updating profile');
    }
    lastUpdated = profile;
  }
}

void main() {
  final testDraughtsman = UserProfile(
    id: 'uid-draughtsman-101',
    name: 'Anas Mohd',
    email: 'anas.draughtsman@archidraft.com',
    mobile: '+1234567890',
    role: 'DRAUGHTSMAN',
    createdAt: DateTime(2026, 1, 15),
    updatedAt: DateTime(2026, 10, 5),
    qualification: 'B.Arch',
    collegeName: 'National Institute of Architecture',
    address: '42 Studio Way, Sector 5',
    dateOfBirth: DateTime(1996, 5, 20),
  );

  Widget createTestWidget({
    Size surfaceSize = const Size(1280, 800),
    UserProfile? profileOverride = const UserProfile(
      id: 'uid-draughtsman-101',
      name: 'Anas Mohd',
      email: 'anas.draughtsman@archidraft.com',
      mobile: '+1234567890',
      role: 'DRAUGHTSMAN',
      qualification: 'B.Arch',
      collegeName: 'National Institute of Architecture',
      address: '42 Studio Way, Sector 5',
    ),
    bool isLoading = false,
    Object? error,
    _FakeProfileRepository? customRepo,
  }) {
    final fakeRepo = customRepo ?? _FakeProfileRepository();

    return ProviderScope(
      overrides: [
        if (isLoading)
          userProfileProvider.overrideWith((ref) => Completer<UserProfile?>().future)
        else if (error != null)
          userProfileProvider.overrideWith((ref) => Future<UserProfile?>.error(error))
        else
          userProfileProvider.overrideWith((ref) async => profileOverride),
        profileRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Inter',
        ),
        home: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: const ProfileScreen(),
        ),
      ),
    );
  }

  group('Panel 10 — Profile Screen Tests', () {
    testWidgets('1. Renders authenticated draughtsman profile data on Desktop (1280x800) with zero overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(profileOverride: testDraughtsman));
      await tester.pumpAndSettle();

      // Verify breadcrumbs and header
      expect(find.text('DRAUGHTSMAN  /  PROFILE & SETTINGS'), findsOneWidget);
      expect(find.text('Draughtsman Profile & Account Settings'), findsOneWidget);

      // Verify identity card elements
      expect(find.text('Anas Mohd'), findsWidgets);
      expect(find.text('anas.draughtsman@archidraft.com'), findsWidgets);
      expect(find.text('ROLE: DRAUGHTSMAN'), findsOneWidget);
      expect(find.text('STATUS: ACTIVE'), findsOneWidget);
      expect(find.textContaining('UID: uid-draughtsman-101'), findsOneWidget);

      // Verify read-only email indicator
      expect(find.text('READ-ONLY (FIREBASE AUTH)'), findsOneWidget);

      // Verify form sections and inputs
      expect(find.text('PERSONAL & CONTACT VITALS'), findsOneWidget);
      expect(find.text('PROFESSIONAL & STUDIO CREDENTIALS'), findsOneWidget);
      expect(find.text('B.Arch'), findsOneWidget);
      expect(find.text('National Institute of Architecture'), findsOneWidget);

      // Zero layout overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. Renders on Mobile (400x800) with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          surfaceSize: const Size(400, 800),
          profileOverride: testDraughtsman,
        ),
      );
      await tester.pumpAndSettle();

      // Breadcrumb renders
      expect(find.text('DRAUGHTSMAN  /  PROFILE & SETTINGS'), findsOneWidget);

      // Identity & credentials rendered in mobile scroll view
      expect(find.text('ROLE: DRAUGHTSMAN'), findsOneWidget);
      expect(find.text('STATUS: ACTIVE'), findsOneWidget);

      // Zero layout overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. Renders loading state properly', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          isLoading: true,
        ),
      );
      await tester.pump();

      expect(find.text('Loading draughtsman profile...'), findsOneWidget);
    });

    testWidgets('4. Renders error state and allows retry', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          error: Exception('Network timeout'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load profile. Please verify your connection.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('5. Renders empty state when profile is null', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          profileOverride: null,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile Not Found'), findsOneWidget);
    });

    testWidgets('6. Input validation blocks submission on empty required fields', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(profileOverride: testDraughtsman));
      await tester.pumpAndSettle();

      // Find the name field and clear it
      final nameFields = find.widgetWithText(TextFormField, 'Anas Mohd');
      expect(nameFields, findsOneWidget);

      await tester.enterText(nameFields, '');
      await tester.pumpAndSettle();

      // Tap Save Profile Changes
      final saveBtn = find.text('Save Profile Changes');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Validation error message appears
      expect(find.text('Name is required.'), findsOneWidget);
    });

    testWidgets('7. Successful save calls repository and displays success feedback', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = _FakeProfileRepository();

      await tester.pumpWidget(
        createTestWidget(
          profileOverride: testDraughtsman,
          customRepo: repo,
        ),
      );
      await tester.pumpAndSettle();

      // Edit qualification
      final qualField = find.widgetWithText(TextFormField, 'B.Arch');
      await tester.enterText(qualField, 'M.Arch (Urban Design)');
      await tester.pumpAndSettle();

      // Discard button should appear because form is dirty
      expect(find.text('Discard Changes'), findsOneWidget);

      // Save changes
      final saveBtn = find.text('Save Profile Changes');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Repo received updated qualification
      expect(repo.lastUpdated?.qualification, equals('M.Arch (Urban Design)'));
      expect(find.text('Profile updated successfully and persisted to server.'), findsOneWidget);
    });

    testWidgets('8. Discard Changes restores original values and cleans dirty state', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(profileOverride: testDraughtsman));
      await tester.pumpAndSettle();

      final qualField = find.widgetWithText(TextFormField, 'B.Arch');
      await tester.enterText(qualField, 'Changed Value');
      await tester.pumpAndSettle();

      expect(find.text('Discard Changes'), findsOneWidget);

      // Tap Discard Changes
      final discardBtn = find.text('Discard Changes');
      await tester.ensureVisible(discardBtn);
      await tester.tap(discardBtn);
      await tester.pumpAndSettle();

      // Form is no longer dirty so Discard Changes is gone
      expect(find.text('Discard Changes'), findsNothing);

      // Scroll back up to check value
      await tester.ensureVisible(qualField);
      expect(find.widgetWithText(TextFormField, 'B.Arch'), findsOneWidget);
    });

    testWidgets('9. Failed save displays actionable error banner', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = _FakeProfileRepository()..shouldFail = true;

      await tester.pumpWidget(
        createTestWidget(
          profileOverride: testDraughtsman,
          customRepo: repo,
        ),
      );
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextFormField, 'Anas Mohd');
      await tester.enterText(nameField, 'Anas Mohammed Updated');
      await tester.pumpAndSettle();

      final saveBtn = find.text('Save Profile Changes');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Actionable error banner appears
      expect(
        find.text('Failed to update profile. Please verify your connection and try again.'),
        findsOneWidget,
      );
    });

    testWidgets('10. UID copy button triggers clipboard message', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(profileOverride: testDraughtsman));
      await tester.pumpAndSettle();

      final copyBtn = find.byTooltip('Copy UID');
      expect(copyBtn, findsOneWidget);

      await tester.tap(copyBtn);
      await tester.pump();

      expect(find.text('User ID copied to clipboard'), findsOneWidget);
    });
  });
}
