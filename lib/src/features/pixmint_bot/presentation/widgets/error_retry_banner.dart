import 'package:flutter/material.dart';

import '../../theme/pixmint_bot_theme.dart';

/// Dismissible / actionable inline error banner with retry trigger.
class ErrorRetryBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorRetryBanner({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: PixmintBotTheme.spacingMd,
        vertical: PixmintBotTheme.spacingSm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: PixmintBotTheme.spacingMd,
        vertical: PixmintBotTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: PixmintBotTheme.errorSurface,
        borderRadius: BorderRadius.circular(PixmintBotTheme.radiusMedium),
        border: Border.all(
          color: PixmintBotTheme.error.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: PixmintBotTheme.error,
            size: 18,
          ),
          const SizedBox(width: PixmintBotTheme.spacingSm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFCA5A5),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: PixmintBotTheme.spacingSm),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: PixmintBotTheme.spacingSm,
                vertical: PixmintBotTheme.spacingXs,
              ),
              backgroundColor: PixmintBotTheme.error.withValues(alpha: 0.15),
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text(
              'Retry',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
