import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../../profile/domain/user_role.dart';
import '../../profile/providers/profile_providers.dart';
import 'admin_shell.dart';
import 'client_shell.dart';
import 'draughtsman_shell.dart';

/// AppShell determines which role-specific shell to display based on
/// the currently authenticated user's role.
class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final role = ref.watch(currentUserRoleProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: AppLoadingIndicator(message: 'Loading application...'),
      ),
      error: (error, stack) => Scaffold(
        body: AppErrorWidget(
          message: 'Failed to load application state.',
          onRetry: () => ref.refresh(userProfileProvider),
        ),
      ),
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            body: AppEmptyState(
              title: 'Profile Missing',
              subtitle: 'Could not load your user profile.\nPlease try logging out and creating a new account.',
              action: FilledButton.icon(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ),
          );
        }

        switch (role) {
          case UserRole.client:
            return ClientShell(profile: profile, child: child);
          case UserRole.draughtsman:
            return DraughtsmanShell(profile: profile, child: child);
          case UserRole.admin:
            return AdminShell(profile: profile, child: child);
          case null:
            return const Scaffold(
              body: AppErrorWidget(
                message: 'Invalid user role configuration.',
              ),
            );
        }
      },
    );
  }
}
