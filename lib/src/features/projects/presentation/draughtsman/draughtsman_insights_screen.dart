import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../domain/assignment.dart';
import '../../domain/assignment_status.dart';
import '../../providers/assignment_providers.dart';
import '../../providers/project_providers.dart';

// ---------------------------------------------------------------------------
// TIME RANGE FILTER ENUM
// ---------------------------------------------------------------------------

enum _InsightsTimeRange {
  last6Months('Last 6 Months', 6),
  last12Months('Last 12 Months', 12),
  allTime('All Time', 0);

  final String label;
  final int monthsBack;
  const _InsightsTimeRange(this.label, this.monthsBack);
}

// ---------------------------------------------------------------------------
// BLUEPRINT GRID BACKGROUND PAINTER (40px unit from DESIGN.md)
// ---------------------------------------------------------------------------

class _BlueprintGridBackgroundPainter extends CustomPainter {
  const _BlueprintGridBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const double gridSize = 40.0;
    final gridPaint = Paint()
      ..color = const Color(0xFF75777E).withValues(alpha: 0.05)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// INSIGHTS SCREEN
// ---------------------------------------------------------------------------

/// Panel 8 — Insights Screen for the Draughtsman Portal.
///
/// Faithfully reproduces the executive dashboard bento layout from:
/// `REFERENCE DESIGN/stitch_draughtsman_studio_os/stitch_draughtsman_studio_os/executive_dashboard/code.html`
/// and adheres to `architectural_precision_system/DESIGN.md`.
class DraughtsmanInsightsScreen extends ConsumerStatefulWidget {
  const DraughtsmanInsightsScreen({super.key});

  @override
  ConsumerState<DraughtsmanInsightsScreen> createState() =>
      _DraughtsmanInsightsScreenState();
}

class _DraughtsmanInsightsScreenState
    extends ConsumerState<DraughtsmanInsightsScreen> {
  _InsightsTimeRange _selectedTimeRange = _InsightsTimeRange.last6Months;
  int? _hoveredBarIndex;

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(draughtsmanSummaryProvider);
    final assignmentsAsync = ref.watch(draughtsmanAssignmentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9FB),
      body: CustomPaint(
        painter: const _BlueprintGridBackgroundPainter(),
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(draughtsmanSummaryProvider);
            ref.invalidate(draughtsmanAssignmentsProvider);
          },
          child: summaryAsync.when(
            loading: () => const AppLoadingIndicator(
              message: 'Loading executive vitals...',
            ),
            error: (err, _) => AppErrorWidget(
              message: 'Failed to load executive vitals: $err',
              onRetry: () {
                ref.invalidate(draughtsmanSummaryProvider);
                ref.invalidate(draughtsmanAssignmentsProvider);
              },
            ),
            data: (summary) {
              return assignmentsAsync.when(
                loading: () => const AppLoadingIndicator(
                  message: 'Loading assignment telemetry...',
                ),
                error: (err, _) => AppErrorWidget(
                  message: 'Failed to load assignments: $err',
                  onRetry: () =>
                      ref.invalidate(draughtsmanAssignmentsProvider),
                ),
                data: (assignments) {
                  return _buildDashboardContent(
                    context,
                    summary,
                    assignments,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    Map<String, dynamic> summary,
    List<Assignment> assignments,
  ) {
    // ── Metric extractions ───────────────────────────────────────────────
    final total = (summary['total_assignments'] as num?)?.toInt() ?? 0;
    final pending = (summary['pending'] as num?)?.toInt() ?? 0;
    final inProgress = (summary['in_progress'] as num?)?.toInt() ?? 0;
    final underReview = (summary['under_review'] as num?)?.toInt() ?? 0;
    final corrections = (summary['corrections'] as num?)?.toInt() ?? 0;
    final completed = (summary['completed'] as num?)?.toInt() ?? 0;

    final activeCount = inProgress + underReview + corrections;
    final completionRate =
        total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0.0';

    // Capacity percentage: active assignments relative to a realistic workload pool (e.g. 10)
    final capacityPct =
        total > 0 ? ((activeCount / 10).clamp(0.0, 1.0) * 100).toInt() : 0;

    // Quality / Productivity rate: First-time pass rate without corrections
    final productivityRate = total > 0
        ? (((total - corrections) / total).clamp(0.0, 1.0) * 100)
            .toStringAsFixed(0)
        : '100';

    final productivityScore = int.tryParse(productivityRate) ?? 100;
    final productivityLabel = productivityScore >= 85
        ? 'Optimal'
        : productivityScore >= 70
            ? 'Standard'
            : 'Attention';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Studio Overview Hero Card (Reference lines 141-152) ──
              _buildStudioOverviewHero(context),

              const SizedBox(height: AppSpacing.xl),

              // ── 2. Key Metrics Bento Grid (Reference lines 153-202) ──
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 840;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _BentoMetricCard(
                            label: 'COMPLETED OUTPUT',
                            value: '$completed',
                            badgeIcon: Icons.arrow_upward_rounded,
                            badgeText: '$completionRate%',
                            badgeSubtext: 'completion rate',
                            cornerIcon: Icons.trending_up_rounded,
                            cornerColor: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _BentoCapacityCard(
                            label: 'ACTIVE PROJECTS',
                            value: '$activeCount',
                            capacityPct: capacityPct,
                            sublabel: '$pending pending new',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _BentoMetricCard(
                            label: 'PRODUCTIVITY',
                            value: '$productivityRate%',
                            badgeIcon: Icons.speed_rounded,
                            badgeText: productivityLabel,
                            badgeSubtext: 'studio efficiency',
                            cornerIcon: Icons.speed_rounded,
                            cornerColor: const Color(0xFF069669),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _BentoMetricCard(
                          label: 'COMPLETED OUTPUT',
                          value: '$completed',
                          badgeIcon: Icons.arrow_upward_rounded,
                          badgeText: '$completionRate%',
                          badgeSubtext: 'completion rate',
                          cornerIcon: Icons.trending_up_rounded,
                          cornerColor: AppColors.secondary,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _BentoCapacityCard(
                          label: 'ACTIVE PROJECTS',
                          value: '$activeCount',
                          capacityPct: capacityPct,
                          sublabel: '$pending pending new',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _BentoMetricCard(
                          label: 'PRODUCTIVITY',
                          value: '$productivityRate%',
                          badgeIcon: Icons.speed_rounded,
                          badgeText: productivityLabel,
                          badgeSubtext: 'studio efficiency',
                          cornerIcon: Icons.speed_rounded,
                          cornerColor: const Color(0xFF069669),
                        ),
                      ],
                    );
                  }
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── 3. Charts & Submissions Bento Row (Reference lines 203-299) ──
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 900;
                  return isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Monthly Cadence Chart (Span 2)
                            Expanded(
                              flex: 2,
                              child: _buildMonthlyActivityCard(assignments),
                            ),
                            const SizedBox(width: AppSpacing.gridGutter),
                            // Recent Submissions (Span 1)
                            Expanded(
                              flex: 1,
                              child: _buildRecentSubmissionsCard(
                                context,
                                assignments,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildMonthlyActivityCard(assignments),
                            const SizedBox(height: AppSpacing.xl),
                            _buildRecentSubmissionsCard(context, assignments),
                          ],
                        );
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── 4. Workflow Velocity & Pipeline Distribution Card ──
              _buildPipelineDistributionCard(
                total: total,
                pending: pending,
                inProgress: inProgress,
                underReview: underReview,
                corrections: corrections,
                completed: completed,
                assignments: assignments,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── 5. System Footer Signature (Reference line 303 & DESIGN.md) ──
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Text(
                    'UI/UX Design & Product Experience crafted by PixelMint Studio MVS',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.outline,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. STUDIO OVERVIEW HERO (Reference lines 141-152)
  // ---------------------------------------------------------------------------

  Widget _buildStudioOverviewHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.05),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.03),
            offset: const Offset(0, 20),
            blurRadius: 40,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ambient background glow (Reference line 143)
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Studio Overview',
                style: AppTypography.headlineDisplay.copyWith(
                  color: AppColors.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Text(
                  'Welcome back to the executive suite. System vitals are optimal. Here is your current studio performance.',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  ElevatedButton.icon(
                    key: const Key('insights_refresh_vitals_button'),
                    onPressed: () {
                      ref.invalidate(draughtsmanSummaryProvider);
                      ref.invalidate(draughtsmanAssignmentsProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Executive vitals refreshed.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Refresh Vitals'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusDefault),
                      ),
                      elevation: 0,
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const Key('insights_view_pipeline_button'),
                    onPressed: () => context.go('/draughtsman/studio'),
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('View Pipeline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusDefault),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. MONTHLY ACTIVITY CADENCE CHART (Reference lines 205-234)
  // ---------------------------------------------------------------------------

  Widget _buildMonthlyActivityCard(List<Assignment> assignments) {
    // Generate chronological monthly buckets based on selected filter
    final now = DateTime.now();
    final monthBuckets = <DateTime, int>{};

    final int numMonths = _selectedTimeRange.monthsBack == 0
        ? 12
        : _selectedTimeRange.monthsBack;

    for (int i = numMonths - 1; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      monthBuckets[monthDate] = 0;
    }

    // Populate honest counts from actual assignment timestamps
    int totalAssignmentsInPeriod = 0;
    for (final a in assignments) {
      final date = a.assignedAt ?? a.createdAt;
      if (date != null) {
        final bucketDate = DateTime(date.year, date.month, 1);
        if (monthBuckets.containsKey(bucketDate)) {
          monthBuckets[bucketDate] = (monthBuckets[bucketDate] ?? 0) + 1;
          totalAssignmentsInPeriod++;
        }
      }
    }

    final maxCount = monthBuckets.values.isEmpty
        ? 1
        : monthBuckets.values.reduce(math.max);
    final effectiveMax = maxCount == 0 ? 1 : maxCount;

    return Container(
      height: 380,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.03),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Title and Time-Range Filter
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Growth',
                    style: AppTypography.headlineLgMobile.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalAssignmentsInPeriod assignments logged in ${_selectedTimeRange.label.toLowerCase()}',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.outline,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              PopupMenuButton<_InsightsTimeRange>(
                key: const Key('insights_time_range_menu'),
                tooltip: 'Select Time Window',
                initialValue: _selectedTimeRange,
                onSelected: (range) {
                  setState(() {
                    _selectedTimeRange = range;
                    _hoveredBarIndex = null;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusDefault),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedTimeRange.label,
                        style: AppTypography.labelMonoSm.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.more_horiz_rounded,
                        size: 16,
                        color: AppColors.outline,
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context) => _InsightsTimeRange.values.map((r) {
                  return PopupMenuItem<_InsightsTimeRange>(
                    value: r,
                    child: Text(
                      r.label,
                      style: AppTypography.bodyMd.copyWith(fontSize: 13),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Chart Graphic Area (Reference lines 211-230)
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Stack(
                children: [
                  // Dashed Horizontal Reference Grid Lines (Reference lines 225-228)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) {
                      return CustomPaint(
                        size: const Size(double.infinity, 1),
                        painter: const _DashedLinePainter(
                          color: Color(0x3375777E),
                        ),
                      );
                    }),
                  ),

                  // Vertical Bars
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final entries = monthBuckets.entries.toList();
                      final double barWidth =
                          (constraints.maxWidth / entries.length * 0.45)
                              .clamp(14.0, 42.0);

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: entries.asMap().entries.map((item) {
                          final index = item.key;
                          final entry = item.value;
                          final monthLabel = DateFormat('MMM').format(entry.key);
                          final count = entry.value;

                          final isCurrentMonth = entry.key.month == now.month &&
                              entry.key.year == now.year;
                          final isPeak =
                              count == maxCount && count > 0 && maxCount > 1;

                          // Height calculation: clamped to ensure minimum visible baseline
                          final double heightFactor = count > 0
                              ? (count / effectiveMax).clamp(0.12, 0.90)
                              : 0.04;

                          final double barHeight =
                              (constraints.maxHeight - 40) * heightFactor;

                          final isHovered = _hoveredBarIndex == index;

                          return MouseRegion(
                            onEnter: (_) =>
                                setState(() => _hoveredBarIndex = index),
                            onExit: (_) =>
                                setState(() => _hoveredBarIndex = null),
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '$monthLabel ${entry.key.year}: $count assignment${count == 1 ? '' : 's'}',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Peak or Hover Tooltip Tag (Reference line 220)
                                  if (isPeak || isHovered)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isHovered
                                            ? AppColors.primary
                                            : const Color(0xFF000000),
                                        borderRadius: BorderRadius.circular(3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.1),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        isHovered
                                            ? '$count'
                                            : (isPeak ? 'Peak' : '$count'),
                                        style: AppTypography.labelMonoSm
                                            .copyWith(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox(height: 18),

                                  // Bar Pillar
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 250),
                                    width: barWidth,
                                    height: math.max(4.0, barHeight),
                                    decoration: BoxDecoration(
                                      color: isCurrentMonth
                                          ? AppColors.secondary
                                          : count > 0
                                              ? (isHovered
                                                  ? AppColors.secondary
                                                      .withValues(alpha: 0.7)
                                                  : AppColors.surfaceVariant)
                                              : AppColors.outlineVariant
                                                  .withValues(alpha: 0.3),
                                      borderRadius:
                                          const BorderRadius.vertical(
                                        top: Radius.circular(3),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Month Label (Reference line 232)
                                  Text(
                                    monthLabel,
                                    style: AppTypography.labelMonoSm.copyWith(
                                      color: isCurrentMonth
                                          ? AppColors.primary
                                          : AppColors.outline,
                                      fontWeight: isCurrentMonth
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. RECENT SUBMISSIONS LIST (Reference lines 236-298)
  // ---------------------------------------------------------------------------

  Widget _buildRecentSubmissionsCard(
    BuildContext context,
    List<Assignment> assignments,
  ) {
    // Sort assignments by latest update/creation
    final sorted = List<Assignment>.from(assignments)
      ..sort((a, b) {
        final aDate = a.updatedAt ?? a.createdAt ?? DateTime(2000);
        final bDate = b.updatedAt ?? b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

    final recent = sorted.take(4).toList();

    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.03),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (Reference line 237-240)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Submissions',
                  style: AppTypography.buttonText.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Icon(
                  Icons.history_rounded,
                  size: 16,
                  color: AppColors.outline,
                ),
              ],
            ),
          ),
          Divider(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
            height: 1,
          ),

          // Submissions List
          Expanded(
            child: recent.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.folder_open_outlined,
                            size: 32,
                            color: AppColors.outline.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No submissions yet',
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.outline,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: recent.length,
                    separatorBuilder: (_, _) => Divider(
                      color: AppColors.outlineVariant.withValues(alpha: 0.15),
                      height: 1,
                    ),
                    itemBuilder: (context, i) {
                      final a = recent[i];
                      final isCorrecting = (a.correctionRound ?? 0) > 0 ||
                          a.projectStatus == 'CORRECTIONS';
                      final isUnderReview =
                          a.projectStatus == 'UNDER_CLIENT_REVIEW';
                      final isCompleted =
                          a.assignmentStatus == AssignmentStatus.completed ||
                              a.projectStatus == 'COMPLETED';

                      final relativeTime = _formatRelativeTime(
                        a.updatedAt ?? a.createdAt,
                      );

                      final code = a.projectId.length >= 8
                          ? a.projectId.substring(0, 8).toUpperCase()
                          : a.projectId.toUpperCase();

                      return InkWell(
                        onTap: () => context.push(
                          '/draughtsman/assignments/${a.id}',
                          extra: a,
                        ),
                        hoverColor: AppColors.surfaceVariant.withValues(alpha: 0.3),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              // Icon container (Reference line 245)
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  isCorrecting
                                      ? Icons.edit_note_rounded
                                      : Icons.description_outlined,
                                  size: 16,
                                  color: AppColors.outline,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),

                              // Text Details (Reference lines 248-250)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.displayProjectName,
                                      style: AppTypography.buttonText.copyWith(
                                        color: AppColors.onSurface,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'PRJ-$code • $relativeTime',
                                      style: AppTypography.labelMonoSm
                                          .copyWith(
                                        color: AppColors.outline,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),

                              // Status Badge (Reference lines 279, 292)
                              _buildStatusBadge(
                                isCorrecting: isCorrecting,
                                isUnderReview: isUnderReview,
                                isCompleted: isCompleted,
                                statusString: a.status,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Footer Action (Reference line 295-297)
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              border: Border(
                top: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: TextButton(
              key: const Key('insights_view_all_submissions_button'),
              onPressed: () => context.go('/draughtsman/studio'),
              child: Text(
                'VIEW ALL SUBMISSIONS',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. PIPELINE DISTRIBUTION & VELOCITY CARD
  // ---------------------------------------------------------------------------

  Widget _buildPipelineDistributionCard({
    required int total,
    required int pending,
    required int inProgress,
    required int underReview,
    required int corrections,
    required int completed,
    required List<Assignment> assignments,
  }) {
    // Calculate average turnaround from completed assignments with timestamps
    final turnaroundList = <double>[];
    for (final a in assignments) {
      if (a.assignedAt != null && (a.submittedAt != null || a.approvedAt != null)) {
        final end = a.approvedAt ?? a.submittedAt!;
        final days = end.difference(a.assignedAt!).inHours / 24.0;
        if (days >= 0) turnaroundList.add(days);
      }
    }

    final turnaroundStr = turnaroundList.isNotEmpty
        ? '${(turnaroundList.reduce((a, b) => a + b) / turnaroundList.length).toStringAsFixed(1)} days'
        : 'Awaiting closed cycles';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.03),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Text(
                'Pipeline Distribution & Velocity',
                style: AppTypography.headlineLgMobile.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 15,
                    color: AppColors.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Avg Turnaround: $turnaroundStr',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.outline,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Multi-segmented Distribution Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 8,
              child: total == 0
                  ? Container(color: AppColors.surfaceVariant)
                  : Row(
                      children: [
                        if (pending > 0)
                          Expanded(
                            flex: pending,
                            child: Container(color: const Color(0xFF75777E)),
                          ),
                        if (inProgress > 0)
                          Expanded(
                            flex: inProgress,
                            child: Container(color: AppColors.secondary),
                          ),
                        if (underReview > 0)
                          Expanded(
                            flex: underReview,
                            child: Container(color: const Color(0xFF356EE7)),
                          ),
                        if (corrections > 0)
                          Expanded(
                            flex: corrections,
                            child: Container(color: const Color(0xFFBA1A1A)),
                          ),
                        if (completed > 0)
                          Expanded(
                            flex: completed,
                            child: Container(color: const Color(0xFF069669)),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Legend chips with honest counts
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _buildLegendChip(
                label: 'Pending',
                count: pending,
                color: const Color(0xFF75777E),
              ),
              _buildLegendChip(
                label: 'In Progress',
                count: inProgress,
                color: AppColors.secondary,
              ),
              _buildLegendChip(
                label: 'Under Review',
                count: underReview,
                color: const Color(0xFF356EE7),
              ),
              _buildLegendChip(
                label: 'Corrections',
                count: corrections,
                color: const Color(0xFFBA1A1A),
              ),
              _buildLegendChip(
                label: 'Completed',
                count: completed,
                color: const Color(0xFF069669),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendChip({
    required String label,
    required int count,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: $count',
          style: AppTypography.labelMonoSm.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge({
    required bool isCorrecting,
    required bool isUnderReview,
    required bool isCompleted,
    required String statusString,
  }) {
    if (isCorrecting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFFDAD6).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: const Color(0xFFBA1A1A).withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Text(
          'Correcting',
          style: AppTypography.labelMonoSm.copyWith(
            color: const Color(0xFF93000A),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (isUnderReview) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFDAE2FF),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Text(
          'Under Review',
          style: AppTypography.labelMonoSm.copyWith(
            color: const Color(0xFF0040A2),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF85F8C4).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: const Color(0xFF069669).withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Text(
          'Completed',
          style: AppTypography.labelMonoSm.copyWith(
            color: const Color(0xFF005137),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          statusString.replaceAll('_', ' '),
          style: AppTypography.labelMonoSm.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
  }

  String _formatRelativeTime(DateTime? date) {
    if (date == null) return 'recently';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes.clamp(1, 59)}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }
}

// ---------------------------------------------------------------------------
// DASHED LINE PAINTER (Reference lines 226-228)
// ---------------------------------------------------------------------------

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double dashWidth = 5.0;
    const double dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// BENTO METRIC CARD (Reference lines 156-170, 186-201)
// ---------------------------------------------------------------------------

class _BentoMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData badgeIcon;
  final String badgeText;
  final String badgeSubtext;
  final IconData cornerIcon;
  final Color cornerColor;

  const _BentoMetricCard({
    required this.label,
    required this.value,
    required this.badgeIcon,
    required this.badgeText,
    required this.badgeSubtext,
    required this.cornerIcon,
    required this.cornerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.03),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(cornerIcon, size: 20, color: cornerColor),
            ],
          ),
          Text(
            value,
            style: AppTypography.headlineDisplay.copyWith(
              color: AppColors.primary,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF85F8C4).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 12, color: const Color(0xFF069669)),
                    const SizedBox(width: 3),
                    Text(
                      badgeText,
                      style: AppTypography.labelMonoSm.copyWith(
                        color: const Color(0xFF069669),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                badgeSubtext,
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.outline,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BENTO CAPACITY CARD (Reference lines 172-184)
// ---------------------------------------------------------------------------

class _BentoCapacityCard extends StatelessWidget {
  final String label;
  final String value;
  final int capacityPct;
  final String sublabel;

  const _BentoCapacityCard({
    required this.label,
    required this.value,
    required this.capacityPct,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.03),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(
                Icons.architecture_outlined,
                size: 20,
                color: AppColors.outline,
              ),
            ],
          ),
          Text(
            value,
            style: AppTypography.headlineDisplay.copyWith(
              color: AppColors.primary,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (capacityPct / 100).clamp(0.04, 1.0),
                  backgroundColor: AppColors.surfaceVariant,
                  color: AppColors.primary,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sublabel,
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.outline,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '$capacityPct% Capacity',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.outline,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
