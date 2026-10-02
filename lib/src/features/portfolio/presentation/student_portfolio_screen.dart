import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archi_draft/src/features/portfolio/domain/portfolio_project.dart';
import 'package:archi_draft/src/features/portfolio/providers/portfolio_providers.dart';
import 'package:archi_draft/src/features/projects/data/file_repository.dart';
import 'package:archi_draft/src/core/theme/app_colors.dart';
import 'package:archi_draft/src/core/theme/app_typography.dart';
import 'package:archi_draft/src/core/theme/app_spacing.dart';
import 'package:intl/intl.dart';

class StudentPortfolioScreen extends ConsumerWidget {
  const StudentPortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(studentPortfolioProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Portfolio'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: portfolioAsync.when(
        data: (portfolio) {
          if (portfolio.isEmpty) {
            return Center(
              child: Text(
                'No completed evaluated projects in your portfolio yet.',
                style: AppTypography.bodyMd,
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 1;
                if (constraints.maxWidth >= 1024) {
                  crossAxisCount = 3;
                } else if (constraints.maxWidth >= 600) {
                  crossAxisCount = 2;
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: portfolio.length,
                  itemBuilder: (context, index) {
                    final project = portfolio[index];
                    return PortfolioProjectCard(project: project);
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Failed to load portfolio.',
                style: AppTypography.bodyMd.copyWith(color: AppColors.error),
              ),
              SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => ref.refresh(studentPortfolioProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

      if (kIsWeb) {
        await repository.downloadFile(
          finalDrawing.fileId,
          finalDrawing.sanitizedName,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download started in browser')),
        );
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/${finalDrawing.sanitizedName}';
        await repository.downloadFile(finalDrawing.fileId, filePath);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded to $filePath')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download drawing.')),
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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.project.projectName,
                    style: AppTypography.headlineLgMobile,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.project.isTrainingProject)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Training',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Real Project',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              '${widget.project.drawingType} • ${widget.project.projectArea}',
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            if (widget.project.approvedAt != null)
              Padding(
                padding: EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Approved on ${dateFormat.format(widget.project.approvedAt!)}',
                  style: AppTypography.bodySm.copyWith(color: AppColors.outline),
                ),
              ),
            Divider(height: AppSpacing.lg),
            Text(
              'Evaluation: ${widget.project.evaluation.result}',
              style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: widget.project.evaluation.overallPercentage / 100,
                    backgroundColor: AppColors.outlineVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.project.evaluation.overallPercentage >= 80 ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  '${widget.project.evaluation.overallPercentage}%',
                  style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: widget.project.evaluation.criteria.length,
                itemBuilder: (context, index) {
                  final crit = widget.project.evaluation.criteria[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(crit.name, style: AppTypography.bodySm),
                        Text('${crit.score}/${crit.maxScore}', style: AppTypography.bodySm),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.project.finalDrawing == null || _isDownloading
                    ? null
                    : _downloadFile,
                icon: _isDownloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(widget.project.finalDrawing == null ? 'Drawing Missing' : 'Final Drawing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
