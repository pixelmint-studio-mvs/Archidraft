import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/bot_user_role.dart';
import '../../domain/models/pixmint_default_suggestions.dart';
import '../../providers/pixmint_bot_providers.dart';
import '../../providers/pixmint_chat_controller.dart';
import '../../theme/pixmint_bot_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/error_retry_banner.dart';
import '../widgets/pixmint_living_mascot.dart';
import '../widgets/quick_action_chips.dart';
import '../widgets/typing_indicator.dart';
import 'pixmint_chat_header.dart';
import 'pixmint_chat_input.dart';

/// The primary chat sheet interface for PIXMINT BOT.
///
/// Can be presented as a modal bottom sheet, embedded in a navigation rail,
/// or displayed as a persistent side drawer on desktop.
class PixmintChatSheet extends ConsumerStatefulWidget {
  final VoidCallback? onClose;
  final BotUserRole? overrideRole;

  const PixmintChatSheet({
    super.key,
    this.onClose,
    this.overrideRole,
  });

  /// Helper to open the chatbot in a responsive bottom sheet.
  static Future<void> show(
    BuildContext context, {
    BotUserRole? role,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PixmintChatSheet(
        overrideRole: role,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  ConsumerState<PixmintChatSheet> createState() => _PixmintChatSheetState();
}

class _PixmintChatSheetState extends ConsumerState<PixmintChatSheet> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.overrideRole != null) {
        ref.read(pixmintOverrideRoleProvider.notifier).setRole(widget.overrideRole);
        ref.read(pixmintChatControllerProvider.notifier).switchRole(widget.overrideRole!);
      }
      ref.read(pixmintChatControllerProvider.notifier).triggerGreeting();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(pixmintChatControllerProvider);
    final suggestionsAsync = ref.watch(pixmintSuggestionsProvider);
    final role = ref.watch(pixmintRoleProvider);
    final suggestions =
        suggestionsAsync.value ?? PixmintDefaultSuggestions.getForRole(role);

    ref.listen<PixmintChatState>(pixmintChatControllerProvider, (previous, next) {
      if (next.messages.length != (previous?.messages.length ?? 0) ||
          next.isThinking != (previous?.isThinking ?? false)) {
        _scrollToBottom();
      }
    });

    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width >= 900;
    final maxHeight = mediaQuery.size.height * 0.88;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 480 : double.infinity,
          maxHeight: maxHeight,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: PixmintBotTheme.background,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(PixmintBotTheme.radiusLarge),
              topRight: const Radius.circular(PixmintBotTheme.radiusLarge),
              bottomLeft: isDesktop
                  ? const Radius.circular(PixmintBotTheme.radiusLarge)
                  : Radius.zero,
              bottomRight: isDesktop
                  ? const Radius.circular(PixmintBotTheme.radiusLarge)
                  : Radius.zero,
            ),
            border: Border.all(
              color: PixmintBotTheme.emerald.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: PixmintBotTheme.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(PixmintBotTheme.radiusLarge),
              topRight: const Radius.circular(PixmintBotTheme.radiusLarge),
              bottomLeft: isDesktop
                  ? const Radius.circular(PixmintBotTheme.radiusLarge)
                  : Radius.zero,
              bottomRight: isDesktop
                  ? const Radius.circular(PixmintBotTheme.radiusLarge)
                  : Radius.zero,
            ),
            child: Column(
              children: [
                // Header
                PixmintChatHeader(
                  role: role,
                  isThinking: chatState.isThinking,
                  isOnline: chatState.errorMessage == null,
                  isConnecting: chatState.isInitializing,
                  mascotState: chatState.mascotState,
                  onClear: () {
                    ref.read(pixmintChatControllerProvider.notifier).clearConversation();
                  },
                  onClose: () {
                    if (widget.onClose != null) {
                      widget.onClose!();
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                ),

                // Main Chat Body
                Expanded(
                  child: chatState.isInitializing
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PixmintLivingMascot(
                                size: 84,
                                state: chatState.mascotState,
                                isThinking: chatState.isThinking,
                                showOrbitalRing: true,
                                showSatelliteDot: true,
                              ),
                              const SizedBox(height: PixmintBotTheme.spacingMd),
                              const Text(
                                'Connecting to PIXMINT BOT...',
                                style: TextStyle(
                                  color: PixmintBotTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // Messages List & Initial Preloaded Questions
                            Expanded(
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                  vertical: PixmintBotTheme.spacingMd,
                                ),
                                itemCount: chatState.messages.length +
                                    (chatState.messages.length <= 2 &&
                                            suggestions.isNotEmpty
                                        ? 1
                                        : 0),
                                itemBuilder: (context, index) {
                                  if (index < chatState.messages.length) {
                                    final message = chatState.messages[index];
                                    return ChatBubble(
                                      message: message,
                                      onRetry: () {
                                        ref
                                            .read(pixmintChatControllerProvider
                                                .notifier)
                                            .retryLastMessage();
                                      },
                                    );
                                  }
                                  // Suggestions card rendered inside scrollable view
                                  return QuickActionChips(
                                    suggestions: suggestions,
                                    isThinking: chatState.isThinking,
                                    onSelected: (suggestion) {
                                      ref
                                          .read(pixmintChatControllerProvider
                                              .notifier)
                                          .sendMessage(suggestion.prompt);
                                    },
                                  );
                                },
                              ),
                            ),

                            // Thinking indicator
                            if (chatState.isThinking) const TypingIndicator(),

                            // Error banner
                            if (chatState.errorMessage != null)
                              ErrorRetryBanner(
                                message: chatState.errorMessage!,
                                onRetry: () {
                                  ref
                                      .read(pixmintChatControllerProvider.notifier)
                                      .retryLastMessage();
                                },
                              ),

                            // Compact Suggestions (Keeps portal questions accessible after conversation starts)
                            if (chatState.messages.length > 2 && suggestions.isNotEmpty)
                              QuickActionChips(
                                suggestions: suggestions,
                                isThinking: chatState.isThinking,
                                isCompact: true,
                                onSelected: (suggestion) {
                                  ref
                                      .read(pixmintChatControllerProvider.notifier)
                                      .sendMessage(suggestion.prompt);
                                },
                              ),
                          ],
                        ),
                ),

                // Input Bar
                PixmintChatInput(
                  isThinking: chatState.isThinking,
                  onSend: (text) {
                    ref
                        .read(pixmintChatControllerProvider.notifier)
                        .sendMessage(text);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
