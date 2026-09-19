import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:archi_draft/src/core/theme/app_colors.dart';
import 'package:archi_draft/src/core/theme/app_spacing.dart';
import 'package:archi_draft/src/core/theme/app_typography.dart';
import 'package:archi_draft/src/shared/widgets/app_state_widgets.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/domain/project_status.dart';
import 'package:archi_draft/src/features/projects/providers/project_form_controller.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/projects/providers/file_providers.dart';
import 'package:uuid/uuid.dart';

import 'widgets/project_status_chip.dart';
import 'widgets/activity_timeline.dart';
import 'widgets/file_attachment_card.dart';
import 'widgets/file_upload_button.dart';
import 'widgets/correction_dialog.dart';

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
          style: AppTypography.buttonText.copyWith(color: AppColors.onSurface),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/client/projects'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_money),
            tooltip: 'Financials',
            onPressed: () =>
                context.push('/client/projects/$projectId/financials'),
          ),
        ],
      ),
      body: projectAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Loading project...'),
        error: (error, _) => AppErrorWidget(
          message: 'Failed to load project.',
          onRetry: () => ref.invalidate(projectProvider(projectId)),
        ),
        data: (project) {
          if (project == null) {
            return const AppErrorWidget(message: 'Project not found.');
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
              style: AppTypography.bodySm.copyWith(color: AppColors.outline),
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
                project.drawingTypeEnum?.displayName ?? project.drawingType,
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

          // DRAWING VERSIONS SECTION (For UNDER_CLIENT_REVIEW or COMPLETED)
          if (status == ProjectStatus.underClientReview ||
              status == ProjectStatus.completed) ...[
            _buildDetailSection(
              title: 'DRAWING VERSIONS',
              fields: [],
              customContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ref
                      .watch(projectDrawingVersionsProvider(project.projectId))
                      .when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: CircularProgressIndicator(),
                        ),
                        error: (err, stack) => Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text(
                            'Error loading versions: $err',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                        data: (versions) {
                          if (versions.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: Text(
                                'No drawings submitted yet.',
                                style: TextStyle(color: AppColors.outline),
                              ),
                            );
                          }

                          final currentVersion = versions.first;

                          return Column(
                            children: [
                              // Latest Version
                              ListTile(
                                title: Text(
                                  'Version ${currentVersion.versionNumber} (Latest)',
                                  style: AppTypography.bodyMd.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Uploaded: ${DateFormat('MMM d, yyyy').format(currentVersion.createdAt ?? DateTime.now())}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.download),
                                  onPressed: () {
                                    // download currentVersion.fileId
                                  },
                                ),
                              ),

                              // Notice about Redline Viewer gap
                              if (status == ProjectStatus.underClientReview)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.sm,
                                      ),
                                      border: Border.all(
                                        color: AppColors.primary.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            'Note: The integrated Redline/Markup viewer is planned for a future update. For now, please download the file to review and describe your corrections below.',
                                            style: AppTypography.bodySm
                                                .copyWith(
                                                  color: AppColors.primary,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Actions if UNDER_CLIENT_REVIEW
                              if (status == ProjectStatus.underClientReview)
                                Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) =>
                                                  CorrectionDialog(
                                                    projectId:
                                                        project.projectId,
                                                    targetVersionId:
                                                        currentVersion.id,
                                                  ),
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.error,
                                            side: const BorderSide(
                                              color: AppColors.error,
                                            ),
                                          ),
                                          child: const Text(
                                            'Request Correction',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: () async {
                                            final confirm =
                                                await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                        title: const Text(
                                                          'Approve Final Drawing',
                                                        ),
                                                        content: const Text(
                                                          'Are you sure you want to approve this drawing? This marks the project as COMPLETED.',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                context.pop(
                                                                  false,
                                                                ),
                                                            child: const Text(
                                                              'Cancel',
                                                            ),
                                                          ),
                                                          FilledButton(
                                                            onPressed: () =>
                                                                context.pop(
                                                                  true,
                                                                ),
                                                            child: const Text(
                                                              'Approve',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                );

                                            if (confirm == true) {
                                              try {
                                                await ref
                                                    .read(
                                                      projectRepositoryProvider,
                                                    )
                                                    .approveFinal(
                                                      projectId:
                                                          project.projectId,
                                                      actionId: const Uuid()
                                                          .v4(),
                                                    );
                                                ref.invalidate(
                                                  projectProvider(
                                                    project.projectId,
                                                  ),
                                                );
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Error: $e',
                                                          ),
                                                        ),
                                                      );
                                                }
                                              }
                                            }
                                          },
                                          child: const Text('Approve Final'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              if (versions.length > 1) ...[
                                const Divider(),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  child: Text(
                                    'Previous Versions',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.outline,
                                    ),
                                  ),
                                ),
                                ...versions
                                    .skip(1)
                                    .map(
                                      (v) => ListTile(
                                        title: Text(
                                          'Version ${v.versionNumber}',
                                          style: AppTypography.bodyMd,
                                        ),
                                        subtitle: Text(
                                          DateFormat('MMM d, yyyy').format(
                                            v.createdAt ?? DateTime.now(),
                                          ),
                                        ),
                                      ),
                                    ),
                              ],
                            ],
                          );
                        },
                      ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // CORRECTIONS SECTION
            _buildDetailSection(
              title: 'CORRECTIONS HISTORY',
              fields: [],
              customContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ref
                      .watch(projectCorrectionsProvider(project.projectId))
                      .when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: CircularProgressIndicator(),
                        ),
                        error: (err, stack) => Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text('Error: $err'),
                        ),
                        data: (corrections) {
                          if (corrections.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: Text(
                                'No corrections requested.',
                                style: TextStyle(color: AppColors.outline),
                              ),
                            );
                          }

                          return Column(
                            children: corrections
                                .map(
                                  (c) => ListTile(
                                    title: Text(
                                      'Round ${c.roundNumber} - ${c.status.label}',
                                      style: AppTypography.bodyMd.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${c.description}\nRequested: ${DateFormat('MMM d, yyyy').format(c.createdAt)}',
                                    ),
                                    isThreeLine: true,
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // AUDIT / TIMELINE SECTION
            _buildDetailSection(
              title: 'ACTIVITY TIMELINE',
              fields: [],
              customContent: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: ActivityTimeline(projectId: project.projectId),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],

          // Reference Files Section
          _buildDetailSection(
            title: 'REFERENCE FILES',
            fields: [],
            customContent: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ref
                    .watch(projectFilesProvider(project.projectId))
                    .when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: CircularProgressIndicator(),
                      ),
                      error: (err, stack) => Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          'Error loading files: $err',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                      data: (files) {
                        final clientFiles = files
                            .where((f) => f.category == 'client_upload')
                            .toList();
                        if (clientFiles.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Text(
                              'No reference files attached.',
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.outline,
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: clientFiles
                              .map((f) => FileAttachmentCard(file: f))
                              .toList(),
                        );
                      },
                    ),
                if (status == ProjectStatus.draft) ...[
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FileUploadButton(
                        projectId: project.projectId,
                        category: 'client_upload',
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
    Widget? customContent,
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
                bottom: BorderSide(color: AppColors.outlineVariant, width: 0.5),
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
          if (customContent != null) customContent,
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
