import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/notification_providers.dart';

/// Notifications dialog styled according to the Architectural Precision System in REFERENCE DESIGN.
class NotificationsDialog extends ConsumerWidget {
  const NotificationsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Dialog(
      alignment: Alignment.topRight,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.only(top: 68, right: 28, bottom: 24, left: 16),
      child: Container(
        width: 420,
        height: 540,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.6),
            width: 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D0D1C32),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
            BoxShadow(
              color: Color(0x080D1C32),
              offset: Offset(0, 8),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Notifications',
                        style: AppTypography.buttonText.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.outlineVariant),
            Expanded(
              child: notificationsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'Failed to load notifications.',
                      style: AppTypography.bodySm.copyWith(color: AppColors.error),
                    ),
                  ),
                ),
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 40,
                            color: AppColors.outline.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'No notifications yet',
                            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                          Text(
                            'You will receive updates on reviews and assignments here.',
                            style: AppTypography.labelMonoSm.copyWith(color: AppColors.outline),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                        onTap: () {
                          if (!n.isRead) {
                            ref.read(markNotificationReadProvider(n.id));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: n.isRead ? Colors.transparent : AppColors.secondaryFixed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                            border: Border.all(
                              color: n.isRead ? AppColors.outlineVariant.withValues(alpha: 0.3) : AppColors.secondary.withValues(alpha: 0.25),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: n.isRead ? Colors.transparent : AppColors.secondary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            n.title,
                                            style: AppTypography.buttonText.copyWith(
                                              fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                                              color: AppColors.onSurface,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          DateFormat('MMM d, HH:mm').format(n.createdAt),
                                          style: AppTypography.labelMonoSm.copyWith(
                                            color: AppColors.outline,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n.message,
                                      style: AppTypography.bodySm.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
