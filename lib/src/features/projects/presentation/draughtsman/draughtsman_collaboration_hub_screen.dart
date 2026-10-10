import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../providers/assignment_providers.dart';
import '../../providers/project_providers.dart';
import 'collaboration_hub_view.dart';

/// Standalone Collaboration Hub screen for Panel 6.
///
/// Faithfully reproduces the standalone layout from:
/// - REFERENCE DESIGN/collaboration_hub/code.html
/// - REFERENCE DESIGN/collaboration_hub/screen.png
///
/// Features:
/// - Top header with DRAUGHTSMAN branding, desktop nav tabs
/// - "Live Workspace" chip navigating back to the active workspace
/// - Blueprint grid matrix background
/// - Centered technical panel container with exact reference styling
class DraughtsmanCollaborationHubScreen extends ConsumerWidget {
  final String assignmentId;

  const DraughtsmanCollaborationHubScreen({
    super.key,
    required this.assignmentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentAsync = ref.watch(assignmentProvider(assignmentId));

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9FB), // reference background
      body: assignmentAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Loading collaboration session...'),
        error: (err, _) => AppErrorWidget(
          message: 'Failed to load assignment details: $err',
          onRetry: () => ref.invalidate(assignmentProvider(assignmentId)),
        ),
        data: (assignment) {
          final projectAsync = ref.watch(projectProvider(assignment.projectId));

          return projectAsync.when(
            loading: () => const AppLoadingIndicator(message: 'Connecting to project thread...'),
            error: (err, _) => AppErrorWidget(
              message: 'Failed to load project details: $err',
              onRetry: () => ref.invalidate(projectProvider(assignment.projectId)),
            ),
            data: (project) {
              if (project == null) {
                return const AppErrorWidget(
                  message: 'Project details not found.',
                );
              }

              return Stack(
                children: [
                  // Blueprint Grid Background Pattern
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BlueprintGridPainter(),
                    ),
                  ),

                  // Main Page Column
                  Column(
                    children: [
                      // Top App Bar
                      _buildTopAppBar(context, ref, assignment.id),

                      // Main Content Area
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1280),
                            child: CollaborationHubView(
                              projectId: assignment.projectId,
                              project: project,
                              isEmbedded: false,
                              assignmentId: assignment.id,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context, WidgetRef ref, String currentAssignmentId) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.marginDesktop : AppSpacing.marginMobile,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        border: const Border(
          bottom: BorderSide(
            color: Color(0x4DC5C6CD),
            width: 0.5,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Branding
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
                tooltip: 'Back to Workspace',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/draughtsman/workspace/$currentAssignmentId');
                  }
                },
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.architecture_rounded,
                size: 24,
                color: Color(0xFF000000),
              ),
              const SizedBox(width: 8),
              const Text(
                'DRAUGHTSMAN',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Color(0xFF000000),
                ),
              ),
            ],
          ),

          // Desktop Navigation Tabs
          if (isDesktop)
            Row(
              children: [
                _buildNavLink(context, 'Studio', '/draughtsman/studio', false),
                _buildNavLink(context, 'Drawings', '/draughtsman/drawings', true),
                _buildNavLink(context, 'Insights', '/draughtsman/insights', false),
              ],
            ),

          // Right Controls: Live Workspace Chip & Profile
          Row(
            children: [
              // Live Workspace Chip (Navigates directly back to the workspace)
              InkWell(
                onTap: () => context.go('/draughtsman/workspace/$currentAssignmentId'),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3F5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF356EE7),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Live Workspace',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF44474D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Avatar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFDAE2FF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0x4DC5C6CD),
                    width: 0.5,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'D',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0453CD),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(BuildContext context, String label, String route, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextButton(
        onPressed: () => context.go(route),
        style: TextButton.styleFrom(
          foregroundColor: isActive ? const Color(0xFF0453CD) : const Color(0xFF44474D),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Blueprint grid background painter matching 40px grid in reference CSS
class _BlueprintGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0A000000)
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
