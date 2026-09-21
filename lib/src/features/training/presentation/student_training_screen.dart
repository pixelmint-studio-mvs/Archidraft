import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../projects/domain/project.dart';
import '../../projects/presentation/widgets/project_card.dart';
import '../domain/training_module.dart';
import '../providers/training_providers.dart';
class StudentTrainingScreen extends ConsumerStatefulWidget {
  const StudentTrainingScreen({super.key});

  @override
  ConsumerState<StudentTrainingScreen> createState() => _StudentTrainingScreenState();
}

class _StudentTrainingScreenState extends ConsumerState<StudentTrainingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modulesAsync = ref.watch(studentModulesProvider);
    final progressAsync = ref.watch(categoryProgressProvider);
    final assignmentsAsync = ref.watch(studentAssignmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBright.withValues(alpha: 0.9),
        title: Text(
          'Learning Path',
          style: AppTypography.headlineLgMobile.copyWith(color: AppColors.primary),
        ),

        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.secondary,
          tabs: const [
            Tab(text: 'Architectural'),
            Tab(text: 'Structural'),
            Tab(text: 'Interior'),
            Tab(text: 'Approval'),
          ],
        ),
      ),
      body: modulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.secondary)),
        error: (err, stack) => _buildErrorState(err.toString(), () => ref.refresh(studentModulesProvider)),
        data: (modules) {
          final allAssignments = assignmentsAsync.asData?.value ?? [];
          if (modules.isEmpty && allAssignments.isEmpty) {
            return _buildEmptyState();
          }

          final archModules = modules.where((m) => m.category == 'Architectural').toList();
          final structModules = modules.where((m) => m.category == 'Structural').toList();
          final intModules = modules.where((m) => m.category == 'Interior').toList();
          final apprModules = modules.where((m) => m.category == 'Approval').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _TrainingCategoryView(
                title: 'Architectural Drafting Foundations',
                modules: archModules,
                category: 'Architectural',
                progressAsync: progressAsync,
                assignments: allAssignments.where((a) => archModules.any((m) => m.id == a.trainingModuleId)).toList(),
              ),
              _TrainingCategoryView(
                title: 'Structural Systems Analysis',
                modules: structModules,
                category: 'Structural',
                progressAsync: progressAsync,
                assignments: allAssignments.where((a) => structModules.any((m) => m.id == a.trainingModuleId)).toList(),
              ),
              _TrainingCategoryView(
                title: 'Interior Space Planning',
                modules: intModules,
                category: 'Interior',
                progressAsync: progressAsync,
                assignments: allAssignments.where((a) => intModules.any((m) => m.id == a.trainingModuleId)).toList(),
              ),
              _TrainingCategoryView(
                title: 'Building Approval Codes',
                modules: apprModules,
                category: 'Approval',
                progressAsync: progressAsync,
                assignments: allAssignments.where((a) => apprModules.any((m) => m.id == a.trainingModuleId)).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school_outlined, size: 64, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No Training Modules',
            style: AppTypography.headlineLgMobile.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'You currently have no training modules assigned.',
            style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to Load Modules',
              style: AppTypography.headlineLgMobile.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'An error occurred connecting to the server. Please try again.',
              style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.onSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainingCategoryView extends StatelessWidget {
  final String title;
  final List<TrainingModule> modules;
  final String category;
  final AsyncValue<List<TrainingCategoryProgress>> progressAsync;
  final List<Project> assignments;

  const _TrainingCategoryView({
    required this.title,
    required this.modules,
    required this.category,
    required this.progressAsync,
    required this.assignments,
  });

  @override
  Widget build(BuildContext context) {
    final mockProjects = modules.where((m) => m.type == 'Mock Project').toList();
    final currentModules = modules.where((m) => m.type == 'Module').toList();
    final masterclass = modules.where((m) => m.type == 'Masterclass').firstOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressSection(),
          const SizedBox(height: AppSpacing.xl),
          if (mockProjects.isNotEmpty || masterclass != null || assignments.isNotEmpty) ...[
            Text(
              'Training Projects',
              style: AppTypography.headlineLgMobile.copyWith(
                color: AppColors.primary,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildProjectsGrid(context, mockProjects, masterclass, assignments),
            const SizedBox(height: AppSpacing.xl),
          ],
          if (currentModules.isNotEmpty) ...[
            Text(
              'Current Modules',
              style: AppTypography.buttonText.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildCurrentModules(currentModules),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.secondary)),
        error: (_, __) => Text('Failed to load progress', style: AppTypography.labelMono.copyWith(color: AppColors.error)),
        data: (progressList) {
          final p = progressList.firstWhere((p) => p.category == category, orElse: () => TrainingCategoryProgress(category: category, overallProgress: 0.0));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Module Progress',
                    style: AppTypography.labelMono.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${(p.overallProgress * 100).toInt()}% Complete',
                    style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                child: LinearProgressIndicator(
                  value: p.overallProgress,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                  minHeight: 8,
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildProjectsGrid(
      BuildContext context, 
      List<TrainingModule> mockProjects, 
      TrainingModule? masterclass,
      List<Project> assignments) {
    
    // Flatten mock projects and real assignments into a single list of widgets to display
    List<Widget> projectCards = [];
    
    for (final mock in mockProjects) {
      projectCards.add(Expanded(child: _buildMockProjectCard(context, mock)));
    }

    for (final assignment in assignments) {
      projectCards.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: ProjectCard(
              project: assignment,
              onTap: () => context.push('/student/projects/${assignment.projectId}'),
            ),
          ),
        ),
      );
    }

    // Pair them up in rows
    List<Widget> rows = [];
    for (int i = 0; i < projectCards.length; i += 2) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              projectCards[i],
              const SizedBox(width: AppSpacing.md),
              if (i + 1 < projectCards.length)
                projectCards[i + 1]
              else
                Expanded(child: const SizedBox()),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ...rows,
        if (masterclass != null) ...[
          const SizedBox(height: AppSpacing.md),
          _buildMasterclassCard(context, masterclass),
        ],
      ],
    );
  }


  Widget _buildMockProjectCard(BuildContext context, TrainingModule module) {
    final isCompleted = module.status == 'Completed';
    final badgeColor = isCompleted ? AppColors.surfaceVariant : AppColors.primaryContainer;
    final badgeText = isCompleted ? AppColors.onSurface : AppColors.onPrimaryContainer;
    
    return GestureDetector(
      onTap: () {
        context.push('/student/training/${module.id}');
      },
      child: Container(
        height: 280, // Fixed height to keep cards aligned
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    module.level,
                    style: AppTypography.labelMono.copyWith(color: badgeText),
                  ),
                ),
                const Icon(Icons.bookmark_border, color: AppColors.outline, size: 20),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: const Center(
                child: Icon(Icons.architecture, color: AppColors.outlineVariant, size: 40),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.title,
                    style: AppTypography.buttonText.copyWith(color: AppColors.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    module.description,
                    style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  module.status,
                  style: AppTypography.labelMono.copyWith(
                    color: isCompleted ? AppColors.secondary : AppColors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
                if (!isCompleted && !module.isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Text(
                      'Continue',
                      style: AppTypography.buttonText.copyWith(color: AppColors.onPrimary, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterclassCard(BuildContext context, TrainingModule masterclass) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryFixedDim,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Pro Masterclass',
                  style: AppTypography.labelMono.copyWith(color: AppColors.tertiaryContainer),
                ),
              ),
              const Icon(Icons.lock, color: AppColors.outline, size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            masterclass.title,
            style: AppTypography.headlineLgMobile.copyWith(color: AppColors.primary, fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            masterclass.description,
            style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prerequisite: ${masterclass.prerequisites ?? 'None'}',
                style: AppTypography.labelMono.copyWith(color: AppColors.outline),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.outline),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Text(
                  masterclass.isLocked ? 'Locked' : 'Available',
                  style: AppTypography.buttonText.copyWith(color: AppColors.primary, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentModules(List<TrainingModule> currentModules) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        children: currentModules.map((m) {
          IconData icon = Icons.play_circle;
          if (m.durationOrFormat?.contains('PDF') == true) icon = Icons.description;
          if (m.durationOrFormat?.contains('Interactive') == true) icon = Icons.view_in_ar;

          return _buildModuleItem(icon, m.title, m.durationOrFormat ?? '');
        }).toList(),
      ),
    );
  }

  Widget _buildModuleItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.buttonText.copyWith(color: AppColors.onSurface),
                ),
                Text(
                  subtitle,
                  style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
