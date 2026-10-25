import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/domain/user_profile.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../notifications/providers/notification_providers.dart';
import 'package:archi_draft/src/shared/widgets/hexagonal_monogram_3d_viewer.dart';

/// Top App Bar using the Stitch glass effect.
///
/// Ref: REFERENCE DESIGN/stitch_draughtsman_studio_os/draughtsman_studio_dashboard
class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final UserProfile? profile;
  final List<Widget>? navigationItems;

  const AppTopBar({
    super.key,
    required this.profile,
    this.navigationItems,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = AppBreakpoints.isMobile(MediaQuery.sizeOf(context).width);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant,
            width: 1.0,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.marginMobile : AppSpacing.marginDesktop,
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
                const HexagonalMonogram3DViewer(width: 28, height: 28, autoRotate: true, rotationSpeed: '36deg'),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  profile?.role.toUpperCase() ?? 'ARCHI DRAFT',
                  style: AppTypography.headlineLgMobile.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w700,
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
                  onTap: () {
                    if (profile?.role.toUpperCase() == 'DRAUGHTSMAN') {
                      context.push('/draughtsman/notifications');
                    } else {
                      context.push('/notifications');
                    }
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                if (profile != null)
                  PopupMenuButton<String>(
                    offset: const Offset(0, 45),
                    onSelected: (value) {
                      if (value == 'profile') {
                        final roleUpper = profile?.role.toUpperCase();
                        if (roleUpper == 'STUDENT') {
                          context.go('/student/profile');
                        } else if (roleUpper == 'DRAUGHTSMAN') {
                          context.go('/draughtsman/profile');
                        } else {
                          context.go('/engineer/profile');
                        }
                      } else if (value == 'logout') {
                        ref.read(authControllerProvider.notifier).signOut();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person_outline, size: 20),
                            SizedBox(width: AppSpacing.sm),
                            Text('My Profile'),
                          ],
                        ),
                      ),
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
                          color: AppColors.outlineVariant,
                          width: 1.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        profile!.name.isNotEmpty ? profile!.name[0].toUpperCase() : '?',
                        style: AppTypography.buttonText.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
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
