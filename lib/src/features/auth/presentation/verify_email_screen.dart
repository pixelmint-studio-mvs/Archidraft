import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/blueprint_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/auth_providers.dart';

/// Email verification screen shown after registration or when an unverified
/// user logs in.
///
/// Styled to match the Stitch "Secure Verification" visual language:
///   - BlueprintBackground
///   - GlassCard with corner technical marks and top accent line
///   - JetBrains Mono label typography
///   - Stitch CTA button style
///
/// Functionality:
/// - Polling / manual "I've Verified" check (Firebase email link flow)
/// - Resend email with 60-second cooldown
/// - Log out
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isChecking = false;
  bool _isResending = false;

  /// Cooldown timer for the resend button (60 seconds).
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _resendCooldown = 60;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);

    final controller = ref.read(authControllerProvider.notifier);
    final isVerified = await controller.checkEmailVerified();

    if (!mounted) return;

    setState(() => _isChecking = false);

    if (isVerified) {
      // GoRouter redirect handles navigation on auth state change
      ref.invalidate(authStateChangesProvider);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email not yet verified. Please check your inbox or spam folder.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resendVerification() async {
    if (_resendCooldown > 0) return;

    setState(() => _isResending = true);

    final controller = ref.read(authControllerProvider.notifier);
    final success = await controller.sendEmailVerification();

    if (!mounted) return;

    setState(() => _isResending = false);

    if (success) {
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email resent. Please check your inbox.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to resend email. Please try again later.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final controller = ref.read(authControllerProvider.notifier);
    await controller.signOut();
    // GoRouter redirect handles navigation to /login
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final email = currentUser?.email ?? 'your email';
    final theme = Theme.of(context);

    return Scaffold(
      body: BlueprintBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
                vertical: AppSpacing.xxl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _VerificationCard(
                  email: email,
                  isChecking: _isChecking,
                  isResending: _isResending,
                  resendCooldown: _resendCooldown,
                  onCheckVerification: _checkVerification,
                  onResend: _resendVerification,
                  onLogout: _handleLogout,
                  theme: theme,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Verification Card — Stitch "Secure Verification" layout
// ─────────────────────────────────────────────────────────────
class _VerificationCard extends StatelessWidget {
  final String email;
  final bool isChecking;
  final bool isResending;
  final int resendCooldown;
  final VoidCallback onCheckVerification;
  final VoidCallback onResend;
  final VoidCallback onLogout;
  final ThemeData theme;

  const _VerificationCard({
    required this.email,
    required this.isChecking,
    required this.isResending,
    required this.resendCooldown,
    required this.onCheckVerification,
    required this.onResend,
    required this.onLogout,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Top accent line (Stitch detail)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusLg),
                  topRight: Radius.circular(AppSpacing.radiusLg),
                ),
              ),
            ),
          ),
          // Corner technical marks
          const Positioned(
            top: AppSpacing.xs,
            left: AppSpacing.xs,
            child: _TechCorner(topLeft: true),
          ),
          const Positioned(
            top: AppSpacing.xs,
            right: AppSpacing.xs,
            child: _TechCorner(topRight: true),
          ),
          const Positioned(
            bottom: AppSpacing.xs,
            left: AppSpacing.xs,
            child: _TechCorner(bottomLeft: true),
          ),
          const Positioned(
            bottom: AppSpacing.xs,
            right: AppSpacing.xs,
            child: _TechCorner(bottomRight: true),
          ),

          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // ── Brand heading ──
              Text(
                'ARCHI DRAFT',
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),

              Text(
                'Studio Verification',
                style: AppTypography.headlineLgMobile.copyWith(
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),

              Text(
                'IDENTITY CONFIRMATION',
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.outline,
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // ── Icon ──
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 36,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── Instruction text ──
              Text(
                'Enter the verification link sent to your registered email address.',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Email display ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ID: ',
                      style: AppTypography.labelMono.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        email,
                        style: AppTypography.labelMono.copyWith(
                          color: AppColors.secondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // ── Primary CTA ──
              _StitchCTA(
                onTap: isChecking ? null : onCheckVerification,
                isLoading: isChecking,
                label: "I'VE VERIFIED MY EMAIL",
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Resend ──
              Center(
                child: TextButton(
                  onPressed: (isResending || resendCooldown > 0)
                      ? null
                      : onResend,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                  ),
                  child: isResending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          resendCooldown > 0
                              ? 'Resend in ${resendCooldown}s'
                              : 'Resend Verification Email',
                          style: AppTypography.labelMono.copyWith(
                            color: resendCooldown > 0
                                ? AppColors.outline
                                : AppColors.secondary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Divider ──
              Divider(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
              const SizedBox(height: AppSpacing.lg),

              // ── Log out ──
              Center(
                child: TextButton(
                  onPressed: onLogout,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.outline,
                  ),
                  child: Text(
                    'LOG OUT',
                    style: AppTypography.labelMono.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stitch-style CTA button — primaryContainer fill, shimmer
// ─────────────────────────────────────────────────────────────
class _StitchCTA extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final String label;
  final IconData icon;

  const _StitchCTA({
    required this.onTap,
    required this.isLoading,
    required this.label,
    required this.icon,
  });

  @override
  State<_StitchCTA> createState() => _StitchCTAState();
}

class _StitchCTAState extends State<_StitchCTA> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: widget.onTap == null
                ? AppColors.surfaceVariant
                : (_hovered ? AppColors.primary : AppColors.primaryContainer),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                )
              else ...[
                Text(
                  widget.label,
                  style: AppTypography.buttonText.copyWith(
                    color: widget.onTap == null
                        ? AppColors.outline
                        : AppColors.onPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AnimatedSlide(
                  duration: const Duration(milliseconds: 200),
                  offset: _hovered ? const Offset(0.3, 0) : Offset.zero,
                  child: Icon(
                    widget.icon,
                    size: 18,
                    color: widget.onTap == null
                        ? AppColors.outline
                        : AppColors.onPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tech corner mark — Stitch login card decorative detail
// ─────────────────────────────────────────────────────────────
class _TechCorner extends StatelessWidget {
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  const _TechCorner({
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(12.0, 12.0),
      painter: _TechCornerPainter(
        color: AppColors.outlineVariant.withValues(alpha: 0.5),
        topLeft: topLeft,
        topRight: topRight,
        bottomLeft: bottomLeft,
        bottomRight: bottomRight,
      ),
    );
  }
}

class _TechCornerPainter extends CustomPainter {
  final Color color;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  const _TechCornerPainter({
    required this.color,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    if (topLeft) {
      canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
      canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
    }
    if (topRight) {
      canvas.drawLine(Offset(0, 0), Offset(size.width, 0), paint);
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width, size.height),
        paint,
      );
    }
    if (bottomLeft) {
      canvas.drawLine(
        Offset(0, size.height),
        Offset(size.width, size.height),
        paint,
      );
      canvas.drawLine(Offset(0, 0), Offset(0, size.height), paint);
    }
    if (bottomRight) {
      canvas.drawLine(
        Offset(0, size.height),
        Offset(size.width, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
