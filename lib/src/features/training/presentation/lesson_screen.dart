import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
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

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonDetailProvider(widget.lessonId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
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
                // Action Button
                ElevatedButton(
                  onPressed: _isSubmitting || lesson.status == 'COMPLETED' ? null : () => _markCompleted(lesson),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lesson.status == 'COMPLETED' ? AppColors.surfaceContainerHigh : AppColors.secondary,
                    foregroundColor: lesson.status == 'COMPLETED' ? AppColors.onSurfaceVariant : AppColors.onSecondary,
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
                            Icon(lesson.status == 'COMPLETED' ? Icons.check_circle : Icons.check, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              lesson.status == 'COMPLETED' ? 'Lesson Completed' : 'Mark as Complete',
                              style: AppTypography.buttonText,
                            ),
                          ],
                        ),
                ),
                if (lesson.status == 'COMPLETED') ...[
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: TextButton(
                      onPressed: () => context.pop(),
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lesson marked as complete!'),
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
