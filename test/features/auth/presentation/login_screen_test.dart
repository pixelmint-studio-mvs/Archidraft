import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/auth/presentation/login_screen.dart';
import 'package:archi_draft/src/features/auth/presentation/widgets/auth_form_field.dart';

void main() {
  group('LoginScreen Security & Form Initialization Tests', () {
    testWidgets(
      'LoginScreen renders email and password fields and AUTHENTICATE button',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: LoginScreen())),
        );

        expect(find.byType(AuthFormField), findsNWidgets(2));
        expect(find.text('AUTHENTICATE'), findsWidgets);
      },
    );

    testWidgets(
      'LoginScreen starts with empty email and password fields by default',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: LoginScreen())),
        );

        final textFields = tester
            .widgetList<TextField>(find.byType(TextField))
            .toList();
        expect(textFields.length, equals(2));

        // Email field controller starts empty
        expect(textFields[0].controller?.text, isEmpty);
        // Password field controller starts empty
        expect(textFields[1].controller?.text, isEmpty);
      },
    );

    testWidgets('Password field starts obscured (hidden)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      final passwordField = tester.widget<TextField>(
        find.byType(TextField).at(1),
      );
      expect(passwordField.obscureText, isTrue);
    });

    testWidgets(
      'Empty fields preserved across all role options: ENGINEER, DRAUGHTSMAN, STUDENT',
      (WidgetTester tester) async {
        for (final role in ['ENGINEER', 'DRAUGHTSMAN', 'STUDENT']) {
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(home: LoginScreen(initialRole: role)),
            ),
          );
          await tester.pumpAndSettle();

          final textFields = tester
              .widgetList<TextField>(find.byType(TextField))
              .toList();
          expect(
            textFields[0].controller?.text,
            isEmpty,
            reason: 'Email must be empty for role ',
          );
          expect(
            textFields[1].controller?.text,
            isEmpty,
            reason: 'Password must be empty for role ',
          );
        }
      },
    );

    testWidgets('Form fields configure appropriate AutofillHints', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      final authFormFields = tester
          .widgetList<AuthFormField>(find.byType(AuthFormField))
          .toList();
      expect(authFormFields[0].autofillHints, contains(AutofillHints.email));
      expect(authFormFields[1].autofillHints, contains(AutofillHints.password));

      final textFields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(textFields[0].autofillHints, contains(AutofillHints.email));
      expect(textFields[1].autofillHints, contains(AutofillHints.password));
    });

    testWidgets('Switching initialRole resets stale form credentials', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen(initialRole: 'ENGINEER')),
        ),
      );
      await tester.pumpAndSettle();

      // Simulate user entering credentials
      await tester.enterText(
        find.byType(TextField).at(0),
        'stale@archidraft.test',
      );
      await tester.enterText(find.byType(TextField).at(1), 'StalePass123!');
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField).at(0)).controller?.text,
        equals('stale@archidraft.test'),
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller?.text,
        equals('StalePass123!'),
      );

      // Role changes to DRAUGHTSMAN
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen(initialRole: 'DRAUGHTSMAN')),
        ),
      );
      await tester.pumpAndSettle();

      // Verify fields were cleared
      expect(
        tester.widget<TextField>(find.byType(TextField).at(0)).controller?.text,
        isEmpty,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller?.text,
        isEmpty,
      );
    });
  });
}
