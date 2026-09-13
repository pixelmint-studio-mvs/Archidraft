import 'package:flutter/material.dart';

import 'package:archi_draft/src/core/theme/app_colors.dart';
import 'package:archi_draft/src/core/theme/app_spacing.dart';
import 'package:archi_draft/src/core/theme/app_typography.dart';

import '../../domain/project_status.dart';

/// A styled chip displaying the project status.
///
/// Uses semantic colors per BRAND_AND_DESIGN_DIRECTION.md:
/// - Draft: Grey
/// - Submitted: Blue
/// - In Progress: Amber
/// - Completed: Green
/// - Cancelled: Red
class ProjectStatusChip extends StatelessWidget {
  final ProjectStatus status;

  const ProjectStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        border: Border.all(color: _borderColor, width: 0.5),
      ),
      child: Text(
        status.toFirestoreString(),
        style: AppTypography.labelMono.copyWith(
          color: _textColor,
          fontSize: 10,
        ),
      ),
    );
  }

  Color get _backgroundColor {
    switch (status) {
      case ProjectStatus.draft:
        return AppColors.surfaceContainerHigh;
      case ProjectStatus.submitted:
        return AppColors.secondaryFixed;
      case ProjectStatus.waitingAssignment:
      case ProjectStatus.waitingAcceptance:
        return AppColors.warningContainer;
      case ProjectStatus.inProgress:
        return AppColors.warningContainer;
      case ProjectStatus.underClientReview:
        return AppColors.secondaryFixed;
      case ProjectStatus.completed:
        return AppColors.successContainer;
      case ProjectStatus.cancelled:
        return AppColors.errorContainer;
    }
  }

  Color get _textColor {
    switch (status) {
      case ProjectStatus.draft:
        return AppColors.onSurfaceVariant;
      case ProjectStatus.submitted:
        return AppColors.onSecondaryFixed;
      case ProjectStatus.waitingAssignment:
      case ProjectStatus.waitingAcceptance:
        return AppColors.onSurface;
      case ProjectStatus.inProgress:
        return AppColors.onSurface;
      case ProjectStatus.underClientReview:
        return AppColors.onSecondaryFixed;
      case ProjectStatus.completed:
        return AppColors.onTertiaryContainer;
      case ProjectStatus.cancelled:
        return AppColors.onErrorContainer;
    }
  }

  Color get _borderColor {
    switch (status) {
      case ProjectStatus.draft:
        return AppColors.outlineVariant;
      case ProjectStatus.submitted:
        return AppColors.secondary;
      case ProjectStatus.waitingAssignment:
      case ProjectStatus.waitingAcceptance:
        return AppColors.warning;
      case ProjectStatus.inProgress:
        return AppColors.warning;
      case ProjectStatus.underClientReview:
        return AppColors.secondary;
      case ProjectStatus.completed:
        return AppColors.success;
      case ProjectStatus.cancelled:
        return AppColors.error;
    }
  }
}
