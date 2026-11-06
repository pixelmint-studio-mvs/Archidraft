import 'package:flutter/material.dart';

import '../../theme/pixmint_bot_theme.dart';
import '../animation/mascot_animation_state.dart';
import '../launcher/pixmint_mascot_painter.dart';

/// Animated pulsing typing indicator showing that PIXMINT BOT is formulating a response.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: PixmintBotTheme.spacingSm,
        bottom: PixmintBotTheme.spacingSm,
        left: PixmintBotTheme.spacingSm,
        right: 48.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const PixmintRobotAvatar(
            size: 28,
            state: MascotAnimationState.thinking,
            isThinking: true,
            animate: true,
          ),
          const SizedBox(width: PixmintBotTheme.spacingSm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: PixmintBotTheme.spacingMd,
              vertical: PixmintBotTheme.spacingSm,
            ),
            decoration: BoxDecoration(
              color: PixmintBotTheme.botBubble,
              borderRadius: BorderRadius.circular(PixmintBotTheme.radiusMedium),
              border: Border.all(
                color: PixmintBotTheme.botBubbleBorder,
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...List.generate(3, (index) {
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final delay = index * 0.2;
                      final progress = (_controller.value - delay) % 1.0;
                      final scale = (0.5 + 0.5 * (1.0 - (progress - 0.5).abs() * 2))
                          .clamp(0.4, 1.0);

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: 7 * scale,
                        height: 7 * scale,
                        decoration: BoxDecoration(
                          color: PixmintBotTheme.emeraldGlow.withValues(alpha: scale),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: PixmintBotTheme.emerald.withValues(alpha: 0.4 * scale),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
                const SizedBox(width: 8),
                const Text(
                  'PIXMINT BOT is thinking...',
                  style: TextStyle(
                    color: PixmintBotTheme.textMuted,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
