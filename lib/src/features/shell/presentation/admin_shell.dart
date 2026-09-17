import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../auth/domain/user_profile.dart';
import 'widgets/app_bottom_nav.dart';
import 'widgets/responsive_scaffold.dart';

/// Navigation shell for the Admin role.
class AdminShell extends StatelessWidget {
  final Widget child;
  final UserProfile profile;

  const AdminShell({
    super.key,
    required this.child,
    required this.profile,
  });

  static const _destinations = [
    NavDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      route: '/admin/dashboard',
    ),
    NavDestination(
      label: 'Projects',
      icon: Icons.folder_outlined,
      route: '/admin/projects',
    ),
    NavDestination(
      label: 'Assignments',
      icon: Icons.assignment_outlined,
      route: '/admin/assignments',
    ),
    NavDestination(
      label: 'Users',
      icon: Icons.people_outline_rounded,
      route: '/admin/users',
    ),
    NavDestination(
      label: 'System',
      icon: Icons.settings_system_daydream_outlined,
      route: '/admin/system',
    ),
  ];

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/admin/dashboard')) return 0;
    if (location.startsWith('/admin/projects')) return 1;
    if (location.startsWith('/admin/assignments')) return 2;
    if (location.startsWith('/admin/users')) return 3;
    if (location.startsWith('/admin/system')) return 4;
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
