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
  final int? correctionRound;
  final bool useHumanLabel;

  const ProjectStatusChip({
    super.key,
    required this.status,
    this.correctionRound,
    this.useHumanLabel = false,
  });

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
        _displayText,
        style: AppTypography.labelMono.copyWith(
          color: _textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String get _displayText {
    if (status == ProjectStatus.completed) {
      return 'COMPLETED';
    }
    if (status == ProjectStatus.cancelled) {
      return 'CANCELLED';
    }
    if (correctionRound != null && correctionRound! > 0 && status == ProjectStatus.inProgress) {
      return 'Correction Round $correctionRound';
    }
    if (useHumanLabel) {
      switch (status) {
        case ProjectStatus.underAdminReview:
          return 'Waiting for Studio Review';
        case ProjectStatus.underEngineerReview:
          return 'Waiting for Your Review';
        case ProjectStatus.completed:
          return 'COMPLETED';
        case ProjectStatus.inProgress:
          return 'In Drafting';
        case ProjectStatus.waitingAssignment:
          return 'Needs Draughtsman';
        case ProjectStatus.waitingAcceptance:
          return 'Awaiting Acceptance';
        case ProjectStatus.submitted:
          return 'Submitted';
        case ProjectStatus.draft:
          return 'Draft';
        case ProjectStatus.cancelled:
          return 'CANCELLED';
      }
    }
    return status.toFirestoreString();
  }

  Color get _backgroundColor {
    if (correctionRound != null && correctionRound! > 0 && status == ProjectStatus.inProgress) {
      return const Color(0xFFFEF3C7); // amber-100
    }
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
      case ProjectStatus.underAdminReview:
        return const Color(0xFFFEF3C7);
      case ProjectStatus.underEngineerReview:
        return const Color(0xFFE0F2FE); // light sky blue
      case ProjectStatus.completed:
        return AppColors.successContainer;
      case ProjectStatus.cancelled:
        return AppColors.errorContainer;
    }
  }

  Color get _textColor {
    if (correctionRound != null && correctionRound! > 0 && status == ProjectStatus.inProgress) {
      return const Color(0xFF92400E); // amber-800
    }
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
      case ProjectStatus.underAdminReview:
        return const Color(0xFFB45309);
      case ProjectStatus.underEngineerReview:
        return const Color(0xFF0369A1);
      case ProjectStatus.completed:
        return AppColors.onTertiaryContainer;
      case ProjectStatus.cancelled:
        return AppColors.onErrorContainer;
    }
  }

  Color get _borderColor {
    if (correctionRound != null && correctionRound! > 0 && status == ProjectStatus.inProgress) {
      return const Color(0xFFF59E0B);
    }
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
      case ProjectStatus.underAdminReview:
        return const Color(0xFFF59E0B);
      case ProjectStatus.underEngineerReview:
        return const Color(0xFF38BDF8);
      case ProjectStatus.completed:
        return AppColors.success;
      case ProjectStatus.cancelled:
        return AppColors.error;
    }
  }
}
