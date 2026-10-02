import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../domain/project.dart';
import '../../domain/project_status.dart';
import '../../providers/project_providers.dart';
import '../../providers/file_providers.dart';
import '../../providers/assignment_providers.dart';
import '../widgets/project_status_chip.dart';
import '../widgets/file_upload_button.dart';
import '../widgets/file_attachment_card.dart';

/// Workspace screen for a student working on an assigned training project.
///
/// Unlike the normal ProjectDetailScreen, this allows staging a "workspace_draft"
/// before officially submitting the drawing version for review.
class StudentProjectWorkspaceScreen extends ConsumerWidget {
  final String projectId;

  const StudentProjectWorkspaceScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectProvider(projectId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Project Workspace',
          style: AppTypography.buttonText.copyWith(color: AppColors.onSurface),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/student/projects'),
        ),
      ),
      body: projectAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Loading workspace...'),
        error: (error, _) => AppErrorWidget(
          message: 'Failed to load workspace.',
          onRetry: () => ref.invalidate(projectProvider(projectId)),
        ),
        data: (project) {
          if (project == null) {
            return const AppErrorWidget(message: 'Project not found.');
          }
          if (project.projectStatus != ProjectStatus.inProgress) {
            // If the project is no longer in progress, fallback to project detail screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/student/projects/$projectId');
            });
            return const SizedBox();
          }
          return _buildWorkspace(context, ref, project);
        },
      ),
    );
  }

  Widget _buildWorkspace(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProjectStatusChip(status: project.projectStatus ?? ProjectStatus.draft),
              const Spacer(),
              if (project.createdAt != null)
                Text(
                  DateFormat('MMM d, yyyy').format(project.createdAt!),
                  style: AppTypography.labelMono.copyWith(color: AppColors.outline),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            project.projectName.isEmpty ? 'Untitled Project' : project.projectName,
            style: AppTypography.headlineLg.copyWith(
              color: AppColors.onSurface,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Project Information Section
          _buildDetailSection(
            title: 'DRAWING REQUIREMENTS',
            fields: [
              _DetailField('Drawing Name', project.drawingName),
              _DetailField(
                'Drawing Type',
                project.drawingTypeEnum?.displayName ?? project.drawingType,
              ),
              _DetailField('Project Address', project.projectAddress),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Workspace Draft Section
          _buildDetailSection(
            title: 'YOUR WORKSPACE DRAFT',
            fields: [],
            customContent: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: Text(
                    'Upload your work in progress here. You can update this file as many times as you want before submitting.',
                    style: TextStyle(color: AppColors.outline),
                  ),
                ),
                ref.watch(projectFilesProvider(project.projectId)).when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text('Error loading files: $err', style: const TextStyle(color: AppColors.error)),
                  ),
                  data: (files) {
                    // Find the latest workspace_draft file
                    final draftFiles = files.where((f) => f.category == 'workspace_draft').toList();
                    draftFiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    final currentDraft = draftFiles.isNotEmpty ? draftFiles.first : null;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (currentDraft != null)
                          FileAttachmentCard(file: currentDraft)
                        else
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Text(
                              'No draft uploaded yet.',
                              style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: SizedBox(
                            width: double.infinity,
                            child: FileUploadButton(
                              projectId: project.projectId,
                              category: 'workspace_draft',
                            ),
                          ),
                        ),
                        if (currentDraft != null) ...[
                          const SizedBox(height: AppSpacing.xl),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Submit Drawing'),
                                    content: const Text(
                                      'Are you sure you want to submit your current draft for review? You will not be able to edit it until the reviewer provides feedback.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Submit'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true && context.mounted) {
                                  final success = await ref
                                      .read(draughtsmanActionsControllerProvider.notifier)
                                      .submitDrawing(
                                        projectId: project.projectId,
                                        draftFileId: currentDraft.id,
                                      );
                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Drawing submitted successfully')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.send_rounded, size: 18),
                              label: const Text('Submit Drawing'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required List<_DetailField> fields,
    Widget? customContent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelMono.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: customContent ??
              Column(
                children: [
                  for (var i = 0; i < fields.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              fields[i].label,
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.outline,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              fields[i].value,
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < fields.length - 1)
                      const Divider(height: 1, color: AppColors.surfaceVariant),
                  ],
                ],
              ),
        ),
      ],
    );
  }
}

class _DetailField {
  final String label;
  final String value;

  _DetailField(this.label, this.value);
}
