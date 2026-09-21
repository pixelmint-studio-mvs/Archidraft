import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../projects/presentation/widgets/project_card.dart';
import '../providers/training_providers.dart';

class StudentDrawingsScreen extends ConsumerWidget {
  const StudentDrawingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(studentAssignmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(studentAssignmentsProvider);
          },
          color: AppColors.secondary,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Drawings Library',
                        style: AppTypography.headlineLgMobile
                            .copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Access all your past and current training drawings.',
                        style: AppTypography.bodyMd
                            .copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
              assignmentsAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.secondary),
                  ),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'Failed to load drawings.\n$error',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMd
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                  ),
                ),
                data: (assignments) {
                  if (assignments.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.layers_clear,
                              size: 64,
                              color: AppColors.outlineVariant.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No Drawings Yet',
                              style: AppTypography.headlineSmMobile
                                  .copyWith(color: AppColors.onSurface),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Your training assignments will appear here.',
                              style: AppTypography.bodyMd
                                  .copyWith(color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Split into a grid with max width constraints if needed, or simple grid
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 400, // Handle web responsiveness
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        childAspectRatio: 0.8, // Adjust based on ProjectCard size
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final assignment = assignments[index];
                          return ProjectCard(
                            project: assignment,
                            onTap: () => context.push(
                                '/student/projects/${assignment.projectId}'),
                          );
                        },
                        childCount: assignments.length,
                      ),
                    ),
                  );
                },
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xxl)),
            ],
          ),
        ),
      ),
    );
  }
}
