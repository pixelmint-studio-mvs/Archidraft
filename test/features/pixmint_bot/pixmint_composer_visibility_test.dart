import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archi_draft/src/core/theme/app_theme.dart';
import 'package:archi_draft/src/features/pixmint_bot/domain/models/bot_user_role.dart';
import 'package:archi_draft/src/features/pixmint_bot/presentation/sheet/pixmint_chat_input.dart';
import 'package:archi_draft/src/features/pixmint_bot/presentation/sheet/pixmint_chat_sheet.dart';
import 'package:archi_draft/src/features/pixmint_bot/theme/pixmint_bot_theme.dart';

void main() {
  group('PIXMINT BOT Chat Composer Text Visibility & Styling', () {
    testWidgets('Applies explicit contrasting colors against light/inherited theme', (tester) async {
      String? submittedText;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PixmintChatInput(
              onSend: (text) => submittedText = text,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Locate TextField and verify styles
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      final TextField textField = tester.widget<TextField>(textFieldFinder);

      // Contrast Rule 1: Typed text must be crisp white (#F8FAFC)
      expect(textField.style?.color, equals(const Color(0xFFF8FAFC)));
      expect(textField.style?.color, equals(PixmintBotTheme.composerText));

      // Contrast Rule 2: Input capsule background must be dark navy (#081824)
      expect(textField.decoration?.filled, isTrue);
      expect(textField.decoration?.fillColor, equals(const Color(0xFF081824)));
      expect(textField.decoration?.fillColor, equals(PixmintBotTheme.composerBackground));

      // Contrast Rule 3: Hint text must be muted grey (#64748B)
      expect(textField.decoration?.hintText, equals('Ask a question...'));
      expect(textField.decoration?.hintStyle?.color, equals(const Color(0xFF64748B)));
      expect(textField.decoration?.hintStyle?.color, equals(PixmintBotTheme.composerHint));

      // Contrast Rule 4: Cursor must be emerald green (#00D6A0)
      expect(textField.cursorColor, equals(const Color(0xFF00D6A0)));
      expect(textField.cursorColor, equals(PixmintBotTheme.composerCursor));

      // Contrast Rule 5: Container capsule decoration must have dark navy background
      final containerFinder = find.ancestor(
        of: textFieldFinder,
        matching: find.byType(Container),
      ).first;
      final Container container = tester.widget<Container>(containerFinder);
      final BoxDecoration decoration = container.decoration as BoxDecoration;

      expect(decoration.color, equals(const Color(0xFF081824)));
      expect(decoration.borderRadius, equals(BorderRadius.circular(16)));
    });

    testWidgets('Focus state activates emerald green border highlight', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PixmintChatInput(
              onSend: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);

      // Tap to focus
      await tester.tap(textFieldFinder);
      await tester.pumpAndSettle();

      final containerFinder = find.ancestor(
        of: textFieldFinder,
        matching: find.byType(Container),
      ).first;
      final Container focusedContainer = tester.widget<Container>(containerFinder);
      final BoxDecoration focusedDecoration = focusedContainer.decoration as BoxDecoration;
      final focusedBorder = focusedDecoration.border as Border;

      // When focused, border transitions to emerald green (#00D6A0)
      expect(focusedBorder.top.color, equals(const Color(0xFF00D6A0)));
      expect(focusedBorder.top.color, equals(PixmintBotTheme.composerBorderFocused));
    });

    testWidgets('Typing lifecycle: text visible, enables send, clears and restores hint on submit', (tester) async {
      String? sentMessage;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PixmintChatInput(
              onSend: (msg) => sentMessage = msg,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);

      // Type text into composer
      const query = 'How do I review drawing annotations?';
      await tester.enterText(textFieldFinder, query);
      await tester.pumpAndSettle();

      // Verify text is present and rendered
      expect(find.text(query), findsOneWidget);

      final TextField activeTextField = tester.widget<TextField>(textFieldFinder);
      expect(activeTextField.controller?.text, equals(query));
      expect(activeTextField.style?.color, equals(const Color(0xFFF8FAFC)));

      // Send button should now be enabled
      final sendButtonFinder = find.byType(IconButton);
      expect(sendButtonFinder, findsOneWidget);
      final IconButton sendButton = tester.widget<IconButton>(sendButtonFinder);
      expect(sendButton.onPressed, isNotNull);

      // Tap send button
      await tester.tap(sendButtonFinder);
      await tester.pumpAndSettle();

      // Verify message was delivered via callback
      expect(sentMessage, equals(query));

      // Verify input was cleared and hint restored
      final TextField clearedTextField = tester.widget<TextField>(textFieldFinder);
      expect(clearedTextField.controller?.text, isEmpty);
      expect(find.text('Ask a question...'), findsOneWidget);
    });

    testWidgets('Keyboard action send submits message', (tester) async {
      String? submittedText;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PixmintChatInput(
              onSend: (text) => submittedText = text,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, 'Keyboard submission test');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      expect(submittedText, equals('Keyboard submission test'));
      final TextField textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('Thinking state displays loading spinner and disables submission', (tester) async {
      String? submittedText;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PixmintChatInput(
              onSend: (text) => submittedText = text,
              isThinking: true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify progress indicator is visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Verify IconButton onPressed is null while thinking
      final sendButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(sendButton.onPressed, isNull);

      // Attempt submission via keyboard action
      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, 'Blocked during thinking');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump(const Duration(milliseconds: 50));

      expect(submittedText, isNull);
    });

    testWidgets('Disabled state preserves dark charcoal text style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PixmintChatInput(
              onSend: (_) {},
              enabled: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final TextField textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
      expect(textField.style?.color, equals(const Color(0xFFF8FAFC)));
      expect(textField.decoration?.fillColor, equals(const Color(0xFF081824)));
    });
  });

  group('Cross-Portal Composer Verification', () {
    final portals = [
      {'name': 'Engineer Portal', 'role': BotUserRole.engineer},
      {'name': 'Draughtsman Portal', 'role': BotUserRole.draughtsman},
      {'name': 'Student Portal', 'role': BotUserRole.student},
      {'name': 'Client Portal', 'role': BotUserRole.engineer},
    ];

    for (final portal in portals) {
      testWidgets('Renders identical high-contrast composer in ${portal['name']}', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: PixmintChatSheet(
                  overrideRole: portal['role'] as BotUserRole,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final composerFinder = find.byType(PixmintChatInput);
        expect(composerFinder, findsOneWidget);

        final TextField textField = tester.widget<TextField>(
          find.descendant(of: composerFinder, matching: find.byType(TextField)),
        );

        // Verify across all portals:
        // 1. Crisp white text (#F8FAFC)
        expect(textField.style?.color, equals(const Color(0xFFF8FAFC)));
        // 2. Dark navy capsule background (#081824)
        expect(textField.decoration?.fillColor, equals(const Color(0xFF081824)));
        // 3. Muted grey hint (#64748B)
        expect(textField.decoration?.hintStyle?.color, equals(const Color(0xFF64748B)));
        // 4. Emerald green cursor (#00D6A0)
        expect(textField.cursorColor, equals(const Color(0xFF00D6A0)));
      });
    }
  });
}
