import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../domain/assignment.dart';
import '../../providers/admin_providers.dart';

class AdminAssignmentsScreen extends ConsumerWidget {
  const AdminAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(allAssignmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('All Assignments')),
      body: assignmentsAsync.when(
        loading: () =>
            const AppLoadingIndicator(message: 'Loading assignments...'),
        error: (e, _) => AppErrorWidget(
          message: 'Failed to load assignments.',
          onRetry: () => ref.invalidate(allAssignmentsProvider),
        ),
        data: (assignments) {
          if (assignments.isEmpty) {
            return Center(
              child: Text(
                'No assignments found.',
                style: TextStyle(color: AppColors.outline),
              ),
            );
          }

          // Sort by creation date descending
          final sortedAssignments = List<Assignment>.from(assignments)
            ..sort(
              (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
                a.createdAt ?? DateTime.now(),
              ),
            );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allAssignmentsProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: sortedAssignments.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final assignment = sortedAssignments[index];
                return _AdminAssignmentCard(assignment: assignment);
              },
            ),
          );
        },
      ),
    );
  }
}

class _AdminAssignmentCard extends StatelessWidget {
  final Assignment assignment;

  const _AdminAssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Project ID: ${assignment.projectId}',
                  style: AppTypography.buttonText,
                ),
                _AssignmentStatusChip(status: assignment.status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Draughtsman ID: ${assignment.draughtsmanId}',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (assignment.createdAt != null)
              Text(
                'Assigned on: ${DateFormat.yMMMd().format(assignment.createdAt!)}',
                style: AppTypography.bodySm.copyWith(color: AppColors.outline),
              ),
            if (assignment.status == 'COMPLETED' &&
                assignment.updatedAt != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Completed on: ${DateFormat.yMMMd().format(assignment.updatedAt!)}',
                style: AppTypography.bodySm.copyWith(color: AppColors.outline),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AssignmentStatusChip extends StatelessWidget {
  final String status;
  const _AssignmentStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'WAITING_ACCEPTANCE':
        bgColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange[800]!;
        break;
      case 'IN_PROGRESS':
        bgColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue[800]!;
        break;
      case 'COMPLETED':
        bgColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green[800]!;
        break;
      default:
        bgColor = AppColors.surfaceContainerHighest;
        textColor = AppColors.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
