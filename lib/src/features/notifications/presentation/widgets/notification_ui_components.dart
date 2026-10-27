import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/app_notification.dart';

/// Supported filter tabs for notifications screens.
enum NotificationFilter { all, unread, reviews, remarks }

/// Blueprint grid canvas background painter (40px unit from Architectural Precision System).
class BlueprintGridBackgroundPainter extends CustomPainter {
  const BlueprintGridBackgroundPainter();

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

/// Header card matching reference design with bell icon, subtitle, unread badge, and actions.
class NotificationHeaderCard extends StatelessWidget {
  final String subtitle;
  final int totalCount;
  final int unreadCount;
  final VoidCallback? onMarkAllRead;
  final VoidCallback onRefresh;
  final VoidCallback? onClearAll;

  const NotificationHeaderCard({
    super.key,
    required this.subtitle,
    required this.totalCount,
    required this.unreadCount,
    required this.onMarkAllRead,
    required this.onRefresh,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
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
                subtitle,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    key: const Key('notifications_mark_all_read_button'),
                    onPressed: onMarkAllRead,
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Mark All as Read'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: onMarkAllRead != null
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
                    onPressed: onRefresh,
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
                  OutlinedButton.icon(
                    key: const Key('notifications_clear_all_button'),
                    onPressed: onClearAll,
                    icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                    label: const Text('Clear All'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: onClearAll != null ? AppColors.error : AppColors.outlineVariant,
                      side: BorderSide(
                        color: onClearAll != null
                            ? AppColors.error.withValues(alpha: 0.6)
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
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnreadBadge(int unreadCount) {
    final hasUnread = unreadCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: hasUnread
            ? const Color(0xFFFFDAD6).withValues(alpha: 0.7)
            : const Color(0xFF85F8C4).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: hasUnread
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
              color: hasUnread
                  ? const Color(0xFFBA1A1A)
                  : const Color(0xFF069669),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            hasUnread ? '$unreadCount UNREAD' : 'ALL CAUGHT UP',
            style: AppTypography.labelMonoSm.copyWith(
              color: hasUnread
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
}

/// Filter chips row for All, Unread, Reviews, Remarks.
class NotificationFilterBar extends StatelessWidget {
  final NotificationFilter activeFilter;
  final int totalCount;
  final int unreadCount;
  final int reviewsCount;
  final int remarksCount;
  final ValueChanged<NotificationFilter> onFilterChanged;

  const NotificationFilterBar({
    super.key,
    required this.activeFilter,
    required this.totalCount,
    required this.unreadCount,
    required this.reviewsCount,
    required this.remarksCount,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All ($totalCount)',
            filter: NotificationFilter.all,
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip(
            label: 'Unread ($unreadCount)',
            filter: NotificationFilter.unread,
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip(
            label: 'Reviews ($reviewsCount)',
            filter: NotificationFilter.reviews,
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip(
            label: 'Remarks ($remarksCount)',
            filter: NotificationFilter.remarks,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required NotificationFilter filter,
  }) {
    final isSelected = activeFilter == filter;
    return InkWell(
      onTap: () => onFilterChanged(filter),
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
}

/// Visual card for an individual notification item.
class NotificationItemCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback? onMarkAsRead;

  const NotificationItemCard({
    super.key,
    required this.notification,
    required this.onTap,
    this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final iconData = iconForNotificationType(notification.type);
    final accentColor = colorForNotificationType(notification.type);
    final typeLabel = labelForNotificationType(notification.type);
    final formattedTime = formatRelativeTime(notification.createdAt);

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
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      notification.title,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.primary,
                        fontWeight:
                            isUnread ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isUnread && onMarkAsRead != null)
                    IconButton(
                      icon: const Icon(
                        Icons.mark_email_read_outlined,
                        size: 20,
                        color: AppColors.secondary,
                      ),
                      onPressed: onMarkAsRead,
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
}

/// Empty state card matching reference design.
class NotificationEmptyStateCard extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const NotificationEmptyStateCard({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
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
              decoration: const BoxDecoration(
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
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.outline,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: onAction,
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
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// System footer signature.
class NotificationSystemFooter extends StatelessWidget {
  const NotificationSystemFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}

// ---------------------------------------------------------------------------
// HELPER FUNCTIONS
// ---------------------------------------------------------------------------

IconData iconForNotificationType(String type) {
  switch (type) {
    case 'CHAT_MESSAGE':
      return Icons.chat_bubble_outline_rounded;
    case 'CORRECTION_REQUESTED':
      return Icons.edit_note_rounded;
    case 'PROJECT_APPROVED':
      return Icons.check_circle_outline_rounded;
    case 'DRAWING_SUBMITTED':
    case 'REVISION_SUBMITTED':
      return Icons.description_outlined;
    case 'PROJECT_ASSIGNED':
    case 'ASSIGNMENT_ACCEPTED':
      return Icons.assignment_ind_outlined;
    default:
      return Icons.notifications_outlined;
  }
}

Color colorForNotificationType(String type) {
  switch (type) {
    case 'CHAT_MESSAGE':
      return AppColors.secondary;
    case 'CORRECTION_REQUESTED':
      return const Color(0xFFBA1A1A);
    case 'PROJECT_APPROVED':
      return const Color(0xFF069669);
    case 'DRAWING_SUBMITTED':
    case 'REVISION_SUBMITTED':
      return const Color(0xFF0D1C32);
    case 'PROJECT_ASSIGNED':
    case 'ASSIGNMENT_ACCEPTED':
      return const Color(0xFF0061A4);
    default:
      return AppColors.outline;
  }
}

String labelForNotificationType(String type) {
  switch (type) {
    case 'CHAT_MESSAGE':
      return 'REMARK';
    case 'CORRECTION_REQUESTED':
      return 'CORRECTION';
    case 'PROJECT_APPROVED':
      return 'APPROVED';
    case 'DRAWING_SUBMITTED':
      return 'SUBMISSION';
    case 'REVISION_SUBMITTED':
      return 'REVISION';
    case 'PROJECT_ASSIGNED':
      return 'ASSIGNED';
    case 'ASSIGNMENT_ACCEPTED':
      return 'ACCEPTED';
    default:
      return type.replaceAll('_', ' ');
  }
}

String formatRelativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d, HH:mm').format(date);
}
