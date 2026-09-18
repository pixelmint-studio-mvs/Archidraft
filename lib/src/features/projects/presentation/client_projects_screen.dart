import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:archi_draft/src/core/theme/app_colors.dart';
import 'package:archi_draft/src/core/theme/app_spacing.dart';
import 'package:archi_draft/src/core/theme/app_typography.dart';
import 'package:archi_draft/src/shared/widgets/app_state_widgets.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';

/// The client's main project list screen.
///
/// Displays all projects owned by the authenticated client with rich
/// filter tabs, summary stats, and styled deliverable rows.
class ClientProjectsScreen extends ConsumerStatefulWidget {
  const ClientProjectsScreen({super.key});

  @override
  ConsumerState<ClientProjectsScreen> createState() =>
      _ClientProjectsScreenState();
}

class _ClientProjectsScreenState extends ConsumerState<ClientProjectsScreen> {
  // 0 = All, 1 = Under Review, 2 = In Drafting, 3 = Approved/Completed
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(clientProjectsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: projectsAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Loading projects...'),
        error: (error, _) => AppErrorWidget(
          message: 'Failed to load projects. Please try again.',
          onRetry: () => ref.invalidate(clientProjectsProvider),
        ),
        data: (projects) {
          final filtered = _filterProjects(projects, _selectedFilter);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(clientProjectsProvider);
              try {
                await ref.read(clientProjectsProvider.future);
              } catch (_) {}
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.marginMobile,
                      AppSpacing.lg,
                      AppSpacing.marginMobile,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ──
                        Text(
                          '• CLIENT PROJECT SUITE',
                          style: AppTypography.labelMono.copyWith(
                            color: AppColors.secondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Projects & CAD Review',
                              style: AppTypography.headlineLgMobile.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'REV v4.2',
                              style: AppTypography.labelMono.copyWith(
                                color: AppColors.outline,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // ── Submit New Project Banner ──
                        _SubmitBanner(
                          onTap: () => context.go('/client/projects/new'),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // ── Filter Tabs ──
                        _FilterTabs(
                          projects: projects,
                          selectedIndex: _selectedFilter,
                          onChanged: (i) =>
                              setState(() => _selectedFilter = i),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // ── Stats Row ──
                        _StatsRow(projects: projects),
                        const SizedBox(height: AppSpacing.xl),

                        // ── Section Header ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ACTIVE TECHNICAL DELIVERABLES',
                              style: AppTypography.labelMono.copyWith(
                                color: AppColors.outline,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'Sorted by date',
                              style: AppTypography.labelMono.copyWith(
                                color: AppColors.outline,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Divider(
                          color: AppColors.secondary,
                          thickness: 2,
                          height: 1,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ),
                  ),
                ),

                // ── Project List ──
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final project = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.marginMobile,
                            vertical: 2,
                          ),
                          child: _ProjectRow(
                            project: project,
                            onTap: () => context.go(
                              '/client/projects/${project.projectId}',
                            ),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'client_new_project_fab',
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

  List<Project> _filterProjects(List<Project> all, int filter) {
    switch (filter) {
      case 1: // Under Review
        return all
            .where((p) =>
                p.status == 'UNDER_CLIENT_REVIEW' ||
                p.status == 'SUBMITTED')
            .toList();
      case 2: // In Drafting
        return all
            .where((p) =>
                p.status == 'IN_PROGRESS' ||
                p.status == 'WAITING_ASSIGNMENT' ||
                p.status == 'WAITING_ACCEPTANCE')
            .toList();
      case 3: // Approved / Completed
        return all
            .where((p) =>
                p.status == 'COMPLETED' || p.status == 'CANCELLED')
            .toList();
      default:
        return all;
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.layers_outlined,
              size: 64,
              color: AppColors.outlineVariant,
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
              'Start by creating your first project brief.',
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
}

// ─────────────────────────────────────────────────────────────
// Submit Banner
// ─────────────────────────────────────────────────────────────

class _SubmitBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _SubmitBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 18,
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
              'START BRIEF  →',
              style: AppTypography.labelMono.copyWith(
                color: AppColors.onPrimaryContainer,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Filter Tabs
// ─────────────────────────────────────────────────────────────

class _FilterTabs extends StatelessWidget {
  final List<Project> projects;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _FilterTabs({
    required this.projects,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final underReview = projects
        .where((p) =>
            p.status == 'UNDER_CLIENT_REVIEW' || p.status == 'SUBMITTED')
        .length;
    final inDrafting = projects
        .where((p) =>
            p.status == 'IN_PROGRESS' ||
            p.status == 'WAITING_ASSIGNMENT' ||
            p.status == 'WAITING_ACCEPTANCE')
        .length;
    final approved = projects
        .where((p) => p.status == 'COMPLETED' || p.status == 'CANCELLED')
        .length;

    final labels = [
      ('All', projects.length),
      ('Under Review', underReview),
      ('In Drafting', inDrafting),
      ('Approved', approved),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(labels.length, (i) {
          final (label, count) = labels[i];
          final selected = i == selectedIndex;
          return Padding(
            padding: EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.onSurface
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AppColors.onSurface
                        : AppColors.outlineVariant,
                  ),
                ),
                child: Text(
                  '$label ($count)',
                  style: AppTypography.bodySm.copyWith(
                    color: selected ? Colors.white : AppColors.onSurface,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stats Row
// ─────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final List<Project> projects;
  const _StatsRow({required this.projects});

  @override
  Widget build(BuildContext context) {
    final inProgress =
        projects.where((p) => p.status == 'IN_PROGRESS').length;
    final pending = projects
        .where((p) =>
            p.status == 'SUBMITTED' ||
            p.status == 'WAITING_ASSIGNMENT' ||
            p.status == 'WAITING_ACCEPTANCE' ||
            p.status == 'UNDER_CLIENT_REVIEW')
        .length;
    final completed =
        projects.where((p) => p.status == 'COMPLETED').length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'ACTIVE DWG',
            value: '$inProgress',
            sublabel: 'In progress',
            sublabelColor: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            label: 'PENDING',
            value: '$pending',
            sublabel: 'Review req.',
            sublabelColor: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            label: 'COMPLETED',
            value: '$completed',
            sublabel: 'All phases',
            sublabelColor: AppColors.outline,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sublabel;
  final Color sublabelColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.sublabelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelMono.copyWith(
              color: AppColors.outline,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.headlineLgMobile.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: AppTypography.labelMono.copyWith(color: sublabelColor),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Project Row (matches screenshot style)
// ─────────────────────────────────────────────────────────────

class _ProjectRow extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const _ProjectRow({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final shortId = project.projectId.length >= 8
        ? 'PRJ-${project.projectId.substring(0, 8).toUpperCase()}'
        : 'PRJ-${project.projectId.toUpperCase()}';
    final dateStr = project.createdAt != null
        ? DateFormat('MMM d, y').format(project.createdAt!)
        : '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.outlineVariant),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ID row + badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  shortId,
                  style: AppTypography.labelMono.copyWith(
                    color: AppColors.outline,
                  ),
                ),
                _StatusBadge(status: project.status),
              ],
            ),
            const SizedBox(height: 4),
            // Project name
            Text(
              project.projectName,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            // Drawing type
            Text(
              project.drawingType.replaceAll('_', ' '),
              style: AppTypography.bodySm.copyWith(color: AppColors.outline),
            ),
            const SizedBox(height: 6),
            // Address + date
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: AppColors.outline,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    project.projectAddress,
                    style: AppTypography.labelMono.copyWith(
                      color: AppColors.outline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (dateStr.isNotEmpty)
                  Text(
                    dateStr,
                    style: AppTypography.labelMono.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Status Badge
// ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTypography.labelMono.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (String, Color, Color) _resolve(String s) {
    switch (s) {
      case 'DRAFT':
        return ('DRAFT', AppColors.surfaceContainerHigh, AppColors.outline);
      case 'SUBMITTED':
        return ('SUBMITTED', AppColors.warningContainer, AppColors.warning);
      case 'WAITING_ASSIGNMENT':
        return ('WAITING', AppColors.warningContainer, AppColors.warning);
      case 'WAITING_ACCEPTANCE':
        return ('PENDING', AppColors.warningContainer, AppColors.warning);
      case 'IN_PROGRESS':
        return ('IN PROGRESS', const Color(0xFFDEEAFF), AppColors.secondary);
      case 'UNDER_CLIENT_REVIEW':
        return ('UNDER REVIEW', const Color(0xFFDEEAFF), AppColors.secondary);
      case 'COMPLETED':
        return ('COMPLETED', AppColors.successContainer, AppColors.success);
      case 'CANCELLED':
        return ('CANCELLED', AppColors.errorContainer, AppColors.error);
      default:
        return (s, AppColors.surfaceContainerHigh, AppColors.outline);
    }
  }
}
