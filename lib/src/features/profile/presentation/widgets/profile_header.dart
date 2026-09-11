import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/domain/user_profile.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile profile;

  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    // Generate initials for the avatar placeholder
    final initials = profile.name.isNotEmpty 
        ? profile.name.trim().split(' ').take(2).map((s) => s.isNotEmpty ? s[0] : '').join().toUpperCase()
        : '?';

    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: AppTypography.headlineLg.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name,
                style: AppTypography.headlineLgMobile.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                profile.email,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryFixed.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  profile.role.toUpperCase(),
                  style: AppTypography.labelMono.copyWith(
                    color: AppColors.onSecondaryFixedVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
