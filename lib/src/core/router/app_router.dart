import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/landing_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/profile/domain/user_role.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/providers/profile_providers.dart';
import '../../features/projects/presentation/client_projects_screen.dart';
import '../../features/projects/presentation/financials_screen.dart';
import '../../features/projects/presentation/project_detail_screen.dart';
import '../../features/projects/presentation/project_form_screen.dart';
import '../../features/projects/presentation/admin/admin_dashboard_screen.dart';
import '../../features/projects/presentation/admin/admin_project_detail_screen.dart';
import '../../features/projects/presentation/admin/admin_projects_screen.dart';
import '../../features/projects/presentation/admin/admin_assignments_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/projects/presentation/draughtsman/draughtsman_studio_screen.dart';
import '../../features/projects/presentation/draughtsman/draughtsman_assignment_detail_screen.dart';
import '../../features/projects/presentation/draughtsman/draughtsman_workspace_screen.dart';
import '../../features/projects/domain/assignment.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/shell/presentation/placeholders/placeholder_screen.dart';
import '../../features/training/presentation/student_training_screen.dart';
import '../../features/training/presentation/training_module_detail_screen.dart';
import '../../features/training/presentation/student_drawings_screen.dart';
import '../../features/training/presentation/student_insights_screen.dart';

/// Provides the GoRouter configuration with authentication-aware redirects.
///
/// Listens to [authStateChangesProvider] and [userProfileProvider] to reactively redirect users:
/// - Not logged in → /login
/// - Logged in but email not verified → /verify-email
/// - Logged in and verified → Role-specific dashboard
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/landing',
    refreshListenable: _GoRouterAuthNotifier(ref),
    redirect: (context, state) {
      final user = authState.value;
      final isLoggedIn = user != null;
      final isEmailVerified = user?.emailVerified ?? false;

      final currentPath = state.matchedLocation;

      // Public routes that don't require authentication
      const publicPaths = [
        '/landing',
        '/role-selection',
        '/login',
        '/register',
        '/forgot-password',
      ];
      final isPublicRoute = publicPaths.contains(currentPath);

      // Not logged in
      if (!isLoggedIn) {
        // Already on a public route — stay there
        if (isPublicRoute) return null;
        // Trying to access protected route — redirect to landing
        return '/landing';
      }

      // 2. Verified User Enforcement
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
      if (isPublicRoute ||
          currentPath == '/verify-email' ||
          currentPath == '/') {
        if (role == UserRole.client) return '/client/projects';
        if (role == UserRole.draughtsman) return '/draughtsman/studio';
        if (role == UserRole.admin) return '/admin/dashboard';
        if (role == UserRole.student) return '/student/dashboard';
        // If role is null or unknown, stay on root to show error state in AppShell
        return '/';
      }

      // Enforce role-based access restrictions
      if (currentPath.startsWith('/client') && role != UserRole.client) {
        return '/'; // Redirect unauthorized access
      }
      if (currentPath.startsWith('/draughtsman') &&
          role != UserRole.draughtsman) {
        return '/';
      }
      if (currentPath.startsWith('/admin') && role != UserRole.admin) {
        return '/';
      }
      if (currentPath.startsWith('/student') && role != UserRole.student) {
        return '/';
      }

      // Allow access
      return null;
    },
    routes: [
      // ── PUBLIC ROUTES ──
      GoRoute(
        path: '/landing',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final role = state.extra as String?;
          return LoginScreen(preselectedRole: role);
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final role = state.extra as String?;
          return RegisterScreen(preselectedRole: role);
        },
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
          // ── COMMON ROUTES ──
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          // ── CLIENT ROUTES ──
          GoRoute(
            path: '/client/projects',
            builder: (context, state) => const ClientProjectsScreen(),
          ),
          GoRoute(
            path: '/client/projects/new',
            builder: (context, state) => const ProjectFormScreen(),
          ),
          GoRoute(
            path: '/client/projects/:projectId',
            builder: (context, state) {
              final projectId = state.pathParameters['projectId']!;
              return ProjectDetailScreen(projectId: projectId);
            },
          ),
          GoRoute(
            path: '/client/projects/:projectId/financials',
            builder: (context, state) {
              final projectId = state.pathParameters['projectId']!;
              return FinancialsScreen(projectId: projectId);
            },
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
            builder: (context, state) => const DraughtsmanStudioScreen(),
          ),
          GoRoute(
            path: '/draughtsman/assignments/:assignmentId',
            builder: (context, state) {
              final assignment = state.extra as Assignment;
              return DraughtsmanAssignmentDetailScreen(assignment: assignment);
            },
          ),
          GoRoute(
            path: '/draughtsman/workspace/:projectId',
            builder: (context, state) {
              final projectId = state.pathParameters['projectId']!;
              return DraughtsmanWorkspaceScreen(projectId: projectId);
            },
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
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/projects',
            builder: (context, state) => const AdminProjectsScreen(),
          ),
          GoRoute(
            path: '/admin/assignments',
            builder: (context, state) => const AdminAssignmentsScreen(),
          ),
          GoRoute(
            path: '/admin/projects/:projectId',
            builder: (context, state) {
              final projectId = state.pathParameters['projectId']!;
              return AdminProjectDetailScreen(projectId: projectId);
            },
          ),
          GoRoute(
            path: '/admin/projects/:projectId/financials',
            builder: (context, state) {
              final projectId = state.pathParameters['projectId']!;
              return FinancialsScreen(projectId: projectId);
            },
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

          // ── STUDENT ROUTES ──
          GoRoute(
            path: '/student/dashboard',
            builder: (context, state) => const StudentTrainingScreen(),
          ),
          GoRoute(
            path: '/student/training/:moduleId',
            builder: (context, state) {
              final moduleId = state.pathParameters['moduleId']!;
              return TrainingModuleDetailScreen(moduleId: moduleId);
            },
          ),
          GoRoute(
            path: '/student/assignments/:assignmentId',
            builder: (context, state) {
              final assignment = state.extra as Assignment;
              return DraughtsmanAssignmentDetailScreen(assignment: assignment);
            },
          ),
          GoRoute(
            path: '/student/projects/:projectId',
            builder: (context, state) {
              final projectId = state.pathParameters['projectId']!;
              return ProjectDetailScreen(projectId: projectId);
            },
          ),
          GoRoute(
            path: '/student/drawings',
            builder: (context, state) => const StudentDrawingsScreen(),
          ),
          GoRoute(
            path: '/student/insights',
            builder: (context, state) => const StudentInsightsScreen(),
          ),
          GoRoute(
            path: '/student/profile',
            builder: (context, state) => const ProfileScreen(),
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
