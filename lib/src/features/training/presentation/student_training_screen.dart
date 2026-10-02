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
  final List<String> _categories = [
    'Architectural',
    'Structural',
    'Interior',
    'Approval'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
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
      body: modulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.secondary)),
        error: (err, stack) => _buildErrorState(err.toString(), () => ref.refresh(studentModulesProvider)),
        data: (modules) {
          final allAssignments = assignmentsAsync.asData?.value ?? [];
          
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  backgroundColor: AppColors.surfaceBright.withValues(alpha: 0.9),
                  title: Text(
                    'Learning Hub',
                    style: AppTypography.headlineLgMobile.copyWith(color: AppColors.primary),
                  ),
                  floating: true,
                  pinned: true,
                  bottom: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.onSurfaceVariant,
                    indicatorColor: AppColors.secondary,
                    tabs: _categories.map((c) => Tab(text: c)).toList(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverviewSection(modules),
                      _buildContinueLearning(modules),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                final categoryModules = modules.where((m) => m.category == category).toList();
                final categoryAssignments = allAssignments.where((a) => categoryModules.any((m) => m.id == a.trainingModuleId)).toList();
                
                String title = '$category Training';
                if (category == 'Architectural') title = 'Architectural Drafting Foundations';
                if (category == 'Structural') title = 'Structural Systems Analysis';
                if (category == 'Interior') title = 'Interior Space Planning';
                if (category == 'Approval') title = 'Building Approval Codes';

                return _TrainingCategoryView(
                  title: title,
                  modules: categoryModules,
                  category: category,
                  progressAsync: progressAsync,
                  assignments: categoryAssignments,
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewSection(List<TrainingModule> modules) {
    if (modules.isEmpty) return const SizedBox();

    final totalModules = modules.length;
    final completedModules = modules.where((m) => m.status == 'Completed').length;
    final overallProgress = totalModules > 0 ? completedModules / totalModules : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Training Journey',
              style: AppTypography.headlineLgMobile.copyWith(color: AppColors.onPrimary, fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Complete modules and masterclasses to advance your skills.',
              style: AppTypography.bodySm.copyWith(color: AppColors.onPrimary.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overall Progress',
                  style: AppTypography.labelMono.copyWith(color: AppColors.onPrimary),
                ),
                Text(
                  '${(overallProgress * 100).toInt()}%',
                  style: AppTypography.labelMono.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: LinearProgressIndicator(
                value: overallProgress,
                backgroundColor: AppColors.onPrimary.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueLearning(List<TrainingModule> modules) {
    if (modules.isEmpty) return const SizedBox();

    TrainingModule? nextModule = modules.where((m) => m.status == 'In Progress').firstOrNull;
    nextModule ??= modules.where((m) => m.status == 'Not Started' && !m.isLocked).firstOrNull;

    if (nextModule == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Continue Learning',
            style: AppTypography.headlineLgMobile.copyWith(color: AppColors.primary, fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () => context.push('/student/training/${nextModule!.id}'),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.play_arrow, color: AppColors.onSecondaryContainer),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nextModule.category,
                          style: AppTypography.labelMono.copyWith(color: AppColors.secondary, fontSize: 10),
                        ),
                        Text(
                          nextModule.title,
                          style: AppTypography.buttonText.copyWith(color: AppColors.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.outline),
                ],
              ),
            ),
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

    if (modules.isEmpty && assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 48, color: AppColors.outlineVariant),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No Modules in $category',
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryProgress(),
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
              'Learning Modules',
              style: AppTypography.headlineLgMobile.copyWith(
                color: AppColors.primary,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildCurrentModules(context, currentModules),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryProgress() {
    final total = modules.length;
    final completed = modules.where((m) => m.status == 'Completed').length;
    final percentage = total > 0 ? completed / total : 0.0;

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
      child: Column(
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
                'Category Progress',
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(percentage * 100).toInt()}% Complete',
                style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '$completed of $total modules completed',
            style: AppTypography.labelMono.copyWith(color: AppColors.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsGrid(
      BuildContext context, 
      List<TrainingModule> mockProjects, 
      TrainingModule? masterclass,
      List<Project> assignments) {
    
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
        height: 280, 
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
                if (isCompleted)
                  const Icon(Icons.check_circle, color: AppColors.secondary, size: 20)
                else
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
                      module.status == 'In Progress' ? 'Continue' : 'Start',
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
    final isCompleted = masterclass.status == 'Completed';

    return GestureDetector(
      onTap: () {
        if (!masterclass.isLocked) {
          context.push('/student/training/${masterclass.id}');
        }
      },
      child: Container(
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
                    color: isCompleted ? AppColors.surfaceVariant : AppColors.tertiaryFixedDim,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Pro Masterclass',
                    style: AppTypography.labelMono.copyWith(
                      color: isCompleted ? AppColors.onSurfaceVariant : AppColors.tertiaryContainer
                    ),
                  ),
                ),
                if (masterclass.isLocked)
                  const Icon(Icons.lock, color: AppColors.outline, size: 20)
                else if (isCompleted)
                  const Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
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
                    color: masterclass.status == 'In Progress' ? AppColors.primary : Colors.transparent,
                  ),
                  child: Text(
                    masterclass.isLocked 
                        ? 'Locked' 
                        : (masterclass.status == 'In Progress' ? 'Continue' : masterclass.status),
                    style: AppTypography.buttonText.copyWith(
                      color: masterclass.status == 'In Progress' ? AppColors.onPrimary : AppColors.primary, 
                      fontSize: 12
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentModules(BuildContext context, List<TrainingModule> currentModules) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        children: currentModules.asMap().entries.map((entry) {
          final index = entry.key;
          final m = entry.value;
          final isLast = index == currentModules.length - 1;
          
          IconData icon = Icons.play_circle;
          if (m.durationOrFormat?.contains('PDF') == true) icon = Icons.description;
          if (m.durationOrFormat?.contains('Interactive') == true) icon = Icons.view_in_ar;
          if (m.status == 'Completed') icon = Icons.check_circle;

          return _buildModuleItem(context, m, icon, isLast);
        }).toList(),
      ),
    );
  }

  Widget _buildModuleItem(BuildContext context, TrainingModule m, IconData icon, bool isLast) {
    final isCompleted = m.status == 'Completed';
    final isInProgress = m.status == 'In Progress';
    
    return InkWell(
      onTap: () {
        if (!m.isLocked) {
          context.push('/student/training/${m.id}');
        }
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: isLast ? null : Border(
            bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.secondary.withValues(alpha: 0.1) : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCompleted 
                      ? AppColors.secondary.withValues(alpha: 0.3) 
                      : AppColors.outlineVariant.withValues(alpha: 0.3)
                ),
              ),
              child: Icon(
                icon, 
                color: isCompleted ? AppColors.secondary : AppColors.primary
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.title,
                    style: AppTypography.buttonText.copyWith(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        m.durationOrFormat ?? '',
                        style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.outlineVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        m.status,
                        style: AppTypography.labelMono.copyWith(
                          color: isCompleted 
                              ? AppColors.secondary 
                              : (isInProgress ? AppColors.primary : AppColors.onSurfaceVariant),
                          fontWeight: isInProgress ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (m.isLocked)
              const Icon(Icons.lock, size: 20, color: AppColors.outline)
            else
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}
