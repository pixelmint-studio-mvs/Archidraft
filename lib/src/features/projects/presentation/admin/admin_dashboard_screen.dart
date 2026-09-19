import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../domain/project.dart';
import '../../providers/admin_providers.dart';
import '../widgets/project_card.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Unassigned'),
              Tab(text: 'Active'),
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
    final asyncProjects = _getProvider(ref);

    return asyncProjects.when(
      loading: () => const AppLoadingIndicator(message: 'Loading projects...'),
      error: (e, _) => AppErrorWidget(
        message: 'Failed to load projects. Please try again.',
        onRetry: () => ref.invalidate(_getProviderRef()),
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

  AsyncValue _getProvider(WidgetRef ref) {
    if (status == 'SUBMITTED') return ref.watch(pendingProjectsProvider);
    if (status == 'WAITING_ASSIGNMENT')
      return ref.watch(unassignedProjectsProvider);
    return ref.watch(activeProjectsProvider);
  }

  FutureProvider<List<Project>> _getProviderRef() {
    if (status == 'SUBMITTED') return pendingProjectsProvider;
    if (status == 'WAITING_ASSIGNMENT') return unassignedProjectsProvider;
    return activeProjectsProvider;
  }
}
