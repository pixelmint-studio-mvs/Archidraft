import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../domain/correction.dart';
import '../../domain/drawing_version.dart';
import '../../domain/project.dart';
import '../../domain/project_status.dart';
import '../../domain/project_file.dart';
import '../../providers/assignment_providers.dart';
import '../../data/file_repository.dart';
import '../../providers/file_providers.dart';
import '../../providers/project_providers.dart';
import '../widgets/project_status_chip.dart';
import '../widgets/file_upload_button.dart';

// ─────────────────────────────────────────────────────────
// WORKSPACE SCREEN
// ─────────────────────────────────────────────────────────

class DraughtsmanWorkspaceScreen extends ConsumerWidget {
  final String projectId;

  const DraughtsmanWorkspaceScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectProvider(projectId));

    return projectAsync.when(
      loading: () => Scaffold(
        appBar: _buildAppBar(context, 'Workspace', null),
        body: const AppLoadingIndicator(message: 'Loading workspace...'),
      ),
      error: (error, _) => Scaffold(
        appBar: _buildAppBar(context, 'Workspace', null),
        body: AppErrorWidget(
          message: 'Failed to load project: $error',
          onRetry: () => ref.invalidate(projectProvider(projectId)),
        ),
      ),
      data: (project) {
        if (project == null) {
          return Scaffold(
            appBar: _buildAppBar(context, 'Workspace', null),
            body: const AppErrorWidget(message: 'Project not found.'),
          );
        }

        final status = project.projectStatus ?? ProjectStatus.draft;

        // Guard: workspace is only accessible when IN_PROGRESS or later active states
        final isAccessible = status == ProjectStatus.inProgress ||
            status == ProjectStatus.underClientReview ||
            status == ProjectStatus.completed;

        if (!isAccessible) {
          return Scaffold(
            appBar: _buildAppBar(context, project.projectName, status),
            body: _WorkspaceLocked(projectName: project.projectName, status: status),
          );
        }

        return _WorkspaceTabs(projectId: projectId, project: project);
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, String? title, ProjectStatus? status) {
    return AppBar(
      backgroundColor: AppColors.surfaceContainerLowest,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title ?? 'Workspace',
            style: AppTypography.buttonText.copyWith(color: AppColors.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (status != null)
            Text(
              status.displayName,
              style: AppTypography.labelMonoSm.copyWith(color: AppColors.onSurfaceVariant),
            ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.canPop() ? context.pop() : context.go('/draughtsman/studio'),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.outlineVariant),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// WORKSPACE LOCKED
// ─────────────────────────────────────────────────────────

class _WorkspaceLocked extends StatelessWidget {
  final String projectName;
  final ProjectStatus status;

  const _WorkspaceLocked({required this.projectName, required this.status});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Icon(Icons.lock_outline_rounded, size: 36, color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Workspace Locked', style: AppTypography.headlineLgMobile),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Accept the assignment to access the workspace for "$projectName".',
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Current status: ${status.displayName}',
              style: AppTypography.labelMonoSm.copyWith(color: AppColors.outline),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: () => context.canPop() ? context.pop() : context.go('/draughtsman/studio'),
              child: const Text('Back to Studio'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TABBED WORKSPACE
// ─────────────────────────────────────────────────────────

class _WorkspaceTabs extends ConsumerStatefulWidget {
  final String projectId;
  final Project project;

  const _WorkspaceTabs({required this.projectId, required this.project});

  @override
  ConsumerState<_WorkspaceTabs> createState() => _WorkspaceTabsState();
}

class _WorkspaceTabsState extends ConsumerState<_WorkspaceTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final status = project.projectStatus ?? ProjectStatus.draft;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              project.projectName.isEmpty ? 'Untitled Project' : project.projectName,
              style: AppTypography.buttonText.copyWith(color: AppColors.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              status.displayName,
              style: AppTypography.labelMonoSm.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/draughtsman/studio'),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: AppTypography.labelMono.copyWith(fontSize: 11),
          unselectedLabelStyle: AppTypography.labelMonoSm,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.secondary,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: 'OVERVIEW'),
            Tab(text: 'DRAWINGS'),
            Tab(text: 'TIMELINE'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(projectId: widget.projectId, project: project),
          _DrawingsTab(projectId: widget.projectId, project: project),
          _TimelineTab(projectId: widget.projectId),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// OVERVIEW TAB
// ─────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  final String projectId;
  final Project project;

  const _OverviewTab({required this.projectId, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final correctionsAsync = ref.watch(projectCorrectionsProvider(projectId));
    final isLoadingAction = ref.watch(draughtsmanActionsControllerProvider).isLoading;
    final status = project.projectStatus ?? ProjectStatus.draft;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(projectProvider(projectId));
        ref.invalidate(projectCorrectionsProvider(projectId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header
            Row(
              children: [
                ProjectStatusChip(status: status),
                if (project.correctionRound > 0) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                    ),
                    child: Text(
                      'REVISION ${project.correctionRound}',
                      style: AppTypography.labelMonoSm.copyWith(
                        color: AppColors.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Active correction alert
            correctionsAsync.maybeWhen(
              data: (corrections) {
                final openCorrections = corrections.where(
                  (c) => c.status == CorrectionStatus.open || c.status == CorrectionStatus.inProgress,
                ).toList();

                if (openCorrections.isEmpty) return const SizedBox.shrink();
                final active = openCorrections.first;
                final isOpen = active.status == CorrectionStatus.open;

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isOpen ? AppColors.errorContainer : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: isOpen ? AppColors.error : AppColors.secondary,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isOpen ? Icons.warning_amber_rounded : Icons.pending_outlined,
                            color: isOpen ? AppColors.error : AppColors.secondary,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'CORRECTION ROUND ${active.roundNumber} — ${active.status.label.toUpperCase()}',
                            style: AppTypography.labelMono.copyWith(
                              color: isOpen ? AppColors.onErrorContainer : AppColors.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        active.description,
                        style: AppTypography.bodyMd.copyWith(
                          color: isOpen ? AppColors.onErrorContainer : AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Requested: ${DateFormat('MMM d, yyyy').format(active.createdAt)}',
                        style: AppTypography.labelMonoSm.copyWith(
                          color: isOpen ? AppColors.onErrorContainer : AppColors.outline,
                        ),
                      ),
                      if (isOpen) ...[
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton.icon(
                          onPressed: isLoadingAction
                              ? null
                              : () => ref.read(draughtsmanActionsControllerProvider.notifier).startCorrection(
                                    projectId: projectId,
                                    correctionId: active.id,
                                  ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 16),
                          label: const Text('Start Working on Correction'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            // Project requirements card
            _SectionCard(
              title: 'PROJECT REQUIREMENTS',
              child: Column(
                children: [
                  _InfoRow('Project Name', project.projectName.isEmpty ? '—' : project.projectName),
                  _InfoRow('Drawing Name', project.drawingName.isEmpty ? '—' : project.drawingName),
                  _InfoRow('Drawing Type', project.drawingTypeEnum?.displayName ?? project.drawingType),
                  _InfoRow(
                    'Area',
                    project.projectArea != null && project.projectArea! > 0
                        ? '${project.projectArea} sq ft'
                        : '—',
                  ),
                  _InfoRow('Address', project.projectAddress.isEmpty ? '—' : project.projectAddress),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Client reference files
            _SectionCard(
              title: 'CLIENT REFERENCE FILES',
              child: _FilesList(
                projectId: projectId,
                category: 'client_upload',
                emptyMessage: 'No reference files attached by client.',
                showUploadButton: false,
                ref: ref,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Submit button (only in IN_PROGRESS)
            if (status == ProjectStatus.inProgress)
              _SubmitButton(projectId: projectId, project: project),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// DRAWINGS TAB
// ─────────────────────────────────────────────────────────

class _DrawingsTab extends ConsumerWidget {
  final String projectId;
  final Project project;

  const _DrawingsTab({required this.projectId, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionsAsync = ref.watch(projectDrawingVersionsProvider(projectId));
    final correctionsAsync = ref.watch(projectCorrectionsProvider(projectId));
    final status = project.projectStatus ?? ProjectStatus.draft;
    final isInProgress = status == ProjectStatus.inProgress;

    final hasOpenCorrection = correctionsAsync.maybeWhen(
      data: (c) => c.any((x) => x.status == CorrectionStatus.open),
      orElse: () => false,
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(projectFilesProvider(projectId));
        ref.invalidate(projectDrawingVersionsProvider(projectId));
        ref.invalidate(projectCorrectionsProvider(projectId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload section (when in progress and no open correction blocking)
            if (isInProgress)
              _SectionCard(
                title: 'UPLOAD DRAWING',
                headerTrailing: Text(
                  'PDF, DWG, DXF, PNG, ZIP — max 50 MB',
                  style: AppTypography.labelMonoSm.copyWith(color: AppColors.outline),
                ),
                child: hasOpenCorrection
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Accept the open correction first, then upload your revised drawing.',
                                style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: SizedBox(
                          width: double.infinity,
                          child: _StyledUploadButton(
                            projectId: projectId,
                            category: 'draughtsman_version',
                          ),
                        ),
                      ),
              ),

            if (isInProgress) const SizedBox(height: AppSpacing.xl),

            // Version history
            _SectionCard(
              title: 'VERSION HISTORY',
              child: versionsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text('Failed to load versions: $e',
                      style: TextStyle(color: AppColors.error)),
                ),
                data: (versions) {
                  if (versions.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: AppEmptyState(
                        title: 'No Drawings Yet',
                        subtitle: 'Upload your first drawing to get started.',
                        icon: Icons.draw_outlined,
                      ),
                    );
                  }
                  return Column(
                    children: versions
                        .map((v) => _VersionCard(version: v, projectId: projectId))
                        .toList(),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Correction attachments (if any)
            correctionsAsync.maybeWhen(
              data: (corrections) {
                if (corrections.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionCard(
                      title: 'CORRECTION ATTACHMENTS',
                      child: _FilesList(
                        projectId: projectId,
                        category: 'correction_attachment',
                        emptyMessage: 'No correction attachments from client.',
                        showUploadButton: false,
                        ref: ref,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TIMELINE TAB
// ─────────────────────────────────────────────────────────

class _TimelineTab extends ConsumerWidget {
  final String projectId;

  const _TimelineTab({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(projectActivityLogsProvider(projectId));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(projectActivityLogsProvider(projectId)),
      child: logsAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Loading timeline...'),
        error: (e, _) => AppErrorWidget(
          message: 'Failed to load activity: $e',
          onRetry: () => ref.invalidate(projectActivityLogsProvider(projectId)),
        ),
        data: (logs) {
          if (logs.isEmpty) {
            return const AppEmptyState(
              title: 'No Activity Yet',
              subtitle: 'Activity will appear here as the project progresses.',
              icon: Icons.timeline_outlined,
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 100),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 0),
            itemBuilder: (context, index) {
              final log = logs[index];
              final isLast = index == logs.length - 1;
              return _TimelineEvent(log: log, isLast: isLast);
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// SUBMIT BUTTON WITH CONFIRMATION DIALOG
// ─────────────────────────────────────────────────────────

class _SubmitButton extends ConsumerWidget {
  final String projectId;
  final Project project;

  const _SubmitButton({required this.projectId, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(projectFilesProvider(projectId));
    final isLoadingAction = ref.watch(draughtsmanActionsControllerProvider).isLoading;

    final hasCompletedDrawing = filesAsync.maybeWhen(
      data: (files) => files.any(
        (f) => f.category == 'draughtsman_version' && f.status == 'COMPLETED',
      ),
      orElse: () => false,
    );

    if (isLoadingAction) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!hasCompletedDrawing)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Upload at least one drawing before you can submit.',
                    style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: hasCompletedDrawing
                ? () => _showSubmitDialog(context, ref)
                : null,
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('Submit for Client Review'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              disabledBackgroundColor: AppColors.surfaceContainerHigh,
            ),
          ),
        ),
      ],
    );
  }

  void _showSubmitDialog(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => _SubmitConfirmationDialog(projectName: project.projectName),
    ).then((confirmed) async {
      if (confirmed != true) return;
      if (!context.mounted) return;

      final success = await ref
          .read(draughtsmanActionsControllerProvider.notifier)
          .submitDrawing(projectId: projectId);

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Drawing submitted successfully for client review!'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(projectProvider(projectId));
        ref.invalidate(draughtsmanAssignmentsProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Submission failed. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });
  }
}

class _SubmitConfirmationDialog extends StatelessWidget {
  final String projectName;

  const _SubmitConfirmationDialog({required this.projectName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      title: Row(
        children: [
          Icon(Icons.send_rounded, color: AppColors.success, size: 22),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(child: Text('Submit for Review')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You are about to submit your drawing for "$projectName" to the client for review.',
            style: AppTypography.bodyMd,
          ),
          const SizedBox(height: AppSpacing.lg),
          _CheckItem('All required drawings have been uploaded'),
          _CheckItem('Drawing meets the project specifications'),
          _CheckItem('Files are complete and in the correct format'),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Once submitted, you cannot upload more files until the client reviews.',
            style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.success),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String text;

  const _CheckItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: AppTypography.bodySm),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// VERSION CARD
// ─────────────────────────────────────────────────────────

class _VersionCard extends ConsumerStatefulWidget {
  final DrawingVersion version;
  final String projectId;

  const _VersionCard({required this.version, required this.projectId});

  @override
  ConsumerState<_VersionCard> createState() => _VersionCardState();
}

class _VersionCardState extends ConsumerState<_VersionCard> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.version;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                'v${v.versionNumber}',
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        v.originalName ?? 'Drawing v${v.versionNumber}',
                        style: AppTypography.buttonText.copyWith(color: AppColors.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (v.correctionId != null)
                      Container(
                        margin: const EdgeInsets.only(left: AppSpacing.sm),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'REVISION',
                          style: AppTypography.labelMonoSm.copyWith(
                            color: AppColors.onErrorContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.outline),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, yyyy HH:mm').format(v.createdAt.toLocal()),
                      style: AppTypography.labelMonoSm.copyWith(color: AppColors.outline),
                    ),
                    if (v.size != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        _formatSize(v.size!),
                        style: AppTypography.labelMonoSm.copyWith(color: AppColors.outline),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _isDownloading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: Icon(Icons.download_rounded, color: AppColors.secondary, size: 20),
                  tooltip: 'Download',
                  onPressed: () => _download(context),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.secondary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                  ),
                ),
        ],
      ),
    );
  }

  void _download(BuildContext context) async {
    setState(() => _isDownloading = true);
    try {
      final repository = ref.read(fileRepositoryProvider);
      final fileName = widget.version.sanitizedName ?? 'download_${widget.version.versionNumber}.pdf';

      if (kIsWeb) {
        await repository.downloadFile(
          widget.version.fileId,
          fileName,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download started in browser')),
        );
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/$fileName';

        await repository.downloadFile(widget.version.fileId, filePath);

        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Downloaded to $filePath')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Download failed: $e')));
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ─────────────────────────────────────────────────────────
// TIMELINE EVENT
// ─────────────────────────────────────────────────────────

class _TimelineEvent extends StatelessWidget {
  final Map<String, dynamic> log;
  final bool isLast;

  const _TimelineEvent({required this.log, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final actionType = log['action_type'] as String? ?? '';
    final details = log['details'] as String? ?? '';
    final actorRole = log['actor_role'] as String? ?? '';
    final timestamp = log['timestamp'] != null
        ? DateTime.tryParse(log['timestamp'] as String)?.toLocal()
        : null;

    final (icon, color) = _iconForAction(actionType);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline spine
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _labelForAction(actionType),
                          style: AppTypography.buttonText.copyWith(color: AppColors.onSurface),
                        ),
                      ),
                      if (actorRole.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          child: Text(
                            actorRole,
                            style: AppTypography.labelMonoSm.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 9,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      details,
                      style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (timestamp != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      DateFormat('MMM d, yyyy • HH:mm').format(timestamp),
                      style: AppTypography.labelMonoSm.copyWith(color: AppColors.outline),
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

  (IconData, Color) _iconForAction(String action) {
    switch (action) {
      case 'ASSIGNMENT_CREATED':
        return (Icons.assignment_ind_outlined, AppColors.secondary);
      case 'ASSIGNMENT_ACCEPTED':
        return (Icons.check_circle_outline, AppColors.success);
      case 'ASSIGNMENT_REJECTED':
        return (Icons.cancel_outlined, AppColors.error);
      case 'FILE_UPLOADED':
        return (Icons.upload_file_outlined, AppColors.secondary);
      case 'DRAWING_SUBMITTED':
        return (Icons.send_outlined, AppColors.primary);
      case 'CORRECTION_REQUESTED':
        return (Icons.redo_outlined, AppColors.warning);
      case 'CORRECTION_STARTED':
        return (Icons.edit_outlined, AppColors.warning);
      case 'DRAWING_APPROVED':
        return (Icons.verified_outlined, AppColors.success);
      case 'PROJECT_COMPLETED':
        return (Icons.celebration_outlined, AppColors.success);
      default:
        return (Icons.circle_outlined, AppColors.onSurfaceVariant);
    }
  }

  String _labelForAction(String action) {
    switch (action) {
      case 'ASSIGNMENT_CREATED':
        return 'Assignment Created';
      case 'ASSIGNMENT_ACCEPTED':
        return 'Assignment Accepted';
      case 'ASSIGNMENT_REJECTED':
        return 'Assignment Rejected';
      case 'FILE_UPLOADED':
        return 'File Uploaded';
      case 'DRAWING_SUBMITTED':
        return 'Drawing Submitted';
      case 'CORRECTION_REQUESTED':
        return 'Correction Requested';
      case 'CORRECTION_STARTED':
        return 'Working on Correction';
      case 'DRAWING_APPROVED':
        return 'Drawing Approved';
      case 'PROJECT_COMPLETED':
        return 'Project Completed';
      default:
        return action.replaceAll('_', ' ').toLowerCase().capitalizeFirst();
    }
  }
}

// ─────────────────────────────────────────────────────────
// FILES LIST — reusable inline file list
// ─────────────────────────────────────────────────────────

class _FilesList extends StatelessWidget {
  final String projectId;
  final String category;
  final String emptyMessage;
  final bool showUploadButton;
  final WidgetRef ref;

  const _FilesList({
    required this.projectId,
    required this.category,
    required this.emptyMessage,
    required this.showUploadButton,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final filesAsync = ref.watch(projectFilesProvider(projectId));

    return filesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text('Error: $e', style: TextStyle(color: AppColors.error)),
      ),
      data: (files) {
        final filtered = files.where((f) => f.category == category).toList();

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              emptyMessage,
              style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
            ),
          );
        }

        return Column(
          children: filtered.map((f) => _StyledFileCard(file: f)).toList(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// STYLED FILE CARD (matches design system)
// ─────────────────────────────────────────────────────────

class _StyledFileCard extends StatelessWidget {
  final ProjectFile file;

  const _StyledFileCard({required this.file});

  @override
  Widget build(BuildContext context) {
    final isCompleted = file.status == 'COMPLETED';
    final ext = file.originalName.split('.').last.toLowerCase();
    final (icon, iconColor) = _iconForExt(ext);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.originalName,
                  style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_formatSize(file.size)} • ${DateFormat('MMM d').format(file.createdAt)}',
                  style: AppTypography.labelMonoSm.copyWith(color: AppColors.outline),
                ),
              ],
            ),
          ),
          if (!isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                file.status,
                style: AppTypography.labelMonoSm.copyWith(
                  color: AppColors.warning,
                  fontSize: 9,
                ),
              ),
            )
          else
            Icon(Icons.download_rounded, size: 20, color: AppColors.secondary),
        ],
      ),
    );
  }

  (IconData, Color) _iconForExt(String ext) {
    switch (ext) {
      case 'pdf':
        return (Icons.picture_as_pdf_outlined, AppColors.error);
      case 'dwg':
      case 'dxf':
        return (Icons.architecture_outlined, AppColors.secondary);
      case 'png':
      case 'jpg':
      case 'jpeg':
        return (Icons.image_outlined, AppColors.primary);
      case 'zip':
        return (Icons.folder_zip_outlined, AppColors.warning);
      default:
        return (Icons.insert_drive_file_outlined, AppColors.onSurfaceVariant);
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ─────────────────────────────────────────────────────────
// STYLED UPLOAD BUTTON (matches design system)
// ─────────────────────────────────────────────────────────

class _StyledUploadButton extends ConsumerStatefulWidget {
  final String projectId;
  final String category;

  const _StyledUploadButton({required this.projectId, required this.category});

  @override
  ConsumerState<_StyledUploadButton> createState() => _StyledUploadButtonState();
}

class _StyledUploadButtonState extends ConsumerState<_StyledUploadButton> {
  @override
  Widget build(BuildContext context) {
    return FileUploadButton(projectId: widget.projectId, category: widget.category);
  }
}

// ─────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? headerTrailing;

  const _SectionCard({required this.title, required this.child, this.headerTrailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusXl),
              ),
              border: Border(
                bottom: BorderSide(color: AppColors.outlineVariant, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.labelMono.copyWith(
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                if (headerTrailing != null) headerTrailing!,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.labelMono.copyWith(
                color: AppColors.outline,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

// String extension for capitalizing the first letter
extension StringCapitalize on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
