import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/blueprint_background.dart';

/// Landing / Welcome screen.
///
/// Faithfully reproduces:
/// - REFERENCE DESIGN/stitch_draughtsman_studio_os/stitch_draughtsman_studio_os/landing_experience/code.html
/// - REFERENCE DESIGN/stitch_draughtsman_studio_os/stitch_draughtsman_studio_os/landing_experience_linked/code.html
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
      begin: const Offset(0, 0.04),
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
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlueprintBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // ── Atmospheric Architectural Construction Lines ──
              Positioned.fill(
                child: CustomPaint(
                  painter: _ConstructionLinesPainter(),
                ),
              ),

              // ── Scrollable main content (max-w-lg / 512px) ──
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop
                      ? AppSpacing.marginDesktop
                      : AppSpacing.marginMobile,
                  vertical: 32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 512),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),

                            // ── Hero: Logo Glass Panel (max-w-[280px]) ──
                            const _LogoPanel(),

                            const SizedBox(height: 32),

                            // ── Headline: Precision. Design. Delivery. ──
                            Text(
                              'Precision.\nDesign.\nDelivery.',
                              style: AppTypography.headlineDisplay.copyWith(
                                color: AppColors.primary,
                                fontSize: isDesktop ? 44.0 : 32.0,
                                height: 1.15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: isDesktop ? -0.88 : -0.64,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 16),

                            // ── Subtitle ──
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 380),
                                child: Text(
                                  'Rigorous engineering software for architects and structural designers.',
                                  style: AppTypography.bodyMd.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontSize: 16,
                                    height: 1.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),

                            const SizedBox(height: 36),

                            // ── CTA: Start Submission ──
                            _CtaButton(
                              label: 'Start Submission',
                              onPressed: () => context.push('/role-selection'),
                            ),

                            const SizedBox(height: 48),

                            // ── Live Stats Bento Grid ──
                            const _StatsBentoGrid(),

                            const SizedBox(height: 48),

                            // ── Footer Credit ──
                            const _FooterCredit(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Fixed top-right: circular glass person icon button ──
              Positioned(
                top: 16,
                right: isDesktop
                    ? AppSpacing.marginDesktop
                    : AppSpacing.marginMobile,
                child: const _LoginCircularIconButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logo glass panel matching code.html:
/// w-full max-w-[280px] aspect-square rounded-2xl glass-panel soft-elevation p-4
class _LogoPanel extends StatelessWidget {
  const _LogoPanel();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 260,
        height: 260,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white,
            width: 1.0,
          ),
          boxShadow: [
            // Ambient elevation matching code.html .soft-elevation
            BoxShadow(
              color: const Color(0xFF0D1C32).withValues(alpha: 0.05),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
            BoxShadow(
              color: const Color(0xFF0D1C32).withValues(alpha: 0.03),
              offset: const Offset(0, 8),
              blurRadius: 24,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/draughtsman_logo.jpeg',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

/// Start Submission CTA Button matching code.html:
/// bg-primary-container text-on-primary py-4 px-6 rounded-lg font-button-text
class _CtaButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _CtaButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTypography.buttonText.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

/// Live Stats Bento Grid matching code.html:
/// Projects Active: 1,204 (+12% this week)
/// Drawings Verified: 8.4k
/// Engineers Joined: 450+
class _StatsBentoGrid extends StatelessWidget {
  const _StatsBentoGrid();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Full-width card: Projects Active 1,204
        _StatCard(
          label: 'PROJECTS ACTIVE',
          value: '1,204',
          trendText: '+12% this week',
          trailing: Icon(
            Icons.architecture_outlined,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 16),
        // Two half-width cards: Drawings Verified (8.4k) and Engineers Joined (450+)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatCard(
                  label: 'DRAWINGS VERIFIED',
                  value: '8.4k',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  label: 'ENGINEERS JOINED',
                  value: '450+',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? trendText;
  final Widget? trailing;

  const _StatCard({
    required this.label,
    required this.value,
    this.trendText,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.surfaceVariant,
          width: 1.0,
        ),
        boxShadow: [
          const BoxShadow(
            color: Colors.white,
            offset: Offset(0, 1),
            blurRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF0D1C32).withValues(alpha: 0.05),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFF0D1C32).withValues(alpha: 0.03),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.outline,
                  letterSpacing: 0.8,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTypography.headlineLg.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 28,
                  letterSpacing: -0.5,
                ),
              ),
              if (trendText != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      size: 14,
                      color: Color(0xFF069669),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trendText!,
                      style: AppTypography.labelMonoSm.copyWith(
                        color: const Color(0xFF069669),
                        fontWeight: FontWeight.w500,
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
              child: Opacity(
                opacity: 0.10,
                child: trailing!,
              ),
            ),
        ],
      ),
    );
  }
}

/// Footer Credit matching code.html:
/// pt-8 border-t border-outline-variant/30 text-center pb-8
class _FooterCredit extends StatelessWidget {
  const _FooterCredit();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 32, bottom: 32),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.30),
            width: 1.0,
          ),
        ),
      ),
      child: Text(
        'UI/UX Design & Product Experience crafted by PixelMint Studio MVS',
        style: AppTypography.bodyMd.copyWith(
          color: AppColors.outline,
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Top-right circular glass person button (landing_experience_linked)
class _LoginCircularIconButton extends StatelessWidget {
  const _LoginCircularIconButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/login'),
        borderRadius: BorderRadius.circular(9999),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.70),
              width: 1.0,
            ),
            boxShadow: [
              const BoxShadow(
                color: Colors.white,
                offset: Offset(0, 1),
                blurRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF0D1C32).withValues(alpha: 0.05),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
              BoxShadow(
                color: const Color(0xFF0D1C32).withValues(alpha: 0.03),
                offset: const Offset(0, 8),
                blurRadius: 24,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.person_rounded,
              size: 22,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Construction lines matching code.html:
/// line-h at 20% and 60%, line-v at 30% and 80%
class _ConstructionLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Horizontal line 1 at 20%
    canvas.drawLine(
      Offset(0, size.height * 0.20),
      Offset(size.width, size.height * 0.20),
      paint,
    );

    // Horizontal line 2 at 60%
    canvas.drawLine(
      Offset(0, size.height * 0.60),
      Offset(size.width, size.height * 0.60),
      paint,
    );

    // Vertical line 1 at 30%
    canvas.drawLine(
      Offset(size.width * 0.30, 0),
      Offset(size.width * 0.30, size.height),
      paint,
    );

    // Vertical line 2 at 80%
    canvas.drawLine(
      Offset(size.width * 0.80, 0),
      Offset(size.width * 0.80, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
