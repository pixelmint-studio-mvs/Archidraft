import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'app_bottom_nav.dart';

/// Navigation Rail for Tablet layouts.
class AppNavRail extends StatelessWidget {
  final int selectedIndex;
  final List<NavDestination> destinations;
  final ValueChanged<int> onDestinationSelected;

  const AppNavRail({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        border: Border(
          right: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xxl),
            // Brand Icon
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(
                Icons.architecture_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // Destinations
            Expanded(
              child: ListView.separated(
                itemCount: destinations.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.xl),
                itemBuilder: (context, index) {
                  final dest = destinations[index];
                  final isSelected = index == selectedIndex;

                  return InkWell(
                    onTap: () => onDestinationSelected(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.secondaryFixed.withValues(
                                      alpha: 0.3,
                                    )
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                            ),
                            child: Icon(
                              dest.icon,
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.outline,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dest.label,
                            style: AppTypography.labelMonoSm.copyWith(
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.outline,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
