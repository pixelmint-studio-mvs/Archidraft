import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/auth/presentation/login_screen.dart';
import 'package:archi_draft/src/features/auth/presentation/widgets/auth_form_field.dart';

void main() {
  testWidgets('LoginScreen renders email and password fields', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Verify that the email and password text fields are present.
    expect(find.byType(AuthFormField), findsNWidgets(2));
    expect(find.text('Sign In'), findsWidgets);
  });
}
