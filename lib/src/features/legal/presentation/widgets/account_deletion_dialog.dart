import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/account_deletion_request.dart';
import '../../providers/legal_providers.dart';

/// Multi-step Account Deletion & Right to Erasure Dialog (§ 12 DPDPA)
///
/// Implements strict confirmation safeguards:
/// - Explains 30-day grace period and cancellation eligibility.
/// - Clarifies collaborative CAD drawing preservation for multi-party projects.
/// - Requires explicit checkboxes and typing "DELETE" to prevent accidental submission.
class AccountDeletionDialog extends ConsumerStatefulWidget {
  const AccountDeletionDialog({super.key});

  static Future<AccountDeletionRequest?> show(BuildContext context) {
    return showDialog<AccountDeletionRequest>(
      context: context,
      builder: (ctx) => const AccountDeletionDialog(),
    );
  }

  @override
  ConsumerState<AccountDeletionDialog> createState() => _AccountDeletionDialogState();
}

class _AccountDeletionDialogState extends ConsumerState<AccountDeletionDialog> {
  int _currentStep = 0;
  bool _understandsConsequences = false;
  bool _understandsAssetPreservation = false;
  final _reasonController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _canProceedStep1 => _understandsConsequences && _understandsAssetPreservation;
  bool get _canProceedStep2 => _confirmController.text.trim().toUpperCase() == 'DELETE';

  Future<void> _submitDeletion() async {
    if (!_canProceedStep2 || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(legalRepositoryProvider);
      final req = await repo.requestAccountDeletion(
        reason: _reasonController.text.trim().isNotEmpty ? _reasonController.text.trim() : null,
      );

      ref.invalidate(myAccountDeletionRequestsProvider);

      if (mounted) {
        Navigator.of(context).pop(req);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deletion request submitted. You have a 30-day grace period to cancel.'),
            backgroundColor: AppColors.secondary,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          final msg = e.toString().replaceAll('Exception: ', '');
          _errorMessage = msg.contains('409') || msg.contains('ALREADY_EXISTS')
              ? 'An active deletion request is already in progress for this account.'
              : 'Failed to submit deletion request: $msg';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
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
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Request Account Deletion', style: AppTypography.headlineSmMobile),
                        Text('Right to Erasure • Digital Personal Data Protection Act, 2023',
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

              // Multi-step content
              if (_currentStep == 0) _buildConsequencesStep(),
              if (_currentStep == 1) _buildConfirmationStep(),

              const SizedBox(height: AppSpacing.xl),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Keep Account'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (_currentStep == 0)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _canProceedStep1
                          ? () => setState(() => _currentStep = 1)
                          : null,
                      child: const Text('Continue \u2192'),
                    )
                  else ...[
                    OutlinedButton(
                      onPressed: _isSubmitting ? null : () => setState(() => _currentStep = 0),
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _canProceedStep2 && !_isSubmitting ? _submitDeletion : null,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Confirm Deletion Request'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsequencesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Please read the following consequences carefully:',
                  style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              _buildBullet('30-Day Grace Period: Your account will enter a 30-day review period during which you can cancel this request at any time.'),
              _buildBullet('Access Suspension: Upon confirmation, session access will be suspended to protect account integrity.'),
              _buildBullet('Collaborative CAD Deliverables: Drawings, floor plans, and project files created for active or completed commissions will be preserved in an anonymized format to protect the property rights of other project participants.'),
              _buildBullet('Statutory Retention: Invoices, payment records, and system security logs will be retained strictly in accordance with Indian tax and CERT-In regulatory requirements.'),
              _buildBullet('AI Chat & Ephemeral History: Private chat transcripts and session logs will be permanently purged.'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        CheckboxListTile(
          value: _understandsConsequences,
          activeColor: AppColors.error,
          title: Text(
            'I understand that my personal profile and account credentials will be scheduled for permanent erasure.',
            style: AppTypography.bodySm,
          ),
          contentPadding: EdgeInsets.zero,
          onChanged: (val) => setState(() => _understandsConsequences = val ?? false),
        ),
        CheckboxListTile(
          value: _understandsAssetPreservation,
          activeColor: AppColors.error,
          title: Text(
            'I understand that collaborative drawings created with other engineers or draughtsmen remain preserved in an anonymized state.',
            style: AppTypography.bodySm,
          ),
          contentPadding: EdgeInsets.zero,
          onChanged: (val) => setState(() => _understandsAssetPreservation = val ?? false),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Optional: Tell us why you are leaving',
          style: AppTypography.labelMonoSm.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _reasonController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'e.g. Closing practice, switching platforms, or completed training...',
            hintStyle: AppTypography.bodySm.copyWith(color: AppColors.outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To prevent accidental deletion, type DELETE below:',
                style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.bold, color: AppColors.error),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _confirmController,
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'DELETE',
                  hintStyle: AppTypography.bodySm.copyWith(color: AppColors.outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
          Expanded(child: Text(text, style: AppTypography.bodySm)),
        ],
      ),
    );
  }
}
