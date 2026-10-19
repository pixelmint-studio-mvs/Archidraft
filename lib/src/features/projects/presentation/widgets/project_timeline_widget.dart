import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:archi_draft/src/core/theme/app_colors.dart';
import 'package:archi_draft/src/core/theme/app_spacing.dart';
import 'package:archi_draft/src/core/theme/app_typography.dart';

/// Represents a single milestone in the project timeline.
class TimelineMilestone {
  /// Display label for the milestone (e.g., "Project Created").
  final String label;

  /// When this milestone occurred. Null if not yet reached.
  final DateTime? timestamp;

  /// Whether this milestone has been reached.
  final bool isReached;

  const TimelineMilestone({
    required this.label,
    this.timestamp,
    required this.isReached,
  });
}

/// A vertical timeline widget showing project milestones.
///
/// Each milestone is rendered as a dot on a vertical line, with a label and
/// optional timestamp. Reached milestones are filled; future ones are hollow.
///
/// Uses Stitch design tokens: [AppColors], [AppTypography], [AppSpacing].
/// No third-party timeline packages.
class ProjectTimelineWidget extends StatelessWidget {
  final List<TimelineMilestone> milestones;

  const ProjectTimelineWidget({super.key, required this.milestones});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(milestones.length, (index) {
        final milestone = milestones[index];
        final isLast = index == milestones.length - 1;

        return _TimelineEntry(
          milestone: milestone,
          isLast: isLast,
        );
      }),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final TimelineMilestone milestone;
  final bool isLast;

  const _TimelineEntry({
    required this.milestone,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isReached = milestone.isReached;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column (dot + line)
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Dot
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isReached
                        ? AppColors.secondary
                        : AppColors.surfaceContainerLowest,
                    border: Border.all(
                      color: isReached
                          ? AppColors.secondary
                          : AppColors.outlineVariant,
                      width: isReached ? 0 : 1.5,
                    ),
                  ),
                ),
                // Connecting line (skip for last item)
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: isReached
                          ? AppColors.secondary.withValues(alpha: 0.3)
                          : AppColors.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Content column
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone.label,
                    style: AppTypography.bodySm.copyWith(
                      color: isReached
                          ? AppColors.onSurface
                          : AppColors.outline,
                      fontWeight:
                          isReached ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (milestone.timestamp != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      DateFormat("MMM d, yyyy 'at' h:mm a")
                          .format(milestone.timestamp!),
                      style: AppTypography.labelMonoSm.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
