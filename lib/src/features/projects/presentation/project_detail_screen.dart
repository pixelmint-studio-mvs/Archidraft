import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:archi_draft/src/core/theme/app_colors.dart';
import 'package:archi_draft/src/core/theme/app_spacing.dart';
import 'package:archi_draft/src/core/theme/app_typography.dart';
import 'package:archi_draft/src/shared/widgets/app_state_widgets.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/domain/project_status.dart';
import 'package:archi_draft/src/features/projects/providers/project_form_controller.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/projects/providers/file_providers.dart';
import 'package:archi_draft/src/features/api/providers/api_providers.dart';
import 'package:uuid/uuid.dart';

import 'widgets/file_attachment_card.dart';
import 'widgets/file_upload_button.dart';
import 'widgets/correction_dialog.dart';
import 'widgets/workflow_timeline_widget.dart';

/// Detail screen for viewing a project.
///
/// Implements the Stitch 12-column Bento Grid layout for the Engineer.
class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectProvider(projectId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Project Details',
          style: AppTypography.buttonText.copyWith(color: AppColors.onSurface),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/engineer/projects'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_money),
            tooltip: 'Financials',
            onPressed: () => context.push('/engineer/projects/$projectId/financials'),
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

  Widget _buildProjectDetail(BuildContext context, WidgetRef ref, Project project) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _BlueprintGridPainter(),
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, ref, project),
                  const SizedBox(height: AppSpacing.xxl),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 1024) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 8, child: _buildMainArea(context, ref, project)),
                            const SizedBox(width: AppSpacing.gridGutter),
                            Expanded(flex: 4, child: _buildSideArea(context, ref, project)),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildMainArea(context, ref, project),
                            const SizedBox(height: AppSpacing.gridGutter),
                            _buildSideArea(context, ref, project),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, Project project) {
    final status = project.projectStatus ?? ProjectStatus.draft;
    
    // Status color mapping for the badge
    Color badgeColor = AppColors.surfaceContainerHigh;
    Color badgeTextColor = AppColors.onSurfaceVariant;
    if (status == ProjectStatus.underClientReview) {
      badgeColor = AppColors.tertiaryFixed;
      badgeTextColor = AppColors.onTertiaryContainer;
    } else if (status == ProjectStatus.completed) {
      badgeColor = AppColors.secondaryFixed;
      badgeTextColor = AppColors.onSecondaryFixed;
    } else if (status == ProjectStatus.draft) {
      badgeColor = AppColors.surfaceVariant;
    } else {
      badgeColor = AppColors.primaryContainer.withValues(alpha: 0.1);
      badgeTextColor = AppColors.primary;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final headerContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    project.projectId.substring(0, 8).toUpperCase(),
                    style: AppTypography.labelMono.copyWith(color: AppColors.outline),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'STATUS: ${status.toFirestoreString()}',
                    style: AppTypography.labelMono.copyWith(color: badgeTextColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              project.projectName.isEmpty ? 'Untitled Project' : project.projectName,
              style: (isMobile ? AppTypography.headlineLgMobile : AppTypography.headlineDisplay).copyWith(color: AppColors.primary),
            ),
          ],
        );

        final actions = _buildHeaderActions(context, ref, project, status);

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              headerContent,
              if (actions != null) ...[
                const SizedBox(height: AppSpacing.lg),
                actions,
              ],
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: headerContent),
            actions ?? const SizedBox.shrink(),
          ],
        );
      }
    );
  }

  Widget? _buildHeaderActions(BuildContext context, WidgetRef ref, Project project, ProjectStatus status) {
    if (status == ProjectStatus.draft) {
      return FilledButton.icon(
        onPressed: () {
          ref.read(projectFormControllerProvider.notifier).loadDraft(project);
          context.go('/engineer/projects/new');
        },
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('Continue Editing'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.onSecondary,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        ),
      );
    } else if (status == ProjectStatus.underClientReview) {
      return Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        alignment: WrapAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => CorrectionDialog(
                  projectId: project.projectId,
                  targetVersionId: 'latest', 
                ),
              );
            },
            icon: const Icon(Icons.rate_review),
            label: const Text('Request Revision'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
            ),
          ),
          FilledButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Approve Final Drawing'),
                  content: const Text('Are you sure you want to approve this drawing? This marks the project as COMPLETED.'),
                  actions: [
                    TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => context.pop(true), child: const Text('Approve')),
                  ],
                ),
              );
              
              if (confirm == true) {
                try {
                  await ref.read(projectRepositoryProvider).approveFinal(
                    projectId: project.projectId,
                    actionId: const Uuid().v4(),
                  );
                  ref.invalidate(projectProvider(project.projectId));
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Approve Final'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
            ),
          ),
        ],
      );
    }
    return null;
  }

  Widget _buildMainArea(BuildContext context, WidgetRef ref, Project project) {
    return Column(
      children: [
        // Drawing Versions / Comparison
        if (project.projectStatus == ProjectStatus.underClientReview || project.projectStatus == ProjectStatus.completed)
          _buildDrawingComparisonSection(context, ref, project)
        else
          _buildSectionCard(
            title: 'Drawing Versions',
            child: Container(
              height: 300,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.layers_outlined, size: 48, color: AppColors.outline),
                  const SizedBox(height: AppSpacing.md),
                  Text('Drawings will appear here once submitted by the draughtsman.', 
                    style: AppTypography.bodyMd.copyWith(color: AppColors.outlineVariant)
                  ),
                ],
              ),
            ),
          ),
          
        const SizedBox(height: AppSpacing.gridGutter),
        
        // Reference files / Upload (for Draft)
        _buildSectionCard(
          title: 'Reference Files',
          child: ref.watch(projectFilesProvider(project.projectId)).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorWidget(
              message: 'Failed to load reference files.',
              onRetry: () => ref.invalidate(projectFilesProvider(project.projectId)),
            ),
            data: (files) {
              final clientFiles = files.where((f) => f.category == 'client_upload' && f.status != 'FAILED').toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (clientFiles.isEmpty)
                    const Text('No reference files attached.', style: TextStyle(color: AppColors.outline))
                  else
                    ...clientFiles.map((f) => FileAttachmentCard(file: f)),
                  
                  if (project.projectStatus == ProjectStatus.draft) ...[
                    const SizedBox(height: AppSpacing.md),
                    FileUploadButton(projectId: project.projectId, category: 'client_upload'),
                  ]
                ],
              );
            }
          ),
        ),
      ],
    );
  }

  Widget _buildDrawingComparisonSection(BuildContext context, WidgetRef ref, Project project) {
    return ref.watch(projectDrawingVersionsProvider(project.projectId)).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorWidget(
        message: 'Failed to load drawings.',
        onRetry: () => ref.invalidate(projectDrawingVersionsProvider(project.projectId)),
      ),
      data: (versions) {
        if (versions.isEmpty) {
          return _buildSectionCard(
            title: 'Drawing Versions',
            child: const Text('No drawings submitted yet.', style: TextStyle(color: AppColors.outline)),
          );
        }

        final current = versions.first;
        final headersAsync = ref.watch(authHeadersProvider);

        return _buildSectionCard(
          title: 'Drawing Viewer',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Viewer Toolbar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Version ${current.versionNumber} (Latest)', style: AppTypography.labelMono.copyWith(color: Colors.white)),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Action handled via file provider or separate trigger in a real app
                    },
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Viewer Frame
              Container(
                height: 400,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: headersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => const Center(child: Text('Failed to load credentials')),
                  data: (headers) {
                    final isImage = current.originalName?.toLowerCase().endsWith('.png') == true ||
                                    current.originalName?.toLowerCase().endsWith('.jpg') == true ||
                                    current.originalName?.toLowerCase().endsWith('.jpeg') == true;

                    if (!isImage) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.preview_outlined, size: 64, color: AppColors.outlineVariant),
                          const SizedBox(height: AppSpacing.md),
                          Text('Preview unavailable for this file type', style: AppTypography.bodyMd.copyWith(color: AppColors.outline)),
                          const SizedBox(height: AppSpacing.sm),
                          Text('${current.originalName ?? "drawing"} • ${current.size} bytes', style: AppTypography.labelMono.copyWith(color: AppColors.outlineVariant)),
                        ],
                      );
                    }

                    final baseUrl = ref.read(apiClientProvider).baseUrl;
                    final url = '$baseUrl/api/files/${current.fileId}/download';

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: Image.network(
                        url,
                        headers: headers,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image_outlined, size: 64, color: AppColors.outlineVariant),
                            const SizedBox(height: AppSpacing.md),
                            Text('Failed to load image', style: AppTypography.bodyMd.copyWith(color: AppColors.outline)),
                          ],
                        ),
                      ),
                    );
                  }
                ),
              ),

              if (versions.length > 1) ...[
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                Text('Previous Versions', style: AppTypography.labelMono.copyWith(color: AppColors.outline)),
                const SizedBox(height: AppSpacing.sm),
                ...versions.skip(1).map((v) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history, color: AppColors.outline),
                  title: Text('Version ${v.versionNumber}', style: AppTypography.bodyMd),
                  subtitle: Text(v.originalName ?? 'Unknown file'),
                  trailing: IconButton(icon: const Icon(Icons.download), onPressed: () {}),
                )),
              ]
            ],
          )
        );
      }
    );
  }

  Widget _buildSideArea(BuildContext context, WidgetRef ref, Project project) {
    return Column(
      children: [
        // Metadata Card
        Container(
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
              Text('Details', style: AppTypography.headlineLgMobile.copyWith(color: AppColors.primary, fontSize: 20)),
              const SizedBox(height: AppSpacing.lg),
              _buildMetaField('PROJECT NAME', project.projectName),
              const Divider(height: 24),
              _buildMetaField('ADDRESS', project.projectAddress),
              const Divider(height: 24),
              _buildMetaField('DRAWING TYPE', project.drawingTypeEnum?.displayName ?? project.drawingType),
              const Divider(height: 24),
              _buildMetaField('AREA', project.projectArea != null ? '${project.projectArea} sq ft' : 'Not specified'),
              const Divider(height: 24),
              _buildMetaField('BUDGET', project.estimatedAmount != null ? '${project.estimatedAmount}' : 'Not specified'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.gridGutter),

        // Workflow Timeline
        ref.watch(projectActivityLogsProvider(project.projectId)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AppErrorWidget(
            message: 'Failed to load timeline.',
            onRetry: () => ref.invalidate(projectActivityLogsProvider(project.projectId)),
          ),
          data: (activities) {
            return WorkflowTimelineWidget(project: project, activities: activities);
          }
        ),
      ],
    );
  }

  Widget _buildMetaField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMono.copyWith(color: AppColors.outline)),
        const SizedBox(height: 4),
        Text(value.isEmpty ? '—' : value, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface)),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
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
          Text(title, style: AppTypography.headlineLgMobile.copyWith(color: AppColors.primary, fontSize: 20)),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _BlueprintGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += AppSpacing.blueprintUnit) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += AppSpacing.blueprintUnit) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

