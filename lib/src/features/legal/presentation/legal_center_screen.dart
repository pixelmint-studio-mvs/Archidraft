import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/business_configuration.dart';
import '../domain/account_deletion_request.dart';
import '../domain/data_correction_request.dart';
import '../domain/data_export_request.dart';
import '../providers/legal_providers.dart';
import 'widgets/account_deletion_dialog.dart';
import 'widgets/data_correction_dialog.dart';
import 'widgets/data_export_dialog.dart';
import 'widgets/document_reader_sheet.dart';
import 'widgets/guardian_consent_dialog.dart';

class LegalCenterScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const LegalCenterScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<LegalCenterScreen> createState() => _LegalCenterScreenState();
}

class _LegalCenterScreenState extends ConsumerState<LegalCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 4),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'EFFECTIVE':
      case 'VERIFIED':
      case 'APPROVED':
      case 'COMPLETED':
        return AppColors.success;
      case 'PENDING_LEGAL_REVIEW':
      case 'UNDER_REVIEW':
        return Colors.orange.shade700;
      case 'PENDING_BUSINESS_APPROVAL':
      case 'PENDING_VERIFICATION':
      case 'PENDING':
      case 'SUBMITTED':
        return Colors.amber.shade800;
      case 'DRAFT':
        return AppColors.secondary;
      case 'REJECTED':
      case 'FAILED':
        return AppColors.error;
      case 'CANCELLED':
      case 'SUPERSEDED':
      case 'ARCHIVED':
      case 'WITHDRAWN':
      default:
        return AppColors.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Legal & Privacy Center', style: AppTypography.headlineSmMobile),
            Text(
              '${BusinessConfiguration.operatingBrand} • Data Protection & Governance',
              style: AppTypography.labelMonoSm.copyWith(color: AppColors.outline),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.secondary,
          tabs: const [
            Tab(icon: Icon(Icons.description_outlined), text: 'Documents Library'),
            Tab(icon: Icon(Icons.tune_outlined), text: 'Consent Preferences'),
            Tab(icon: Icon(Icons.folder_shared_outlined), text: 'My Personal Data'),
            Tab(icon: Icon(Icons.manage_accounts_outlined), text: 'Account Deletion'),
            Tab(icon: Icon(Icons.support_agent_outlined), text: 'Help & Grievance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDocumentsSection(),
          _buildConsentSection(),
          _buildMyDataSection(),
          _buildAccountDeletionSection(),
          _buildHelpGrievanceSection(),
        ],
      ),
    );
  }

  // =========================================================================
  // SECTION A: LEGAL DOCUMENTS LIBRARY
  // =========================================================================
  Widget _buildDocumentsSection() {
    final docsAsync = ref.watch(allCanonicalDocumentsProvider);

    return docsAsync.when(
      loading: () => const AppLoadingIndicator(message: 'Loading canonical legal documents...'),
      error: (err, _) => AppErrorWidget(
        message: 'Could not load legal documents library.',
        onRetry: () => ref.refresh(allCanonicalDocumentsProvider),
      ),
      data: (docs) {
        if (docs.isEmpty) {
          return const AppEmptyState(
            title: 'No Documents Found',
            subtitle: 'Platform agreements are currently synchronizing with the server.',
            icon: Icons.article_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final statusColor = _getStatusColor(doc.status);
            final isEffective = doc.status.toUpperCase() == 'EFFECTIVE';

            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.article_outlined, color: AppColors.secondary, size: 22),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doc.title, style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      doc.status.replaceAll('_', ' '),
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'v${doc.version}',
                                    style: AppTypography.labelMonoSm.copyWith(color: AppColors.outline),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    isEffective
                                        ? 'Effective ${doc.effectiveAt?.split('T').first ?? 'Active'}'
                                        : 'Awaiting Business Approval',
                                    style: AppTypography.bodySm.copyWith(
                                      color: isEffective ? AppColors.onSurfaceVariant : Colors.orange.shade800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => DocumentReaderSheet.show(context, doc),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('Read'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
                        ),
                      ],
                    ),
                    if (doc.changeSummary != null && doc.changeSummary!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Summary: ${doc.changeSummary}',
                          style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // SECTION B: CONSENT PREFERENCES
  // =========================================================================
  Widget _buildConsentSection() {
    final statusAsync = ref.watch(userLegalStatusProvider);

    return statusAsync.when(
      loading: () => const AppLoadingIndicator(message: 'Loading consent preferences...'),
      error: (err, _) => AppErrorWidget(
        message: 'Could not load consent preferences.',
        onRetry: () => ref.refresh(userLegalStatusProvider),
      ),
      data: (status) {
        final marketingGranted = status.optionalConsents['MARKETING_COMMUNICATIONS'] == true;
        final portfolioGranted = status.optionalConsents['PORTFOLIO_SHOWCASE'] == true;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Mandatory Section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user_outlined, color: AppColors.secondary, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Mandatory Platform Agreements',
                            style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Required to access drafting, collaboration, and CAD workspaces.',
                      style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      leading: Icon(
                        status.termsAccepted ? Icons.check_circle : Icons.warning_amber,
                        color: status.termsAccepted ? AppColors.success : AppColors.error,
                      ),
                      title: Text('Platform Terms and Conditions', style: AppTypography.bodyMd),
                      subtitle: Text(
                        status.termsAccepted
                            ? 'Affirmatively accepted (Version ${status.acceptedTermsVersion})'
                            : (status.reacceptanceRequired
                                ? 'Re-acceptance required for v${status.latestTermsVersion}'
                                : 'Pending Acceptance'),
                        style: AppTypography.bodySm,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        status.privacyNoticeAcknowledged ? Icons.check_circle : Icons.info_outline,
                        color: status.privacyNoticeAcknowledged ? AppColors.success : AppColors.outline,
                      ),
                      title: Text('Privacy Policy & Data Notice', style: AppTypography.bodyMd),
                      subtitle: Text(
                        status.privacyNoticeAcknowledged
                            ? 'Acknowledged and reviewed'
                            : 'Pending Acknowledgment',
                        style: AppTypography.bodySm,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Optional Section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune_rounded, color: AppColors.secondary, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Optional Data Processing Consents',
                            style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You can grant or withdraw optional consent at any time. Withdrawal does not affect your account or access to mandatory drafting tools.',
                      style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const Divider(height: 24),
                    SwitchListTile(
                      value: marketingGranted,
                      title: Text('Marketing & Product Announcements', style: AppTypography.bodyMd),
                      subtitle: Text('Receive drafting tips, engineering insights, and platform updates.',
                          style: AppTypography.bodySm),
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.secondary,
                      onChanged: (val) => _handleConsentToggle('MARKETING_COMMUNICATIONS', val, marketingGranted),
                    ),
                    const Divider(),
                    SwitchListTile(
                      value: portfolioGranted,
                      title: Text('Public Showcase & Portfolio Indexing', style: AppTypography.bodyMd),
                      subtitle: Text('Allow approved drawings and CAD models to be showcased in educational galleries.',
                          style: AppTypography.bodySm),
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.secondary,
                      onChanged: (val) => _handleConsentToggle('PORTFOLIO_SHOWCASE', val, portfolioGranted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleConsentToggle(String purpose, bool newValue, bool currentValue) async {
    final repo = ref.read(legalRepositoryProvider);

    if (!newValue && currentValue) {
      // Withdrawing consent requires confirmation
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Withdraw Optional Consent?'),
          content: Text(
            'Are you sure you want to withdraw consent for ${purpose.replaceAll('_', ' ')}? You will no longer receive these communications or indexing.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Confirm Withdrawal'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      await repo.withdrawOptionalConsent(purpose: purpose);
    } else {
      await repo.updateConsent(purpose: purpose, granted: newValue);
    }

    ref.invalidate(userLegalStatusProvider);
  }

  // =========================================================================
  // SECTION C: MY PERSONAL DATA (§ 11 & § 12 DPDPA)
  // =========================================================================
  Widget _buildMyDataSection() {
    final exportsAsync = ref.watch(myDataExportRequestsProvider);
    final correctionsAsync = ref.watch(myDataCorrectionRequestsProvider);
    final profile = ref.watch(userProfileProvider).value;
    final isStudent = profile?.role.toUpperCase() == 'STUDENT';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Actions Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Personal Data Rights Management',
                    style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'Exercise your rights to data portability, export, and profile field corrections under the Digital Personal Data Protection Act, 2023.',
                  style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Download My Data'),
                      onPressed: () => DataExportDialog.show(context),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.secondary),
                      icon: const Icon(Icons.edit_note_rounded, size: 16),
                      label: const Text('Correct Information'),
                      onPressed: () => DataCorrectionDialog.show(context),
                    ),
                    if (isStudent)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
                        icon: const Icon(Icons.escalator_warning_outlined, size: 16),
                        label: const Text('Guardian Consent'),
                        onPressed: () => GuardianConsentDialog.show(context),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Export Archives Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Data Export Archives', style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      onPressed: () => ref.invalidate(myDataExportRequestsProvider),
                    ),
                  ],
                ),
                const Divider(),
                exportsAsync.when(
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                  error: (e, _) => Text('Error loading exports: $e', style: AppTypography.bodySm),
                  data: (exports) {
                    if (exports.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text('No export requests yet. Click "Download My Data" above to generate a copy.',
                            style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
                      );
                    }
                    return Column(
                      children: exports.map((exp) => _buildExportItem(exp)).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Correction Requests Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Profile Correction Requests',
                        style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      onPressed: () => ref.invalidate(myDataCorrectionRequestsProvider),
                    ),
                  ],
                ),
                const Divider(),
                correctionsAsync.when(
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                  error: (e, _) => Text('Error loading corrections: $e', style: AppTypography.bodySm),
                  data: (corrections) {
                    if (corrections.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text('No correction requests. Click "Correct Information" to submit a change.',
                            style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
                      );
                    }
                    return Column(
                      children: corrections.map((cor) => _buildCorrectionItem(cor)).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        if (isStudent) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildGuardianConsentsCard(),
        ],
      ],
    );
  }

  Widget _buildExportItem(DataExportRequest exp) {
    final statusColor = _getStatusColor(exp.status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              exp.status,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exp.exportScope.replaceAll('_', ' '), style: AppTypography.buttonText),
                Text(
                  'Requested: ${exp.requestedAt.split('T').first}${exp.downloadUrlExpiresAt != null ? ' • Link Expires: ${exp.downloadUrlExpiresAt!.split(' ').first}' : ''}',
                  style: AppTypography.bodySm.copyWith(color: AppColors.outline),
                ),
              ],
            ),
          ),
          if (exp.isCompleted && exp.downloadR2Key != null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              icon: const Icon(Icons.file_download, size: 14),
              label: const Text('Download Archive'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Secure archive token active. Stored at: ${exp.downloadR2Key}'),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCorrectionItem(DataCorrectionRequest cor) {
    final statusColor = _getStatusColor(cor.status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  cor.status,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(cor.fieldLabel, style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(cor.createdAt.split('T').first, style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Proposed: "${cor.proposedValue}"', style: AppTypography.bodyMd),
          if (cor.reviewNotes != null && cor.reviewNotes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Admin Review Note: ${cor.reviewNotes}',
                style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant, fontStyle: FontStyle.italic)),
          ],
          const Divider(height: 16),
        ],
      ),
    );
  }

  Widget _buildGuardianConsentsCard() {
    final guardianAsync = ref.watch(myGuardianConsentsProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Student Guardian Consents (§ 9 DPDPA)',
                    style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: () => ref.invalidate(myGuardianConsentsProvider),
                ),
              ],
            ),
            const Divider(),
            guardianAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
              error: (e, _) => Text('Error loading guardian consents: $e', style: AppTypography.bodySm),
              data: (consents) {
                if (consents.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No guardian consent recorded. If you are under 18, submit your parent/guardian details.',
                        style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
                  );
                }
                return Column(
                  children: consents.map((g) {
                    final statusColor = _getStatusColor(g.verificationStatus);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.escalator_warning, color: statusColor),
                      title: Text('${g.guardianName} (${g.relationship})'),
                      subtitle: Text('Status: ${g.verificationStatus.replaceAll('_', ' ')} • Email: ${g.guardianEmail}'),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // SECTION D: ACCOUNT MANAGEMENT & DELETION
  // =========================================================================
  Widget _buildAccountDeletionSection() {
    final deletionAsync = ref.watch(myAccountDeletionRequestsProvider);

    return deletionAsync.when(
      loading: () => const AppLoadingIndicator(message: 'Loading deletion request status...'),
      error: (e, _) => AppErrorWidget(
        message: 'Could not load account status.',
        onRetry: () => ref.refresh(myAccountDeletionRequestsProvider),
      ),
      data: (requests) {
        final activeRequest = requests.where((r) => r.isCancellable).firstOrNull;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (activeRequest != null) _buildActiveDeletionBanner(activeRequest),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 24),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Permanent Account Deletion', style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.bold)),
                              Text('Right to Erasure • Section 12 Digital Personal Data Protection Act, 2023',
                                  style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      'Requesting account deletion will schedule your personal credentials and profile for permanent erasure after a 30-day statutory grace period.',
                      style: AppTypography.bodyMd,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Important Safeguards & Retained Records:',
                              style: AppTypography.labelMonoSm.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('• 30-Day Cancellation Window: You can cancel the deletion request at any time during the grace period.',
                              style: AppTypography.bodySm),
                          Text('• Collaborative CAD Drawings: Drawings and floor plans created for other clients or engineers are preserved in an anonymized state.',
                              style: AppTypography.bodySm),
                          Text('• Statutory Tax Records: Invoices and transaction records are retained for 8 years under Section 44AA of the Income Tax Act.',
                              style: AppTypography.bodySm),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (activeRequest == null)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Request Account Deletion'),
                        onPressed: () => AccountDeletionDialog.show(context),
                      )
                    else
                      Text(
                        'A deletion request is currently active. You can cancel it using the banner above.',
                        style: AppTypography.bodySm.copyWith(color: AppColors.outline),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (requests.isNotEmpty) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Deletion Request History', style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.bold)),
                      const Divider(),
                      ...requests.map((r) {
                        final color = _getStatusColor(r.status);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Status: ${r.status}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                          subtitle: Text('Submitted: ${r.submittedAt.split('T').first}${r.reason != null ? ' • Reason: ${r.reason}' : ''}'),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildActiveDeletionBanner(AccountDeletionRequest activeRequest) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hourglass_top_rounded, color: AppColors.error, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Account Scheduled for Deletion',
                    style: AppTypography.headlineSmMobile.copyWith(color: AppColors.error)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your account deletion request was submitted on ${activeRequest.submittedAt.split('T').first}. You are currently within the 30-day statutory grace period. You may cancel this request at any time to retain your account and active projects.',
            style: AppTypography.bodySm.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.undo_rounded, size: 16),
            label: const Text('Cancel Deletion Request'),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cancel Account Deletion?'),
                  content: const Text('Are you sure you want to cancel your deletion request? Your account access and project status will be fully restored.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Keep Deletion')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Yes, Cancel Deletion'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                final repo = ref.read(legalRepositoryProvider);
                await repo.cancelAccountDeletion(activeRequest.id);
                ref.invalidate(myAccountDeletionRequestsProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account deletion request successfully cancelled.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SECTION E: HELP & GRIEVANCE CONTACT
  // =========================================================================
  Widget _buildHelpGrievanceSection() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.corporate_fare_rounded, color: AppColors.secondary, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Legal Business Identity', style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.bold)),
                          Text(BusinessConfiguration.legalRepresentation,
                              style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildContactRow('Operating Brand', BusinessConfiguration.operatingBrand),
                _buildContactRow('Legal Proprietor', BusinessConfiguration.legalProprietor),
                _buildContactRow('Business Structure', BusinessConfiguration.structure),
                _buildContactRow('Product / Application', BusinessConfiguration.productName),
                _buildContactRow('Official Application Site', BusinessConfiguration.applicationWebsite),
                _buildContactRow('Business Website', BusinessConfiguration.businessWebsite),
                const Divider(height: 24),
                _buildContactRow('Customer Support Email', BusinessConfiguration.supportEmail),
                _buildContactRow('Privacy Request Email', BusinessConfiguration.privacyEmail),
                _buildContactRow('Grievance Redressal Email', BusinessConfiguration.grievanceEmail),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Statutory Verification Disclaimers
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Statutory Verification Notice', style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  'Physical Establishment Address: ${BusinessConfiguration.physicalAddressStatus}\n${BusinessConfiguration.physicalAddressNote}',
                  style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  'Grievance Officer Appointment: ${BusinessConfiguration.grievanceOfficerStatus}\n${BusinessConfiguration.grievanceOfficerNote}',
                  style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(label, style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
          ),
          Expanded(
            child: Text(value, style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
