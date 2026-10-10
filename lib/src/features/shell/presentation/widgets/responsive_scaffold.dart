import 'package:flutter/material.dart';
import '../../../../core/constants/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/domain/user_profile.dart';
import 'app_bottom_nav.dart';
import 'app_nav_rail.dart';
import 'app_top_bar.dart';

/// Responsive scaffold that adapts navigation based on screen width.
///
/// Implements the Stitch blueprint background and responsive layout structure.
class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final List<NavDestination> destinations;
  final ValueChanged<int> onDestinationSelected;
  final UserProfile? profile;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = AppBreakpoints.isMobile(constraints.maxWidth);
        final isTablet = AppBreakpoints.isTablet(constraints.maxWidth);

        // Blueprint Grid Background Pattern (implemented via CustomPaint)
        final background = CustomPaint(
          painter: _BlueprintPainter(),
          child: Container(),
        );

        if (isMobile) {
          return Scaffold(
            extendBody: true,
            extendBodyBehindAppBar: true,
            backgroundColor: AppColors.background,
            appBar: AppTopBar(profile: profile),
            body: Stack(
              children: [
                background,
                SafeArea(
                  bottom: false,
                  child: body,
                ),
              ],
            ),
            bottomNavigationBar: AppBottomNav(
              selectedIndex: selectedIndex,
              destinations: destinations,
              onDestinationSelected: onDestinationSelected,
            ),
          );
        }

        if (isTablet) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Stack(
              children: [
                background,
                Row(
                  children: [
                    AppNavRail(
                      selectedIndex: selectedIndex,
                      destinations: destinations,
                      onDestinationSelected: onDestinationSelected,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          AppTopBar(profile: profile),
                          Expanded(child: body),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // Desktop
        // On desktop, we put navigation in the TopBar matching REFERENCE DESIGN
        final desktopNavItems = List.generate(destinations.length, (index) {
          final dest = destinations[index];
          final isSelected = index == selectedIndex;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              onTap: () => onDestinationSelected(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      dest.icon,
                      size: 18,
                      color: isSelected ? AppColors.secondary : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dest.label,
                      style: AppTypography.labelMono.copyWith(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.secondary : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });

        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: AppColors.background,
          appBar: AppTopBar(
            profile: profile,
            navigationItems: desktopNavItems,
          ),
          body: Stack(
            children: [
              background,
              SafeArea(
                bottom: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppBreakpoints.maxContentWidth,
                    ),
                    child: body,
                  ),
                ),
              ),
              // Reference Design System Signature Footer
              const Positioned(
                bottom: 16,
                right: AppSpacing.marginDesktop,
                child: Text(
                  'UI/UX Design & Product Experience crafted by PixelMint Studio MVS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BlueprintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    const double step = 40.0; // AppSpacing.blueprintUnit

    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
