import 'package:archi_draft/src/features/notifications/providers/notification_providers.dart';
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
  bool _isRefreshing = false;
  bool _isApprovingFinal = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      ref.invalidate(projectProvider(widget.projectId));
      ref.invalidate(projectDrawingVersionsProvider(widget.projectId));
      ref.invalidate(projectCorrectionsProvider(widget.projectId));
      ref.invalidate(projectFilesProvider(widget.projectId));
      await ref.read(projectProvider(widget.projectId).future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project details and drawings refreshed'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refresh failed: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Widget _buildDrawingsRefreshButton() {
    return TextButton.icon(
      onPressed: _isRefreshing ? null : _handleRefresh,
      icon: _isRefreshing
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
            )
          : const Icon(Icons.refresh_rounded, size: 14),
      label: Text(
        _isRefreshing ? 'Refreshing...' : 'Refresh Drawings',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }

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
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh project & drawings',
            onPressed: _isRefreshing ? null : _handleRefresh,
          ),
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
                    project.correctionRound > 0 && status == ProjectStatus.inProgress
                        ? 'STATUS: CORRECTION ROUND ${project.correctionRound}'
                        : (status == ProjectStatus.underEngineerReview
                            ? 'STATUS: WAITING FOR YOUR REVIEW'
                            : (status == ProjectStatus.underAdminReview
                                ? 'STATUS: WAITING FOR STUDIO REVIEW'
                                : (status == ProjectStatus.completed
                                    ? 'STATUS: COMPLETED'
                                    : 'STATUS: ${status.toFirestoreString()}'))),
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
              final approvedList = versionsAsync.value?.where((v) => v.isApproved).toList() ?? [];
              final latestVersionId = approvedList.isNotEmpty
                  ? approvedList.first.id
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
            label: Text(project.correctionRound > 0
                ? 'Request Correction (Round ${project.correctionRound + 1})'
                : 'Request Revision (Round 1)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
            ),
          ),
          FilledButton.icon(
            onPressed: _isApprovingFinal
                ? null
                : () async {
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
                      if (_isApprovingFinal) return;
                      setState(() => _isApprovingFinal = true);
                      try {
                        await ref.read(projectRepositoryProvider).approveFinal(
                          projectId: project.projectId,
                          actionId: const Uuid().v4(),
                        );
                        ref.invalidate(projectProvider(project.projectId));
                        ref.invalidate(projectCorrectionsProvider(project.projectId));
                        ref.invalidate(projectDrawingVersionsProvider(project.projectId));
                        ref.invalidate(engineerProjectsProvider);
                        ref.invalidate(notificationsProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Project final drawing approved successfully! Status: COMPLETED'),
                              backgroundColor: Color(0xFF059669),
                              duration: Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isApprovingFinal = false);
                        }
                      }
                    }
                  },
            icon: _isApprovingFinal
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check),
            label: Text(_isApprovingFinal ? 'Approving Final...' : 'Approve Final'),
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

  Widget _buildCorrectionStageCard(BuildContext context, Project project) {
    if (project.projectStatus == ProjectStatus.completed || project.projectStatus == ProjectStatus.cancelled) {
      return const SizedBox.shrink();
    }
    if (project.correctionRound <= 0 && project.projectStatus != ProjectStatus.inProgress) {
      return const SizedBox.shrink();
    }

    final correctionsAsync = ref.watch(projectCorrectionsProvider(project.projectId));
    final openCorrection = correctionsAsync.value?.where((c) => c.status != CorrectionStatus.resolved).firstOrNull;

    if (openCorrection == null) {
      return const SizedBox.shrink();
    }

    final roundNum = openCorrection.roundNumber;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.gridGutter),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
            ),
            child: const Icon(Icons.rate_review_outlined, color: Color(0xFFB45309), size: 24),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CORRECTION ROUND $roundNum REQUESTED',
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB45309),
                        letterSpacing: 0.8,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ROUND $roundNum IN PROGRESS',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  project.projectStatus == ProjectStatus.underAdminReview
                      ? 'Draughtsman has submitted the corrected drawing. Studio Admin is verifying quality before releasing to you.'
                      : (openCorrection.description.isNotEmpty
                          ? 'Feedback provided: "${openCorrection.description}"'
                          : 'Draughtsman is actively preparing revised technical deliverables for your review.'),
                  style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildCompletionSummaryCard(BuildContext context, Project project) {
    final versionsAsync = ref.watch(projectDrawingVersionsProvider(project.projectId));
    final approvedVersions = versionsAsync.value?.where((v) => v.isApproved).toList() ?? [];
    final latestApproved = approvedVersions.isNotEmpty ? approvedVersions.first : null;
    final dateStr = project.completedAt != null
        ? DateFormat.yMMMd().add_jm().format(project.completedAt!)
        : (latestApproved?.createdAt != null
            ? DateFormat.yMMMd().add_jm().format(latestApproved!.createdAt!)
            : 'Completed');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.gridGutter),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF047857), size: 28),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'PROJECT DELIVERED & COMPLETED',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF065F46),
                            letterSpacing: 0.8,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                          ),
                          child: const Text(
                            'COMPLETED',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'All technical drawings for "${project.projectName.isNotEmpty ? project.projectName : 'Project'}" have passed Studio Quality Control and received your final acceptance.',
                      style: AppTypography.bodyMd.copyWith(color: const Color(0xFF064E3B)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.lg,
                      runSpacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.layers_rounded, size: 16, color: Color(0xFF047857)),
                            const SizedBox(width: 6),
                            Text(
                              latestApproved != null
                                  ? 'Final Deliverable: v${latestApproved.versionNumber} (${latestApproved.originalName ?? 'CAD Package'})'
                                  : 'Final Deliverable: Approved',
                              style: AppTypography.labelMono.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF065F46),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF047857)),
                            const SizedBox(width: 6),
                            Text(
                              'Approved: $dateStr',
                              style: AppTypography.labelMono.copyWith(
                                fontSize: 12,
                                color: const Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (latestApproved != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      OutlinedButton.icon(
                        onPressed: () {
                          ref.read(fileRepositoryProvider).downloadFile(
                                latestApproved.fileId,
                                latestApproved.originalName ?? 'final_drawing.dwg',
                                openInBrowser: false,
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Downloading ${latestApproved.originalName ?? "final drawing"}...')),
                          );
                        },
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Download Final Approved Package'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF065F46),
                          side: const BorderSide(color: Color(0xFF10B981)),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainArea(BuildContext context, Project project) {
    return Column(
      children: [
        if (project.projectStatus == ProjectStatus.completed)
          _buildCompletionSummaryCard(context, project),

        // Correction Stage Visibility Card
        _buildCorrectionStageCard(context, project),

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
        // Phase 4 containment: Engineers only see approved drawing versions (or legacy versions without approval status)
        final approvedVersions = versions
            .where((v) => v.isApproved)
            .toList();

        if (approvedVersions.isEmpty) {
          return _buildSectionCard(
            title: 'Drawing Versions',
            trailing: _buildDrawingsRefreshButton(),
            child: Container(
              height: 300,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.layers_outlined, size: 48, color: AppColors.outline),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    project.projectStatus == ProjectStatus.underAdminReview
                        ? 'Draughtsman deliverable is undergoing Studio QC review. Approved drawings will appear here.'
                        : 'Drawings will appear here once submitted by the draughtsman.',
                    style: AppTypography.bodyMd.copyWith(color: AppColors.outlineVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final sortedVersions = List<DrawingVersion>.from(approvedVersions)
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
            statusLabel = 'Waiting for Your Review';
          } else if (project.projectStatus == ProjectStatus.underAdminReview) {
            statusLabel = 'Waiting for Studio Review';
          } else if (project.projectStatus == ProjectStatus.inProgress) {
            statusLabel = project.correctionRound > 0 ? 'Correction Round ${project.correctionRound}' : 'In Drafting';
          } else if (project.projectStatus == ProjectStatus.completed) {
            statusLabel = 'Completed';
          } else {
            statusLabel = project.projectStatus?.displayName ?? project.status;
          }
        } else {
          statusLabel = 'Previous Version';
        }

        return _buildSectionCard(
          title: 'Drawing Versions',
          trailing: _buildDrawingsRefreshButton(),
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

  Widget _buildSectionCard({required String title, required Widget child, Widget? trailing}) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.headlineLgMobile.copyWith(color: AppColors.primary, fontSize: 20)),
              ?trailing,
            ],
          ),
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