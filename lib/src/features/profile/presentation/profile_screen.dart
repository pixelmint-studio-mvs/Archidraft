import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import 'widgets/profile_form.dart';
import 'widgets/profile_header.dart';

/// Screen for displaying and editing the user's profile.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final authController = ref.watch(authControllerProvider);
    final isSigningOut = authController is AsyncLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: AppTypography.headlineLgMobile.copyWith(color: AppColors.primary),
        ),
        actions: [
          IconButton(
            icon: isSigningOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.error,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.logout_rounded, color: AppColors.error),
            onPressed: isSigningOut
                ? null
                : () {
                    // Sign out
                    ref.read(authControllerProvider.notifier).signOut();
                  },
            tooltip: 'Sign Out',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: profileAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Loading profile...'),
        error: (err, stack) => AppErrorWidget(
          message: 'Failed to load profile.',
          onRetry: () => ref.refresh(userProfileProvider),
        ),
        data: (profile) {
          if (profile == null) {
            return const AppEmptyState(
              title: 'Profile not found',
              subtitle: 'We could not find your profile information.',
              icon: Icons.person_off_outlined,
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Header Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.03),
                        blurRadius: 40,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ProfileHeader(profile: profile),
                ),
                const SizedBox(height: AppSpacing.xl),
                
                // Profile Form Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.03),
                        blurRadius: 40,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ProfileForm(profile: profile),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          );
        },
      ),
    );
  }
}
