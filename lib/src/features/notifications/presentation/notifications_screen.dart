import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
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
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: AppTypography.headlineSmMobile.copyWith(color: AppColors.onSurface),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              if (user?.role == 'STUDENT') {
                context.go('/student/dashboard');
              } else if (user?.role == 'DRAUGHTSMAN') {
                context.go('/draughtsman/studio');
              } else if (user?.role == 'ADMIN' || user?.role == 'STUDIO_ADMIN') {
                context.go('/admin/dashboard');
              } else {
                context.go('/client/projects');
              }
            }
          },
        ),
      ),
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
                    if (context.mounted) {
                      final role = user?.role;
                      final projectId = n.projectId;
                      if (role == 'ADMIN' || role == 'STUDIO_ADMIN') {
                        if (projectId != null && projectId.isNotEmpty) {
                          context.go('/admin/projects/$projectId');
                        } else {
                          context.go('/admin/dashboard');
                        }
                      } else if (projectId != null && projectId.isNotEmpty) {
                        if (role == 'CLIENT') {
                          context.go('/client/projects/$projectId');
                        } else if (role == 'DRAUGHTSMAN') {
                          if (n.type == 'DRAUGHTSMAN_ASSIGNED' ||
                              n.type == 'WAITING_ACCEPTANCE') {
                            context.go('/draughtsman/assignments/$projectId');
                          } else {
                            context.go('/draughtsman/workspace/$projectId');
                          }
                        } else if (role == 'STUDENT') {
                          context.go('/student/workspace/$projectId');
                        }
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
