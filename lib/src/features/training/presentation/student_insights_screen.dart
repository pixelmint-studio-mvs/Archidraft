import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/training_module.dart';
import '../providers/training_providers.dart';

class StudentInsightsScreen extends ConsumerWidget {
  const StudentInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(categoryProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(categoryProgressProvider);
          },
          color: AppColors.secondary,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Performance Insights',
                        style: AppTypography.headlineLgMobile
                            .copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'View your learning performance and progress analytics.',
                        style: AppTypography.bodyMd
                            .copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
              progressAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.secondary),
                  ),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'Failed to load insights.\n$error',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMd
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                  ),
                ),
                data: (progressList) {
                  if (progressList.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 64,
                              color: AppColors.outlineVariant.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No Data Yet',
                              style: AppTypography.headlineSmMobile
                                  .copyWith(color: AppColors.onSurface),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Complete training modules to see your insights.',
                              style: AppTypography.bodyMd
                                  .copyWith(color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Calculate some aggregate stats
                  final totalProgress = progressList.fold<double>(
                      0, (sum, item) => sum + item.overallProgress);
                  final avgProgress = totalProgress / progressList.length;

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: _buildOverviewCard(avgProgress),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Text(
                          'Category Mastery',
                          style: AppTypography.headlineSmMobile
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ...progressList.map((p) => Padding(
                            padding: const EdgeInsets.only(
                                left: AppSpacing.lg,
                                right: AppSpacing.lg,
                                bottom: AppSpacing.md),
                            child: _buildCategoryCard(p),
                          )),
                    ]),
                  );
                },
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xxl)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(double averageProgress) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Overall Training Completion',
            style: AppTypography.bodyMd
                .copyWith(color: AppColors.onPrimary.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${(averageProgress * 100).toInt()}%',
            style: AppTypography.headlineDisplay.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: averageProgress,
              backgroundColor: AppColors.onPrimary.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(TrainingCategoryProgress progress) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                progress.category,
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(progress.overallProgress * 100).toInt()}%',
                  style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: progress.overallProgress,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
