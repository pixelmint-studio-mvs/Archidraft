import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../domain/assignment.dart';
import '../../domain/assignment_status.dart';
import '../../providers/assignment_providers.dart';
import '../../providers/project_providers.dart';

// ---------------------------------------------------------------------------
// FILTER ENUM
// ---------------------------------------------------------------------------

enum _StudioFilter { all, pending, inProgress, corrections, completed }

extension _StudioFilterX on _StudioFilter {
  bool matches(Assignment a) {
    switch (this) {
      case _StudioFilter.all:
        return a.assignmentStatus != AssignmentStatus.completed &&
            a.projectStatus != 'COMPLETED';
      case _StudioFilter.pending:
        return a.assignmentStatus == AssignmentStatus.pending;
      case _StudioFilter.inProgress:
        return a.assignmentStatus == AssignmentStatus.accepted &&
            a.projectStatus == 'IN_PROGRESS' &&
            (a.correctionRound == null || a.correctionRound == 0);
      case _StudioFilter.corrections:
        return a.assignmentStatus == AssignmentStatus.accepted &&
            (a.correctionRound ?? 0) > 0;
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
            const AppLoadingIndicator(message: 'Loading workspace...'),
        error: (error, _) => AppErrorWidget(
          message: 'Failed to load assignments.\n$error',
          onRetry: () => ref.invalidate(draughtsmanAssignmentsProvider),
        ),
        data: (assignments) => _buildContent(context, assignments),
      ),
    );
  }

  int _count(_StudioFilter f, List<Assignment> all) {
    return all
        .where((a) => a.assignmentStatus != AssignmentStatus.replaced)
        .where((a) => f.matches(a))
        .length;
  }

  Widget _buildContent(BuildContext context, List<Assignment> assignments) {
    final active = assignments
        .where((a) => a.assignmentStatus != AssignmentStatus.replaced)
        .toList();
    final filtered = active.where((a) {
      if (!_filter.matches(a)) return false;
      final q = _searchQuery.toLowerCase();
      return q.isEmpty ||
          a.displayProjectName.toLowerCase().contains(q) ||
          (a.drawingType ?? '').toLowerCase().contains(q) ||
          (a.projectAddress ?? '').toLowerCase().contains(q) ||
          (a.id).toLowerCase().contains(q);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 768;
        final int columns = screenWidth >= 1200 ? 3 : (screenWidth >= 768 ? 2 : 1);
        final horizontalPadding = isMobile
            ? AppSpacing.marginMobile
            : AppSpacing.marginDesktop;

        return CustomScrollView(
          slivers: [
            // Toolbar: Search and Filters
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.xl,
                  horizontalPadding,
                  AppSpacing.lg,
                ),
                child: _buildToolbar(active, isMobile),
              ),
            ),

            // Bento Grid or Empty State
            if (filtered.isEmpty)
              SliverToBoxAdapter(child: _buildEmpty(horizontalPadding))
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  AppSpacing.xxxl,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: AppSpacing.gridGutter,
                    crossAxisSpacing: AppSpacing.gridGutter,
                    mainAxisExtent: 520,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _ProjectBentoCard(assignment: filtered[i]),
                    childCount: filtered.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(List<Assignment> active, bool isMobile) {
    final searchWidget = SizedBox(
      width: isMobile ? double.infinity : 384,
      height: 48,
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: AppTypography.labelMono.copyWith(
          color: AppColors.onSurface,
          fontSize: 12,
        ),
        decoration: InputDecoration(
          hintText: 'Search projects by ID, Client, or Location...',
          hintStyle: AppTypography.labelMono.copyWith(
            color: AppColors.outlineVariant,
            fontSize: 12,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.outline,
          ),
          filled: true,
          fillColor: AppColors.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
            borderSide: const BorderSide(
              color: AppColors.outlineVariant,
              width: 0.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
            borderSide: const BorderSide(
              color: AppColors.outlineVariant,
              width: 0.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
            borderSide: const BorderSide(
              color: AppColors.secondary,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );

    final filtersWidget = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _buildFilterButton(
          filter: _StudioFilter.all,
          label: 'All Active',
        ),
        _buildFilterButton(
          filter: _StudioFilter.pending,
          label: 'New',
          count: _count(_StudioFilter.pending, active),
        ),
        _buildFilterButton(
          filter: _StudioFilter.inProgress,
          label: 'In Progress',
          count: _count(_StudioFilter.inProgress, active),
        ),
        _buildFilterButton(
          filter: _StudioFilter.corrections,
          label: 'Corrections',
          count: _count(_StudioFilter.corrections, active),
          isErrorPill: true,
        ),
        _buildFilterButton(
          filter: _StudioFilter.completed,
          label: 'Completed',
          count: _count(_StudioFilter.completed, active),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchWidget,
          const SizedBox(height: 12),
          filtersWidget,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        searchWidget,
        filtersWidget,
      ],
    );
  }

  Widget _buildFilterButton({
    required _StudioFilter filter,
    required String label,
    int? count,
    bool isErrorPill = false,
  }) {
    final isSelected = _filter == filter;

    return InkWell(
      onTap: () => setState(() => _filter = filter),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.70),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.60),
            width: 0.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0D1C32).withValues(alpha: 0.08),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.labelMono.copyWith(
                color: isSelected ? Colors.white : AppColors.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (isErrorPill
                          ? AppColors.errorContainer
                          : AppColors.surfaceContainerHigh),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$count',
                  style: AppTypography.labelMonoSm.copyWith(
                    color: isSelected
                        ? Colors.white
                        : (isErrorPill
                            ? AppColors.error
                            : AppColors.onSurfaceVariant),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppSpacing.xxxl,
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.outlineVariant, width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.folder_open_outlined,
                size: 48,
                color: AppColors.outline,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No Projects in this View',
                style: AppTypography.headlineLgMobile.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No projects matching "$_searchQuery".'
                    : 'Projects matching the current filter will appear here.',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PROJECT BENTO CARD (Matching draughtsman_workspace/code.html)
// ---------------------------------------------------------------------------

class _ProjectBentoCard extends ConsumerStatefulWidget {
  final Assignment assignment;

  const _ProjectBentoCard({required this.assignment});

  @override
  ConsumerState<_ProjectBentoCard> createState() => _ProjectBentoCardState();
}

class _ProjectBentoCardState extends ConsumerState<_ProjectBentoCard> {
  bool _isHovered = false;
  bool _versionHistoryExpanded = false;

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return 'Today, $hour:$minute';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${months[dt.month - 1]} ${dt.day}, $hour:$minute';
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    final isPending = a.assignmentStatus == AssignmentStatus.pending;
    final isCompleted = a.assignmentStatus == AssignmentStatus.completed ||
        a.projectStatus == 'COMPLETED';
    final hasCorrection = (a.correctionRound ?? 0) > 0;
    final isUnderReview = a.projectStatus == 'UNDER_CLIENT_REVIEW';

    // Status pill tokens matching code.html
    String statusLabel;
    Color statusColor;
    Color statusBg;
    Color statusBorder;
    IconData statusIcon;

    if (hasCorrection) {
      statusLabel = 'Correction';
      statusColor = AppColors.error;
      statusBg = AppColors.errorContainer.withValues(alpha: 0.35);
      statusBorder = AppColors.error.withValues(alpha: 0.20);
      statusIcon = Icons.error_outline_rounded;
    } else if (isPending) {
      statusLabel = 'New';
      statusColor = AppColors.onTertiaryContainer;
      statusBg = AppColors.tertiaryFixedDim.withValues(alpha: 0.25);
      statusBorder = AppColors.onTertiaryContainer.withValues(alpha: 0.20);
      statusIcon = Icons.fiber_new_rounded;
    } else if (isUnderReview) {
      statusLabel = 'Review';
      statusColor = const Color(0xFF39475F);
      statusBg = AppColors.surfaceContainerHigh;
      statusBorder = AppColors.outlineVariant.withValues(alpha: 0.40);
      statusIcon = Icons.rate_review_outlined;
    } else if (isCompleted) {
      statusLabel = 'Completed';
      statusColor = AppColors.onTertiaryContainer;
      statusBg = AppColors.tertiaryFixedDim.withValues(alpha: 0.25);
      statusBorder = AppColors.onTertiaryContainer.withValues(alpha: 0.20);
      statusIcon = Icons.check_circle_outline_rounded;
    } else {
      statusLabel = 'In Progress';
      statusColor = AppColors.secondary;
      statusBg = AppColors.secondaryFixed.withValues(alpha: 0.15);
      statusBorder = AppColors.secondary.withValues(alpha: 0.20);
      statusIcon = Icons.sync_rounded;
    }

    final prjCode = a.id.length > 12
        ? 'PRJ-${a.id.substring(0, 8).toUpperCase()}'
        : 'PRJ-${a.id.toUpperCase()}';

    // Client/Location label
    final clientSubtitle = a.projectAddress?.isNotEmpty ?? false
        ? 'Location: ${a.projectAddress}'
        : (a.drawingType != null
            ? 'Drawing: ${a.drawingType}'
            : 'Client: Ministry of Culture');

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? AppColors.secondary.withValues(alpha: 0.40)
                : AppColors.outlineVariant.withValues(alpha: 0.50),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D1C32)
                  .withValues(alpha: _isHovered ? 0.08 : 0.03),
              offset: Offset(0, _isHovered ? 8 : 4),
              blurRadius: _isHovered ? 28 : 24,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Structural corner hint matching code.html
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: hasCorrection
                      ? AppColors.errorContainer.withValues(alpha: 0.12)
                      : (isPending
                          ? AppColors.tertiaryFixedDim.withValues(alpha: 0.12)
                          : AppColors.secondaryFixed.withValues(alpha: 0.12)),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(100),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Header: PRJ Code + Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          prjCode,
                          style: AppTypography.labelMono.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 11,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: statusBorder,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 13, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: AppTypography.labelMono.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Project Title
                  InkWell(
                    onTap: () => context.push('/draughtsman/assignments/${a.id}', extra: a),
                    child: Text(
                      a.displayProjectName,
                      style: AppTypography.headlineLgMobile.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 19,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Client / Location info
                  Text(
                    clientSubtitle,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Drawing Preview Viewport Container (dynamic height: 116px when expanded, 148px when collapsed)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _versionHistoryExpanded ? 116 : 148,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.45),
                        width: 0.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          if (isPending)
                            Center(
                              child: Icon(
                                Icons.domain_add_outlined,
                                size: 48,
                                color: AppColors.outlineVariant
                                    .withValues(alpha: 0.45),
                              ),
                            )
                          else
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _BlueprintPreviewPainter(),
                              ),
                            ),

                          // Redlining hint overlay if correction
                          if (hasCorrection)
                            Positioned.fill(
                              child: Container(
                                color: AppColors.error.withValues(alpha: 0.05),
                              ),
                            ),

                          // Bottom Drawing Tags
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Wrap(
                              spacing: 6,
                              children: [
                                if (a.drawingType != null &&
                                    a.drawingType!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.90),
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(
                                        color: AppColors.outlineVariant
                                            .withValues(alpha: 0.50),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      a.drawingType!.toUpperCase(),
                                      style: AppTypography.labelMonoSm.copyWith(
                                        color: AppColors.secondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                if (hasCorrection)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorContainer,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      'REV ${a.correctionRound}',
                                      style: AppTypography.labelMonoSm.copyWith(
                                        color: AppColors.onErrorContainer,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Hairline Divider
                  Divider(
                    color: AppColors.outlineVariant.withValues(alpha: 0.35),
                    height: 1,
                    thickness: 0.5,
                  ),
                  const SizedBox(height: 12),

                  // Primary Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: hasCorrection
                        ? OutlinedButton(
                            onPressed: () {
                              context.push('/draughtsman/workspace/${a.id}');
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.error,
                                width: 1.0,
                              ),
                              foregroundColor: AppColors.error,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.rate_review_outlined,
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Review Correction',
                                  style: AppTypography.buttonText.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              if (isPending) {
                                context.push(
                                  '/draughtsman/assignments/${a.id}',
                                  extra: a,
                                );
                              } else {
                                context.push('/draughtsman/workspace/${a.id}');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isPending
                                      ? Icons.play_arrow_rounded
                                      : (isCompleted
                                          ? Icons.visibility_outlined
                                          : Icons.upload_rounded),
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isPending
                                      ? 'Start Drafting'
                                      : (isCompleted
                                          ? 'View Project'
                                          : 'Upload Draft'),
                                  style: AppTypography.buttonText.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),

                  const SizedBox(height: 8),

                  // Version History Collapsible Section
                  _VersionHistorySection(
                    projectId: a.projectId,
                    isExpanded: _versionHistoryExpanded,
                    onToggle: () => setState(
                      () => _versionHistoryExpanded = !_versionHistoryExpanded,
                    ),
                    formatDate: _formatDate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// VERSION HISTORY COLLAPSIBLE SECTION
// ---------------------------------------------------------------------------

class _VersionHistorySection extends ConsumerWidget {
  final String projectId;
  final bool isExpanded;
  final VoidCallback onToggle;
  final String Function(DateTime) formatDate;

  const _VersionHistorySection({
    required this.projectId,
    required this.isExpanded,
    required this.onToggle,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Version History',
                  style: AppTypography.labelMono.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: AppColors.outline,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Consumer(
            builder: (context, ref, _) {
              final versionsAsync =
                  ref.watch(projectDrawingVersionsProvider(projectId));
              return versionsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                  ),
                ),
                error: (_, _) => Padding(
                  padding: const EdgeInsets.only(left: 6, top: 4),
                  child: Text(
                    'No version history yet.',
                    style: AppTypography.labelMono.copyWith(
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.50),
                      fontSize: 11,
                    ),
                  ),
                ),
                data: (versions) {
                  if (versions.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 6, top: 4),
                      child: Text(
                        'No version history yet.',
                        style: AppTypography.labelMono.copyWith(
                          color:
                              AppColors.onSurfaceVariant.withValues(alpha: 0.50),
                          fontSize: 11,
                        ),
                      ),
                    );
                  }

                  return Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: AppColors.outlineVariant.withValues(alpha: 0.40),
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 100),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: versions.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final v = entry.value;
                            final isLatest = idx == 0;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'v${v.versionNumber}.0${isLatest ? ' (Current)' : ''}',
                                    style: AppTypography.labelMono.copyWith(
                                      color: isLatest
                                          ? AppColors.onSurface
                                          : AppColors.onSurfaceVariant,
                                      fontSize: 11,
                                      fontWeight: isLatest
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                  Text(
                                    formatDate(v.createdAt),
                                    style: AppTypography.labelMonoSm.copyWith(
                                      color: AppColors.outline,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// BLUEPRINT PREVIEW PAINTER
// ---------------------------------------------------------------------------

class _BlueprintPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFC5C6CD).withValues(alpha: 0.30)
      ..strokeWidth = 0.5;

    // Draw 20px CAD grid
    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Draw schematic CAD architectural linework
    final accentPaint = Paint()
      ..color = const Color(0xFF0453CD).withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(24, size.height - 24)
      ..lineTo(size.width * 0.35, size.height * 0.35)
      ..lineTo(size.width * 0.65, size.height * 0.55)
      ..lineTo(size.width - 24, size.height * 0.25);

    canvas.drawPath(path, accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
