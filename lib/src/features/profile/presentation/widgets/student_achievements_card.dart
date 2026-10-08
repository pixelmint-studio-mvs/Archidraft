import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/achievements_providers.dart';

class StudentAchievementsCard extends ConsumerWidget {
  const StudentAchievementsCard({super.key});

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'school_outlined':
        return Icons.school_outlined;
      case 'workspace_premium_outlined':
        return Icons.workspace_premium_outlined;
      case 'assignment_turned_in_outlined':
        return Icons.assignment_turned_in_outlined;
      case 'verified_outlined':
        return Icons.verified_outlined;
      case 'military_tech_outlined':
        return Icons.military_tech_outlined;
      default:
        return Icons.emoji_events_outlined;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(studentAchievementsProvider);

    return achievementsAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Failed to load achievements',
                style: AppTypography.bodyMd.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: () => ref.invalidate(studentAchievementsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (achievements) {
        if (achievements.isEmpty) {
          return const SizedBox.shrink();
        }

        final unlockedCount = achievements.where((a) => a.isUnlocked).length;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.03),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(
                      Icons.emoji_events_outlined,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STUDENT MILESTONES',
                          style: AppTypography.labelMono.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Achievements & Progress Badges',
                          style: AppTypography.headlineSmMobile.copyWith(
                            color: AppColors.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: unlockedCount > 0
                          ? AppColors.primaryContainer.withValues(alpha: 0.6)
                          : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      '$unlockedCount / ${achievements.length}',
                      style: AppTypography.labelMono.copyWith(
                        color: unlockedCount > 0
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Achievements list
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: achievements.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  final isUnlocked = achievement.isUnlocked;

                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? AppColors.surfaceBright
                          : AppColors.surfaceContainerLow.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: isUnlocked
                            ? AppColors.outlineVariant.withValues(alpha: 0.5)
                            : AppColors.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge Icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isUnlocked
                                ? AppColors.primaryContainer.withValues(alpha: 0.5)
                                : AppColors.surfaceContainerHigh,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: Icon(
                            _getIconData(achievement.icon),
                            color: isUnlocked
                                ? AppColors.primary
                                : AppColors.outline,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),

                        // Title, Description, and Progress
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      achievement.title,
                                      style: AppTypography.bodyMd.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isUnlocked
                                            ? AppColors.onSurface
                                            : AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xs,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isUnlocked
                                          ? AppColors.primaryContainer
                                              .withValues(alpha: 0.5)
                                          : AppColors.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusDefault),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isUnlocked
                                              ? Icons.check_circle_rounded
                                              : Icons.lock_outline_rounded,
                                          size: 12,
                                          color: isUnlocked
                                              ? AppColors.primary
                                              : AppColors.outline,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          isUnlocked ? 'Unlocked' : 'Locked',
                                          style: AppTypography.labelMonoSm.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isUnlocked
                                                ? AppColors.primary
                                                : AppColors.outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                achievement.description,
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              if (isUnlocked && achievement.unlockedAt != null)
                                Text(
                                  'Earned ${_formatDate(achievement.unlockedAt!)}',
                                  style: AppTypography.labelMonoSm.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              else
                                Text(
                                  'In Progress (${achievement.currentProgress}/${achievement.targetProgress})',
                                  style: AppTypography.labelMonoSm.copyWith(
                                    color: AppColors.outline,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
