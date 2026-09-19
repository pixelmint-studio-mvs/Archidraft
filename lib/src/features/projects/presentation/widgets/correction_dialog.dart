import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_spacing.dart';

import '../../providers/project_providers.dart';

class CorrectionDialog extends ConsumerStatefulWidget {
  final String projectId;
  final String targetVersionId;

  const CorrectionDialog({
    super.key,
    required this.projectId,
    required this.targetVersionId,
  });

  @override
  ConsumerState<CorrectionDialog> createState() => _CorrectionDialogState();
}

class _CorrectionDialogState extends ConsumerState<CorrectionDialog> {
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final actionId = const Uuid().v4();
      final correctionId = const Uuid().v4();

      await ref
          .read(projectRepositoryProvider)
          .requestCorrection(
            projectId: widget.projectId,
            actionId: actionId,
            correctionId: correctionId,
            targetVersionId: widget.targetVersionId,
            description: description,
          );

      ref.invalidate(projectProvider(widget.projectId));
      ref.invalidate(projectCorrectionsProvider(widget.projectId));

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correction requested successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to request correction: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request Correction'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Please describe the changes you need.'),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Describe your correction...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => context.pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Submit Request'),
        ),
      ],
    );
  }
}
