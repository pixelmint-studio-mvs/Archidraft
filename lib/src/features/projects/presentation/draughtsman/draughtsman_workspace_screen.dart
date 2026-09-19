import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../domain/project.dart';
import '../../domain/project_status.dart';
import '../../../../features/auth/providers/auth_providers.dart';
import '../../providers/project_providers.dart';
import '../../providers/file_providers.dart';
import '../../providers/assignment_providers.dart';
import '../widgets/project_status_chip.dart';
import '../widgets/file_attachment_card.dart';
import '../widgets/file_upload_button.dart';
import '../../domain/correction.dart';

class DraughtsmanWorkspaceScreen extends ConsumerWidget {
  final String projectId;

  const DraughtsmanWorkspaceScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectProvider(projectId));
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Workspace'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: projectAsync.when(
        loading: () =>
            const AppLoadingIndicator(message: 'Loading workspace...'),
        error: (error, _) => AppErrorWidget(
          message: 'Failed to load project.',
          onRetry: () => ref.invalidate(projectProvider(projectId)),
        ),
        data: (project) {
          if (project == null) {
            return const AppErrorWidget(message: 'Project not found.');
          }

          final userProfile = userProfileAsync.value;
          final role = userProfile?.role;

          if (role == 'DRAUGHTSMAN') {
            final status = project.projectStatus ?? ProjectStatus.draft;
            if (status.index < ProjectStatus.inProgress.index) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_rounded, size: 64, color: AppColors.error),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Workspace Locked',
                      style: AppTypography.headlineLgMobile,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'You must accept the assignment before accessing the workspace.',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );
            }
          }

          return _buildWorkspace(context, ref, project);
        },
      ),
    );
  }

  Widget _buildWorkspace(BuildContext context, WidgetRef ref, Project project) {
    final status = project.projectStatus ?? ProjectStatus.draft;
    final isLoadingAction = ref
        .watch(draughtsmanActionsControllerProvider)
        .isLoading;
    final correctionsAsync = ref.watch(projectCorrectionsProvider(projectId));
    final hasOpenCorrection = correctionsAsync.maybeWhen(
      data: (corrections) => corrections.any((c) => c.status == CorrectionStatus.open),
      orElse: () => false,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [ProjectStatusChip(status: status)]),
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
          const SizedBox(height: AppSpacing.xl),

          // Project Requirements
          _buildRequirementsCard(project),

          const SizedBox(height: AppSpacing.xxl),

          // Client Reference Files
          _buildFilesSection(
            context,
            ref,
            title: 'CLIENT REFERENCE FILES',
            category: 'client_upload',
            emptyMessage: 'No reference files attached.',
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Active Correction Alert (If any)
          if (status == ProjectStatus.inProgress)
            correctionsAsync.maybeWhen(
              data: (corrections) {
                try {
                  final activeCorrection = corrections.firstWhere((c) => c.status == CorrectionStatus.open || c.status == CorrectionStatus.inProgress);
                  final isOpen = activeCorrection.status == CorrectionStatus.open;
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xxl),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: isOpen ? AppColors.errorContainer : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: isOpen ? AppColors.error : AppColors.primary),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(isOpen ? Icons.warning_amber_rounded : Icons.info_outline_rounded, color: isOpen ? AppColors.error : AppColors.primary),
                            const SizedBox(width: AppSpacing.sm),
                            Text('ACTIVE CORRECTION (Round ${activeCorrection.roundNumber})', 
                              style: AppTypography.labelMono.copyWith(color: isOpen ? AppColors.onErrorContainer : AppColors.onSurface, fontWeight: FontWeight.bold)
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(activeCorrection.description, style: AppTypography.bodyMd.copyWith(color: isOpen ? AppColors.onErrorContainer : AppColors.onSurface)),
                        if (isOpen) ...[
                          const SizedBox(height: AppSpacing.md),
                          FilledButton(
                            onPressed: isLoadingAction ? null : () {
                              ref.read(draughtsmanActionsControllerProvider.notifier).startCorrection(
                                projectId: projectId,
                                correctionId: activeCorrection.id,
                              );
                            },
                            child: const Text('Start Working'),
                          ),
                        ],
                      ],
                    ),
                  );
                } catch (_) {
                  return const SizedBox.shrink();
                }
              },
              orElse: () => const SizedBox.shrink(),
            ),

          if (status == ProjectStatus.inProgress &&
              correctionsAsync.hasValue &&
              correctionsAsync.value!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              child: _buildFilesSection(
                context,
                ref,
                title: 'CORRECTION ATTACHMENTS',
                category: 'correction_attachment',
                emptyMessage: 'No attachments provided for correction.',
              ),
            ),

          // Draughtsman Drawing Versions
          _buildFilesSection(
            context,
            ref,
            title: 'YOUR DRAWINGS',
            category: 'draughtsman_version',
            emptyMessage: 'No drawings uploaded yet.',
            showUploadButton: status == ProjectStatus.inProgress && !hasOpenCorrection,
          ),

          const SizedBox(height: AppSpacing.xxl),

          if (isLoadingAction)
            const Center(child: CircularProgressIndicator())
          else if (status == ProjectStatus.inProgress)
            _buildSubmitButton(context, ref, project),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildFilesSection(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String category,
    required String emptyMessage,
    bool showUploadButton = false,
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

          ref
              .watch(projectFilesProvider(projectId))
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
                  final categorizedFiles = files
                      .where((f) => f.category == category)
                      .toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (categorizedFiles.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Text(
                            emptyMessage,
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.outline,
                            ),
                          ),
                        )
                      else
                        Column(
                          children: categorizedFiles
                              .map((f) => FileAttachmentCard(file: f))
                              .toList(),
                        ),

                      if (showUploadButton) ...[
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: FileUploadButton(
                              projectId: projectId,
                              category: category,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                    ],
                  );
                },
              ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final filesAsync = ref.watch(projectFilesProvider(projectId));

        // We only enable submit if there is at least one draughtsman_version file
        final hasFiles = filesAsync.maybeWhen(
          data: (files) => files.any(
            (f) =>
                f.category == 'draughtsman_version' && f.status == 'COMPLETED',
          ),
          orElse: () => false,
        );

        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: hasFiles ? () => _handleSubmit(context, ref) : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            ),
            child: const Text('Submit for Client Review'),
          ),
        );
      },
    );
  }

  void _handleSubmit(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(draughtsmanActionsControllerProvider.notifier)
        .submitDrawing(projectId: projectId);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drawing submitted successfully!')),
      );
      context.pop();
    }
  }

  Widget _buildRequirementsCard(Project project) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROJECT REQUIREMENTS',
            style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          _RequirementRow(label: 'Drawing Type', value: project.drawingType.isNotEmpty ? project.drawingType : 'Not specified'),
          const SizedBox(height: AppSpacing.md),
          _RequirementRow(label: 'Project Area', value: (project.projectArea != null && project.projectArea! > 0) ? '${project.projectArea} sq ft' : 'Not specified'),
          const SizedBox(height: AppSpacing.md),
          _RequirementRow(label: 'Address', value: project.projectAddress.isNotEmpty ? project.projectAddress : 'Not specified'),
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final String label;
  final String value;

  const _RequirementRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          ),
        ),
      ],
    );
  }
}
