import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/data_export_request.dart';
import '../../providers/legal_providers.dart';

/// Personal Data Export Dialog (§ 11 DPDPA - Right to Access Personal Data)
///
/// Allows users to request a structured, machine-readable JSON copy of their
/// account profile, consent logs, project metadata, and transactions.
class DataExportDialog extends ConsumerStatefulWidget {
  const DataExportDialog({super.key});

  static Future<DataExportRequest?> show(BuildContext context) {
    return showDialog<DataExportRequest>(
      context: context,
      builder: (ctx) => const DataExportDialog(),
    );
  }

  @override
  ConsumerState<DataExportDialog> createState() => _DataExportDialogState();
}

class _DataExportDialogState extends ConsumerState<DataExportDialog> {
  String _selectedScope = 'FULL_PERSONAL_DATA';
  bool _isSubmitting = false;
  String? _errorMessage;

  final Map<String, String> _scopeDescriptions = {
    'FULL_PERSONAL_DATA': 'Full Profile & Activity Archive: Includes identity vitals, historical consent ledger, project drawing metadata, and billing records.',
    'CONSENTS_ONLY': 'Consent Ledger Only: Historical opt-in records, document version acceptances, timestamps, and IP hashes.',
    'ACTIVITY_ONLY': 'Project & Activity Metadata: Projects brief submissions, revision rounds, and assignment logs.',
  };

  Future<void> _submitExport() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(legalRepositoryProvider);
      final req = await repo.requestDataExport(exportScope: _selectedScope);

      ref.invalidate(myDataExportRequestsProvider);

      if (mounted) {
        Navigator.of(context).pop(req);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Personal data export requested. Archive will be generated shortly.'),
            backgroundColor: AppColors.secondary,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          final msg = e.toString().replaceAll('Exception: ', '');
          _errorMessage = msg.contains('409') || msg.contains('EXPORT_REQUEST_EXISTS')
              ? 'An active data export request is already in progress. Please wait for it to complete.'
              : 'Failed to request data export: $msg';
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
                    child: const Icon(Icons.download_for_offline_outlined, color: AppColors.secondary, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Download My Personal Data', style: AppTypography.headlineSmMobile),
                        Text('Digital Personal Data Protection Act, 2023 • Section 11',
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

              Text(
                'Select Export Scope',
                style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Data is packaged into a secure, machine-readable JSON archive. Download links remain valid for 7 days.',
                style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),

              ..._scopeDescriptions.entries.map((entry) {
                final isSelected = _selectedScope == entry.key;
                return InkWell(
                  onTap: () => setState(() => _selectedScope = entry.key),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.secondary : AppColors.outlineVariant.withValues(alpha: 0.6),
                        width: isSelected ? 1.5 : 1,
                      ),
                      color: isSelected ? AppColors.secondary.withValues(alpha: 0.04) : Colors.transparent,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? AppColors.secondary : AppColors.outline,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key.replaceAll('_', ' '),
                                style: AppTypography.buttonText.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(entry.value, style: AppTypography.bodySm),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: AppSpacing.lg),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Submit Export Request'),
                    onPressed: _isSubmitting ? null : _submitExport,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
