import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:archi_draft/src/core/theme/app_colors.dart';
import 'package:archi_draft/src/core/theme/app_spacing.dart';
import 'package:archi_draft/src/core/theme/app_typography.dart';
import 'package:archi_draft/src/shared/widgets/app_state_widgets.dart';

import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/domain/project_status.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'widgets/project_card.dart';

/// Filter categories for the client project list.
///
/// Each filter maps to a subset of [ProjectStatus] values.
enum _ProjectFilter {
  all,
  active,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case _ProjectFilter.all:
        return 'All';
      case _ProjectFilter.active:
        return 'Active';
      case _ProjectFilter.completed:
        return 'Completed';
      case _ProjectFilter.cancelled:
        return 'Cancelled';
    }
  }

  /// Returns true if a project matches this filter.
  bool matches(ProjectStatus? status) {
    if (status == null) return this == _ProjectFilter.all;
    switch (this) {
      case _ProjectFilter.all:
        return true;
      case _ProjectFilter.active:
        return status != ProjectStatus.completed &&
            status != ProjectStatus.cancelled;
      case _ProjectFilter.completed:
        return status == ProjectStatus.completed;
      case _ProjectFilter.cancelled:
        return status == ProjectStatus.cancelled;
    }
  }
}

/// The client's main project list screen.
///
/// Displays all projects owned by the authenticated client.
/// Uses a real-time Firestore stream for live updates.
/// Phase 7: Added local status filter tabs.
///
/// Stitch design reference: executive_dashboard — card grid layout.
class ClientProjectsScreen extends ConsumerStatefulWidget {
  const ClientProjectsScreen({super.key});

  @override
  ConsumerState<ClientProjectsScreen> createState() =>
      _ClientProjectsScreenState();
}

class _ClientProjectsScreenState extends ConsumerState<ClientProjectsScreen> {
  _ProjectFilter _selectedFilter = _ProjectFilter.all;

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(clientProjectsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // Filter tabs
          _buildFilterBar(),
          // Project list
          Expanded(
            child: projectsAsync.when(
              loading: () => const AppLoadingIndicator(
                message: 'Loading projects...',
              ),
              error: (error, _) => AppErrorWidget(
                message: 'Failed to load projects. Please try again.',
                onRetry: () => ref.invalidate(clientProjectsProvider),
              ),
              data: (projects) {
                final filtered = projects
                    .where((p) => _selectedFilter.matches(p.projectStatus))
                    .toList();
                if (filtered.isEmpty) {
                  return _buildEmptyState(context);
                }
                return _buildProjectList(context, filtered);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/client/projects/new'),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.onSecondary,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          'New Project',
          style: AppTypography.buttonText.copyWith(
            color: AppColors.onSecondary,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        AppSpacing.md,
        AppSpacing.marginMobile,
        AppSpacing.md,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _ProjectFilter.values.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.secondary
                        : AppColors.surfaceContainerLow,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.secondary
                          : AppColors.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    filter.label,
                    style: AppTypography.buttonText.copyWith(
                      color: isSelected
                          ? AppColors.onSecondary
                          : AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isFiltered = _selectedFilter != _ProjectFilter.all;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFiltered ? Icons.filter_list_off_rounded : Icons.layers_outlined,
              size: 64,
              color: AppColors.outlineVariant,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              isFiltered
                  ? 'No ${_selectedFilter.label.toLowerCase()} projects'
                  : 'No Projects Yet',
              style: AppTypography.headlineLgMobile.copyWith(
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isFiltered
                  ? 'Try a different filter or create a new project.'
                  : 'Start by creating your first project brief.\nTap the button below to get started.',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.outline,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isFiltered) ...[
              const SizedBox(height: AppSpacing.xxl),
              FilledButton.icon(
                onPressed: () => context.go('/client/projects/new'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create Project'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.onSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProjectList(BuildContext context, List<Project> projects) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1024
            ? 3
            : constraints.maxWidth >= 600
                ? 2
                : 1;

        if (crossAxisCount == 1) {
          // Mobile: simple list
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.marginMobile,
              AppSpacing.lg,
              AppSpacing.marginMobile,
              100, // Space for FAB
            ),
            itemCount: projects.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final project = projects[index];
              return ProjectCard(
                project: project,
                onTap: () =>
                    context.go('/client/projects/${project.projectId}'),
              );
            },
          );
        }

        // Tablet/Desktop: grid
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            constraints.maxWidth >= 1024
                ? AppSpacing.marginDesktop
                : AppSpacing.marginTablet,
            AppSpacing.lg,
            constraints.maxWidth >= 1024
                ? AppSpacing.marginDesktop
                : AppSpacing.marginTablet,
            100,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.gridGutter,
            mainAxisSpacing: AppSpacing.gridGutter,
            childAspectRatio: 1.6,
          ),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return ProjectCard(
              project: project,
              onTap: () =>
                  context.go('/client/projects/${project.projectId}'),
            );
          },
        );
      },
    );
  }
}
