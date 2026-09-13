import 'package:flutter/material.dart';

import 'package:archi_draft/src/core/theme/app_colors.dart';
import 'package:archi_draft/src/core/theme/app_spacing.dart';
import 'package:archi_draft/src/core/theme/app_typography.dart';

import '../../domain/drawing_type.dart';
import '../../providers/project_form_controller.dart';

/// Read-only summary of all project brief fields for the review step.
///
/// Displays all entered data with "Edit" links back to specific steps.
class ProjectReviewSection extends StatelessWidget {
  final ProjectFormState formState;
  final ValueChanged<int> onEditStep;

  const ProjectReviewSection({
    super.key,
    required this.formState,
    required this.onEditStep,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Your Project',
            style: AppTypography.headlineLgMobile.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Please review all details before submitting.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Submission readiness indicator
          if (!formState.isReadyForSubmission) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Some required fields are incomplete. Please go back and fill them in.',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Section 1: Project Information
          _buildSection(
            title: 'PROJECT INFORMATION',
            stepIndex: 0,
            isValid: formState.isStep1Valid,
            fields: [
              _buildField('Project Name', formState.projectName),
              _buildField('Project Address', formState.projectAddress),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Section 2: Drawing Requirements
          _buildSection(
            title: 'DRAWING REQUIREMENTS',
            stepIndex: 1,
            isValid: formState.isStep2Valid,
            fields: [
              _buildField('Drawing Name', formState.drawingName),
              _buildField(
                'Drawing Type',
                DrawingType.fromString(formState.drawingType)?.displayName ??
                    formState.drawingType,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Section 3: Dimensions & Budget
          _buildSection(
            title: 'DIMENSIONS & BUDGET',
            stepIndex: 2,
            isValid: formState.isStep3Valid,
            fields: [
              _buildField(
                'Project Area',
                formState.projectArea.isEmpty
                    ? ''
                    : '${formState.projectArea} sq ft',
              ),
              _buildField(
                'Estimated Budget',
                formState.estimatedAmount.isEmpty
                    ? 'Not specified'
                    : formState.estimatedAmount,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required int stepIndex,
    required bool isValid,
    required List<Widget> fields,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isValid
              ? AppColors.outlineVariant
              : AppColors.error.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
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
                bottom: BorderSide(color: AppColors.outlineVariant, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                if (isValid)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 16,
                  )
                else
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 16,
                  ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.labelMono.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => onEditStep(stepIndex),
                  child: Text(
                    'EDIT',
                    style: AppTypography.labelMono.copyWith(
                      color: AppColors.secondary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Fields
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: fields,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, String value) {
    final isEmpty = value.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelMono.copyWith(
              color: AppColors.outline,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isEmpty ? '— Not provided —' : value,
            style: AppTypography.bodyMd.copyWith(
              color: isEmpty ? AppColors.error : AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
