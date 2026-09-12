import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:archi_draft/src/core/theme/app_colors.dart';
import 'package:archi_draft/src/core/theme/app_spacing.dart';
import 'package:archi_draft/src/core/theme/app_typography.dart';
import 'package:archi_draft/src/shared/widgets/app_state_widgets.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/domain/project_status.dart';
import 'package:archi_draft/src/features/projects/providers/project_form_controller.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/projects/providers/client_project_controller.dart';
import 'widgets/project_status_chip.dart';
import 'widgets/project_timeline_widget.dart';

/// Detail screen for viewing a project.
///
/// Phase 7 enhancements:
/// - Status-aware header with contextual subtitle
/// - Assigned draughtsman section (when assigned)
/// - Project timeline section (milestones derived from timestamps)
/// - Cancel project action (DRAFT / SUBMITTED only)
/// - Real-time updates via StreamProvider
///
/// Stitch design reference: project_details_versioning — card sections, status badge.
class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectProvider(projectId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Project Details',
          style: AppTypography.buttonText.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/client/projects'),
        ),
      ),
      body: projectAsync.when(
        loading: () =>
            const AppLoadingIndicator(message: 'Loading project...'),
        error: (error, _) => AppErrorWidget(
          message: 'Failed to load project.',
          onRetry: () => ref.invalidate(projectProvider(projectId)),
        ),
        data: (project) {
          if (project == null) {
            return const AppErrorWidget(
              message: 'Project not found.',
            );
          }
          return _buildProjectDetail(context, ref, project);
        },
      ),
    );
  }

  Widget _buildProjectDetail(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) {
    final status = project.projectStatus ?? ProjectStatus.draft;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status-Aware Header ──
          _buildStatusHeader(status, project),

          const SizedBox(height: AppSpacing.xxl),

          // ── Project Information Section ──
          _buildDetailSection(
            title: 'PROJECT INFORMATION',
            fields: [
              _DetailField('Project Name', project.projectName),
              _DetailField('Project Address', project.projectAddress),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Drawing Requirements Section ──
          _buildDetailSection(
            title: 'DRAWING REQUIREMENTS',
            fields: [
              _DetailField('Drawing Name', project.drawingName),
              _DetailField(
                'Drawing Type',
                project.drawingTypeEnum?.displayName ??
                    project.drawingType,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Dimensions & Budget Section ──
          _buildDetailSection(
            title: 'DIMENSIONS & BUDGET',
            fields: [
              _DetailField(
                'Project Area',
                project.projectArea != null
                    ? '${project.projectArea} sq ft'
                    : 'Not specified',
              ),
              _DetailField(
                'Estimated Budget',
                project.estimatedAmount != null
                    ? '${project.estimatedAmount}'
                    : 'Not specified',
              ),
            ],
          ),

          // ── Assigned Draughtsman Section (conditional) ──
          if (project.draughtsmanName != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildDetailSection(
              title: 'ASSIGNED DRAUGHTSMAN',
              fields: [
                _DetailField('Name', project.draughtsmanName!),
                if (project.assignedAt != null)
                  _DetailField(
                    'Assigned On',
                    DateFormat('MMMM d, yyyy').format(project.assignedAt!),
                  ),
              ],
            ),
          ],

          // ── Rejection Reason (conditional) ──
          if (project.rejectionReason != null &&
              project.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildRejectionSection(project.rejectionReason!),
          ],

          const SizedBox(height: AppSpacing.xxl),

          // ── Project Timeline ──
          _buildTimelineSection(project, status),

          const SizedBox(height: AppSpacing.xxl),

          // ── Action Buttons ──
          _buildActionButtons(context, ref, project, status),

          const SizedBox(height: 100), // Bottom spacing
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // STATUS-AWARE HEADER
  // ──────────────────────────────────────────

  Widget _buildStatusHeader(ProjectStatus status, Project project) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ProjectStatusChip(status: status),
            const Spacer(),
            if (project.createdAt != null)
              Text(
                DateFormat('MMM d, yyyy').format(project.createdAt!),
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.outline,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          project.projectName.isEmpty
              ? 'Untitled Project'
              : project.projectName,
          style: AppTypography.headlineLg.copyWith(
            color: AppColors.onSurface,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Contextual subtitle
        Text(
          _statusSubtitle(status),
          style: AppTypography.bodyMd.copyWith(
            color: _statusSubtitleColor(status),
          ),
        ),
        // Submitted timestamp
        if (status != ProjectStatus.draft && project.submittedAt != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Submitted on ${DateFormat("MMMM d, yyyy 'at' h:mm a").format(project.submittedAt!)}',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.outline,
            ),
          ),
        ],
      ],
    );
  }

  String _statusSubtitle(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.draft:
        return 'This project is still a draft. Edit and submit when ready.';
      case ProjectStatus.submitted:
        return 'Your project is being reviewed by the studio.';
      case ProjectStatus.waitingAssignment:
        return 'Your project has been approved! A draughtsman will be assigned shortly.';
      case ProjectStatus.waitingAcceptance:
        return 'A draughtsman has been assigned and is reviewing your project.';
      case ProjectStatus.inProgress:
        return 'Your project is actively being worked on.';
      case ProjectStatus.underClientReview:
        return 'Your drawings are ready for review.';
      case ProjectStatus.completed:
        return 'Project completed successfully.';
      case ProjectStatus.cancelled:
        return 'This project has been cancelled.';
    }
  }

  Color _statusSubtitleColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.completed:
        return AppColors.success;
      case ProjectStatus.cancelled:
        return AppColors.error;
      case ProjectStatus.underClientReview:
        return AppColors.secondary;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  // ──────────────────────────────────────────
  // REJECTION REASON SECTION
  // ──────────────────────────────────────────

  Widget _buildRejectionSection(String reason) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'REJECTION REASON',
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            reason,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // PROJECT TIMELINE
  // ──────────────────────────────────────────

  Widget _buildTimelineSection(Project project, ProjectStatus status) {
    final milestones = _buildMilestones(project, status);
    if (milestones.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROJECT TIMELINE',
          style: AppTypography.labelMono.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ProjectTimelineWidget(milestones: milestones),
      ],
    );
  }

  /// Builds the milestone list based on available timestamps.
  ///
  /// Only includes milestones that are relevant to the current status.
  /// Milestones beyond the current status are shown as unreached (hollow dots).
  List<TimelineMilestone> _buildMilestones(
    Project project,
    ProjectStatus status,
  ) {
    final milestones = <TimelineMilestone>[];

    // Always show "Created"
    milestones.add(TimelineMilestone(
      label: 'Project Created',
      timestamp: project.createdAt,
      isReached: true,
    ));

    // "Submitted" — shown once submitted or beyond
    if (_statusIndex(status) >= _statusIndex(ProjectStatus.submitted)) {
      milestones.add(TimelineMilestone(
        label: 'Submitted for Review',
        timestamp: project.submittedAt,
        isReached: true,
      ));
    } else if (status == ProjectStatus.draft) {
      milestones.add(const TimelineMilestone(
        label: 'Submit for Review',
        isReached: false,
      ));
    }

    // "Approved" — shown once approved or beyond
    if (_statusIndex(status) >= _statusIndex(ProjectStatus.waitingAssignment)) {
      milestones.add(TimelineMilestone(
        label: 'Approved by Studio',
        timestamp: project.approvedAt,
        isReached: true,
      ));
    } else if (_statusIndex(status) >= _statusIndex(ProjectStatus.submitted) &&
        !status.isTerminal) {
      milestones.add(const TimelineMilestone(
        label: 'Studio Review',
        isReached: false,
      ));
    }

    // "Draughtsman Assigned" — shown once assigned or beyond
    if (_statusIndex(status) >= _statusIndex(ProjectStatus.waitingAcceptance)) {
      milestones.add(TimelineMilestone(
        label: 'Draughtsman Assigned',
        timestamp: project.assignedAt,
        isReached: true,
      ));
    } else if (_statusIndex(status) >= _statusIndex(ProjectStatus.waitingAssignment) &&
        !status.isTerminal) {
      milestones.add(const TimelineMilestone(
        label: 'Draughtsman Assignment',
        isReached: false,
      ));
    }

    // "In Progress" — shown once in progress or beyond
    if (_statusIndex(status) >= _statusIndex(ProjectStatus.inProgress)) {
      milestones.add(const TimelineMilestone(
        label: 'Work In Progress',
        isReached: true,
      ));
    } else if (_statusIndex(status) >= _statusIndex(ProjectStatus.waitingAcceptance) &&
        !status.isTerminal) {
      milestones.add(const TimelineMilestone(
        label: 'Work Begins',
        isReached: false,
      ));
    }

    // "Under Review" — shown once submitted for review or beyond
    if (_statusIndex(status) >= _statusIndex(ProjectStatus.underClientReview)) {
      milestones.add(const TimelineMilestone(
        label: 'Drawings Ready for Review',
        isReached: true,
      ));
    } else if (_statusIndex(status) >= _statusIndex(ProjectStatus.inProgress) &&
        !status.isTerminal) {
      milestones.add(const TimelineMilestone(
        label: 'Drawing Delivery',
        isReached: false,
      ));
    }

    // "Completed" — only shown if completed
    if (status == ProjectStatus.completed) {
      milestones.add(TimelineMilestone(
        label: 'Project Completed',
        timestamp: project.completedAt,
        isReached: true,
      ));
    } else if (_statusIndex(status) >= _statusIndex(ProjectStatus.underClientReview) &&
        !status.isTerminal) {
      milestones.add(const TimelineMilestone(
        label: 'Completion',
        isReached: false,
      ));
    }

    // "Cancelled" — only shown if cancelled
    if (status == ProjectStatus.cancelled) {
      milestones.add(TimelineMilestone(
        label: 'Project Cancelled',
        timestamp: project.cancelledAt,
        isReached: true,
      ));
    }

    return milestones;
  }

  /// Maps status to a numeric index for comparison.
  int _statusIndex(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.draft:
        return 0;
      case ProjectStatus.submitted:
        return 1;
      case ProjectStatus.waitingAssignment:
        return 2;
      case ProjectStatus.waitingAcceptance:
        return 3;
      case ProjectStatus.inProgress:
        return 4;
      case ProjectStatus.underClientReview:
        return 5;
      case ProjectStatus.completed:
        return 6;
      case ProjectStatus.cancelled:
        return -1; // Terminal, handled separately
    }
  }

  // ──────────────────────────────────────────
  // ACTION BUTTONS
  // ──────────────────────────────────────────

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    Project project,
    ProjectStatus status,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Continue Editing (DRAFT only)
        if (status == ProjectStatus.draft) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                ref
                    .read(projectFormControllerProvider.notifier)
                    .loadDraft(project);
                context.go('/client/projects/new');
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Continue Editing'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.onSecondary,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.lg,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Cancel Project (DRAFT or SUBMITTED)
        if (project.isCancellable) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCancelDialog(context, ref, project),
              icon: Icon(
                Icons.cancel_outlined,
                size: 18,
                color: AppColors.error,
              ),
              label: Text(
                'Cancel Project',
                style: AppTypography.buttonText.copyWith(
                  color: AppColors.error,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(
                  color: AppColors.error.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.lg,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
        ],

        // Under Review placeholder
        if (status == ProjectStatus.underClientReview) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.secondaryFixed.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 20,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Review actions will be available in a future update.',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showCancelDialog(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        title: Text(
          'Cancel Project',
          style: AppTypography.headlineLgMobile.copyWith(
            color: AppColors.onSurface,
            fontSize: 20,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel "${project.projectName}"?\n\nThis action cannot be undone.',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Keep Project',
              style: AppTypography.buttonText.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: const Text('Cancel Project'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && context.mounted) {
        final controller =
            ref.read(clientProjectControllerProvider.notifier);
        final success = await controller.cancelProject(project.projectId);

        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Project cancelled successfully.'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'Failed to cancel project. Please try again.'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            );
          }
        }
      }
    });
  }

  // ──────────────────────────────────────────
  // DETAIL SECTION BUILDER (preserved from Phase 5)
  // ──────────────────────────────────────────

  Widget _buildDetailSection({
    required String title,
    required List<_DetailField> fields,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
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
                bottom: BorderSide(
                  color: AppColors.outlineVariant,
                  width: 0.5,
                ),
              ),
            ),
            child: Text(
              title,
              style: AppTypography.labelMono.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),

          // Fields
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: fields.map((field) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.label,
                        style: AppTypography.labelMono.copyWith(
                          color: AppColors.outline,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        field.value.isEmpty ? '—' : field.value,
                        style: AppTypography.bodyMd.copyWith(
                          color: field.value.isEmpty
                              ? AppColors.outline
                              : AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailField {
  final String label;
  final String value;

  const _DetailField(this.label, this.value);
}
