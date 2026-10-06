import os

target = os.path.join(
    os.path.dirname(__file__), '..', 'lib', 'src', 'features', 'projects',
    'presentation', 'draughtsman', 'draughtsman_studio_screen.dart'
)

code = r"""import 'package:flutter/material.dart';
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

// ---------------------------------------------------------------------------
// FILTER MODE
// ---------------------------------------------------------------------------

enum _StudioFilter { all, pending, accepted, underReview, corrections, completed }

extension _StudioFilterX on _StudioFilter {
  String get label {
    switch (this) {
      case _StudioFilter.all:         return 'All';
      case _StudioFilter.pending:     return 'Pending';
      case _StudioFilter.accepted:    return 'In Progress';
      case _StudioFilter.underReview: return 'Under Review';
      case _StudioFilter.corrections: return 'Corrections';
      case _StudioFilter.completed:   return 'Completed';
    }
  }

  Color filterColor() {
    switch (this) {
      case _StudioFilter.all:         return AppColors.onSurface;
      case _StudioFilter.pending:     return AppColors.warning;
      case _StudioFilter.accepted:    return AppColors.secondary;
      case _StudioFilter.underReview: return AppColors.onPrimaryContainer;
      case _StudioFilter.corrections: return AppColors.error;
      case _StudioFilter.completed:   return AppColors.success;
    }
  }

  bool matches(Assignment a) {
    switch (this) {
      case _StudioFilter.all:    return true;
      case _StudioFilter.pending:
        return a.assignmentStatus == AssignmentStatus.pending;
      case _StudioFilter.accepted:
        return a.assignmentStatus == AssignmentStatus.accepted &&
            a.projectStatus != 'UNDER_CLIENT_REVIEW';
      case _StudioFilter.underReview:
        return a.projectStatus == 'UNDER_CLIENT_REVIEW';
      case _StudioFilter.corrections:
        return a.assignmentStatus == AssignmentStatus.accepted &&
            (a.correctionRound ?? 0) > 0 &&
            a.projectStatus != 'UNDER_CLIENT_REVIEW';
      case _StudioFilter.completed:
        return a.assignmentStatus == AssignmentStatus.completed ||
            a.projectStatus == 'COMPLETED';
    }
  }
}

// ---------------------------------------------------------------------------
// STUDIO SCREEN
// ---------------------------------------------------------------------------

class DraughtsmanStudioScreen extends ConsumerStatefulWidget {
  const DraughtsmanStudioScreen({super.key});

  @override
  ConsumerState<DraughtsmanStudioScreen> createState() =>
      _DraughtsmanStudioScreenState();
}

class _DraughtsmanStudioScreenState
    extends ConsumerState<DraughtsmanStudioScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _StudioFilter _filter = _StudioFilter.all;

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
        loading: () =>
            const AppLoadingIndicator(message: 'Loading assignments...'),
        error: (error, _) => AppErrorWidget(
          message: 'Failed to load assignments.\n$error',
          onRetry: () => ref.invalidate(draughtsmanAssignmentsProvider),
        ),
        data: (assignments) => _buildContent(context, assignments),
      ),
    );
  }

  // Helpers ------------------------------------------------------------------

  int _count(_StudioFilter f, List<Assignment> all) {
    switch (f) {
      case _StudioFilter.all: return all.length;
      case _StudioFilter.pending:
        return all.where((a) => a.assignmentStatus == AssignmentStatus.pending).length;
      case _StudioFilter.accepted:
        return all.where((a) =>
            a.assignmentStatus == AssignmentStatus.accepted &&
            a.projectStatus != 'UNDER_CLIENT_REVIEW').length;
      case _StudioFilter.underReview:
        return all.where((a) => a.projectStatus == 'UNDER_CLIENT_REVIEW').length;
      case _StudioFilter.corrections:
        return all.where((a) =>
            a.assignmentStatus == AssignmentStatus.accepted &&
            (a.correctionRound ?? 0) > 0 &&
            a.projectStatus != 'UNDER_CLIENT_REVIEW').length;
      case _StudioFilter.completed:
        return all.where((a) =>
            a.assignmentStatus == AssignmentStatus.completed ||
            a.projectStatus == 'COMPLETED').length;
    }
  }

  // Build --------------------------------------------------------------------

  Widget _buildContent(BuildContext context, List<Assignment> assignments) {
    final filtered = assignments.where((a) {
      if (!_filter.matches(a)) return false;
      final q = _searchQuery.toLowerCase();
      return q.isEmpty ||
          a.displayProjectName.toLowerCase().contains(q) ||
          (a.drawingType ?? '').toLowerCase().contains(q) ||
          (a.projectAddress ?? '').toLowerCase().contains(q);
    }).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildPageHeader()),
        SliverToBoxAdapter(child: _buildMetricCards(assignments)),
        SliverToBoxAdapter(child: _buildFilters(assignments)),
        SliverToBoxAdapter(child: _buildSectionHeader(filtered.length)),
        if (filtered.isEmpty)
          SliverToBoxAdapter(child: _buildEmpty())
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _AssignmentCard(assignment: filtered[i]),
              childCount: filtered.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
      ],
    );
  }

  Widget _buildPageHeader() {
    final dateStr = DateFormat('MMMM d, yyyy').format(DateTime.now());
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Studio Dashboard',
                    style: AppTypography.headlineLg
                        .copyWith(color: AppColors.onSurface)),
                const SizedBox(height: AppSpacing.xs),
                Row(children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppColors.outline),
                  const SizedBox(width: 6),
                  Text(dateStr,
                      style: AppTypography.labelMono
                          .copyWith(color: AppColors.outline)),
                ]),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(draughtsmanAssignmentsProvider),
            tooltip: 'Refresh',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerLow,
              side: BorderSide(color: AppColors.outlineVariant),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards(List<Assignment> all) {
    final items = [
      (
        'NEW',
        'Pending',
        _count(_StudioFilter.pending, all),
        AppColors.warning,
        Icons.mark_email_unread_outlined,
        _StudioFilter.pending
      ),
      (
        'DRAFTING',
        'In Progress',
        _count(_StudioFilter.accepted, all),
        AppColors.secondary,
        Icons.draw_outlined,
        _StudioFilter.accepted
      ),
      (
        'REVIEW',
        'Under Review',
        _count(_StudioFilter.underReview, all),
        AppColors.onPrimaryContainer,
        Icons.rate_review_outlined,
        _StudioFilter.underReview
      ),
      (
        'REVISE',
        'Corrections',
        _count(_StudioFilter.corrections, all),
        AppColors.error,
        Icons.edit_note_rounded,
        _StudioFilter.corrections
      ),
      (
        'DONE',
        'Completed',
        _count(_StudioFilter.completed, all),
        AppColors.success,
        Icons.check_circle_outline_rounded,
        _StudioFilter.completed
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: LayoutBuilder(builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;
        if (isNarrow) {
          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: items
                .map((it) => SizedBox(
                      width: (constraints.maxWidth - AppSpacing.md) / 2,
                      child: _MetricCard(
                          label: it.$1,
                          sublabel: it.$2,
                          count: it.$3,
                          color: it.$4,
                          icon: it.$5,
                          onTap: () => setState(() => _filter = it.$6)),
                    ))
                .toList(),
          );
        }
        return Row(
          children: items
              .expand((it) => [
                    Expanded(
                      child: _MetricCard(
                          label: it.$1,
                          sublabel: it.$2,
                          count: it.$3,
                          color: it.$4,
                          icon: it.$5,
                          onTap: () => setState(() => _filter = it.$6)),
                    ),
                    if (it != items.last) const SizedBox(width: AppSpacing.md),
                  ])
              .toList(),
        );
      }),
    );
  }

  Widget _buildFilters(List<Assignment> all) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: AppTypography.bodyMd,
            decoration: InputDecoration(
              hintText: 'Search by project name, drawing type, address...',
              hintStyle:
                  AppTypography.bodyMd.copyWith(color: AppColors.outline),
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
                  borderSide: BorderSide(color: AppColors.outlineVariant)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide(color: AppColors.outlineVariant)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide:
                      BorderSide(color: AppColors.secondary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _StudioFilter.values.map((f) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: _FilterChip(
                    label: f.label,
                    isSelected: _filter == f,
                    count: _count(f, all),
                    color: f == _StudioFilter.all ? null : f.filterColor(),
                    onTap: () => setState(() => _filter = f),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _filter == _StudioFilter.all
                ? 'ALL ASSIGNMENTS'
                : '${_filter.label.toUpperCase()} ASSIGNMENTS',
            style: AppTypography.labelMono
                .copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 1.2),
          ),
          Text('$count results',
              style:
                  AppTypography.labelMonoSm.copyWith(color: AppColors.outline)),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: AppEmptyState(
        title: _searchQuery.isNotEmpty || _filter != _StudioFilter.all
            ? 'No Matching Assignments'
            : 'No Assignments',
        subtitle: _searchQuery.isNotEmpty || _filter != _StudioFilter.all
            ? 'Try adjusting your search or filter.'
            : 'You have no active assignments right now.',
        icon: Icons.assignment_outlined,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// METRIC CARD
// ---------------------------------------------------------------------------

class _MetricCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.label,
    required this.sublabel,
    required this.count,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
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
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: color)),
            ]),
            const SizedBox(height: AppSpacing.md),
            Text('$count',
                style: AppTypography.headlineLg.copyWith(
                    color: AppColors.onSurface, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            Text(sublabel,
                style: AppTypography.bodySm
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.xs),
            Text(label,
                style: AppTypography.labelMonoSm
                    .copyWith(color: color, letterSpacing: 1.0)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FILTER CHIP
// ---------------------------------------------------------------------------

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
    final c = color ?? AppColors.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
        decoration: BoxDecoration(
          color: isSelected
              ? c.withValues(alpha: 0.1)
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
              color: isSelected ? c : AppColors.outlineVariant,
              width: isSelected ? 1.5 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: AppTypography.labelMonoSm.copyWith(
                color: isSelected ? c : AppColors.onSurfaceVariant,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              )),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: isSelected ? c : AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text('$count',
                style: AppTypography.labelMonoSm.copyWith(
                    color: isSelected ? Colors.white : AppColors.outline,
                    fontSize: 9)),
          ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ASSIGNMENT CARD
// ---------------------------------------------------------------------------

class _AssignmentCard extends StatefulWidget {
  final Assignment assignment;
  const _AssignmentCard({required this.assignment});

  @override
  State<_AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<_AssignmentCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    final status = a.assignmentStatus ?? AssignmentStatus.pending;
    final isPending = status == AssignmentStatus.pending;
    final projectStatus = a.projectStatus ?? '';
    final isUnderReview = projectStatus == 'UNDER_CLIENT_REVIEW';
    final isCompleted =
        status == AssignmentStatus.completed || projectStatus == 'COMPLETED';
    final isRejected = status == AssignmentStatus.rejected ||
        status == AssignmentStatus.replaced;
    final hasCorrection = (a.correctionRound ?? 0) > 0;
    final isInProgress = status == AssignmentStatus.accepted && !isUnderReview;

    final String statusLabel;
    final Color accent;
    if (isCompleted) {
      statusLabel = 'COMPLETED';
      accent = AppColors.success;
    } else if (isUnderReview) {
      statusLabel = 'UNDER REVIEW';
      accent = AppColors.onPrimaryContainer;
    } else if (isPending) {
      statusLabel = 'PENDING ACCEPTANCE';
      accent = AppColors.warning;
    } else if (isRejected) {
      statusLabel = status.displayName.toUpperCase();
      accent = AppColors.error;
    } else if (isInProgress && hasCorrection) {
      statusLabel = 'REVISION ${a.correctionRound}';
      accent = AppColors.error;
    } else if (isInProgress) {
      statusLabel = 'IN PROGRESS';
      accent = AppColors.secondary;
    } else {
      statusLabel = status.displayName.toUpperCase();
      accent = AppColors.outline;
    }

    final updatedAt = a.updatedAt ?? a.createdAt;
    final updatedStr = updatedAt != null
        ? 'Updated ${_timeAgo(updatedAt)}'
        : (a.createdAt != null
            ? 'Assigned ${DateFormat('MMM d, yyyy').format(a.createdAt!)}'
            : '');

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.push('/draughtsman/assignments/${a.id}', extra: a),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: _isHovered
                  ? accent.withValues(alpha: 0.5)
                  : AppColors.outlineVariant,
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                        color: accent.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent stripe
                  Container(width: 4, color: accent),

                  // Card body
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(a.displayProjectName,
                                    style: AppTypography.buttonText
                                        .copyWith(color: AppColors.onSurface),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _StatusBadge(label: statusLabel, color: accent),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.xs),

                          // Drawing type + REV badge
                          if (a.drawingType != null &&
                              a.drawingType!.isNotEmpty)
                            Wrap(spacing: AppSpacing.sm, runSpacing: 4, children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm),
                                  border: Border.all(
                                      color: AppColors.outlineVariant),
                                ),
                                child: Text(a.drawingType!.toUpperCase(),
                                    style: AppTypography.labelMonoSm.copyWith(
                                        color: AppColors.secondary,
                                        letterSpacing: 0.6)),
                              ),
                              if (hasCorrection)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorContainer,
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm),
                                  ),
                                  child: Text('REV ${a.correctionRound}',
                                      style: AppTypography.labelMonoSm.copyWith(
                                          color: AppColors.onErrorContainer,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.6)),
                                ),
                            ]),

                          const SizedBox(height: AppSpacing.xs),

                          // Address
                          if (a.projectAddress != null &&
                              a.projectAddress!.isNotEmpty)
                            Row(children: [
                              Icon(Icons.location_on_outlined,
                                  size: 12, color: AppColors.outline),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(a.projectAddress!,
                                    style: AppTypography.labelMonoSm
                                        .copyWith(color: AppColors.outline),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ]),

                          const SizedBox(height: AppSpacing.md),

                          // Timestamp + action
                          Row(children: [
                            Expanded(
                                child: Text(updatedStr,
                                    style: AppTypography.labelMonoSm
                                        .copyWith(color: AppColors.outline))),
                            if (isPending)
                              _QuickAction(
                                label: 'Review',
                                icon: Icons.arrow_forward_rounded,
                                color: AppColors.warning,
                                onTap: () => context.push(
                                    '/draughtsman/assignments/${a.id}',
                                    extra: a),
                              )
                            else if (!isCompleted && !isRejected)
                              _QuickAction(
                                label: isUnderReview ? 'View' : 'Open Workspace',
                                icon: isUnderReview
                                    ? Icons.visibility_outlined
                                    : Icons.open_in_new_rounded,
                                color: accent,
                                onTap: () {
                                  if (isUnderReview) {
                                    context.push(
                                        '/draughtsman/assignments/${a.id}',
                                        extra: a);
                                  } else {
                                    context.push(
                                        '/draughtsman/workspace/${a.id}');
                                  }
                                },
                              ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(dt);
  }
}

// ---------------------------------------------------------------------------
// STATUS BADGE
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: AppTypography.labelMonoSm.copyWith(
              color: color, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    );
  }
}

// ---------------------------------------------------------------------------
// QUICK ACTION BUTTON
// ---------------------------------------------------------------------------

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs + 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: AppTypography.labelMonoSm
                  .copyWith(color: color, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Icon(icon, size: 12, color: color),
        ]),
      ),
    );
  }
}
"""

with open(target, 'w', encoding='utf-8') as f:
    f.write(code)

print(f"Written {len(code)} chars to {os.path.abspath(target)}")
