import 'package:flutter/material.dart';
import '../../../domain/evaluation.dart';

class EvaluationCard extends StatelessWidget {
  final Evaluation evaluation;

  const EvaluationCard({
    super.key,
    required this.evaluation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final isApproved = evaluation.overallResult == EvaluationResult.approved;
    final color = isApproved ? Colors.green : Colors.red;
    final icon = isApproved ? Icons.check_circle_outline : Icons.error_outline;
    final title = isApproved ? 'Evaluation: Approved' : 'Evaluation: Needs Correction';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatDate(evaluation.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (evaluation.generalFeedback != null && evaluation.generalFeedback!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Feedback',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                evaluation.generalFeedback!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (evaluation.criteria != null && evaluation.criteria!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Criteria Breakdown',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...evaluation.criteria!.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
