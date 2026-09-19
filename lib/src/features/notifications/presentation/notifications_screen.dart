import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../shell/presentation/widgets/app_top_bar.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/notification_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final user = userProfileAsync.value;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar(profile: user),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              return Card(
                elevation: 0,
                color: n.isRead
                    ? AppColors.surface
                    : AppColors.primaryContainer.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  side: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  title: Text(
                    n.title,
                    style: AppTypography.bodyMd.copyWith(
                      fontWeight: n.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(n.message, style: AppTypography.bodyMd),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, y h:mm a').format(n.createdAt),
                        style: AppTypography.labelMono.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  trailing: n.isRead
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () async {
                            await ref
                                .read(notificationRepositoryProvider)
                                .markAsRead(n.id);
                            ref.invalidate(notificationsProvider);
                          },
                        ),
                  onTap: () async {
                    if (!n.isRead) {
                      await ref
                          .read(notificationRepositoryProvider)
                          .markAsRead(n.id);
                      ref.invalidate(notificationsProvider);
                    }
                    if (n.projectId != null && context.mounted) {
                      if (user?.role == 'CLIENT') {
                        context.go('/project/${n.projectId}');
                      } else if (user?.role == 'DRAUGHTSMAN') {
                        context.go('/draughtsman/assignment/${n.projectId}');
                      }
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
