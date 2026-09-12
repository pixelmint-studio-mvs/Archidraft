import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:archi_draft/src/core/theme/app_colors.dart';
import 'package:archi_draft/src/core/theme/app_spacing.dart';
import 'package:archi_draft/src/core/theme/app_typography.dart';
import 'package:archi_draft/src/shared/widgets/app_state_widgets.dart';

import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'widgets/project_card.dart';

/// The client's main project list screen.
///
/// Displays all projects owned by the authenticated client.
/// Uses a real-time Firestore stream for live updates.
///
/// Stitch design reference: executive_dashboard — card grid layout.
class ClientProjectsScreen extends ConsumerWidget {
  const ClientProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(clientProjectsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: projectsAsync.when(
        loading: () => const AppLoadingIndicator(
          message: 'Loading projects...',
        ),
        error: (error, _) => AppErrorWidget(
          message: 'Failed to load projects. Please try again.',
          onRetry: () => ref.invalidate(clientProjectsProvider),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildProjectList(context, projects);
        },
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.layers_outlined,
              size: 64,
              color: AppColors.outlineVariant,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No Projects Yet',
              style: AppTypography.headlineLgMobile.copyWith(
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Start by creating your first project brief.\nTap the button below to get started.',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.outline,
              ),
              textAlign: TextAlign.center,
            ),
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
        ),
      ),
    );
  }

  Widget _buildProjectList(BuildContext context, List projects) {
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
            separatorBuilder: (_, __) =>
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
