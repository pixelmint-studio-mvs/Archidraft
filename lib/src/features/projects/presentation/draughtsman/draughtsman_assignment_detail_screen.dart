import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../../../shared/widgets/blueprint_background.dart';
import '../../domain/assignment.dart';
import '../../domain/assignment_status.dart';
import '../../domain/drawing_version.dart';
import '../../domain/project_status.dart';
import '../../providers/assignment_providers.dart';
import '../../providers/project_providers.dart';

/// Detailed view for a single assignment.
///
/// Faithfully reproduces and harmonizes:
/// - project_details_versioning/code.html
/// - project_workflow_timeline/code.html
///
/// Integrates real project specifications, drawing versions comparison,
/// real activity audit, and the continuous PROJECT WORKFLOW vertical timeline.
class DraughtsmanAssignmentDetailScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const DraughtsmanAssignmentDetailScreen({
    super.key,
    required this.assignmentId,
  });

  @override
  ConsumerState<DraughtsmanAssignmentDetailScreen> createState() =>
      _DraughtsmanAssignmentDetailScreenState();
}

class _DraughtsmanAssignmentDetailScreenState
    extends ConsumerState<DraughtsmanAssignmentDetailScreen> {
  bool _isOverlayMode = false;
  int? _selectedPreviousVersionNumber;
  int? _selectedCurrentVersionNumber;

  @override
  Widget build(BuildContext context) {
    ref.listen(draughtsmanActionsControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    final assignmentAsync = ref.watch(assignmentProvider(widget.assignmentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Studio',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/draughtsman/studio');
            }
          },
        ),
        title: Text(
          'Assignment Details',
          style: AppTypography.buttonText.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Assignment',
            onPressed: () {
              ref.invalidate(assignmentProvider(widget.assignmentId));
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      body: BlueprintBackground(
        child: assignmentAsync.when(
          loading: () =>
              const AppLoadingIndicator(message: 'Loading assignment details...'),
          error: (error, _) => AppErrorWidget(
            message: 'Failed to load assignment.',
            onRetry: () => ref.invalidate(assignmentProvider(widget.assignmentId)),
          ),
          data: (assignment) => _buildContent(context, assignment),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Assignment assignment) {
    final status = assignment.assignmentStatus ?? AssignmentStatus.pending;
    final isLoading = ref.watch(draughtsmanActionsControllerProvider).isLoading;
    final versionsAsync =
        ref.watch(projectDrawingVersionsProvider(assignment.projectId));
    final activitiesAsync =
        ref.watch(projectActivityLogsProvider(assignment.projectId));

    final projectStatusValue = assignment.projectStatus;
    final projectStatus = projectStatusValue != null
        ? ProjectStatus.values.firstWhere(
            (e) => e.name.toUpperCase() == projectStatusValue.toUpperCase(),
            orElse: () => ProjectStatus.draft,
          )
        : null;

    final prjCode = assignment.id.length > 12
        ? 'PRJ-${assignment.id.substring(0, 8).toUpperCase()}'
        : 'PRJ-${assignment.id.toUpperCase()}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktop = screenWidth >= 1024;
        final horizontalPadding =
            isDesktop ? AppSpacing.marginDesktop : AppSpacing.marginMobile;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: isDesktop ? AppSpacing.xl : AppSpacing.lg,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 1. PROJECT HEADER CARD (project_details_versioning + project_workflow_timeline) ──
                  _buildProjectHeaderCard(
                    assignment: assignment,
                    prjCode: prjCode,
                    projectStatus: projectStatus,
                    isDesktop: isDesktop,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── 2. CONTEXTUAL ACTION PANEL (If Action Required / Loading) ──
                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (status == AssignmentStatus.pending) ...[
                    _PendingActions(assignment: assignment),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // ── 3. RESPONSIVE BENTO / TWO-COLUMN GRID ──
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column (Span 7) — Drawing Versioning + Project Workflow Timeline
                        Expanded(
                          flex: 7,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildDrawingVersioningCard(
                                assignment: assignment,
                                versionsAsync: versionsAsync,
                                isDesktop: true,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _buildWorkflowTimelineSection(
                                assignment: assignment,
                                status: status,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.gridGutter),
                        // Right Column (Span 5) — Project Details Specifications + Activity Audit
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildDetailsCard(assignment),
                              const SizedBox(height: AppSpacing.lg),
                              _buildActivityAuditCard(activitiesAsync),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    // Mobile / Tablet Stack
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDrawingVersioningCard(
                          assignment: assignment,
                          versionsAsync: versionsAsync,
                          isDesktop: false,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildDetailsCard(assignment),
                        const SizedBox(height: AppSpacing.lg),
                        _buildWorkflowTimelineSection(
                          assignment: assignment,
                          status: status,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildActivityAuditCard(activitiesAsync),
                      ],
                    ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // 1. PROJECT HEADER CARD
  // Matches:
  // - project_details_versioning/code.html lines 208-226
  // - project_workflow_timeline/code.html lines 168-189
  // ─────────────────────────────────────────────────────────

  Widget _buildProjectHeaderCard({
    required Assignment assignment,
    required String prjCode,
    required ProjectStatus? projectStatus,
    required bool isDesktop,
  }) {
    final status = assignment.assignmentStatus ?? AssignmentStatus.pending;
    final isPending = status == AssignmentStatus.pending;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.45),
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
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle architectural construction lines
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 1.0,
            child: Container(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            bottom: 0,
            width: 1.0,
            child: Container(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(isDesktop ? AppSpacing.xl : AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag & Status Badges
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        prjCode,
                        style: AppTypography.labelMono.copyWith(
                          color: AppColors.outline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _buildStatusBadge(assignment, projectStatus),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Project Title & Primary Action in Responsive Row
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 650 : double.infinity,
                      ),
                      child: Text(
                        assignment.projectName?.isNotEmpty == true
                            ? assignment.projectName!
                            : 'Civic Center Pavilion',
                        style: isDesktop
                            ? AppTypography.headlineDisplay.copyWith(
                                color: AppColors.primary,
                                fontSize: 28,
                                height: 1.2,
                              )
                            : AppTypography.headlineLgMobile.copyWith(
                                color: AppColors.primary,
                                fontSize: 22,
                                height: 1.2,
                              ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isPending)
                          ElevatedButton.icon(
                            onPressed: () {
                              context.push(
                                  '/draughtsman/workspace/${assignment.id}');
                            },
                            icon: const Icon(Icons.open_in_new_rounded, size: 16),
                            label: const Text('Open Workspace'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusDefault),
                              ),
                              elevation: 0,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),
                Divider(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  height: 1,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Metadata Grid
                isDesktop
                    ? Row(
                        children: [
                          Expanded(
                            child: _buildMetaColumn(
                              'CLIENT',
                              assignment.projectName?.contains('TEST') == true
                                  ? 'Client Test Corporation'
                                  : 'Studio Partner',
                            ),
                          ),
                          Expanded(
                            child: _buildMetaColumn(
                              'DRAWING TYPE',
                              assignment.drawingType ?? 'Floor Plan',
                            ),
                          ),
                          Expanded(
                            child: _buildMetaColumn(
                              'PROJECT AREA',
                              assignment.projectArea != null
                                  ? (assignment.projectArea!.toLowerCase().contains('sq')
                                      ? assignment.projectArea!
                                      : '${assignment.projectArea} sq ft')
                                  : 'Not specified',
                            ),
                          ),
                          Expanded(
                            child: _buildMetaColumn(
                              'ASSIGNED DATE',
                              assignment.assignedAt != null
                                  ? DateFormat('MMM d, yyyy')
                                      .format(assignment.assignedAt!)
                                  : 'Oct 6, 2026',
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetaColumn(
                                  'CLIENT',
                                  'Studio Client',
                                ),
                              ),
                              Expanded(
                                child: _buildMetaColumn(
                                  'DRAWING TYPE',
                                  assignment.drawingType ?? 'Floor Plan',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetaColumn(
                                  'PROJECT AREA',
                                  assignment.projectArea != null
                                      ? (assignment.projectArea!.toLowerCase().contains('sq')
                                          ? assignment.projectArea!
                                          : '${assignment.projectArea} sq ft')
                                      : 'Not specified',
                                ),
                              ),
                              Expanded(
                                child: _buildMetaColumn(
                                  'ASSIGNED DATE',
                                  assignment.assignedAt != null
                                      ? DateFormat('MMM d, yyyy')
                                          .format(assignment.assignedAt!)
                                      : 'Oct 6, 2026',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMonoSm.copyWith(
            color: AppColors.outline,
            fontSize: 10,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatusBadge(Assignment assignment, ProjectStatus? projectStatus) {
    String text;
    Color bg;
    Color fg;

    final rawStatus = assignment.projectStatus ?? 'PENDING';
    if (rawStatus == 'UNDER_CLIENT_REVIEW' || rawStatus == 'REVIEW') {
      text = 'STATUS: REVIEW';
      bg = const Color(0xFF85F8C4);
      fg = const Color(0xFF069669);
    } else if (rawStatus == 'IN_PROGRESS') {
      text = 'STATUS: IN PROGRESS';
      bg = AppColors.secondaryFixed;
      fg = AppColors.secondary;
    } else if (rawStatus == 'COMPLETED') {
      text = 'STATUS: COMPLETED';
      bg = const Color(0xFFE8F5E9);
      fg = AppColors.success;
    } else if ((assignment.correctionRound ?? 0) > 0) {
      text = 'STATUS: CORRECTION (ROUND ${assignment.correctionRound})';
      bg = AppColors.errorContainer;
      fg = AppColors.error;
    } else {
      text = 'STATUS: $rawStatus';
      bg = AppColors.surfaceContainerHigh;
      fg = AppColors.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        text,
        style: AppTypography.labelMono.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 2. DRAWING VERSIONING & COMPARISON CARD
  // Faithfully reproduces: project_details_versioning/code.html lines 228-270
  // ─────────────────────────────────────────────────────────

  Widget _buildDrawingVersioningCard({
    required Assignment assignment,
    required AsyncValue<List<DrawingVersion>> versionsAsync,
    required bool isDesktop,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.45),
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
            offset: const Offset(0, 12),
            blurRadius: 24,
          ),
        ],
      ),
      padding: EdgeInsets.all(isDesktop ? AppSpacing.xl : AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toolbar with Split View / Overlay & Zoom Controls
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ToolbarSegment(
                      label: 'Split View',
                      isSelected: !_isOverlayMode,
                      onTap: () => setState(() => _isOverlayMode = false),
                    ),
                    _ToolbarSegment(
                      label: 'Overlay',
                      isSelected: _isOverlayMode,
                      onTap: () => setState(() => _isOverlayMode = true),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.zoom_in_rounded, size: 20),
                    color: AppColors.outline,
                    onPressed: () {},
                    tooltip: 'Zoom In',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    icon: const Icon(Icons.zoom_out_rounded, size: 20),
                    color: AppColors.outline,
                    onPressed: () {},
                    tooltip: 'Zoom Out',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    icon: const Icon(Icons.fit_screen_rounded, size: 20),
                    color: AppColors.outline,
                    onPressed: () {},
                    tooltip: 'Fit to Screen',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          Divider(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Comparison Viewers & Drawings
          versionsAsync.when(
            loading: () => const SizedBox(
              height: 380,
              child: Center(
                child: AppLoadingIndicator(message: 'Loading drawing versions...'),
              ),
            ),
            error: (e, _) => SizedBox(
              height: 380,
              child: Center(
                child: Text(
                  'Failed to load versions: $e',
                  style: AppTypography.bodySm.copyWith(color: AppColors.error),
                ),
              ),
            ),
            data: (versions) {
              final sortedVersions = List<DrawingVersion>.from(versions)
                ..sort((a, b) => a.versionNumber.compareTo(b.versionNumber));

              if (sortedVersions.isEmpty) {
                return _buildEmptyDraftViewport(assignment);
              }

              final currentVersion = sortedVersions.firstWhere(
                (v) => v.versionNumber == _selectedCurrentVersionNumber,
                orElse: () => sortedVersions.last,
              );

              final previousVersion = sortedVersions.firstWhere(
                (v) => v.versionNumber == _selectedPreviousVersionNumber,
                orElse: () => sortedVersions.length > 1
                    ? sortedVersions[sortedVersions.length - 2]
                    : sortedVersions.first,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Version Pills Selector
                  if (sortedVersions.length > 1) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Text(
                            'REVISIONS:',
                            style: AppTypography.labelMonoSm.copyWith(
                              color: AppColors.outline,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          ...sortedVersions.map((v) {
                            final isCurr = v.versionNumber ==
                                currentVersion.versionNumber;
                            final isPrev = v.versionNumber ==
                                previousVersion.versionNumber;

                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    if (v.versionNumber !=
                                        currentVersion.versionNumber) {
                                      _selectedPreviousVersionNumber =
                                          v.versionNumber;
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isCurr
                                        ? AppColors.primary
                                        : (isPrev
                                            ? AppColors.surfaceContainerHigh
                                            : AppColors.surfaceContainerLow),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isPrev
                                          ? AppColors.secondary
                                          : AppColors.outlineVariant
                                              .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    'v${v.versionNumber}${isCurr ? ' (Current)' : (isPrev ? ' (Compare)' : '')}',
                                    style: AppTypography.labelMono.copyWith(
                                      color: isCurr
                                          ? Colors.white
                                          : (isPrev
                                              ? AppColors.secondary
                                              : AppColors.onSurfaceVariant),
                                      fontSize: 11,
                                      fontWeight: isCurr || isPrev
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Viewport Canvas
                  _isOverlayMode
                      ? SizedBox(
                          height: isDesktop ? 380 : 300,
                          child: _buildOverlayViewport(
                              currentVersion, previousVersion),
                        )
                      : (isDesktop
                          ? SizedBox(
                              height: 380,
                              child: _buildSplitViewport(
                                  currentVersion, previousVersion, isDesktop),
                            )
                          : _buildSplitViewport(
                              currentVersion, previousVersion, isDesktop)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSplitViewport(
    DrawingVersion current,
    DrawingVersion previous,
    bool isDesktop,
  ) {
    final showDual = current.versionNumber != previous.versionNumber;

    if (!showDual) {
      return SizedBox(
        height: isDesktop ? 380 : 300,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Current: v${current.versionNumber}',
                    style: AppTypography.labelMono.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: CustomPaint(
                    size: const Size(400, 280),
                    painter: _BlueprintDrawingPainter(
                      isRevised: false,
                      revisionNumber: current.versionNumber,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 580;
        final prevPanel = Container(
          height: isNarrow ? 240 : null,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Previous: v${previous.versionNumber}',
                    style: AppTypography.labelMono.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              Center(
                child: CustomPaint(
                  size: const Size(220, 200),
                  painter: _BlueprintDrawingPainter(
                    isRevised: false,
                    revisionNumber: previous.versionNumber,
                  ),
                ),
              ),
            ],
          ),
        );

        final currPanel = Container(
          height: isNarrow ? 240 : null,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Current: v${current.versionNumber}',
                    style: AppTypography.labelMono.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              Center(
                child: CustomPaint(
                  size: const Size(220, 200),
                  painter: _BlueprintDrawingPainter(
                    isRevised: true,
                    revisionNumber: current.versionNumber,
                  ),
                ),
              ),
            ],
          ),
        );

        if (isNarrow) {
          return Column(
            children: [
              prevPanel,
              const SizedBox(height: AppSpacing.md),
              currPanel,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: prevPanel),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: currPanel),
          ],
        );
      },
    );
  }

  Widget _buildOverlayViewport(
      DrawingVersion current, DrawingVersion previous) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.45),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            left: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Overlay: v${previous.versionNumber} vs v${current.versionNumber}',
                    style: AppTypography.labelMono.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: CustomPaint(
                size: const Size(360, 260),
                painter: _BlueprintDrawingPainter(
                  isRevised: true,
                  isOverlayMode: true,
                  revisionNumber: current.versionNumber,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDraftViewport(Assignment assignment) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.draw_outlined,
              size: 40,
              color: AppColors.outline,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Initial Draft In Progress',
              style: AppTypography.buttonText.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No revisions committed yet. Upload drawing in Workspace.',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/draughtsman/workspace/${assignment.id}');
              },
              icon: const Icon(Icons.upload_file_rounded, size: 16),
              label: const Text('Open Workspace to Upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 3. PROJECT WORKFLOW TIMELINE
  // Faithfully reproduces: project_workflow_timeline/code.html lines 190-285
  // ─────────────────────────────────────────────────────────

  Widget _buildWorkflowTimelineSection({
    required Assignment assignment,
    required AssignmentStatus status,
  }) {
    final rawStatus = assignment.projectStatus ?? 'PENDING';
    final isPending = status == AssignmentStatus.pending;
    final isAccepted = status == AssignmentStatus.accepted;
    final isUnderReview = rawStatus == 'UNDER_CLIENT_REVIEW' || rawStatus == 'REVIEW';
    final isCompleted = rawStatus == 'COMPLETED' || status == AssignmentStatus.completed;
    final correctionRound = assignment.correctionRound ?? 0;
    final isCorrectionMode = correctionRound > 0 && !isCompleted;

    // Timeline Node calculations
    // 1. Request Submitted -> Completed
    const step1Completed = true;
    const step1Active = false;

    // 2. Admin Review & Assignment -> Completed
    const step2Completed = true;
    const step2Active = false;

    // 3. Assigned to Draughtsman -> Completed if accepted, Active if pending
    final step3Completed = isAccepted || isUnderReview || isCompleted;
    final step3Active = isPending;

    // 4. Drawing Creation & Versioning -> Active if in progress and not under review
    final step4Completed = isUnderReview || isCompleted || isCorrectionMode;
    final step4Active = isAccepted && !isUnderReview && !isCompleted && !isCorrectionMode;

    // 5. Client Review / Correction Rounds
    final step5Completed = isCompleted;
    final step5Active = isUnderReview || isCorrectionMode;

    // 6. Final Approval & Delivery
    final step6Completed = isCompleted;
    const step6Active = false;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.45),
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
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_tree_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'PROJECT WORKFLOW',
                style: AppTypography.buttonText.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Vertical Timeline Steps matching Reference Design 40px Nodes
          _WorkflowTimelineNode(
            stepNumber: '1',
            title: '1. Request Submitted',
            description: 'Files uploaded and project requirements defined by client.',
            isCompleted: step1Completed,
            isActive: step1Active,
            isLast: false,
          ),
          _WorkflowTimelineNode(
            stepNumber: '2',
            title: '2. Admin Review & Allocation',
            description: 'Scope approved by studio admin and allocated to Draughtsman.',
            isCompleted: step2Completed,
            isActive: step2Active,
            isLast: false,
          ),
          _WorkflowTimelineNode(
            stepNumber: '3',
            title: '3. Assigned to Draughtsman',
            description: isPending
                ? 'Action Required: Accept or reject this assignment.'
                : 'Assignment accepted. Drafting authorized.',
            isCompleted: step3Completed,
            isActive: step3Active,
            isLast: false,
            activeWidget: step3Active
                ? _buildActivePendingBox(assignment)
                : null,
          ),
          _WorkflowTimelineNode(
            stepNumber: '4',
            title: '4. Drawing Creation & Versioning',
            description: step4Active
                ? 'Currently drafting architectural floor plans and sections.'
                : 'Drawing revisions drafted and uploaded to studio workspace.',
            isCompleted: step4Completed,
            isActive: step4Active,
            isLast: false,
            activeWidget: step4Active
                ? _buildActiveDraftingBox(assignment)
                : null,
          ),
          _WorkflowTimelineNode(
            stepNumber: '5',
            title: isCorrectionMode
                ? '5. Correction Requested (Round $correctionRound)'
                : '5. Client & Engineer Review',
            description: isCorrectionMode
                ? 'Revisions required by client or engineer. See review notes.'
                : (isUnderReview
                    ? 'Drawings submitted and currently pending approval.'
                    : 'Initial structural and specifications review.'),
            isCompleted: step5Completed,
            isActive: step5Active,
            isCorrection: isCorrectionMode,
            isLast: false,
            activeWidget: step5Active
                ? _buildActiveReviewBox(assignment, isCorrectionMode, correctionRound)
                : null,
          ),
          _WorkflowTimelineNode(
            stepNumber: '6',
            title: '6. Final Approval & Delivery',
            description: isCompleted
                ? 'Drawings approved. Handover of finalized CAD drawing sets complete.'
                : 'Handover of finalized drawing sets upon final approval.',
            isCompleted: step6Completed,
            isActive: step6Active,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDraftingBox(Assignment assignment) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DRAFT PROGRESS',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.outline,
                  fontSize: 10,
                ),
              ),
              Text(
                '65%',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.65,
              backgroundColor: AppColors.surfaceContainerHigh,
              color: AppColors.secondary,
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/draughtsman/workspace/${assignment.id}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerHigh,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(
                        color: AppColors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  child: Text(
                    'VIEW DRAFTS IN WORKSPACE',
                    style: AppTypography.labelMonoSm.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivePendingBox(Assignment assignment) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ASSIGNMENT PENDING ACCEPTANCE',
            style: AppTypography.labelMonoSm.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Review project specifications and confirm allocation to begin drafting.',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveReviewBox(
    Assignment assignment,
    bool isCorrectionMode,
    int correctionRound,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isCorrectionMode
            ? AppColors.errorContainer.withValues(alpha: 0.2)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: isCorrectionMode
              ? AppColors.error.withValues(alpha: 0.4)
              : AppColors.secondary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrectionMode
                    ? Icons.warning_amber_rounded
                    : Icons.rate_review_outlined,
                size: 16,
                color: isCorrectionMode ? AppColors.error : AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isCorrectionMode
                      ? 'CORRECTION CYCLE #$correctionRound ACTIVE'
                      : 'UNDER CLIENT & LEAD ARCHITECT REVIEW',
                  style: AppTypography.labelMonoSm.copyWith(
                    color: isCorrectionMode ? AppColors.error : AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isCorrectionMode
                ? 'Client requested amendments to the submitted draft. Please make updates in Workspace and resubmit.'
                : 'Current revision submitted. Awaiting approval or correction feedback.',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.push('/draughtsman/workspace/${assignment.id}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isCorrectionMode ? AppColors.error : AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                isCorrectionMode ? 'OPEN WORKSPACE FOR CORRECTIONS' : 'OPEN WORKSPACE',
                style: AppTypography.labelMonoSm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 4. PROJECT DETAILS SPECIFICATIONS CARD
  // Matches: project_details_versioning/code.html lines 273-295
  // ─────────────────────────────────────────────────────────

  Widget _buildDetailsCard(Assignment assignment) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.45),
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
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: AppTypography.headlineLgMobile.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Author / Assignee
          Text(
            'ASSIGNEE',
            style: AppTypography.labelMonoSm.copyWith(
              color: AppColors.outline,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'D',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Draughtsman',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          Divider(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.md),

          // Drawing Name
          Text(
            'DRAWING NAME & TYPE',
            style: AppTypography.labelMonoSm.copyWith(
              color: AppColors.outline,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${assignment.drawingName?.isNotEmpty == true ? assignment.drawingName : 'Main Architectural Plan'} • ${assignment.drawingType ?? 'Floor Plan'}',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurface,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          Divider(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.md),

          // Location
          Text(
            'LOCATION / SITE ADDRESS',
            style: AppTypography.labelMonoSm.copyWith(
              color: AppColors.outline,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            assignment.projectAddress?.isNotEmpty == true
                ? assignment.projectAddress!
                : '123 Test Street, Dev City',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurface,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          Divider(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.md),

          // File Format & Size
          Text(
            'FILE FORMAT & CAD SPEC',
            style: AppTypography.labelMonoSm.copyWith(
              color: AppColors.outline,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'DWG / PDF Vector • Layered Architectural Standard',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurface,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          Divider(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.md),

          // Last Modified
          Text(
            'LAST MODIFIED',
            style: AppTypography.labelMonoSm.copyWith(
              color: AppColors.outline,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            assignment.updatedAt != null
                ? DateFormat('MMM d, yyyy • HH:mm')
                    .format(assignment.updatedAt!)
                : 'Recent',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurface,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 5. ACTIVITY AUDIT CARD
  // Matches: project_details_versioning/code.html lines 296-324
  // ─────────────────────────────────────────────────────────

  Widget _buildActivityAuditCard(
    AsyncValue<List<Map<String, dynamic>>> activitiesAsync,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.45),
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
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Audit',
            style: AppTypography.headlineLgMobile.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          activitiesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: AppLoadingIndicator(message: 'Loading activity logs...'),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Activity log unavailable.',
                style: AppTypography.bodySm.copyWith(color: AppColors.outline),
              ),
            ),
            data: (logs) {
              if (logs.isEmpty) {
                return _buildStaticAuditFallback();
              }

              return Column(
                children: List.generate(
                  math.min(logs.length, 5),
                  (index) {
                    final item = logs[index];
                    final rawTime = item['timestamp']?.toString() ?? '';
                    final details = item['details']?.toString() ??
                        item['action_type']?.toString() ??
                        'Action logged';
                    final isFirst = index == 0;
                    final isLast = index == math.min(logs.length, 5) - 1;

                    final act = item['action_type']?.toString() ?? '';
                    final actionTitle = switch (act) {
                      'PROJECT_APPROVED' => 'Project Scope Approved',
                      'DRAUGHTSMAN_ASSIGNED' => 'Draughtsman Assigned',
                      'ASSIGNMENT_ACCEPTED' => 'Assignment Accepted',
                      'FILE_UPLOADED' => 'Drawing Version Uploaded',
                      'DRAWING_SUBMITTED' => 'Drawing Submitted for Review',
                      'CORRECTION_REQUESTED' => 'Correction Requested',
                      'CORRECTION_STARTED' => 'Correction Started',
                      'PROJECT_COMPLETED' => 'Project Approved & Completed',
                      _ => 'System Event',
                    };

                    return _AuditLogItem(
                      timestamp: _formatTimestamp(rawTime),
                      title: actionTitle,
                      subtitle: details,
                      isFirst: isFirst,
                      isLast: isLast,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStaticAuditFallback() {
    return const Column(
      children: [
        _AuditLogItem(
          timestamp: 'RECENT',
          title: 'Assignment Initialized',
          subtitle: 'Allocation dispatched by Studio Admin.',
          isFirst: true,
          isLast: true,
        ),
      ],
    );
  }

  String _formatTimestamp(String raw) {
    if (raw.isEmpty) return 'RECENT';
    try {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return DateFormat('MMM d, HH:mm').format(parsed).toUpperCase();
      }
    } catch (_) {}
    return raw.toUpperCase();
  }
}

// ─────────────────────────────────────────────────────────
// WORKFLOW TIMELINE NODE WIDGET
// Matches: project_workflow_timeline/code.html lines 201-284
// ─────────────────────────────────────────────────────────

class _WorkflowTimelineNode extends StatelessWidget {
  final String stepNumber;
  final String title;
  final String description;
  final bool isCompleted;
  final bool isActive;
  final bool isCorrection;
  final bool isLast;
  final Widget? activeWidget;

  const _WorkflowTimelineNode({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.isActive,
    this.isCorrection = false,
    required this.isLast,
    this.activeWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget nodeIcon;
    BoxDecoration nodeDecoration;

    if (isCompleted) {
      // Completed node: 40px rounded-full bg-secondary, 4px white border, white check icon
      nodeDecoration = BoxDecoration(
        color: AppColors.secondary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.08),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      );
      nodeIcon = const Icon(
        Icons.check_rounded,
        size: 18,
        color: Colors.white,
      );
    } else if (isActive) {
      // Active node: 40px rounded-full bg-white, 2px border-secondary, glowing shadow, 8px dot
      final ringColor = isCorrection ? AppColors.error : AppColors.secondary;
      nodeDecoration = BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: ringColor.withValues(alpha: 0.35),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      );
      nodeIcon = Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: ringColor,
          shape: BoxShape.circle,
        ),
      );
    } else {
      // Pending node: 40px rounded-full bg-surface, 2px border-outline-variant, opacity 0.5
      nodeDecoration = BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.7),
          width: 2,
        ),
      );
      nodeIcon = Text(
        stepNumber,
        style: TextStyle(
          color: AppColors.outline.withValues(alpha: 0.7),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical Line + 40px Node Column
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: nodeDecoration,
                  child: Center(child: nodeIcon),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: isCompleted
                          ? AppColors.secondary
                          : AppColors.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.lg),

          // Content Column
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 8,
                bottom: isLast ? 0 : AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.buttonText.copyWith(
                      color: isActive
                          ? (isCorrection ? AppColors.error : AppColors.secondary)
                          : (isCompleted
                              ? AppColors.primary
                              : AppColors.outline),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: AppTypography.bodyMd.copyWith(
                      color: isActive
                          ? AppColors.onSurface
                          : (isCompleted
                              ? AppColors.onSurfaceVariant
                              : AppColors.outline),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  ?activeWidget,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// ACTIVITY AUDIT ITEM WIDGET
// Matches: project_details_versioning/code.html lines 299-323
// ─────────────────────────────────────────────────────────

class _AuditLogItem extends StatelessWidget {
  final String timestamp;
  final String title;
  final String subtitle;
  final bool isFirst;
  final bool isLast;

  const _AuditLogItem({
    required this.timestamp,
    required this.title,
    required this.subtitle,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hairline vertical line with 8px circular node
          SizedBox(
            width: 16,
            child: Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isFirst
                        ? AppColors.primary
                        : AppColors.surfaceContainerHigh,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF000000).withValues(alpha: 0.1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: AppColors.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timestamp,
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.outline,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TOOLBAR SEGMENT BUTTON WIDGET
// ─────────────────────────────────────────────────────────

class _ToolbarSegment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolbarSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF000000).withValues(alpha: 0.05),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.labelMono.copyWith(
            color: isSelected ? AppColors.primary : AppColors.outline,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// BLUEPRINT TECHNICAL DRAWING PAINTER
// Generates authentic architectural drawing geometry with dimension lines
// ─────────────────────────────────────────────────────────

class _BlueprintDrawingPainter extends CustomPainter {
  final bool isRevised;
  final bool isOverlayMode;
  final int revisionNumber;

  _BlueprintDrawingPainter({
    required this.isRevised,
    this.isOverlayMode = false,
    required this.revisionNumber,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid pattern
    final gridPaint = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    for (double x = 0; x <= w; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y <= h; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Outer boundary walls
    final wallPaint = Paint()
      ..color = isOverlayMode && isRevised
          ? AppColors.secondary
          : const Color(0xFF1B1B1D)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final boundary = RRect.fromRectAndRadius(
      Rect.fromLTWH(30, 30, w - 60, h - 60),
      const Radius.circular(2),
    );
    canvas.drawRRect(boundary, wallPaint);

    // Inner room walls
    final midX = w * 0.45;
    final midY = h * 0.52;
    canvas.drawLine(Offset(midX, 30), Offset(midX, h - 30), wallPaint);
    canvas.drawLine(Offset(30, midY), Offset(w - 30, midY), wallPaint);

    // Door swing arc
    final arcPaint = Paint()
      ..color = AppColors.outline.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(midX, midY), radius: 24),
      0,
      1.57,
      false,
      arcPaint,
    );

    // If Revised (Current version) — highlight the revision area
    if (isRevised) {
      final highlightPaint = Paint()
        ..color = AppColors.secondary.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;

      final highlightBorder = Paint()
        ..color = AppColors.secondary
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final revisedRoom = Rect.fromLTWH(midX + 10, 40, w - midX - 80, midY - 50);
      canvas.drawRect(revisedRoom, highlightPaint);
      canvas.drawRect(revisedRoom, highlightBorder);
    }

    // Technical stamp / Scale tag
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'ARCHI DRAFT • PRECISION SYSTEM • v$revisionNumber\nSCALE 1:100 • DWG MATRIX',
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 8,
          color: AppColors.outline.withValues(alpha: 0.7),
          height: 1.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(40, h - 55));
  }

  @override
  bool shouldRepaint(covariant _BlueprintDrawingPainter oldDelegate) {
    return oldDelegate.isRevised != isRevised ||
        oldDelegate.isOverlayMode != isOverlayMode ||
        oldDelegate.revisionNumber != revisionNumber;
  }
}

// ─────────────────────────────────────────────────────────
// ACTION PANELS (PRESERVED WORKFLOW LOGIC)
// ─────────────────────────────────────────────────────────

class _PendingActions extends ConsumerWidget {
  final Assignment assignment;

  const _PendingActions({required this.assignment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_late_outlined,
                  color: AppColors.secondary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'ACTION REQUIRED',
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Review the project requirements and decide whether to accept or reject this assignment.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleReject(context, ref),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _handleAccept(context, ref),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Accept'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAccept(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success, size: 22),
            SizedBox(width: AppSpacing.sm),
            Text('Accept Assignment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accept this assignment for "${assignment.projectName ?? 'Untitled'}"?',
              style: AppTypography.bodyMd,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'By accepting, you commit to completing the drawing per the listed specifications.',
              style: AppTypography.bodySm
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    final success = await ref
        .read(draughtsmanActionsControllerProvider.notifier)
        .acceptAssignment(
          assignmentId: assignment.id,
          projectId: assignment.projectId,
        );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment Accepted! Opening workspace...'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pushReplacement('/draughtsman/workspace/${assignment.id}');
    }
  }

  void _handleReject(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.error, size: 22),
            SizedBox(width: AppSpacing.sm),
            Text('Reject Assignment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject this assignment for "${assignment.projectName ?? 'Untitled'}"?',
              style: AppTypography.bodyMd,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'This action cannot be undone. The admin will be notified and may reassign the project.',
              style: AppTypography.bodySm
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    final success = await ref
        .read(draughtsmanActionsControllerProvider.notifier)
        .rejectAssignment(
          assignmentId: assignment.id,
          projectId: assignment.projectId,
        );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment Rejected.'),
          backgroundColor: AppColors.error,
        ),
      );
      context.go('/draughtsman/studio');
    }
  }
}
