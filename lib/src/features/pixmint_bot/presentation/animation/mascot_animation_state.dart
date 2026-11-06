import 'package:flutter/material.dart';

import '../../theme/pixmint_bot_theme.dart';

/// The 7 distinct behavioral animation states of the living PIXMINT BOT mascot.
///
/// Designed by PixelMint Studio MVS to reflect real chatbot lifecycle events:
/// - [idle]: Gentle floating, desynchronized sway, randomized blinking, soft breathing glow.
/// - [greeting]: Welcoming entrance, friendly head tilt, eye brightness flare.
/// - [thinking]: Focused posture, emerald eye pulse, restrained visor scanning sweep.
/// - [answering]: Attentive posture, subtle natural micro-gestures while answering.
/// - [success]: Cheerful positive celebration, happy curved eyes, emerald flare.
/// - [error]: Restrained warning expression, amber/ruby visor accent.
/// - [offline]: Desaturated, dimmed eyes, truthful disconnected status indicator.
enum MascotAnimationState {
  idle,
  greeting,
  thinking,
  answering,
  success,
  error,
  offline;

  /// Whether this state represents active computation.
  bool get isProcessing => this == MascotAnimationState.thinking || this == MascotAnimationState.answering;

  /// Whether this state is an alert/warning state.
  bool get isError => this == MascotAnimationState.error;

  /// Whether this state represents a disconnected system.
  bool get isOffline => this == MascotAnimationState.offline;

  /// Primary eye and aura color associated with this state.
  Color get glowColor {
    switch (this) {
      case MascotAnimationState.idle:
      case MascotAnimationState.greeting:
      case MascotAnimationState.answering:
        return PixmintBotTheme.emeraldGlow;
      case MascotAnimationState.thinking:
        return PixmintBotTheme.cyan;
      case MascotAnimationState.success:
        return const Color(0xFF34D399); // Radiant mint emerald
      case MascotAnimationState.error:
        return const Color(0xFFF59E0B); // Amber warning
      case MascotAnimationState.offline:
        return const Color(0xFF64748B); // Slate muted
    }
  }

  /// Secondary visor highlight or accent color.
  Color get accentColor {
    switch (this) {
      case MascotAnimationState.idle:
      case MascotAnimationState.greeting:
      case MascotAnimationState.answering:
        return PixmintBotTheme.emerald;
      case MascotAnimationState.thinking:
        return const Color(0xFF06B6D4);
      case MascotAnimationState.success:
        return const Color(0xFF10B981);
      case MascotAnimationState.error:
        return const Color(0xFFEF4444);
      case MascotAnimationState.offline:
        return const Color(0xFF475569);
    }
  }

  /// Visor eye base glow intensity (0.0 to 1.0).
  double get baseGlowIntensity {
    switch (this) {
      case MascotAnimationState.idle:
        return 0.75;
      case MascotAnimationState.greeting:
        return 1.0;
      case MascotAnimationState.thinking:
        return 0.90;
      case MascotAnimationState.answering:
        return 0.85;
      case MascotAnimationState.success:
        return 1.0;
      case MascotAnimationState.error:
        return 0.80;
      case MascotAnimationState.offline:
        return 0.25;
    }
  }
}
