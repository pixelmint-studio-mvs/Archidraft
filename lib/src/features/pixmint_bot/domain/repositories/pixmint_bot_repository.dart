import '../models/bot_user_role.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/chat_suggestion.dart';

/// Abstract repository defining the communication contract for PIXMINT BOT.
///
/// Implementations can be a local Mock repository (for offline/testing)
/// or an authenticated remote repository connecting to ARCHI DRAFT's Cloudflare Worker.
abstract class PixmintBotRepository {
  /// Checks whether PIXMINT BOT service is online, maintenance, or disabled.
  Future<Map<String, dynamic>> checkBotStatus();

  /// Initializes or retrieves an active chat session for the specified role.
  Future<ChatSession> getOrCreateSession({
    required BotUserRole role,
    String? existingSessionId,
    bool newSession = false,
  });

  /// Lists past sessions for the current authenticated user.
  Future<List<ChatSession>> listSessions();

  /// Loads the message history for a given session.
  Future<List<ChatMessage>> getMessages(String sessionId);

  /// Sends a user message to PIXMINT BOT and retrieves the response.
  Future<ChatMessage> sendMessage({
    required String sessionId,
    required String content,
    required BotUserRole role,
    Map<String, dynamic>? clientContext,
    List<ChatMessage>? history,
  });

  /// Retrieves role-aware suggestion chips to help the user get started.
  Future<List<ChatSuggestion>> getSuggestions(BotUserRole role);

  /// Archives a conversation session.
  Future<void> archiveSession(String sessionId);

  /// Clears or deletes a session.
  Future<void> clearSession(String sessionId);

  /// Submits user rating (+1 / -1) and optional feedback for a bot message.
  Future<void> submitFeedback({
    required String messageId,
    required int rating,
    String? feedbackText,
  });
}
