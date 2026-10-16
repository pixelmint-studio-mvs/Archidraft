import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../../training/providers/training_providers.dart';
import '../../domain/assignment.dart';
import '../../providers/project_providers.dart';
import 'student_project_workspace_screen.dart';

/// Safely resolves a Student assignment route without crashing on null extras
/// or leaking Draughtsman interfaces.
class StudentAssignmentResolverScreen extends ConsumerWidget {
  final String assignmentId;
  final Assignment? initialAssignment;

  const StudentAssignmentResolverScreen({
    super.key,
    required this.assignmentId,
    this.initialAssignment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. If an Assignment domain object was passed via extra, navigate directly
    // to the student workspace for that assignment's project.
    if (initialAssignment != null) {
      return StudentProjectWorkspaceScreen(
        projectId: initialAssignment!.projectId,
      );
    }

    // 2. Otherwise (deep link, browser reload, null extra), resolve the project
    // from the student's assigned projects or by project ID.
    final assignmentsAsync = ref.watch(studentAssignmentsProvider);

    return assignmentsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: AppLoadingIndicator(message: 'Locating student assignment...'),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/student/projects');
              }
            },
          ),
          title: Text(
            'Assignment',
            style: AppTypography.headlineSmMobile.copyWith(
              color: AppColors.onBackground,
            ),
          ),
        ),
        body: AppErrorWidget(
          message: 'Failed to load assignment.',
          onRetry: () => ref.refresh(studentAssignmentsProvider),
        ),
      ),
      data: (projects) {
        // Check if assignmentId matches project ID or currentAssignmentId
        final match = projects.where(
          (p) =>
              p.projectId == assignmentId ||
              p.currentAssignmentId == assignmentId,
        ).firstOrNull;

        if (match != null) {
          return StudentProjectWorkspaceScreen(projectId: match.projectId);
        }

        // Check if assignmentId directly matches an accessible training project
        final projectAsync = ref.watch(projectProvider(assignmentId));
        return projectAsync.when(
          loading: () => const Scaffold(
            backgroundColor: AppColors.background,
            body: AppLoadingIndicator(message: 'Loading project workspace...'),
          ),
          error: (e, st) => _buildNotFoundState(context),
          data: (project) {
            if (project != null &&
                (project.isTrainingProject == 1 ||
                    project.trainingModuleId != null)) {
              return StudentProjectWorkspaceScreen(
                projectId: project.projectId,
              );
            }
            return _buildNotFoundState(context);
          },
        );
      },
    );
  }

  Widget _buildNotFoundState(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/student/projects');
            }
          },
        ),
        title: Text(
          'Assignment Not Found',
          style: AppTypography.headlineSmMobile.copyWith(
            color: AppColors.onBackground,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.assignment_late_outlined,
                size: 56,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Assignment Unavailable',
                style: AppTypography.headlineSmMobile.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'The requested assignment was not found or is not linked to your student account.',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () => context.go('/student/projects'),
                icon: const Icon(Icons.folder_open_outlined, size: 18),
                label: const Text('View My Projects'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
