import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archi_draft/src/features/auth/domain/user_profile.dart';
import 'package:archi_draft/src/features/pixmint_bot/data/repositories/mock_pixmint_bot_repository.dart';
import 'package:archi_draft/src/features/pixmint_bot/domain/models/bot_user_role.dart';
import 'package:archi_draft/src/features/pixmint_bot/presentation/launcher/pixmint_bot_launcher.dart';
import 'package:archi_draft/src/features/pixmint_bot/presentation/sheet/pixmint_chat_sheet.dart';
import 'package:archi_draft/src/features/pixmint_bot/presentation/widgets/error_retry_banner.dart';
import 'package:archi_draft/src/features/pixmint_bot/providers/pixmint_bot_providers.dart';
import 'package:archi_draft/src/features/shell/presentation/widgets/app_bottom_nav.dart';
import 'package:archi_draft/src/features/shell/presentation/widgets/responsive_scaffold.dart';

void main() {
  const sampleDestinations = [
    NavDestination(label: 'Home', icon: Icons.home, route: '/home'),
    NavDestination(label: 'Projects', icon: Icons.work, route: '/projects'),
  ];

  UserProfile makeProfile(String role) => UserProfile(
        id: 'usr-test-1',
        name: 'Test Engineer',
        email: 'test@example.com',
        mobile: '1234567890',
        role: role,
      );

  group('PIXMINT BOT Responsive Shell & Viewport Placement', () {
    testWidgets('Mobile viewport (<600px) places launcher with bottom navigation clearance', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockPixmintBotRepository(simulatedDelay: Duration.zero);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pixmintRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: ResponsiveScaffold(
              selectedIndex: 0,
              destinations: sampleDestinations,
              onDestinationSelected: (_) {},
              profile: makeProfile('ENGINEER'),
              body: const Center(child: Text('Mobile Workspace')),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PixmintBotLauncher), findsOneWidget);

      // Verify positioned coordinates
      final positioned = tester.widget<Positioned>(
        find.ancestor(
          of: find.byType(PixmintBotLauncher),
          matching: find.byType(Positioned),
        ),
      );
      expect(positioned.bottom, equals(84.0));
      expect(positioned.right, equals(16.0));
    });

    testWidgets('Desktop viewport (>=1200px) places launcher at bottom: 40, right: 40', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockPixmintBotRepository(simulatedDelay: Duration.zero);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pixmintRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: ResponsiveScaffold(
              selectedIndex: 0,
              destinations: sampleDestinations,
              onDestinationSelected: (_) {},
              profile: makeProfile('DRAUGHTSMAN'),
              body: const Center(child: Text('Desktop Workspace')),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PixmintBotLauncher), findsOneWidget);

      final positioned = tester.widget<Positioned>(
        find.ancestor(
          of: find.byType(PixmintBotLauncher),
          matching: find.byType(Positioned),
        ),
      );
      expect(positioned.bottom, equals(40.0));
      expect(positioned.right, equals(32.0));
    });

    testWidgets('Role authorization hides launcher on ADMIN role and when navigation hidden', (tester) async {
      final mockRepo = MockPixmintBotRepository(simulatedDelay: Duration.zero);

      // Admin role must NOT show launcher (managed via Next.js /bot)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pixmintRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: ResponsiveScaffold(
              selectedIndex: 0,
              destinations: sampleDestinations,
              onDestinationSelected: (_) {},
              profile: makeProfile('ADMIN'),
              body: const Center(child: Text('Admin Workspace')),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(PixmintBotLauncher), findsNothing);

      // Explicit hideNavigation must NOT show launcher
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pixmintRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: ResponsiveScaffold(
              selectedIndex: 0,
              destinations: sampleDestinations,
              onDestinationSelected: (_) {},
              profile: makeProfile('ENGINEER'),
              hideNavigation: true,
              body: const Center(child: Text('Login Page')),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(PixmintBotLauncher), findsNothing);
    });

    testWidgets('Chat sheet renders bounded dialog container on desktop', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockPixmintBotRepository(simulatedDelay: Duration.zero);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pixmintRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PixmintChatSheet(
                overrideRole: BotUserRole.student,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PixmintChatSheet), findsOneWidget);
      final constrainedBox = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(PixmintChatSheet),
          matching: find.byType(ConstrainedBox),
        ).first,
      );
      expect(constrainedBox.constraints.maxWidth, equals(480.0));
    });

    testWidgets('ErrorRetryBanner displays error message and triggers retry callback', (tester) async {
      bool retryTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ErrorRetryBanner(
                message: 'Unable to connect to ARCHI DRAFT AI service.',
                onRetry: () => retryTriggered = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Unable to connect to ARCHI DRAFT AI service.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryTriggered, isTrue);
    });
  });
}
