import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../../training/providers/training_providers.dart';
import '../../data/file_repository.dart';
import '../../domain/correction.dart';
import '../../domain/drawing_version.dart';
import '../../domain/project.dart';
import '../../domain/project_file.dart';
import '../../domain/project_status.dart';
import '../../providers/assignment_providers.dart';
import '../../providers/file_providers.dart';
import '../../providers/project_providers.dart';
import '../widgets/file_attachment_card.dart';
import '../widgets/file_upload_button.dart';
import 'widgets/evaluation_card.dart';
import '../widgets/cad_drawing_viewer.dart';

/// Workspace screen for a student working on an assigned training project.
///
/// Presents five distinct workflow states:
/// A. Waiting Acceptance — Assignment brief, requirements, reference files, allocation summary, and Accept Assignment CTA.
/// B. First Attempt — Assignment brief, requirements, reference files, draft upload, and initial submission CTA.
/// C. Revision Required — Active ADMIN correction instructions, evaluation rubric/feedback, version history, and revised resubmission.
/// D. Awaiting Review — Explanation that submission awaits ADMIN review, submitted drawing version, and disabled edit controls.
/// E. Approved / Completed — Authoritative completion status, final approved drawing download, evaluation rubric, and disabled edit controls.
class StudentProjectWorkspaceScreen extends ConsumerStatefulWidget {
  final String projectId;

  const StudentProjectWorkspaceScreen({super.key, required this.projectId});

  @override
  ConsumerState<StudentProjectWorkspaceScreen> createState() =>
      _StudentProjectWorkspaceScreenState();
}

class _StudentProjectWorkspaceScreenState
    extends ConsumerState<StudentProjectWorkspaceScreen> {
  void _showDrawingPreviewDialog(BuildContext context, String fileId, String fileName, int versionNumber) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        backgroundColor: const Color(0xFF07111E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 860,
          height: 560,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                color: const Color(0xFF0B192C),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.architecture_rounded,
                          color: Color(0xFF00E5FF),
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Preview: $fileName',
                          style: AppTypography.headlineSmMobile.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    IconButton(
                      key: const ValueKey('close_cad_preview_dialog'),
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      tooltip: 'Close Preview',
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CadDrawingViewer(
                  fileId: fileId,
                  fileName: fileName,
                  versionNumber: versionNumber,
                  height: 500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isAccepting = false;
  String? _acceptanceError;
  bool _locallyAccepted = false;
  bool _isSubmitting = false;
  String? _submissionError;

  String? _selectedDrawingFileId;
  String? _selectedDrawingFileName;
  int _selectedDrawingVersionNumber = 1;

  bool _isCadFile(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return ext == 'dwg' || ext == 'dxf';
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectProvider(widget.projectId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Project Workspace',
          style: AppTypography.buttonText.copyWith(color: AppColors.onSurface),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/student/projects');
            }
          },
        ),
      ),
      body: projectAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Loading workspace...'),
        error: (error, _) => AppErrorWidget(
          message: 'Failed to load workspace.',
          onRetry: () => ref.invalidate(projectProvider(widget.projectId)),
        ),
        data: (project) {
          if (project == null) {
            return const AppErrorWidget(message: 'Project not found.');
          }
          return _buildWorkspace(context, ref, project);
        },
      ),
    );
  }

  Future<void> _handleAcceptAssignment(Project project) async {
    if (_isAccepting) return;

    setState(() {
      _isAccepting = true;
      _acceptanceError = null;
    });

    try {
      final success = await ref
          .read(draughtsmanActionsControllerProvider.notifier)
          .acceptAssignment(
            assignmentId: project.currentAssignmentId ?? project.projectId,
            projectId: project.projectId,
          );

      if (!mounted) return;

      if (success) {
        setState(() {
          _isAccepting = false;
          _locallyAccepted = true;
        });
        ref.invalidate(projectProvider(project.projectId));
        ref.invalidate(studentAssignmentsProvider);
        ref.invalidate(draughtsmanAssignmentsProvider);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Practical assignment accepted! Workspace is now active.'),
            backgroundColor: AppColors.secondary,
          ),
        );
      } else {
        setState(() {
          _isAccepting = false;
          _acceptanceError = 'Failed to accept practical assignment. Please retry.';
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept practical assignment. Please retry.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAccepting = false;
        _acceptanceError = 'Error: $e';
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildWorkspace(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) {
    final rawStatus = project.projectStatus ?? ProjectStatus.draft;
    final status = _locallyAccepted && rawStatus == ProjectStatus.waitingAcceptance
        ? ProjectStatus.inProgress
        : rawStatus;
    final correctionRound = project.correctionRound;

    final filesAsync = ref.watch(projectFilesProvider(project.projectId));
    final versionsAsync = ref.watch(projectDrawingVersionsProvider(project.projectId));
    final correctionsAsync = ref.watch(projectCorrectionsProvider(project.projectId));
    final evaluationsAsync = ref.watch(projectEvaluationsProvider(project.projectId));

    final corrections = correctionsAsync.value ?? [];
    final activeCorrection = _findActiveCorrection(corrections);
    final resolvedCorrections = corrections.where((c) => c.status == CorrectionStatus.resolved).toList();

    // Determine the UX states
    final bool isWaitingAcceptance = status == ProjectStatus.waitingAcceptance;
    final bool isCompleted = status == ProjectStatus.completed;
    final bool isUnderReview = status == ProjectStatus.underClientReview || status == ProjectStatus.submitted;
    final bool isRevisionRequired = status == ProjectStatus.inProgress && (activeCorrection != null || correctionRound > 0);
    final bool isFirstAttempt = status == ProjectStatus.inProgress && !isRevisionRequired;
    final bool isRejected = status == ProjectStatus.cancelled;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Status & Metadata
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildStateBadge(
                      isWaitingAcceptance: isWaitingAcceptance,
                      isCompleted: isCompleted,
                      isUnderReview: isUnderReview,
                      isRevisionRequired: isRevisionRequired,
                      isFirstAttempt: isFirstAttempt,
                      isRejected: isRejected,
                      roundNumber: activeCorrection?.roundNumber ?? correctionRound,
                    ),
                  ],
                ),
                if (project.createdAt != null)
                  Text(
                    DateFormat('MMM d, yyyy').format(project.createdAt!),
                    style: AppTypography.labelMono.copyWith(color: AppColors.outline),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            project.projectName.isEmpty ? 'Untitled Project' : project.projectName,
            style: AppTypography.headlineLg.copyWith(
              color: AppColors.onSurface,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // State-specific Alert / Callout Banner
          _buildStateBanner(
            context: context,
            isWaitingAcceptance: isWaitingAcceptance,
            isCompleted: isCompleted,
            isUnderReview: isUnderReview,
            isRevisionRequired: isRevisionRequired,
            isFirstAttempt: isFirstAttempt,
            isRejected: isRejected,
            project: project,
            activeCorrection: activeCorrection,
            roundNumber: activeCorrection?.roundNumber ?? correctionRound,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Practical Assignment Acceptance Section (When WAITING_ACCEPTANCE)
          if (isWaitingAcceptance) ...[
            _buildDetailSection(
              title: 'PRACTICAL ASSIGNMENT ACTION',
              fields: [],
              customContent: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assignment Allocation Summary',
                      style: AppTypography.headlineSmMobile.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Accept this practical assignment to activate your drafting workspace and begin preparing your drawing.',
                      style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.surfaceVariant),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow('Project Name', project.projectName.isEmpty ? 'Untitled' : project.projectName),
                          const Divider(height: AppSpacing.md),
                          _buildSummaryRow('Drawing Target', project.drawingName),
                          const Divider(height: AppSpacing.md),
                          _buildSummaryRow(
                            'Discipline',
                            project.drawingTypeEnum?.displayName ?? project.drawingType,
                          ),
                          const Divider(height: AppSpacing.md),
                          _buildSummaryRow('Site Address', project.projectAddress),
                          if (project.projectArea != null) ...[
                            const Divider(height: AppSpacing.md),
                            _buildSummaryRow('Target Area', '${project.projectArea} sq ft'),
                          ],
                        ],
                      ),
                    ),
                    if (_acceptanceError != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _acceptanceError!,
                                style: AppTypography.bodySm.copyWith(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const ValueKey('accept_assignment_button'),
                        onPressed: _isAccepting
                            ? null
                            : () => _handleAcceptAssignment(project),
                        icon: _isAccepting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.onSecondary,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline, size: 20),
                        label: Text(
                          _isAccepting
                              ? 'Accepting Assignment...'
                              : _acceptanceError != null
                                  ? 'Retry Accept Assignment'
                                  : 'Accept Assignment',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: AppColors.onSecondary,
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],

          // Drawing Requirements Section
          _buildDetailSection(
            title: 'DRAWING REQUIREMENTS',
            fields: [
              _DetailField('Drawing Name', project.drawingName),
              _DetailField(
                'Drawing Type',
                project.drawingTypeEnum?.displayName ?? project.drawingType,
              ),
              _DetailField('Project Address', project.projectAddress),
              if (project.projectArea != null)
                _DetailField('Project Area', '${project.projectArea} sq ft'),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Reference & Specification Files Section
          _buildDetailSection(
            title: 'REFERENCE & SPECIFICATION FILES',
            fields: [],
            customContent: filesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text('Error loading files: $err', style: const TextStyle(color: AppColors.error)),
              ),
              data: (files) {
                final refFiles = files
                    .where((f) =>
                        f.category != 'workspace_draft' &&
                        f.category != 'draughtsman_version' &&
                        f.status != 'FAILED')
                    .toList();

                if (refFiles.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'No reference files attached.',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                    ),
                  );
                }

                return Column(
                  children: [
                    for (final file in refFiles) ...[
                      FileAttachmentCard(file: file),
                      if (_isCadFile(file.sanitizedName))
                        Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.md, bottom: AppSpacing.sm),
                          child: OutlinedButton.icon(
                            key: ValueKey('preview_ref_${file.id}'),
                            onPressed: () {
                              setState(() {
                                _selectedDrawingFileId = file.id;
                                _selectedDrawingFileName = file.sanitizedName;
                                _selectedDrawingVersionNumber = 0;
                              });
                              _showDrawingPreviewDialog(context, file.id, file.sanitizedName, 0);
                            },
                            icon: const Icon(Icons.architecture_rounded, size: 16, color: Color(0xFF00E5FF)),
                            label: Text('Inspect ${file.sanitizedName} in CAD Viewer'),
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // CAD DRAWING CANVAS (Interactive CAD Canvas Section)
          _buildCadDrawingCanvasSection(
            context: context,
            filesAsync: filesAsync,
            versionsAsync: versionsAsync,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Evaluations & Admin Feedback Section
          _buildDetailSection(
            title: 'EVALUATION & ADMIN FEEDBACK',
            fields: [],
            customContent: evaluationsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text('Error loading evaluations: $err', style: const TextStyle(color: AppColors.error)),
              ),
              data: (evaluations) {
                if (evaluations.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      isFirstAttempt
                          ? 'No evaluations yet. STUDIO_ADMIN feedback and scoring criteria will appear here after review.'
                          : isUnderReview
                              ? 'Evaluation pending. STUDIO_ADMIN feedback and rubric scores will appear once reviewed.'
                              : 'No evaluations recorded.',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      for (final evaluation in evaluations)
                        EvaluationCard(evaluation: evaluation),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Historical Corrections (Resolved) Section
          if (resolvedCorrections.isNotEmpty) ...[
            _buildDetailSection(
              title: 'PREVIOUS CORRECTIONS HISTORY',
              fields: [],
              customContent: Column(
                children: [
                  for (final c in resolvedCorrections)
                    ListTile(
                      leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                      title: Text(
                        'Round ${c.roundNumber} - Resolved',
                        style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${c.description}\nResolved: ${c.resolvedAt != null ? DateFormat('MMM d, yyyy').format(c.resolvedAt!) : 'Completed'}',
                      ),
                      isThreeLine: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],

          // Drawing Versions & Submissions History Section
          _buildDetailSection(
            title: 'DRAWING VERSIONS & SUBMISSIONS',
            fields: [],
            customContent: versionsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text('Error loading versions: $err', style: const TextStyle(color: AppColors.error)),
              ),
              data: (versions) {
                if (versions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'No submitted versions yet. Upload and submit your draft below to create Version 1.',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                    ),
                  );
                }

                return Column(
                  children: [
                    for (int i = 0; i < versions.length; i++) ...[
                      _DrawingVersionTile(
                        version: versions[i],
                        onPreview: (fileId, fileName, versionNumber) {
                          setState(() {
                            _selectedDrawingFileId = fileId;
                            _selectedDrawingFileName = fileName;
                            _selectedDrawingVersionNumber = versionNumber;
                          });
                          _showDrawingPreviewDialog(context, fileId, fileName, versionNumber);
                        },
                        statusTag: i == 0
                            ? (isCompleted
                                ? 'Approved'
                                : isUnderReview
                                    ? 'Under Review'
                                    : 'Latest')
                            : null,
                        tagColor: i == 0
                            ? (isCompleted
                                ? Colors.green
                                : isUnderReview
                                    ? Colors.orange
                                    : AppColors.primary)
                            : null,
                      ),
                      if (i < versions.length - 1)
                        const Divider(height: 1, color: AppColors.surfaceVariant),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Workspace Draft Section (Staging & Submission)
          if (isFirstAttempt || isRevisionRequired || isRejected)
            _buildDetailSection(
              title: isRejected ? 'YOUR REVISED DRAFT (POST-REJECTION)' : (isRevisionRequired ? 'YOUR REVISED DRAFT' : 'YOUR WORKSPACE DRAFT'),
              fields: [],
              customContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    child: Text(
                      isRejected
                          ? 'Make the required corrections addressing the rejection feedback above. You can update this file as many times as you want before submitting.'
                          : isRevisionRequired
                              ? 'Upload your revised drawing addressing the feedback above. You can update this file as many times as you want before submitting.'
                              : 'Upload your work in progress here. You can update this file as many times as you want before submitting.',
                      style: const TextStyle(color: AppColors.outline),
                    ),
                  ),
                  filesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text('Error loading files: $err', style: const TextStyle(color: AppColors.error)),
                    ),
                    data: (files) {
                      final draftFiles = files.where((f) => f.category == 'workspace_draft').toList();
                      draftFiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                      final currentDraft = draftFiles.isNotEmpty ? draftFiles.first : null;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (currentDraft != null) ...[
                            FileAttachmentCard(
                              file: currentDraft,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              child: OutlinedButton.icon(
                                key: const ValueKey('preview_draft_button'),
                                onPressed: () {
                                  setState(() {
                                    _selectedDrawingFileId = currentDraft.id;
                                    _selectedDrawingFileName = currentDraft.sanitizedName;
                                    _selectedDrawingVersionNumber = 1;
                                  });
                                  _showDrawingPreviewDialog(
                                    context,
                                    currentDraft.id,
                                    currentDraft.sanitizedName,
                                    1,
                                  );
                                },
                                icon: const Icon(Icons.visibility_outlined, size: 18),
                                label: const Text('Preview CAD Drawing'),
                              ),
                            ),
                          ] else
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Text(
                                'No draft uploaded yet.',
                                style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.md),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            child: SizedBox(
                              width: double.infinity,
                              child: FileUploadButton(
                                projectId: project.projectId,
                                category: 'workspace_draft',
                              ),
                            ),
                          ),
                          if (_submissionError != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        _submissionError!,
                                        style: AppTypography.bodySm.copyWith(color: AppColors.error),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                key: const ValueKey('submit_drawing_button'),
                                onPressed: (currentDraft == null || _isSubmitting)
                                    ? null
                                    : () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(isRejected ? 'Resubmit Drawing' : (isRevisionRequired ? 'Submit Revision' : 'Submit Drawing')),
                                            content: Text(
                                              isRejected
                                                  ? 'Are you sure you want to resubmit your revised drawing for review?'
                                                  : isRevisionRequired
                                                      ? 'Are you sure you want to submit your revised drawing for review? You will not be able to edit it until the STUDIO_ADMIN provides new feedback.'
                                                      : 'Are you sure you want to submit your current draft for review? You will not be able to edit it until the STUDIO_ADMIN provides feedback.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              FilledButton(
                                                onPressed: () => Navigator.of(context).pop(true),
                                                child: const Text('Submit'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed == true && context.mounted) {
                                          setState(() {
                                            _isSubmitting = true;
                                            _submissionError = null;
                                          });

                                          try {
                                            final success = await ref
                                                .read(draughtsmanActionsControllerProvider.notifier)
                                                .submitDrawing(
                                                  projectId: project.projectId,
                                                  draftFileId: currentDraft.id,
                                                );
                                            if (!context.mounted) return;
                                            setState(() {
                                              _isSubmitting = false;
                                            });

                                            if (success) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    isRejected
                                                        ? 'Drawing resubmitted successfully'
                                                        : isRevisionRequired
                                                            ? 'Revision submitted successfully'
                                                            : 'Drawing submitted successfully',
                                                  ),
                                                ),
                                              );
                                            } else {
                                              setState(() {
                                                _submissionError =
                                                    'Failed to submit drawing. Your draft remains saved. You can retry.';
                                              });
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Failed to submit drawing. Your draft remains saved.',
                                                  ),
                                                  backgroundColor: AppColors.error,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            setState(() {
                                              _isSubmitting = false;
                                              _submissionError = 'Submission failed: $e';
                                            });
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Submission failed: $e'),
                                                backgroundColor: AppColors.error,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                icon: _isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.onPrimary,
                                        ),
                                      )
                                    : const Icon(Icons.send_rounded, size: 18),
                                label: Text(
                                  _isSubmitting
                                      ? 'Submitting...'
                                      : _submissionError != null
                                          ? (isRejected
                                              ? 'Retry Resubmit Drawing'
                                              : isRevisionRequired
                                                  ? 'Retry Submit Revision'
                                                  : 'Retry Submit Drawing')
                                          : (isRejected
                                              ? 'Resubmit Drawing for Review'
                                              : isRevisionRequired
                                                  ? 'Submit Revision for Review'
                                                  : 'Submit Drawing for Review'),
                                ),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (currentDraft == null)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.md,
                                right: AppSpacing.md,
                                top: AppSpacing.xs,
                              ),
                              child: Text(
                                'Upload your draft drawing above to enable submission.',
                                style: AppTypography.bodySm.copyWith(color: AppColors.outline),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      );
                    },
                  ),
                ],
              ),
            )
          else if (isWaitingAcceptance)
            _buildDetailSection(
              title: 'WORKSPACE DRAFT',
              fields: [],
              customContent: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, color: AppColors.outline),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Draft upload and submission will be unlocked once you accept this assignment.',
                        style: AppTypography.bodySm.copyWith(color: AppColors.outline),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (isUnderReview)
            _buildDetailSection(
              title: 'WORKSPACE DRAFT',
              fields: [],
              customContent: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, color: AppColors.outline),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Draft submissions are locked while your drawing is awaiting review by the STUDIO_ADMIN.',
                        style: AppTypography.bodySm.copyWith(color: AppColors.outline),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (isCompleted)
            _buildDetailSection(
              title: 'WORKSPACE DRAFT',
              fields: [],
              customContent: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Project is completed and approved. No further draft submissions are accepted.',
                        style: AppTypography.bodySm.copyWith(color: AppColors.outline),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(
            height: AppSpacing.bottomNavHeight +
                MediaQuery.of(context).padding.bottom +
                AppSpacing.xxl,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStateBadge({
    required bool isWaitingAcceptance,
    required bool isCompleted,
    required bool isUnderReview,
    required bool isRevisionRequired,
    required bool isFirstAttempt,
    required bool isRejected,
    required int roundNumber,
  }) {
    String label;
    Color color;

    if (isWaitingAcceptance) {
      label = 'Pending Acceptance';
      color = AppColors.secondary;
    } else if (isCompleted) {
      label = 'Approved';
      color = Colors.green;
    } else if (isUnderReview) {
      label = 'Awaiting Review';
      color = Colors.orange;
    } else if (isRevisionRequired) {
      label = 'Revision Round $roundNumber';
      color = AppColors.error;
    } else if (isRejected) {
      label = 'Rejected';
      color = AppColors.error;
    } else if (isFirstAttempt) {
      label = 'First Attempt';
      color = AppColors.primary;
    } else {
      label = 'Pending';
      color = AppColors.outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTypography.labelMono.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStateBanner({
    required BuildContext context,
    required bool isWaitingAcceptance,
    required bool isCompleted,
    required bool isUnderReview,
    required bool isRevisionRequired,
    required bool isFirstAttempt,
    required bool isRejected,
    required Project project,
    required Correction? activeCorrection,
    required int roundNumber,
  }) {
    if (isRejected) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.error, size: 24),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SUBMISSION REJECTED',
                    style: AppTypography.labelMono.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    project.rejectionReason ??
                        'The reviewer has rejected this drawing submission. Please review the comments and feedback below, make the necessary changes to your drawing, and resubmit.',
                    style: AppTypography.bodySm.copyWith(color: AppColors.onSurface),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (isWaitingAcceptance) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.assignment_outlined, color: AppColors.secondary, size: 24),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ASSIGNMENT PENDING ACCEPTANCE',
                    style: AppTypography.labelMono.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'This practical assignment has been allocated to you. Review the drawing requirements and reference files below, then accept the assignment to begin work and unlock draft uploads.',
                    style: AppTypography.bodySm.copyWith(color: AppColors.onSurface),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    if (isRevisionRequired) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'REVISION REQUIRED (ROUND $roundNumber)',
                        style: AppTypography.labelMono.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                        ),
                        child: Text(
                          activeCorrection?.status == CorrectionStatus.inProgress
                              ? 'IN PROGRESS'
                              : 'ACTION REQUIRED',
                          style: AppTypography.labelMono.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              activeCorrection != null
                  ? activeCorrection.description
                  : 'The STUDIO_ADMIN has requested revisions for your submitted drawing. Please check the feedback below and upload an updated drawing.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
            ),
            if (activeCorrection != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Requested: ${DateFormat('MMM d, yyyy h:mm a').format(activeCorrection.createdAt)}',
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.outline,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (isUnderReview) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.hourglass_top_rounded, color: Colors.orange, size: 24),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AWAITING ADMIN REVIEW',
                    style: AppTypography.labelMono.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Your drawing submission is currently under review by the STUDIO_ADMIN. You will receive feedback or approval here. Draft uploads are disabled during review.',
                    style: AppTypography.bodySm.copyWith(color: AppColors.onSurface),
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
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 24),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DRAWING APPROVED & PROJECT COMPLETED',
                    style: AppTypography.labelMono.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Congratulations! Your practical project has been completed and formally approved. Your approved drawing and evaluation rubric are preserved below.',
                    style: AppTypography.bodySm.copyWith(color: AppColors.onSurface),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Default: First Attempt
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FIRST ATTEMPT',
                  style: AppTypography.labelMono.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Follow the drawing requirements and reference files below. Upload your draft drawing to your workspace and submit when ready for review.',
                  style: AppTypography.bodySm.copyWith(color: AppColors.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required List<_DetailField> fields,
    Widget? customContent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelMono.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: customContent ??
              Column(
                children: [
                  for (var i = 0; i < fields.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              fields[i].label,
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.outline,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              fields[i].value,
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < fields.length - 1)
                      const Divider(height: 1, color: AppColors.surfaceVariant),
                  ],
                ],
              ),
        ),
      ],
    );
  }

  Widget _buildCadDrawingCanvasSection({
    required BuildContext context,
    required AsyncValue<List<ProjectFile>> filesAsync,
    required AsyncValue<List<DrawingVersion>> versionsAsync,
  }) {
    final files = filesAsync.value ?? [];
    final versions = versionsAsync.value ?? [];

    final draftFiles = files
        .where((f) =>
            f.category == 'workspace_draft' &&
            f.status != 'FAILED' &&
            _isCadFile(f.sanitizedName))
        .toList();
    draftFiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final currentDraft = draftFiles.isNotEmpty ? draftFiles.first : null;

    final cadVersions = versions
        .where((v) =>
            v.fileId.isNotEmpty &&
            _isCadFile(v.sanitizedName ?? v.originalName ?? ''))
        .toList();

    final refCadFiles = files
        .where((f) =>
            f.category != 'workspace_draft' &&
            f.category != 'draughtsman_version' &&
            f.status != 'FAILED' &&
            _isCadFile(f.sanitizedName))
        .toList();

    // Determine the active file to display
    String? activeFileId = _selectedDrawingFileId;
    String activeFileName = _selectedDrawingFileName ?? '';
    int activeVersionNumber = _selectedDrawingVersionNumber;

    final allAvailableIds = <String>{
      if (currentDraft != null) currentDraft.id,
      for (final v in cadVersions) v.fileId,
      for (final r in refCadFiles) r.id,
    };

    if (activeFileId == null || !allAvailableIds.contains(activeFileId)) {
      if (currentDraft != null) {
        activeFileId = currentDraft.id;
        activeFileName = currentDraft.sanitizedName;
        activeVersionNumber = 1;
      } else if (cadVersions.isNotEmpty) {
        activeFileId = cadVersions.first.fileId;
        activeFileName = cadVersions.first.sanitizedName ??
            cadVersions.first.originalName ??
            'drawing_v${cadVersions.first.versionNumber}.dwg';
        activeVersionNumber = cadVersions.first.versionNumber;
      } else {
        activeFileId = null;
      }
    }

    final targetFileId = activeFileId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CAD DRAWING CANVAS',
              style: AppTypography.labelMono.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (targetFileId != null)
              InkWell(
                onTap: () => _showDrawingPreviewDialog(
                  context,
                  targetFileId,
                  activeFileName,
                  activeVersionNumber,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.fullscreen_rounded, size: 16, color: Color(0xFF00E5FF)),
                      const SizedBox(width: 4),
                      Text(
                        'Full Screen',
                        style: AppTypography.labelMono.copyWith(
                          color: const Color(0xFF00E5FF),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (targetFileId != null && (currentDraft != null || cadVersions.length > 1 || refCadFiles.isNotEmpty)) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (currentDraft != null) ...[
                ChoiceChip(
                  selected: activeFileId == currentDraft.id,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedDrawingFileId = currentDraft.id;
                        _selectedDrawingFileName = currentDraft.sanitizedName;
                        _selectedDrawingVersionNumber = 1;
                      });
                    }
                  },
                  label: Text('Draft (WIP): ${currentDraft.sanitizedName}'),
                  avatar: const Icon(Icons.edit_note_rounded, size: 16),
                  selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: activeFileId == currentDraft.id
                        ? const Color(0xFF00E5FF)
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
              for (final v in cadVersions) ...[
                ChoiceChip(
                  selected: activeFileId == v.fileId,
                  onSelected: (selected) {
                    if (selected && v.fileId.isNotEmpty) {
                      setState(() {
                        _selectedDrawingFileId = v.fileId;
                        _selectedDrawingFileName = v.sanitizedName ??
                            v.originalName ??
                            'drawing_v${v.versionNumber}.dwg';
                        _selectedDrawingVersionNumber = v.versionNumber;
                      });
                    }
                  },
                  label: Text('Rev ${v.versionNumber}'),
                  avatar: const Icon(Icons.history_rounded, size: 16),
                  selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: activeFileId == v.fileId
                        ? const Color(0xFF00E5FF)
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
              for (final r in refCadFiles) ...[
                ChoiceChip(
                  selected: activeFileId == r.id,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedDrawingFileId = r.id;
                        _selectedDrawingFileName = r.sanitizedName;
                        _selectedDrawingVersionNumber = 0;
                      });
                    }
                  },
                  label: Text('Ref: ${r.sanitizedName}'),
                  avatar: const Icon(Icons.architecture_rounded, size: 16),
                  selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: activeFileId == r.id
                        ? const Color(0xFF00E5FF)
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (targetFileId != null)
          CadDrawingViewer(
            key: ValueKey('student_workspace_cad_$targetFileId'),
            fileId: targetFileId,
            fileName: activeFileName,
            versionNumber: activeVersionNumber,
            height: 480,
          )
        else
          Container(
            height: 320,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF07111E),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _StudentCadGridPainter(),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.architecture_rounded,
                            color: Color(0xFF00E5FF),
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'CAD Canvas Ready',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'Upload a DWG or DXF drawing draft below to inspect geometry on the interactive CAD canvas.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (refCadFiles.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton.icon(
                            key: const ValueKey('preview_ref_cad_canvas_btn'),
                            onPressed: () {
                              final refFile = refCadFiles.first;
                              setState(() {
                                _selectedDrawingFileId = refFile.id;
                                _selectedDrawingFileName = refFile.sanitizedName;
                                _selectedDrawingVersionNumber = 0;
                              });
                            },
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 16,
                              color: Color(0xFF00E5FF),
                            ),
                            label: Text(
                              'Inspect Reference CAD (${refCadFiles.first.sanitizedName})',
                              style: const TextStyle(color: Color(0xFF00E5FF)),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                              ),
                              backgroundColor: const Color(0xFF0B192C),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DetailField {
  final String label;
  final String value;

  _DetailField(this.label, this.value);
}

class _DrawingVersionTile extends ConsumerStatefulWidget {
  final DrawingVersion version;
  final String? statusTag;
  final Color? tagColor;
  final void Function(String fileId, String fileName, int versionNumber)? onPreview;

  const _DrawingVersionTile({
    required this.version,
    this.statusTag,
    this.tagColor,
    this.onPreview,
  });

  @override
  ConsumerState<_DrawingVersionTile> createState() => _DrawingVersionTileState();
}

class _DrawingVersionTileState extends ConsumerState<_DrawingVersionTile> {
  bool _isDownloading = false;

  Future<void> _download() async {
    setState(() => _isDownloading = true);
    try {
      final repository = ref.read(fileRepositoryProvider);
      final fileName = widget.version.sanitizedName ??
          widget.version.originalName ??
          'drawing_v${widget.version.versionNumber}.pdf';

      if (kIsWeb) {
        await repository.downloadFile(widget.version.fileId, fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Download started in browser')),
          );
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/$fileName';
        await repository.downloadFile(widget.version.fileId, filePath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Downloaded to $filePath')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = widget.version.createdAt != null
        ? DateFormat('MMM d, yyyy').format(widget.version.createdAt!)
        : 'Recent';

    final sz = widget.version.size ?? 0;
    final sizeStr = sz > 0
        ? '${(sz / 1024).toStringAsFixed(1)} KB • '
        : '';

    final fileName = widget.version.sanitizedName ?? widget.version.originalName;
    final isLatest = widget.statusTag != null;

    return Container(
      decoration: isLatest
          ? BoxDecoration(
              color: (widget.tagColor ?? AppColors.primary).withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            )
          : null,
      child: ListTile(
        leading: Icon(
          Icons.picture_as_pdf_outlined,
          color: widget.tagColor ?? AppColors.primary,
        ),
        title: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Version ${widget.version.versionNumber}',
              style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.bold),
            ),
            if (widget.statusTag != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (widget.tagColor ?? AppColors.primary).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                ),
                child: Text(
                  widget.statusTag!,
                  style: AppTypography.labelMono.copyWith(
                    color: widget.tagColor ?? AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fileName != null && fileName.isNotEmpty) ...[
              Text(
                fileName,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
            ],
            Text(
              '$sizeStr$dateStr',
              style: AppTypography.labelMono.copyWith(
                color: AppColors.outline,
                fontSize: 11,
              ),
            ),
          ],
        ),
        isThreeLine: fileName != null && fileName.isNotEmpty,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.version.fileId.isNotEmpty && widget.onPreview != null)
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20),
                tooltip: 'Preview CAD Drawing',
                onPressed: () {
                  final name = widget.version.sanitizedName ??
                      widget.version.originalName ??
                      'drawing_v${widget.version.versionNumber}.dwg';
                  widget.onPreview!(widget.version.fileId, name, widget.version.versionNumber);
                },
              ),
            _isDownloading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.download_rounded),
                    tooltip: 'Download Version',
                    onPressed: _download,
                  ),
          ],
        ),
      ),
    );
  }
}

Correction? _findActiveCorrection(List<Correction> corrections) {
  final sorted = List<Correction>.from(corrections)
    ..sort((a, b) => b.roundNumber.compareTo(a.roundNumber));
  for (final c in sorted) {
    if (c.status == CorrectionStatus.open || c.status == CorrectionStatus.inProgress) {
      return c;
    }
  }
  return null;
}

/// Subtle CAD Blueprint Grid Painter for Student Workspace
class _StudentCadGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintMinor = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.04)
      ..strokeWidth = 0.5;

    final paintMajor = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    const step = 20.0;
    for (double x = 0; x <= size.width; x += step) {
      final isMajor = (x / step).round() % 5 == 0;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), isMajor ? paintMajor : paintMinor);
    }

    for (double y = 0; y <= size.height; y += step) {
      final isMajor = (y / step).round() % 5 == 0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), isMajor ? paintMajor : paintMinor);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

