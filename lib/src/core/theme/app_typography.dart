import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typography tokens derived from the Stitch design system.
///
/// Primary font: Inter (headings, body, buttons)
/// Secondary font: JetBrains Mono (labels, codes, technical identifiers)
///
/// Ref: REFERENCE DESIGN/stitch_draughtsman_studio_os — Tailwind fontSize config.
class AppTypography {
  AppTypography._();

  /// Display headline — 48px, Bold, -0.02em tracking
  /// Usage: Major page titles, hero text
  static TextStyle headlineDisplay = GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 56 / 48,
    letterSpacing: -0.02 * 48,
  );

  /// Large headline — 32px, SemiBold, -0.01em tracking
  /// Usage: Section headings, card titles (desktop)
  static TextStyle headlineLg = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 40 / 32,
    letterSpacing: -0.01 * 32,
  );

  /// Large headline (mobile) — 24px, SemiBold
  /// Usage: Section headings, card titles (mobile)
  static TextStyle headlineLgMobile = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
  );

  /// Body medium — 16px, Regular
  /// Usage: Body text, descriptions, paragraphs
  static TextStyle bodyMd = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  /// Body small — 14px, Regular
  /// Usage: Secondary body text, captions
  static TextStyle bodySm = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );

  /// Button text — 14px, SemiBold
  /// Usage: Buttons, interactive labels, nav items
  static TextStyle buttonText = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
  );

  /// Mono label — 12px, Medium, 0.05em tracking (JetBrains Mono)
  /// Usage: Status badges, project IDs, technical labels, timestamps
  static TextStyle labelMono = GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0.05 * 12,
  );

  /// Small mono label — 10px, Medium (JetBrains Mono)
  /// Usage: Tiny timestamps, secondary metadata
  static TextStyle labelMonoSm = GoogleFonts.jetBrainsMono(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 14 / 10,
    letterSpacing: 0.05 * 10,
  );
}
