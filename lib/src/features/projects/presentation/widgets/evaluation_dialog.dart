import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/evaluation.dart';
import '../../providers/project_providers.dart';

class EvaluationDialog extends ConsumerStatefulWidget {
  final String projectId;
  final String targetVersionId;
  final EvaluationResult initialResult;

  const EvaluationDialog({
    super.key,
    required this.projectId,
    required this.targetVersionId,
    required this.initialResult,
  });

  @override
  ConsumerState<EvaluationDialog> createState() => _EvaluationDialogState();
}

class _EvaluationDialogState extends ConsumerState<EvaluationDialog> {
  late EvaluationResult _result;
  final _feedbackController = TextEditingController();
  
  // Minimal structured criteria for now
  int? _accuracyScore;
  int? _technicalStandardsScore;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _result = widget.initialResult;
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final feedback = _feedbackController.text.trim();
    if (_result == EvaluationResult.needsCorrection && feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide feedback for the correction.')),
      );
      return;
    }
    
    if (_accuracyScore == null || _technicalStandardsScore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please score both Accuracy and Technical Standards.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final actionId = const Uuid().v4();
      final correctionId = const Uuid().v4();

      final criteria = <String, dynamic>{
        'Accuracy': _accuracyScore,
        'Technical Standards': _technicalStandardsScore,
      };

      await ref
          .read(projectRepositoryProvider)
          .evaluateDrawing(
            projectId: widget.projectId,
            actionId: actionId,
            drawingVersionId: widget.targetVersionId,
            overallResult: _result == EvaluationResult.approved ? 'APPROVED' : 'NEEDS_CORRECTION',
            generalFeedback: feedback.isNotEmpty ? feedback : null,
            criteriaJson: criteria,
            correctionId: _result == EvaluationResult.needsCorrection ? correctionId : null,
          );

      ref.invalidate(projectProvider(widget.projectId));
      ref.invalidate(projectEvaluationsProvider(widget.projectId));
      ref.invalidate(projectCorrectionsProvider(widget.projectId));
      ref.invalidate(projectDrawingVersionsProvider(widget.projectId));

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Evaluation submitted successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit evaluation: $e')),
        );
      }
    }
  }

  final _scoreOptions = const [
    DropdownMenuEntry(value: 5, label: '5 - Excellent'),
    DropdownMenuEntry(value: 4, label: '4 - Strong'),
    DropdownMenuEntry(value: 3, label: '3 - Competent'),
    DropdownMenuEntry(value: 2, label: '2 - Developing'),
    DropdownMenuEntry(value: 1, label: '1 - Needs significant improvement'),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Evaluate Drawing'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownMenu<EvaluationResult>(
                initialSelection: _result,
                label: const Text('Overall Result'),
                dropdownMenuEntries: const [
                  DropdownMenuEntry(
                    value: EvaluationResult.approved,
                    label: 'Approved (Completes Project)',
                  ),
                  DropdownMenuEntry(
                    value: EvaluationResult.needsCorrection,
                    label: 'Needs Correction (Requests Correction)',
                  ),
                ],
                onSelected: (val) {
                  if (val != null) setState(() => _result = val);
                },
                width: 350,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _feedbackController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: _result == EvaluationResult.needsCorrection ? 'Correction Details *' : 'General Feedback',
                  hintText: 'Provide detailed feedback...',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Structured Criteria *',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownMenu<int>(
                label: const Text('Accuracy'),
                dropdownMenuEntries: _scoreOptions,
                onSelected: (val) {
                  setState(() => _accuracyScore = val);
                },
                width: 350,
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownMenu<int>(
                label: const Text('Technical Standards'),
                dropdownMenuEntries: _scoreOptions,
                onSelected: (val) {
                  setState(() => _technicalStandardsScore = val);
                },
                width: 350,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => context.pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: _result == EvaluationResult.approved ? AppColors.success : AppColors.error,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Submit Evaluation'),
        ),
      ],
    );
  }
}
