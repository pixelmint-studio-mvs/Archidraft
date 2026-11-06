import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../../domain/models/bot_user_role.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_session.dart';
import '../../domain/models/chat_suggestion.dart';
import '../../domain/repositories/pixmint_bot_repository.dart';

/// Exception thrown when PIXMINT BOT communication fails.
class PixmintException implements Exception {
  final String message;
  final int? statusCode;

  const PixmintException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class PixmintAuthException extends PixmintException {
  const PixmintAuthException(super.message, [super.statusCode = 401]);
}

class PixmintServiceUnavailableException extends PixmintException {
  const PixmintServiceUnavailableException(super.message, [super.statusCode = 503]);
}

class PixmintNetworkException extends PixmintException {
  const PixmintNetworkException(super.message);
}

/// Production HTTP repository for PIXMINT BOT connecting to the ARCHI DRAFT
/// Cloudflare Worker backend API.
///
/// Features:
/// - Authenticated Bearer token injection from Firebase Auth
/// - Resilient timeout handling
/// - Direct integration with `/api/pixmint/chat/` endpoints
/// - Fail-loud error propagation (no silent mock fallback in production)
class ArchiDraftPixmintBotRepository implements PixmintBotRepository {
  final String baseUrl;
  final Future<String?> Function()? authTokenGetter;
  final http.Client _client;
  final PixmintBotRepository? _fallbackRepo;
  final Duration timeout;

  ArchiDraftPixmintBotRepository({
    this.baseUrl = 'https://archi-draft-worker-staging.imserratex.workers.dev',
    this.authTokenGetter,
    http.Client? client,
    PixmintBotRepository? fallbackRepo,
    this.timeout = const Duration(seconds: 12),
  })  : _client = client ?? http.Client(),
        // ignore: prefer_initializing_formals
        _fallbackRepo = fallbackRepo;

  String _cleanUrl(String path) {
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$cleanBase$cleanPath';
  }

  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authTokenGetter != null) {
      try {
        final token = await authTokenGetter!();
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        throw PixmintAuthException('Failed to retrieve authentication credentials: $e');
      }
    }

    return headers;
  }

  Never _handleHttpError(http.Response response, String defaultMessage) {
    String errorMsg = defaultMessage;
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['error'] != null) {
        errorMsg = data['error'].toString();
      }
    } catch (_) {}

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw PixmintAuthException(errorMsg, response.statusCode);
    }
    if (response.statusCode == 503) {
      throw PixmintServiceUnavailableException(errorMsg, response.statusCode);
    }
    throw PixmintException(errorMsg, response.statusCode);
  }

  @override
  Future<Map<String, dynamic>> checkBotStatus() async {
    try {
      final headers = await _buildHeaders();
      final uri = Uri.parse(_cleanUrl('/api/pixmint/chat/status'));
      final response = await _client.get(uri, headers: headers).timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      _handleHttpError(response, 'Failed to fetch bot service status.');
    } on PixmintException {
      rethrow;
    } on SocketException catch (e) {
      if (_fallbackRepo != null) return _fallbackRepo.checkBotStatus();
      throw PixmintNetworkException('Network connection failed: ${e.message}');
    } on TimeoutException {
      if (_fallbackRepo != null) return _fallbackRepo.checkBotStatus();
      throw const PixmintNetworkException('PIXMINT BOT connection timed out. Please retry.');
    } catch (e) {
      if (_fallbackRepo != null) return _fallbackRepo.checkBotStatus();
      throw PixmintNetworkException('Connection failed: $e');
    }
  }

  @override
  Future<ChatSession> getOrCreateSession({
    required BotUserRole role,
    String? existingSessionId,
    bool newSession = false,
  }) async {
    try {
      final headers = await _buildHeaders();
      final uri = Uri.parse(_cleanUrl('/api/pixmint/chat/sessions'));
      final response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'role': role.name,
              if (existingSessionId != null) 'sessionId': existingSessionId,
              if (newSession) 'newSession': true,
            }),
          )
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ChatSession.fromJson(data);
      }
      _handleHttpError(response, 'Failed to initialize conversation session.');
    } on PixmintException {
      rethrow;
    } on SocketException catch (e) {
      if (_fallbackRepo != null) {
        return _fallbackRepo.getOrCreateSession(
          role: role,
          existingSessionId: existingSessionId,
          newSession: newSession,
        );
      }
      throw PixmintNetworkException('Network connection failed: ${e.message}');
    } on TimeoutException {
      if (_fallbackRepo != null) {
        return _fallbackRepo.getOrCreateSession(
          role: role,
          existingSessionId: existingSessionId,
          newSession: newSession,
        );
      }
      throw const PixmintNetworkException('Connection timed out while initializing session.');
    } catch (e) {
      if (_fallbackRepo != null) {
        return _fallbackRepo.getOrCreateSession(
          role: role,
          existingSessionId: existingSessionId,
          newSession: newSession,
        );
      }
      throw PixmintNetworkException('Failed to create session: $e');
    }
  }

  @override
  Future<List<ChatSession>> listSessions() async {
    try {
      final headers = await _buildHeaders();
      final uri = Uri.parse(_cleanUrl('/api/pixmint/chat/sessions'));
      final response = await _client.get(uri, headers: headers).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data.map((item) => ChatSession.fromJson(item as Map<String, dynamic>)).toList();
      }
      _handleHttpError(response, 'Failed to retrieve conversation history.');
    } on PixmintException {
      rethrow;
    } on SocketException catch (e) {
      if (_fallbackRepo != null) return _fallbackRepo.listSessions();
      throw PixmintNetworkException('Network connection failed: ${e.message}');
    } on TimeoutException {
      if (_fallbackRepo != null) return _fallbackRepo.listSessions();
      throw const PixmintNetworkException('Connection timed out while listing sessions.');
    } catch (e) {
      if (_fallbackRepo != null) return _fallbackRepo.listSessions();
      throw PixmintNetworkException('Failed to list sessions: $e');
    }
  }

  @override
  Future<List<ChatMessage>> getMessages(String sessionId) async {
    try {
      final headers = await _buildHeaders();
      final uri = Uri.parse(_cleanUrl('/api/pixmint/chat/sessions/$sessionId/messages'));
      final response = await _client.get(uri, headers: headers).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data.map((item) => ChatMessage.fromJson(item as Map<String, dynamic>)).toList();
      }
      _handleHttpError(response, 'Failed to fetch session messages.');
    } on PixmintException {
      rethrow;
    } on SocketException catch (e) {
      if (_fallbackRepo != null) return _fallbackRepo.getMessages(sessionId);
      throw PixmintNetworkException('Network connection failed: ${e.message}');
    } on TimeoutException {
      if (_fallbackRepo != null) return _fallbackRepo.getMessages(sessionId);
      throw const PixmintNetworkException('Connection timed out while loading messages.');
    } catch (e) {
      if (_fallbackRepo != null) return _fallbackRepo.getMessages(sessionId);
      throw PixmintNetworkException('Failed to fetch messages: $e');
    }
  }

  @override
  Future<ChatMessage> sendMessage({
    required String sessionId,
    required String content,
    required BotUserRole role,
    Map<String, dynamic>? clientContext,
    List<ChatMessage>? history,
  }) async {
    try {
      final headers = await _buildHeaders();
      final uri = Uri.parse(_cleanUrl('/api/pixmint/chat/sessions/$sessionId/messages'));
      final recentHistory = (history ?? []).take(6).map((m) => <String, String>{
            'sender': m.sender == MessageSender.user ? 'user' : 'bot',
            'content': m.content,
          }).toList();

      final response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'content': content,
              'role': role.name,
              if (recentHistory.isNotEmpty) 'history': recentHistory,
              'clientContext': ?clientContext,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ChatMessage.fromJson(data);
      }
      _handleHttpError(response, 'Failed to send message.');
    } on PixmintException {
      rethrow;
    } on SocketException catch (e) {
      if (_fallbackRepo != null) {
        return _fallbackRepo.sendMessage(
          sessionId: sessionId,
          content: content,
          role: role,
          clientContext: clientContext,
          history: history,
        );
      }
      throw PixmintNetworkException('Network connection failed: ${e.message}');
    } on TimeoutException {
      if (_fallbackRepo != null) {
        return _fallbackRepo.sendMessage(
          sessionId: sessionId,
          content: content,
          role: role,
          clientContext: clientContext,
          history: history,
        );
      }
      throw const PixmintNetworkException('Message dispatch timed out. Please tap retry.');
    } catch (e) {
      if (_fallbackRepo != null) {
        return _fallbackRepo.sendMessage(
          sessionId: sessionId,
          content: content,
          role: role,
          clientContext: clientContext,
          history: history,
        );
      }
      throw PixmintNetworkException('Failed to deliver message: $e');
    }
  }

  @override
  Future<List<ChatSuggestion>> getSuggestions(BotUserRole role) async {
    try {
      final headers = await _buildHeaders();
      final uri = Uri.parse(_cleanUrl('/api/pixmint/chat/suggestions?role=${role.name}'));
      final response = await _client.get(uri, headers: headers).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final suggestions = data.map((item) => ChatSuggestion.fromJson(item as Map<String, dynamic>)).toList();
        if (suggestions.isNotEmpty) return suggestions;
      }
    } catch (_) {
      // Suggestions failure is non-fatal; caller will fall back to static default catalog
    }

    if (_fallbackRepo != null) {
      return _fallbackRepo.getSuggestions(role);
    }
    return const [];
  }

  @override
  Future<void> archiveSession(String sessionId) async {
    try {
      final headers = await _buildHeaders();
      final uri = Uri.parse(_cleanUrl('/api/pixmint/chat/sessions/$sessionId/archive'));
      final response = await _client.patch(uri, headers: headers).timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }
      _handleHttpError(response, 'Failed to archive session.');
    } on PixmintException {
      rethrow;
    } catch (e) {
      if (_fallbackRepo != null) return _fallbackRepo.archiveSession(sessionId);
      throw PixmintNetworkException('Archive failed: $e');
    }
  }

  @override
  Future<void> clearSession(String sessionId) async {
    try {
      final headers = await _buildHeaders();
      final uri = Uri.parse(_cleanUrl('/api/pixmint/chat/sessions/$sessionId/archive'));
      await _client.patch(uri, headers: headers).timeout(timeout);
    } catch (_) {}

    if (_fallbackRepo != null) {
      return _fallbackRepo.clearSession(sessionId);
    }
  }

  @override
  Future<void> submitFeedback({
    required String messageId,
    required int rating,
    String? feedbackText,
  }) async {
    try {
      final headers = await _buildHeaders();
      final uri = Uri.parse(_cleanUrl('/api/pixmint/chat/feedback'));
      final response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'messageId': messageId,
              'rating': rating,
              'feedbackText': ?feedbackText,
            }),
          )
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }
      _handleHttpError(response, 'Failed to submit feedback.');
    } on PixmintException {
      rethrow;
    } catch (e) {
      if (_fallbackRepo != null) {
        return _fallbackRepo.submitFeedback(
          messageId: messageId,
          rating: rating,
          feedbackText: feedbackText,
        );
      }
      throw PixmintNetworkException('Feedback submission failed: $e');
    }
  }
}
