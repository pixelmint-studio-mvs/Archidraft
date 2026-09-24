import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../training/providers/training_providers.dart';
import '../../domain/project.dart';
import '../../domain/project_status.dart';

class StudentProjectsScreen extends ConsumerWidget {
  const StudentProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(studentAssignmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Projects',
          style: AppTypography.headlineSmMobile.copyWith(color: AppColors.onBackground),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
      ),
      body: assignmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.secondary)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: AppSpacing.md),
              Text('Could not load projects.', style: AppTypography.bodyMd),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton(
                onPressed: () => ref.refresh(studentAssignmentsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open_outlined, size: 64, color: AppColors.onSurfaceVariant.withOpacity(0.5)),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No projects yet',
                    style: AppTypography.headlineSmMobile.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Your training projects will appear here.',
                    style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.secondary,
            onRefresh: () async {
              ref.invalidate(studentAssignmentsProvider);
              try {
                await ref.read(studentAssignmentsProvider.future);
              } catch (_) {}
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: projects.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final project = projects[index];
                return _ProjectListItem(project: project);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ProjectListItem extends StatelessWidget {
  final Project project;

  const _ProjectListItem({required this.project});

  @override
  Widget build(BuildContext context) {
    final status = project.projectStatus ?? ProjectStatus.draft;
    final statusColor = _getStatusColor(status);

    return InkWell(
      onTap: () {
        context.push('/student/projects/${project.projectId}');
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.surfaceVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    project.projectName,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs / 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                  ),
                  child: Text(
                    _getStatusDisplay(status),
                    style: AppTypography.labelMono.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (project.projectAddress.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      project.projectAddress,
                      style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: AppColors.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  project.createdAt != null 
                    ? 'Started ${project.createdAt!.toLocal().toString().substring(0, 10)}'
                    : 'Started recently',
                  style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const Spacer(),
                if (project.correctionRound > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 12, color: AppColors.error),
                        const SizedBox(width: 4),
                        Text(
                          'Rev ${project.correctionRound}',
                          style: AppTypography.labelMono.copyWith(
                            color: AppColors.error,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.completed:
        return AppColors.success;
      case ProjectStatus.inProgress:
        return AppColors.secondary;
      case ProjectStatus.submitted:
      case ProjectStatus.underClientReview:
        return AppColors.warning;
      case ProjectStatus.draft:
      case ProjectStatus.waitingAssignment:
      case ProjectStatus.waitingAcceptance:
      case ProjectStatus.cancelled:
        return AppColors.onSurfaceVariant;
    }
  }

  String _getStatusDisplay(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.waitingAssignment: return 'PENDING ASSIGN';
      case ProjectStatus.waitingAcceptance: return 'PENDING ACCEPT';
      case ProjectStatus.inProgress: return 'IN PROGRESS';
      case ProjectStatus.submitted: return 'SUBMITTED';
      case ProjectStatus.underClientReview: return 'IN REVIEW';
      case ProjectStatus.completed: return 'COMPLETED';
      case ProjectStatus.draft: return 'DRAFT';
      case ProjectStatus.cancelled: return 'CANCELLED';
    }
  }
}
