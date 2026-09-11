import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/profile/domain/user_role.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/providers/profile_providers.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/shell/presentation/placeholders/placeholder_screen.dart';

/// Provides the GoRouter configuration with authentication-aware redirects.
///
/// Listens to [authStateChangesProvider] and [userProfileProvider] to reactively redirect users:
/// - Not logged in → /login
/// - Logged in but email not verified → /verify-email
/// - Logged in and verified → Role-specific dashboard
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _GoRouterAuthNotifier(ref),
    redirect: (context, state) {
      final user = authState.value;
      final isLoggedIn = user != null;
      final isEmailVerified = user?.emailVerified ?? false;

      final currentPath = state.matchedLocation;

      // Public routes that don't require authentication
      const publicPaths = ['/login', '/register', '/forgot-password'];
      final isPublicRoute = publicPaths.contains(currentPath);

      // Not logged in
      if (!isLoggedIn) {
        // Already on a public route — stay there
        if (isPublicRoute) return null;
        // Trying to access protected route — redirect to login
        return '/login';
      }

      // Logged in but email not verified
      if (!isEmailVerified) {
        if (currentPath == '/verify-email') return null;
        return '/verify-email';
      }

      // For logged in & verified users, wait until profile is loaded
      final profileAsync = ref.read(userProfileProvider);
      if (profileAsync.isLoading) {
        return null; // Wait for profile to load
      }

      final role = ref.read(currentUserRoleProvider);

      // Redirect from public routes, verify-email, or root to the role dashboard
      if (isPublicRoute || currentPath == '/verify-email' || currentPath == '/') {
        if (role == UserRole.client) return '/client/projects';
        if (role == UserRole.draughtsman) return '/draughtsman/studio';
        if (role == UserRole.admin) return '/admin/dashboard';
        // If role is null or unknown, stay on root to show error state in AppShell
        return '/';
      }

      // Enforce role-based access restrictions
      if (currentPath.startsWith('/client') && role != UserRole.client) {
        return '/'; // Redirect unauthorized access
      }
      if (currentPath.startsWith('/draughtsman') && role != UserRole.draughtsman) {
        return '/'; 
      }
      if (currentPath.startsWith('/admin') && role != UserRole.admin) {
        return '/'; 
      }

      // Allow access
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      // Root route for initial loading or fallback error display
      GoRoute(
        path: '/',
        builder: (context, state) => const AppShell(child: SizedBox.shrink()),
      ),
      // Authenticated Shell Routes
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // ── CLIENT ROUTES ──
          GoRoute(
            path: '/client/projects',
            builder: (context, state) => const PlaceholderScreen(
              title: 'Client Projects',
              description: 'Manage and review your project submissions.',
              icon: Icons.layers_outlined,
            ),
          ),
          GoRoute(
            path: '/client/activity',
            builder: (context, state) => const PlaceholderScreen(
              title: 'Activity',
              description: 'View recent project updates and notifications.',
              icon: Icons.history_rounded,
            ),
          ),
          GoRoute(
            path: '/client/profile',
            builder: (context, state) => const ProfileScreen(),
          ),

          // ── DRAUGHTSMAN ROUTES ──
          GoRoute(
            path: '/draughtsman/studio',
            builder: (context, state) => const PlaceholderScreen(
              title: 'Draughtsman Studio',
              description: 'Your workspace for active drafting tasks.',
              icon: Icons.grid_view_rounded,
            ),
          ),
          GoRoute(
            path: '/draughtsman/drawings',
            builder: (context, state) => const PlaceholderScreen(
              title: 'Drawings Library',
              description: 'Access all your past and current drawings.',
              icon: Icons.layers_outlined,
            ),
          ),
          GoRoute(
            path: '/draughtsman/insights',
            builder: (context, state) => const PlaceholderScreen(
              title: 'Insights',
              description: 'View your performance and earnings analytics.',
              icon: Icons.analytics_outlined,
            ),
          ),
          GoRoute(
            path: '/draughtsman/profile',
            builder: (context, state) => const ProfileScreen(),
          ),

          // ── ADMIN ROUTES ──
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) => const PlaceholderScreen(
              title: 'Admin Dashboard',
              description: 'Platform overview and metrics.',
              icon: Icons.dashboard_outlined,
            ),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const PlaceholderScreen(
              title: 'User Management',
              description: 'Manage clients and draughtsmen accounts.',
              icon: Icons.people_outline_rounded,
            ),
          ),
          GoRoute(
            path: '/admin/system',
            builder: (context, state) => const PlaceholderScreen(
              title: 'System Settings',
              description: 'Configure platform-wide settings.',
              icon: Icons.settings_system_daydream_outlined,
            ),
          ),
        ],
      ),
    ],
  );
});

/// A [ChangeNotifier] that triggers GoRouter refresh when auth state or profile changes.
class _GoRouterAuthNotifier extends ChangeNotifier {
  _GoRouterAuthNotifier(this._ref) {
    _ref.listen(authStateChangesProvider, (_, _) {
      notifyListeners();
    });
    _ref.listen(userProfileProvider, (_, _) {
      notifyListeners();
    });
  }

  final Ref _ref;
}
