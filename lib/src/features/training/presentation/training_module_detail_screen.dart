import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/training_module.dart';
import '../providers/training_providers.dart';

class TrainingModuleDetailScreen extends ConsumerWidget {
  final String moduleId;

  const TrainingModuleDetailScreen({
    super.key,
    required this.moduleId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moduleDetailAsync = ref.watch(moduleDetailProvider(moduleId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '/ ACADEMY // MOD_04',
              style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
            ),
            Text(
              'PRJ-TRN-882',
              style: AppTypography.labelMono.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.md),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.tertiaryFixed,
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
            ),
            child: Text(
              'BIM-202',
              style: AppTypography.labelMono.copyWith(color: AppColors.tertiaryContainer, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: moduleDetailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.secondary)),
        error: (err, stack) => _buildErrorState(err.toString(), () => ref.refresh(moduleDetailProvider(moduleId))),
        data: (module) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(module),
                const SizedBox(height: AppSpacing.lg),
                _buildLintingPanel(),
                const SizedBox(height: AppSpacing.lg),
                _buildMentorReview(),
                const SizedBox(height: AppSpacing.lg),
                _buildResubmissionDropzone(),
                const SizedBox(height: AppSpacing.lg),
                _buildActionPalette(),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to Load Module',
              style: AppTypography.headlineLgMobile.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'An error occurred connecting to the server. Please try again.',
              style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.onSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(TrainingModule module) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  module.category.toUpperCase(),
                  style: AppTypography.labelMono.copyWith(color: AppColors.onPrimaryContainer, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                module.level,
                style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            module.title,
            style: AppTypography.headlineLgMobile.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            module.description,
            style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: module.imageUrl != null 
                    ? Image.network(
                        module.imageUrl!,
                        fit: BoxFit.cover,
                      )
                    : const Center(child: Icon(Icons.image_not_supported, color: AppColors.outlineVariant, size: 48)),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified, color: AppColors.tertiaryFixed, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'REV_02.DWG (${module.status.toUpperCase()})',
                            style: AppTypography.labelMono.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                      Text(
                        'SCALE 1:50',
                        style: AppTypography.labelMono.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          if (module.status == 'Completed' && module.score != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FINAL ASSESSMENT',
                            style: AppTypography.labelMono.copyWith(color: AppColors.onPrimary),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${module.score}',
                                style: AppTypography.headlineDisplay.copyWith(color: AppColors.onPrimary, fontSize: 34),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '/ 100',
                                style: AppTypography.labelMono.copyWith(color: AppColors.outlineVariant),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.tertiaryFixed,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  module.score! >= 90 ? 'DISTINCTION' : 'PASS',
                                  style: AppTypography.labelMono.copyWith(color: AppColors.tertiaryContainer, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.military_tech, color: AppColors.tertiaryFixed, size: 28),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLintingPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.rule, color: AppColors.secondary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'AUTOMATED PRE-FLIGHT CAD LINTING',
                    style: AppTypography.labelMono.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                'v4.1 ENGINE',
                style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildLintItem(
                title: 'Line Weight Hierarchy',
                subtitle: '0.18mm - 0.70mm calibrated vector profiles compliant',
                status: 'PASSED',
                isPassed: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildLintItem(
                title: 'Scale Annotation Consistency',
                subtitle: '1:50 Metric Ortho & callout dimensions synchronized',
                status: 'PASSED',
                isPassed: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildLintItem(
                title: 'Unassigned Layer Check',
                subtitle: '2 structural polyline entities found on Layer 0',
                status: 'FLAGGED',
                isPassed: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLintItem({
    required String title,
    required String subtitle,
    required String status,
    required bool isPassed,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isPassed ? AppColors.surface : AppColors.errorContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isPassed ? AppColors.tertiaryFixed : AppColors.error,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPassed ? Icons.check : Icons.priority_high,
              color: isPassed ? AppColors.tertiaryContainer : AppColors.onError,
              size: 16,
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
                    Text(
                      title,
                      style: AppTypography.buttonText.copyWith(color: AppColors.onSurface),
                    ),
                    Text(
                      status,
                      style: AppTypography.labelMono.copyWith(
                        color: isPassed ? AppColors.onTertiaryContainer : AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.rate_review, color: AppColors.secondary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'MENTOR REDLINE REVIEW',
                    style: AppTypography.labelMono.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                'GRADED OCT 24',
                style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMentorHeader(),
              const SizedBox(height: AppSpacing.md),
              _buildVoiceNoteWidget(),
              const SizedBox(height: AppSpacing.md),
              Text(
                'EVALUATION MATRIX',
                style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildRubricItem('Structural Geometry & Joinery', '24 / 25', '"Crisp framing lines. Great application of the parametric louvers, particularly the seismic relief joins."'),
              const SizedBox(height: AppSpacing.xs),
              _buildRubricItem('Drawing Readability & Density', '25 / 25', '"Dimension strings are unobstructed and follow standard metric offset margins flawlessly."'),
              const SizedBox(height: AppSpacing.xs),
              _buildRubricItem('Life Safety & Code Notes', '23 / 25', '"Check fire separation wall rating notes on sheet 2. Ensure IBC 2024 citation matches Japan local code."'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMentorHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.surfaceContainer,
                child: Icon(Icons.person, color: AppColors.onSurfaceVariant), // Placeholder for image
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Arch. Marcus Vance',
                        style: AppTypography.buttonText.copyWith(color: AppColors.onSurface),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: AppColors.secondary, size: 16),
                    ],
                  ),
                  Text(
                    'AIA Fellow • Studio Partner',
                    style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondaryFixed,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'LEAD',
              style: AppTypography.labelMono.copyWith(color: AppColors.onSecondaryFixed, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceNoteWidget() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.mic, color: AppColors.tertiaryFixed, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Mentor Voice Memo Critique',
                    style: AppTypography.labelMono.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                '01:42',
                style: AppTypography.labelMono.copyWith(color: AppColors.outlineVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.tertiaryFixed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: AppColors.tertiaryContainer, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(15, (index) {
                    final isActive = index == 2 || index == 3 || index == 4;
                    return Container(
                      width: 4,
                      height: isActive ? 20 : (8 + (index % 3) * 6).toDouble(),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.tertiaryFixed : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '1.0x',
                style: AppTypography.labelMono.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRubricItem(String title, String score, String comment) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.buttonText.copyWith(color: AppColors.onSurface),
              ),
              Text(
                score,
                style: AppTypography.labelMono.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            comment,
            style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildResubmissionDropzone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.publish, color: AppColors.secondary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'ITERATE REVISION V2.1',
                    style: AppTypography.labelMono.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                'OPTIONAL RE-LINT',
                style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryFixed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cloud_upload, color: AppColors.onSecondaryFixed, size: 20),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Tap or Drop .DWG / .RVT Bundle',
                      style: AppTypography.buttonText.copyWith(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Maximum bundle size 85MB • Auto-sanitizes',
                      style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Re-Linting Pipeline Readiness',
                    style: AppTypography.labelMono.copyWith(color: AppColors.onSurface),
                  ),
                  Text(
                    'Standby',
                    style: AppTypography.labelMono.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                child: const LinearProgressIndicator(
                  value: 1.0,
                  backgroundColor: AppColors.surfaceContainer,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionPalette() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.download, color: AppColors.tertiaryFixed, size: 20),
              const SizedBox(width: 8),
              Text(
                'Download Annotated Redline PDF',
                style: AppTypography.buttonText,
              ),
              const SizedBox(width: 8),
              Text(
                '(18.4 MB)',
                style: AppTypography.labelMono.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surfaceContainerLowest,
            foregroundColor: AppColors.onSurface,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Request 1-on-1 Mentor Office Hours',
                style: AppTypography.buttonText,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
