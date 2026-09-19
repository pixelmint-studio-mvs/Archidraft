import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../domain/assignment.dart';
import '../../domain/assignment_status.dart';
import '../../domain/project.dart';
import '../../providers/assignment_providers.dart';
import '../../providers/project_providers.dart';

class DraughtsmanAssignmentDetailScreen extends ConsumerWidget {
  final Assignment assignment;

  const DraughtsmanAssignmentDetailScreen({
    super.key,
    required this.assignment,
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

    final projectAsync = ref.watch(projectProvider(assignment.projectId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        title: const Text('Assignment Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/draughtsman/studio'),
        ),
      ),
      body: projectAsync.when(
        loading: () =>
            const AppLoadingIndicator(message: 'Loading project details...'),
        error: (error, _) => AppErrorWidget(
          message: 'Failed to load project.',
          onRetry: () => ref.invalidate(projectProvider(assignment.projectId)),
        ),
        data: (project) {
          if (project == null) {
            return const AppErrorWidget(message: 'Project not found.');
          }
          return _buildDetails(context, ref, project);
        },
      ),
    );
  }

  Widget _buildDetails(BuildContext context, WidgetRef ref, Project project) {
    final status = assignment.assignmentStatus;
    final isLoading = ref.watch(draughtsmanActionsControllerProvider).isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.projectName.isEmpty
                ? 'Untitled Project'
                : project.projectName,
            style: AppTypography.headlineLg.copyWith(
              color: AppColors.onSurface,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          _buildInfoCard(
            title: 'Project Info',
            children: [
              _InfoRow('Address', project.projectAddress),
              _InfoRow('Drawing Name', project.drawingName),
              _InfoRow(
                'Drawing Type',
                project.drawingTypeEnum?.displayName ?? project.drawingType,
              ),
              _InfoRow(
                'Project Area',
                project.projectArea != null
                    ? '${project.projectArea} sq ft'
                    : 'Not specified',
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),

          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (status == AssignmentStatus.pending) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleReject(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _handleAccept(context, ref),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ] else if (status == AssignmentStatus.accepted) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  context.push('/draughtsman/workspace/${project.projectId}');
                },
                child: const Text('Open Workspace'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.buttonText),
          const Divider(height: AppSpacing.xl),
          ...children,
        ],
      ),
    );
  }

  void _handleAccept(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept Assignment'),
        content: const Text('Are you sure you want to accept this assignment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ref
        .read(draughtsmanActionsControllerProvider.notifier)
        .acceptAssignment(
          assignmentId: assignment.id,
          projectId: assignment.projectId,
        );
    if (success && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Assignment Accepted!')));
      context.pop(); // go back
    }
  }

  void _handleReject(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Assignment'),
        content: const Text('Are you sure you want to reject this assignment? You cannot undo this action.'),
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

    final success = await ref
        .read(draughtsmanActionsControllerProvider.notifier)
        .rejectAssignment(
          assignmentId: assignment.id,
          projectId: assignment.projectId,
        );
    if (success && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Assignment Rejected')));
      context.pop();
    }
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
              style: AppTypography.labelMono.copyWith(color: AppColors.outline),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: AppTypography.bodyMd,
            ),
          ),
        ],
      ),
    );
  }
}
