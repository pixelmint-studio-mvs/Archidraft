import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_providers.dart';
import '../../projects/domain/project.dart';
import '../../projects/domain/project_status.dart';
import '../../projects/domain/correction.dart';
import '../../projects/presentation/widgets/project_status_chip.dart';
import '../domain/training_module.dart';
import '../providers/training_providers.dart';
import '../../profile/presentation/widgets/student_skill_matrix.dart';
import '../../portfolio/providers/portfolio_providers.dart';
import '../../profile/providers/credentials_providers.dart';
import '../../profile/providers/achievements_providers.dart';
import '../../profile/providers/metrics_providers.dart';

// ─────────────────────────────────────────────
// LOCAL PROVIDERS
// ─────────────────────────────────────────────

class PendingCorrectionItem {
  final Project project;
  final Correction correction;

  PendingCorrectionItem(this.project, this.correction);
}

final _studioCorrectionsProvider = FutureProvider.autoDispose<List<PendingCorrectionItem>>((ref) async {
  final assignments = await ref.watch(studentAssignmentsProvider.future);
  final corrections = await ref.watch(studentCorrectionsProvider.future);

  final projectsWithCorrections = assignments
      .where((p) => p.correctionRound > 0 && !(p.projectStatus?.isTerminal ?? true))
      .toList();

  final List<PendingCorrectionItem> allCorrections = [];

  for (final p in projectsWithCorrections) {
    final projCorrections = corrections.where((c) => c.projectId == p.projectId).toList();
    for (final c in projCorrections) {
      allCorrections.add(PendingCorrectionItem(p, c));
    }
  }

  allCorrections.sort((a, b) => b.correction.createdAt.compareTo(a.correction.createdAt));
  return allCorrections;
});

class OverallTrainingStats {
  final double overallProgress;
  final int completedModules;
  final int inProgressModules;
  final int totalModules;

  OverallTrainingStats({
    required this.overallProgress,
    required this.completedModules,
    required this.inProgressModules,
    required this.totalModules,
  });
}

final _overallTrainingStatsProvider = Provider.autoDispose<AsyncValue<OverallTrainingStats>>((ref) {
  final progressAsync = ref.watch(categoryProgressProvider);
  final modulesAsync = ref.watch(studentModulesProvider);

  if (progressAsync.isLoading || modulesAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (progressAsync.hasError) {
    return AsyncValue.error(progressAsync.error!, progressAsync.stackTrace!);
  }
  if (modulesAsync.hasError) {
    return AsyncValue.error(modulesAsync.error!, modulesAsync.stackTrace!);
  }

  final progressList = progressAsync.value!;
  final modules = modulesAsync.value!;

  final totalProgress = progressList.fold<double>(0.0, (sum, p) => sum + p.overallProgress);
  final averageProgress = progressList.isNotEmpty ? totalProgress / progressList.length : 0.0;

  final completed = modules.where((m) => m.status == 'Completed').length;
  final inProgress = modules.where((m) => m.status == 'In Progress').length;

  return AsyncValue.data(OverallTrainingStats(
    overallProgress: averageProgress,
    completedModules: completed,
    inProgressModules: inProgress,
    totalModules: modules.length,
  ));
});

class ContinueLearningData {
  final TrainingModule module;
  final int moduleIndex;
  final int totalCategoryModules;

  ContinueLearningData(this.module, this.moduleIndex, this.totalCategoryModules);
}

final _continueLearningModuleProvider = Provider.autoDispose<AsyncValue<ContinueLearningData?>>((ref) {
  final modulesAsync = ref.watch(studentModulesProvider);

  return modulesAsync.whenData((modules) {
    if (modules.isEmpty) return null;

    TrainingModule? targetModule;

    final inProgress = modules.where((m) => m.status == 'In Progress').toList();
    if (inProgress.isNotEmpty) {
      targetModule = inProgress.first;
    } else {
      final notStarted = modules.where((m) => m.status == 'Not Started' && !m.isLocked).toList();
      if (notStarted.isNotEmpty) {
        targetModule = notStarted.first;
      }
    }

    if (targetModule == null) return null;

    final categoryModules = modules.where((m) => m.category == targetModule!.category).toList();
    final index = categoryModules.indexOf(targetModule) + 1;

    return ContinueLearningData(targetModule, index, categoryModules.length);
  });
});


/// Student Studio — the Student's workspace dashboard.
class StudentStudioScreen extends ConsumerWidget {
  const StudentStudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final useWideLayout = screenWidth >= 720;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.secondary,
          onRefresh: () async {
            ref.invalidate(userProfileProvider);
            ref.invalidate(categoryProgressProvider);
            ref.invalidate(studentModulesProvider);
            ref.invalidate(studentAssignmentsProvider);
            ref.invalidate(_studioCorrectionsProvider);
            ref.invalidate(studentActivityProvider);
            ref.invalidate(studentPortfolioProvider);
            ref.invalidate(studentCredentialsProvider);
            ref.invalidate(studentAchievementsProvider);
            ref.invalidate(studentMetricsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Welcome Header ──
                _WelcomeHeader(profileAsync: profileAsync),
                const SizedBox(height: AppSpacing.xl),

                if (useWideLayout) ...[
                  // ── Wide layout: 2-column ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column
                      Expanded(
                        child: Column(
                          children: const [
                            _OverallProgressSection(),
                            SizedBox(height: AppSpacing.lg),
                            _ContinueLearningSection(),
                            SizedBox(height: AppSpacing.lg),
                            _ActiveProjectSection(),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      // Right column
                      Expanded(
                        child: Column(
                          children: const [
                            _PortfolioHighlightsSection(),
                            SizedBox(height: AppSpacing.lg),
                            _PendingCorrectionsSection(),
                            SizedBox(height: AppSpacing.lg),
                            _RecentActivitySection(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _ProfessionalReadinessSection(),
                  const SizedBox(height: AppSpacing.xl),
                  const StudentSkillMatrix(),
                ] else ...[
                  // ── Narrow layout: single column ──
                  const _OverallProgressSection(),
                  const SizedBox(height: AppSpacing.xl),
                  const _ContinueLearningSection(),
                  const SizedBox(height: AppSpacing.xl),
                  const _ActiveProjectSection(),
                  const SizedBox(height: AppSpacing.xl),
                  const _PortfolioHighlightsSection(),
                  const SizedBox(height: AppSpacing.xl),
                  const _PendingCorrectionsSection(),
                  const SizedBox(height: AppSpacing.xl),
                  const _ProfessionalReadinessSection(),
                  const SizedBox(height: AppSpacing.xl),
                  const StudentSkillMatrix(),
                  const SizedBox(height: AppSpacing.xl),
                  const _RecentActivitySection(),
                ],

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WELCOME HEADER
// ─────────────────────────────────────────────

class _WelcomeHeader extends StatelessWidget {
  final AsyncValue profileAsync;

  const _WelcomeHeader({required this.profileAsync});

  @override
  Widget build(BuildContext context) {
    final name = profileAsync.when(
      data: (profile) => profile?.name ?? 'Student',
      loading: () => '...',
      error: (err, st) => 'Student',
    );

    final firstName = name.split(' ').first;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 640;

          final greetingContent = Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: const Icon(
                  Icons.architecture,
                  color: AppColors.onSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $firstName',
                      style: AppTypography.headlineLgMobile.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Continue your training and keep your projects moving.',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final portfolioButton = ElevatedButton.icon(
            onPressed: () {
              context.push('/student/portfolio');
            },
            icon: const Icon(Icons.work),
            label: const Text('View My Portfolio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                greetingContent,
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: portfolioButton,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: greetingContent),
              const SizedBox(width: AppSpacing.lg),
              portfolioButton,
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// OVERALL TRAINING PROGRESS
// ─────────────────────────────────────────────

class _OverallProgressSection extends ConsumerWidget {
  const _OverallProgressSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_overallTrainingStatsProvider);

    return _StudioCard(
      child: statsAsync.when(
        loading: () => const _SectionLoading(),
        error: (err, _) => _SectionError(
          message: 'Could not load progress.',
          onRetry: () {
            ref.invalidate(categoryProgressProvider);
            ref.invalidate(studentModulesProvider);
          },
        ),
        data: (stats) {
          if (stats.totalModules == 0) {
            return const _SectionEmpty(
              icon: Icons.trending_up_outlined,
              message: 'No training progress yet.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OVERALL TRAINING',
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(stats.overallProgress * 100).toInt()}%',
                    style: AppTypography.headlineLgMobile.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                child: LinearProgressIndicator(
                  value: stats.overallProgress,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${stats.completedModules} of ${stats.totalModules} modules completed',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (stats.inProgressModules > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${stats.inProgressModules} module${stats.inProgressModules > 1 ? 's' : ''} in progress',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/student/training');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text('Continue Training \u2192', style: AppTypography.buttonText),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


// ─────────────────────────────────────────────
// CONTINUE LEARNING
// ─────────────────────────────────────────────

class _ContinueLearningSection extends ConsumerWidget {
  const _ContinueLearningSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moduleAsync = ref.watch(_continueLearningModuleProvider);

    return _StudioCard(
      child: moduleAsync.when(
        loading: () => const _SectionLoading(),
        error: (err, _) => _SectionError(
          message: 'Could not load modules.',
          onRetry: () => ref.invalidate(studentModulesProvider),
        ),
        data: (data) {
          if (data == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONTINUE LEARNING',
                  style: AppTypography.labelMono.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const _SectionEmpty(
                  icon: Icons.school_outlined,
                  message: "You're ready to start your next module.",
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed: () => context.go('/student/training'),
                  child: const Text('Browse Training \u2192'),
                ),
              ],
            );
          }

          final module = data.module;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONTINUE LEARNING',
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                module.title,
                style: AppTypography.headlineSmMobile.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                module.category,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Module ${data.moduleIndex} of ${data.totalCategoryModules}',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${(module.progress * 100).toInt()}%',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                child: LinearProgressIndicator(
                  value: module.progress,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.push('/student/training/${module.id}');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text('Continue Learning \u2192', style: AppTypography.buttonText),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ACTIVE TRAINING PROJECT
// ─────────────────────────────────────────────

class _ActiveProjectSection extends ConsumerWidget {
  const _ActiveProjectSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(studentAssignmentsProvider);

    return _StudioCard(
      child: assignmentsAsync.when(
        loading: () => const _SectionLoading(),
        error: (err, _) => _SectionError(
          message: 'Could not load projects.',
          onRetry: () => ref.invalidate(studentAssignmentsProvider),
        ),
        data: (assignments) {
          final activeProjects = assignments.where((p) {
            final status = p.projectStatus;
            return status != null && !status.isTerminal;
          }).toList();

          if (activeProjects.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT PROJECT',
                  style: AppTypography.labelMono.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const _SectionEmpty(
                  icon: Icons.assignment_outlined,
                  message: 'No active training project.',
                ),
              ],
            );
          }

          final project = activeProjects.first;
          final status = project.projectStatus ?? ProjectStatus.draft;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CURRENT PROJECT',
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                project.projectName.isEmpty ? 'Untitled Project' : project.projectName,
                style: AppTypography.headlineSmMobile.copyWith(
                  color: AppColors.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (project.drawingType.isNotEmpty)
                Text(
                  project.drawingType,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              ProjectStatusChip(status: status),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.push('/student/projects/${project.projectId}');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text('Continue Project \u2192', style: AppTypography.buttonText),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PENDING CORRECTIONS
// ─────────────────────────────────────────────

class _PendingCorrectionsSection extends ConsumerWidget {
  const _PendingCorrectionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final correctionsAsync = ref.watch(_studioCorrectionsProvider);

    return _StudioCard(
      child: correctionsAsync.when(
        loading: () => const _SectionLoading(),
        error: (err, _) => _SectionError(
          message: 'Could not load corrections.',
          onRetry: () => ref.invalidate(_studioCorrectionsProvider),
        ),
        data: (corrections) {
          if (corrections.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CORRECTIONS',
                  style: AppTypography.labelMono.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const _SectionEmpty(
                  icon: Icons.check_circle_outline,
                  message: "You're all caught up.",
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CORRECTIONS',
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${corrections.length} correction${corrections.length > 1 ? 's' : ''} need${corrections.length == 1 ? 's' : ''} your attention',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(color: AppColors.surfaceVariant),
              const SizedBox(height: AppSpacing.sm),
              ...corrections.map((item) {
                final project = item.project;
                final correction = item.correction;
                final statusColor = correction.status == CorrectionStatus.open
                    ? AppColors.error
                    : AppColors.warning;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.projectName.isEmpty ? 'Untitled Project' : project.projectName,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '"${correction.description}"',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurface,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Text(
                              correction.status.value,
                              style: AppTypography.labelMono.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.push('/student/projects/${project.projectId}');
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Review Correction \u2192'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PORTFOLIO HIGHLIGHTS
// ─────────────────────────────────────────────

class _PortfolioHighlightsSection extends ConsumerWidget {
  const _PortfolioHighlightsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(studentPortfolioProvider);
    final credentialsAsync = ref.watch(studentCredentialsProvider);
    final achievementsAsync = ref.watch(studentAchievementsProvider);

    final isLoading = portfolioAsync.isLoading && credentialsAsync.isLoading && achievementsAsync.isLoading;
    if (isLoading) {
      return const _StudioCard(child: _SectionLoading());
    }

    final hasError = portfolioAsync.hasError && credentialsAsync.hasError;
    if (hasError) {
      return _StudioCard(
        child: _SectionError(
          message: 'Could not load portfolio highlights.',
          onRetry: () {
            ref.invalidate(studentPortfolioProvider);
            ref.invalidate(studentCredentialsProvider);
            ref.invalidate(studentAchievementsProvider);
          },
        ),
      );
    }

    final portfolio = portfolioAsync.value ?? [];
    final credentials = credentialsAsync.value ?? [];
    final achievements = achievementsAsync.value ?? [];
    final unlockedMilestones = achievements.where((a) => a.isUnlocked).length;

    // Latest approved deliverable if any
    final latestProject = portfolio.isNotEmpty ? portfolio.first : null;

    return _StudioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PORTFOLIO & EVIDENCE',
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const Icon(
                Icons.verified_outlined,
                size: 18,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Evidence counters
          Row(
            children: [
              Expanded(
                child: _StudioHighlightStat(
                  count: '${portfolio.length}',
                  label: 'Approved Works',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StudioHighlightStat(
                  count: '${credentials.length}',
                  label: 'Credentials',
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StudioHighlightStat(
                  count: '$unlockedMilestones',
                  label: 'Milestones',
                  color: AppColors.tertiary,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.surfaceVariant),
          const SizedBox(height: AppSpacing.md),

          if (latestProject != null) ...[
            Text(
              'LATEST APPROVED DELIVERABLE',
              style: AppTypography.labelMono.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        latestProject.projectName,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        latestProject.drawingType,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.secondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                  ),
                  child: Text(
                    '${latestProject.evaluation.overallPercentage}% Score',
                    style: AppTypography.labelMono.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ] else ...[
            Row(
              children: [
                Icon(Icons.assignment_turned_in_outlined, size: 20, color: AppColors.outlineVariant),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Complete practical assignments to build your verified portfolio.',
                    style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                context.push('/student/portfolio');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Text('View Full Portfolio \u2192', style: AppTypography.buttonText),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioHighlightStat extends StatelessWidget {
  final String count;
  final String label;
  final Color color;

  const _StudioHighlightStat({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: AppTypography.headlineSmMobile.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelMono.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// RECENT ACTIVITY
// ─────────────────────────────────────────────

class _RecentActivitySection extends ConsumerWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(studentActivityProvider);

    return _StudioCard(
      child: activityAsync.when(
        loading: () => const _SectionLoading(),
        error: (err, _) => _SectionError(
          message: 'Could not load activity.',
          onRetry: () => ref.invalidate(studentActivityProvider),
        ),
        data: (activities) {
          if (activities.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECENT ACTIVITY',
                  style: AppTypography.labelMono.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const _SectionEmpty(
                  icon: Icons.history_outlined,
                  message: 'No recent activity.',
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RECENT ACTIVITY',
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ...activities.take(8).map((activity) {
                final actionType = activity['action_type'] as String? ?? '';
                final projectName = activity['project_name'] as String? ?? '';
                final timestamp = activity['timestamp'] as String?;

                String label = _actionLabel(actionType);
                String formattedTime = '';
                if (timestamp != null) {
                  final dt = DateTime.tryParse(timestamp);
                  if (dt != null) {
                    formattedTime = _formatRelativeDate(dt);
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _actionIcon(actionType),
                        size: 18,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (projectName.isNotEmpty)
                              Text(
                                projectName,
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.secondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      if (formattedTime.isNotEmpty)
                        Text(
                          formattedTime,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.outlineVariant,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  static String _actionLabel(String actionType) {
    switch (actionType) {
      case 'FILE_UPLOADED':
        return 'Drawing submitted';
      case 'DRAWING_SUBMITTED':
        return 'Drawing submitted for review';
      case 'CORRECTION_REQUESTED':
        return 'Correction received';
      case 'PROJECT_SUBMITTED':
        return 'Project submitted';
      case 'PROJECT_COMPLETED':
        return 'Project completed';
      case 'ASSIGNMENT_ACCEPTED':
        return 'Assignment accepted';
      case 'FILE_DELETED':
        return 'File removed';
      default:
        return actionType.replaceAll('_', ' ').toLowerCase();
    }
  }

  static IconData _actionIcon(String actionType) {
    switch (actionType) {
      case 'FILE_UPLOADED':
        return Icons.upload_file_outlined;
      case 'DRAWING_SUBMITTED':
        return Icons.send_outlined;
      case 'CORRECTION_REQUESTED':
        return Icons.edit_note_outlined;
      case 'PROJECT_COMPLETED':
        return Icons.check_circle_outline;
      case 'ASSIGNMENT_ACCEPTED':
        return Icons.assignment_turned_in_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  static String _formatRelativeDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

// ─────────────────────────────────────────────
// SHARED STUDIO CARD WRAPPER
// ─────────────────────────────────────────────

class _StudioCard extends StatelessWidget {
  final Widget child;

  const _StudioCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
// SECTION STATE HELPERS
// ─────────────────────────────────────────────

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: AppColors.secondary,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _SectionError({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.error_outline, size: 20, color: AppColors.error.withValues(alpha: 0.7)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            message,
            style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
        if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: AppTypography.buttonText.copyWith(
                color: AppColors.secondary,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  final IconData icon;
  final String message;

  const _SectionEmpty({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 24, color: AppColors.outlineVariant),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            message,
            style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// PROFESSIONAL READINESS EVIDENCE
// ─────────────────────────────────────────────

class _ProfessionalReadinessSection extends ConsumerWidget {
  const _ProfessionalReadinessSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(studentMetricsProvider);

    return metricsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
      data: (metrics) {
        final readiness = metrics.readiness;
        if (readiness == null) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'PROFESSIONAL READINESS EVIDENCE',
                    style: AppTypography.labelMono.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Objective evidence rubric across curriculum mastery, practical execution, technical precision, and revision discipline.',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  final itemWidth = isWide ? (constraints.maxWidth - AppSpacing.md) / 2 : double.infinity;

                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        child: _ReadinessPillarCard(
                          icon: Icons.menu_book_outlined,
                          title: 'Curriculum Mastery',
                          value: '${readiness.curriculum.percentage}%',
                          subtitle: '${readiness.curriculum.completedLessons} of ${readiness.curriculum.totalLessons} lessons completed',
                          progress: readiness.curriculum.totalLessons > 0
                              ? readiness.curriculum.completedLessons / readiness.curriculum.totalLessons
                              : 0.0,
                          accentColor: AppColors.primary,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _ReadinessPillarCard(
                          icon: Icons.draw_outlined,
                          title: 'Practical Execution',
                          value: '${readiness.practical.completedProjects} Project${readiness.practical.completedProjects == 1 ? '' : 's'}',
                          subtitle: '${readiness.practical.approvedDeliverables} approved deliverable${readiness.practical.approvedDeliverables == 1 ? '' : 's'}',
                          accentColor: AppColors.secondary,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _ReadinessPillarCard(
                          icon: Icons.verified_outlined,
                          title: 'Technical Precision',
                          value: readiness.precision.averageScore != null
                              ? '${readiness.precision.averageScore} / 5.0'
                              : 'Pending Evals',
                          subtitle: readiness.precision.evaluationCount > 0
                              ? '${readiness.precision.evaluationCount} approved evaluation${readiness.precision.evaluationCount == 1 ? '' : 's'}'
                              : 'Evaluated upon approval',
                          progress: readiness.precision.averageScore != null
                              ? readiness.precision.averageScore! / 5.0
                              : null,
                          accentColor: AppColors.tertiary,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _ReadinessPillarCard(
                          icon: Icons.assignment_turned_in_outlined,
                          title: 'Revision Discipline',
                          value: '${readiness.revision.resolutionRate}% Resolved',
                          subtitle: '${readiness.revision.correctionsResolved} of ${readiness.revision.correctionsIssued} corrections resolved (${readiness.revision.totalRounds} round${readiness.revision.totalRounds == 1 ? '' : 's'})',
                          progress: readiness.revision.resolutionRate / 100.0,
                          accentColor: AppColors.success,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReadinessPillarCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final double? progress;
  final Color accentColor;

  const _ReadinessPillarCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    this.progress,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accentColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.headlineSmMobile.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                backgroundColor: AppColors.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
