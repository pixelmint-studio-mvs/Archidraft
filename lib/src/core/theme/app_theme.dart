import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Centralized application theme using Stitch design tokens.
class AppTheme {
  AppTheme._();

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: TextTheme(
      displayLarge: AppTypography.headlineDisplay,
      headlineLarge: AppTypography.headlineLg,
      headlineMedium: AppTypography.headlineLgMobile,
      bodyLarge: AppTypography.bodyMd,
      bodyMedium: AppTypography.bodySm,
      labelLarge: AppTypography.buttonText,
      labelSmall: AppTypography.labelMono,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.glassWhite,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.headlineLgMobile.copyWith(
        color: AppColors.primary,
      ),
      iconTheme: const IconThemeData(color: AppColors.primary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5), width: 1.0),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        borderSide: const BorderSide(color: AppColors.outlineVariant, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        borderSide: const BorderSide(color: AppColors.error, width: 1.0),
      ),
      labelStyle: const TextStyle(
        fontFamily: 'JetBrains Mono',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.05 * 12,
        color: AppColors.onSurface,
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.outline,
      ),
      prefixIconColor: AppColors.outline,
      suffixIconColor: AppColors.outline,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: AppColors.surfaceVariant,
        disabledForegroundColor: AppColors.onSurfaceVariant,
        textStyle: AppTypography.buttonText,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.surfaceContainerLowest,
        disabledForegroundColor: AppColors.outline,
        disabledBackgroundColor: AppColors.surfaceContainerLow,
        side: const BorderSide(color: AppColors.outlineVariant, width: 1.0),
        textStyle: AppTypography.buttonText,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        ),
      ),
    ),
  );

  // We can provide a dark theme as well, but for now we fallback to standard dark or identical if we want
  // Since Stitch didn't fully map out Dark mode beyond some background adjustments,
  // we'll keep it simple or stick to light mode for now.
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryContainer,
      secondary: AppColors.secondaryContainer,
      surface: AppColors.inverseSurface,
      onSurface: AppColors.inverseOnSurface,
    ),
    textTheme: TextTheme(
      displayLarge: AppTypography.headlineDisplay,
      headlineLarge: AppTypography.headlineLg,
      headlineMedium: AppTypography.headlineLgMobile,
      bodyLarge: AppTypography.bodyMd,
      bodyMedium: AppTypography.bodySm,
      labelLarge: AppTypography.buttonText,
      labelSmall: AppTypography.labelMono,
    ),
  );
}
