import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:archi_draft/src/core/theme/app_colors.dart';
import 'package:archi_draft/src/core/theme/app_spacing.dart';
import 'package:archi_draft/src/core/theme/app_typography.dart';
import 'package:archi_draft/src/shared/widgets/app_state_widgets.dart';

import 'package:archi_draft/src/features/auth/providers/auth_providers.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/domain/project_status.dart';

import 'widgets/project_status_chip.dart';

/// Client / Engineer Projects Dashboard Screen.
///
/// Implements the Stitch "Client Projects Dashboard" design (screen ID: 07f71e1e54eb4a7aa39ccd2434a06c97).
///
/// Layout:
///   - Welcome section (monospace label + bold title)
///   - "Submit New Project" CTA button
///   - Horizontal filter pills (All / Under Review / In Drafting / Approved)
///   - 3-column metric summary strip (Active, Pending Review, Completed)
///   - Project cards list with top accent line per card
///   - Empty state with blueprint-style illustration
///
/// Backend: reads via [clientProjectsProvider] → ApiClient → Cloudflare Worker → D1.
/// Auth: Firebase ID token is attached by ApiClient._getHeaders(); no client-supplied UID.
class ClientProjectsScreen extends ConsumerStatefulWidget {
  const ClientProjectsScreen({super.key});

  @override
  ConsumerState<ClientProjectsScreen> createState() =>
      _ClientProjectsScreenState();
}

class _ClientProjectsScreenState extends ConsumerState<ClientProjectsScreen> {
  _FilterOption _selectedFilter = _FilterOption.all;

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(clientProjectsProvider);
    final statsAsync = ref.watch(clientDashboardStatsProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final profileName = profileAsync.when(
      data: (p) => p?.name,
      loading: () => null,
      error: (e, st) => null,
    );

    return Scaffold(
      backgroundColor: Colors.transparent, // Let ResponsiveScaffold background show
      body: projectsAsync.when(
        loading: () =>
            const AppLoadingIndicator(message: 'Loading projects...'),
        error: (error, _) => AppErrorWidget(
          message: 'Failed to load projects. Please try again.',
          onRetry: () => ref.invalidate(clientProjectsProvider),
        ),
        data: (projects) {
          final filtered = _applyFilter(projects, _selectedFilter);
          return RefreshIndicator(
            color: AppColors.secondary,
            onRefresh: () async {
              ref.invalidate(clientProjectsProvider);
              try {
                await ref.read(clientProjectsProvider.future);
              } catch (_) {}
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Welcome Section ──
                SliverToBoxAdapter(
                  child: _buildWelcomeSection(context, profileName),
                ),
                // ── CTA + Filter Pills ──
                SliverToBoxAdapter(
                  child: _buildActionsSection(context, projects),
                ),
                // ── Metric Strip ──
                SliverToBoxAdapter(
                  child: _buildMetricStrip(statsAsync),
                ),
                // ── Section Header ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.marginMobile,
                      AppSpacing.xl,
                      AppSpacing.marginMobile,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ACTIVE TECHNICAL DELIVERABLES',
                          style: AppTypography.labelMono.copyWith(
                            color: AppColors.outline,
                            letterSpacing: 0.08 * 12,
                          ),
                        ),
                        Text(
                          'Sorted by date',
                          style: AppTypography.labelMonoSm.copyWith(
                            color: AppColors.outlineVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Project Cards or Empty State ──
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context, projects.isNotEmpty),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.marginMobile,
                      0,
                      AppSpacing.marginMobile,
                      120, // Space for FAB
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final project = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppSpacing.md),
                            child: _StitchProjectCard(
                              project: project,
                              onTap: () => context.go(
                                  '/client/projects/${project.projectId}'),
                            ),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/client/projects/new'),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.onSecondary,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          'New Project',
          style: AppTypography.buttonText.copyWith(
            color: AppColors.onSecondary,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  // ── Welcome Section ─────────────────────────────────────────────────────────

  Widget _buildWelcomeSection(BuildContext context, String? userName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        AppSpacing.lg,
        AppSpacing.marginMobile,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stitch: monospace uppercase label with green dot
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'CLIENT PROJECT SUITE',
                    style: AppTypography.labelMono.copyWith(
                      color: AppColors.outline,
                      letterSpacing: 0.08 * 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Projects & CAD Review',
                style: AppTypography.headlineLgMobile.copyWith(
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          // Stitch: small mono version label
          Text(
            'REV v4.2',
            style: AppTypography.labelMonoSm.copyWith(
              color: AppColors.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions: CTA + Filter Pills ─────────────────────────────────────────────

  Widget _buildActionsSection(BuildContext context, List<Project> projects) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        AppSpacing.lg,
        AppSpacing.marginMobile,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stitch: full-width midnight CTA button
          InkWell(
            onTap: () => context.go('/client/projects/new'),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer, // deep midnight blue
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+',
                      style: AppTypography.buttonText.copyWith(
                        color: const Color(0xFF38BDF8), // cyan-400
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Submit New Project',
                      style: AppTypography.buttonText.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    'START BRIEF',
                    style: AppTypography.labelMono.copyWith(
                      color: AppColors.onPrimaryContainer,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppColors.onPrimaryContainer,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Stitch: horizontal scroll filter pills
          _buildFilterPills(projects),
        ],
      ),
    );
  }

  Widget _buildFilterPills(List<Project> projects) {
    final counts = {
      _FilterOption.all: projects.length,
      _FilterOption.underReview: projects
          .where((p) => p.projectStatus == ProjectStatus.underClientReview)
          .length,
      _FilterOption.inDrafting: projects
          .where((p) =>
              p.projectStatus == ProjectStatus.submitted ||
              p.projectStatus == ProjectStatus.inProgress ||
              p.projectStatus == ProjectStatus.waitingAssignment ||
              p.projectStatus == ProjectStatus.waitingAcceptance)
          .length,
      _FilterOption.approved: projects
          .where((p) => p.projectStatus == ProjectStatus.completed)
          .length,
    };

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _FilterOption.values.map((option) {
          final isSelected = _selectedFilter == option;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryContainer
                      : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : AppColors.outlineVariant,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 4,
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.label,
                      style: AppTypography.bodySm.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '(${counts[option]})',
                      style: AppTypography.labelMonoSm.copyWith(
                        color: isSelected
                            ? AppColors.onPrimaryContainer
                            : _filterCountColor(option),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _filterCountColor(_FilterOption option) {
    switch (option) {
      case _FilterOption.underReview:
        return AppColors.secondary;
      case _FilterOption.inDrafting:
        return AppColors.warning;
      case _FilterOption.approved:
        return AppColors.success;
      default:
        return AppColors.outline;
    }
  }

  // ── Metric Summary Strip ─────────────────────────────────────────────────────

  Widget _buildMetricStrip(AsyncValue<ClientDashboardStats> statsAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        AppSpacing.lg,
        AppSpacing.marginMobile,
        0,
      ),
      child: statsAsync.when(
        loading: () => const SizedBox(
          height: 80,
          child: AppLoadingIndicator(),
        ),
        error: (e, st) => const SizedBox.shrink(),
        data: (stats) => Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'ACTIVE DWG',
                value: stats.active.toString(),
                subtext: 'In progress',
                subColor: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricCard(
                label: 'PENDING',
                value: stats.pendingReview.toString(),
                subtext: 'Review req.',
                subColor: AppColors.warning,
                hasPulse: stats.pendingReview > 0,
                borderColor: stats.pendingReview > 0
                    ? const Color(0xFFFDE68A) // amber-200
                    : null,
                backgroundColor: stats.pendingReview > 0
                    ? const Color(0xFFFFFBEB).withValues(alpha: 0.5) // amber-50
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricCard(
                label: 'COMPLETED',
                value: stats.completed.toString(),
                subtext: 'All phases',
                subColor: AppColors.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context, bool isFiltered) {
    if (isFiltered) {
      // Filtered empty state: no projects match this filter
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list_off_rounded,
                  size: 48, color: AppColors.outlineVariant),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No Projects in This Category',
                style: AppTypography.headlineLgMobile.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Try selecting a different filter.',
                style: AppTypography.bodySm.copyWith(color: AppColors.outline),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Blank slate empty state (no projects at all)
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.layers_outlined,
                size: 36,
                color: AppColors.outlineVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No Projects Yet',
              style: AppTypography.headlineLgMobile.copyWith(
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Start by creating your first project brief.\nOur team will review and assign a draughtsman.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton.icon(
              onPressed: () => context.go('/client/projects/new'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create Project'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.onSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter Logic ─────────────────────────────────────────────────────────────

  List<Project> _applyFilter(List<Project> projects, _FilterOption filter) {
    switch (filter) {
      case _FilterOption.all:
        return projects;
      case _FilterOption.underReview:
        return projects
            .where((p) => p.projectStatus == ProjectStatus.underClientReview)
            .toList();
      case _FilterOption.inDrafting:
        return projects
            .where((p) =>
                p.projectStatus == ProjectStatus.submitted ||
                p.projectStatus == ProjectStatus.inProgress ||
                p.projectStatus == ProjectStatus.waitingAssignment ||
                p.projectStatus == ProjectStatus.waitingAcceptance)
            .toList();
      case _FilterOption.approved:
        return projects
            .where((p) => p.projectStatus == ProjectStatus.completed)
            .toList();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS & HELPERS
// ─────────────────────────────────────────────────────────────────────────────

enum _FilterOption {
  all('All'),
  underReview('Under Review'),
  inDrafting('In Drafting'),
  approved('Approved');

  const _FilterOption(this.label);
  final String label;
}

// ─────────────────────────────────────────────────────────────────────────────
// STITCH PROJECT CARD
// Matches the Stitch design: white card, 1px border, colored top accent line,
// project ID in mono, bold title, drawing type, address row.
// ─────────────────────────────────────────────────────────────────────────────

class _StitchProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;

  const _StitchProjectCard({required this.project, this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = project.projectStatus ?? ProjectStatus.draft;
    final drawingType = project.drawingTypeEnum;
    final createdAt = project.createdAt;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.outlineVariant, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stitch: colored top accent line based on status
            Container(
              height: 4,
              color: _accentColor(status),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card header: project ID + status chip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'PRJ-${project.projectId.substring(0, 8).toUpperCase()}',
                        style: AppTypography.labelMono.copyWith(
                          color: AppColors.outline,
                          fontSize: 10,
                          letterSpacing: 0.1 * 10,
                        ),
                      ),
                      ProjectStatusChip(status: status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Project name
                  Text(
                    project.projectName.isEmpty
                        ? 'Untitled Project'
                        : project.projectName,
                    style: AppTypography.headlineLgMobile.copyWith(
                      color: AppColors.primaryContainer, // deep midnight
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Drawing type subtitle
                  if (drawingType != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      drawingType.displayName,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.md),

                  // Footer row: address + date
                  Row(
                    children: [
                      if (project.projectAddress.isNotEmpty) ...[
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppColors.outline,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            project.projectAddress,
                            style: AppTypography.labelMonoSm.copyWith(
                              color: AppColors.outline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else
                        const Spacer(),
                      if (createdAt != null)
                        Text(
                          DateFormat('MMM d, yyyy').format(createdAt),
                          style: AppTypography.labelMonoSm.copyWith(
                            color: AppColors.outlineVariant,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _accentColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.inProgress:
      case ProjectStatus.waitingAcceptance:
        return AppColors.secondary; // blue
      case ProjectStatus.underClientReview:
        return const Color(0xFF38BDF8); // cyan
      case ProjectStatus.completed:
        return AppColors.success; // green
      case ProjectStatus.cancelled:
        return AppColors.error; // red
      case ProjectStatus.waitingAssignment:
        return AppColors.warning; // amber
      case ProjectStatus.submitted:
        return AppColors.secondaryContainer; // lighter blue
      case ProjectStatus.draft:
        return AppColors.outlineVariant; // grey
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// METRIC CARD
// ─────────────────────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;
  final Color subColor;
  final bool hasPulse;
  final Color? borderColor;
  final Color? backgroundColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtext,
    required this.subColor,
    this.hasPulse = false,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: borderColor ?? AppColors.outlineVariant.withValues(alpha: 0.9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.03),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelMonoSm.copyWith(
              color: AppColors.outline,
              letterSpacing: 0.08 * 10,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                value,
                style: AppTypography.headlineLgMobile.copyWith(
                  fontFamily: 'JetBrains Mono',
                  color: AppColors.primaryContainer,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (hasPulse) ...[
                const SizedBox(width: AppSpacing.xs),
                _PulsingDot(),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtext,
            style: AppTypography.labelMonoSm.copyWith(
              color: subColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.warning,
        ),
      ),
    );
  }
}
