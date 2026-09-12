import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:archi_draft/src/core/theme/app_colors.dart';
import 'package:archi_draft/src/core/theme/app_spacing.dart';
import 'package:archi_draft/src/core/theme/app_typography.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../domain/drawing_type.dart';
import '../../domain/project.dart';
import '../../domain/project_status.dart';
import '../../providers/project_form_controller.dart';
import '../../providers/project_providers.dart';
import 'widgets/project_status_chip.dart';

/// Detail screen for viewing a project.
///
/// Draft mode: Shows project data with "Continue Editing" and "Submit" buttons.
/// Submitted mode: Read-only display with status and timestamps.
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
          // Header: Status + Project Name
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

          // Submitted timestamp
          if (status == ProjectStatus.submitted &&
              project.submittedAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Submitted on ${DateFormat('MMMM d, yyyy \'at\' h:mm a').format(project.submittedAt!)}',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.outline,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),

          // Project Information Section
          _buildDetailSection(
            title: 'PROJECT INFORMATION',
            fields: [
              _DetailField('Project Name', project.projectName),
              _DetailField('Project Address', project.projectAddress),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Drawing Requirements Section
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

          // Dimensions & Budget Section
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

          const SizedBox(height: AppSpacing.xxl),

          // Action Buttons
          if (status == ProjectStatus.draft) ...[
            // Continue Editing Button
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
          ],

          const SizedBox(height: 100), // Bottom spacing
        ],
      ),
    );
  }

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
