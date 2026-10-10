import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../../projects/domain/assignment.dart';
import '../../projects/providers/assignment_providers.dart';
import '../domain/app_notification.dart';
import '../providers/notification_providers.dart';

// ---------------------------------------------------------------------------
// FILTER ENUM
// ---------------------------------------------------------------------------

enum _NotificationFilter { all, unread, reviews, messages }

// ---------------------------------------------------------------------------
// BLUEPRINT GRID BACKGROUND PAINTER (40px unit from DESIGN.md)
// ---------------------------------------------------------------------------

class _BlueprintGridBackgroundPainter extends CustomPainter {
  const _BlueprintGridBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const double gridSize = 40.0;
    final gridPaint = Paint()
      ..color = const Color(0xFF75777E).withValues(alpha: 0.05)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// NOTIFICATIONS SCREEN
// ---------------------------------------------------------------------------

/// Panel 9 — Notifications Screen for the Draughtsman Portal.
///
/// Adheres to the Architectural Precision System in `REFERENCE DESIGN`:
/// - Warm white `#FBF9FB` drafting canvas with 40px grid lines.
/// - Pure white surface cards with dual architectural soft shadows.
/// - JetBrains Mono for technical codes, tags, and timestamps.
/// - Distinct read vs unread indicators with real server persistence.
/// - Direct navigation to corresponding assignments, drawings, and chat.
class DraughtsmanNotificationsScreen extends ConsumerStatefulWidget {
  const DraughtsmanNotificationsScreen({super.key});

  @override
  ConsumerState<DraughtsmanNotificationsScreen> createState() =>
      _DraughtsmanNotificationsScreenState();
}

class _DraughtsmanNotificationsScreenState
    extends ConsumerState<DraughtsmanNotificationsScreen> {
  _NotificationFilter _activeFilter = _NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final assignmentsAsync = ref.watch(draughtsmanAssignmentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9FB),
      body: CustomPaint(
        painter: const _BlueprintGridBackgroundPainter(),
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(notificationsProvider);
            ref.invalidate(draughtsmanAssignmentsProvider);
          },
          child: notificationsAsync.when(
            loading: () => const AppLoadingIndicator(
              message: 'Loading notifications stream...',
            ),
            error: (err, _) => AppErrorWidget(
              message: 'Failed to load notifications.',
              onRetry: () => ref.invalidate(notificationsProvider),
            ),
            data: (notifications) {
              final assignments = assignmentsAsync.maybeWhen(
                data: (list) => list,
                orElse: () => <Assignment>[],
              );

              return _buildContent(context, notifications, assignments);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<AppNotification> allNotifications,
    List<Assignment> assignments,
  ) {
    // ── Filter notifications ──────────────────────────────────────────
    final filtered = allNotifications.where((n) {
      switch (_activeFilter) {
        case _NotificationFilter.all:
          return true;
        case _NotificationFilter.unread:
          return !n.isRead;
        case _NotificationFilter.reviews:
          return n.type == 'CORRECTION_REQUESTED' ||
              n.type == 'PROJECT_APPROVED' ||
              n.type == 'DRAWING_SUBMITTED';
        case _NotificationFilter.messages:
          return n.type == 'CHAT_MESSAGE';
      }
    }).toList();

    final unreadCount = allNotifications.where((n) => !n.isRead).length;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Top Header Card ──
              _buildHeaderCard(context, allNotifications.length, unreadCount),

              const SizedBox(height: AppSpacing.lg),

              // ── 2. Filter Bar ──
              _buildFilterBar(allNotifications, unreadCount),

              const SizedBox(height: AppSpacing.lg),

              // ── 3. Notification List or Empty State ──
              if (filtered.isEmpty)
                _buildEmptyState(context)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final n = filtered[index];
                    return _buildNotificationCard(context, n, assignments);
                  },
                ),

              const SizedBox(height: AppSpacing.xxl),

              // ── 4. System Footer Signature ──
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Text(
                    'UI/UX Design & Product Experience crafted by PixelMint Studio MVS',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.outline,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. HEADER CARD
  // ---------------------------------------------------------------------------

  Widget _buildHeaderCard(
    BuildContext context,
    int totalCount,
    int unreadCount,
  ) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: Color(0x05000000),
            offset: Offset(0, 12),
            blurRadius: 24,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle ambient glow on top right
          Positioned(
            top: -25,
            right: -25,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.04),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusDefault),
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Notifications',
                        style: AppTypography.headlineLgMobile.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildUnreadBadge(unreadCount),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusDefault),
                          ),
                          child: const Icon(
                            Icons.notifications_active_outlined,
                            size: 22,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Notifications',
                          style: AppTypography.headlineDisplay.copyWith(
                            color: AppColors.primary,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    _buildUnreadBadge(unreadCount),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Direct notifications on assignments, engineering remarks, and review cycles.',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Action Buttons Row
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    key: const Key('notifications_mark_all_read_button'),
                    onPressed: unreadCount > 0
                        ? () async {
                            try {
                              await ref.read(
                                  markAllNotificationsReadProvider.future);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('All notifications marked as read.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to update: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Mark All as Read'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: unreadCount > 0
                            ? AppColors.primary
                            : AppColors.outlineVariant,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusDefault),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const Key('notifications_refresh_button'),
                    onPressed: () {
                      ref.invalidate(notificationsProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notifications refreshed.'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Refresh'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onSurfaceVariant,
                      side: const BorderSide(color: AppColors.outlineVariant),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusDefault),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnreadBadge(int unreadCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: unreadCount > 0
            ? const Color(0xFFFFDAD6).withValues(alpha: 0.7)
            : const Color(0xFF85F8C4).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: unreadCount > 0
              ? const Color(0xFFBA1A1A).withValues(alpha: 0.3)
              : const Color(0xFF069669).withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unreadCount > 0
                  ? const Color(0xFFBA1A1A)
                  : const Color(0xFF069669),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            unreadCount > 0 ? '$unreadCount UNREAD' : 'ALL CAUGHT UP',
            style: AppTypography.labelMonoSm.copyWith(
              color: unreadCount > 0
                  ? const Color(0xFF93000A)
                  : const Color(0xFF005137),
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. FILTER BAR
  // ---------------------------------------------------------------------------

  Widget _buildFilterBar(
    List<AppNotification> allNotifications,
    int unreadCount,
  ) {
    final reviewsCount = allNotifications
        .where((n) =>
            n.type == 'CORRECTION_REQUESTED' ||
            n.type == 'PROJECT_APPROVED' ||
            n.type == 'DRAWING_SUBMITTED')
        .length;
    final messagesCount =
        allNotifications.where((n) => n.type == 'CHAT_MESSAGE').length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All (${allNotifications.length})',
            filter: _NotificationFilter.all,
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip(
            label: 'Unread ($unreadCount)',
            filter: _NotificationFilter.unread,
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip(
            label: 'Reviews ($reviewsCount)',
            filter: _NotificationFilter.reviews,
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip(
            label: 'Remarks ($messagesCount)',
            filter: _NotificationFilter.messages,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required _NotificationFilter filter,
  }) {
    final isSelected = _activeFilter == filter;
    return InkWell(
      onTap: () => setState(() => _activeFilter = filter),
      borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.5),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.labelMonoSm.copyWith(
            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. NOTIFICATION CARD
  // ---------------------------------------------------------------------------

  Widget _buildNotificationCard(
    BuildContext context,
    AppNotification n,
    List<Assignment> assignments,
  ) {
    final isUnread = !n.isRead;
    final iconData = _iconForType(n.type);
    final accentColor = _colorForType(n.type);
    final typeLabel = _typeDisplayLabel(n.type);
    final formattedTime = _formatRelativeTime(n.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: isUnread
            ? AppColors.secondaryFixed.withValues(alpha: 0.12)
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isUnread
              ? AppColors.secondary.withValues(alpha: 0.35)
              : AppColors.outlineVariant.withValues(alpha: 0.4),
          width: isUnread ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.02),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () async {
          if (isUnread) {
            try {
              await ref.read(markNotificationReadProvider(n.id).future);
            } catch (_) {}
          }
          if (context.mounted) {
            _navigateToNotificationTarget(context, n, assignments);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unread Blue Bullet Indicator
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnread ? AppColors.secondary : Colors.transparent,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Category Icon Container
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.25),
                    width: 0.5,
                  ),
                ),
                child: Icon(iconData, size: 18, color: accentColor),
              ),
              const SizedBox(width: AppSpacing.md),

              // Details & Message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Type Tag + Relative Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            typeLabel,
                            style: AppTypography.labelMonoSm.copyWith(
                              color: accentColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Text(
                          formattedTime,
                          style: AppTypography.labelMonoSm.copyWith(
                            color: AppColors.outline,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Notification Title
                    Text(
                      n.title,
                      style: AppTypography.buttonText.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Notification Message Body
                    Text(
                      n.message,
                      style: AppTypography.bodyMd.copyWith(
                        color: isUnread
                            ? AppColors.onSurface
                            : AppColors.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Trailing Action Controls
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isUnread)
                    IconButton(
                      tooltip: 'Mark as read',
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 20,
                        color: AppColors.secondary,
                      ),
                      onPressed: () async {
                        try {
                          await ref
                              .read(markNotificationReadProvider(n.id).future);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Marked as read.'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e')),
                            );
                          }
                        }
                      },
                    ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.outline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. EMPTY STATE
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            offset: Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainerHigh,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 28,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No Notifications Found',
              style: AppTypography.headlineLgMobile.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                'You have no notifications under this filter. Updates on assigned drawings, revisions, and remarks will appear here.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.outline,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: () => context.go('/draughtsman/studio'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusDefault),
                ),
              ),
              child: const Text('Back to Studio'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NAVIGATION ROUTING HELPER
  // ---------------------------------------------------------------------------

  void _navigateToNotificationTarget(
    BuildContext context,
    AppNotification n,
    List<Assignment> assignments,
  ) {
    // Attempt matching assignment from notification text
    Assignment? matched;
    for (final a in assignments) {
      if (a.projectName != null &&
          (n.title.contains(a.projectName!) ||
              n.message.contains(a.projectName!))) {
        matched = a;
        break;
      }
      if (n.title.contains(a.projectId) || n.message.contains(a.projectId)) {
        matched = a;
        break;
      }
    }

    // Route based on genuine notification type
    switch (n.type) {
      case 'CHAT_MESSAGE':
        if (matched != null) {
          context.push('/draughtsman/collaboration/${matched.id}');
        } else if (assignments.isNotEmpty) {
          context.push('/draughtsman/collaboration/${assignments.first.id}');
        } else {
          context.go('/draughtsman/studio');
        }
        break;

      case 'CORRECTION_REQUESTED':
        if (matched != null) {
          context.push('/draughtsman/workspace/${matched.id}');
        } else if (assignments.isNotEmpty) {
          context.push('/draughtsman/workspace/${assignments.first.id}');
        } else {
          context.go('/draughtsman/studio');
        }
        break;

      case 'PROJECT_APPROVED':
      case 'DRAWING_SUBMITTED':
        if (matched != null) {
          context.push('/draughtsman/drawings/${matched.id}');
        } else {
          context.go('/draughtsman/drawings');
        }
        break;

      default:
        if (matched != null) {
          context.push('/draughtsman/assignments/${matched.id}');
        } else {
          context.go('/draughtsman/studio');
        }
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  IconData _iconForType(String type) {
    switch (type) {
      case 'CHAT_MESSAGE':
        return Icons.chat_bubble_outline_rounded;
      case 'CORRECTION_REQUESTED':
        return Icons.edit_note_rounded;
      case 'PROJECT_APPROVED':
        return Icons.check_circle_outline_rounded;
      case 'DRAWING_SUBMITTED':
        return Icons.description_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'CHAT_MESSAGE':
        return AppColors.secondary;
      case 'CORRECTION_REQUESTED':
        return const Color(0xFFBA1A1A); // Error red
      case 'PROJECT_APPROVED':
        return const Color(0xFF069669); // Emerald
      case 'DRAWING_SUBMITTED':
        return const Color(0xFF0D1C32); // Primary container
      default:
        return AppColors.outline;
    }
  }

  String _typeDisplayLabel(String type) {
    switch (type) {
      case 'CHAT_MESSAGE':
        return 'REMARK';
      case 'CORRECTION_REQUESTED':
        return 'CORRECTION';
      case 'PROJECT_APPROVED':
        return 'APPROVED';
      case 'DRAWING_SUBMITTED':
        return 'SUBMISSION';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  String _formatRelativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, HH:mm').format(date);
  }
}
