import 'package:flutter/material.dart';

import 'package:archi_draft/src/core/theme/app_colors.dart';
import 'package:archi_draft/src/core/theme/app_spacing.dart';
import 'package:archi_draft/src/core/theme/app_typography.dart';

/// Step indicator for the multi-step project form.
///
/// Displays step circles connected by lines, with distinct states:
/// - Completed: Blue filled circle with checkmark
/// - Active: Blue outlined circle with step number
/// - Upcoming: Grey outlined circle with step number
class ProjectFormStepper extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepTitles;

  const ProjectFormStepper({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepTitles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIndex = index ~/ 2;
            return Expanded(
              child: Container(
                height: 1,
                color: stepIndex < currentStep
                    ? AppColors.secondary
                    : AppColors.outlineVariant,
              ),
            );
          }
          // Step circle
          final stepIndex = index ~/ 2;
          return _buildStepCircle(stepIndex);
        }),
      ),
    );
  }

  Widget _buildStepCircle(int stepIndex) {
    final isCompleted = stepIndex < currentStep;
    final isActive = stepIndex == currentStep;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.secondary
                : isActive
                ? AppColors.surfaceContainerLowest
                : AppColors.surfaceContainerLowest,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted || isActive
                  ? AppColors.secondary
                  : AppColors.outlineVariant,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppColors.onSecondary,
                  )
                : Text(
                    '${stepIndex + 1}',
                    style: AppTypography.buttonText.copyWith(
                      color: isActive ? AppColors.secondary : AppColors.outline,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: 64,
          child: Text(
            stepIndex < stepTitles.length ? stepTitles[stepIndex] : '',
            style: AppTypography.labelMono.copyWith(
              color: isActive
                  ? AppColors.secondary
                  : isCompleted
                  ? AppColors.onSurface
                  : AppColors.outline,
              fontSize: 8,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
