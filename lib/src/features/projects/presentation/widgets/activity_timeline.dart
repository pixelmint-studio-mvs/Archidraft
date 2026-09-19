import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/project_providers.dart';

class ActivityTimeline extends ConsumerWidget {
  final String projectId;

  const ActivityTimeline({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(projectActivityLogsProvider(projectId));

    return activityAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return Text('No activity yet.', style: AppTypography.bodyMd);
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final isLast = index == logs.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        margin: const EdgeInsets.only(top: 4, bottom: 4),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: AppColors.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.details,
                            style: AppTypography.bodyMd.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${log.actorRole} • ${DateFormat('MMM d, y h:mm a').format(log.createdAt)}',
                            style: AppTypography.labelMono.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Text(
        'Error loading activity: $err',
        style: AppTypography.bodyMd.copyWith(color: AppColors.error),
      ),
    );
  }
}
