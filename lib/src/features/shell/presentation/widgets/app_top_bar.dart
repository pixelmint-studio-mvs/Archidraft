import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/domain/user_profile.dart';
import '../../../notifications/presentation/widgets/notifications_badge.dart';
import '../../../auth/providers/auth_providers.dart';

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
                    const NotificationsBadge(),
                    const SizedBox(width: AppSpacing.sm),
                    if (profile != null)
                      PopupMenuButton<String>(
                        offset: const Offset(0, 48),
                        onSelected: (value) {
                          if (value == 'profile') {
                            context.go('/client/profile');
                          } else if (value == 'logout') {
                            ref.read(authControllerProvider.notifier).signOut();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 20),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'My Profile',
                                  style: AppTypography.bodyMd,
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                const Icon(Icons.logout_rounded, size: 20, color: AppColors.error),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Sign Out',
                                  style: AppTypography.bodyMd.copyWith(color: AppColors.error),
                                ),
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
