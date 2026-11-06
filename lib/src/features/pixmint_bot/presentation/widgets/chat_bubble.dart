import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../domain/models/chat_message.dart';
import '../../theme/pixmint_bot_theme.dart';
import '../launcher/pixmint_mascot_painter.dart';

/// Renders a message bubble for either the user or PIXMINT BOT.
///
/// Features:
/// - Official 3D robot body avatar with mint leaf emblem
/// - Rich Markdown formatting (headers, bold, bullets, steps, code blocks)
/// - Verified source citations accordion
/// - Timestamp and status indicators
class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;

  const ChatBubble({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _showSources = false;

  @override
  Widget build(BuildContext context) {
    if (widget.message.isSystem) {
      return _buildSystemMessage();
    }

    if (widget.message.isUser) {
      return _buildUserBubble(context);
    }

    return _buildBotBubble(context);
  }

  Widget _buildSystemMessage() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: PixmintBotTheme.spacingSm),
        padding: const EdgeInsets.symmetric(
          horizontal: PixmintBotTheme.spacingMd,
          vertical: PixmintBotTheme.spacingXs,
        ),
        decoration: BoxDecoration(
          color: PixmintBotTheme.surfaceElevated.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(PixmintBotTheme.radiusSmall),
        ),
        child: Text(
          widget.message.content,
          style: const TextStyle(
            color: PixmintBotTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildUserBubble(BuildContext context) {
    final timeStr = DateFormat('hh:mm a').format(widget.message.createdAt);

    return Padding(
      padding: const EdgeInsets.only(
        top: PixmintBotTheme.spacingSm,
        bottom: PixmintBotTheme.spacingSm,
        left: 48.0,
        right: PixmintBotTheme.spacingSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: PixmintBotTheme.spacingLg,
                vertical: PixmintBotTheme.spacingMd,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    PixmintBotTheme.userBubble,
                    PixmintBotTheme.userBubbleGradientEnd,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(PixmintBotTheme.radiusMedium),
                  topRight: Radius.circular(PixmintBotTheme.radiusMedium),
                  bottomLeft: Radius.circular(PixmintBotTheme.radiusMedium),
                  bottomRight: Radius.circular(PixmintBotTheme.radiusSmall),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SelectableText(
                    widget.message.content,
                    style: const TextStyle(
                      color: PixmintBotTheme.userBubbleText,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildStatusIcon(),
                    ],
                  ),
                  if (widget.message.hasError && widget.onRetry != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: widget.onRetry,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh, size: 14, color: Color(0xFFFCA5A5)),
                              SizedBox(width: 4),
                              Text(
                                'Retry',
                                style: TextStyle(
                                  color: Color(0xFFFCA5A5),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: widget.message.content));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Unsent message copied to clipboard'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_rounded, size: 12, color: Colors.white70),
                              SizedBox(width: 4),
                              Text(
                                'Copy Text',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (widget.message.status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: PixmintBotTheme.userBubbleText.withValues(alpha: 0.8),
          ),
        );
      case MessageStatus.sent:
        return const Icon(
          Icons.done_all,
          size: 13,
          color: Color(0xFF93C5FD),
        );
      case MessageStatus.error:
        return const Icon(
          Icons.error_outline,
          size: 13,
          color: Color(0xFFFCA5A5),
        );
    }
  }

  Widget _buildBotBubble(BuildContext context) {
    final timeStr = DateFormat('hh:mm a').format(widget.message.createdAt);
    final hasSources = widget.message.sources.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(
        top: PixmintBotTheme.spacingSm,
        bottom: PixmintBotTheme.spacingSm,
        left: PixmintBotTheme.spacingSm,
        right: 32.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Official Chibi Mascot Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: PixmintBotTheme.emerald.withValues(alpha: 0.55),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: PixmintBotTheme.emeraldGlow.withValues(alpha: 0.25),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const ClipOval(
              child: PixmintRobotAvatar(
                size: 36,
                animate: false,
                useFullMascot: false,
                showOrbitalRing: false,
              ),
            ),
          ),
          const SizedBox(width: PixmintBotTheme.spacingSm),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: PixmintBotTheme.spacingLg,
                vertical: PixmintBotTheme.spacingMd,
              ),
              decoration: BoxDecoration(
                color: PixmintBotTheme.botBubble,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(PixmintBotTheme.radiusSmall),
                  topRight: Radius.circular(PixmintBotTheme.radiusMedium),
                  bottomLeft: Radius.circular(PixmintBotTheme.radiusMedium),
                  bottomRight: Radius.circular(PixmintBotTheme.radiusMedium),
                ),
                border: Border.all(
                  color: PixmintBotTheme.botBubbleBorder,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bot label & Copy button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: PixmintBotTheme.emeraldGlow,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'PIXMINT BOT',
                            style: TextStyle(
                              color: PixmintBotTheme.emeraldGlow,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        color: PixmintBotTheme.textMuted,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Copy response',
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: widget.message.content),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: PixmintBotTheme.spacingSm),

                  // Rich formatted message text
                  _buildFormattedContent(widget.message.content),

                  // Sources / Citations accordion
                  if (hasSources) ...[
                    const SizedBox(height: PixmintBotTheme.spacingMd),
                    InkWell(
                      borderRadius: BorderRadius.circular(
                        PixmintBotTheme.radiusSmall,
                      ),
                      onTap: () {
                        setState(() {
                          _showSources = !_showSources;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: PixmintBotTheme.spacingSm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: PixmintBotTheme.surfaceElevated.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(
                            PixmintBotTheme.radiusSmall,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_outlined,
                              size: 13,
                              color: PixmintBotTheme.emeraldGlow,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.message.sources.length} Verified Sources',
                              style: const TextStyle(
                                color: PixmintBotTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _showSources
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 16,
                              color: PixmintBotTheme.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showSources) ...[
                      const SizedBox(height: PixmintBotTheme.spacingSm),
                      ...widget.message.sources.map(
                        (source) => Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.all(
                            PixmintBotTheme.spacingSm,
                          ),
                          decoration: BoxDecoration(
                            color: PixmintBotTheme.surfaceElevated.withValues(
                              alpha: 0.35,
                            ),
                            borderRadius: BorderRadius.circular(
                              PixmintBotTheme.radiusSmall,
                            ),
                            border: Border.all(
                              color: PixmintBotTheme.emerald.withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.verified_outlined,
                                size: 13,
                                color: PixmintBotTheme.emerald,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      source.title,
                                      style: const TextStyle(
                                        color: PixmintBotTheme.textPrimary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (source.docRef != null)
                                      Text(
                                        source.docRef!,
                                        style: const TextStyle(
                                          color: PixmintBotTheme.textMuted,
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: PixmintBotTheme.spacingSm),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      color: PixmintBotTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Parses text with light markdown styling:
  /// - Bold text marked with **text**
  /// - Headings marked with ###
  /// - Bullet lists marked with • or -
  Widget _buildFormattedContent(String text) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Check for markdown headers
      if (line.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              line.substring(4),
              style: const TextStyle(
                color: PixmintBotTheme.emeraldGlow,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
        continue;
      }

      // Check for bullet lines
      if (line.trimLeft().startsWith('• ') ||
          line.trimLeft().startsWith('- ') ||
          line.trimLeft().startsWith('* ')) {
        final cleanLine = line.trimLeft().substring(2);
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(
                    color: PixmintBotTheme.emeraldGlow,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: _buildRichInlineSpans(cleanLine),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Regular line
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: _buildRichInlineSpans(line),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Parses inline **bold** tags into TextSpans.
  Widget _buildRichInlineSpans(String text) {
    final spans = <TextSpan>[];
    final parts = text.split('**');

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isEmpty) continue;

      if (i % 2 == 1) {
        // Odd index was inside **bold**
        final isBrand = part.toUpperCase().contains('PIXELMINT') ||
            part.toUpperCase().contains('PIXMINT');
        spans.add(
          TextSpan(
            text: part,
            style: TextStyle(
              color: isBrand
                  ? PixmintBotTheme.emeraldGlow
                  : PixmintBotTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: part,
            style: const TextStyle(
              color: PixmintBotTheme.botBubbleText,
              fontWeight: FontWeight.w400,
            ),
          ),
        );
      }
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      style: const TextStyle(
        fontSize: 13.5,
        height: 1.45,
      ),
    );
  }
}
