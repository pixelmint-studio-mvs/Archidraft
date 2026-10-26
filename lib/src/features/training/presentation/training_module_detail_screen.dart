import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../projects/domain/project.dart';
import '../../projects/domain/project_status.dart';
import '../../projects/presentation/student/widgets/evaluation_card.dart';
import '../../projects/presentation/widgets/project_status_chip.dart';
import '../../projects/providers/assignment_providers.dart';
import '../../projects/providers/project_providers.dart';
import '../domain/training_module.dart';
import '../providers/training_providers.dart';

class TrainingModuleDetailScreen extends ConsumerStatefulWidget {
  final String moduleId;

  const TrainingModuleDetailScreen({
    super.key,
    required this.moduleId,
  });

  @override
  ConsumerState<TrainingModuleDetailScreen> createState() => _TrainingModuleDetailScreenState();
}

class _TrainingModuleDetailScreenState extends ConsumerState<TrainingModuleDetailScreen> {
  bool _isAccepting = false;

  @override
  Widget build(BuildContext context) {
    final moduleDetailAsync = ref.watch(moduleDetailProvider(widget.moduleId));
    final assignmentsAsync = ref.watch(studentAssignmentsProvider);
    final assignments = assignmentsAsync.value ?? [];
    final linkedProject = assignments.where((p) => p.trainingModuleId == widget.moduleId).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/student/training');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              moduleDetailAsync.value != null
                  ? '${moduleDetailAsync.value!.category.toUpperCase()} MODULE'
                  : 'TRAINING MODULE',
              style: AppTypography.labelMono.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              moduleDetailAsync.value?.title ?? 'Training Module',
              style: AppTypography.labelMono.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (moduleDetailAsync.value != null)
            Container(
              margin: const EdgeInsets.only(right: AppSpacing.md),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.tertiaryFixed,
                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              ),
              child: Text(
                moduleDetailAsync.value!.type.toUpperCase(),
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.tertiaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: moduleDetailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.secondary)),
        error: (error, stack) => Center(
          child: SelectableText(
            'Error loading module details for module ${widget.moduleId}: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (module) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(module, linkedProject),
                const SizedBox(height: AppSpacing.lg),
                _buildLessonsList(module),
                if (linkedProject != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _buildPracticalAssignmentCard(context, ref, module, linkedProject),
                ] else if (module.type == 'Mock Project') ...[
                  const SizedBox(height: AppSpacing.xl),
                  _buildPendingAssignmentCard(context),
                ],
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(TrainingModule module, Project? linkedProject) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  module.category.toUpperCase(),
                  style: AppTypography.labelMono.copyWith(color: AppColors.onPrimaryContainer, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                module.level,
                style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            module.title,
            style: AppTypography.headlineLgMobile.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            module.description,
            style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
          ),
          if (module.type == 'Module') ...[
            const SizedBox(height: AppSpacing.lg),
            Builder(builder: (context) {
              final double progressFraction = module.progress > 1.0
                  ? (module.progress / 100.0).clamp(0.0, 1.0)
                  : module.progress.clamp(0.0, 1.0);
              final int progressPercent = (progressFraction * 100).round();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Module Progress',
                        style: AppTypography.labelMono.copyWith(color: AppColors.onSurface),
                      ),
                      Text(
                        '$progressPercent%',
                        style: AppTypography.labelMono.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    child: LinearProgressIndicator(
                      value: progressFraction,
                      backgroundColor: AppColors.surfaceContainer,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                      minHeight: 6,
                    ),
                  ),
                ],
              );
            }),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (module.imageUrl != null)
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      module.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${module.category.toUpperCase()} // ${module.type.toUpperCase()}',
                          style: AppTypography.labelMono.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          module.status.toUpperCase(),
                          style: AppTypography.labelMono.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        module.status == 'Completed' ? Icons.check_circle : Icons.school_outlined,
                        size: 16,
                        color: module.status == 'Completed' ? AppColors.tertiaryFixedDim : AppColors.secondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        module.durationOrFormat ?? '${module.category} Track',
                        style: AppTypography.labelMono.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: module.status == 'Completed'
                          ? AppColors.tertiaryFixed
                          : (module.status == 'In Progress' ? AppColors.primaryContainer : AppColors.surfaceContainerHigh),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      module.status.toUpperCase(),
                      style: AppTypography.labelMono.copyWith(
                        color: module.status == 'Completed'
                            ? AppColors.tertiaryContainer
                            : (module.status == 'In Progress' ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (module.status == 'Completed' && module.score != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FINAL ASSESSMENT',
                        style: AppTypography.labelMono.copyWith(color: AppColors.onPrimary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${module.score}',
                            style: AppTypography.headlineDisplay.copyWith(color: AppColors.onPrimary, fontSize: 34),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '/ 100',
                            style: AppTypography.labelMono.copyWith(color: AppColors.outlineVariant),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.tertiaryFixed,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              module.score! >= 90 ? 'DISTINCTION' : 'PASS',
                              style: AppTypography.labelMono.copyWith(color: AppColors.tertiaryContainer, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.military_tech, color: AppColors.tertiaryFixed, size: 28),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPracticalAssignmentCard(
    BuildContext context,
    WidgetRef ref,
    TrainingModule module,
    Project project,
  ) {
    final isWaitingAcceptance = project.projectStatus == ProjectStatus.waitingAcceptance;
    final evaluationsAsync = ref.watch(projectEvaluationsProvider(project.projectId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.architecture, color: AppColors.secondary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'PRACTICAL ASSIGNMENT',
                    style: AppTypography.labelMono.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                'STUDIO PROJECT',
                style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ProjectStatusChip(status: project.projectStatus ?? ProjectStatus.draft),
                  if (project.correctionRound > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryFixed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ROUND ${project.correctionRound}',
                        style: AppTypography.labelMono.copyWith(
                          color: AppColors.onSecondaryFixed,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                project.projectName,
                style: AppTypography.buttonText.copyWith(color: AppColors.onSurface, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                project.projectAddress,
                style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.draw, size: 14, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      'DRAWING TYPE: ',
                      style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11),
                    ),
                    Text(
                      project.drawingType.toUpperCase(),
                      style: AppTypography.labelMono.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (isWaitingAcceptance)
                ElevatedButton(
                  onPressed: _isAccepting
                      ? null
                      : () => _handleAcceptAssignment(context, ref, project),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.onSecondary,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  child: _isAccepting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.onSecondary,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Accept Practical Assignment',
                              style: AppTypography.buttonText,
                            ),
                          ],
                        ),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    context.push('/student/workspace/${project.projectId}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.open_in_new, color: AppColors.tertiaryFixed, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Open Practical Workspace',
                        style: AppTypography.buttonText,
                      ),
                    ],
                  ),
                ),
              evaluationsAsync.when(
                data: (evaluations) {
                  if (evaluations.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          const Icon(Icons.assignment_turned_in, color: AppColors.secondary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'OFFICIAL EVALUATION',
                            style: AppTypography.labelMono.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      EvaluationCard(evaluation: evaluations.first),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.md),
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (error, stack) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingAssignmentCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment_outlined, color: AppColors.secondary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'PRACTICAL ASSIGNMENT',
                    style: AppTypography.labelMono.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                'STUDIO_ADMIN',
                style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pending_actions_outlined, color: AppColors.secondary, size: 24),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Assignment Pending Studio Admin',
                style: AppTypography.buttonText.copyWith(color: AppColors.onSurface, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'No practical project has been assigned to this module yet. Your Studio Admin (STUDIO_ADMIN) will assign a practical drafting project to your portal.',
                style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'STATUS: PENDING ASSIGNMENT',
                  style: AppTypography.labelMono.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleAcceptAssignment(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    setState(() {
      _isAccepting = true;
    });

    try {
      final success = await ref
          .read(draughtsmanActionsControllerProvider.notifier)
          .acceptAssignment(
            assignmentId: project.currentAssignmentId ?? project.projectId,
            projectId: project.projectId,
          );

      if (!context.mounted) return;

      if (success) {
        ref.invalidate(studentAssignmentsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Practical assignment accepted! Workspace is ready.'),
            backgroundColor: AppColors.secondary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept practical assignment. Please retry.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
      }
    }
  }

  Widget _buildLessonsList(TrainingModule module) {
    return Consumer(
      builder: (context, ref, child) {
        final lessonsAsync = ref.watch(moduleLessonsProvider(module.id));

        return lessonsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.secondary)),
          error: (error, stack) => Center(child: Text('Error loading lessons: $error', style: const TextStyle(color: Colors.red))),
          data: (lessons) {
            if (lessons.isEmpty) {
              if (module.type == 'Mock Project') {
                return const SizedBox.shrink();
              }
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: const Center(
                  child: Text('No lessons available for this module yet.', style: TextStyle(color: AppColors.onSurfaceVariant)),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                  child: Text(
                    'MODULE LESSONS',
                    style: AppTypography.labelMono.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold),
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lessons.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    final isCompleted = lesson.status == 'COMPLETED';
                    final isNext = !isCompleted && (index == 0 || lessons[index - 1].status == 'COMPLETED');

                    return InkWell(
                      onTap: () {
                        context.push('/student/training/lessons/${lesson.id}');
                      },
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isNext ? AppColors.surfaceContainerLow : AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          border: isNext ? Border.all(color: AppColors.secondary.withValues(alpha: 0.3)) : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isCompleted ? AppColors.tertiaryFixed : (isNext ? AppColors.secondary : AppColors.surfaceContainerHigh),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(Icons.check, color: AppColors.tertiaryContainer, size: 16)
                                    : Text(
                                        '${index + 1}',
                                        style: AppTypography.labelMono.copyWith(
                                          color: isNext ? AppColors.onSecondary : AppColors.onSurfaceVariant,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text(
                                    lesson.title,
                                    style: AppTypography.buttonText.copyWith(color: AppColors.onSurface),
                                  ),
                                  if (lesson.estimatedDuration != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      lesson.estimatedDuration!,
                                      style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
