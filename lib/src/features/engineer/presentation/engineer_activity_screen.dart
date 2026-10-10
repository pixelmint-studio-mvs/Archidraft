import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:archi_draft/src/core/theme/app_colors.dart';
import 'package:archi_draft/src/core/theme/app_spacing.dart';
import 'package:archi_draft/src/core/theme/app_typography.dart';
import 'package:archi_draft/src/core/utils/file_category_labels.dart';
import 'package:archi_draft/src/shared/widgets/app_state_widgets.dart';

import 'package:archi_draft/src/features/projects/providers/project_providers.dart';

/// Screen displaying the Engineer-specific activity feed.
///
/// Shows activity logs strictly relevant to the authenticated Engineer and
/// the Engineer's owned projects. Internal studio/draughtsman rejections or
/// unrelated roles' actions are not displayed.
class EngineerActivityScreen extends ConsumerWidget {
  const EngineerActivityScreen({super.key});

  IconData _getActionIcon(String actionType) {
    switch (actionType) {
      case 'PROJECT_SUBMITTED':
        return Icons.send_rounded;
      case 'PROJECT_APPROVED':
        return Icons.verified_outlined;
      case 'PROJECT_REJECTED':
        return Icons.cancel_outlined;
      case 'DRAUGHTSMAN_ASSIGNED':
        return Icons.person_pin_outlined;
      case 'DRAWING_SUBMITTED':
        return Icons.draw_outlined;
      case 'CORRECTION_REQUESTED':
        return Icons.build_circle_outlined;
      case 'PROJECT_COMPLETED':
        return Icons.check_circle_outline;
      case 'FILE_UPLOADED':
        return Icons.cloud_upload_outlined;
      case 'FILE_DELETED':
        return Icons.delete_outline;
      default:
        return Icons.history_rounded;
    }
  }

  Color _getActionColor(String actionType) {
    switch (actionType) {
      case 'PROJECT_APPROVED':
      case 'PROJECT_COMPLETED':
        return AppColors.secondary;
      case 'PROJECT_REJECTED':
      case 'FILE_DELETED':
        return AppColors.error;
      case 'CORRECTION_REQUESTED':
        return Colors.orange[800] ?? Colors.orange;
      case 'PROJECT_SUBMITTED':
      case 'DRAWING_SUBMITTED':
        return AppColors.primary;
      default:
        return AppColors.outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(engineerActivityLogsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              // Header
              Text(
                'ARCHITECTURAL PORTAL • ACTIVITY',
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Activity Feed',
                style: AppTypography.headlineLgMobile.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Track real-time actions and lifecycle updates across your engineering projects.',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Activity List
              Expanded(
                child: activityAsync.when(
                  loading: () => const AppLoadingIndicator(message: 'Loading activities...'),
                  error: (e, _) => AppErrorWidget(
                    message: 'Failed to load activity logs.',
                    onRetry: () => ref.invalidate(engineerActivityLogsProvider),
                  ),
                  data: (activities) {
                    if (activities.isEmpty) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          margin: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                            border: Border.all(
                              color: AppColors.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.history_toggle_off_rounded,
                                size: 56,
                                color: AppColors.outlineVariant,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'No Activity Yet',
                                style: AppTypography.headlineLgMobile.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Activities will appear here as your projects are created, reviewed, and updated.',
                                style: AppTypography.bodyMd.copyWith(
                                  color: AppColors.outline,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(engineerActivityLogsProvider),
                      child: ListView.separated(
                        itemCount: activities.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final log = activities[index];
                          final icon = _getActionIcon(log.actionType);
                          final color = _getActionColor(log.actionType);

                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                              border: Border.all(
                                color: AppColors.outlineVariant.withValues(alpha: 0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.xs,
                              ),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: color, size: 20),
                              ),
                              title: Text(
                                sanitiseActivityDetails(log.details),
                                style: AppTypography.bodyMd.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '${log.projectName != null ? "${log.projectName} • " : ""}${log.actorRole} • ${DateFormat('MMM d, y • h:mm a').format(log.createdAt)}',
                                  style: AppTypography.labelMono.copyWith(
                                    fontSize: 11,
                                    color: AppColors.outline,
                                  ),
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: AppColors.outlineVariant,
                              ),
                              onTap: () {
                                if (log.projectId.isNotEmpty) {
                                  context.go('/engineer/projects/${log.projectId}');
                                }
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
