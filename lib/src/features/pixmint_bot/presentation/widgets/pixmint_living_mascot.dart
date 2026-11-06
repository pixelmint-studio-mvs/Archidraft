import 'package:flutter/material.dart';

import '../../theme/pixmint_bot_theme.dart';
import '../animation/mascot_animation_state.dart';
import '../launcher/pixmint_mascot_painter.dart';

/// Premium living mascot display widget for PIXMINT BOT.
///
/// Designed for welcome banners, headers, and hero cards with:
/// - Prominent official character presentation (glossy white robot, leaf emblem)
/// - Continuous subtle floating and organic desynchronized swaying
/// - Multi-state responsiveness ([MascotAnimationState])
/// - Interactive tap-to-greet behavior
/// - Optional status speech chip
class PixmintLivingMascot extends StatelessWidget {
  final double size;
  final MascotAnimationState state;
  final bool isThinking;
  final bool showOrbitalRing;
  final bool showSatelliteDot;
  final bool useAssetImage;
  final String? statusBadgeText;
  final VoidCallback? onTap;

  const PixmintLivingMascot({
    super.key,
    this.size = 120.0,
    this.state = MascotAnimationState.idle,
    this.isThinking = false,
    this.showOrbitalRing = false,
    this.showSatelliteDot = false,
    this.useAssetImage = true,
    this.statusBadgeText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (statusBadgeText != null) ...[
          _buildStatusBadge(context),
          const SizedBox(height: PixmintBotTheme.spacingSm),
        ],
        PixmintRobotAvatar(
          size: size,
          state: state,
          isThinking: isThinking,
          animate: true,
          useFullMascot: true,
          useAssetImage: useAssetImage,
          showOrbitalRing: showOrbitalRing,
          showSatelliteDot: showSatelliteDot,
          onTap: onTap,
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final auraColor = state.glowColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: PixmintBotTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: auraColor.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: auraColor.withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: auraColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: auraColor.withValues(alpha: 0.8),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusBadgeText!,
            style: const TextStyle(
              color: PixmintBotTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
