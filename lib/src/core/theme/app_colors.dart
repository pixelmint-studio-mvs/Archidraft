import 'package:flutter/material.dart';

/// Centralized color tokens derived from the Stitch design system.
///
/// These map to the Material 3 color scheme used across all Stitch screens.
/// Ref: REFERENCE DESIGN/stitch_draughtsman_studio_os — unified color palette.
class AppColors {
  AppColors._();

  // ── Primary ──
  static const Color primary = Color(0xFF000000);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF0D1C32);
  static const Color onPrimaryContainer = Color(0xFF76849F);

  // ── Secondary ──
  static const Color secondary = Color(0xFF0453CD);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF356EE7);
  static const Color onSecondaryContainer = Color(0xFFFEFCFF);
  static const Color secondaryFixed = Color(0xFFDAE2FF);
  static const Color onSecondaryFixed = Color(0xFF001848);
  static const Color onSecondaryFixedVariant = Color(0xFF0040A2);

  // ── Tertiary ──
  static const Color tertiary = Color(0xFF000000);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF002114);
  static const Color onTertiaryContainer = Color(0xFF069669);
  static const Color tertiaryFixed = Color(0xFF85F8C4);
  static const Color tertiaryFixedDim = Color(0xFF68DBA9);

  // ── Error ──
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ── Surface ──
  static const Color surface = Color(0xFFFBF9FB);
  static const Color onSurface = Color(0xFF1B1B1D);
  static const Color onSurfaceVariant = Color(0xFF44474D);
  static const Color surfaceVariant = Color(0xFFE4E2E4);
  static const Color surfaceDim = Color(0xFFDBD9DB);
  static const Color surfaceBright = Color(0xFFFBF9FB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF5F3F5);
  static const Color surfaceContainer = Color(0xFFEFEDEF);
  static const Color surfaceContainerHigh = Color(0xFFEAE7EA);
  static const Color surfaceContainerHighest = Color(0xFFE4E2E4);

  // ── Outline ──
  static const Color outline = Color(0xFF75777E);
  static const Color outlineVariant = Color(0xFFC5C6CD);

  // ── Background ──
  static const Color background = Color(0xFFFBF9FB);
  static const Color onBackground = Color(0xFF1B1B1D);

  // ── Inverse ──
  static const Color inverseSurface = Color(0xFF303032);
  static const Color inverseOnSurface = Color(0xFFF2F0F2);
  static const Color inversePrimary = Color(0xFFB9C7E4);

  // ── Status Semantics ──
  /// Success / Approved states
  static const Color success = Color(0xFF069669);
  static const Color successContainer = Color(0xFF85F8C4);

  /// Warning / Pending states
  static const Color warning = Color(0xFFE6A817);
  static const Color warningContainer = Color(0xFFFFF0C7);

  /// Glass effect base colors
  static const Color glassWhite = Color(0x99FFFFFF); // 60% opacity
  static const Color glassBlack = Color(0x99000000); // 60% opacity
  static const Color glassBorder = Color(0x80FFFFFF); // 50% opacity
}
