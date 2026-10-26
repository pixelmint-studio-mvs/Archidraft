import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:archi_draft/src/core/theme/app_colors.dart';
import 'package:archi_draft/src/core/theme/app_spacing.dart';
import 'package:archi_draft/src/core/theme/app_typography.dart';
import 'package:archi_draft/src/shared/widgets/app_state_widgets.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/domain/project_status.dart';
import 'package:archi_draft/src/features/profile/domain/user_role.dart';
import 'package:archi_draft/src/features/auth/providers/auth_providers.dart';
import 'package:archi_draft/src/features/projects/domain/drawing_version.dart';
import 'package:archi_draft/src/features/projects/data/file_repository.dart';
import 'package:archi_draft/src/features/projects/providers/project_form_controller.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/projects/providers/file_providers.dart';
import 'package:archi_draft/src/features/projects/presentation/widgets/cad_drawing_viewer.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:archi_draft/src/features/projects/domain/correction.dart';
import 'package:archi_draft/src/features/projects/presentation/widgets/file_attachment_card.dart';
import 'package:archi_draft/src/features/projects/presentation/widgets/file_upload_button.dart';
import 'package:archi_draft/src/features/projects/presentation/widgets/correction_dialog.dart';
import 'package:archi_draft/src/features/projects/presentation/widgets/workflow_timeline_widget.dart';

/// Detail screen for viewing a project.
///
/// Implements the Stitch 12-column Bento Grid layout for the Engineer.
class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  int? _selectedVersionNumber;

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectProvider(widget.projectId));
    final profile = ref.watch(userProfileProvider).value;
    final userRole = UserRole.fromString(profile?.role) ?? UserRole.engineer;

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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else if (userRole == UserRole.student) {
              context.go('/student/projects');
            } else {
              context.go('/engineer/projects');
            }
          },
        ),
        actions: [
          if (userRole == UserRole.student)
            TextButton.icon(
              icon: const Icon(Icons.draw_outlined, size: 18),
              label: const Text('Workspace'),
              onPressed: () => context.push('/student/workspace/${widget.projectId}'),
            )
          else
            IconButton(
              icon: const Icon(Icons.forum_outlined),
              tooltip: 'Collaboration Hub',
              onPressed: () => context.push('/engineer/projects/${widget.projectId}/collaboration-hub'),
            ),
        ],
      ),
      body: projectAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Loading project...'),
        error: (error, _) => AppErrorWidget(
          message: 'Failed to load project.',
          onRetry: () => ref.invalidate(projectProvider(widget.projectId)),
        ),
        data: (project) {
          if (project == null) {
            return const AppErrorWidget(message: 'Project not found.');
          }
          return _buildProjectDetail(context, project);
        },
      ),
    );
  }

  Widget _buildProjectDetail(BuildContext context, Project project) {
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
                  _buildHeader(context, project),
                  const SizedBox(height: AppSpacing.xxl),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 1024) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 8, child: _buildMainArea(context, project)),
                            const SizedBox(width: AppSpacing.gridGutter),
                            Expanded(flex: 4, child: _buildSideArea(context, project)),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildMainArea(context, project),
                            const SizedBox(height: AppSpacing.gridGutter),
                            _buildSideArea(context, project),
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

  Widget _buildHeader(BuildContext context, Project project) {
    final status = project.projectStatus ?? ProjectStatus.draft;
    
    // Status color mapping for the badge
    Color badgeColor = AppColors.surfaceContainerHigh;
    Color badgeTextColor = AppColors.onSurfaceVariant;
    if (status == ProjectStatus.underEngineerReview) {
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
                    project.projectId.length >= 8 ? project.projectId.substring(0, 8).toUpperCase() : project.projectId.toUpperCase(),
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

        final actions = _buildHeaderActions(context, project, status);

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

  Widget? _buildHeaderActions(BuildContext context, Project project, ProjectStatus status) {
    final profile = ref.watch(userProfileProvider).value;
    final userRole = UserRole.fromString(profile?.role) ?? UserRole.engineer;
    final isStudentTraining = project.isTrainingProject == 1 && userRole == UserRole.student;

    if (isStudentTraining && (status == ProjectStatus.inProgress || status == ProjectStatus.waitingAcceptance)) {
      return FilledButton.icon(
        onPressed: () => context.push('/student/workspace/${project.projectId}'),
        icon: const Icon(Icons.edit_document, size: 18),
        label: const Text('Open Workspace'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        ),
      );
    }

    if (status == ProjectStatus.draft && !isStudentTraining) {
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
    } else if (status == ProjectStatus.underEngineerReview && userRole != UserRole.student) {
      return Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        alignment: WrapAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              final versionsAsync = ref.read(projectDrawingVersionsProvider(project.projectId));
              final latestVersionId = versionsAsync.value?.isNotEmpty == true
                  ? versionsAsync.value!.first.id
                  : 'latest';
              showDialog(
                context: context,
                builder: (context) => CorrectionDialog(
                  projectId: project.projectId,
                  targetVersionId: latestVersionId,
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
          OutlinedButton.icon(
            onPressed: () => context.push('/engineer/projects/${project.projectId}/collaboration-hub'),
            icon: const Icon(Icons.forum_outlined, size: 18),
            label: const Text('Collaboration Hub'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
            ),
          ),
        ],
      );
    } else if (status != ProjectStatus.draft) {
      return OutlinedButton.icon(
        onPressed: () => context.push('/engineer/projects/${project.projectId}/collaboration-hub'),
        icon: const Icon(Icons.forum_outlined, size: 18),
        label: const Text('Collaboration Hub'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        ),
      );
    }
    return null;
  }

  Widget _buildMainArea(BuildContext context, Project project) {
    return Column(
      children: [
        // Drawing Versions section with embedded CAD viewer
        _buildDrawingVersionsSection(context, project),
          
        const SizedBox(height: AppSpacing.gridGutter),
        
        // Collaboration Hub Section
        _buildSectionCard(
          title: 'Collaboration Hub',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Communicate directly with the assigned draughtsman, discuss drawing revisions, and review project queries.',
                style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => context.push('/engineer/projects/${project.projectId}/collaboration-hub'),
                icon: const Icon(Icons.forum_outlined, size: 18),
                label: const Text('Open Collaboration Hub'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                ),
              ),
            ],
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
              final clientFiles = files.where((f) => (f.category == 'client_upload' || f.category == 'client_reference') && f.status != 'FAILED').toList();
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

  Widget _buildDrawingVersionsSection(BuildContext context, Project project) {
    return ref.watch(projectDrawingVersionsProvider(project.projectId)).when(
      loading: () => _buildSectionCard(
        title: 'Drawing Versions',
        child: const SizedBox(
          height: 240,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => _buildSectionCard(
        title: 'Drawing Versions',
        child: AppErrorWidget(
          message: 'Failed to load drawings.',
          onRetry: () => ref.invalidate(projectDrawingVersionsProvider(project.projectId)),
        ),
      ),
      data: (versions) {
        if (versions.isEmpty) {
          return _buildSectionCard(
            title: 'Drawing Versions',
            child: Container(
              height: 300,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.layers_outlined, size: 48, color: AppColors.outline),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Drawings will appear here once submitted by the draughtsman.',
                    style: AppTypography.bodyMd.copyWith(color: AppColors.outlineVariant),
                  ),
                ],
              ),
            ),
          );
        }

        final sortedVersions = List<DrawingVersion>.from(versions)
          ..sort((a, b) => b.versionNumber.compareTo(a.versionNumber));
        final latestVersion = sortedVersions.first;
        final current = sortedVersions.firstWhere(
          (v) => v.versionNumber == _selectedVersionNumber,
          orElse: () => latestVersion,
        );

        final correctionsAsync = ref.watch(projectCorrectionsProvider(project.projectId));
        final corrections = correctionsAsync.value ?? [];
        Correction? currentCorrection;
        for (final c in corrections) {
          if (c.targetVersionId == current.id) {
            currentCorrection = c;
            break;
          }
        }

        final ext = (current.originalName ?? '').split('.').last.toUpperCase();
        final formatLabel = ext.isEmpty ? 'CAD' : ext;
        final dateStr = current.createdAt != null
            ? DateFormat.yMMMd().add_jm().format(current.createdAt!)
            : 'Date unavailable';
        final draughtsmanLabel = current.uploaderName ??
            (project.assignedDraughtsmanId != null ? 'Assigned Draughtsman' : 'Draughtsman');

        final String statusLabel;
        if (current.versionNumber == latestVersion.versionNumber) {
          if (project.projectStatus == ProjectStatus.underEngineerReview) {
            statusLabel = 'Under Engineer Review';
          } else if (project.projectStatus == ProjectStatus.inProgress) {
            statusLabel = 'In Revision';
          } else if (project.projectStatus == ProjectStatus.completed) {
            statusLabel = 'Approved';
          } else {
            statusLabel = project.projectStatus?.displayName ?? project.status;
          }
        } else {
          statusLabel = 'Previous Version';
        }

        return _buildSectionCard(
          title: 'Drawing Versions',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Viewer Toolbar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (sortedVersions.length > 1)
                    PopupMenuButton<int>(
                      tooltip: 'Select Drawing Version',
                      initialValue: current.versionNumber,
                      onSelected: (ver) {
                        setState(() {
                          _selectedVersionNumber = ver;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Version ${current.versionNumber}${current.versionNumber == latestVersion.versionNumber ? ' (Latest)' : ''}',
                              style: AppTypography.labelMono.copyWith(color: Colors.white),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => sortedVersions
                          .map((v) => PopupMenuItem<int>(
                                value: v.versionNumber,
                                child: Text(
                                  'Version ${v.versionNumber}${v.versionNumber == latestVersion.versionNumber ? ' (Latest)' : ''}',
                                  style: AppTypography.labelMono,
                                ),
                              ))
                          .toList(),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Version ${current.versionNumber} (Latest)',
                        style: AppTypography.labelMono.copyWith(color: Colors.white),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(fileRepositoryProvider).downloadFile(
                            current.fileId,
                            current.originalName ?? 'drawing.$ext',
                            openInBrowser: false,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Downloading ${current.originalName ?? "drawing"}...')),
                      );
                    },
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download Original'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Version Metadata Strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: AppColors.outline),
                        const SizedBox(width: 4),
                        Text(
                          draughtsmanLabel,
                          style: AppTypography.labelMono.copyWith(fontSize: 11, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.outline),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: AppTypography.labelMono.copyWith(fontSize: 11, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.badge_outlined, size: 14, color: AppColors.outline),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: AppTypography.labelMono.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: current.versionNumber == latestVersion.versionNumber ? AppColors.primary : AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.insert_drive_file_outlined, size: 14, color: AppColors.outline),
                        const SizedBox(width: 4),
                        Text(
                          '$formatLabel • ${(current.size != null ? (current.size! / 1024).toStringAsFixed(1) : '0')} KB',
                          style: AppTypography.labelMono.copyWith(fontSize: 11, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (currentCorrection != null && currentCorrection.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.rate_review_outlined, size: 15, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Round ${currentCorrection.roundNumber} Revision Notes: ${currentCorrection.description}',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              // Interactive CAD Drawing Viewer
              CadDrawingViewer(
                fileId: current.fileId,
                fileName: current.originalName ?? 'drawing.$ext',
                fileSize: current.size,
                versionNumber: current.versionNumber,
                onDownload: () {
                  ref.read(fileRepositoryProvider).downloadFile(
                        current.fileId,
                        current.originalName ?? 'drawing.$ext',
                        openInBrowser: false,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Downloading ${current.originalName ?? "drawing"}...')),
                  );
                },
              ),

              if (sortedVersions.length > 1) ...[
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                Text('All Revisions', style: AppTypography.labelMono.copyWith(color: AppColors.outline)),
                const SizedBox(height: AppSpacing.sm),
                ...sortedVersions.map((v) {
                  final isCurrent = v.versionNumber == current.versionNumber;
                  final vExt = (v.originalName ?? '').split('.').last.toUpperCase();
                  final vDraughtsman = v.uploaderName ?? (project.assignedDraughtsmanId != null ? 'Assigned Draughtsman' : 'Draughtsman');
                  final vDate = v.createdAt != null ? DateFormat.yMMMd().format(v.createdAt!) : '';

                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isCurrent ? Icons.check_circle_rounded : Icons.history_rounded,
                        color: isCurrent ? AppColors.primary : AppColors.outline,
                      ),
                      title: Text(
                        'Version ${v.versionNumber}${v.versionNumber == latestVersion.versionNumber ? ' (Latest)' : ''}',
                        style: AppTypography.bodyMd.copyWith(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '${v.originalName ?? "drawing"} • $vExt • ${(v.size != null ? (v.size! / 1024).toStringAsFixed(1) : 0)} KB • $vDraughtsman • $vDate',
                        style: AppTypography.bodySm.copyWith(color: AppColors.outline),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isCurrent)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedVersionNumber = v.versionNumber;
                                });
                              },
                              child: const Text('View'),
                            ),
                          IconButton(
                            icon: const Icon(Icons.download, size: 18),
                            tooltip: 'Download file',
                            onPressed: () {
                              ref.read(fileRepositoryProvider).downloadFile(
                                    v.fileId,
                                    v.originalName ?? 'drawing.$vExt',
                                    openInBrowser: false,
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Downloading ${v.originalName ?? "drawing"}...')),
                              );
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _selectedVersionNumber = v.versionNumber;
                        });
                      },
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSideArea(BuildContext context, Project project) {
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