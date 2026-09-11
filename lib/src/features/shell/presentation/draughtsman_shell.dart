import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../auth/domain/user_profile.dart';
import 'widgets/app_bottom_nav.dart';
import 'widgets/responsive_scaffold.dart';

/// Navigation shell for the Draughtsman role.
class DraughtsmanShell extends StatelessWidget {
  final Widget child;
  final UserProfile profile;

  const DraughtsmanShell({
    super.key,
    required this.child,
    required this.profile,
  });

  static const _destinations = [
    NavDestination(
      label: 'Studio',
      icon: Icons.grid_view_rounded,
      route: '/draughtsman/studio',
    ),
    NavDestination(
      label: 'Drawings',
      icon: Icons.layers_outlined,
      route: '/draughtsman/drawings',
    ),
    NavDestination(
      label: 'Insights',
      icon: Icons.analytics_outlined,
      route: '/draughtsman/insights',
    ),
    NavDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      route: '/draughtsman/profile',
    ),
  ];

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/draughtsman/studio')) return 0;
    if (location.startsWith('/draughtsman/drawings')) return 1;
    if (location.startsWith('/draughtsman/insights')) return 2;
    if (location.startsWith('/draughtsman/profile')) return 3;
    return 0; // Default
  }

  void _onDestinationSelected(BuildContext context, int index) {
    context.go(_destinations[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return ResponsiveScaffold(
      body: child,
      profile: profile,
      selectedIndex: selectedIndex,
      destinations: _destinations,
      onDestinationSelected: (index) => _onDestinationSelected(context, index),
    );
  }
}
