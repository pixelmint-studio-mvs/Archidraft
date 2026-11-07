import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/user_profile.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import 'widgets/profile_form.dart';
import 'widgets/profile_header.dart';
import 'package:go_router/go_router.dart';
import 'widgets/student_credentials_card.dart';
import 'widgets/student_achievements_card.dart';
import '../../legal/presentation/widgets/document_reader_sheet.dart';
import '../../legal/presentation/widgets/account_deletion_dialog.dart';
import '../../legal/data/authoritative_policy_content.dart';

// ---------------------------------------------------------------------------
// BLUEPRINT GRID BACKGROUND PAINTER (40px unit from DESIGN.md)
// ---------------------------------------------------------------------------

class _BlueprintGridBackgroundPainter extends CustomPainter {
  const _BlueprintGridBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const double gridSize = 40.0;
    final gridPaint = Paint()
      ..color = const Color(0xFF75777E).withValues(alpha: 0.05)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// PROFILE SCREEN
// ---------------------------------------------------------------------------

/// Panel 10 — Profile Screen for Draughtsman (and authenticated users).
///
/// Implements the Architectural Precision System from `REFERENCE DESIGN/DESIGN.md`:
/// - Warm white `#FBF9FB` drafting canvas with 40px blueprint grid lines.
/// - Pure white surface cards with dual soft elevation shadows.
/// - JetBrains Mono for technical codes, tags, and timestamps.
/// - Responsive two-column bento on desktop (>=960px) and fluid single column on mobile.
/// - Zero redundant inner AppBars when wrapped inside shell.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomPaint(
        painter: const _BlueprintGridBackgroundPainter(),
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userProfileProvider);
          },
          child: profileAsync.when(
            loading: () => const AppLoadingIndicator(
              message: 'Loading draughtsman profile...',
            ),
            error: (err, stack) => AppErrorWidget(
              message: 'Failed to load profile. Please verify your connection.',
              onRetry: () => ref.refresh(userProfileProvider),
            ),
            data: (profile) {
              if (profile == null) {
                return const AppEmptyState(
                  title: 'Profile Not Found',
                  subtitle:
                      'We could not find your profile information. Please log in again.',
                  icon: Icons.person_off_outlined,
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 960;
                  final horizontalPadding = isDesktop
                      ? AppSpacing.marginDesktop
                      : AppSpacing.marginMobile;

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Architectural Breadcrumb & Header
                        _buildScreenHeader(context, ref, profile, isDesktop),
                        const SizedBox(height: AppSpacing.xl),

                        // Responsive Content Layout
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column: Identity & Specification Card
                              SizedBox(
                                width: 360,
                                child: ProfileHeader(profile: profile),
                              ),
                              const SizedBox(width: AppSpacing.xl),

                              // Right Column: Personal & Professional Vitals Form
                              Expanded(
                                child: ProfileForm(profile: profile),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Identity & Specification Card
                              ProfileHeader(profile: profile),
                              const SizedBox(height: AppSpacing.xl),

                              // Form
                              ProfileForm(profile: profile),
                            ],
                          ),

                        if (profile.role.toUpperCase() == 'STUDENT') ...[
                          const SizedBox(height: AppSpacing.xl),
                          const StudentAchievementsCard(),
                          const SizedBox(height: AppSpacing.xl),
                          const StudentCredentialsCard(),
                          const SizedBox(height: AppSpacing.xl),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => context.push('/student/portfolio'),
                              icon: const Icon(Icons.work_outline),
                              label: const Text('View Full Student Portfolio \u2192'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        _buildLegalPrivacyCard(context),
                        const SizedBox(height: AppSpacing.xxxl),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildScreenHeader(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    bool isDesktop,
  ) {
    final roleUpper = profile.role.toUpperCase();
    final isDraughtsman = roleUpper == 'DRAUGHTSMAN';
    final isStudent = roleUpper == 'STUDENT';
    final rolePrefix = isStudent ? 'STUDENT' : (isDraughtsman ? 'DRAUGHTSMAN' : 'CLIENT');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Technical Breadcrumb Row
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                const Icon(
                  Icons.architecture_rounded,
                  size: 16,
                  color: AppColors.secondary,
                ),
                Text(
                  '$rolePrefix  /  PROFILE & SETTINGS',
                  style: AppTypography.labelMono.copyWith(
                    color: AppColors.outline,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            if (isDesktop)
              OutlinedButton.icon(
                onPressed: () {
                  ref.invalidate(userProfileProvider);
                },
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Refresh Data'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSurfaceVariant,
                  side: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.6),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: AppTypography.labelMono.copyWith(fontSize: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusDefault),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Main Title & Subtitle
        Text(
          isStudent ? 'Student Profile & Learning Credentials' : (isDraughtsman ? 'Draughtsman Profile & Account Settings' : 'User Profile & Settings'),
          style: isDesktop
              ? AppTypography.headlineLg.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                )
              : AppTypography.headlineLgMobile.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isStudent ? 'Manage your training profile, track earned certificates, and review your drafting skill matrix.' : (isDraughtsman ? 'Manage your architectural draughtsman credentials, studio contact information, and verified CAD qualifications.' : 'Manage your profile details and studio project contact preferences.'),
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLegalPrivacyCard(BuildContext context) {
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
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppColors.secondary, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LEGAL & PRIVACY',
                        style: AppTypography.labelMono.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Manage your legal agreements, personal information and privacy preferences.',
                        style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.hub_outlined, color: AppColors.secondary),
              title: Text('Legal & Privacy Center', style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text('View platform compliance status, document versions, and contact details.', style: AppTypography.bodySm),
              trailing: const Icon(Icons.chevron_right),
              contentPadding: EdgeInsets.zero,
              onTap: () => context.push('/legal/center'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.description_outlined, color: AppColors.onSurfaceVariant),
              title: Text('Terms and Conditions', style: AppTypography.bodyMd),
              subtitle: Text('Read the active Platform Terms and Conditions agreement.', style: AppTypography.bodySm),
              trailing: const Icon(Icons.open_in_new, size: 18, color: AppColors.outline),
              contentPadding: EdgeInsets.zero,
              onTap: () => DocumentReaderSheet.show(context, kDefaultEffectiveTermsDocument),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.onSurfaceVariant),
              title: Text('Privacy Policy & Data Notice', style: AppTypography.bodyMd),
              subtitle: Text('Review data collection, processing purposes, and DPDPA rights.', style: AppTypography.bodySm),
              trailing: const Icon(Icons.open_in_new, size: 18, color: AppColors.outline),
              contentPadding: EdgeInsets.zero,
              onTap: () => DocumentReaderSheet.show(context, kDefaultEffectivePrivacyDocument),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.folder_shared_outlined, color: AppColors.onSurfaceVariant),
              title: Text('My Data & Privacy Requests', style: AppTypography.bodyMd),
              subtitle: Text('Export your personal data or request corrections under Section 11/12 DPDPA.', style: AppTypography.bodySm),
              trailing: const Icon(Icons.chevron_right),
              contentPadding: EdgeInsets.zero,
              onTap: () => context.push('/legal/center'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: Text('Account Deletion', style: AppTypography.bodyMd.copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
              subtitle: Text('Request erasure of your account with a 30-day statutory grace period.', style: AppTypography.bodySm),
              trailing: const Icon(Icons.chevron_right, color: AppColors.error),
              contentPadding: EdgeInsets.zero,
              onTap: () => AccountDeletionDialog.show(context),
            ),
          ],
        ),
      ),
    );
  }
}

