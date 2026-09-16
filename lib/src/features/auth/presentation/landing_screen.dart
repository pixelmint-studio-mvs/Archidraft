import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/blueprint_background.dart';

/// Landing / Welcome screen.
///
/// Stitch reference: landing_experience_linked
/// Key design elements:
///   - Blueprint grid background (40px, #E4E2E4, 60% opacity)
///   - Top-right floating login icon button (glass pill)
///   - Hero: 280×280 glass logo panel (backdropFilter blur 20, white 60%)
///   - Headline: "Precision.\nDesign.\nDelivery." — 24px SemiBold Inter, centered
///   - Subtitle: bodyMd, onSurfaceVariant, centered
///   - CTA: "Start Submission →" full-width, primaryContainer bg, onPrimary text
///   - Stats bento grid: Projects Active (col-span-2) + Drawings Verified + Engineers Joined
///   - Footer: PixelMint Studio MVS credit, 11px, outline color
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlueprintBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // ── Scrollable main content ──
              SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: AppSpacing.marginMobile,
                  right: AppSpacing.marginMobile,
                  top:
                      AppSpacing.xxl +
                      AppSpacing.xl, // space below fixed header
                  bottom: AppSpacing.xxxl,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Hero: Logo Panel ──
                            _LogoPanel(),

                            const SizedBox(height: AppSpacing.xxl),

                            // ── Headline ──
                            Text(
                              'Precision.\nDesign.\nDelivery.',
                              style: AppTypography.headlineLgMobile.copyWith(
                                color: AppColors.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: AppSpacing.lg),

                            // ── Subtitle ──
                            Text(
                              'Rigorous engineering software for architects and structural designers.',
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: AppSpacing.blueprintUnit),

                            // ── CTA: Start Submission ──
                            _CtaButton(
                              label: 'Start Submission',
                              onPressed: () => context.push('/role-selection'),
                            ),

                            const SizedBox(height: AppSpacing.xxxl),

                            // ── Stats Bento Grid ──
                            _StatsBentoGrid(),

                            const SizedBox(height: AppSpacing.xxxl),

                            // ── Footer Credit ──
                            _FooterCredit(),

                            const SizedBox(height: AppSpacing.xl),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Fixed top-right: login icon button ──
              Positioned(
                top: AppSpacing.lg,
                right: AppSpacing.marginMobile,
                child: _LoginIconButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Logo Panel — glass card 280×280 with mix-blend-multiply logo
// ─────────────────────────────────────────────────────────────
class _LogoPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 280,
            height: 280,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: const Color(0x99FFFFFF), // 60% white — glass
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: const Color(0xCCFFFFFF), // 80% white border
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryContainer.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: AppColors.primaryContainer.withValues(alpha: 0.03),
                  blurRadius: 24,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/draughtsman_logo.jpeg',
              fit: BoxFit.contain,
              // mix-blend-multiply equivalent: use ColorFiltered to achieve
              // darkened blending on white background
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CTA Button — full-width, primaryContainer bg, arrow icon
// ─────────────────────────────────────────────────────────────
class _CtaButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _CtaButton({required this.label, required this.onPressed});

  @override
  State<_CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<_CtaButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.primary : AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.2),
                offset: const Offset(0, 1),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: AppTypography.buttonText.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedSlide(
                duration: const Duration(milliseconds: 200),
                offset: _hovered ? const Offset(0.3, 0) : Offset.zero,
                child: const Icon(
                  Icons.arrow_forward,
                  color: AppColors.onPrimary,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stats Bento Grid — 2-column grid, first card full-width
// ─────────────────────────────────────────────────────────────
class _StatsBentoGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Full-width card: Projects Active
        _StatCard(
          label: 'PROJECTS ACTIVE',
          value: '1,204',
          trailing: const Icon(
            Icons.architecture_outlined,
            size: 36,
            color: AppColors.primary,
          ),
          trend: '+12% this week',
          fullWidth: true,
        ),
        const SizedBox(height: AppSpacing.gridGutter),
        // Two half-width cards
        Row(
          children: [
            Expanded(
              child: _StatCard(label: 'DRAWINGS VERIFIED', value: '8.4k'),
            ),
            const SizedBox(width: AppSpacing.gridGutter),
            Expanded(
              child: _StatCard(label: 'ENGINEERS JOINED', value: '450+'),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;
  final String? trend;
  final bool fullWidth;

  const _StatCard({
    required this.label,
    required this.value,
    this.trailing,
    this.trend,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.surfaceVariant, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.03),
            blurRadius: 24,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.outline,
                  letterSpacing: 0.05 * 12,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: AppTypography.headlineLgMobile.copyWith(
                  color: AppColors.primary,
                ),
              ),
              if (trend != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 14,
                      color: AppColors.onTertiaryContainer,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      trend!,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onTertiaryContainer,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          if (trailing != null)
            Positioned(
              top: 0,
              right: 0,
              child: Opacity(opacity: 0.10, child: trailing!),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Footer Credit
// ─────────────────────────────────────────────────────────────
class _FooterCredit extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
          thickness: 1,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'UI/UX Design & Product Experience crafted by PixelMint Studio MVS',
          style: AppTypography.labelMono.copyWith(
            color: AppColors.outline,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Login Icon Button — top-right, glass pill
// Stitch: p-2, bg-surface-container-lowest/80, backdrop-blur-md,
//         rounded-full, border border-white/50, person icon
// ─────────────────────────────────────────────────────────────
class _LoginIconButton extends StatefulWidget {
  @override
  State<_LoginIconButton> createState() => _LoginIconButtonState();
}

class _LoginIconButtonState extends State<_LoginIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push('/login'),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: _hovered
                    ? AppColors.surfaceVariant.withValues(alpha: 0.9)
                    : AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.03),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
