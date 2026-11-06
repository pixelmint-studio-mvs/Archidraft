import 'package:flutter/material.dart';

import '../../domain/models/chat_suggestion.dart';
import '../../theme/pixmint_bot_theme.dart';

/// Predefined question chips for one-tap prompting.
///
/// Features:
/// - Prominent "What can I help you with?" section header with sparkle icon.
/// - Initially presents 4 questions with a "+ More questions" expansion toggle.
/// - Refresh/Shuffle button to cycle through suggestions without losing chat state.
/// - Compact horizontal strip mode for active conversations.
/// - Disabled during bot thinking to prevent duplicate submissions.
class QuickActionChips extends StatefulWidget {
  final List<ChatSuggestion> suggestions;
  final ValueChanged<ChatSuggestion> onSelected;
  final bool isThinking;
  final bool isCompact;
  final int initialVisibleCount;
  final String? title;

  const QuickActionChips({
    super.key,
    required this.suggestions,
    required this.onSelected,
    this.isThinking = false,
    this.isCompact = false,
    this.initialVisibleCount = 4,
    this.title,
  });

  @override
  State<QuickActionChips> createState() => _QuickActionChipsState();
}

class _QuickActionChipsState extends State<QuickActionChips> {
  bool _isExpanded = false;
  int _shuffleIndex = 0;

  List<ChatSuggestion> _getRotatedList() {
    if (widget.suggestions.isEmpty) return const [];
    final offset = _shuffleIndex % widget.suggestions.length;
    if (offset == 0) return widget.suggestions;
    return [
      ...widget.suggestions.sublist(offset),
      ...widget.suggestions.sublist(0, offset),
    ];
  }

  void _shuffle() {
    if (widget.isThinking || widget.suggestions.isEmpty) return;
    setState(() {
      _shuffleIndex = (_shuffleIndex + 1) % widget.suggestions.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.suggestions.isEmpty) return const SizedBox.shrink();

    final rotated = _getRotatedList();

    if (widget.isCompact) {
      return _buildCompactBar(rotated);
    }

    final visibleCount = _isExpanded
        ? rotated.length
        : (rotated.length > widget.initialVisibleCount
            ? widget.initialVisibleCount
            : rotated.length);
    final visibleSuggestions = rotated.take(visibleCount).toList();

    return AbsorbPointer(
      absorbing: widget.isThinking,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: widget.isThinking ? 0.6 : 1.0,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: PixmintBotTheme.spacingMd,
            vertical: PixmintBotTheme.spacingSm,
          ),
          padding: const EdgeInsets.all(PixmintBotTheme.spacingMd),
          decoration: BoxDecoration(
            color: const Color(0xFF071B26).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(PixmintBotTheme.radiusMedium),
            border: Border.all(
              color: PixmintBotTheme.emerald.withValues(alpha: 0.25),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Title & Shuffle Button
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 15,
                    color: PixmintBotTheme.emerald,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title ?? 'What can I help you with?',
                      style: const TextStyle(
                        color: PixmintBotTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Refresh / Shuffle button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _shuffle,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: PixmintBotTheme.emerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: PixmintBotTheme.emerald.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              size: 13,
                              color: PixmintBotTheme.emeraldGlow,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Shuffle',
                              style: TextStyle(
                                color: PixmintBotTheme.emeraldGlow,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Suggestion Pills Grid/Wrap
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: visibleSuggestions.map((suggestion) {
                  return _PillSuggestionChip(
                    suggestion: suggestion,
                    onTap: () => widget.onSelected(suggestion),
                  );
                }).toList(),
              ),

              // "More questions" / "Show less" Control
              if (rotated.length > widget.initialVisibleCount) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.center,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isExpanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 16,
                            color: PixmintBotTheme.emeraldGlow,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isExpanded
                                ? 'Show less'
                                : 'More questions (${rotated.length - widget.initialVisibleCount})',
                            style: const TextStyle(
                              color: PixmintBotTheme.emeraldGlow,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactBar(List<ChatSuggestion> suggestions) {
    return AbsorbPointer(
      absorbing: widget.isThinking,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: widget.isThinking ? 0.6 : 1.0,
        child: Container(
          height: 38,
          margin: const EdgeInsets.symmetric(
            horizontal: PixmintBotTheme.spacingMd,
            vertical: 4,
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.auto_awesome,
                  size: 13,
                  color: PixmintBotTheme.emerald,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final suggestion = suggestions[index];
                    return _PillSuggestionChip(
                      suggestion: suggestion,
                      isCompact: true,
                      onTap: () => widget.onSelected(suggestion),
                    );
                  },
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 14,
                  color: PixmintBotTheme.textSecondary,
                ),
                tooltip: 'Shuffle',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: _shuffle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillSuggestionChip extends StatelessWidget {
  final ChatSuggestion suggestion;
  final VoidCallback onTap;
  final bool isCompact;

  const _PillSuggestionChip({
    required this.suggestion,
    required this.onTap,
    this.isCompact = false,
  });

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'rate_review':
        return Icons.rate_review_outlined;
      case 'edit_note':
        return Icons.edit_note_outlined;
      case 'fact_check':
        return Icons.fact_check_outlined;
      case 'search':
        return Icons.search_rounded;
      case 'sync_alt':
        return Icons.sync_alt_rounded;
      case 'broken_image':
        return Icons.broken_image_outlined;
      case 'build':
        return Icons.build_circle_outlined;
      case 'assignment':
        return Icons.assignment_outlined;
      case 'check_circle':
        return Icons.check_circle_outline_rounded;
      case 'upload_file':
        return Icons.upload_file_outlined;
      case 'layers':
        return Icons.layers_outlined;
      case 'publish':
        return Icons.publish_outlined;
      case 'rule':
        return Icons.rule_folder_outlined;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'timeline':
        return Icons.timeline_rounded;
      case 'school':
        return Icons.school_outlined;
      case 'menu_book':
        return Icons.menu_book_outlined;
      case 'send':
        return Icons.send_outlined;
      case 'grading':
        return Icons.grading_outlined;
      case 'comment':
        return Icons.comment_outlined;
      case 'verified':
        return Icons.verified_outlined;
      case 'report_problem':
        return Icons.report_problem_outlined;
      case 'auto_stories':
        return Icons.auto_stories_outlined;
      case 'source':
        return Icons.source_outlined;
      case 'quiz':
        return Icons.quiz_outlined;
      case 'monitor_heart':
        return Icons.monitor_heart_outlined;
      case 'mark_chat_unread':
        return Icons.mark_chat_unread_outlined;
      case 'query_stats':
        return Icons.query_stats_rounded;
      case 'toggle_on':
        return Icons.toggle_on_outlined;
      case 'history':
        return Icons.history_edu_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 12,
            vertical: isCompact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF09202E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: PixmintBotTheme.emerald.withValues(alpha: 0.6),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: PixmintBotTheme.emerald.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIcon(suggestion.iconName),
                size: isCompact ? 12 : 13,
                color: PixmintBotTheme.emerald,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  suggestion.label,
                  style: TextStyle(
                    color: PixmintBotTheme.textPrimary,
                    fontSize: isCompact ? 11.5 : 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                  maxLines: isCompact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
