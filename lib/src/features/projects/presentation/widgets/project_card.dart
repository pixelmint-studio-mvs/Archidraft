import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:archi_draft/src/core/theme/app_colors.dart';
import 'package:archi_draft/src/core/theme/app_spacing.dart';
import 'package:archi_draft/src/core/theme/app_typography.dart';
import '../../domain/project.dart';
import '../../domain/project_status.dart';
import 'project_status_chip.dart';

/// A styled card for displaying a project in the client's project list.
///
/// Stitch design reference: White card, 1px outline border, 20-24px radius,
/// generous padding. Technical precision with monospace labels.
class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;

  const ProjectCard({super.key, required this.project, this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = project.projectStatus ?? ProjectStatus.draft;
    final drawingType = project.drawingTypeEnum;
    final createdAt = project.createdAt;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.outlineVariant, width: 1),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: status chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ProjectStatusChip(status: status),
                if (createdAt != null)
                  Text(
                    DateFormat('MMM d, yyyy').format(createdAt),
                    style: AppTypography.labelMono.copyWith(
                      color: AppColors.outline,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Project name
            Text(
              project.projectName.isEmpty
                  ? 'Untitled Project'
                  : project.projectName,
              style: AppTypography.headlineLgMobile.copyWith(
                color: AppColors.onSurface,
                fontSize: 18,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Drawing type label
            if (drawingType != null)
              Text(
                drawingType.displayName,
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),

            const SizedBox(height: AppSpacing.md),

            // Project address
            if (project.projectAddress.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.outline,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      project.projectAddress,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
