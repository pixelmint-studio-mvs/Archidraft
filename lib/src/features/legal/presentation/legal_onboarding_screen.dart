import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../../profile/domain/user_role.dart';
import '../../profile/providers/profile_providers.dart';
import '../domain/legal_document.dart';
import '../providers/legal_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/authoritative_policy_content.dart';
import 'widgets/legal_markdown_viewer.dart';

class LegalOnboardingScreen extends ConsumerStatefulWidget {
  final bool isPreLogin;
  final String? preLoginRole;

  const LegalOnboardingScreen({
    super.key,
    this.isPreLogin = false,
    this.preLoginRole,
  });

  /// Distinguishes genuine network connection failures from HTTP or application-level errors.
  static String mapLegalErrorMessage(Object? error) {
    final errStr = error?.toString() ?? '';
    final lower = errStr.toLowerCase();
    final isNetworkError = lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection reset') ||
        lower.contains('connection refused') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection') ||
        lower.contains('timeout');

    if (isNetworkError) {
      return 'Unable to reach legal policy service. Please check network connection.';
    }
    if (lower.contains('api error')) {
      return 'Legal policy service error: $errStr. Please try again.';
    }
    return 'Unable to reach legal policy service. Please check network connection.';
  }

  @override
  ConsumerState<LegalOnboardingScreen> createState() => _LegalOnboardingScreenState();
}

class _LegalOnboardingScreenState extends ConsumerState<LegalOnboardingScreen> {
  bool _termsAgreed = false;
  bool _privacyAcknowledged = true;
  bool _marketingConsent = false;
  bool _portfolioConsent = false;

  bool _isSubmitting = false;
  String? _submissionError;

  @override
  void initState() {
    super.initState();
    if (!widget.isPreLogin) {
      final preLogin = ref.read(preLoginTermsProvider);
      if (preLogin.accepted) {
        _termsAgreed = true;
        _marketingConsent = preLogin.marketingConsent;
        _portfolioConsent = preLogin.portfolioConsent;
      }
    }
  }

  void _navigateToRoleDashboard() {
    final role = ref.read(currentUserRoleProvider);
    final isProfileComplete = ref.read(isProfileCompleteProvider);

    if (role == UserRole.engineer || role == UserRole.client) {
      context.go('/engineer/projects');
    } else if (role == UserRole.draughtsman) {
      context.go(isProfileComplete ? '/draughtsman/studio' : '/draughtsman/onboarding');
    } else if (role == UserRole.student) {
      context.go('/student/dashboard');
    } else if (role == UserRole.admin) {
      context.go('/admin/dashboard');
    } else {
      context.go('/');
    }
  }

  Future<void> _handleAcceptance(LegalDocument? termsDoc, LegalDocument? privacyDoc) async {
    if (!_termsAgreed && termsDoc != null) return;

    if (widget.isPreLogin) {
      final role = widget.preLoginRole ?? ref.read(preLoginTermsProvider).role ?? 'ENGINEER';
      ref.read(preLoginTermsProvider.notifier).acceptTerms(
        role: role,
        marketingConsent: _marketingConsent,
        portfolioConsent: _portfolioConsent,
      );
      if (mounted) {
        context.push('/login', extra: role);
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    try {
      final repo = ref.read(legalRepositoryProvider);

      // 1. Accept mandatory platform terms
      final effectiveTerms = (termsDoc != null && termsDoc.content.trim().length > 50)
          ? termsDoc
          : kDefaultEffectiveTermsDocument;
      await repo.acceptTerms(
        documentId: effectiveTerms.id,
        version: effectiveTerms.version,
      );

      // 2. Acknowledge privacy notice
      if (_privacyAcknowledged) {
        final effectivePriv = (privacyDoc != null && privacyDoc.content.trim().length > 50)
            ? privacyDoc
            : kDefaultEffectivePrivacyDocument;
        await repo.acknowledgePrivacy(
          documentId: effectivePriv.id,
          version: effectivePriv.version,
        );
      }

      // 3. Record optional purpose-specific consents
      await repo.updateConsent(
        purpose: 'MARKETING_COMMUNICATIONS',
        granted: _marketingConsent,
        documentId: privacyDoc?.id,
        version: privacyDoc?.version,
      );

      await repo.updateConsent(
        purpose: 'PORTFOLIO_SHOWCASE',
        granted: _portfolioConsent,
        documentId: privacyDoc?.id,
        version: privacyDoc?.version,
      );

      // Invalidate legal status so router immediately allows navigation
      ref.invalidate(userLegalStatusProvider);

      if (mounted) {
        _navigateToRoleDashboard();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submissionError = 'Failed to record legal acceptance. Please verify your connection and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final termsDocAsync = ref.watch(effectiveDocumentProvider('TERMS_AND_CONDITIONS'));
    final privacyDocAsync = ref.watch(effectiveDocumentProvider('PRIVACY_POLICY'));

    Widget bodyContent;
    if (widget.isPreLogin) {
      bodyContent = termsDocAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Loading Terms of Service...'),
        error: (err, _) => _buildCard(
          context: context,
          termsDoc: kDefaultEffectiveTermsDocument,
          privacyDocAsync: privacyDocAsync,
          isReacceptance: false,
          isPreLogin: true,
        ),
        data: (termsDoc) => _buildCard(
          context: context,
          termsDoc: (termsDoc != null && termsDoc.content.trim().length > 50)
              ? termsDoc
              : kDefaultEffectiveTermsDocument,
          privacyDocAsync: privacyDocAsync,
          isReacceptance: false,
          isPreLogin: true,
        ),
      );
    } else {
      final legalStatusAsync = ref.watch(userLegalStatusProvider);
      bodyContent = legalStatusAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Checking platform policy status...'),
        error: (err, _) => AppErrorWidget(
          message: LegalOnboardingScreen.mapLegalErrorMessage(err),
          onRetry: () => ref.refresh(userLegalStatusProvider),
        ),
        data: (legalStatus) {
          // If mandatory documents are missing in DB, provide graceful recoverable path
          if (legalStatus.missingMandatoryDocs) {
            return _buildMaintenanceCard(context);
          }

          return termsDocAsync.when(
            loading: () => const AppLoadingIndicator(message: 'Loading Terms of Service...'),
            error: (err, _) => AppErrorWidget(
              message: 'Could not load platform terms document.',
              onRetry: () => ref.refresh(effectiveDocumentProvider('TERMS_AND_CONDITIONS')),
            ),
            data: (termsDoc) => _buildCard(
              context: context,
              termsDoc: termsDoc,
              privacyDocAsync: privacyDocAsync,
              isReacceptance: legalStatus.reacceptanceRequired,
              isPreLogin: false,
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xxl,
            ),
            child: bodyContent,
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required LegalDocument? termsDoc,
    required AsyncValue<LegalDocument?> privacyDocAsync,
    required bool isReacceptance,
    required bool isPreLogin,
  }) {
    final isTrivialTerms = termsDoc == null ||
        termsDoc.content.trim().isEmpty ||
        termsDoc.content.trim() == '# Terms and Conditions' ||
        termsDoc.content.trim() == '# Terms' ||
        termsDoc.content.trim() == 'Platform Terms of Service content...';
    final termsContent = isTrivialTerms
        ? kAuthoritativeTermsAndConditionsContent
        : termsDoc.content;
    final termsVersion = (termsDoc != null && termsDoc.version.isNotEmpty)
        ? termsDoc.version
        : kAuthoritativeTermsVersion;
    final termsTitle = (termsDoc != null && termsDoc.title.isNotEmpty)
        ? termsDoc.title
        : kAuthoritativeTermsTitle;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isPreLogin) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/role-selection');
                    }
                  },
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back to Role Selection'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Header badge & title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.gavel_rounded, color: AppColors.secondary, size: 28),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isReacceptance
                            ? 'Updated Platform Terms & Conditions'
                            : 'Welcome to ARCHI DRAFT',
                        style: AppTypography.headlineLgMobile.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isReacceptance
                            ? 'We have updated our terms. Please review and accept the latest version to proceed.'
                            : (isPreLogin
                                ? 'Please review and accept our platform policies to proceed to login.'
                                : 'Please review and accept our platform policies to activate your workspace.'),
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 36),

            // SECTION 1: MANDATORY TERMS
            _buildDocumentPreviewCard(
              title: termsTitle,
              version: termsVersion,
              isMandatory: true,
              content: termsContent,
              effectiveDate: termsDoc?.effectiveAt,
            ),
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              value: _termsAgreed,
              onChanged: (_isSubmitting || termsContent.trim().isEmpty)
                  ? null
                  : (val) => setState(() => _termsAgreed = val ?? false),
              title: Text(
                'I have read, understood, and unconditionally agree to the Terms and Conditions (v$termsVersion).',
                style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.secondary,
            ),
            const SizedBox(height: AppSpacing.xl),

            // SECTION 2: PRIVACY NOTICE
            privacyDocAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => _buildPrivacyPreviewSection(
                privacyDoc: kDefaultEffectivePrivacyDocument,
              ),
              data: (privacyDoc) => _buildPrivacyPreviewSection(
                privacyDoc: privacyDoc ?? kDefaultEffectivePrivacyDocument,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // SECTION 3: UNBUNDLED OPTIONAL CONSENTS
            Material(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune_rounded, size: 20, color: AppColors.secondary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Optional Preferences (Defaults to OFF)',
                          style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'These optional items are completely separate from your mandatory platform access.',
                      style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SwitchListTile(
                      value: _marketingConsent,
                      onChanged: _isSubmitting ? null : (val) => setState(() => _marketingConsent = val),
                      title: const Text('Product Updates & Engineering Insights'),
                      subtitle: const Text('Receive occasional email announcements regarding feature releases.'),
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.secondary,
                    ),
                    const Divider(),
                    SwitchListTile(
                      value: _portfolioConsent,
                      onChanged: _isSubmitting ? null : (val) => setState(() => _portfolioConsent = val),
                      title: const Text('Public Portfolio & Showcase Indexing'),
                      subtitle: const Text('Allow verified showcase projects to be highlighted in community galleries.'),
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.secondary,
                    ),
                  ],
                ),
              ),
            ),

            if (_submissionError != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _submissionError!,
                        style: AppTypography.bodyMd.copyWith(color: AppColors.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xxl),

            // Accept button
            ElevatedButton(
              onPressed: (!_termsAgreed || _isSubmitting)
                  ? null
                  : () => _handleAcceptance(termsDoc, privacyDocAsync.value),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      isPreLogin
                          ? 'Agree & Continue to Login'
                          : (isReacceptance ? 'Accept Updated Terms & Continue' : 'Agree & Enter Workspace'),
                      style: AppTypography.buttonText.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),

            if (isPreLogin) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/role-selection');
                        }
                      },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Decline & Return to Role Selection'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyPreviewSection({required LegalDocument privacyDoc}) {
    final isTrivialPrivacy = privacyDoc.content.trim().isEmpty ||
        privacyDoc.content.trim() == 'Digital Personal Data Protection and Privacy Notice...' ||
        privacyDoc.content.trim() == '# Privacy Policy';
    final privContent = isTrivialPrivacy
        ? kAuthoritativePrivacyPolicyContent
        : privacyDoc.content;
    final privVersion = privacyDoc.version.isNotEmpty
        ? privacyDoc.version
        : kAuthoritativePrivacyVersion;
    final privTitle = privacyDoc.title.isNotEmpty
        ? privacyDoc.title
        : kAuthoritativePrivacyTitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDocumentPreviewCard(
          title: privTitle,
          version: privVersion,
          isMandatory: false,
          content: privContent,
          effectiveDate: privacyDoc.effectiveAt,
        ),
        const SizedBox(height: AppSpacing.md),
        CheckboxListTile(
          value: _privacyAcknowledged,
          onChanged: _isSubmitting ? null : (val) => setState(() => _privacyAcknowledged = val ?? false),
          title: Text(
            'I acknowledge receipt of the Privacy Notice explaining data processing under the DPDP Act 2023.',
            style: AppTypography.bodyMd,
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.secondary,
        ),
      ],
    );
  }

  Widget _buildDocumentPreviewCard({
    required String title,
    required String version,
    required bool isMandatory,
    required String content,
    String? effectiveDate,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: ExpansionTile(
        initiallyExpanded: isMandatory,
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isMandatory ? AppColors.secondary.withValues(alpha: 0.1) : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'v$version',
                style: AppTypography.labelMono.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isMandatory ? AppColors.secondary : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        subtitle: effectiveDate != null
            ? Text(
                'Effective: ${effectiveDate.split('T').first}',
                style: AppTypography.labelMonoSm.copyWith(color: AppColors.outline),
              )
            : null,
        children: [
          Container(
            height: 180,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SingleChildScrollView(
              child: LegalMarkdownViewer(
                markdown: content,
                isBold: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCard(BuildContext context) {
    final role = ref.watch(currentUserRoleProvider);
    final isAdmin = role == UserRole.admin;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.engineering_outlined, size: 48, color: AppColors.secondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Policy Maintenance in Progress',
              style: AppTypography.headlineSmMobile.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Mandatory platform terms are currently being published by the administration. Protected workspace operations are paused pending publication of effective terms.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(userLegalStatusProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Check for Updates'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/admin/dashboard'),
                    icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                    label: const Text('Open Admin Console'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
