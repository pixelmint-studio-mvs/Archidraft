import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/metrics_providers.dart';
import '../../domain/student_metrics.dart';

class StudentSkillMatrix extends ConsumerWidget {
  const StudentSkillMatrix({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(studentMetricsProvider);

    return metricsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorState(onRetry: () => ref.invalidate(studentMetricsProvider)),
      data: (metrics) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('STUDENT SKILL MATRIX'),
          const SizedBox(height: AppSpacing.md),
          _LearningProgressCard(learning: metrics.learning),
          const SizedBox(height: AppSpacing.md),
          _PracticalProficiencyCard(practical: metrics.practical),
          const SizedBox(height: AppSpacing.md),
          _ActivityMetricsCard(activity: metrics.activity),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.labelMono.copyWith(
        color: AppColors.onSurfaceVariant,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _LearningProgressCard extends StatelessWidget {
  final List<LearningMetric> learning;
  const _LearningProgressCard({required this.learning});

  @override
  Widget build(BuildContext context) {
    return _MatrixCard(
      title: 'LEARNING PROGRESS',
      icon: Icons.school_outlined,
      child: learning.isEmpty
          ? const _EmptyState('No learning data available.')
          : Column(
              children: learning.map((metric) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            metric.category.toUpperCase(),
                            style: AppTypography.bodySm.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Text(
                            '${metric.percentage}%',
                            style: AppTypography.bodySm.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${metric.completedLessons} of ${metric.totalLessons} lessons completed',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        child: LinearProgressIndicator(
                          value: metric.totalLessons > 0 ? metric.completedLessons / metric.totalLessons : 0,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _PracticalProficiencyCard extends StatelessWidget {
  final List<PracticalMetric> practical;
  const _PracticalProficiencyCard({required this.practical});

  @override
  Widget build(BuildContext context) {
    return _MatrixCard(
      title: 'PRACTICAL PROFICIENCY',
      icon: Icons.architecture_outlined,
      child: practical.isEmpty
          ? const _EmptyState('No evaluation data yet. Proficiency appears after evaluated project work.')
          : Column(
              children: practical.map((metric) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            metric.name,
                            style: AppTypography.bodySm.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Text(
                            '${metric.score.toStringAsFixed(1)} / ${metric.maxScore} (${metric.percentage}%)',
                            style: AppTypography.bodySm.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Based on ${metric.evaluationCount} evaluation(s)',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        child: LinearProgressIndicator(
                          value: metric.maxScore > 0 ? metric.score / metric.maxScore : 0,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _ActivityMetricsCard extends StatelessWidget {
  final ActivityMetric activity;
  const _ActivityMetricsCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return _MatrixCard(
      title: 'PROJECT ACTIVITY',
      icon: Icons.assignment_turned_in_outlined,
      child: Row(
        children: [
          Expanded(
            child: _ActivityStat(
              label: 'Completed Projects',
              value: activity.completedProjects.toString(),
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.outline),
          Expanded(
            child: _ActivityStat(
              label: 'Correction Rounds',
              value: activity.correctionRounds.toString(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityStat extends StatelessWidget {
  final String label;
  final String value;
  const _ActivityStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headlineLgMobile.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _MatrixCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _MatrixCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.onSurfaceVariant, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Failed to load metrics.',
            style: AppTypography.bodySm.copyWith(color: AppColors.onErrorContainer),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: AppColors.onErrorContainer),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
