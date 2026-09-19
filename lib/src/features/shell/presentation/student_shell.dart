import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/domain/user_profile.dart';
import 'widgets/app_bottom_nav.dart';
import 'widgets/responsive_scaffold.dart';

/// Navigation shell for the Student role.
///
/// Group 1: Provides Dashboard + Profile navigation.
/// Groups 2-5 will extend this with Training, Projects, etc.
class StudentShell extends StatelessWidget {
  final Widget child;
  final UserProfile profile;

  const StudentShell({super.key, required this.child, required this.profile});

  static const _destinations = [
    NavDestination(
      label: 'Studio',
      icon: Icons.architecture,
      route: '/student/dashboard',
    ),
    NavDestination(
      label: 'Drawings',
      icon: Icons.layers_outlined,
      route: '/student/drawings',
    ),
    NavDestination(
      label: 'Insights',
      icon: Icons.analytics_outlined,
      route: '/student/insights',
    ),
    NavDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      route: '/student/profile',
    ),
  ];

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/student/dashboard')) return 0;
    if (location.startsWith('/student/drawings')) return 1;
    if (location.startsWith('/student/insights')) return 2;
    if (location.startsWith('/student/profile')) return 3;
    return 0;
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
