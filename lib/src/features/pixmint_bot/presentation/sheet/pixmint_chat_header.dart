import 'package:flutter/material.dart';

import '../../domain/models/bot_user_role.dart';
import '../../theme/pixmint_bot_theme.dart';
import '../animation/mascot_animation_state.dart';
import '../launcher/pixmint_mascot_painter.dart';

/// Top header bar for the PIXMINT BOT chat interface.
///
/// Faithfully reproduces the official chat mockup:
/// - Robot avatar with glowing emerald halo
/// - "PIXMINT BOT" bold title
/// - "Online" active status indicator with glowing green dot
/// - Minimize (—) and Close (✕) actions
class PixmintChatHeader extends StatelessWidget {
  final BotUserRole role;
  final VoidCallback onClear;
  final VoidCallback onClose;
  final VoidCallback? onMinimize;
  final bool isThinking;
  final bool isOnline;
  final bool isConnecting;
  final MascotAnimationState? mascotState;

  const PixmintChatHeader({
    super.key,
    required this.role,
    required this.onClear,
    required this.onClose,
    this.onMinimize,
    this.isThinking = false,
    this.isOnline = true,
    this.isConnecting = false,
    this.mascotState,
  });

  MascotAnimationState get _effectiveMascotState {
    if (mascotState != null) return mascotState!;
    if (isConnecting) return MascotAnimationState.greeting;
    if (!isOnline) return MascotAnimationState.offline;
    if (isThinking) return MascotAnimationState.thinking;
    return MascotAnimationState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveState = _effectiveMascotState;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PixmintBotTheme.spacingLg,
        vertical: PixmintBotTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: PixmintBotTheme.surfaceCard,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Circular bot avatar with glowing halo
          PixmintRobotAvatar(
            size: 38,
            state: effectiveState,
            isThinking: isThinking,
            showOrbitalRing: true,
            showSatelliteDot: true,
            animate: true,
          ),
          const SizedBox(width: PixmintBotTheme.spacingMd),

          // Title & Online status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'PIXMINT BOT',
                        style: TextStyle(
                          color: PixmintBotTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildRoleTag(role),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isConnecting
                            ? PixmintBotTheme.warning
                            : (!isOnline ? PixmintBotTheme.error : PixmintBotTheme.emeraldGlow),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isConnecting
                                    ? PixmintBotTheme.warning
                                    : (!isOnline ? PixmintBotTheme.error : PixmintBotTheme.emeraldGlow))
                                .withValues(alpha: 0.8),
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isConnecting ? 'Connecting...' : (!isOnline ? 'Offline' : 'Online'),
                      style: TextStyle(
                        color: isConnecting
                            ? PixmintBotTheme.warning
                            : (!isOnline ? PixmintBotTheme.error : PixmintBotTheme.emeraldGlow),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Reset / Clear action
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            color: PixmintBotTheme.textMuted,
            tooltip: 'Reset Conversation',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: PixmintBotTheme.surfaceCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PixmintBotTheme.radiusMedium),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  title: const Text(
                    'Reset Conversation?',
                    style: TextStyle(
                      color: PixmintBotTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  content: const Text(
                    'This will clear your active conversation history with PIXMINT BOT. This action cannot be undone.',
                    style: TextStyle(
                      color: PixmintBotTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: PixmintBotTheme.textSecondary),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PixmintBotTheme.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(PixmintBotTheme.radiusSmall),
                        ),
                      ),
                      child: const Text('Reset Conversation'),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onClear();
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          // Minimize button (—) as in mockup
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 20),
            color: PixmintBotTheme.textSecondary,
            tooltip: 'Minimize',
            onPressed: onMinimize ?? onClose,
          ),

          // Close button (✕) as in mockup
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            color: PixmintBotTheme.textSecondary,
            tooltip: 'Close',
            onPressed: onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTag(BotUserRole role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: role.badgeColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: role.badgeColor.withValues(alpha: 0.45),
          width: 0.8,
        ),
      ),
      child: Text(
        role.displayName.toUpperCase(),
        style: TextStyle(
          color: role.badgeColor,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
