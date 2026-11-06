import 'dart:async';
import 'package:uuid/uuid.dart';

import '../../domain/engine/pixmint_knowledge_engine.dart';
import '../../domain/models/bot_user_role.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_session.dart';
import '../../domain/models/chat_suggestion.dart';
import '../../domain/models/pixmint_default_suggestions.dart';
import '../../domain/repositories/pixmint_bot_repository.dart';

/// Standalone repository for PIXMINT BOT operating via the local
/// [PixmintKnowledgeEngine].
///
/// Delivers natural, grounded, role-aware architectural & engineering answers
/// based on authoritative Archi Draft platform workflows.
class MockPixmintBotRepository implements PixmintBotRepository {
  final _uuid = const Uuid();
  final Duration simulatedDelay;
  bool shouldSimulateFailure = false;

  final Map<String, ChatSession> _sessions = {};
  final Map<String, List<ChatMessage>> _messages = {};

  MockPixmintBotRepository({
    this.simulatedDelay = const Duration(milliseconds: 600),
  });

  @override
  Future<ChatSession> getOrCreateSession({
    required BotUserRole role,
    String? existingSessionId,
    bool newSession = false,
  }) async {
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }

    if (!newSession && existingSessionId != null && _sessions.containsKey(existingSessionId)) {
      return _sessions[existingSessionId]!;
    }

    // Reuse existing active session if not forced new
    if (!newSession && _sessions.isNotEmpty) {
      final active = _sessions.values.where((s) => !s.isArchived).lastOrNull;
      if (active != null) return active;
    }

    final sessionId =
        existingSessionId ?? 'session_${_uuid.v4().substring(0, 8)}';
    final now = DateTime.now();

    final welcomeMessage = ChatMessage(
      id: 'msg_${_uuid.v4().substring(0, 8)}',
      sessionId: sessionId,
      sender: MessageSender.bot,
      content: _getWelcomeMessage(role),
      createdAt: now,
      status: MessageStatus.sent,
      sources: const [],
    );

    final session = ChatSession(
      id: sessionId,
      title: '${role.displayName} Assistant Session',
      role: role,
      createdAt: now,
      updatedAt: now,
      messages: [welcomeMessage],
    );

    _sessions[sessionId] = session;
    _messages[sessionId] = [welcomeMessage];

    return session;
  }

  @override
  Future<List<ChatSession>> listSessions() async {
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }
    return _sessions.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<ChatMessage>> getMessages(String sessionId) async {
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }
    return _messages[sessionId] ?? [];
  }

  @override
  Future<ChatMessage> sendMessage({
    required String sessionId,
    required String content,
    required BotUserRole role,
    Map<String, dynamic>? clientContext,
    List<ChatMessage>? history,
  }) async {
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }

    if (shouldSimulateFailure) {
      throw Exception(
        'Simulated network timeout while contacting PIXMINT BOT service.',
      );
    }

    final userMessage = ChatMessage(
      id: 'msg_${_uuid.v4().substring(0, 8)}',
      sessionId: sessionId,
      sender: MessageSender.user,
      content: content,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
    );

    _messages.putIfAbsent(sessionId, () => []).add(userMessage);

    // Formulate intent-aware verified response using conversation history
    final fullHistory = history ?? _messages[sessionId] ?? [];
    final engineAnswer = PixmintKnowledgeEngine.resolve(
      prompt: content,
      role: role,
      conversationHistory: fullHistory,
    );

    final botMessage = ChatMessage(
      id: 'msg_${_uuid.v4().substring(0, 8)}',
      sessionId: sessionId,
      sender: MessageSender.bot,
      content: engineAnswer.content,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
      sources: engineAnswer.sources,
    );

    _messages[sessionId]!.add(botMessage);

    if (_sessions.containsKey(sessionId)) {
      _sessions[sessionId] = _sessions[sessionId]!.copyWith(
        updatedAt: DateTime.now(),
        messages: List.from(_messages[sessionId]!),
      );
    }

    return botMessage;
  }

  @override
  Future<List<ChatSuggestion>> getSuggestions(BotUserRole role) async {
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (shouldSimulateFailure) {
      throw Exception('Simulated network failure fetching suggestions');
    }

    return PixmintDefaultSuggestions.getForRole(role);
  }

  @override
  Future<void> clearSession(String sessionId) async {
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _sessions.remove(sessionId);
    _messages.remove(sessionId);
  }

  @override
  Future<Map<String, dynamic>> checkBotStatus() async {
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return {
      'status': 'online',
      'botEnabled': true,
      'maintenanceMode': false,
      'version': '2.0.0',
    };
  }

  @override
  Future<void> archiveSession(String sessionId) async {
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _sessions.remove(sessionId);
  }

  @override
  Future<void> submitFeedback({
    required String messageId,
    required int rating,
    String? feedbackText,
  }) async {
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Official welcome message matching the character sheet & chat mockup
  String _getWelcomeMessage(BotUserRole role) {
    final roleName = role.displayName;
    return "Hi $roleName! 👋 I'm **PIXMINT BOT**, your intelligent AI companion for Archi Draft.\n\n"
        "I can help you with project creation, CAD drawing standards, review workflows, assignments, and troubleshooting.\n\n"
        "What can I help you with today?";
  }
}
