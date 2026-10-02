import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../training/providers/training_providers.dart';
import '../../domain/project.dart';
import '../../domain/project_status.dart';

enum ProjectFilter { all, active, corrections, review, completed }

class StudentProjectsScreen extends ConsumerStatefulWidget {
  const StudentProjectsScreen({super.key});

  @override
  ConsumerState<StudentProjectsScreen> createState() => _StudentProjectsScreenState();
}

class _StudentProjectsScreenState extends ConsumerState<StudentProjectsScreen> {
  ProjectFilter _selectedFilter = ProjectFilter.all;

  @override
  Widget build(BuildContext context) {
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
        error: (err, stack) => _buildErrorState(context),
        data: (projects) => _buildBody(context, projects),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
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
    );
  }

  Widget _buildBody(BuildContext context, List<Project> projects) {
    if (projects.isEmpty) {
      return RefreshIndicator(
        color: AppColors.secondary,
        onRefresh: () async => ref.refresh(studentAssignmentsProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            alignment: Alignment.center,
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
                  'Your assigned projects will appear here.',
                  style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activeProjects = projects.where((p) => p.projectStatus == ProjectStatus.inProgress || p.projectStatus == ProjectStatus.waitingAcceptance).toList();
    final correctionProjects = projects.where((p) => p.correctionRound > 0 && p.projectStatus != ProjectStatus.completed).toList();
    final reviewProjects = projects.where((p) => p.projectStatus == ProjectStatus.underClientReview || p.projectStatus == ProjectStatus.submitted).toList();
    final completedProjects = projects.where((p) => p.projectStatus == ProjectStatus.completed).toList();

    List<Project> filteredProjects;
    switch (_selectedFilter) {
      case ProjectFilter.all:
        filteredProjects = projects;
        break;
      case ProjectFilter.active:
        filteredProjects = activeProjects;
        break;
      case ProjectFilter.corrections:
        filteredProjects = correctionProjects;
        break;
      case ProjectFilter.review:
        filteredProjects = reviewProjects;
        break;
      case ProjectFilter.completed:
        filteredProjects = completedProjects;
        break;
    }

    // Determine priority project for the "Featured" section
    Project? priorityProject;
    if (_selectedFilter == ProjectFilter.all) {
      if (correctionProjects.isNotEmpty) {
        priorityProject = correctionProjects.first;
      } else if (activeProjects.isNotEmpty) {
        priorityProject = activeProjects.first;
      }
    }

    return RefreshIndicator(
      color: AppColors.secondary,
      onRefresh: () async => ref.refresh(studentAssignmentsProvider.future),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildSummaryCards(
              activeCount: activeProjects.length,
              correctionsCount: correctionProjects.length,
              reviewCount: reviewProjects.length,
              completedCount: completedProjects.length,
            ),
          ),
          SliverToBoxAdapter(
            child: _buildFilterChips(),
          ),
          if (priorityProject != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Needs Attention',
                      style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _FeaturedProjectCard(project: priorityProject),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'All Projects',
                      style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
          if (filteredProjects.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No projects found for this filter.',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md).copyWith(top: priorityProject != null ? 0 : AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final project = filteredProjects[index];
                    if (priorityProject != null && project.projectId == priorityProject.projectId) {
                      return const SizedBox.shrink(); // Don't show priority project twice
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ProjectListItem(project: project),
                    );
                  },
                  childCount: filteredProjects.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards({
    required int activeCount,
    required int correctionsCount,
    required int reviewCount,
    required int completedCount,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          _SummaryCard(title: 'Active', count: activeCount, color: AppColors.secondary, icon: Icons.bolt),
          const SizedBox(width: AppSpacing.sm),
          _SummaryCard(title: 'Corrections', count: correctionsCount, color: AppColors.error, icon: Icons.error_outline),
          const SizedBox(width: AppSpacing.sm),
          _SummaryCard(title: 'Under Review', count: reviewCount, color: AppColors.warning, icon: Icons.rate_review_outlined),
          const SizedBox(width: AppSpacing.sm),
          _SummaryCard(title: 'Completed', count: completedCount, color: AppColors.success, icon: Icons.check_circle_outline),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: ProjectFilter.values.map((filter) {
          final isSelected = _selectedFilter == filter;
          String label;
          switch (filter) {
            case ProjectFilter.all: label = 'All'; break;
            case ProjectFilter.active: label = 'Active'; break;
            case ProjectFilter.corrections: label = 'Corrections'; break;
            case ProjectFilter.review: label = 'Under Review'; break;
            case ProjectFilter.completed: label = 'Completed'; break;
          }

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                }
              },
              backgroundColor: AppColors.surfaceContainerLowest,
              selectedColor: AppColors.secondaryContainer,
              labelStyle: AppTypography.labelMono.copyWith(
                color: isSelected ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : AppColors.surfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            count.toString(),
            style: AppTypography.headlineLgMobile.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _FeaturedProjectCard extends StatelessWidget {
  final Project project;

  const _FeaturedProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final status = project.projectStatus ?? ProjectStatus.draft;
    final statusColor = _getStatusColor(status);

    return InkWell(
      onTap: () {
        if (project.projectStatus == ProjectStatus.inProgress) {
          context.push('/student/workspace/${project.projectId}');
        } else {
          context.push('/student/projects/${project.projectId}');
        }
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: project.correctionRound > 0 ? AppColors.error : AppColors.secondary.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
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
                if (project.correctionRound > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error, size: 14, color: AppColors.error),
                        const SizedBox(width: 4),
                        Text(
                          'Correction Rev ${project.correctionRound}',
                          style: AppTypography.labelMono.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              project.projectName,
              style: AppTypography.headlineSmMobile.copyWith(color: AppColors.onSurface),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.architecture, size: 16, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  project.drawingTypeEnum?.displayName ?? project.drawingType,
                  style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
            if (project.projectAddress.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 6),
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
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () {
                context.push('/student/projects/${project.projectId}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.onSecondary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: const Text('Open Workspace'),
            ),
          ],
        ),
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
        if (project.projectStatus == ProjectStatus.inProgress) {
          context.push('/student/workspace/${project.projectId}');
        } else {
          context.push('/student/projects/${project.projectId}');
        }
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
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
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.architecture, size: 14, color: AppColors.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  project.drawingTypeEnum?.displayName ?? project.drawingType,
                  style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
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
                if (project.correctionRound > 0 && status != ProjectStatus.completed) ...[
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
