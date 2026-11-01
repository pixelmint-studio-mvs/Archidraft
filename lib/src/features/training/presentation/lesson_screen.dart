import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../profile/providers/credentials_providers.dart';
import '../domain/lesson.dart';
import '../providers/training_providers.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const LessonScreen({
    super.key,
    required this.lessonId,
  });

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  bool _isSubmitting = false;
  bool _isDownloadingCert = false;

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonDetailProvider(widget.lessonId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/student/training');
            }
          },
        ),
        title: Text(
          'LESSON VIEW',
          style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ),
      body: lessonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.secondary)),
        error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red))),
        data: (lesson) {
          final isCompleted = lesson.status == 'COMPLETED';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LESSON ${lesson.lessonOrder}',
                  style: AppTypography.labelMono.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  lesson.title,
                  style: AppTypography.headlineLgMobile.copyWith(color: AppColors.onSurface),
                ),
                if (lesson.estimatedDuration != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 16, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        lesson.estimatedDuration!,
                        style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                // Main Content
                Text(
                  lesson.content,
                  style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface, height: 1.6),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Official Certificate Card (visible when completed)
                if (isCompleted) ...[
                  _buildCertificateCard(context, lesson),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // Action Button
                ElevatedButton(
                  onPressed: _isSubmitting || isCompleted ? null : () => _markCompleted(lesson),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted ? AppColors.surfaceContainerHigh : AppColors.secondary,
                    foregroundColor: isCompleted ? AppColors.onSurfaceVariant : AppColors.onSecondary,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.onSecondary,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isCompleted ? Icons.check_circle : Icons.check, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              isCompleted ? 'Lesson Completed' : 'Mark as Complete',
                              style: AppTypography.buttonText,
                            ),
                          ],
                        ),
                ),
                if (isCompleted) ...[
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/student/training/${lesson.moduleId}');
                        }
                      },
                      child: Text(
                        'Return to Module',
                        style: AppTypography.buttonText.copyWith(color: AppColors.secondary),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCertificateCard(BuildContext context, Lesson lesson) {
    final certId = lesson.certificateId;
    final token = lesson.verificationToken;
    final hasCert = certId != null && certId.isNotEmpty;
    final verifyUrl = lesson.publicVerificationUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: AppColors.secondary,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LESSON COMPLETION CERTIFICATE',
                      style: AppTypography.labelMono.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Official Achievement Credential',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'Earned',
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
          const SizedBox(height: AppSpacing.md),
          Text(
            lesson.title,
            style: AppTypography.headlineSmMobile.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          if (hasCert) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Credential ID: ',
                  style: AppTypography.labelMono.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                Text(
                  certId,
                  style: AppTypography.labelMono.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ElevatedButton.icon(
                onPressed: _isDownloadingCert || !hasCert
                    ? null
                    : () => _downloadLessonCertificate(lesson),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.onSecondary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                icon: _isDownloadingCert
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onSecondary),
                      )
                    : const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('Download Certificate PDF'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  if (token != null && token.isNotEmpty) {
                    context.push('/verify/$token');
                  } else if (hasCert) {
                    context.push('/verify/$certId');
                  }
                  Clipboard.setData(ClipboardData(text: verifyUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Public verification link copied to clipboard')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                icon: const Icon(Icons.qr_code, size: 18),
                label: const Text('Verify Certificate'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _downloadLessonCertificate(Lesson lesson) async {
    final certId = lesson.certificateId;
    if (certId == null || certId.isEmpty) return;

    setState(() => _isDownloadingCert = true);
    try {
      final repository = ref.read(credentialsRepositoryProvider);
      String savePath = 'Certificate_$certId.pdf';
      bool isMobile = false;
      try {
        if (!identical(0, 0.0)) {
          isMobile = true;
          final directory = await getApplicationDocumentsDirectory();
          savePath = '${directory.path}/$savePath';
        }
      } catch (_) {}

      await repository.downloadCertificate(certId, savePath);
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
            const SnackBar(content: Text('Certificate downloaded successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingCert = false);
      }
    }
  }

  Future<void> _markCompleted(Lesson lesson) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(trainingRepositoryProvider);
      await repository.updateLessonProgress(lesson.id, 'COMPLETED');
      
      if (!mounted) return;

      // Invalidate providers so the UI refreshes
      ref.invalidate(lessonDetailProvider(lesson.id));
      ref.invalidate(moduleLessonsProvider(lesson.moduleId));
      ref.invalidate(moduleDetailProvider(lesson.moduleId));
      ref.invalidate(studentModulesProvider);
      ref.invalidate(categoryProgressProvider);
      ref.invalidate(studentCredentialsProvider);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lesson marked as complete! Certificate issued.'),
          backgroundColor: AppColors.secondary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete lesson: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
