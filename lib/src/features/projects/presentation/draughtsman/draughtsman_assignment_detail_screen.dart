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
import '../../domain/project.dart';
import '../../providers/assignment_providers.dart';
import '../../providers/project_providers.dart';
import '../widgets/project_status_chip.dart';
import '../../domain/project_status.dart';

/// Detailed view for a single assignment.
///
/// Shows all available project metadata, the assignment status, and
/// contextual CTA buttons: Accept/Reject (if PENDING) or Open Workspace
/// (if ACCEPTED). All backend calls go through [DraughtsmanActionsController].
class DraughtsmanAssignmentDetailScreen extends ConsumerWidget {
  final String assignmentId;

  const DraughtsmanAssignmentDetailScreen({
    super.key,
    required this.assignmentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to controller errors so we can show snackbars
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

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Assignment Details',
          style: AppTypography.buttonText.copyWith(color: AppColors.onSurface),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/draughtsman/studio'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.outlineVariant),
        ),
      ),
      body: assignmentAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Loading assignment details...'),
        error: (error, _) => AppErrorWidget(
          message: 'Failed to load assignment.',
          onRetry: () => ref.invalidate(assignmentProvider(assignmentId)),
        ),
        data: (assignment) {
          if (assignment == null) {
            return const AppErrorWidget(message: 'Assignment not found.');
          }
          return _buildDetails(context, ref, assignment);
        },
      ),
    );
  }

  Widget _buildDetails(BuildContext context, WidgetRef ref, Assignment assignment) {
    final status = assignment.assignmentStatus ?? AssignmentStatus.pending;
    final isLoading = ref.watch(draughtsmanActionsControllerProvider).isLoading;
    final projectStatusValue = assignment.projectStatus;
    final projectStatus = projectStatusValue != null
        ? ProjectStatus.values.firstWhere(
            (e) => e.name.toUpperCase() == projectStatusValue.toUpperCase(),
            orElse: () => ProjectStatus.draft,
          )
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project name and status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  assignment.projectName?.isEmpty ?? true ? 'Untitled Project' : assignment.projectName!,
                  style: AppTypography.headlineLg.copyWith(
                    color: AppColors.onSurface,
                    fontSize: 26,
                  ),
                ),
              ),
              if (projectStatus != null) ...[
                const SizedBox(width: AppSpacing.md),
                ProjectStatusChip(status: projectStatus),
              ],
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Assignment status badge
          _AssignmentStatusBadge(status: status),

          const SizedBox(height: AppSpacing.xxl),

          // Action buttons — shown at top for easy access
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            _buildActions(context, ref, status, assignment),
            const SizedBox(height: AppSpacing.xxl),
          ],

          // Drawing specifications
          _InfoCard(
            title: 'DRAWING SPECIFICATIONS',
            icon: Icons.architecture_outlined,
            children: [
              _InfoRow(
                'Drawing Name',
                assignment.drawingName?.isEmpty ?? true ? '—' : assignment.drawingName!,
              ),
              _InfoRow(
                'Drawing Type',
                assignment.drawingType ?? '—',
              ),
              _InfoRow(
                'Project Area',
                assignment.projectArea != null
                    ? '${assignment.projectArea} sq ft'
                    : 'Not specified',
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Project location
          _InfoCard(
            title: 'PROJECT LOCATION',
            icon: Icons.location_on_outlined,
            children: [
              _InfoRow('Address', assignment.projectAddress?.isEmpty ?? true ? '—' : assignment.projectAddress!),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Assignment timeline
          _InfoCard(
            title: 'ASSIGNMENT TIMELINE',
            icon: Icons.schedule_outlined,
            children: [
              _InfoRow(
                'Assigned',
                assignment.assignedAt != null
                    ? DateFormat('MMM d, yyyy').format(assignment.assignedAt!)
                    : '—',
              ),
              _InfoRow(
                'Correction Round',
                assignment.correctionRound != null && assignment.correctionRound! > 0
                    ? 'Round ${assignment.correctionRound}'
                    : 'Initial Drawing',
              ),
            ],
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    WidgetRef ref,
    AssignmentStatus status,
    Assignment assignment,
  ) {
    switch (status) {
      case AssignmentStatus.pending:
        return _PendingActions(
          assignment: assignment,
        );
      case AssignmentStatus.accepted:
        return _AcceptedAction(projectId: assignment.projectId);
      case AssignmentStatus.completed:
        return _CompletedBanner(projectId: assignment.projectId);
      case AssignmentStatus.rejected:
        return _RejectedBanner();
      case AssignmentStatus.replaced:
        return _ReplacedBanner();
    }
  }
}

// ─────────────────────────────────────────────────────────
// ACTION PANELS
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_late_outlined, color: AppColors.secondary, size: 20),
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
                    side: BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success, size: 22),
            const SizedBox(width: AppSpacing.sm),
            const Text('Accept Assignment'),
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
              style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
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
        SnackBar(
          content: const Text('Assignment Accepted! Opening workspace...'),
          backgroundColor: AppColors.success,
        ),
      );
      // Navigate directly to workspace
      context.pushReplacement('/draughtsman/workspace/${assignment.projectId}');
    }
  }

  void _handleReject(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.error, size: 22),
            const SizedBox(width: AppSpacing.sm),
            const Text('Reject Assignment'),
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
              style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
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
        const SnackBar(content: Text('Assignment Rejected')),
      );
      context.go('/draughtsman/studio');
    }
  }
}

class _AcceptedAction extends StatelessWidget {
  final String projectId;

  const _AcceptedAction({required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.draw_outlined, color: AppColors.success, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'ASSIGNMENT IN PROGRESS',
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'You have accepted this assignment. Open the workspace to upload drawings and manage the project.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  context.push('/draughtsman/workspace/$projectId'),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Open Workspace'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedBanner extends StatelessWidget {
  final String projectId;

  const _CompletedBanner({required this.projectId});

  @override
  Widget build(BuildContext context) {
    return _StatusBanner(
      color: AppColors.success,
      icon: Icons.verified_outlined,
      label: 'ASSIGNMENT COMPLETE',
      description: 'This project has been completed and approved.',
      action: OutlinedButton.icon(
        onPressed: () => context.push('/draughtsman/workspace/$projectId'),
        icon: const Icon(Icons.history_outlined, size: 16),
        label: const Text('View History'),
      ),
    );
  }
}

class _RejectedBanner extends StatelessWidget {
  const _RejectedBanner();

  @override
  Widget build(BuildContext context) {
    return const _StatusBanner(
      color: AppColors.error,
      icon: Icons.cancel_outlined,
      label: 'ASSIGNMENT REJECTED',
      description: 'You rejected this assignment. It may be reassigned to another draughtsman.',
    );
  }
}

class _ReplacedBanner extends StatelessWidget {
  const _ReplacedBanner();

  @override
  Widget build(BuildContext context) {
    return const _StatusBanner(
      color: AppColors.onSurfaceVariant,
      icon: Icons.swap_horiz_rounded,
      label: 'ASSIGNMENT REPLACED',
      description: 'This assignment was replaced and reassigned by the admin.',
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final String description;
  final Widget? action;

  const _StatusBanner({
    required this.color,
    required this.icon,
    required this.label,
    required this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.labelMono.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(description, style: AppTypography.bodyMd),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// ASSIGNMENT STATUS BADGE
// ─────────────────────────────────────────────────────────

class _AssignmentStatusBadge extends StatelessWidget {
  final AssignmentStatus status;

  const _AssignmentStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bgColor) = switch (status) {
      AssignmentStatus.pending => ('PENDING RESPONSE', AppColors.warning, AppColors.warning.withValues(alpha: 0.1)),
      AssignmentStatus.accepted => ('ACCEPTED — IN PROGRESS', AppColors.success, AppColors.success.withValues(alpha: 0.1)),
      AssignmentStatus.completed => ('COMPLETED', AppColors.success, AppColors.success.withValues(alpha: 0.1)),
      AssignmentStatus.rejected => ('REJECTED', AppColors.error, AppColors.error.withValues(alpha: 0.1)),
      AssignmentStatus.replaced => ('REPLACED', AppColors.onSurfaceVariant, AppColors.surfaceContainerLow),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTypography.labelMonoSm.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

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
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusXl)),
              border: Border(
                  bottom: BorderSide(color: AppColors.outlineVariant, width: 0.5)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: AppTypography.labelMono.copyWith(
                      color: AppColors.onSurfaceVariant, letterSpacing: 1.0),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
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
            width: 110,
            child: Text(
              label,
              style: AppTypography.labelMono.copyWith(
                  color: AppColors.outline, fontSize: 11),
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
