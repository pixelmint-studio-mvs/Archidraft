import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/legal_providers.dart';

class PrivacyRequestDialog extends ConsumerStatefulWidget {
  const PrivacyRequestDialog({super.key});

  @override
  ConsumerState<PrivacyRequestDialog> createState() => _PrivacyRequestDialogState();
}

class _PrivacyRequestDialogState extends ConsumerState<PrivacyRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _detailsController = TextEditingController();

  String _selectedType = 'DATA_ACCESS';
  bool _isSubmitting = false;
  String? _errorMessage;

  final Map<String, String> _typeLabels = {
    'DATA_ACCESS': 'Data Access / Export (DPDP Sec 11)',
    'DATA_CORRECTION': 'Data Correction / Update (DPDP Sec 11)',
    'DATA_ERASURE': 'Data Erasure / Deletion (DPDP Sec 12)',
    'GRIEVANCE': 'Grievance Redressal (IT SPDI Rule 5(9))',
  };

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(legalRepositoryProvider);
      await repo.submitPrivacyRequest(
        requestType: _selectedType,
        details: _detailsController.text.trim(),
      );

      ref.invalidate(myPrivacyRequestsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Privacy request submitted successfully.'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to submit request: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shield_outlined, color: AppColors.secondary, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Submit Privacy Request',
                        style: AppTypography.headlineSmMobile,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Exercise your data rights under the Digital Personal Data Protection Act 2023 and Information Technology Rules 2011.',
                  style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Request Type Dropdown
                Text(
                  'Request Category',
                  style: AppTypography.buttonText,
                ),
                const SizedBox(height: AppSpacing.xs),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: _typeLabels.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value, style: AppTypography.bodySm),
                    );
                  }).toList(),
                  onChanged: _isSubmitting ? null : (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Details Field
                Text(
                  'Request Details & Scope',
                  style: AppTypography.buttonText,
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _detailsController,
                  maxLines: 4,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    hintText: 'Please specify the exact records, corrections, or grievance points...',
                    hintStyle: AppTypography.bodySm.copyWith(color: AppColors.outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 5) {
                      return 'Please provide at least 5 characters of detail.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Statutory notice badge
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: AppColors.secondary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _selectedType == 'GRIEVANCE'
                              ? 'Statutory Deadline: IT SPDI Rule 5(9) prescribes resolution within 1 month (30 days). Operational target: 15 business days.'
                              : _selectedType == 'DATA_ERASURE'
                                  ? 'Erasure requests are logged under DPDP Sec 12. Operational target: 30 days pending verified legal identity.'
                                  : 'Data requests are logged under DPDP Sec 11. Operational target: 15 business days.',
                          style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _errorMessage!,
                    style: AppTypography.bodySm.copyWith(color: AppColors.error),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.onSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit Request'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
