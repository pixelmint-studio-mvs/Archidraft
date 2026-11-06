import 'package:flutter/material.dart';
import '../../theme/pixmint_bot_theme.dart';

/// User role within the host application environment.
///
/// Corresponds to Archi Draft user roles while keeping the bot module
/// independently usable without hard coupling.
enum BotUserRole {
  engineer,
  draughtsman,
  student,
  admin,
  guest;

  String get displayName {
    switch (this) {
      case BotUserRole.engineer:
        return 'Engineer';
      case BotUserRole.draughtsman:
        return 'Draughtsman';
      case BotUserRole.student:
        return 'Student';
      case BotUserRole.admin:
        return 'Studio Admin';
      case BotUserRole.guest:
        return 'Guest';
    }
  }

  Color get badgeColor {
    switch (this) {
      case BotUserRole.engineer:
        return const Color(0xFF38BDF8); // cyan
      case BotUserRole.draughtsman:
        return PixmintBotTheme.emeraldGlow; // emerald
      case BotUserRole.student:
        return const Color(0xFFA78BFA); // purple
      case BotUserRole.admin:
        return const Color(0xFFF59E0B); // amber
      case BotUserRole.guest:
        return const Color(0xFF94A3B8); // slate
    }
  }

  static BotUserRole fromString(String? role) {
    if (role == null) return BotUserRole.guest;
    switch (role.trim().toUpperCase()) {
      case 'ENGINEER':
      case 'CLIENT':
        return BotUserRole.engineer;
      case 'DRAUGHTSMAN':
        return BotUserRole.draughtsman;
      case 'STUDENT':
        return BotUserRole.student;
      case 'ADMIN':
      case 'STUDIO_ADMIN':
        return BotUserRole.admin;
      default:
        return BotUserRole.guest;
    }
  }
}
