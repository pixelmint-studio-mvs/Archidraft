import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/glass_card.dart';
import '../domain/user_profile.dart';
import '../providers/auth_providers.dart';

class RegistrationConfirmationScreen extends ConsumerStatefulWidget {
  const RegistrationConfirmationScreen({super.key});

  @override
  ConsumerState<RegistrationConfirmationScreen> createState() =>
      _RegistrationConfirmationScreenState();
}

class _RegistrationConfirmationScreenState
    extends ConsumerState<RegistrationConfirmationScreen> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    try {
      ref.invalidate(userProfileProvider);
      ref.invalidate(registrationStatusProvider);
      await ref.read(userProfileProvider.future);
      await ref.read(registrationStatusProvider.future);
    } catch (_) {
      // Handled by UI state
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) {
      context.go('/landing');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    final regStatusAsync = ref.watch(registrationStatusProvider);

    final UserProfile? profile = profileAsync.value;
    final Map<String, dynamic>? regStatus = regStatusAsync.value;

    final String status = profile?.verificationStatus ??
        (regStatus?['status'] as String? ?? 'PENDING');
    final String? rejectionReason = profile?.rejectionReason ??
        (regStatus?['rejection_reason'] as String?);

    final isPending = status == 'PENDING';
    final isRejected = status == 'REJECTED';
    final isApproved = status == 'APPROVED';

    final userName = profile?.name ?? (regStatus?['name'] as String? ?? 'User');
    final userEmail = profile?.email ?? (regStatus?['email'] as String? ?? '');
    final role = profile?.role ?? (regStatus?['role'] as String? ?? '');

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Brand
                      Text(
                        'ARCHI DRAFT',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Status Icon
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isRejected
                                ? AppColors.errorContainer.withValues(alpha: 0.3)
                                : (isApproved
                                    ? AppColors.primaryContainer.withValues(alpha: 0.3)
                                    : AppColors.secondaryContainer.withValues(alpha: 0.3)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isRejected
                                ? Icons.cancel_outlined
                                : (isApproved
                                    ? Icons.check_circle_outline
                                    : Icons.mark_email_read_outlined),
                            size: 44,
                            color: isRejected
                                ? AppColors.error
                                : (isApproved
                                    ? AppColors.primary
                                    : AppColors.secondary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Prominent Exact Confirmation Message
                      Text(
                        'Your Registration has been sent, Status Will Be updated soon',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Status Badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isRejected
                                ? AppColors.error.withValues(alpha: 0.12)
                                : (isApproved
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : Colors.amber.withValues(alpha: 0.15)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isRejected
                                  ? AppColors.error
                                  : (isApproved
                                      ? Colors.green
                                      : Colors.amber.shade700),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isRejected
                                    ? Icons.error_outline
                                    : (isApproved
                                        ? Icons.verified_outlined
                                        : Icons.hourglass_top_outlined),
                                size: 16,
                                color: isRejected
                                    ? AppColors.error
                                    : (isApproved
                                        ? Colors.green.shade800
                                        : Colors.amber.shade900),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isRejected
                                    ? 'REJECTED'
                                    : (isApproved ? 'APPROVED' : 'PENDING REVIEW'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 1.0,
                                  color: isRejected
                                      ? AppColors.error
                                      : (isApproved
                                          ? Colors.green.shade800
                                          : Colors.amber.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submission Details Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (userName.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_outline,
                                        size: 16, color: AppColors.outline),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Applicant: $userName',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (userEmail.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.email_outlined,
                                        size: 16, color: AppColors.outline),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Email: $userEmail',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (role.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.badge_outlined,
                                      size: 16, color: AppColors.outline),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Applied Role: $role',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Rejection Alert (if rejected)
                      if (isRejected) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.errorContainer.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: AppColors.error),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.info_outline,
                                      color: AppColors.error, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Registration Not Approved',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (rejectionReason != null &&
                                  rejectionReason.trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Reason: $rejectionReason',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                'Access to application features remains restricted. You may contact studio administration for assistance.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Explanatory Information Points
                      if (isPending) ...[
                        _buildInfoTile(
                          icon: Icons.check_circle_outline,
                          title: 'Submission Received',
                          description:
                              'Your registration information and supporting proof document have been received and stored securely.',
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoTile(
                          icon: Icons.admin_panel_settings_outlined,
                          title: 'Manual Admin Review',
                          description:
                              'Our Admin team is manually reviewing your submitted credentials and proof document.',
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoTile(
                          icon: Icons.lock_outline,
                          title: 'Access Restricted Until Approval',
                          description:
                              'Access to Archi Draft features will be granted only after explicit Admin approval.',
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoTile(
                          icon: Icons.email_outlined,
                          title: 'Email Notification',
                          description:
                              'You will receive an email at $userEmail when your registration status is updated.',
                          theme: theme,
                        ),
                        const SizedBox(height: 24),
                      ],

                      if (isApproved) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.green, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Registration Approved!',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: Colors.green.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Your account has been verified by the Admin. You may now proceed into the application.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => context.go('/'),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('PROCEED TO ARCHI DRAFT'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Actions
                      if (!isApproved) ...[
                        FilledButton.icon(
                          onPressed: _isRefreshing ? null : _handleRefresh,
                          icon: _isRefreshing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          label: Text(_isRefreshing
                              ? 'CHECKING STATUS...'
                              : 'REFRESH STATUS'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      OutlinedButton.icon(
                        onPressed: _handleSignOut,
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('SIGN OUT'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.outlineVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String description,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
