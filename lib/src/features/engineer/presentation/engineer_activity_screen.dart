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
/// the Engineer's owned projects. Internal studio/draughtsman rejections,
/// internal QC notes, and unrelated roles' actions are not displayed.
class EngineerActivityScreen extends ConsumerStatefulWidget {
  const EngineerActivityScreen({super.key});

  @override
  ConsumerState<EngineerActivityScreen> createState() => _EngineerActivityScreenState();
}

class _EngineerActivityScreenState extends ConsumerState<EngineerActivityScreen> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      ref.invalidate(engineerActivityLogsProvider);
      await ref.read(engineerActivityLogsProvider.future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity feed refreshed'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh activity: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

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
      case 'ASSIGNMENT_ACCEPTED':
        return Icons.how_to_reg_outlined;
      case 'DRAWING_SUBMITTED':
      case 'ADMIN_DRAWING_APPROVED':
        return Icons.draw_outlined;
      case 'CORRECTION_REQUESTED':
        return Icons.build_circle_outlined;
      case 'CORRECTION_STARTED':
        return Icons.engineering_outlined;
      case 'CORRECTION_RESOLVED':
        return Icons.task_alt_outlined;
      case 'PROJECT_COMPLETED':
        return Icons.check_circle_outline;
      case 'PROJECT_CANCELLED':
        return Icons.cancel_presentation_outlined;
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
      case 'CORRECTION_RESOLVED':
      case 'ADMIN_DRAWING_APPROVED':
        return AppColors.secondary;
      case 'PROJECT_REJECTED':
      case 'PROJECT_CANCELLED':
      case 'FILE_DELETED':
        return AppColors.error;
      case 'CORRECTION_REQUESTED':
      case 'CORRECTION_STARTED':
        return Colors.orange[800] ?? Colors.orange;
      case 'PROJECT_SUBMITTED':
      case 'DRAWING_SUBMITTED':
      case 'ASSIGNMENT_ACCEPTED':
      case 'DRAUGHTSMAN_ASSIGNED':
        return AppColors.primary;
      default:
        return AppColors.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Header with Refresh Action Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _isRefreshing ? null : _handleRefresh,
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      _isRefreshing ? 'Syncing...' : 'Sync Feed',
                      style: AppTypography.buttonText.copyWith(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Activity List
              Expanded(
                child: activityAsync.when(
                  loading: () => const AppLoadingIndicator(message: 'Loading activities...'),
                  error: (e, _) => AppErrorWidget(
                    message: 'Failed to load activity logs.',
                    onRetry: _handleRefresh,
                  ),
                  data: (activities) {
                    if (activities.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: LayoutBuilder(
                          builder: (context, constraints) => SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: constraints.maxHeight),
                              child: Center(
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
                                      const Icon(
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
                                      const SizedBox(height: AppSpacing.md),
                                      OutlinedButton.icon(
                                        onPressed: _handleRefresh,
                                        icon: const Icon(Icons.refresh, size: 16),
                                        label: const Text('Refresh Feed'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _handleRefresh,
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
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.sm,
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
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (log.projectName != null && log.projectName!.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        margin: const EdgeInsets.only(bottom: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: AppColors.primary.withValues(alpha: 0.2),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.apartment_rounded,
                                              size: 12,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                log.projectName!,
                                                style: AppTypography.labelMonoSm.copyWith(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    Text(
                                      sanitiseActivityDetails(log.details),
                                      style: AppTypography.bodyMd.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    '${log.actorRole} • ${log.createdAt != null ? DateFormat('MMM d, y • h:mm a').format(log.createdAt!) : 'Date unavailable'}',
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
