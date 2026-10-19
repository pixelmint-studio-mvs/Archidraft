import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/domain/user_profile.dart';
import '../../../auth/providers/auth_providers.dart';

/// Architectural Identity & Credentials Card.
///
/// Implements the Architectural Precision System from `REFERENCE DESIGN/DESIGN.md`:
/// - High-contrast typography and subtle hairline borders.
/// - JetBrains Mono technical status chips and copyable UID.
/// - Detailed specification breakdown of account vitals.
class ProfileHeader extends ConsumerWidget {
  final UserProfile profile;

  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = profile.name.trim().isNotEmpty
        ? profile.name
            .trim()
            .split(' ')
            .take(2)
            .map((s) => s.isNotEmpty ? s[0] : '')
            .join()
            .toUpperCase()
        : '?';

    final authState = ref.watch(authControllerProvider);
    final isSigningOut = authState is AsyncLoading;

    final createdAtStr = profile.createdAt != null
        ? DateFormat('MMM dd, yyyy').format(profile.createdAt!)
        : 'Registered Draughtsman';

    final updatedAtStr = profile.updatedAt != null
        ? DateFormat('MMM dd, yyyy').format(profile.updatedAt!)
        : 'Up to date';

    final isDraughtsman = profile.role.toUpperCase() == 'DRAUGHTSMAN';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.6),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0D1C32),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: Color(0x080D1C32),
            offset: Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Tag
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Text(
                'ACCOUNT CREDENTIALS',
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.outline,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'STATUS: ACTIVE',
                      style: AppTypography.labelMono.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Avatar & Primary Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.outlineVariant,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: AppTypography.headlineLg.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name.isNotEmpty ? profile.name : 'Draughtsman User',
                      style: AppTypography.headlineLgMobile.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 14,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            profile.email,
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryFixed.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            'ROLE: ${profile.role.toUpperCase()}',
                            style: AppTypography.labelMono.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSecondaryFixedVariant,
                            ),
                          ),
                        ),
                        if (isDraughtsman)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              border: Border.all(
                                color: AppColors.outlineVariant.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Text(
                              'CAD / BIM SPEC',
                              style: AppTypography.labelMono.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // UID Copy Card
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.fingerprint_rounded,
                  size: 16,
                  color: AppColors.outline,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'UID: ${profile.id}',
                    style: AppTypography.labelMono.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  color: AppColors.secondary,
                  tooltip: 'Copy UID',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: profile.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User ID copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          const Divider(height: 1, color: AppColors.surfaceContainerHigh),
          const SizedBox(height: AppSpacing.lg),

          // Account Telemetry Specifications
          Text(
            'ACCOUNT SPECIFICATIONS',
            style: AppTypography.labelMono.copyWith(
              color: AppColors.outline,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSpecRow('Identity Provider', 'Firebase Auth (Cloud Verified)'),
          _buildSpecRow('Security Clearance', isDraughtsman ? 'Architectural Studio' : 'Client Access'),
          _buildSpecRow('Registration Date', createdAtStr),
          _buildSpecRow('Last Persisted Sync', updatedAtStr),

          const SizedBox(height: AppSpacing.xl),
          const Divider(height: 1, color: AppColors.surfaceContainerHigh),
          const SizedBox(height: AppSpacing.lg),

          // Security Information Box
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Identity & Access Security',
                        style: AppTypography.buttonText.copyWith(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your email and core authentication credentials are protected by Firebase Auth and Cloudflare D1 policies.',
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Sign Out Action
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSigningOut
                  ? null
                  : () {
                      ref.read(authControllerProvider.notifier).signOut();
                    },
              icon: isSigningOut
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.error,
                      ),
                    )
                  : const Icon(Icons.logout_rounded, size: 16, color: AppColors.error),
              label: Text(
                isSigningOut ? 'Signing Out...' : 'Sign Out of Studio',
                style: AppTypography.buttonText.copyWith(
                  color: AppColors.error,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppColors.error.withValues(alpha: 0.3),
                  width: 1.0,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.labelMono.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
