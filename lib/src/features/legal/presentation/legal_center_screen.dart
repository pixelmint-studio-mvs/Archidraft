import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../providers/legal_providers.dart';
import 'widgets/privacy_request_dialog.dart';

class LegalCenterScreen extends ConsumerStatefulWidget {
  const LegalCenterScreen({super.key});

  @override
  ConsumerState<LegalCenterScreen> createState() => _LegalCenterScreenState();
}

class _LegalCenterScreenState extends ConsumerState<LegalCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Legal & Privacy Center', style: AppTypography.headlineSmMobile),
        backgroundColor: Colors.white,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.secondary,
          tabs: const [
            Tab(icon: Icon(Icons.description_outlined), text: 'Policies & Terms'),
            Tab(icon: Icon(Icons.tune_outlined), text: 'Consent Preferences'),
            Tab(icon: Icon(Icons.shield_outlined), text: 'Data Rights & Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPoliciesTab(),
          _buildConsentPreferencesTab(),
          _buildPrivacyRequestsTab(),
        ],
      ),
    );
  }

  Widget _buildPoliciesTab() {
    final docsAsync = ref.watch(effectiveDocumentsListProvider);

    return docsAsync.when(
      loading: () => const AppLoadingIndicator(message: 'Loading active platform documents...'),
      error: (err, _) => AppErrorWidget(
        message: 'Could not load legal documents.',
        onRetry: () => ref.refresh(effectiveDocumentsListProvider),
      ),
      data: (docs) {
        if (docs.isEmpty) {
          return const AppEmptyState(
            title: 'No Documents Published',
            subtitle: 'Platform terms are currently being finalized.',
            icon: Icons.article_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                title: Text(doc.title, style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.bold)),
                subtitle: Text('Version ${doc.version} • Effective ${doc.effectiveAt?.split('T').first ?? 'Active'}', style: AppTypography.bodySm),
                children: [
                  Container(
                    height: 250,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SingleChildScrollView(
                        child: Text(
                          doc.content.isNotEmpty ? doc.content : 'Document content active on server.',
                          style: AppTypography.bodySm.copyWith(fontFamily: 'monospace'),
                        ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConsentPreferencesTab() {
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
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mandatory Agreements', style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSpacing.sm),
                    ListTile(
                      leading: Icon(
                        status.termsAccepted ? Icons.check_circle : Icons.warning_amber,
                        color: status.termsAccepted ? AppColors.success : AppColors.error,
                      ),
                      title: Text('Terms & Conditions', style: AppTypography.bodyMd),
                      subtitle: Text(
                        status.termsAccepted
                            ? 'Accepted Version ${status.acceptedTermsVersion}'
                            : (status.reacceptanceRequired ? 'Re-acceptance required for v${status.latestTermsVersion}' : 'Not Accepted'),
                        style: AppTypography.bodySm,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    ListTile(
                      leading: Icon(
                        status.privacyNoticeAcknowledged ? Icons.check_circle : Icons.info_outline,
                        color: status.privacyNoticeAcknowledged ? AppColors.success : AppColors.outline,
                      ),
                      title: Text('Privacy Policy Acknowledgment', style: AppTypography.bodyMd),
                      subtitle: Text(status.privacyNoticeAcknowledged ? 'Acknowledged' : 'Pending Review', style: AppTypography.bodySm),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Optional Data Processing Consents', style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'You can grant or withdraw optional consents at any time. Changes take effect immediately.',
                      style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const Divider(height: 24),
                    SwitchListTile(
                      value: marketingGranted,
                      title: Text('Marketing & Product Announcements', style: AppTypography.bodyMd),
                      subtitle: Text('Receive engineering insights and platform feature emails.', style: AppTypography.bodySm),
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.secondary,
                      onChanged: (val) async {
                        final repo = ref.read(legalRepositoryProvider);
                        await repo.updateConsent(purpose: 'MARKETING_COMMUNICATIONS', granted: val);
                        ref.invalidate(userLegalStatusProvider);
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      value: portfolioGranted,
                      title: Text('Public Showcase & Gallery Indexing', style: AppTypography.bodyMd),
                      subtitle: Text('Feature approved drawings and models in public design portfolios.', style: AppTypography.bodySm),
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.secondary,
                      onChanged: (val) async {
                        final repo = ref.read(legalRepositoryProvider);
                        await repo.updateConsent(purpose: 'PORTFOLIO_SHOWCASE', granted: val);
                        ref.invalidate(userLegalStatusProvider);
                      },
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

  Widget _buildPrivacyRequestsTab() {
    final requestsAsync = ref.watch(myPrivacyRequestsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const PrivacyRequestDialog(),
          );
        },
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Privacy Request'),
      ),
      body: requestsAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Loading your privacy requests...'),
        error: (err, _) => AppErrorWidget(
          message: 'Could not load privacy requests.',
          onRetry: () => ref.refresh(myPrivacyRequestsProvider),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return const AppEmptyState(
              title: 'No Active Privacy Requests',
              subtitle: 'You have not submitted any data access, correction, erasure, or grievance requests.',
              icon: Icons.shield_outlined,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              final isResolved = req.status == 'RESOLVED';

              Color statusColor = AppColors.secondary;
              if (isResolved) statusColor = AppColors.success;
              if (req.status == 'REJECTED') statusColor = AppColors.error;

              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              req.status,
                              style: AppTypography.labelMonoSm.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(req.id, style: AppTypography.labelMonoSm),
                          const Spacer(),
                          Text(
                            req.createdAt.split('T').first,
                            style: AppTypography.bodySm.copyWith(color: AppColors.outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        req.requestType.replaceAll('_', ' '),
                        style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(req.details, style: AppTypography.bodyMd),
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 16, color: AppColors.outline),
                          const SizedBox(width: 4),
                          Text(
                            'Target Date: ${req.operationalTargetDate.split(' ').first}',
                            style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'Basis: ${req.statutoryBasis}',
                            style: AppTypography.bodySm.copyWith(color: AppColors.outline),
                          ),
                        ],
                      ),
                      if (req.resolutionNotes != null && req.resolutionNotes!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Resolution Note: ${req.resolutionNotes}',
                            style: AppTypography.bodySm.copyWith(fontStyle: FontStyle.italic),
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
      ),
    );
  }
}
