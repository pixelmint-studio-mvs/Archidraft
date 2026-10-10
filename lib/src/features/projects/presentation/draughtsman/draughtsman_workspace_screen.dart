import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/utils/date_parser.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../../../shared/widgets/blueprint_background.dart';
import '../../domain/drawing_version.dart';
import '../../domain/project.dart';
import '../../domain/project_status.dart';
import '../../domain/project_file.dart';
import '../../domain/assignment.dart';
import '../../domain/correction.dart';
import '../../data/file_repository.dart';
import '../../providers/assignment_providers.dart';
import '../../providers/file_providers.dart';
import '../../providers/project_providers.dart';
import '../widgets/file_upload_button.dart';
import 'collaboration_hub_view.dart';

// ─────────────────────────────────────────────────────────
// DRAUGHTSMAN WORKSPACE SCREEN (PANEL 5)
// Faithfully reproduces:
// - REFERENCE DESIGN/draughtsman_workspace
// - REFERENCE DESIGN/project_details_versioning
// - REFERENCE DESIGN/collaboration_hub
// ─────────────────────────────────────────────────────────

class DraughtsmanWorkspaceScreen extends ConsumerWidget {
  final String assignmentId;
  final String? initialTab;

  const DraughtsmanWorkspaceScreen({
    super.key,
    required this.assignmentId,
    this.initialTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final assignmentAsync = ref.watch(assignmentProvider(assignmentId));

    return assignmentAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildSimpleAppBar(context, 'Loading Workspace...'),
        body: const AppLoadingIndicator(message: 'Loading workspace...'),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildSimpleAppBar(context, 'Workspace Error'),
        body: AppErrorWidget(
          message: 'Failed to load assignment: $error',
          onRetry: () => ref.invalidate(assignmentProvider(assignmentId)),
        ),
      ),
      data: (assignment) {
        if (assignment.projectId.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: _buildSimpleAppBar(context, 'Workspace Error'),
            body: const AppErrorWidget(
              message: 'Invalid assignment: missing project association.',
              onRetry: null,
            ),
          );
        }

        final projectId = assignment.projectId;
        final projectAsync = ref.watch(projectProvider(projectId));

        return projectAsync.when(
          loading: () => Scaffold(
            backgroundColor: AppColors.background,
            appBar: _buildSimpleAppBar(context, assignment.displayProjectName),
            body: const AppLoadingIndicator(message: 'Loading workspace...'),
          ),
          error: (error, _) => Scaffold(
            backgroundColor: AppColors.background,
            appBar: _buildSimpleAppBar(context, assignment.displayProjectName),
            body: AppErrorWidget(
              message: 'Failed to load workspace: $error',
              onRetry: () => ref.invalidate(projectProvider(projectId)),
            ),
          ),
          data: (project) {
            if (project == null) {
              return Scaffold(
                backgroundColor: AppColors.background,
                appBar: _buildSimpleAppBar(context, assignment.displayProjectName),
                body: AppErrorWidget(
                  message: 'Project record not found.',
                  onRetry: () => ref.invalidate(projectProvider(projectId)),
                ),
              );
            }

            return _WorkspaceScaffold(
              assignmentId: assignmentId,
              assignment: assignment,
              projectId: projectId,
              project: project,
              initialTab: initialTab,
            );
          },
        );
      },
    );
  }

  AppBar _buildSimpleAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: AppColors.surfaceContainerLowest,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Text(
        title,
        style: AppTypography.buttonText.copyWith(color: AppColors.onSurface),
      ),
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
    );
  }
}

// ─────────────────────────────────────────────────────────
// MAIN WORKSPACE SCAFFOLD
// ─────────────────────────────────────────────────────────

class _WorkspaceScaffold extends ConsumerStatefulWidget {
  final String assignmentId;
  final Assignment assignment;
  final String projectId;
  final Project project;
  final String? initialTab;

  const _WorkspaceScaffold({
    required this.assignmentId,
    required this.assignment,
    required this.projectId,
    required this.project,
    this.initialTab,
  });

  @override
  ConsumerState<_WorkspaceScaffold> createState() => _WorkspaceScaffoldState();
}

class _WorkspaceScaffoldState extends ConsumerState<_WorkspaceScaffold>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialTab == 'overview' || widget.initialTab == 'specs') {
      initialIndex = 2;
    } else if (widget.initialTab == 'timeline' || widget.initialTab == 'audit') {
      initialIndex = 3;
    } else if (widget.initialTab == 'collaboration' || widget.initialTab == 'chat') {
      initialIndex = 1;
    }
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void didUpdateWidget(_WorkspaceScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab && widget.initialTab != null) {
      int targetIndex = _tabController.index;
      if (widget.initialTab == 'overview' || widget.initialTab == 'specs') {
        targetIndex = 2;
      } else if (widget.initialTab == 'timeline' || widget.initialTab == 'audit') {
        targetIndex = 3;
      } else if (widget.initialTab == 'collaboration' || widget.initialTab == 'chat') {
        targetIndex = 1;
      } else if (widget.initialTab == 'workspace' || widget.initialTab == 'canvas') {
        targetIndex = 0;
      }
      if (targetIndex != _tabController.index) {
        _tabController.animateTo(targetIndex);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final assignment = widget.assignment;
    final status = project.projectStatus ?? ProjectStatus.draft;

    final prjCode = assignment.id.length > 12
        ? 'PRJ-${assignment.id.substring(0, 8).toUpperCase()}'
        : 'PRJ-${assignment.id.toUpperCase()}';

    // Status chip styling
    Color statusBgColor = AppColors.secondary.withValues(alpha: 0.1);
    Color statusTextColor = AppColors.secondary;
    String statusText = 'STATUS: ${status.displayName.toUpperCase()}';

    final isUnderReview = status == ProjectStatus.underClientReview;
    final isCompleted = status == ProjectStatus.completed;
    final hasCorrections = (assignment.correctionRound != null && assignment.correctionRound! > 0) ||
        assignment.isRevision;

    if (isCompleted) {
      statusBgColor = AppColors.success.withValues(alpha: 0.12);
      statusTextColor = AppColors.success;
      statusText = 'STATUS: COMPLETED';
    } else if (hasCorrections && !isUnderReview) {
      statusBgColor = AppColors.error.withValues(alpha: 0.12);
      statusTextColor = AppColors.error;
      statusText = 'STATUS: CORRECTION (ROUND ${assignment.correctionRound ?? 1})';
    } else if (isUnderReview) {
      statusBgColor = const Color(0xFF002114);
      statusTextColor = const Color(0xFF85F8C4);
      statusText = 'STATUS: REVIEW';
    }

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
        title: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 360;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: AppColors.outlineVariant.withValues(alpha: 0.5),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          prjCode,
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: statusTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: Text(
                    project.projectName.isNotEmpty ? project.projectName : 'Architectural Project',
                    style: AppTypography.buttonText.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: isNarrow ? 12 : 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree_outlined),
            tooltip: 'View Assignment Details & Workflow',
            onPressed: () => context.push('/draughtsman/assignments/${widget.assignmentId}'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Workspace',
            onPressed: () {
              ref.invalidate(assignmentProvider(widget.assignmentId));
              ref.invalidate(projectProvider(widget.projectId));
              ref.invalidate(projectDrawingVersionsProvider(widget.projectId));
              ref.invalidate(projectFilesProvider(widget.projectId));
              ref.invalidate(projectCorrectionsProvider(widget.projectId));
              ref.invalidate(projectActivityLogsProvider(widget.projectId));
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.secondary,
          indicatorWeight: 2,
          isScrollable: true,
          tabs: const [
            Tab(text: 'WORKSPACE CANVAS'),
            Tab(text: 'COLLABORATION HUB'),
            Tab(text: 'OVERVIEW & SPECS'),
            Tab(text: 'TIMELINE & AUDIT'),
          ],
        ),
      ),
      body: BlueprintBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _WorkspaceCanvasTab(
              assignmentId: widget.assignmentId,
              assignment: widget.assignment,
              projectId: widget.projectId,
              project: widget.project,
            ),
            _CollaborationHubTab(
              projectId: widget.projectId,
              project: widget.project,
              assignmentId: widget.assignmentId,
            ),
            _OverviewTab(
              projectId: widget.projectId,
              project: widget.project,
            ),
            _TimelineTab(
              projectId: widget.projectId,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 1. WORKSPACE CANVAS TAB (PRIMARY CAD AREA)
// ─────────────────────────────────────────────────────────

class _WorkspaceCanvasTab extends ConsumerStatefulWidget {
  final String assignmentId;
  final Assignment assignment;
  final String projectId;
  final Project project;

  const _WorkspaceCanvasTab({
    required this.assignmentId,
    required this.assignment,
    required this.projectId,
    required this.project,
  });

  @override
  ConsumerState<_WorkspaceCanvasTab> createState() => _WorkspaceCanvasTabState();
}

class _WorkspaceCanvasTabState extends ConsumerState<_WorkspaceCanvasTab> {
  bool _isOverlayMode = false;
  double _zoomScale = 1.0;
  final TransformationController _transformationController = TransformationController();

  void _zoomIn() {
    setState(() {
      _zoomScale = (_zoomScale * 1.25).clamp(0.5, 4.0);
      _transformationController.value = Matrix4.diagonal3Values(_zoomScale, _zoomScale, 1.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomScale = (_zoomScale / 1.25).clamp(0.5, 4.0);
      _transformationController.value = Matrix4.diagonal3Values(_zoomScale, _zoomScale, 1.0);
    });
  }

  void _fitScreen() {
    setState(() {
      _zoomScale = 1.0;
      _transformationController.value = Matrix4.identity();
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final versionsAsync = ref.watch(projectDrawingVersionsProvider(widget.projectId));
    final correctionsAsync = ref.watch(projectCorrectionsProvider(widget.projectId));
    final filesAsync = ref.watch(projectFilesProvider(widget.projectId));

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Workflow & Correction Alert Banners
              _buildWorkflowStatusBanners(correctionsAsync),
              const SizedBox(height: AppSpacing.lg),

              // Main Workspace Bento Grid
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CAD Drawing Viewport (Span 7)
                    Expanded(
                      flex: 7,
                      child: _buildDrawingArea(versionsAsync),
                    ),
                    const SizedBox(width: AppSpacing.gridGutter),
                    // Side Controls Panel (Span 5)
                    Expanded(
                      flex: 5,
                      child: _buildSideControls(versionsAsync, filesAsync, correctionsAsync),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDrawingArea(versionsAsync),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSideControls(versionsAsync, filesAsync, correctionsAsync),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWorkflowStatusBanners(AsyncValue<List<Correction>> correctionsAsync) {
    final project = widget.project;
    final status = project.projectStatus ?? ProjectStatus.draft;

    final isUnderReview = status == ProjectStatus.underClientReview;
    final isCompleted = status == ProjectStatus.completed;

    return correctionsAsync.maybeWhen(
      data: (corrections) {
        final openCorrection = corrections.where((c) => c.status != CorrectionStatus.resolved).firstOrNull;

        if (openCorrection != null && !isUnderReview && !isCompleted) {
          final isOpen = openCorrection.status == CorrectionStatus.open;
          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 1.0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.rate_review_outlined, color: AppColors.error, size: 24),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            'CORRECTION REQUIRED — ROUND #${openCorrection.roundNumber}',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isOpen ? 'NEEDS START' : 'IN CORRECTION',
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        openCorrection.description,
                        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
                      ),
                      if (isOpen) ...[
                        const SizedBox(height: AppSpacing.sm),
                        FilledButton.icon(
                          onPressed: () => _handleStartCorrection(openCorrection.id),
                          icon: const Icon(Icons.play_arrow_rounded, size: 16),
                          label: Text('Start Correction Round #${openCorrection.roundNumber}'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        if (isUnderReview) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: const Color(0xFF002114).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: const Color(0xFF069669).withValues(alpha: 0.4), width: 1.0),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.pending_actions_outlined, color: Color(0xFF069669), size: 24),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UNDER CLIENT & LEAD ARCHITECT REVIEW',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF069669),
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Submitted drawing is currently locked while the Engineering Lead and Client inspect vectors.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        if (isCompleted) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.4), width: 1.0),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.verified_outlined, color: AppColors.success, size: 24),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROJECT COMPLETED & APPROVED',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'All drawings approved by the Engineering Lead. Final production deliverables archived.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  void _handleStartCorrection(String correctionId) async {
    final success = await ref
        .read(draughtsmanActionsControllerProvider.notifier)
        .startCorrection(projectId: widget.projectId, correctionId: correctionId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correction phase started. Upload corrected draft.')),
      );
    }
  }

  Widget _buildDrawingArea(AsyncValue<List<DrawingVersion>> versionsAsync) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D1C32).withValues(alpha: 0.04),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFF0D1C32).withValues(alpha: 0.03),
            offset: const Offset(0, 12),
            blurRadius: 24,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toolbar: Segmented Split/Overlay, Coordinates & Zoom Controls
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              // Split View / Overlay Segment
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
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

              // Technical Coordinate & Scale Readout
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: const Text(
                  'SCALE 1:100 • 24.50m × 18.20m • CAD MATRIX',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.outline,
                  ),
                ),
              ),

              // Zoom Controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.zoom_in_rounded, size: 20),
                    color: AppColors.outline,
                    tooltip: 'Zoom In',
                    onPressed: _zoomIn,
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_out_rounded, size: 20),
                    color: AppColors.outline,
                    tooltip: 'Zoom Out',
                    onPressed: _zoomOut,
                  ),
                  IconButton(
                    icon: const Icon(Icons.fit_screen_rounded, size: 20),
                    color: AppColors.outline,
                    tooltip: 'Fit to Screen',
                    onPressed: _fitScreen,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          Divider(color: AppColors.outlineVariant.withValues(alpha: 0.3), height: 1),
          const SizedBox(height: AppSpacing.md),

          // CAD Blueprint Viewport
          Container(
            height: 480,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                child: versionsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error loading drawing: $e')),
                  data: (versions) {
                    final current = versions.isNotEmpty ? versions.first : null;
                    final previous = versions.length > 1 ? versions[1] : null;

                    if (_isOverlayMode) {
                      return _buildOverlayViewer(current, previous);
                    } else {
                      return _buildSplitViewer(current, previous);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitViewer(DrawingVersion? current, DrawingVersion? previous) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        if (isNarrow) {
          // Stacked on narrow screens to guarantee ZERO RenderFlex overflow
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildViewerHalf(
                  label: previous != null ? 'Previous: Rev ${previous.versionNumber}' : 'Initial State',
                  isCurrent: false,
                  revisionNumber: previous?.versionNumber ?? 1,
                  height: 235,
                ),
                Container(height: 1, color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                _buildViewerHalf(
                  label: current != null ? 'Current: Rev ${current.versionNumber}' : 'Current Draft',
                  isCurrent: true,
                  revisionNumber: current?.versionNumber ?? 2,
                  height: 235,
                ),
              ],
            ),
          );
        }

        return Row(
          children: [
            // Left Half: Previous Revision
            Expanded(
              child: _buildViewerHalf(
                label: previous != null ? 'Previous: Rev ${previous.versionNumber}' : 'Initial State',
                isCurrent: false,
                revisionNumber: previous?.versionNumber ?? 1,
              ),
            ),
            // Center Divider with slider handle
            Container(
              width: 1,
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
            // Right Half: Current Revision
            Expanded(
              child: _buildViewerHalf(
                label: current != null ? 'Current: Rev ${current.versionNumber}' : 'Current Draft',
                isCurrent: true,
                revisionNumber: current?.versionNumber ?? 2,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildViewerHalf({
    required String label,
    required bool isCurrent,
    required int revisionNumber,
    double? height,
  }) {
    return Container(
      height: height,
      color: isCurrent ? Colors.white : AppColors.surfaceContainerLowest.withValues(alpha: 0.6),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _BlueprintWorkspacePainter(
                isCurrent: isCurrent,
                revisionNumber: revisionNumber,
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCurrent ? AppColors.primary : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isCurrent
                      ? Colors.transparent
                      : AppColors.outlineVariant.withValues(alpha: 0.5),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isCurrent ? Colors.white : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayViewer(DrawingVersion? current, DrawingVersion? previous) {
    return Stack(
      children: [
        // Base Layer (Previous Drawing)
        Positioned.fill(
          child: CustomPaint(
            painter: _BlueprintWorkspacePainter(
              isCurrent: false,
              revisionNumber: previous?.versionNumber ?? 1,
            ),
          ),
        ),
        // Overlay Layer (Current Drawing with diff vectors)
        Positioned.fill(
          child: CustomPaint(
            painter: _BlueprintWorkspacePainter(
              isCurrent: true,
              isOverlay: true,
              revisionNumber: current?.versionNumber ?? 2,
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              'Overlay Diff: Rev ${previous?.versionNumber ?? 1} vs Rev ${current?.versionNumber ?? 2}',
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSideControls(
    AsyncValue<List<DrawingVersion>> versionsAsync,
    AsyncValue<List<ProjectFile>> filesAsync,
    AsyncValue<List<Correction>> correctionsAsync,
  ) {
    final project = widget.project;
    final assignment = widget.assignment;
    final status = project.projectStatus ?? ProjectStatus.draft;
    final isUnderReview = status == ProjectStatus.underClientReview;
    final isCompleted = status == ProjectStatus.completed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Details & Specifications Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.4),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D1C32).withValues(alpha: 0.04),
                offset: const Offset(0, 4),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Details & Specifications',
                style: AppTypography.headlineLgMobile.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _DetailField(
                label: 'AUTHOR',
                valueWidget: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                      child: const Text(
                        'DS',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Draughtsman Studio',
                        style: AppTypography.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              _DetailField(
                label: 'SITE LOCATION',
                value: assignment.projectAddress?.isNotEmpty == true
                    ? assignment.projectAddress!
                    : '123 Marine Drive, South Mumbai',
              ),
              _DetailField(
                label: 'DRAWING SPECIFICATION',
                value: assignment.drawingType?.isNotEmpty == true
                    ? assignment.drawingType!
                    : 'ARCHITECTURAL_DRAFTING - CAD VECTOR STANDARD',
              ),
              _DetailField(
                label: 'FILE FORMAT',
                value: 'DWG / DXF Vector • Layered Architectural Standard',
              ),
              _DetailField(
                label: 'LAST MODIFIED',
                value: DateFormat('MMM d, yyyy • HH:mm').format(assignment.updatedAt ?? project.createdAt ?? DateTime.now()),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // 2. Upload Revision & Submission Controls
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.4),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'UPLOAD REVISION DRAWING',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'PDF, DWG, DXF, PNG, ZIP — max 50 MB',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  color: AppColors.outline,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Dropzone texture container
              Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, size: 32, color: AppColors.secondary),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isUnderReview
                          ? 'Upload locked while under review'
                          : (isCompleted ? 'Project completed' : 'Select architectural CAD drawing'),
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (!isUnderReview && !isCompleted)
                      _StyledWorkspaceUploadButton(
                        projectId: widget.projectId,
                        category: 'draughtsman_version',
                      ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Primary Action: Submit for Review
              _SubmitWorkspaceButton(
                projectId: widget.projectId,
                project: widget.project,
                assignment: widget.assignment,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // 3. Version Log & Download History
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.4),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VERSION HISTORY',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              versionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
                data: (versions) {
                  if (versions.isEmpty) {
                    return Text(
                      'No revisions recorded yet.',
                      style: AppTypography.bodySm.copyWith(color: AppColors.outline),
                    );
                  }
                  return Column(
                    children: versions
                        .map((v) => _VersionLogItem(
                              version: v,
                              isCurrent: v == versions.first,
                              projectId: widget.projectId,
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// BLUEPRINT WORKSPACE CUSTOM PAINTER
// Generates CAD architectural geometry, grid coordinates, and revision clouds
// ─────────────────────────────────────────────────────────

class _BlueprintWorkspacePainter extends CustomPainter {
  final bool isCurrent;
  final bool isOverlay;
  final int revisionNumber;

  _BlueprintWorkspacePainter({
    required this.isCurrent,
    this.isOverlay = false,
    required this.revisionNumber,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Technical grid pattern (40px blueprint unit)
    final gridPaint = Paint()
      ..color = const Color(0xFFC5C6CD).withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    for (double x = 0; x <= w; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y <= h; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Outer structural walls
    final wallPaint = Paint()
      ..color = isOverlay
          ? const Color(0xFF0453CD).withValues(alpha: 0.9)
          : (isCurrent ? const Color(0xFF0D1C32) : const Color(0xFF75777E))
      ..strokeWidth = isCurrent ? 2.0 : 1.2
      ..style = PaintingStyle.stroke;

    final boundary = RRect.fromRectAndRadius(
      Rect.fromLTWH(36, 36, w - 72, h - 72),
      const Radius.circular(2),
    );
    canvas.drawRRect(boundary, wallPaint);

    // Structural partitions
    final midX = w * 0.42;
    final midY = h * 0.50;
    canvas.drawLine(Offset(midX, 36), Offset(midX, h - 36), wallPaint);
    canvas.drawLine(Offset(36, midY), Offset(w - 36, midY), wallPaint);

    // Inner doorway swing (90-degree radial arc)
    final arcPaint = Paint()
      ..color = AppColors.outline.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(midX, midY), radius: 28),
      0,
      1.57,
      false,
      arcPaint,
    );

    // Architectural central rotunda/circle feature
    final atriumCenter = Offset(w * 0.72, h * 0.30);
    final atriumPaint = Paint()
      ..color = isOverlay
          ? const Color(0xFF0453CD).withValues(alpha: 0.7)
          : (isCurrent ? const Color(0xFF0D1C32) : const Color(0xFF75777E))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(atriumCenter, 38, atriumPaint);

    // Revision differential highlight (Overlay & Current)
    if (isOverlay || isCurrent) {
      final revisionRect = Rect.fromLTWH(midX + 16, midY + 16, w - midX - 60, h - midY - 60);

      final diffPaint = Paint()
        ..color = const Color(0xFF069669).withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawRect(revisionRect, diffPaint);

      final diffBorder = Paint()
        ..color = const Color(0xFF069669)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawRect(revisionRect, diffBorder);
    }

    // Technical stamp / Coordinate readout
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'ARCHI DRAFT CAD WORKSPACE • REV $revisionNumber\nSCALE 1:100 • DWG MATRIX (0, 0)',
        style: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 8,
          color: Color(0xFF75777E),
          height: 1.3,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(44, h - 64));
  }

  @override
  bool shouldRepaint(covariant _BlueprintWorkspacePainter oldDelegate) {
    return oldDelegate.isCurrent != isCurrent ||
        oldDelegate.isOverlay != isOverlay ||
        oldDelegate.revisionNumber != revisionNumber;
  }
}

// ─────────────────────────────────────────────────────────
// SUBMIT WORKSPACE BUTTON
// ─────────────────────────────────────────────────────────

class _SubmitWorkspaceButton extends ConsumerWidget {
  final String projectId;
  final Project project;
  final Assignment assignment;

  const _SubmitWorkspaceButton({
    required this.projectId,
    required this.project,
    required this.assignment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(projectFilesProvider(projectId));
    final isLoadingAction = ref.watch(draughtsmanActionsControllerProvider).isLoading;
    final status = project.projectStatus ?? ProjectStatus.draft;

    final isUnderReview = status == ProjectStatus.underClientReview;
    final isCompleted = status == ProjectStatus.completed;

    final hasCompletedDrawing = filesAsync.maybeWhen(
      data: (files) => files.any(
        (f) => f.category == 'draughtsman_version',
      ),
      orElse: () => false,
    );

    if (isLoadingAction) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isCompleted) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, size: 16, color: AppColors.success),
        label: const Text('Approved & Completed'),
      );
    }

    if (isUnderReview) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.pending_actions, size: 16),
        label: const Text('Under Review (Locked)'),
      );
    }

    return FilledButton.icon(
      onPressed: hasCompletedDrawing ? () => _showSubmitDialog(context, ref) : null,
      icon: const Icon(Icons.send_rounded, size: 16),
      label: Text(
        assignment.correctionRound != null && assignment.correctionRound! > 0
            ? 'Resubmit Corrected Draft'
            : 'Submit for Review',
      ),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryContainer,
        disabledBackgroundColor: AppColors.surfaceContainerHigh,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  void _showSubmitDialog(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Drawing for Review'),
        content: Text('Submit "${project.projectName}" for client & lead architect review?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      if (!context.mounted) return;

      final success = await ref
          .read(draughtsmanActionsControllerProvider.notifier)
          .submitDrawing(projectId: projectId);

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Drawing submitted successfully for Review!')),
        );
        ref.invalidate(projectProvider(projectId));
        ref.invalidate(draughtsmanAssignmentsProvider);
        ref.invalidate(assignmentProvider(assignment.id));
      }
    });
  }
}

// ─────────────────────────────────────────────────────────
// STYLED WORKSPACE UPLOAD BUTTON
// ─────────────────────────────────────────────────────────

class _StyledWorkspaceUploadButton extends ConsumerWidget {
  final String projectId;
  final String category;

  const _StyledWorkspaceUploadButton({
    required this.projectId,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FileUploadButton(
      projectId: projectId,
      category: category,
    );
  }
}

// ─────────────────────────────────────────────────────────
// TOOLBAR SEGMENT & DETAIL FIELD COMPONENTS
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
              ? const [
                  BoxShadow(
                    color: Color(0x0D0D1C32),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.outline,
          ),
        ),
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _DetailField({required this.label, this.value, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.outline,
            ),
          ),
          const SizedBox(height: 3),
          if (valueWidget != null)
            valueWidget!
          else
            Text(
              value ?? '—',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

class _VersionLogItem extends ConsumerWidget {
  final DrawingVersion version;
  final bool isCurrent;
  final String projectId;

  const _VersionLogItem({
    required this.version,
    required this.isCurrent,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'v${version.versionNumber}.0 ${isCurrent ? '(Current)' : ''}',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isCurrent ? AppColors.primary : AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  DateFormat('MMM d, HH:mm').format(version.createdAt),
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ),
          if (version.fileId.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download_rounded, size: 18),
              color: AppColors.secondary,
              tooltip: 'Download Revision File',
              onPressed: () async {
                final fileName = version.originalName ?? version.sanitizedName ?? 'drawing_v${version.versionNumber}.dwg';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Downloading $fileName...')),
                );
                try {
                  await ref.read(fileRepositoryProvider).downloadFile(version.fileId, fileName);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Download failed: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 2. COLLABORATION HUB TAB
// ─────────────────────────────────────────────────────────

class _CollaborationHubTab extends StatelessWidget {
  final String projectId;
  final Project project;
  final String? assignmentId;

  const _CollaborationHubTab({
    required this.projectId,
    required this.project,
    this.assignmentId,
  });

  @override
  Widget build(BuildContext context) {
    return CollaborationHubView(
      projectId: projectId,
      project: project,
      isEmbedded: true,
      assignmentId: assignmentId,
    );
  }
}


// ─────────────────────────────────────────────────────────
// 3. OVERVIEW & SPECS TAB
// ─────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  final String projectId;
  final Project project;

  const _OverviewTab({required this.projectId, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectCode = project.projectId.length >= 8
        ? 'PRJ-${project.projectId.substring(0, 8).toUpperCase()}'
        : project.projectId;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(projectProvider(projectId));
        ref.invalidate(projectFilesProvider(projectId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionCard(
                  title: 'PROJECT SPECIFICATIONS',
                  child: Column(
                    children: [
                      _InfoRow('Project Code', projectCode),
                      _InfoRow('Project Name', project.projectName.isNotEmpty ? project.projectName : '—'),
                      _InfoRow('Drawing Name', project.drawingName.isNotEmpty ? project.drawingName : '—'),
                      _InfoRow('Project Area', project.projectArea != null ? '${project.projectArea} sq ft' : '—'),
                      _InfoRow('Status', project.projectStatus?.displayName ?? '—'),
                      _InfoRow('Correction Round', 'Round ${project.correctionRound}', isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _SectionCard(
                  title: 'CLIENT REFERENCE FILES',
                  child: _FilesList(
                    projectId: projectId,
                    category: 'client_reference',
                    emptyMessage: 'No reference files attached by client.',
                    ref: ref,
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

// ─────────────────────────────────────────────────────────
// 4. TIMELINE TAB
// ─────────────────────────────────────────────────────────

class _TimelineTab extends ConsumerWidget {
  final String projectId;

  const _TimelineTab({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(projectActivityLogsProvider(projectId));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(projectActivityLogsProvider(projectId)),
          child: logsAsync.when(
            loading: () => const AppLoadingIndicator(message: 'Loading timeline...'),
            error: (e, _) => AppErrorWidget(
              message: 'Failed to load activity: $e',
              onRetry: () => ref.invalidate(projectActivityLogsProvider(projectId)),
            ),
            data: (logs) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: _SectionCard(
                  title: 'ACTIVITY AUDIT',
                  child: logs.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          child: Center(
                            child: AppEmptyState(
                              title: 'No Activity Yet',
                              subtitle: 'Activity will appear here as the project progresses.',
                              icon: Icons.history_rounded,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: logs.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 0),
                          itemBuilder: (context, index) {
                            return _TimelineEvent(
                              log: logs[index],
                              isFirst: index == 0,
                              isLast: index == logs.length - 1,
                            );
                          },
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

String _formatAction(String action) {
  if (action.isEmpty) return 'Action Logged';
  if (action.contains(' ') && action != action.toUpperCase()) {
    return action;
  }
  return action
      .replaceAll('_', ' ')
      .split(' ')
      .where((s) => s.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}

String _formatTimelineDate(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(dt.year, dt.month, dt.day);
  final timeStr = DateFormat('HH:mm').format(dt);

  if (date == today) {
    return 'TODAY, $timeStr';
  } else if (date == today.subtract(const Duration(days: 1))) {
    return 'YESTERDAY, $timeStr';
  } else {
    return '${DateFormat('MMM d').format(dt).toUpperCase()}, $timeStr';
  }
}

class _TimelineEvent extends StatelessWidget {
  final dynamic log;
  final bool isFirst;
  final bool isLast;

  const _TimelineEvent({
    required this.log,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    String action = 'Action Logged';
    String details = '';
    String timeStr = '';

    if (log is Map) {
      action = (log['action'] as String?) ?? (log['action_type'] as String?) ?? 'Action Logged';
      details = (log['details'] as String?) ?? '';
      final createdAt = log['created_at'] ?? log['timestamp'];
      if (createdAt != null) {
        final dt = DateParser.parse(createdAt);
        if (dt != null) {
          timeStr = _formatTimelineDate(dt);
        }
      }
    } else {
      try {
        action = (log.action as String?) ?? 'Action Logged';
      } catch (_) {
        action = 'Action Logged';
      }
      try {
        details = (log.details as String?) ?? '';
      } catch (_) {
        details = '';
      }
      try {
        final createdAt = log.createdAt ?? log.timestamp;
        if (createdAt != null) {
          final dt = createdAt is DateTime ? createdAt : DateParser.parse(createdAt);
          if (dt != null) {
            timeStr = _formatTimelineDate(dt);
          }
        }
      } catch (_) {}
    }

    final formattedAction = _formatAction(action);
    final isComment = details.contains('"') ||
        details.toLowerCase().contains('note:') ||
        details.toLowerCase().contains('comment');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 3),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFirst ? AppColors.primary : AppColors.outlineVariant,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
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
                  if (timeStr.isNotEmpty)
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                        color: AppColors.outline,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    formattedAction,
                    style: AppTypography.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    if (isComment)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(
                            color: AppColors.outlineVariant.withValues(alpha: 0.25),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          details,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      Text(
                        details,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilesList extends StatelessWidget {
  final String projectId;
  final String category;
  final String emptyMessage;
  final WidgetRef ref;

  const _FilesList({
    required this.projectId,
    required this.category,
    required this.emptyMessage,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final filesAsync = ref.watch(projectFilesProvider(projectId));

    return filesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (files) {
        final categoryFiles = files.where((f) => f.category == category).toList();
        if (categoryFiles.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Text(
              emptyMessage,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.outline,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }
        return Column(
          children: categoryFiles.map((f) => _FileTile(file: f, projectId: projectId)).toList(),
        );
      },
    );
  }
}

class _FileTile extends StatelessWidget {
  final ProjectFile file;
  final String projectId;

  const _FileTile({required this.file, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, size: 20, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(file.originalName, style: AppTypography.bodyMd),
          ),
          Text(
            '${(file.size / 1024).toStringAsFixed(1)} KB',
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
              color: AppColors.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
          width: 0.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow(this.label, this.value, {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
            ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 400) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: AppColors.outline,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 160,
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: AppColors.outline,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
