import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../providers/admin_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(adminDashboardMetricsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: metricsAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Loading metrics...'),
        error: (e, _) => AppErrorWidget(
          message: 'Failed to load dashboard metrics.',
          onRetry: () => ref.invalidate(adminDashboardMetricsProvider),
        ),
        data: (metrics) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminDashboardMetricsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _buildMetricCard(
                  'Total Projects',
                  metrics.totalProjects,
                  Icons.folder_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildMetricCard(
                  'Active Projects',
                  metrics.activeProjects,
                  Icons.trending_up,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildMetricCard(
                  'Awaiting Assignment',
                  metrics.projectsAwaitingAssignment,
                  Icons.person_add_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildMetricCard(
                  'Under Client Review',
                  metrics.projectsUnderClientReview,
                  Icons.rate_review_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildMetricCard(
                  'Completed Projects',
                  metrics.completedProjects,
                  Icons.check_circle_outline,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildMetricCard(
                  'Active Draughtsmen',
                  metrics.activeDraughtsmen,
                  Icons.people_outline,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildMetricCard(
                  'Pending Assignments',
                  metrics.pendingAssignments,
                  Icons.assignment_late_outlined,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, int value, IconData icon) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
