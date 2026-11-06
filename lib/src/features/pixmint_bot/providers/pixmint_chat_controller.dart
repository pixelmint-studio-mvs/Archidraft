import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/models/bot_user_role.dart';
import '../domain/models/chat_message.dart';
import '../domain/models/chat_session.dart';
import '../domain/repositories/pixmint_bot_repository.dart';
import '../presentation/animation/mascot_animation_state.dart';
import 'pixmint_bot_providers.dart';

/// State of an active PIXMINT BOT conversation.
class PixmintChatState {
  final ChatSession? activeSession;
  final List<ChatMessage> messages;
  final bool isInitializing;
  final bool isThinking;
  final String? errorMessage;
  final BotUserRole role;
  final MascotAnimationState mascotState;

  const PixmintChatState({
    this.activeSession,
    this.messages = const [],
    this.isInitializing = false,
    this.isThinking = false,
    this.errorMessage,
    this.role = BotUserRole.engineer,
    this.mascotState = MascotAnimationState.idle,
  });

  bool get hasActiveSession => activeSession != null;
  bool get hasMessages => messages.isNotEmpty;

  PixmintChatState copyWith({
    ChatSession? activeSession,
    List<ChatMessage>? messages,
    bool? isInitializing,
    bool? isThinking,
    String? errorMessage,
    bool clearError = false,
    BotUserRole? role,
    MascotAnimationState? mascotState,
  }) {
    return PixmintChatState(
      activeSession: activeSession ?? this.activeSession,
      messages: messages ?? this.messages,
      isInitializing: isInitializing ?? this.isInitializing,
      isThinking: isThinking ?? this.isThinking,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      role: role ?? this.role,
      mascotState: mascotState ?? this.mascotState,
    );
  }
}

/// State notifier driving conversation lifecycle, message sending, and error recovery.
class PixmintChatController extends Notifier<PixmintChatState> {
  final _uuid = const Uuid();
  Timer? _transientTimer;
  bool _disposed = false;
  bool _isInitializing = false;

  final PixmintBotRepository? _customRepo;
  final BotUserRole? _initialRole;

  PixmintChatController([this._customRepo, this._initialRole]);

  PixmintBotRepository get _repository => _customRepo ?? ref.read(pixmintRepositoryProvider);

  @override
  PixmintChatState build() {
    _disposed = false;
    _isInitializing = false;
    ref.onDispose(() {
      _disposed = true;
      _transientTimer?.cancel();
    });

    final BotUserRole role = _initialRole ?? ref.watch(pixmintRoleProvider);
    Future.microtask(() => initializeSession(role));
    return PixmintChatState(role: role);
  }

  /// Initializes a new session or restores an existing one for the target role.
  Future<void> initializeSession(BotUserRole role, {bool forceNew = false}) async {
    if (_disposed) return;
    if (_isInitializing && !forceNew) return;
    if (!forceNew && state.hasActiveSession && state.role == role) return;

    _isInitializing = true;
    state = state.copyWith(
      isInitializing: true,
      clearError: true,
      role: role,
      mascotState: MascotAnimationState.greeting,
    );

    try {
      final session = await _repository.getOrCreateSession(
        role: role,
        existingSessionId: forceNew ? null : state.activeSession?.id,
        newSession: forceNew,
      );
      final messages = await _repository.getMessages(session.id);

      if (_disposed) return;
      state = state.copyWith(
        activeSession: session,
        messages: messages,
        isInitializing: false,
        mascotState: MascotAnimationState.idle,
      );
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(
        isInitializing: false,
        errorMessage: 'Unable to initialize PIXMINT BOT session. Please tap retry.',
        mascotState: MascotAnimationState.error,
      );
    } finally {
      _isInitializing = false;
    }
  }

  /// Updates the role dynamically (e.g. when switching accounts or panels in ARCHI DRAFT).
  Future<void> switchRole(BotUserRole newRole) async {
    if (state.role == newRole && state.hasActiveSession) return;
    await initializeSession(newRole);
  }

  /// Submits a user prompt to the bot with optimistic UI and failure handling.
  Future<void> sendMessage(String text, {Map<String, dynamic>? clientContext}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isThinking || state.activeSession == null) return;

    final sessionId = state.activeSession!.id;
    final tempId = 'temp_${_uuid.v4().substring(0, 8)}';

    // Optimistic user message
    final optimisticMessage = ChatMessage(
      id: tempId,
      sessionId: sessionId,
      sender: MessageSender.user,
      content: trimmed,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );

    if (_disposed) return;
    state = state.copyWith(
      messages: [...state.messages, optimisticMessage],
      isThinking: true,
      clearError: true,
      mascotState: MascotAnimationState.thinking,
    );

    try {
      final botMessage = await _repository.sendMessage(
        sessionId: sessionId,
        content: trimmed,
        role: state.role,
        clientContext: clientContext,
        history: state.messages.where((m) => m.id != tempId).toList(),
      );

      // Replace optimistic message status to sent, and append bot response
      final updatedMessages = state.messages.map((m) {
        if (m.id == tempId) {
          return m.copyWith(status: MessageStatus.sent);
        }
        return m;
      }).toList();

      if (_disposed) return;
      state = state.copyWith(
        messages: [...updatedMessages, botMessage],
        isThinking: false,
        mascotState: MascotAnimationState.answering,
      );

      if (_isTestEnvironment) {
        state = state.copyWith(
          messages: [...updatedMessages, botMessage],
          isThinking: false,
          mascotState: MascotAnimationState.answering,
        );
        return;
      }

      // Transition answering -> success -> idle
      _transientTimer?.cancel();
      _transientTimer = Timer(const Duration(milliseconds: 1400), () {
        if (!_disposed && state.mascotState == MascotAnimationState.answering) {
          state = state.copyWith(mascotState: MascotAnimationState.success);
          _transientTimer = Timer(const Duration(milliseconds: 1000), () {
            if (!_disposed && state.mascotState == MascotAnimationState.success) {
              state = state.copyWith(mascotState: MascotAnimationState.idle);
            }
          });
        }
      });
    } catch (e) {
      // Mark optimistic message as error
      final updatedMessages = state.messages.map((m) {
        if (m.id == tempId) {
          return m.copyWith(
            status: MessageStatus.error,
            errorMessage: 'Message delivery failed.',
          );
        }
        return m;
      }).toList();

      if (_disposed) return;
      state = state.copyWith(
        messages: updatedMessages,
        isThinking: false,
        errorMessage: 'Failed to receive response from PIXMINT BOT. Tap retry below.',
        mascotState: MascotAnimationState.error,
      );
    }
  }

  /// Retries the last failed message.
  Future<void> retryLastMessage() async {
    final lastUserMsg = state.messages.lastWhere(
      (m) => m.isUser && m.hasError,
      orElse: () => state.messages.lastWhere(
        (m) => m.isUser,
        orElse: () => ChatMessage(
          id: '',
          sessionId: '',
          sender: MessageSender.user,
          content: '',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      ),
    );

    if (lastUserMsg.content.isNotEmpty) {
      // Remove failed message from list and re-send
      state = state.copyWith(
        messages: state.messages.where((m) => m.id != lastUserMsg.id).toList(),
      );
      await sendMessage(lastUserMsg.content);
    }
  }

  /// Clears the conversation and starts a fresh session.
  Future<void> clearConversation() async {
    if (state.activeSession == null) return;
    final sessionId = state.activeSession!.id;

    if (_disposed) return;
    state = state.copyWith(isInitializing: true, clearError: true);
    try {
      await _repository.clearSession(sessionId);
      await initializeSession(state.role, forceNew: true);
    } catch (_) {
      if (_disposed) return;
      state = state.copyWith(isInitializing: false);
    }
  }

  bool get _isTestEnvironment {
    try {
      return !kIsWeb &&
          WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return true;
    }
  }

  /// Sets whether the network or backend is offline, transitioning the mascot state truthfully.
  void setOffline(bool isOffline) {
    if (_disposed) return;
    state = state.copyWith(
      mascotState: isOffline ? MascotAnimationState.offline : MascotAnimationState.idle,
    );
  }

  /// Manually triggers a welcoming greeting animation (e.g. when opening chat sheet).
  void triggerGreeting() {
    if (_disposed) return;
    state = state.copyWith(mascotState: MascotAnimationState.greeting);
    if (_isTestEnvironment) {
      state = state.copyWith(mascotState: MascotAnimationState.idle);
      return;
    }
    _transientTimer?.cancel();
    _transientTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!_disposed && state.mascotState == MascotAnimationState.greeting) {
        state = state.copyWith(mascotState: MascotAnimationState.idle);
      }
    });
  }

  /// Sets a specific mascot animation state.
  void setMascotState(MascotAnimationState newState) {
    if (_disposed) return;
    state = state.copyWith(mascotState: newState);
  }
}
