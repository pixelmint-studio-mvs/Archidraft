import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../domain/project.dart';
import '../../providers/project_providers.dart';

import '../widgets/project_card.dart';

class AdminProjectsScreen extends StatelessWidget {
  const AdminProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text('All Projects'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Unassigned'),
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.outline,
          ),
        ),
        body: const TabBarView(
          children: [
            _ProjectListTab(status: 'SUBMITTED'),
            _ProjectListTab(status: 'WAITING_ASSIGNMENT'),
            _ProjectListTab(status: 'IN_PROGRESS'),
            _ProjectListTab(status: 'COMPLETED'),
          ],
        ),
      ),
    );
  }
}

class _ProjectListTab extends ConsumerWidget {
  final String status;
  const _ProjectListTab({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We will just fetch all projects and filter for now, or update the provider
    // Since we don't have separate providers for all statuses, let's fetch all client projects (which admin can access)
    // Actually, ProjectRepository.getProjectsByStatus exists. Let's create a family provider or use existing.
    // For simplicity, we can use a FutureProvider.family here.
    final asyncProjects = ref.watch(projectsByStatusProvider(status));

    return asyncProjects.when(
      loading: () => const AppLoadingIndicator(message: 'Loading projects...'),
      error: (e, _) => AppErrorWidget(
        message: 'Failed to load projects.',
        onRetry: () => ref.invalidate(projectsByStatusProvider(status)),
      ),
      data: (projects) {
        if (projects.isEmpty) {
          return Center(
            child: Text(
              'No projects found in this state.',
              style: TextStyle(color: AppColors.outline),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 1024
                ? 3
                : constraints.maxWidth >= 600
                ? 2
                : 1;

            if (crossAxisCount == 1) {
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.marginMobile),
                itemCount: projects.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return ProjectCard(
                    project: project,
                    onTap: () =>
                        context.go('/admin/projects/${project.projectId}'),
                  );
                },
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.marginTablet),
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
                      context.go('/admin/projects/${project.projectId}'),
                );
              },
            );
          },
        );
      },
    );
  }
}

final projectsByStatusProvider = FutureProvider.family<List<Project>, String>((ref, status) async {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.getProjectsByStatus(status);
});
