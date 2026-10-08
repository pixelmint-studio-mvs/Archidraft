import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:archi_draft/src/features/profile/presentation/profile_screen.dart';
import 'package:archi_draft/src/features/profile/presentation/widgets/student_credentials_card.dart';
import 'package:archi_draft/src/features/auth/domain/user_profile.dart';
import 'package:archi_draft/src/features/auth/providers/auth_providers.dart';

void main() {
  testWidgets('ProfileScreen renders StudentCredentialsCard when role is STUDENT', (WidgetTester tester) async {
    final studentProfile = UserProfile(
      id: 'test-id',
      name: 'Test Student',
      email: 'test@student.com',
      mobile: '1234567890',
      role: 'STUDENT',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => studentProfile),
          // We might need to override authControllerProvider as well to avoid AsyncLoading issues, but let's see.
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final cardFinder = find.byType(StudentCredentialsCard);
    
    // We expect the card to be found
    expect(cardFinder, findsOneWidget);
  });
}
