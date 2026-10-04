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

class DraughtsmanStudioScreen extends ConsumerStatefulWidget {
  const DraughtsmanStudioScreen({super.key});

  @override
  ConsumerState<DraughtsmanStudioScreen> createState() => _DraughtsmanStudioScreenState();
}

class _DraughtsmanStudioScreenState extends ConsumerState<DraughtsmanStudioScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  // null = all, otherwise filter by AssignmentStatus
  AssignmentStatus? _filterStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(draughtsmanAssignmentsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: assignmentsAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Loading assignments...'),
        error: (error, _) => AppErrorWidget(
          message: 'Failed to load assignments.\n$error',
          onRetry: () => ref.invalidate(draughtsmanAssignmentsProvider),
        ),
        data: (assignments) => _buildContent(context, assignments),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Assignment> assignments) {
    // Compute metric counts
    final pending = assignments.where((a) => a.assignmentStatus == AssignmentStatus.pending).length;
    final inProgress = assignments.where((a) => a.assignmentStatus == AssignmentStatus.accepted).length;
    final underReview = assignments.where((a) => a.projectStatus == 'UNDER_CLIENT_REVIEW').length;
    final completed = assignments.where((a) =>
        a.assignmentStatus == AssignmentStatus.completed ||
        a.projectStatus == 'COMPLETED').length;

    // Apply search + filter
    final filtered = assignments.where((a) {
      final matchesFilter = _filterStatus == null || a.assignmentStatus == _filterStatus;
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          a.displayProjectName.toLowerCase().contains(q) ||
          (a.drawingType ?? '').toLowerCase().contains(q) ||
          (a.projectAddress ?? '').toLowerCase().contains(q);
      return matchesFilter && matchesSearch;
    }).toList();

    return CustomScrollView(
      slivers: [
        // ── Page Header ──
        SliverToBoxAdapter(
          child: _buildPageHeader(context),
        ),

        // ── Summary Metric Cards ──
        SliverToBoxAdapter(
          child: _buildMetricCards(
            pending: pending,
            inProgress: inProgress,
            underReview: underReview,
            completed: completed,
          ),
        ),

        // ── Search + Filter Bar ──
        SliverToBoxAdapter(
          child: _buildSearchAndFilterBar(assignments),
        ),

        // ── Section Header ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _filterStatus == null ? 'ALL ASSIGNMENTS' : '${_filterStatus!.displayName.toUpperCase()} ASSIGNMENTS',
                  style: AppTypography.labelMono.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '${filtered.length} results',
                  style: AppTypography.labelMonoSm.copyWith(color: AppColors.outline),
                ),
              ],
            ),
          ),
        ),

        // ── Assignment Cards ──
        if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: AppEmptyState(
                title: _searchQuery.isNotEmpty || _filterStatus != null
                    ? 'No Matching Assignments'
                    : 'No Assignments',
                subtitle: _searchQuery.isNotEmpty || _filterStatus != null
                    ? 'Try adjusting your search or filter.'
                    : 'You have no active assignments right now.',
                icon: Icons.assignment_outlined,
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _AssignmentCard(
                assignment: filtered[index],
                index: index,
              ),
              childCount: filtered.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
      ],
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('MMMM d, yyyy').format(now);

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Studio Dashboard',
                  style: AppTypography.headlineLg.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.outline),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: AppTypography.labelMono.copyWith(color: AppColors.outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(draughtsmanAssignmentsProvider),
            tooltip: 'Refresh assignments',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerLow,
              side: BorderSide(color: AppColors.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards({
    required int pending,
    required int inProgress,
    required int underReview,
    required int completed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          if (isNarrow) {
            return Column(
              children: [
                Row(children: [
                  Expanded(child: _MetricCard(label: 'NEW', sublabel: 'Pending Review', count: pending, color: AppColors.warning, icon: Icons.mark_email_unread_outlined)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _MetricCard(label: 'DRAFTING', sublabel: 'In Progress', count: inProgress, color: AppColors.secondary, icon: Icons.draw_outlined)),
                ]),
                const SizedBox(height: AppSpacing.md),
                Row(children: [
                  Expanded(child: _MetricCard(label: 'REVIEW', sublabel: 'Client QA', count: underReview, color: AppColors.onPrimaryContainer, icon: Icons.rate_review_outlined)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _MetricCard(label: 'DONE', sublabel: 'Completed', count: completed, color: AppColors.success, icon: Icons.check_circle_outline_rounded)),
                ]),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: _MetricCard(label: 'NEW', sublabel: 'Pending Review', count: pending, color: AppColors.warning, icon: Icons.mark_email_unread_outlined)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _MetricCard(label: 'DRAFTING', sublabel: 'In Progress', count: inProgress, color: AppColors.secondary, icon: Icons.draw_outlined)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _MetricCard(label: 'REVIEW', sublabel: 'Client QA', count: underReview, color: AppColors.onPrimaryContainer, icon: Icons.rate_review_outlined)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _MetricCard(label: 'DONE', sublabel: 'Completed', count: completed, color: AppColors.success, icon: Icons.check_circle_outline_rounded)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilterBar(List<Assignment> assignments) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: AppTypography.bodyMd,
            decoration: InputDecoration(
              hintText: 'Search by project name, drawing type, address...',
              hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.outline),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(color: AppColors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(color: AppColors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(color: AppColors.secondary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _filterStatus == null,
                  count: assignments.length,
                  onTap: () => setState(() => _filterStatus = null),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: 'Pending',
                  isSelected: _filterStatus == AssignmentStatus.pending,
                  count: assignments.where((a) => a.assignmentStatus == AssignmentStatus.pending).length,
                  color: AppColors.warning,
                  onTap: () => setState(() => _filterStatus =
                      _filterStatus == AssignmentStatus.pending ? null : AssignmentStatus.pending),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: 'Accepted',
                  isSelected: _filterStatus == AssignmentStatus.accepted,
                  count: assignments.where((a) => a.assignmentStatus == AssignmentStatus.accepted).length,
                  color: AppColors.secondary,
                  onTap: () => setState(() => _filterStatus =
                      _filterStatus == AssignmentStatus.accepted ? null : AssignmentStatus.accepted),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: 'Completed',
                  isSelected: _filterStatus == AssignmentStatus.completed,
                  count: assignments.where((a) => a.assignmentStatus == AssignmentStatus.completed).length,
                  color: AppColors.success,
                  onTap: () => setState(() => _filterStatus =
                      _filterStatus == AssignmentStatus.completed ? null : AssignmentStatus.completed),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Metric Summary Card
// ─────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final int count;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.sublabel,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '$count',
            style: AppTypography.headlineLg.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            sublabel,
            style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelMonoSm.copyWith(
              color: color,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Filter Chip
// ─────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int count;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.count,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withValues(alpha: 0.1) : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.labelMonoSm.copyWith(
                color: isSelected ? chipColor : AppColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? chipColor : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                '$count',
                style: AppTypography.labelMonoSm.copyWith(
                  color: isSelected ? Colors.white : AppColors.outline,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Assignment Card
// ─────────────────────────────────────────

class _AssignmentCard extends StatefulWidget {
  final Assignment assignment;
  final int index;

  const _AssignmentCard({required this.assignment, required this.index});

  @override
  State<_AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<_AssignmentCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;
    final status = assignment.assignmentStatus ?? AssignmentStatus.pending;
    final isPending = status == AssignmentStatus.pending;
    final isAccepted = status == AssignmentStatus.accepted;
    final isCompleted = status == AssignmentStatus.completed ||
        assignment.projectStatus == 'COMPLETED';

    final Color statusColor;
    switch (status) {
      case AssignmentStatus.pending:
        statusColor = AppColors.warning;
        break;
      case AssignmentStatus.accepted:
        statusColor = AppColors.secondary;
        break;
      case AssignmentStatus.completed:
        statusColor = AppColors.success;
        break;
      case AssignmentStatus.rejected:
      case AssignmentStatus.replaced:
        statusColor = AppColors.error;
        break;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.push(
          '/draughtsman/assignments/${assignment.id}',
          extra: assignment,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: _isHovered ? AppColors.secondary : AppColors.outlineVariant,
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: _isHovered
                ? [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drawing Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    isPending
                        ? Icons.assignment_late_outlined
                        : isAccepted
                            ? Icons.draw_outlined
                            : isCompleted
                                ? Icons.task_alt_rounded
                                : Icons.assignment_outlined,
                    size: 22,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              assignment.displayProjectName,
                              style: AppTypography.buttonText.copyWith(
                                color: AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _StatusBadge(status: status, color: statusColor),
                        ],
                      ),

                      if (assignment.drawingType != null && assignment.drawingType!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          assignment.drawingType!,
                          style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      if (assignment.projectAddress != null && assignment.projectAddress!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 12, color: AppColors.outline),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                assignment.projectAddress!,
                                style: AppTypography.labelMonoSm.copyWith(color: AppColors.outline),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: AppSpacing.sm),

                      Row(
                        children: [
                          if (assignment.createdAt != null)
                            Text(
                              'Assigned ${DateFormat('MMM d, yyyy').format(assignment.createdAt!)}',
                              style: AppTypography.labelMonoSm.copyWith(color: AppColors.outline),
                            ),
                          if (assignment.correctionRound != null && assignment.correctionRound! > 0) ...[
                            const SizedBox(width: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.errorContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Rev ${assignment.correctionRound}',
                                style: AppTypography.labelMonoSm.copyWith(
                                  color: AppColors.onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: _isHovered ? AppColors.secondary : AppColors.outline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AssignmentStatus status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: AppTypography.labelMonoSm.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
