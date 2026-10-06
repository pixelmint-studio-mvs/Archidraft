import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/domain/user_profile.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../notifications/presentation/notifications_dialog.dart';
import '../../../notifications/providers/notification_providers.dart';

/// Top App Bar using the Stitch glass effect.
///
/// Used on Desktop layout, or as the standard AppBar on mobile/tablet.
class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final UserProfile? profile;
  final List<Widget>? navigationItems;

  const AppTopBar({
    super.key,
    this.profile,
    this.navigationItems,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassWhite,
            border: Border(
              bottom: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginDesktop,
            vertical: AppSpacing.md,
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Brand
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: const Icon(
                        Icons.architecture_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'DRAUGHTSMAN',
                      style: AppTypography.headlineLgMobile.copyWith(
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                
                // Desktop Navigation (if provided)
                if (navigationItems != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: navigationItems!,
                  ),

                // Avatar / Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NotificationBell(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => const NotificationsDialog(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (profile != null)
                      PopupMenuButton<String>(
                        offset: const Offset(0, 45),
                        onSelected: (value) {
                          if (value == 'logout') {
                            ref.read(authControllerProvider.notifier).signOut();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, size: 20),
                                SizedBox(width: AppSpacing.sm),
                                Text('Logout'),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            profile!.name.isNotEmpty ? profile!.name[0].toUpperCase() : '?',
                            style: AppTypography.buttonText.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.appBarHeight);
}

/// Notification bell button with unread count badge.
class _NotificationBell extends ConsumerWidget {
  final VoidCallback onTap;
  const _NotificationBell({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = notificationsAsync.maybeWhen(
      data: (list) => list.where((n) => !n.isRead).length,
      orElse: () => 0,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            unreadCount > 0
                ? Icons.notifications_rounded
                : Icons.notifications_none_rounded,
          ),
          color: AppColors.onSurfaceVariant,
          onPressed: onTap,
        ),
        if (unreadCount > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceContainerLowest, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
