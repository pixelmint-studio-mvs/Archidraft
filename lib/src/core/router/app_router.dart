import 'package:go_router/go_router.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/login/presentation/login_screen.dart';

/// App router configuration for Archi Draft.
///
/// Phase 1 routes are integration validation only.
/// Allowed: / and /login (simple placeholders).
/// No login logic, authentication, or role-based redirects.
/// Ref: docs/04_development/DEVELOPMENT_ROADMAP.md (Phase 1)
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
  ],
);
