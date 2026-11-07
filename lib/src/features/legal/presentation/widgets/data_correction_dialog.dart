import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../domain/data_correction_request.dart';
import '../../providers/legal_providers.dart';

/// Personal Information Correction Request Dialog (§ 12 DPDPA)
///
/// Enables users to request administrative correction, completion, or updating
/// of sensitive legal profile fields (Name, Mobile, Postal Address, Qualifications).
class DataCorrectionDialog extends ConsumerStatefulWidget {
  const DataCorrectionDialog({super.key});

  static Future<DataCorrectionRequest?> show(BuildContext context) {
    return showDialog<DataCorrectionRequest>(
      context: context,
      builder: (ctx) => const DataCorrectionDialog(),
    );
  }

  @override
  ConsumerState<DataCorrectionDialog> createState() => _DataCorrectionDialogState();
}

class _DataCorrectionDialogState extends ConsumerState<DataCorrectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _proposedValueController = TextEditingController();
  final _reasonController = TextEditingController();

  String _selectedField = 'name';
  bool _isSubmitting = false;
  String? _errorMessage;

  final Map<String, String> _supportedFields = {
    'name': 'Full Legal Name',
    'mobile': 'Mobile Phone Number',
    'address': 'Primary Postal Address',
    'qualification': 'Educational / CAD Qualification',
  };

  @override
  void dispose() {
    _proposedValueController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  String _getCurrentValue(String field) {
    final profile = ref.read(userProfileProvider).value;
    if (profile == null) return 'Not available';

    switch (field) {
      case 'name':
        return profile.name.isNotEmpty ? profile.name : 'Not set';
      case 'mobile':
      case 'phone':
        return profile.mobile.isNotEmpty ? profile.mobile : 'Not set';
      case 'address':
        return profile.address != null && profile.address!.isNotEmpty ? profile.address! : 'Not set';
      case 'qualification':
        return profile.qualification != null && profile.qualification!.isNotEmpty ? profile.qualification! : 'Not set';
      default:
        return 'Not set';
    }
  }

  Future<void> _submitCorrection() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(legalRepositoryProvider);
      final req = await repo.requestDataCorrection(
        fieldName: _selectedField,
        proposedValue: _proposedValueController.text.trim(),
        reason: _reasonController.text.trim().isNotEmpty ? _reasonController.text.trim() : null,
      );

      ref.invalidate(myDataCorrectionRequestsProvider);

      if (mounted) {
        Navigator.of(context).pop(req);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Correction request submitted for administrative review.'),
            backgroundColor: AppColors.secondary,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to submit correction request: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentValue = _getCurrentValue(_selectedField);

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
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit_note_rounded, color: AppColors.secondary, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Correct My Information', style: AppTypography.headlineSmMobile),
                          Text('Right to Correction • Section 12 DPDPA, 2023',
                              style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(_errorMessage!,
                              style: AppTypography.bodySm.copyWith(color: AppColors.error)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Field Selector
                DropdownButtonFormField<String>(
                  initialValue: _selectedField,
                  decoration: InputDecoration(
                    labelText: 'Field to Correct',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: _supportedFields.entries.map((e) {
                    return DropdownMenuItem(value: e.key, child: Text(e.value));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedField = val);
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Current Value Display
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: AppColors.outline),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Current Recorded Value: $currentValue',
                          style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Proposed Value Input
                TextFormField(
                  controller: _proposedValueController,
                  decoration: InputDecoration(
                    labelText: 'Proposed Corrected Value *',
                    hintText: 'Enter accurate, verifiable information...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter the corrected value';
                    }
                    if (val.trim() == currentValue) {
                      return 'Proposed value is identical to current value';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Reason Input
                TextFormField(
                  controller: _reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Reason for Correction',
                    hintText: 'e.g. Typographical error, official name change, or updated credentials...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isSubmitting ? null : _submitCorrection,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
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
