import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/home/presentation/home_screen.dart';

/// Provides the GoRouter configuration with authentication-aware redirects.
///
/// Listens to [authStateChangesProvider] to reactively redirect users:
/// - Not logged in → /login
/// - Logged in but email not verified → /verify-email
/// - Logged in and verified → / (home)
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _GoRouterAuthNotifier(ref),
    redirect: (context, state) {
      final user = authState.valueOrNull;
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

      // Logged in and verified — redirect away from auth screens
      if (isPublicRoute || currentPath == '/verify-email') {
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
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});

/// A [ChangeNotifier] that triggers GoRouter refresh when auth state changes.
///
/// This bridges Riverpod's reactive streams with GoRouter's
/// [refreshListenable] mechanism.
class _GoRouterAuthNotifier extends ChangeNotifier {
  _GoRouterAuthNotifier(this._ref) {
    _ref.listen(authStateChangesProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;
}
