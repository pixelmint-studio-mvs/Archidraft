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

/// Drawings Library screen for the Draughtsman portal.
///
/// Shows all assignments along with their associated drawing types and statuses,
/// allowing quick navigation to any workspace. Filtered to show accepted/in-progress
/// and completed drawings.
class DraughtsmanDrawingsScreen extends ConsumerStatefulWidget {
  const DraughtsmanDrawingsScreen({super.key});

  @override
  ConsumerState<DraughtsmanDrawingsScreen> createState() =>
      _DraughtsmanDrawingsScreenState();
}

class _DraughtsmanDrawingsScreenState
    extends ConsumerState<DraughtsmanDrawingsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(draughtsmanAssignmentsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: assignmentsAsync.when(
        loading: () =>
            const AppLoadingIndicator(message: 'Loading drawings...'),
        error: (e, _) => AppErrorWidget(
          message: 'Failed to load drawings.',
          onRetry: () => ref.invalidate(draughtsmanAssignmentsProvider),
        ),
        data: (assignments) {
          // Only show accepted + completed (with drawings)
          final relevant = assignments
              .where((a) =>
                  a.assignmentStatus == AssignmentStatus.accepted ||
                  a.assignmentStatus == AssignmentStatus.completed ||
                  a.projectStatus == 'IN_PROGRESS' ||
                  a.projectStatus == 'UNDER_CLIENT_REVIEW' ||
                  a.projectStatus == 'COMPLETED')
              .toList();

          final filtered = _searchQuery.isEmpty
              ? relevant
              : relevant.where((a) {
                  final q = _searchQuery.toLowerCase();
                  return a.displayProjectName.toLowerCase().contains(q) ||
                      (a.drawingType ?? '').toLowerCase().contains(q);
                }).toList();

          return CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(assignments.length),
              ),

              // Search
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: AppTypography.bodyMd,
                    decoration: InputDecoration(
                      hintText: 'Search drawings...',
                      hintStyle:
                          AppTypography.bodyMd.copyWith(color: AppColors.outline),
                      prefixIcon:
                          const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide:
                            BorderSide(color: AppColors.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide:
                            BorderSide(color: AppColors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: BorderSide(
                            color: AppColors.secondary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md),
                    ),
                  ),
                ),
              ),

              // Section header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DRAWING SETS',
                        style: AppTypography.labelMono.copyWith(
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 1.2),
                      ),
                      Text(
                        '${filtered.length} drawings',
                        style: AppTypography.labelMonoSm
                            .copyWith(color: AppColors.outline),
                      ),
                    ],
                  ),
                ),
              ),

              // Empty state
              if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: AppEmptyState(
                      title: 'No Drawings',
                      subtitle: _searchQuery.isNotEmpty
                          ? 'No drawings matched your search.'
                          : 'Accept an assignment to start drawing.',
                      icon: Icons.layers_outlined,
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _DrawingCard(assignment: filtered[index]),
                    childCount: filtered.length,
                  ),
                ),

              const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxxl)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(int total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
            bottom: BorderSide(color: AppColors.outlineVariant, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Drawings Library',
                  style: AppTypography.headlineLg
                      .copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'All your active and completed drawing sets.',
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.invalidate(draughtsmanAssignmentsProvider),
            tooltip: 'Refresh drawings',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerLow,
              side: BorderSide(color: AppColors.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Drawing Card
// ─────────────────────────────────────────

class _DrawingCard extends StatefulWidget {
  final Assignment assignment;
  const _DrawingCard({required this.assignment});

  @override
  State<_DrawingCard> createState() => _DrawingCardState();
}

class _DrawingCardState extends State<_DrawingCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    final isCompleted = a.projectStatus == 'COMPLETED' ||
        a.assignmentStatus == AssignmentStatus.completed;
    final isUnderReview = a.projectStatus == 'UNDER_CLIENT_REVIEW';

    final Color statusColor;
    final String statusLabel;
    final IconData drawingIcon;

    if (isUnderReview) {
      statusColor = AppColors.secondary;
      statusLabel = 'UNDER REVIEW';
      drawingIcon = Icons.rate_review_outlined;
    } else if (isCompleted) {
      statusColor = AppColors.success;
      statusLabel = 'APPROVED';
      drawingIcon = Icons.task_alt_rounded;
    } else {
      statusColor = AppColors.warning;
      statusLabel = 'DRAFTING';
      drawingIcon = Icons.draw_outlined;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.push(
          '/draughtsman/workspace/${a.id}',
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: _isHovered ? AppColors.secondary : AppColors.outlineVariant,
              width: _isHovered ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Icon(drawingIcon, size: 22, color: statusColor),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            a.displayProjectName,
                            style: AppTypography.buttonText
                                .copyWith(color: AppColors.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusDefault),
                            border: Border.all(
                                color: statusColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            statusLabel,
                            style: AppTypography.labelMonoSm.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (a.drawingType != null && a.drawingType!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        a.drawingType!,
                        style: AppTypography.bodySm
                            .copyWith(color: AppColors.secondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        if (a.createdAt != null) ...[
                          Icon(Icons.calendar_today_outlined,
                              size: 11, color: AppColors.outline),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d, yyyy').format(a.createdAt!),
                            style: AppTypography.labelMonoSm
                                .copyWith(color: AppColors.outline),
                          ),
                        ],
                        if (a.correctionRound != null &&
                            a.correctionRound! > 0) ...[
                          const SizedBox(width: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Rev ${a.correctionRound}',
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
              Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: _isHovered ? AppColors.secondary : AppColors.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
