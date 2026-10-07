import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/project.dart';
import '../../domain/project_status.dart';
import '../../domain/activity_log.dart';
import '../../../../core/utils/file_category_labels.dart';

class WorkflowTimelineWidget extends StatelessWidget {
  final Project project;
  final List<ActivityLog> activities;

  const WorkflowTimelineWidget({
    super.key,
    required this.project,
    required this.activities,
  });

  int _getStatusIndex(ProjectStatus? status) {
    if (status == null) return -1;
    switch (status) {
      case ProjectStatus.draft: return 0;
      case ProjectStatus.submitted: return 1;
      case ProjectStatus.waitingAssignment: return 2;
      case ProjectStatus.waitingAcceptance: return 3;
      case ProjectStatus.inProgress: return 4;
      case ProjectStatus.underClientReview: return 5;
      case ProjectStatus.completed: return 6;
      case ProjectStatus.cancelled: return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = project.projectStatus;
    final currentIndex = _getStatusIndex(status);
    final isCancelled = status == ProjectStatus.cancelled;

    final nodes = [
      _TimelineStage('Draft', 'Project requirements defined', ProjectStatus.draft),
      _TimelineStage('Submitted', 'Pending admin review', ProjectStatus.submitted),
      _TimelineStage('Waiting Assignment', 'Allocating to draughtsman', ProjectStatus.waitingAssignment),
      _TimelineStage('Waiting Acceptance', 'Draughtsman review', ProjectStatus.waitingAcceptance),
      _TimelineStage('In Progress', 'Drawing creation', ProjectStatus.inProgress),
      _TimelineStage('Under Review', 'Client review and corrections', ProjectStatus.underClientReview),
      _TimelineStage('Completed', 'Final delivery', ProjectStatus.completed),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_tree_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('PROJECT WORKFLOW', style: AppTypography.buttonText.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (isCancelled)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(Icons.cancel, color: AppColors.error),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Project Cancelled', style: AppTypography.bodyMd.copyWith(color: AppColors.onErrorContainer, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          else
            Stack(
              children: [
                // Background line
                Positioned(
                  left: 20,
                  top: 24,
                  bottom: 24,
                  width: 2,
                  child: Container(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                ),
                // Progress line
                if (currentIndex >= 0)
                  Positioned(
                    left: 20,
                    top: 24,
                    bottom: 24, 
                    width: 2,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final totalNodes = nodes.length;
                        final progressRatio = (currentIndex) / (totalNodes - 1);
                        return Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            height: constraints.maxHeight * progressRatio,
                            color: AppColors.secondary,
                          ),
                        );
                      }
                    ),
                  ),
                
                Column(
                  children: List.generate(nodes.length, (index) {
                    final stage = nodes[index];
                    final isCompleted = index < currentIndex;
                    final isActive = index == currentIndex;
                    final isPending = index > currentIndex;

                    final activeActivities = isActive ? activities.take(2).toList() : <ActivityLog>[];

                    return _buildNode(
                      stage: stage,
                      isCompleted: isCompleted,
                      isActive: isActive,
                      isPending: isPending,
                      activities: activeActivities,
                      isLast: index == nodes.length - 1,
                    );
                  }),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNode({
    required _TimelineStage stage,
    required bool isCompleted,
    required bool isActive,
    required bool isPending,
    required List<ActivityLog> activities,
    required bool isLast,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Node icon
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: AppSpacing.lg),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? AppColors.secondary : (isActive ? Colors.white : AppColors.surface),
              border: Border.all(
                color: isCompleted ? Colors.white : (isActive ? AppColors.secondary : AppColors.outlineVariant.withValues(alpha: 0.5)),
                width: isCompleted ? 4 : 2,
              ),
              boxShadow: isActive ? [
                BoxShadow(color: AppColors.secondary.withValues(alpha: 0.3), blurRadius: 15)
              ] : null,
            ),
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : (isActive
                    ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.secondary)))
                    : null),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.label,
                    style: AppTypography.buttonText.copyWith(
                      color: isActive ? AppColors.secondary : (isPending ? AppColors.outline : AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stage.description,
                    style: AppTypography.bodyMd.copyWith(
                      color: isActive ? AppColors.primary : AppColors.outline,
                      fontSize: 14,
                    ),
                  ),
                  if (isActive && activities.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: activities.map((act) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sanitiseActivityDetails(act.details), style: AppTypography.bodyMd.copyWith(fontSize: 13, color: AppColors.onSurfaceVariant)),
                              Text('${act.actorRole} • ${DateFormat('MMM d, h:mm a').format(act.createdAt)}', style: AppTypography.labelMono.copyWith(fontSize: 10, color: AppColors.outline)),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStage {
  final String label;
  final String description;
  final ProjectStatus status;

  _TimelineStage(this.label, this.description, this.status);
}
