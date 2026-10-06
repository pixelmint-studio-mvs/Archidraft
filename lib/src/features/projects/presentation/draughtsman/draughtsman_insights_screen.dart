import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../domain/assignment_status.dart';
import '../../providers/assignment_providers.dart';
import '../../providers/project_providers.dart';

/// Insights screen for the Draughtsman portal.
///
/// Displays real summary statistics derived from the assignments API and
/// the /api/draughtsman/summary endpoint. No placeholder data.
class DraughtsmanInsightsScreen extends ConsumerWidget {
  const DraughtsmanInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(draughtsmanSummaryProvider);
    final assignmentsAsync = ref.watch(draughtsmanAssignmentsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(draughtsmanSummaryProvider);
          ref.invalidate(draughtsmanAssignmentsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            SliverToBoxAdapter(
              child: summaryAsync.when(
                loading: () => const AppLoadingIndicator(message: 'Loading metrics...'),
                error: (e, _) => AppErrorWidget(
                  message: 'Failed to load metrics.',
                  onRetry: () => ref.invalidate(draughtsmanSummaryProvider),
                ),
                data: (summary) => _buildMetricGrid(summary),
              ),
            ),
            SliverToBoxAdapter(
              child: assignmentsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (assignments) => _buildActivityBreakdown(assignments),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insights',
            style: AppTypography.headlineLg.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your performance overview and drawing statistics.',
            style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGrid(Map<String, dynamic> summary) {
    final total = (summary['total_assignments'] as num?)?.toInt() ?? 0;
    final pending = (summary['pending'] as num?)?.toInt() ?? 0;
    final inProgress = (summary['in_progress'] as num?)?.toInt() ?? 0;
    final underReview = (summary['under_review'] as num?)?.toInt() ?? 0;
    final corrections = (summary['corrections'] as num?)?.toInt() ?? 0;
    final completed = (summary['completed'] as num?)?.toInt() ?? 0;
    final rejected = (summary['rejected'] as num?)?.toInt() ?? 0;

    // Completion rate
    final completionRate = total > 0 ? (completed / total * 100).toStringAsFixed(1) : '—';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OVERVIEW',
            style: AppTypography.labelMono.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Hero metric
          _HeroMetricCard(
            label: 'Total Assignments',
            value: '$total',
            sublabel: '$completionRate% completion rate',
            icon: Icons.assignment_outlined,
          ),
          const SizedBox(height: AppSpacing.md),

          // 2-column grid of metrics
          Row(
            children: [
              Expanded(child: _SmallMetricCard(label: 'PENDING', value: '$pending', color: AppColors.warning)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _SmallMetricCard(label: 'IN PROGRESS', value: '$inProgress', color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _SmallMetricCard(label: 'UNDER REVIEW', value: '$underReview', color: AppColors.onPrimaryContainer)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _SmallMetricCard(label: 'COMPLETED', value: '$completed', color: AppColors.success)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _SmallMetricCard(label: 'CORRECTIONS', value: '$corrections', color: AppColors.error)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _SmallMetricCard(label: 'REJECTED', value: '$rejected', color: AppColors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBreakdown(List assignments) {
    if (assignments.isEmpty) return const SizedBox.shrink();

    // Group assignments by month for a timeline breakdown
    final grouped = <String, int>{};
    for (final a in assignments) {
      final createdAt = a.createdAt;
      if (createdAt == null) continue;
      final key = DateFormat('MMM yyyy').format(createdAt);
      grouped[key] = (grouped[key] ?? 0) + 1;
    }

    // Status distribution
    final statusCounts = <AssignmentStatus, int>{};
    for (final a in assignments) {
      final s = a.assignmentStatus ?? AssignmentStatus.pending;
      statusCounts[s] = (statusCounts[s] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'STATUS DISTRIBUTION',
            style: AppTypography.labelMono.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _StatusDistributionBar(statusCounts: statusCounts, total: assignments.length),
          const SizedBox(height: AppSpacing.xl),

          if (grouped.isNotEmpty) ...[
            Text(
              'ACTIVITY TIMELINE',
              style: AppTypography.labelMono.copyWith(
                color: AppColors.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...grouped.entries.map((entry) => _TimelineRow(month: entry.key, count: entry.value, maxCount: grouped.values.fold(0, (a, b) => a > b ? a : b))),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Hero Metric Card
// ─────────────────────────────────────────

class _HeroMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String sublabel;
  final IconData icon;

  const _HeroMetricCard({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.03),
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: AppSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.headlineLg.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 36,
                ),
              ),
              Text(label, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
              Text(sublabel, style: AppTypography.labelMonoSm.copyWith(color: AppColors.outline)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Small Metric Card
// ─────────────────────────────────────────

class _SmallMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SmallMetricCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypography.headlineLgMobile.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelMonoSm.copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Status Distribution Bar
// ─────────────────────────────────────────

class _StatusDistributionBar extends StatelessWidget {
  final Map<AssignmentStatus, int> statusCounts;
  final int total;

  const _StatusDistributionBar({required this.statusCounts, required this.total});

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();

    final colors = {
      AssignmentStatus.pending: AppColors.warning,
      AssignmentStatus.accepted: AppColors.secondary,
      AssignmentStatus.completed: AppColors.success,
      AssignmentStatus.rejected: AppColors.error,
      AssignmentStatus.replaced: AppColors.onPrimaryContainer,
    };

    return Column(
      children: [
        // Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: Row(
            children: AssignmentStatus.values.where((s) => statusCounts.containsKey(s)).map((s) {
              final count = statusCounts[s] ?? 0;
              final fraction = count / total;
              return Expanded(
                flex: (fraction * 1000).round(),
                child: Container(
                  height: 12,
                  color: colors[s] ?? AppColors.outline,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Legend
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: AssignmentStatus.values.where((s) => statusCounts.containsKey(s)).map((s) {
            final count = statusCounts[s] ?? 0;
            final color = colors[s] ?? AppColors.outline;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                const SizedBox(width: 4),
                Text(
                  '${s.displayName} ($count)',
                  style: AppTypography.labelMonoSm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// Timeline Row
// ─────────────────────────────────────────

class _TimelineRow extends StatelessWidget {
  final String month;
  final int count;
  final int maxCount;

  const _TimelineRow({required this.month, required this.count, required this.maxCount});

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount > 0 ? count / maxCount : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              month,
              style: AppTypography.labelMonoSm.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '$count',
                      style: AppTypography.labelMonoSm.copyWith(
                        color: AppColors.onSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
