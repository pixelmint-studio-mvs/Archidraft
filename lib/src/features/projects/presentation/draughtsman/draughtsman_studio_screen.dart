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

class DraughtsmanStudioScreen extends ConsumerWidget {
  const DraughtsmanStudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(draughtsmanAssignmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        title: const Text('Draughtsman Studio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(draughtsmanAssignmentsProvider),
          ),
        ],
      ),
      body: assignmentsAsync.when(
        loading: () =>
            const AppLoadingIndicator(message: 'Loading assignments...'),
        error: (error, _) => AppErrorWidget(
          message: 'Failed to load assignments.',
          onRetry: () => ref.invalidate(draughtsmanAssignmentsProvider),
        ),
        data: (assignments) {
          if (assignments.isEmpty) {
            return const AppEmptyState(
              title: 'No Assignments',
              subtitle: 'You have no active assignments right now.',
              icon: Icons.assignment_outlined,
            );
          }

          final pending = assignments
              .where((a) => a.assignmentStatus == AssignmentStatus.pending)
              .toList();
          final accepted = assignments
              .where((a) => a.assignmentStatus == AssignmentStatus.accepted)
              .toList();
          final completed = assignments
              .where((a) => a.assignmentStatus == AssignmentStatus.completed)
              .toList();

          return CustomScrollView(
            slivers: [
              if (pending.isNotEmpty) ...[
                _buildSectionHeader('Pending Acceptance (${pending.length})'),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _AssignmentCard(assignment: pending[index]),
                    childCount: pending.length,
                  ),
                ),
              ],
              if (accepted.isNotEmpty) ...[
                _buildSectionHeader('In Progress (${accepted.length})'),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _AssignmentCard(assignment: accepted[index]),
                    childCount: accepted.length,
                  ),
                ),
              ],
              if (completed.isNotEmpty) ...[
                _buildSectionHeader('Completed (${completed.length})'),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _AssignmentCard(assignment: completed[index]),
                    childCount: completed.length,
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          title,
          style: AppTypography.headlineLgMobile.copyWith(
            color: AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;

  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: InkWell(
        onTap: () => context.push(
          '/draughtsman/assignments/${assignment.id}',
          extra: assignment,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Project ID: ${assignment.projectId}', // ideally we fetch the project details to show name, but keeping it simple
                    style: AppTypography.buttonText,
                  ),
                  _AssignmentStatusChip(
                    status:
                        assignment.assignmentStatus ?? AssignmentStatus.pending,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (assignment.createdAt != null)
                Text(
                  'Assigned on: ${DateFormat('MMM d, yyyy').format(assignment.createdAt!)}',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignmentStatusChip extends StatelessWidget {
  final AssignmentStatus status;

  const _AssignmentStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (status) {
      case AssignmentStatus.pending:
        color = AppColors.warning;
        break;
      case AssignmentStatus.accepted:
        color = AppColors.primary;
        break;
      case AssignmentStatus.completed:
        color = AppColors.success;
        break;
      case AssignmentStatus.rejected:
      case AssignmentStatus.replaced:
        color = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.displayName,
        style: AppTypography.labelMonoSm.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
