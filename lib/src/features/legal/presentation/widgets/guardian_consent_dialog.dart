import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/guardian_consent.dart';
import '../../providers/legal_providers.dart';

/// Student Parental / Guardian Consent Dialog (§ 9 DPDPA - Student Safeguards)
///
/// Collects verifiable parental or lawful guardian information for students under 18.
class GuardianConsentDialog extends ConsumerStatefulWidget {
  const GuardianConsentDialog({super.key});

  static Future<GuardianConsent?> show(BuildContext context) {
    return showDialog<GuardianConsent>(
      context: context,
      builder: (ctx) => const GuardianConsentDialog(),
    );
  }

  @override
  ConsumerState<GuardianConsentDialog> createState() => _GuardianConsentDialogState();
}

class _GuardianConsentDialogState extends ConsumerState<GuardianConsentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedRelationship = 'Father';
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _relationships = [
    'Father',
    'Mother',
    'Legal Guardian',
    'Institutional Sponsor',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitGuardianConsent() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(legalRepositoryProvider);
      final consent = await repo.submitGuardianConsent(
        guardianName: _nameController.text.trim(),
        guardianEmail: _emailController.text.trim(),
        guardianPhone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        relationship: _selectedRelationship,
      );

      ref.invalidate(myGuardianConsentsProvider);

      if (mounted) {
        Navigator.of(context).pop(consent);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guardian consent submitted. Verification pending official review.'),
            backgroundColor: AppColors.secondary,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to submit guardian consent: ${e.toString().replaceAll('Exception: ', '')}';
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
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.escalator_warning_rounded, color: AppColors.secondary, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Parental / Guardian Consent', style: AppTypography.headlineSmMobile),
                          Text('Under-18 Student Safeguard • Section 9 DPDPA, 2023',
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

                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'Pursuant to Section 9 of the DPDP Act 2023, vocational drafting students under 18 require verifiable parental or legal guardian consent before participating in commercial live client training briefs.',
                    style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Guardian Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Parent / Legal Guardian Full Name *',
                    hintText: 'e.g. S. Mohammed Ibrahim',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Please enter guardian full legal name' : null,
                ),
                const SizedBox(height: AppSpacing.md),

                // Guardian Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Parent / Guardian Email Address *',
                    hintText: 'guardian@example.com',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter guardian email';
                    if (!val.contains('@') || !val.contains('.')) return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Guardian Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Guardian Phone Number (Optional)',
                    hintText: '+91 98765 43210',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Relationship Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedRelationship,
                  decoration: InputDecoration(
                    labelText: 'Relationship to Student',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: _relationships.map((rel) {
                    return DropdownMenuItem(value: rel, child: Text(rel));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRelationship = val);
                  },
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
                      onPressed: _isSubmitting ? null : _submitGuardianConsent,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit Guardian Consent'),
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
