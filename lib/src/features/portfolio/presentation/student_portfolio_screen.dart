import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../projects/data/file_repository.dart';
import '../domain/portfolio_project.dart';
import '../providers/portfolio_providers.dart';
import '../../profile/domain/student_credential.dart';
import '../../profile/providers/credentials_providers.dart';
import '../../profile/domain/student_achievement.dart';
import '../../profile/providers/achievements_providers.dart';

enum PortfolioFilter {
  all,
  practical,
  credentials,
  milestones,
}

class StudentPortfolioScreen extends ConsumerStatefulWidget {
  const StudentPortfolioScreen({super.key});

  @override
  ConsumerState<StudentPortfolioScreen> createState() => _StudentPortfolioScreenState();
}

class _StudentPortfolioScreenState extends ConsumerState<StudentPortfolioScreen> {
  PortfolioFilter _selectedFilter = PortfolioFilter.all;

  @override
  Widget build(BuildContext context) {
    final portfolioAsync = ref.watch(studentPortfolioProvider);
    final credentialsAsync = ref.watch(studentCredentialsProvider);
    final achievementsAsync = ref.watch(studentAchievementsProvider);

    final isLoading = portfolioAsync.isLoading && credentialsAsync.isLoading && achievementsAsync.isLoading;
    final hasError = portfolioAsync.hasError && credentialsAsync.hasError;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Student Portfolio',
          style: AppTypography.headlineSmMobile.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Portfolio',
            onPressed: () {
              ref.invalidate(studentPortfolioProvider);
              ref.invalidate(studentCredentialsProvider);
              ref.invalidate(studentAchievementsProvider);
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Failed to load portfolio evidence.',
                          style: AppTypography.bodyMd.copyWith(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(studentPortfolioProvider);
                            ref.invalidate(studentCredentialsProvider);
                            ref.invalidate(studentAchievementsProvider);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(studentPortfolioProvider);
                    ref.invalidate(studentCredentialsProvider);
                    ref.invalidate(studentAchievementsProvider);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Evidence Overview Banner
                        _EvidenceOverviewHeader(
                          portfolio: portfolioAsync.value ?? [],
                          credentials: credentialsAsync.value ?? [],
                          achievements: achievementsAsync.value ?? [],
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Filter Segmented Bar
                        _FilterTabs(
                          selected: _selectedFilter,
                          practicalCount: (portfolioAsync.value ?? []).length,
                          credentialsCount: (credentialsAsync.value ?? []).length,
                          milestonesCount: (achievementsAsync.value ?? []).where((a) => a.isUnlocked).length,
                          onChanged: (newFilter) {
                            setState(() {
                              _selectedFilter = newFilter;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Section Content
                        _buildSectionContent(
                          portfolio: portfolioAsync.value ?? [],
                          credentials: credentialsAsync.value ?? [],
                          achievements: achievementsAsync.value ?? [],
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectionContent({
    required List<PortfolioProject> portfolio,
    required List<StudentCredential> credentials,
    required List<StudentAchievement> achievements,
  }) {
    final unlockedMilestones = achievements.where((a) => a.isUnlocked).toList();

    switch (_selectedFilter) {
      case PortfolioFilter.all:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPracticalSection(portfolio),
            const SizedBox(height: AppSpacing.xl),
            _buildCredentialsSection(credentials),
            const SizedBox(height: AppSpacing.xl),
            _buildMilestonesSection(unlockedMilestones),
          ],
        );
      case PortfolioFilter.practical:
        return _buildPracticalSection(portfolio);
      case PortfolioFilter.credentials:
        return _buildCredentialsSection(credentials);
      case PortfolioFilter.milestones:
        return _buildMilestonesSection(unlockedMilestones);
    }
  }

  Widget _buildPracticalSection(List<PortfolioProject> portfolio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.architecture, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'PRACTICAL DELIVERABLES',
              style: AppTypography.labelMono.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                '${portfolio.length}',
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (portfolio.isEmpty)
          const _EmptySectionCard(
            icon: Icons.assignment_turned_in_outlined,
            title: 'No Practical Deliverables Yet',
            description:
                'Completed CAD drawings reviewed and approved by Studio Administration will be published here with evaluation scorecards.',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: portfolio.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.lg),
            itemBuilder: (context, index) {
              return PortfolioProjectCard(project: portfolio[index]);
            },
          ),
      ],
    );
  }

  Widget _buildCredentialsSection(List<StudentCredential> credentials) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.workspace_premium_outlined, color: AppColors.secondary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'CREDENTIALS & CERTIFICATIONS',
              style: AppTypography.labelMono.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                '${credentials.length}',
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (credentials.isEmpty)
          const _EmptySectionCard(
            icon: Icons.card_membership_outlined,
            title: 'No Formal Credentials Yet',
            description:
                'Official course and module credentials issued by Administration will appear here with downloadable certificates and verification tokens.',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: credentials.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              return PortfolioCredentialCard(credential: credentials[index]);
            },
          ),
      ],
    );
  }

  Widget _buildMilestonesSection(List<StudentAchievement> unlockedMilestones) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events_outlined, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'MILESTONES & ACHIEVEMENTS',
              style: AppTypography.labelMono.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                '${unlockedMilestones.length}',
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (unlockedMilestones.isEmpty)
          const _EmptySectionCard(
            icon: Icons.emoji_events_outlined,
            title: 'No Milestones Unlocked Yet',
            description:
                'Progress milestones are automatically awarded as you complete lessons, advance modules, and earn drawing approvals.',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: unlockedMilestones.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              return PortfolioMilestoneCard(milestone: unlockedMilestones[index]);
            },
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// EVIDENCE OVERVIEW HEADER
// ─────────────────────────────────────────────

class _EvidenceOverviewHeader extends StatelessWidget {
  final List<PortfolioProject> portfolio;
  final List<StudentCredential> credentials;
  final List<StudentAchievement> achievements;

  const _EvidenceOverviewHeader({
    required this.portfolio,
    required this.credentials,
    required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    final unlockedMilestones = achievements.where((a) => a.isUnlocked).length;
    final totalPercentage = portfolio.fold<int>(0, (sum, p) => sum + p.evaluation.overallPercentage);
    final avgScore = portfolio.isNotEmpty ? (totalPercentage / portfolio.length).round() : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Curriculum & Practical Evidence',
                      style: AppTypography.headlineSmMobile.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Official portfolio of Admin-evaluated CAD deliverables, verified credentials, and curriculum achievements.',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1, color: AppColors.surfaceVariant),
          const SizedBox(height: AppSpacing.lg),

          // Responsive Metrics Grid / Wrap
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _MetricPill(
                icon: Icons.architecture,
                value: '${portfolio.length}',
                label: 'Approved Projects',
                accentColor: AppColors.primary,
              ),
              _MetricPill(
                icon: Icons.workspace_premium_outlined,
                value: '${credentials.length}',
                label: 'Credentials',
                accentColor: AppColors.secondary,
              ),
              _MetricPill(
                icon: Icons.emoji_events_outlined,
                value: '$unlockedMilestones',
                label: 'Milestones',
                accentColor: AppColors.tertiary,
              ),
              if (avgScore != null)
                _MetricPill(
                  icon: Icons.grade_outlined,
                  value: '$avgScore%',
                  label: 'Avg Evaluation',
                  accentColor: avgScore >= 80 ? AppColors.success : AppColors.primary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accentColor;

  const _MetricPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.bodyMd.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FILTER TABS
// ─────────────────────────────────────────────

class _FilterTabs extends StatelessWidget {
  final PortfolioFilter selected;
  final int practicalCount;
  final int credentialsCount;
  final int milestonesCount;
  final ValueChanged<PortfolioFilter> onChanged;

  const _FilterTabs({
    required this.selected,
    required this.practicalCount,
    required this.credentialsCount,
    required this.milestonesCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = practicalCount + credentialsCount + milestonesCount;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All ($totalCount)', PortfolioFilter.all),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip('Practical Work ($practicalCount)', PortfolioFilter.practical),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip('Credentials ($credentialsCount)', PortfolioFilter.credentials),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip('Milestones ($milestonesCount)', PortfolioFilter.milestones),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, PortfolioFilter filter) {
    final isSelected = selected == filter;

    return InkWell(
      onTap: () => onChanged(filter),
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.buttonText.copyWith(
            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PRACTICAL PROJECT CARD
// ─────────────────────────────────────────────

class PortfolioProjectCard extends ConsumerStatefulWidget {
  final PortfolioProject project;

  const PortfolioProjectCard({
    super.key,
    required this.project,
  });

  @override
  ConsumerState<PortfolioProjectCard> createState() => _PortfolioProjectCardState();
}

class _PortfolioProjectCardState extends ConsumerState<PortfolioProjectCard> {
  bool _isDownloading = false;

  Future<void> _downloadFile() async {
    if (widget.project.finalDrawing == null) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      final repository = ref.read(fileRepositoryProvider);
      final finalDrawing = widget.project.finalDrawing!;

      final isDwg = finalDrawing.sanitizedName.toLowerCase().endsWith('.dwg');

      if (kIsWeb) {
        await repository.downloadFile(
          finalDrawing.fileId,
          finalDrawing.sanitizedName,
        );
        if (!mounted) return;
        if (isDwg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 8),
              content: const Text(
                'DWG downloaded. AutoCAD Viewer is required to open it.',
              ),
              action: SnackBarAction(
                label: 'Download AutoCAD Viewer for Android',
                onPressed: () async {
                  final uri = Uri.parse(
                    'https://play.google.com/store/apps/details?id=com.autodesk.autocadws',
                  );
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Download started in browser')),
          );
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/${finalDrawing.sanitizedName}';
        await repository.downloadFile(finalDrawing.fileId, filePath);

        if (!mounted) return;
        if (isDwg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 8),
              content: const Text(
                'DWG downloaded. AutoCAD Viewer is required to open it.',
              ),
              action: SnackBarAction(
                label: 'Download AutoCAD Viewer for Android',
                onPressed: () async {
                  final uri = Uri.parse(
                    'https://play.google.com/store/apps/details?id=com.autodesk.autocadws',
                  );
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloaded to ${finalDrawing.sanitizedName}'),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () => OpenFilex.open(filePath),
              ),
            ),
          );
        }
        try {
          await OpenFilex.open(filePath);
        } catch (_) {
          // Do not treat opening failure or lack of viewer as a download failure
        }
      }
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download drawing: $errorMsg')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final evalPercentage = widget.project.evaluation.overallPercentage;
    final isSuccess = evalPercentage >= 80;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.project.projectName,
                      style: AppTypography.headlineSmMobile.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.project.drawingType} • ${widget.project.projectArea}',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.project.isTrainingProject
                      ? AppColors.secondary.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                ),
                child: Text(
                  widget.project.isTrainingProject ? 'Training Project' : 'Practical Work',
                  style: AppTypography.labelMono.copyWith(
                    color: widget.project.isTrainingProject ? AppColors.secondary : AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          if (widget.project.approvedAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  'Admin Approved on ${dateFormat.format(widget.project.approvedAt!)}',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.surfaceVariant),
          const SizedBox(height: AppSpacing.md),

          // Evaluation Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isSuccess ? AppColors.success : AppColors.primary).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                    ),
                    child: Text(
                      widget.project.evaluation.result,
                      style: AppTypography.labelMono.copyWith(
                        color: isSuccess ? AppColors.success : AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Evaluation Score',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Text(
                '$evalPercentage%',
                style: AppTypography.headlineSmMobile.copyWith(
                  color: isSuccess ? AppColors.success : AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: evalPercentage / 100.0,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(
                isSuccess ? AppColors.success : AppColors.primary,
              ),
              minHeight: 8,
            ),
          ),

          // Criteria breakdown (if available)
          if (widget.project.evaluation.criteria.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'EVALUATION CRITERIA',
              style: AppTypography.labelMono.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...widget.project.evaluation.criteria.map((crit) {
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      crit.name,
                      style: AppTypography.bodySm.copyWith(color: AppColors.onSurface),
                    ),
                    Text(
                      '${crit.score} / ${crit.maxScore}',
                      style: AppTypography.labelMono.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          if (widget.project.evaluation.generalFeedback != null &&
              widget.project.evaluation.generalFeedback!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.rate_review_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'ADMIN MENTOR FEEDBACK',
                        style: AppTypography.labelMono.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.project.evaluation.generalFeedback!,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurface,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          // Final Drawing Action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.project.finalDrawing == null || _isDownloading ? null : _downloadFile,
              icon: _isDownloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download, size: 18),
              label: Text(
                widget.project.finalDrawing == null
                    ? 'Final Drawing Not Available'
                    : 'Download Final Drawing (${widget.project.finalDrawing!.sanitizedName})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CREDENTIAL CARD
// ─────────────────────────────────────────────

class PortfolioCredentialCard extends ConsumerStatefulWidget {
  final StudentCredential credential;

  const PortfolioCredentialCard({
    super.key,
    required this.credential,
  });

  @override
  ConsumerState<PortfolioCredentialCard> createState() => _PortfolioCredentialCardState();
}

class _PortfolioCredentialCardState extends ConsumerState<PortfolioCredentialCard> {
  bool _isProcessing = false;

  Future<void> _handleDownloadOrGenerate() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final repository = ref.read(credentialsRepositoryProvider);
      if (widget.credential.certificateObjectKey == null) {
        await repository.generateCertificate(widget.credential.id);
        ref.invalidate(studentCredentialsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Certificate generated successfully!')),
          );
        }
      } else {
        String savePath = 'Certificate_${widget.credential.id}.pdf';
        bool isMobile = false;
        try {
          if (!identical(0, 0.0)) {
            isMobile = true;
            final directory = await getApplicationDocumentsDirectory();
            savePath = '${directory.path}/$savePath';
          }
        } catch (_) {}

        await repository.downloadCertificate(widget.credential.id, savePath);
        if (mounted) {
          if (isMobile) {
            await OpenFilex.open(savePath);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Certificate opened')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Certificate downloaded')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final hasCertificate = widget.credential.certificateObjectKey != null;
    final hasVerification = widget.credential.verificationToken != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: AppColors.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.credential.title,
                      style: AppTypography.headlineSmMobile.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Type: ${widget.credential.type} • Issued: ${dateFormat.format(widget.credential.issuedAt)}',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasVerification)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: AppTypography.labelMono.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          if (widget.credential.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.credential.description,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurface,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: _isProcessing ? null : _handleDownloadOrGenerate,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(hasCertificate ? Icons.picture_as_pdf : Icons.build_circle_outlined, size: 18),
                label: Text(hasCertificate ? 'Download PDF Certificate' : 'Generate Certificate PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.secondary),
                ),
              ),
              if (hasVerification)
                TextButton.icon(
                  onPressed: () {
                    context.push('/verify/${widget.credential.verificationToken}');
                  },
                  icon: const Icon(Icons.qr_code, size: 18),
                  label: const Text('View Online Verification'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MILESTONE CARD
// ─────────────────────────────────────────────

class PortfolioMilestoneCard extends StatelessWidget {
  final StudentAchievement milestone;

  const PortfolioMilestoneCard({
    super.key,
    required this.milestone,
  });

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'school_outlined':
        return Icons.school_outlined;
      case 'workspace_premium_outlined':
        return Icons.workspace_premium_outlined;
      case 'assignment_turned_in_outlined':
        return Icons.assignment_turned_in_outlined;
      case 'verified_outlined':
        return Icons.verified_outlined;
      case 'military_tech_outlined':
        return Icons.military_tech_outlined;
      default:
        return Icons.emoji_events_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              _getIconData(milestone.icon),
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        milestone.title,
                        style: AppTypography.bodyMd.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                      ),
                      child: Text(
                        milestone.category,
                        style: AppTypography.labelMono.copyWith(
                          fontSize: 10,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  milestone.description,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (milestone.unlockedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Unlocked ${dateFormat.format(milestone.unlockedAt!)}',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.outline,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EMPTY SECTION CARD
// ─────────────────────────────────────────────

class _EmptySectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _EmptySectionCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTypography.headlineSmMobile.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
