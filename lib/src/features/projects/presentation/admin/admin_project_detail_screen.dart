import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../domain/evaluation.dart';
import '../../domain/project.dart';
import '../../domain/project_status.dart';
import '../../providers/admin_providers.dart';
import '../../providers/project_providers.dart';
import '../student/widgets/evaluation_card.dart';
import '../widgets/evaluation_dialog.dart';
import '../widgets/project_status_chip.dart';

class AdminProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const AdminProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectProvider(projectId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        title: const Text('Admin Project Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Project',
            onPressed: () =>
                context.push('/admin/projects/$projectId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.attach_money),
            tooltip: 'Financials',
            onPressed: () =>
                context.push('/admin/projects/$projectId/financials'),
          ),
        ],
      ),
      body: projectAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Loading project...'),
        error: (error, _) => AppErrorWidget(
          message: 'Failed to load project.',
          onRetry: () => ref.invalidate(projectProvider(projectId)),
        ),
        data: (project) {
          if (project == null) {
            return const AppErrorWidget(message: 'Project not found.');
          }
          return _buildProjectDetail(context, ref, project);
        },
      ),
    );
  }

  Widget _buildProjectDetail(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) {
    final status = project.projectStatus ?? ProjectStatus.draft;
    final isLoading = ref.watch(adminActionsControllerProvider).isLoading;
    final isTraining = project.isTrainingProject == 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProjectStatusChip(status: status),
              const Spacer(),
              if (project.createdAt != null)
                Text(
                  DateFormat('MMM d, yyyy').format(project.createdAt!),
                  style: AppTypography.labelMono.copyWith(
                    color: AppColors.outline,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            project.projectName.isEmpty
                ? 'Untitled Project'
                : project.projectName,
            style: AppTypography.headlineLg.copyWith(
              color: AppColors.onSurface,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          if (isTraining) ...[
            _buildDetailSection(
              title: 'TRAINING ASSIGNMENT',
              fields: [
                _DetailField(
                  'Assigned Student',
                  project.assignedDraughtsmanId ?? 'Unassigned',
                ),
                _DetailField(
                  'Training Module ID',
                  project.trainingModuleId ?? 'Not specified',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          _buildDetailSection(
            title: 'PROJECT INFORMATION',
            fields: [
              _DetailField(
                isTraining ? 'Supervisor / Creator ID' : 'Client ID',
                project.clientId,
              ),
              _DetailField('Project Name', project.projectName),
              _DetailField('Project Address', project.projectAddress),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          _buildDetailSection(
            title: 'DRAWING REQUIREMENTS',
            fields: [
              _DetailField('Drawing Name', project.drawingName),
              _DetailField(
                'Drawing Type',
                project.drawingTypeEnum?.displayName ?? project.drawingType,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          _buildDetailSection(
            title: 'DIMENSIONS & BUDGET',
            fields: [
              _DetailField(
                'Project Area',
                project.projectArea != null
                    ? '${project.projectArea} sq ft'
                    : 'Not specified',
              ),
              _DetailField(
                'Estimated Budget',
                project.estimatedAmount != null
                    ? '${project.estimatedAmount}'
                    : 'Not specified',
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),

          // DRAWING VERSIONS & EVALUATION
          if (status == ProjectStatus.inProgress ||
              status == ProjectStatus.underClientReview ||
              status == ProjectStatus.completed) ...[
            _buildDetailSection(
              title: 'DRAWING VERSIONS & SUBMISSIONS',
              fields: [],
              customContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ref
                      .watch(projectDrawingVersionsProvider(project.projectId))
                      .when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, _) => Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text(
                            'Error loading versions: $err',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                        data: (versions) {
                          if (versions.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: Text(
                                'No drawings submitted yet.',
                                style: TextStyle(color: AppColors.outline),
                              ),
                            );
                          }

                          final currentVersion = versions.first;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.description_outlined),
                                title: Text(
                                  'Version ${currentVersion.versionNumber} (Latest)',
                                  style: AppTypography.bodyMd.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Submitted: ${DateFormat('MMM d, yyyy HH:mm').format(currentVersion.createdAt ?? DateTime.now())}\nAuthor: ${currentVersion.uploadedBy}',
                                ),
                              ),
                              if (status == ProjectStatus.underClientReview)
                                Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) =>
                                                  EvaluationDialog(
                                                projectId: project.projectId,
                                                targetVersionId: currentVersion.id,
                                                initialResult: EvaluationResult.needsCorrection,
                                              ),
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.error,
                                            side: const BorderSide(
                                              color: AppColors.error,
                                            ),
                                          ),
                                          child: const Text('Request Correction'),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) =>
                                                  EvaluationDialog(
                                                projectId: project.projectId,
                                                targetVersionId: currentVersion.id,
                                                initialResult: EvaluationResult.approved,
                                              ),
                                            );
                                          },
                                          style: FilledButton.styleFrom(
                                            backgroundColor: AppColors.success,
                                          ),
                                          child: const Text('Approve Submission'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (versions.length > 1) ...[
                                const Divider(),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  child: Text(
                                    'Previous Versions',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.outline,
                                    ),
                                  ),
                                ),
                                ...versions.skip(1).map(
                                  (v) => ListTile(
                                    title: Text('Version ${v.versionNumber}'),
                                    subtitle: Text(
                                      DateFormat('MMM d, yyyy HH:mm').format(
                                        v.createdAt ?? DateTime.now(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // EVALUATIONS SECTION
            _buildDetailSection(
              title: 'EVALUATIONS',
              fields: [],
              customContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ref
                      .watch(projectEvaluationsProvider(project.projectId))
                      .when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, _) => Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text('Error: $err'),
                        ),
                        data: (evaluations) {
                          if (evaluations.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: Text(
                                'No evaluations yet.',
                                style: TextStyle(color: AppColors.outline),
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              children: evaluations
                                  .map((e) => EvaluationCard(evaluation: e))
                                  .toList(),
                            ),
                          );
                        },
                      ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // CORRECTIONS SECTION
            _buildDetailSection(
              title: 'CORRECTIONS HISTORY',
              fields: [],
              customContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ref
                      .watch(projectCorrectionsProvider(project.projectId))
                      .when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, _) => Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text('Error: $err'),
                        ),
                        data: (corrections) {
                          if (corrections.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: Text(
                                'No corrections requested.',
                                style: TextStyle(color: AppColors.outline),
                              ),
                            );
                          }
                          return Column(
                            children: corrections
                                .map(
                                  (c) => ListTile(
                                    title: Text(
                                      'Round ${c.roundNumber} - ${c.status.label}',
                                      style: AppTypography.bodyMd.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${c.description}\nRequested: ${DateFormat('MMM d, yyyy').format(c.createdAt)}',
                                    ),
                                    isThreeLine: true,
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],

          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (status == ProjectStatus.submitted) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleReject(context, ref, project),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _handleApprove(context, ref, project),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
            if (status == ProjectStatus.waitingAssignment) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _showAssignDialog(context, ref, project),
                  child: Text(isTraining ? 'Assign Student' : 'Assign Draughtsman'),
                ),
              ),
            ],
            if (status == ProjectStatus.inProgress ||
                status == ProjectStatus.waitingAcceptance) ...[
              Center(
                child: Column(
                  children: [
                    Text(
                      'Assigned to: ${project.assignedDraughtsmanId ?? 'Unknown'}',
                      style: AppTypography.bodyMd,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Status: ${status == ProjectStatus.waitingAcceptance ? 'Waiting Acceptance' : 'Accepted (In Progress)'}',
                      style: AppTypography.labelMono.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () =>
                            _showReassignDialog(context, ref, project),
                        child: Text(isTraining ? 'Reassign Student' : 'Reassign Draughtsman'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required List<_DetailField> fields,
    Widget? customContent,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusXl),
              ),
              border: Border(
                bottom: BorderSide(color: AppColors.outlineVariant, width: 0.5),
              ),
            ),
            child: Text(
              title,
              style: AppTypography.labelMono.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          if (customContent != null)
            customContent
          else
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: fields.map((field) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          field.label,
                          style: AppTypography.labelMono.copyWith(
                            color: AppColors.outline,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          field.value.isEmpty ? '—' : field.value,
                          style: AppTypography.bodyMd,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _handleApprove(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final success = await ref
        .read(adminActionsControllerProvider.notifier)
        .approveProject(project.projectId);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Project approved!')));
      context.pop();
    }
  }

  void _handleReject(BuildContext context, WidgetRef ref, Project project) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Project'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason for rejection'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(context); // close dialog
              final success = await ref
                  .read(adminActionsControllerProvider.notifier)
                  .rejectProject(projectId: project.projectId, reason: reason);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Project rejected')),
                );
                context.pop();
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context, WidgetRef ref, Project project) {
    final isTraining = project.isTrainingProject == 1;
    final targetRole = isTraining ? 'STUDENT' : 'DRAUGHTSMAN';
    final roleLabel = isTraining ? 'Student' : 'Draughtsman';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Assign $roleLabel'),
          content: SizedBox(
            width: double.maxFinite,
            child: Consumer(
              builder: (context, ref, child) {
                final usersAsync = ref.watch(draughtsmenListProvider);
                return usersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (users) {
                    final candidates =
                        users.where((u) => u.role == targetRole).toList();
                    if (candidates.isEmpty) {
                      return Text('No $roleLabel candidates found.');
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: candidates.length,
                      itemBuilder: (context, index) {
                        final u = candidates[index];
                        return ListTile(
                          title: Text(u.name),
                          subtitle: Text(u.email),
                          onTap: () async {
                            Navigator.pop(context);
                            final success = await ref
                                .read(adminActionsControllerProvider.notifier)
                                .assignDraughtsman(
                                  projectId: project.projectId,
                                  draughtsmanId: u.id,
                                );
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Assigned $roleLabel successfully!',
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showReassignDialog(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) {
    final isTraining = project.isTrainingProject == 1;
    final targetRole = isTraining ? 'STUDENT' : 'DRAUGHTSMAN';
    final roleLabel = isTraining ? 'Student' : 'Draughtsman';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reassign $roleLabel'),
          content: SizedBox(
            width: double.maxFinite,
            child: Consumer(
              builder: (context, ref, child) {
                final usersAsync = ref.watch(draughtsmenListProvider);
                return usersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (users) {
                    final candidates = users
                        .where(
                          (u) =>
                              u.role == targetRole &&
                              u.id != project.assignedDraughtsmanId,
                        )
                        .toList();
                    if (candidates.isEmpty) {
                      return Text('No other $roleLabel candidates found.');
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: candidates.length,
                      itemBuilder: (context, index) {
                        final u = candidates[index];
                        return ListTile(
                          title: Text(u.name),
                          subtitle: Text(u.email),
                          onTap: () async {
                            Navigator.pop(context);
                            final success = await ref
                                .read(adminActionsControllerProvider.notifier)
                                .reassignDraughtsman(
                                  projectId: project.projectId,
                                  draughtsmanId: u.id,
                                );
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Reassigned $roleLabel successfully!',
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _DetailField {
  final String label;
  final String value;
  const _DetailField(this.label, this.value);
}
