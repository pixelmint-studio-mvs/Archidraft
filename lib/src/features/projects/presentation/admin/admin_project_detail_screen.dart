import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../domain/project.dart';
import '../../domain/project_status.dart';
import '../../providers/admin_providers.dart';
import '../../providers/project_providers.dart';
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
            icon: const Icon(Icons.attach_money),
            tooltip: 'Financials',
            onPressed: () => context.push('/admin/projects/$projectId/financials'),
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

          _buildDetailSection(
            title: 'PROJECT INFORMATION',
            fields: [
              _DetailField('Client ID', project.clientId),
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
                  child: const Text('Assign Draughtsman'),
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
                        child: const Text('Reassign Draughtsman'),
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign Draughtsman'),
          content: SizedBox(
            width: double.maxFinite,
            child: Consumer(
              builder: (context, ref, child) {
                final draughtsmenAsync = ref.watch(draughtsmenListProvider);
                return draughtsmenAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (draughtsmen) {
                    if (draughtsmen.isEmpty)
                      return const Text('No draughtsmen found.');
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: draughtsmen.length,
                      itemBuilder: (context, index) {
                        final d = draughtsmen[index];
                        return ListTile(
                          title: Text(d.name),
                          subtitle: Text(d.email),
                          onTap: () async {
                            Navigator.pop(context);
                            final success = await ref
                                .read(adminActionsControllerProvider.notifier)
                                .assignDraughtsman(
                                  projectId: project.projectId,
                                  draughtsmanId: d.id,
                                );
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Assigned!')),
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reassign Draughtsman'),
          content: SizedBox(
            width: double.maxFinite,
            child: Consumer(
              builder: (context, ref, child) {
                final draughtsmenAsync = ref.watch(draughtsmenListProvider);
                return draughtsmenAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (draughtsmen) {
                    if (draughtsmen.isEmpty)
                      return const Text('No draughtsmen found.');
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: draughtsmen.length,
                      itemBuilder: (context, index) {
                        final d = draughtsmen[index];
                        if (d.id == project.assignedDraughtsmanId)
                          return const SizedBox.shrink();
                        return ListTile(
                          title: Text(d.name),
                          subtitle: Text(d.email),
                          onTap: () async {
                            Navigator.pop(context);
                            final success = await ref
                                .read(adminActionsControllerProvider.notifier)
                                .reassignDraughtsman(
                                  projectId: project.projectId,
                                  draughtsmanId: d.id,
                                );
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Reassigned!')),
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
