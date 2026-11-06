import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:archi_draft/src/features/pixmint_bot/data/repositories/archi_draft_pixmint_bot_repository.dart';
import 'package:archi_draft/src/features/pixmint_bot/data/repositories/mock_pixmint_bot_repository.dart';
import 'package:archi_draft/src/features/pixmint_bot/domain/models/bot_user_role.dart';
import 'package:archi_draft/src/features/pixmint_bot/domain/models/chat_message.dart';
import 'package:archi_draft/src/features/pixmint_bot/domain/models/pixmint_default_suggestions.dart';
import 'package:archi_draft/src/features/pixmint_bot/presentation/animation/mascot_animation_state.dart';
import 'package:archi_draft/src/features/pixmint_bot/presentation/launcher/pixmint_bot_launcher.dart';
import 'package:archi_draft/src/features/pixmint_bot/presentation/launcher/pixmint_mascot_painter.dart';
import 'package:archi_draft/src/features/pixmint_bot/providers/pixmint_bot_providers.dart';

void main() {
  group('BotUserRole & Suggestions', () {
    test('Role string normalization and mapping', () {
      expect(BotUserRole.fromString('ENGINEER'), equals(BotUserRole.engineer));
      expect(BotUserRole.fromString('CLIENT'), equals(BotUserRole.engineer));
      expect(BotUserRole.fromString('DRAUGHTSMAN'), equals(BotUserRole.draughtsman));
      expect(BotUserRole.fromString('STUDENT'), equals(BotUserRole.student));
      expect(BotUserRole.fromString('ADMIN'), equals(BotUserRole.admin));
      expect(BotUserRole.fromString('STUDIO_ADMIN'), equals(BotUserRole.admin));
      expect(BotUserRole.fromString('unknown_role'), equals(BotUserRole.guest));
    });

    test('Default suggestions return distinct prompts per role', () {
      final engSuggestions = PixmintDefaultSuggestions.getForRole(BotUserRole.engineer);
      final drgSuggestions = PixmintDefaultSuggestions.getForRole(BotUserRole.draughtsman);
      final stuSuggestions = PixmintDefaultSuggestions.getForRole(BotUserRole.student);
      final admSuggestions = PixmintDefaultSuggestions.getForRole(BotUserRole.admin);

      expect(engSuggestions, isNotEmpty);
      expect(drgSuggestions, isNotEmpty);
      expect(stuSuggestions, isNotEmpty);
      expect(admSuggestions, isNotEmpty);

      // Verify role-specific domain specialization
      expect(engSuggestions.any((s) => s.prompt.toLowerCase().contains('drawing') || s.prompt.toLowerCase().contains('review')), isTrue);
      expect(drgSuggestions.any((s) => s.prompt.toLowerCase().contains('drawing') || s.prompt.toLowerCase().contains('upload')), isTrue);
      expect(stuSuggestions.any((s) => s.prompt.toLowerCase().contains('training') || s.prompt.toLowerCase().contains('exercise')), isTrue);
      expect(admSuggestions.any((s) => s.prompt.toLowerCase().contains('knowledge') || s.prompt.toLowerCase().contains('metrics') || s.prompt.toLowerCase().contains('status')), isTrue);
    });
  });

  group('ArchiDraftPixmintBotRepository HTTP Contracts', () {
    test('Injects Authorization header and parses successful status', () async {
      String? capturedAuthHeader;
      final mockClient = MockClient((request) async {
        capturedAuthHeader = request.headers['Authorization'];
        if (request.url.path == '/api/pixmint/chat/status') {
          return http.Response(
            jsonEncode({
              'enabled': true,
              'maintenanceMode': false,
              'modelName': 'gemini-1.5-flash',
              'portalAccess': {'engineer': true, 'draughtsman': true, 'student': true, 'admin': true},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final repo = ArchiDraftPixmintBotRepository(
        baseUrl: 'https://staging.archidraft.test',
        authTokenGetter: () async => 'test-firebase-id-token-xyz',
        client: mockClient,
      );

      final status = await repo.checkBotStatus();

      expect(capturedAuthHeader, equals('Bearer test-firebase-id-token-xyz'));
      expect(status['enabled'], isTrue);
      expect(status['modelName'], equals('gemini-1.5-flash'));
    });

    test('Throws PixmintAuthException on 401 Unauthorized', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Unauthorized', 'code': 'UNAUTHORIZED'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = ArchiDraftPixmintBotRepository(
        baseUrl: 'https://staging.archidraft.test',
        client: mockClient,
      );

      expect(
        () => repo.getOrCreateSession(role: BotUserRole.engineer),
        throwsA(isA<PixmintAuthException>()),
      );
    });

    test('Throws PixmintServiceUnavailableException on 503 Maintenance', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Service undergoing maintenance', 'code': 'MAINTENANCE_MODE'}),
          503,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = ArchiDraftPixmintBotRepository(
        baseUrl: 'https://staging.archidraft.test',
        client: mockClient,
      );

      expect(
        () => repo.sendMessage(
          sessionId: 'sess-123',
          content: 'Hello bot',
          role: BotUserRole.draughtsman,
        ),
        throwsA(isA<PixmintServiceUnavailableException>()),
      );
    });

    test('Sends chat message and correctly parses response payload', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/pixmint/chat/sessions/sess-abc/messages') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['content'], equals('Explain floor plans'));
          expect(body['role'], equals('engineer'));

          return http.Response(
            jsonEncode({
              'id': 'msg-999',
              'sessionId': 'sess-abc',
              'sender': 'bot',
              'content': 'Floor plans provide a top-down architectural layout.',
              'timestamp': '2026-11-06T12:00:00Z',
              'isGreeting': false,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final repo = ArchiDraftPixmintBotRepository(
        baseUrl: 'https://staging.archidraft.test',
        client: mockClient,
      );

      final msg = await repo.sendMessage(
        sessionId: 'sess-abc',
        content: 'Explain floor plans',
        role: BotUserRole.engineer,
      );

      expect(msg.id, equals('msg-999'));
      expect(msg.sender, equals(MessageSender.bot));
      expect(msg.content, contains('Floor plans provide'));
    });
  });

  group('PixmintChatController Riverpod 3.x State Management', () {
    test('Initializes with greeting and transitions to ready state', () async {
      final mockRepo = MockPixmintBotRepository(simulatedDelay: Duration.zero);
      final container = ProviderContainer(
        overrides: [
          pixmintRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      container.read(pixmintChatControllerProvider);
      // Allow microtask initializeSession to execute
      await Future<void>.delayed(Duration.zero);

      final state = container.read(pixmintChatControllerProvider);

      expect(state.messages, isNotEmpty);
      expect(state.messages.first.sender, equals(MessageSender.bot));
      expect(state.isThinking, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('sendMessage appends optimistic user message and streams bot reply', () async {
      final mockRepo = MockPixmintBotRepository(simulatedDelay: Duration.zero);
      final container = ProviderContainer(
        overrides: [
          pixmintRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(pixmintChatControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      await controller.sendMessage('How do I submit an elevation drawing?');

      final state = container.read(pixmintChatControllerProvider);
      expect(state.messages.length, greaterThanOrEqualTo(2));
      expect(state.messages.any((m) => m.content == 'How do I submit an elevation drawing?'), isTrue);
      expect(state.isThinking, isFalse);
      expect(state.errorMessage, isNull);
    });
  });

  group('Pixmint UI & Mascot Widgets', () {
    testWidgets('PixmintRobotAvatar renders without layout exceptions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PixmintRobotAvatar(
                size: 48,
                state: MascotAnimationState.idle,
                animate: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PixmintRobotAvatar), findsOneWidget);
    });

    testWidgets('PixmintBotLauncher displays launcher icon and pulses', (tester) async {
      final mockRepo = MockPixmintBotRepository(simulatedDelay: Duration.zero);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pixmintRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  PixmintBotLauncher(animate: false),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PixmintBotLauncher), findsOneWidget);
      expect(find.byType(PixmintRobotAvatar), findsOneWidget);
    });
  });
}
