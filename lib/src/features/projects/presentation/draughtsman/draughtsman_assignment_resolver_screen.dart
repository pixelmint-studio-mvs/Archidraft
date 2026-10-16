import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../domain/assignment.dart';
import '../../providers/assignment_providers.dart';
import 'draughtsman_assignment_detail_screen.dart';

/// Safely resolves a Draughtsman assignment route without crashing on null extras
/// or treating arbitrary project IDs as proof of ownership.
class DraughtsmanAssignmentResolverScreen extends ConsumerWidget {
  final String assignmentId;
  final Assignment? initialAssignment;

  const DraughtsmanAssignmentResolverScreen({
    super.key,
    required this.assignmentId,
    this.initialAssignment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. If an Assignment domain object was safely passed via extra, navigate directly.
    if (initialAssignment != null) {
      return DraughtsmanAssignmentDetailScreen(
        assignment: initialAssignment!,
      );
    }

    // 2. Otherwise (deep link, browser reload, null extra), resolve the assignment
    // strictly from the authenticated Draughtsman's authorized assignments provider.
    final assignmentsAsync = ref.watch(draughtsmanAssignmentsProvider);

    if (assignmentsAsync.hasError) {
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
                context.go('/draughtsman/studio');
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
          onRetry: () => ref.refresh(draughtsmanAssignmentsProvider),
        ),
      );
    }

    return assignmentsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: AppLoadingIndicator(message: 'Locating draughtsman assignment...'),
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
                context.go('/draughtsman/studio');
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
          onRetry: () => ref.refresh(draughtsmanAssignmentsProvider),
        ),
      ),
      data: (assignments) {
        // Resolve only if the assignment belongs to the authenticated Draughtsman
        // and is returned by their authorized assignments list.
        final match = assignments.where(
          (a) => a.id == assignmentId || a.projectId == assignmentId,
        ).firstOrNull;

        if (match != null) {
          return DraughtsmanAssignmentDetailScreen(assignment: match);
        }

        return _buildNotFoundState(context);
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
              context.go('/draughtsman/studio');
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
                'The requested assignment was not found or is not linked to your draughtsman account.',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () => context.go('/draughtsman/studio'),
                icon: const Icon(Icons.folder_open_outlined, size: 18),
                label: const Text('View Draughtsman Studio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
