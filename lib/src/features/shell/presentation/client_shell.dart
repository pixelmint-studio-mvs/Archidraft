import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../auth/domain/user_profile.dart';
import 'widgets/app_bottom_nav.dart';
import 'widgets/responsive_scaffold.dart';

/// Navigation shell for the Client role.
class ClientShell extends StatelessWidget {
  final Widget child;
  final UserProfile profile;

  const ClientShell({
    super.key,
    required this.child,
    required this.profile,
  });

  static const _destinations = [
    NavDestination(
      label: 'Projects',
      icon: Icons.layers_outlined,
      route: '/client/projects',
    ),
    NavDestination(
      label: 'Activity',
      icon: Icons.history_rounded,
      route: '/client/activity',
    ),
    NavDestination(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      route: '/client/profile',
    ),
  ];

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/client/projects')) return 0;
    if (location.startsWith('/client/activity')) return 1;
    if (location.startsWith('/client/profile')) return 2;
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
