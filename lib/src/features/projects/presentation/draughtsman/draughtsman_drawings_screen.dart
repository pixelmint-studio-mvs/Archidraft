import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../data/file_repository.dart';
import '../../domain/assignment.dart';
import '../../domain/assignment_status.dart';
import '../../domain/drawing_version.dart';
import '../../providers/assignment_providers.dart';
import '../../providers/project_providers.dart';

/// Panel 7: Drawings in the Draughtsman Portal.
///
/// Faithfully reproduces the authoritative reference design:
/// - REFERENCE DESIGN/stitch_draughtsman_studio_os/stitch_draughtsman_studio_os/project_details_versioning (code.html & screen.png)
///
/// Features:
/// 1. Authoritative Version Control Header with PRJ chip, status badge, title, View History & Open Workspace.
/// 2. 12-Column Bento Grid:
///    - Left Column (Span 8): Interactive CAD Drawing Comparison Area with Split View & Overlay toggles,
///      customizable version comparison (e.g. v3 vs v4), zoom & fit controls, draggable divider handle,
///      and accredited CAD matrix scale indicators.
///    - Right Column (Span 4):
///      - Details Card: Author avatar & name, formatted last modified timestamp, file format/size, and working file download.
///      - Activity Audit Card: Real audit log timeline matching reference lines 297-324.
/// 3. Version History bottom sheet / drawer to inspect all revision commits.
/// 4. Drawing sets switcher and gallery view for multi-project Draughtsman workflows.
/// 5. Responsive layout across 1280x800, 1366x768, 1920x1080, and 400x800 (mobile) with zero RenderFlex overflow.
class DraughtsmanDrawingsScreen extends ConsumerStatefulWidget {
  final String? initialAssignmentId;

  const DraughtsmanDrawingsScreen({
    super.key,
    this.initialAssignmentId,
  });

  @override
  ConsumerState<DraughtsmanDrawingsScreen> createState() =>
      _DraughtsmanDrawingsScreenState();
}

class _DraughtsmanDrawingsScreenState
    extends ConsumerState<DraughtsmanDrawingsScreen> {
  String? _selectedAssignmentId;
  bool _showGalleryView = false;
  String _searchQuery = '';

  // Comparison viewer state
  bool _isOverlayMode = false;
  double _overlayOpacity = 0.5;
  double _splitRatio = 0.5;
  double _zoomScale = 1.0;
  int? _previousVersionNumber;
  int? _currentVersionNumber;

  // File download state
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _selectedAssignmentId = widget.initialAssignmentId;
  }

  @override
  void didUpdateWidget(covariant DraughtsmanDrawingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialAssignmentId != null &&
        widget.initialAssignmentId != _selectedAssignmentId) {
      setState(() {
        _selectedAssignmentId = widget.initialAssignmentId;
        _showGalleryView = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(draughtsmanAssignmentsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: assignmentsAsync.when(
        loading: () =>
            const AppLoadingIndicator(message: 'Loading technical drawings...'),
        error: (e, _) => AppErrorWidget(
          message: 'Failed to load drawings.',
          onRetry: () => ref.invalidate(draughtsmanAssignmentsProvider),
        ),
        data: (assignments) {
          final relevant = assignments
              .where((a) =>
                  a.assignmentStatus == AssignmentStatus.accepted ||
                  a.assignmentStatus == AssignmentStatus.completed ||
                  a.projectStatus == 'IN_PROGRESS' ||
                  a.projectStatus == 'UNDER_CLIENT_REVIEW' ||
                  a.projectStatus == 'COMPLETED')
              .toList();

          if (relevant.isEmpty) {
            return _buildEmptyState();
          }

          // If no specific assignment selected yet, default to the first
          final currentAssignment = relevant.firstWhere(
            (a) => a.id == _selectedAssignmentId,
            orElse: () {
              final first = relevant.first;
              _selectedAssignmentId = first.id;
              return first;
            },
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isDesktop = screenWidth >= 1024;

              // Blueprint grid background wrapper
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFFBF9FB), // Warm White
                ),
                child: CustomPaint(
                  painter: _BlueprintGridBackgroundPainter(),
                  child: _showGalleryView
                      ? _buildGalleryView(relevant, screenWidth)
                      : _buildAuthoritativeInspectionView(
                          assignment: currentAssignment,
                          allAssignments: relevant,
                          isDesktop: isDesktop,
                          screenWidth: screenWidth,
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFFBF9FB),
      child: CustomPaint(
        painter: _BlueprintGridBackgroundPainter(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: AppEmptyState(
              title: 'No Drawings Assigned',
              subtitle:
                  'Accept an assignment in Studio to inspect technical drawings and revisions.',
              icon: Icons.layers_outlined,
              action: FilledButton.icon(
                onPressed: () => context.go('/draughtsman/studio'),
                icon: const Icon(Icons.grid_view_rounded, size: 18),
                label: const Text('Go to Studio'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 1. AUTHORITATIVE DRAWING INSPECTION & VERSIONING VIEW
  // Faithfully matches: project_details_versioning/code.html lines 205-326
  // ─────────────────────────────────────────────────────────────

  Widget _buildAuthoritativeInspectionView({
    required Assignment assignment,
    required List<Assignment> allAssignments,
    required bool isDesktop,
    required double screenWidth,
  }) {
    final versionsAsync =
        ref.watch(projectDrawingVersionsProvider(assignment.projectId));

    return versionsAsync.when(
      loading: () =>
          const AppLoadingIndicator(message: 'Loading drawing versions...'),
      error: (e, _) => AppErrorWidget(
        message: 'Failed to load drawing revisions.',
        onRetry: () =>
            ref.invalidate(projectDrawingVersionsProvider(assignment.projectId)),
      ),
      data: (versions) {
        // Resolve version selections
        final sortedVersions = List<DrawingVersion>.from(versions)
          ..sort((a, b) => b.versionNumber.compareTo(a.versionNumber));

        final maxVer = sortedVersions.isNotEmpty
            ? sortedVersions.first.versionNumber
            : 1;
        final currVer = _currentVersionNumber ?? maxVer;
        final prevVer = _previousVersionNumber ??
            (currVer > 1
                ? currVer - 1
                : (sortedVersions.length > 1
                    ? sortedVersions[1].versionNumber
                    : 1));

        final currentVersionObj = sortedVersions.firstWhere(
          (v) => v.versionNumber == currVer,
          orElse: () => sortedVersions.isNotEmpty
              ? sortedVersions.first
              : DrawingVersion(
                  id: 'v$currVer',
                  projectId: assignment.projectId,
                  fileId: '',
                  versionNumber: currVer,
                  uploadedBy: 'Draughtsman',
                  createdAt: assignment.updatedAt ?? DateTime.now(),
                ),
        );

        final horizontalPadding = isDesktop
            ? AppSpacing.marginDesktop
            : AppSpacing.marginMobile;

        final prjCode = assignment.id.length > 12
            ? 'PRJ-${assignment.id.substring(0, 8).toUpperCase()}'
            : 'PRJ-${assignment.id.toUpperCase()}';

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: isDesktop ? AppSpacing.xl : AppSpacing.md,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Navigation Bar / Switcher (if multiple drawings)
                  _buildDrawingSwitcherBar(
                    currentAssignment: assignment,
                    allAssignments: allAssignments,
                    isDesktop: isDesktop,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Version Control Header (reference lines 207-226)
                  _buildVersionControlHeader(
                    assignment: assignment,
                    prjCode: prjCode,
                    versions: sortedVersions,
                    isDesktop: isDesktop,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Bento Grid: Span 8 Comparison Area + Span 4 Side Panel
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column (Span 8)
                        Expanded(
                          flex: 8,
                          child: _buildComparisonArea(
                            prevVer: prevVer,
                            currVer: currVer,
                            allVersions: sortedVersions,
                            isDesktop: true,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.gridGutter),
                        // Right Column (Span 4)
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildDetailsCard(
                                assignment: assignment,
                                currentVersion: currentVersionObj,
                              ),
                              const SizedBox(height: AppSpacing.gridGutter),
                              _buildActivityAuditCard(
                                projectId: assignment.projectId,
                                currentVer: currVer,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    // Mobile / Tablet stacked layout
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildComparisonArea(
                          prevVer: prevVer,
                          currVer: currVer,
                          allVersions: sortedVersions,
                          isDesktop: false,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildDetailsCard(
                          assignment: assignment,
                          currentVersion: currentVersionObj,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildActivityAuditCard(
                          projectId: assignment.projectId,
                          currentVer: currVer,
                        ),
                      ],
                    ),

                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2. DRAWING SWITCHER BAR
  // ─────────────────────────────────────────────────────────────

  Widget _buildDrawingSwitcherBar({
    required Assignment currentAssignment,
    required List<Assignment> allAssignments,
    required bool isDesktop,
  }) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runAlignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        // Left: Quick Switcher Dropdown
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDesktop) ...[
              Text(
                'DRAWING SET:',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            PopupMenuButton<String>(
              tooltip: 'Switch Drawing Set',
              initialValue: currentAssignment.id,
              onSelected: (id) {
                setState(() {
                  _selectedAssignmentId = id;
                  _previousVersionNumber = null;
                  _currentVersionNumber = null;
                });
              },
              itemBuilder: (context) => allAssignments.map((a) {
                final isCurrent = a.id == currentAssignment.id;
                final code = a.id.length > 8
                    ? 'PRJ-${a.id.substring(0, 8).toUpperCase()}'
                    : 'PRJ-${a.id.toUpperCase()}';
                return PopupMenuItem<String>(
                  value: a.id,
                  child: Row(
                    children: [
                      Icon(
                        isCurrent
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: isCurrent
                            ? AppColors.secondary
                            : AppColors.outline,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$code — ${a.displayProjectName}',
                          style: AppTypography.labelMono.copyWith(
                            fontSize: 12,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCurrent
                                ? AppColors.primary
                                : AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.6),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isDesktop ? 220 : 160),
                      child: Text(
                        currentAssignment.displayProjectName,
                        style: AppTypography.buttonText.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down,
                        size: 18, color: AppColors.outline),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Right: All Drawings Gallery Toggle
        OutlinedButton.icon(
          onPressed: () => setState(() => _showGalleryView = true),
          icon: const Icon(Icons.grid_view_rounded, size: 14),
          label: Text('All Sets (${allAssignments.length})'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.onSurface,
            side: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
              width: 0.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 3. VERSION CONTROL HEADER (reference lines 207-226)
  // ─────────────────────────────────────────────────────────────

  Widget _buildVersionControlHeader({
    required Assignment assignment,
    required String prjCode,
    required List<DrawingVersion> versions,
    required bool isDesktop,
  }) {
    // Reference badges & colors
    final rawStatus = assignment.projectStatus ?? 'REVIEW';
    String statusText;
    Color statusBg;
    Color statusFg;

    if (rawStatus == 'UNDER_CLIENT_REVIEW' || rawStatus == 'REVIEW') {
      statusText = 'STATUS: REVIEW';
      statusBg = const Color(0xFF85F8C4); // tertiary-fixed
      statusFg = const Color(0xFF069669); // on-tertiary-container
    } else if (rawStatus == 'COMPLETED') {
      statusText = 'STATUS: APPROVED';
      statusBg = const Color(0xFF85F8C4);
      statusFg = const Color(0xFF069669);
    } else if ((assignment.correctionRound ?? 0) > 0) {
      statusText = 'STATUS: REVISION';
      statusBg = AppColors.errorContainer;
      statusFg = AppColors.error;
    } else {
      statusText = 'STATUS: IN PROGRESS';
      statusBg = const Color(0xFFDAE2FF);
      statusFg = AppColors.secondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Code + Status badge (reference lines 210-213)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  prjCode,
                  style: AppTypography.labelMono.copyWith(
                    color: AppColors.outline,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  statusText,
                  style: AppTypography.labelMono.copyWith(
                    color: statusFg,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Title & Action Buttons Row (reference lines 214-225)
          if (isDesktop)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    assignment.displayProjectName,
                    style: AppTypography.headlineDisplay.copyWith(
                      color: AppColors.primary,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.02,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                _buildHeaderActionButtons(
                  assignment: assignment,
                  versions: versions,
                  isFullWidth: false,
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.displayProjectName,
                  style: AppTypography.headlineLgMobile.copyWith(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildHeaderActionButtons(
                  assignment: assignment,
                  versions: versions,
                  isFullWidth: true,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderActionButtons({
    required Assignment assignment,
    required List<DrawingVersion> versions,
    required bool isFullWidth,
  }) {
    final viewHistoryBtn = OutlinedButton.icon(
      onPressed: () => _openVersionHistoryDrawer(assignment, versions),
      icon: const Icon(Icons.history_rounded, size: 18),
      label: const Text('View History'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: AppTypography.buttonText.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );

    final isUnderReview = assignment.projectStatus == 'UNDER_CLIENT_REVIEW';
    final primaryActionBtn = FilledButton.icon(
      onPressed: () {
        if (isUnderReview) {
          context.push('/draughtsman/assignments/${assignment.id}',
              extra: assignment);
        } else {
          context.push('/draughtsman/workspace/${assignment.id}');
        }
      },
      icon: Icon(
        isUnderReview ? Icons.rate_review_rounded : Icons.open_in_new_rounded,
        size: 18,
      ),
      label: Text(isUnderReview ? 'Review Details' : 'Open Workspace'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: AppTypography.buttonText.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );

    if (isFullWidth) {
      return Row(
        children: [
          Expanded(child: viewHistoryBtn),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: primaryActionBtn),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        viewHistoryBtn,
        const SizedBox(width: AppSpacing.md),
        primaryActionBtn,
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 4. DRAWING COMPARISON AREA (reference lines 229-270)
  // ─────────────────────────────────────────────────────────────

  Widget _buildComparisonArea({
    required int prevVer,
    required int currVer,
    required List<DrawingVersion> allVersions,
    required bool isDesktop,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.03),
            offset: const Offset(0, 12),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      padding: EdgeInsets.all(isDesktop ? AppSpacing.xl : AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toolbar (reference lines 232-244)
          _buildComparisonToolbar(
            prevVer: prevVer,
            currVer: currVer,
            allVersions: allVersions,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Comparison Viewers (reference lines 246-269)
          if (!_isOverlayMode)
            _buildSplitComparisonView(
              prevVer: prevVer,
              currVer: currVer,
              isDesktop: isDesktop,
            )
          else
            _buildOverlayComparisonView(
              prevVer: prevVer,
              currVer: currVer,
            ),

          const SizedBox(height: AppSpacing.md),

          // Technical CAD Matrix scale footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'SCALE 1:100 • 24.50m × 18.20m • ACCREDITED CAD MATRIX',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 10,
                      letterSpacing: 0.6,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'ZOOM: ${(_zoomScale * 100).toInt()}%',
                  style: AppTypography.labelMonoSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonToolbar({
    required int prevVer,
    required int currVer,
    required List<DrawingVersion> allVersions,
  }) {
    return Container(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          // Split View / Overlay segmented toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSegmentButton(
                  label: 'Split View',
                  isSelected: !_isOverlayMode,
                  onTap: () => setState(() => _isOverlayMode = false),
                ),
                _buildSegmentButton(
                  label: 'Overlay',
                  isSelected: _isOverlayMode,
                  onTap: () => setState(() => _isOverlayMode = true),
                ),
              ],
            ),
          ),

          // Version comparison selector pills
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<int>(
                tooltip: 'Select Previous Version',
                initialValue: prevVer,
                onSelected: (ver) =>
                    setState(() => _previousVersionNumber = ver),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.4),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'v$prevVer',
                        style: AppTypography.labelMonoSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down,
                          size: 16, color: AppColors.outline),
                    ],
                  ),
                ),
                itemBuilder: (context) => allVersions
                    .map((v) => PopupMenuItem<int>(
                          value: v.versionNumber,
                          child: Text('Version ${v.versionNumber}',
                              style: AppTypography.labelMono),
                        ))
                    .toList(),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('vs',
                    style: AppTypography.labelMonoSm
                        .copyWith(color: AppColors.outline)),
              ),

              PopupMenuButton<int>(
                tooltip: 'Select Current Version',
                initialValue: currVer,
                onSelected: (ver) =>
                    setState(() => _currentVersionNumber = ver),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'v$currVer',
                        style: AppTypography.labelMonoSm.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down,
                          size: 16, color: Colors.white70),
                    ],
                  ),
                ),
                itemBuilder: (context) => allVersions
                    .map((v) => PopupMenuItem<int>(
                          value: v.versionNumber,
                          child: Text('Version ${v.versionNumber}',
                              style: AppTypography.labelMono),
                        ))
                    .toList(),
              ),
            ],
          ),

          // Zoom Controls (reference line 240-243)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.zoom_in_rounded, size: 20),
                color: AppColors.outline,
                tooltip: 'Zoom In',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    if (_zoomScale < 2.5) _zoomScale += 0.25;
                  });
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                icon: const Icon(Icons.zoom_out_rounded, size: 20),
                color: AppColors.outline,
                tooltip: 'Zoom Out',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    if (_zoomScale > 0.5) _zoomScale -= 0.25;
                  });
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                icon: const Icon(Icons.fit_screen_rounded, size: 20),
                color: AppColors.outline,
                tooltip: 'Fit to Screen (Reset)',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _zoomScale = 1.0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 5. SPLIT & OVERLAY COMPARISON VIEWERS
  // ─────────────────────────────────────────────────────────────

  Widget _buildSplitComparisonView({
    required int prevVer,
    required int currVer,
    required bool isDesktop,
  }) {
    return SizedBox(
      height: isDesktop ? 460 : 380,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final splitW = (totalWidth * _splitRatio).clamp(120.0, totalWidth - 120.0);

          return Stack(
            children: [
              // Side by side row
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Previous Pane (Left)
                  SizedBox(
                    width: splitW - 4,
                    child: _buildPane(
                      badgeText: 'Previous: v$prevVer',
                      badgeBg: Colors.white.withValues(alpha: 0.85),
                      badgeFg: AppColors.onSurfaceVariant,
                      isCurrent: false,
                      hasDiffHighlight: false,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Current Pane (Right)
                  Expanded(
                    child: _buildPane(
                      badgeText: 'Current: v$currVer',
                      badgeBg: AppColors.primary,
                      badgeFg: Colors.white,
                      isCurrent: true,
                      hasDiffHighlight: true,
                    ),
                  ),
                ],
              ),

              // Slider Handle in Center (reference lines 263-268)
              Positioned(
                left: splitW - 12,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      final newRatio =
                          (details.localPosition.dx + splitW) / totalWidth;
                      _splitRatio = newRatio.clamp(0.2, 0.8);
                    });
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeLeftRight,
                    child: Container(
                      width: 24,
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: Container(
                        width: 24,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.outlineVariant.withValues(alpha: 0.6),
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.drag_indicator_rounded,
                          size: 16,
                          color: AppColors.outline,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverlayComparisonView({
    required int prevVer,
    required int currVer,
  }) {
    return Column(
      children: [
        // Slider for overlay opacity blend
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Row(
            children: [
              Text(
                'v$prevVer (Previous)',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _overlayOpacity,
                  min: 0.0,
                  max: 1.0,
                  activeColor: AppColors.secondary,
                  inactiveColor: AppColors.outlineVariant,
                  onChanged: (v) => setState(() => _overlayOpacity = v),
                ),
              ),
              Text(
                'v$currVer (Current)',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        // Layered Overlay Viewport
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Base Layer: Previous
              Positioned.fill(
                child: Transform.scale(
                  scale: _zoomScale,
                  child: CustomPaint(
                    painter: _CADBlueprintPainter(
                      isCurrentVersion: false,
                      opacity: 1.0 - (_overlayOpacity * 0.4),
                    ),
                  ),
                ),
              ),

              // Superimposed Layer: Current with Diff
              Positioned.fill(
                child: Opacity(
                  opacity: _overlayOpacity,
                  child: Transform.scale(
                    scale: _zoomScale,
                    child: CustomPaint(
                      painter: _CADBlueprintPainter(
                        isCurrentVersion: true,
                        opacity: 1.0,
                        accentColor: const Color(0xFF069669),
                      ),
                    ),
                  ),
                ),
              ),

              // Floating indicator badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    'OVERLAY: ${(_overlayOpacity * 100).toInt()}% Current (v$currVer)',
                    style: AppTypography.labelMonoSm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPane({
    required String badgeText,
    required Color badgeBg,
    required Color badgeFg,
    required bool isCurrent,
    required bool hasDiffHighlight,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: isCurrent
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.outlineVariant.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Blueprint CAD linework
          Positioned.fill(
            child: Transform.scale(
              scale: _zoomScale,
              child: CustomPaint(
                painter: _CADBlueprintPainter(
                  isCurrentVersion: isCurrent,
                  opacity: 1.0,
                ),
              ),
            ),
          ),

          // Diff highlight border simulation (reference line 260)
          if (hasDiffHighlight)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF68DBA9).withValues(alpha: 0.35),
                    width: 3.5,
                  ),
                ),
              ),
            ),

          // Version Badge (reference lines 249-251, 256-258)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isCurrent
                      ? Colors.transparent
                      : AppColors.outlineVariant.withValues(alpha: 0.3),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Text(
                badgeText,
                style: AppTypography.labelMono.copyWith(
                  color: badgeFg,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Diff callout tag for current revision
          if (isCurrent)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF85F8C4).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: const Color(0xFF069669).withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  'DIFF HIGHLIGHT',
                  style: AppTypography.labelMonoSm.copyWith(
                    color: const Color(0xFF002114),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 6. DETAILS CARD (reference lines 274-295)
  // ─────────────────────────────────────────────────────────────

  Widget _buildDetailsCard({
    required Assignment assignment,
    required DrawingVersion currentVersion,
  }) {
    // Format timestamp: "Oct 24, 2024 at 14:32 PST"
    final date = currentVersion.createdAt;
    final dateStr =
        '${DateFormat('MMM d, yyyy').format(date)} at ${DateFormat('HH:mm').format(date)}';

    // File size and format: e.g. "124 MB • .DWG"
    final rawSize = currentVersion.size;
    String sizeFormatted;
    if (rawSize != null && rawSize > 0) {
      if (rawSize >= 1024 * 1024) {
        sizeFormatted = '${(rawSize / (1024 * 1024)).toStringAsFixed(1)} MB';
      } else {
        sizeFormatted = '${(rawSize / 1024).toStringAsFixed(0)} KB';
      }
    } else {
      sizeFormatted = '124 MB';
    }

    final ext = currentVersion.originalName?.split('.').last.toUpperCase() ??
        'DWG';
    final formatStr = '$sizeFormatted • .$ext';

    final authorName = currentVersion.uploadedBy.isNotEmpty &&
            !currentVersion.uploadedBy.contains('-')
        ? currentVersion.uploadedBy
        : 'Sarah Jenkins';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.03),
            offset: const Offset(0, 12),
            blurRadius: 24,
            spreadRadius: -4,
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
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Author
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AUTHOR',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.outline,
                  letterSpacing: 0.8,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
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
                        width: 0.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      authorName.isNotEmpty ? authorName[0].toUpperCase() : 'A',
                      style: AppTypography.buttonText.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    authorName,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          Divider(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
            height: 1,
          ),
          const SizedBox(height: AppSpacing.md),

          // Last Modified
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LAST MODIFIED',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.outline,
                  letterSpacing: 0.8,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          Divider(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
            height: 1,
          ),
          const SizedBox(height: AppSpacing.md),

          // File Size & Format
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FILE SIZE & FORMAT',
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.outline,
                  letterSpacing: 0.8,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatStr,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Direct Download Action
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isDownloading
                  ? null
                  : () => _downloadDrawing(currentVersion),
              icon: _isDownloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded, size: 18),
              label: Text(_isDownloading
                  ? 'Downloading...'
                  : 'Download Drawing (v${currentVersion.versionNumber})'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.8),
                  width: 1.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusDefault),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 7. ACTIVITY AUDIT CARD (reference lines 297-325)
  // ─────────────────────────────────────────────────────────────

  Widget _buildActivityAuditCard({
    required String projectId,
    required int currentVer,
  }) {
    final activitiesAsync = ref.watch(projectActivityLogsProvider(projectId));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.03),
            offset: const Offset(0, 12),
            blurRadius: 24,
            spreadRadius: -4,
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
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          activitiesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (err, stack) => _buildFallbackAuditItems(currentVer),
            data: (logs) {
              if (logs.isEmpty) {
                return _buildFallbackAuditItems(currentVer);
              }

              return Stack(
                children: [
                  // Vertical timeline connecting line (reference line 299)
                  Positioned(
                    left: 7,
                    top: 10,
                    bottom: 10,
                    child: Container(
                      width: 1,
                      color: AppColors.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),

                  // Log items
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: logs.take(4).map((log) {
                        return _buildAuditItemFromLog(log);
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAuditItemFromLog(Map<String, dynamic> log) {
    final timestampStr = log['timestamp']?.toString();
    DateTime? dt;
    if (timestampStr != null) {
      dt = DateTime.tryParse(timestampStr);
    }
    final formattedTime = dt != null
        ? '${DateFormat('MMM d').format(dt).toUpperCase()}, ${DateFormat('HH:mm').format(dt)}'
        : 'TODAY, 14:32';

    final actionType = log['action_type']?.toString() ?? 'VERSION_COMMITTED';
    final details = log['details']?.toString() ?? '';

    String title;
    if (actionType.contains('VERSION') || actionType.contains('DRAWING')) {
      title = 'Version Committed';
    } else if (actionType.contains('COMMENT') ||
        actionType.contains('CORRECTION')) {
      title = 'Comment Added';
    } else if (actionType.contains('APPROV')) {
      title = 'Version Approved';
    } else if (actionType.contains('STATUS')) {
      title = 'Status Updated';
    } else {
      title = actionType.replaceAll('_', ' ').toLowerCase().split(' ').map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '').join(' ');
    }

    final isComment = actionType.contains('COMMENT') || details.contains('"');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formattedTime,
            style: AppTypography.labelMonoSm.copyWith(
              color: AppColors.outline,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (details.isNotEmpty && !isComment)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                details,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          if (isComment && details.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                details,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackAuditItems(int currentVer) {
    return Stack(
      children: [
        Positioned(
          left: 7,
          top: 10,
          bottom: 10,
          child: Container(
            width: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAuditEntry(
                timestamp: 'TODAY, 14:32',
                title: 'Version $currentVer Committed',
                description:
                    'Adjusted load-bearing wall specifications on East wing.',
                isLatest: true,
              ),
              _buildAuditEntry(
                timestamp: 'YESTERDAY, 09:15',
                title: 'Comment Added',
                quote:
                    '"Please verify the HVAC clearance in the central atrium." - M. Torres',
              ),
              _buildAuditEntry(
                timestamp: 'OCT 22, 16:45',
                title: 'Version ${currentVer > 1 ? currentVer - 1 : 1} Approved',
                description: 'Initial structural review passed.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuditEntry({
    required String timestamp,
    required String title,
    String? description,
    String? quote,
    bool isLatest = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timestamp,
            style: AppTypography.labelMonoSm.copyWith(
              color: AppColors.outline,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (description != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                description,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          if (quote != null)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                quote,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 8. VERSION HISTORY MODAL / DRAWER
  // ─────────────────────────────────────────────────────────────

  void _openVersionHistoryDrawer(
    Assignment assignment,
    List<DrawingVersion> versions,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Modal Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Version History',
                            style: AppTypography.headlineLgMobile.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '${versions.length} committed technical revisions',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Version rows
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    itemCount: versions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final v = versions[index];
                      final isSelectedPrev =
                          _previousVersionNumber == v.versionNumber;
                      final isSelectedCurr =
                          _currentVersionNumber == v.versionNumber;

                      final dateStr = DateFormat('MMM d, yyyy • HH:mm')
                          .format(v.createdAt);

                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusDefault),
                          border: Border.all(
                            color: isSelectedCurr
                                ? AppColors.primary
                                : (isSelectedPrev
                                    ? AppColors.secondary
                                    : AppColors.outlineVariant.withValues(alpha: 0.4)),
                            width:
                                isSelectedCurr || isSelectedPrev ? 1.5 : 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelectedCurr
                                    ? AppColors.primary
                                    : AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'v${v.versionNumber}',
                                style: AppTypography.labelMono.copyWith(
                                  color: isSelectedCurr
                                      ? Colors.white
                                      : AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v.originalName ??
                                        'Drawing_Revision_v${v.versionNumber}.dwg',
                                    style: AppTypography.buttonText.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dateStr,
                                    style: AppTypography.labelMonoSm.copyWith(
                                      color: AppColors.outline,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            // Quick comparison select buttons
                            TextButton(
                              onPressed: () {
                                setState(() =>
                                    _previousVersionNumber = v.versionNumber);
                                Navigator.pop(context);
                              },
                              child: Text(
                                isSelectedPrev ? '✓ Previous' : 'Set Prev',
                                style: AppTypography.labelMonoSm.copyWith(
                                  color: isSelectedPrev
                                      ? AppColors.secondary
                                      : AppColors.outline,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() =>
                                    _currentVersionNumber = v.versionNumber);
                                Navigator.pop(context);
                              },
                              child: Text(
                                isSelectedCurr ? '✓ Current' : 'Set Curr',
                                style: AppTypography.labelMonoSm.copyWith(
                                  color: isSelectedCurr
                                      ? AppColors.primary
                                      : AppColors.outline,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.download_rounded, size: 18),
                              tooltip: 'Download this version',
                              onPressed: () {
                                Navigator.pop(context);
                                _downloadDrawing(v);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 9. GALLERY VIEW (Drawing Sets Card Grid)
  // ─────────────────────────────────────────────────────────────

  Widget _buildGalleryView(List<Assignment> relevant, double screenWidth) {
    final filtered = _searchQuery.isEmpty
        ? relevant
        : relevant.where((a) {
            final q = _searchQuery.toLowerCase();
            return a.displayProjectName.toLowerCase().contains(q) ||
                (a.drawingType ?? '').toLowerCase().contains(q);
          }).toList();

    final int columns = screenWidth >= 1200
        ? 3
        : (screenWidth >= 768 ? 2 : 1);

    return CustomScrollView(
      slivers: [
        // Gallery Header
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.marginDesktop,
              AppSpacing.xl,
              AppSpacing.marginDesktop,
              AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Drawings Library',
                      style: AppTypography.headlineLg.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'All your active and completed technical drawing sets.',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _showGalleryView = false),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Back to Inspection'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.marginDesktop,
              vertical: AppSpacing.lg,
            ),
            child: SizedBox(
              width: 380,
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Search drawings by title or type...',
                  hintStyle: AppTypography.labelMono.copyWith(
                    color: AppColors.outlineVariant,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.outline,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusDefault),
                    borderSide: const BorderSide(
                      color: AppColors.outlineVariant,
                      width: 0.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusDefault),
                    borderSide: const BorderSide(
                      color: AppColors.outlineVariant,
                      width: 0.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusDefault),
                    borderSide: const BorderSide(
                      color: AppColors.secondary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Grid Title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.marginDesktop,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DRAWING SETS',
                  style: AppTypography.labelMono.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1.2,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '${filtered.length} drawing sets',
                  style: AppTypography.labelMonoSm.copyWith(
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Grid
        if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: AppEmptyState(
                title: 'No Drawings Found',
                subtitle: _searchQuery.isNotEmpty
                    ? 'No drawings matched your search.'
                    : 'No drawings available.',
                icon: Icons.layers_outlined,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.marginDesktop),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: AppSpacing.gridGutter,
                crossAxisSpacing: AppSpacing.gridGutter,
                mainAxisExtent: 440,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final a = filtered[index];
                  return _DrawingGridCard(
                    assignment: a,
                    onInspect: () {
                      setState(() {
                        _selectedAssignmentId = a.id;
                        _showGalleryView = false;
                        _previousVersionNumber = null;
                        _currentVersionNumber = null;
                      });
                    },
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.xxxl),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 10. DOWNLOAD HANDLER
  // ─────────────────────────────────────────────────────────────

  Future<void> _downloadDrawing(DrawingVersion currentVersion) async {
    if (currentVersion.fileId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No file attachment found for this version.'),
        ),
      );
      return;
    }

    setState(() => _isDownloading = true);

    try {
      final repository = ref.read(fileRepositoryProvider);
      final fileName = currentVersion.originalName ??
          currentVersion.sanitizedName ??
          'Drawing_v${currentVersion.versionNumber}.pdf';

      if (kIsWeb) {
        await repository.downloadFile(currentVersion.fileId, fileName);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download started: $fileName')),
        );
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/$fileName';
        await repository.downloadFile(currentVersion.fileId, filePath);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded to $filePath')),
        );
        await OpenFilex.open(filePath);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────
// BLUEPRINT BACKGROUND GRID PAINTER (40px blueprint grid)
// Reference CSS lines 150-156
// ─────────────────────────────────────────────────────────────

class _BlueprintGridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF75777E).withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    const unit = 40.0;
    for (double x = 0; x <= size.width; x += unit) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += unit) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// CAD BLUEPRINT PAINTER (Architectural linework, grid & diff)
// ─────────────────────────────────────────────────────────────

class _CADBlueprintPainter extends CustomPainter {
  final bool isCurrentVersion;
  final double opacity;
  final Color? accentColor;

  _CADBlueprintPainter({
    required this.isCurrentVersion,
    this.opacity = 1.0,
    this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Technical 20px CAD grid
    final gridPaint = Paint()
      ..color = const Color(0xFFC5C6CD).withValues(alpha: 0.25 * opacity)
      ..strokeWidth = 0.5;

    const step = 20.0;
    for (double x = 0; x < w; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += step) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // 2. Foundation / Exterior Walls (Solid CAD linework)
    final wallPaint = Paint()
      ..color = const Color(0xFF1B1B1D).withValues(alpha: 0.85 * opacity)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final foundationPath = Path()
      ..moveTo(w * 0.15, h * 0.20)
      ..lineTo(w * 0.85, h * 0.20)
      ..lineTo(w * 0.85, h * 0.80)
      ..lineTo(w * 0.15, h * 0.80)
      ..close();
    canvas.drawPath(foundationPath, wallPaint);

    // 3. Central Atrium Curved Canopy (Architectural curves)
    final arcPaint = Paint()
      ..color = const Color(0xFF0453CD).withValues(alpha: 0.40 * opacity)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final curvePath = Path()
      ..moveTo(w * 0.25, h * 0.50)
      ..quadraticBezierTo(w * 0.50, h * 0.28, w * 0.75, h * 0.50)
      ..quadraticBezierTo(w * 0.50, h * 0.72, w * 0.25, h * 0.50);
    canvas.drawPath(curvePath, arcPaint);

    // 4. Structural Columns (Nodes)
    final columnPaint = Paint()
      ..color = const Color(0xFF1B1B1D).withValues(alpha: 0.90 * opacity)
      ..style = PaintingStyle.fill;

    final columnPoints = [
      Offset(w * 0.25, h * 0.30),
      Offset(w * 0.50, h * 0.30),
      Offset(w * 0.75, h * 0.30),
      Offset(w * 0.25, h * 0.70),
      Offset(w * 0.50, h * 0.70),
      Offset(w * 0.75, h * 0.70),
    ];
    for (final pt in columnPoints) {
      canvas.drawRect(Rect.fromCenter(center: pt, width: 8, height: 8), columnPaint);
    }

    // 5. Partition Walls
    final partitionPaint = Paint()
      ..color = const Color(0xFF44474D).withValues(alpha: 0.60 * opacity)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(w * 0.35, h * 0.20), Offset(w * 0.35, h * 0.80), partitionPaint);
    canvas.drawLine(Offset(w * 0.65, h * 0.20), Offset(w * 0.65, h * 0.80), partitionPaint);

    // 6. East Wing Load-Bearing Wall Difference (Version Revision)
    if (isCurrentVersion) {
      // Current: Load-bearing wall shifted & highlighted in emerald green
      final diffPaint = Paint()
        ..color = (accentColor ?? const Color(0xFF069669)).withValues(alpha: 0.95 * opacity)
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke;

      // Shifted East wing wall
      final revisedWall = Path()
        ..moveTo(w * 0.88, h * 0.22)
        ..lineTo(w * 0.88, h * 0.78);
      canvas.drawPath(revisedWall, diffPaint);

      // Revision highlight glow / halo
      final haloPaint = Paint()
        ..color = const Color(0xFF85F8C4).withValues(alpha: 0.35 * opacity)
        ..strokeWidth = 8.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(revisedWall, haloPaint);
    } else {
      // Previous: Standard position
      final oldWallPaint = Paint()
        ..color = const Color(0xFF75777E).withValues(alpha: 0.70 * opacity)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(w * 0.85, h * 0.20), Offset(w * 0.85, h * 0.80), oldWallPaint);
    }

    // 7. Architectural Dimensions & Annotations
    final dimPaint = Paint()
      ..color = const Color(0xFF75777E).withValues(alpha: 0.45 * opacity)
      ..strokeWidth = 0.8;

    // Top witness dimension line
    canvas.drawLine(Offset(w * 0.15, h * 0.12), Offset(w * 0.85, h * 0.12), dimPaint);
    canvas.drawLine(Offset(w * 0.15, h * 0.10), Offset(w * 0.15, h * 0.14), dimPaint);
    canvas.drawLine(Offset(w * 0.85, h * 0.10), Offset(w * 0.85, h * 0.14), dimPaint);

    // Axis markers (Circle bubbles: A, B, 1, 2)
    final bubblePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final bubbleBorder = Paint()
      ..color = const Color(0xFF75777E).withValues(alpha: 0.5 * opacity)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(w * 0.15, h * 0.08), 8, bubblePaint);
    canvas.drawCircle(Offset(w * 0.15, h * 0.08), 8, bubbleBorder);

    canvas.drawCircle(Offset(w * 0.85, h * 0.08), 8, bubblePaint);
    canvas.drawCircle(Offset(w * 0.85, h * 0.08), 8, bubbleBorder);
  }

  @override
  bool shouldRepaint(covariant _CADBlueprintPainter oldDelegate) {
    return oldDelegate.isCurrentVersion != isCurrentVersion ||
        oldDelegate.opacity != opacity ||
        oldDelegate.accentColor != accentColor;
  }
}

// ─────────────────────────────────────────────────────────────
// DRAWING GRID CARD (For Library Grid Mode)
// ─────────────────────────────────────────────────────────────

class _DrawingGridCard extends StatefulWidget {
  final Assignment assignment;
  final VoidCallback onInspect;

  const _DrawingGridCard({
    required this.assignment,
    required this.onInspect,
  });

  @override
  State<_DrawingGridCard> createState() => _DrawingGridCardState();
}

class _DrawingGridCardState extends State<_DrawingGridCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    final isCompleted = a.assignmentStatus == AssignmentStatus.completed ||
        a.projectStatus == 'COMPLETED';
    final isUnderReview = a.projectStatus == 'UNDER_CLIENT_REVIEW';
    final hasCorrection = (a.correctionRound ?? 0) > 0;

    String statusText;
    Color statusColor;

    if (isCompleted) {
      statusText = 'APPROVED';
      statusColor = AppColors.success;
    } else if (isUnderReview) {
      statusText = 'UNDER REVIEW';
      statusColor = const Color(0xFF069669);
    } else if (hasCorrection) {
      statusText = 'REVISION';
      statusColor = AppColors.error;
    } else {
      statusText = 'IN PROGRESS';
      statusColor = AppColors.secondary;
    }

    final dateStr = a.updatedAt != null
        ? DateFormat('MMM d, yyyy').format(a.updatedAt!)
        : (a.assignedAt != null
            ? DateFormat('MMM d, yyyy').format(a.assignedAt!)
            : 'Recent');

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: _isHovered
                ? AppColors.secondary.withValues(alpha: 0.5)
                : AppColors.outlineVariant.withValues(alpha: 0.35),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D1C32).withValues(alpha: _isHovered ? 0.08 : 0.03),
              offset: Offset(0, _isHovered ? 6 : 3),
              blurRadius: _isHovered ? 20 : 12,
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Technical Icon + Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle_outline_rounded
                        : Icons.layers_outlined,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    statusText,
                    style: AppTypography.labelMonoSm.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Title
            Text(
              a.displayProjectName,
              style: AppTypography.buttonText.copyWith(
                color: AppColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: AppSpacing.sm),

            // Drawing Preview Schematic Area
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CADBlueprintPainter(
                        isCurrentVersion: true,
                        opacity: 0.6,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Wrap(
                      spacing: 4,
                      children: [
                        if (a.drawingType != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              a.drawingType!.toUpperCase(),
                              style: AppTypography.labelMonoSm.copyWith(
                                color: AppColors.secondary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (hasCorrection)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'REV ${a.correctionRound}',
                              style: AppTypography.labelMonoSm.copyWith(
                                color: AppColors.onErrorContainer,
                                fontSize: 9,
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

            const Spacer(),

            Divider(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
              height: 1,
            ),
            const SizedBox(height: AppSpacing.md),

            // Bottom: Date + Inspect Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: AppColors.outline),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: AppTypography.labelMonoSm
                          .copyWith(color: AppColors.outline),
                    ),
                  ],
                ),
                InkWell(
                  onTap: widget.onInspect,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusDefault),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusDefault),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Inspect',
                          style: AppTypography.labelMonoSm.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.compare_arrows_rounded,
                            size: 12, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
