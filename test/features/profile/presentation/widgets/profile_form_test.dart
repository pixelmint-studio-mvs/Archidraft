import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:archi_draft/src/features/auth/domain/user_profile.dart';
import 'package:archi_draft/src/features/profile/data/profile_repository.dart';
import 'package:archi_draft/src/features/profile/presentation/widgets/profile_form.dart';
import 'package:archi_draft/src/features/profile/providers/profile_providers.dart';

class _FakeProfileRepository implements ProfileRepository {
  UserProfile? lastUpdatedProfile;

  @override
  Future<UserProfile?> getProfile(String uid) async {
    return lastUpdatedProfile;
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    lastUpdatedProfile = profile;
  }

  @override
  Future<bool> profileExists(String uid) async {
    return true;
  }

  @override
  Future<List<UserProfile>> getDraughtsmen() async {
    return [];
  }
}

void main() {
  late _FakeProfileRepository fakeProfileRepository;

  setUp(() {
    fakeProfileRepository = _FakeProfileRepository();
  });

  final testProfile = UserProfile(
    id: 'student_123',
    name: 'Jane Architect',
    email: 'jane@example.com',
    mobile: '9876543210',
    role: 'STUDENT',
    address: '123 Studio Way',
    dateOfBirth: DateTime(2001, 4, 15),
    qualification: 'B.Arch',
    collegeName: 'National Academy of Architecture',
  );

  testWidgets('ProfileForm displays formatted Date of Birth and preserves across rebuilds',
      (WidgetTester tester) async {
    int rebuildCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(fakeProfileRepository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            rebuildCount++;
                          });
                        },
                        child: Text('Rebuild Parent ($rebuildCount)'),
                      ),
                      ProfileForm(profile: testProfile),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final expectedFormattedDate = DateFormat('MMM dd, yyyy').format(testProfile.dateOfBirth!);
    expect(find.text(expectedFormattedDate), findsOneWidget);
    expect(find.text('Jane Architect'), findsOneWidget);

    // Trigger parent rebuild
    await tester.tap(find.text('Rebuild Parent (0)'));
    await tester.pumpAndSettle();

    // Verify DoB and fields remain intact after rebuild
    expect(find.text('Rebuild Parent (1)'), findsOneWidget);
    expect(find.text(expectedFormattedDate), findsOneWidget);
    expect(find.text('Jane Architect'), findsOneWidget);
  });

  testWidgets('Picking a new Date of Birth updates the field without losing other values',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(fakeProfileRepository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileForm(profile: testProfile),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on Date of Birth field
    final dobGestureFinder = find.ancestor(
      of: find.byIcon(Icons.calendar_today_outlined),
      matching: find.byType(GestureDetector),
    );
    await tester.tap(dobGestureFinder);
    await tester.pumpAndSettle();

    // The date picker dialog should be visible
    expect(find.byType(DatePickerDialog), findsOneWidget);

    // Tap 'OK' to select current date in dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Form should still have name, mobile, qualification, college intact
    expect(find.text('Jane Architect'), findsOneWidget);
    expect(find.text('9876543210'), findsOneWidget);
    expect(find.text('123 Studio Way'), findsOneWidget);
    expect(find.text('B.Arch'), findsOneWidget);
    expect(find.text('National Academy of Architecture'), findsOneWidget);
  });

  testWidgets('Submitting profile preserves dateOfBirth and all other fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(fakeProfileRepository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileForm(profile: testProfile),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Change name
    await tester.enterText(find.widgetWithText(TextFormField, 'Jane Architect'), 'Jane Modified');
    await tester.pumpAndSettle();

    // Tap Save Changes
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(fakeProfileRepository.lastUpdatedProfile, isNotNull);
    final saved = fakeProfileRepository.lastUpdatedProfile!;
    expect(saved.name, equals('Jane Modified'));
    expect(saved.mobile, equals('9876543210'));
    expect(saved.dateOfBirth, equals(testProfile.dateOfBirth));
    expect(saved.qualification, equals('B.Arch'));
    expect(saved.collegeName, equals('National Academy of Architecture'));
    expect(saved.address, equals('123 Studio Way'));
  });

  testWidgets('Parent rebuild does not overwrite unsaved edits when profile id matches',
      (WidgetTester tester) async {
    UserProfile activeProfile = testProfile;
    void Function(void Function())? parentSetState;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(fakeProfileRepository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                parentSetState = setState;
                return SingleChildScrollView(
                  child: ProfileForm(profile: activeProfile),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // User types an unsaved name into the text field
    await tester.enterText(find.widgetWithText(TextFormField, 'Jane Architect'), 'Unsaved Draft Name');
    await tester.pumpAndSettle();

    // Parent rebuilds with an updated address on the profile
    parentSetState!(() {
      activeProfile = testProfile.copyWith(address: '456 New Studio Way');
    });
    await tester.pumpAndSettle();

    // The unsaved text 'Unsaved Draft Name' must still be present!
    expect(find.text('Unsaved Draft Name'), findsOneWidget);
  });
}
