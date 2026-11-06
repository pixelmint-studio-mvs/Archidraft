import 'package:flutter/material.dart';

/// Theme tokens and design constants for PIXMINT BOT.
///
/// Designed with exact fidelity to the official character sheet:
/// glossy ceramic white robot chassis, dark visor with glowing cyan-emerald eyes,
/// emerald accent rings, and deep slate-navy surfaces.
class PixmintBotTheme {
  PixmintBotTheme._();

  // ── Palette (from official character sheet & chat mockup) ───────────────
  static const Color background = Color(0xFF07141E);
  static const Color surface = Color(0xFF0B1B27);
  static const Color surfaceCard = Color(0xFF10222E);
  static const Color surfaceElevated = Color(0xFF162D3D);
  static const Color surfaceGlass = Color(0xDD07141E);

  // Signature Emerald Glow (matching mascot eyes and orbital ring)
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldGlow = Color(0xFF00F2A9);
  static const Color emeraldDark = Color(0xFF047857);
  static const Color emeraldMuted = Color(0x2A10B981);

  // Accent Cyan & Mint
  static const Color cyan = Color(0xFF06B6D4);
  static const Color cyanGlow = Color(0xFF38BDF8);

  // Typography Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF475569);

  // ── Chat Composer Input Tokens ──────────────────────────────────────────
  static const Color composerBackground = Color(0xFF081824);
  static const Color composerText = Color(0xFFF8FAFC);
  static const Color composerHint = Color(0xFF64748B);
  static const Color composerCursor = Color(0xFF00D6A0);
  static const Color composerSelection = Color(0x3300D6A0);
  static const Color composerBorder = Color(0x1FFFFFFF);
  static const Color composerBorderFocused = Color(0xFF00D6A0);

  // Functional Colors
  static const Color error = Color(0xFFEF4444);
  static const Color errorSurface = Color(0x22EF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);

  // Bubble Colors
  static const Color userBubble = Color(0xFF0284C7);
  static const Color userBubbleGradientEnd = Color(0xFF0369A1);
  static const Color userBubbleText = Color(0xFFFFFFFF);
  static const Color botBubble = Color(0xFF10222E);
  static const Color botBubbleBorder = Color(0x3310B981);
  static const Color botBubbleText = Color(0xFFF1F5F9);

  // ── Dimensions & Radii ──────────────────────────────────────────────────
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusFull = 999.0;

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 12.0;
  static const double spacingLg = 16.0;
  static const double spacingXl = 24.0;
  static const double spacingXxl = 32.0;

  // ── Shadows & Elevations ────────────────────────────────────────────────
  static List<BoxShadow> get emeraldGlowShadow => [
        BoxShadow(
          color: emerald.withValues(alpha: 0.45),
          blurRadius: 18,
          spreadRadius: 2,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: emeraldGlow.withValues(alpha: 0.25),
          blurRadius: 32,
          spreadRadius: 4,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.55),
          blurRadius: 28,
          spreadRadius: -4,
          offset: const Offset(0, 12),
        ),
      ];

  // ── BoxDecoration Helpers ────────────────────────────────────────────────
  static BoxDecoration get glassCardDecoration => BoxDecoration(
        color: surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(
          color: emerald.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: cardShadow,
      );

  static BoxDecoration get botLauncherDecoration => BoxDecoration(
        color: const Color(0xFF07141E),
        shape: BoxShape.circle,
        border: Border.all(
          color: emeraldGlow,
          width: 2.2,
        ),
        boxShadow: emeraldGlowShadow,
      );
}
