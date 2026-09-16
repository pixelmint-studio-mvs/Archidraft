import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/blueprint_background.dart';

/// Role Selection screen — pre-login role chooser.
///
/// Derived from the Stitch visual language (no dedicated Stitch screen exists):
///   - Same blueprint background as Landing
///   - Same glass card / surface-container-lowest card treatment as Login
///   - Same typography scale, color tokens, spacing rhythm
///   - Two roles matching existing app domain: CLIENT, DRAUGHTSMAN
///   - Selected state: secondary-container border ring + onSecondaryFixed fill
///   - CTA: primaryContainer "Continue →" — disabled until a role is selected
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  /// null = nothing selected yet
  String? _selectedRole;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_selectedRole == null) return;
    // Navigate to login, passing the selected role as extra so the
    // login / register flow can pre-populate it.
    context.push('/login', extra: _selectedRole);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlueprintBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
                vertical: AppSpacing.xxl,
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
                          // ── Back navigation ──
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _BackButton(),
                          ),

                          const SizedBox(height: AppSpacing.xxl),

                          // ── Logo mark (small, top-centred) ──
                          _SmallLogoMark(),

                          const SizedBox(height: AppSpacing.xl),

                          // ── Headline ──
                          Text(
                            'Choose Your Role',
                            style: AppTypography.headlineLgMobile.copyWith(
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: AppSpacing.sm),

                          // ── Subtitle ──
                          Text(
                            'Select how you\'ll be using Draughtsman Studio.',
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: AppSpacing.xxxl),

                          // ── Role Cards ──
                          _RoleCard(
                            roleKey: 'CLIENT',
                            icon: Icons.business_center_outlined,
                            title: 'Engineer / Client',
                            description: 'Submit structural drawings and track your project through the review and delivery pipeline.',
                            isSelected: _selectedRole == 'CLIENT',
                            onTap: () =>
                                setState(() => _selectedRole = 'CLIENT'),
                          ),

                          const SizedBox(height: AppSpacing.gridGutter),

                          _RoleCard(
                            roleKey: 'DRAUGHTSMAN',
                            icon: Icons.architecture_outlined,
                            title: 'Draughtsman',
                            description: 'Receive, review and deliver precision engineering drawings from your professional workspace.',
                            isSelected: _selectedRole == 'DRAUGHTSMAN',
                            onTap: () =>
                                setState(() => _selectedRole = 'DRAUGHTSMAN'),
                          ),

                          const SizedBox(height: AppSpacing.xxxl),

                          // ── CTA ──
                          _ContinueButton(
                            enabled: _selectedRole != null,
                            onPressed: _onContinue,
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          // ── Footer credit ──
                          Text(
                            'UI/UX Design & Product Experience crafted by PixelMint Studio MVS',
                            style: AppTypography.labelMono.copyWith(
                              color: AppColors.outline,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
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
// Back Button — ghost / tertiary style, JetBrains Mono
// ─────────────────────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_back, color: AppColors.outline, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'BACK',
            style: AppTypography.labelMono.copyWith(color: AppColors.outline),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Small Logo Mark — compact branding, no text
// Matches Stitch logo area treatment on login / landing
// ─────────────────────────────────────────────────────────────
class _SmallLogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: const Color(0x99FFFFFF),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: const Color(0xCCFFFFFF), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryContainer.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/draughtsman_logo.jpeg',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Role Card
// Default: surface-container-lowest bg, surfaceVariant border, 12px radius
// Selected: 2px secondaryContainer border ring, secondaryFixed bg tint
// Hover: surfaceContainer bg
// ─────────────────────────────────────────────────────────────
class _RoleCard extends StatefulWidget {
  final String roleKey;
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.roleKey,
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // Corner technical marks — matches Stitch login card treatment
    const double cornerSize = 12.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.secondaryFixed.withValues(alpha: 0.18)
                : _hovered
                ? AppColors.surfaceContainer
                : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.secondaryContainer
                  : AppColors.outlineVariant.withValues(alpha: 0.5),
              width: widget.isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 0,
                spreadRadius: 0,
                offset: const Offset(0, 0),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 40,
                spreadRadius: -10,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Corner technical marks (Stitch login screen pattern)
              Positioned(
                top: -AppSpacing.xl + AppSpacing.xs,
                left: -AppSpacing.xl + AppSpacing.xs,
                child: _CornerMark(
                  size: cornerSize,
                  topLeft: true,
                  color: widget.isSelected
                      ? AppColors.secondaryContainer
                      : AppColors.outlineVariant,
                ),
              ),
              Positioned(
                top: -AppSpacing.xl + AppSpacing.xs,
                right: -AppSpacing.xl + AppSpacing.xs,
                child: _CornerMark(
                  size: cornerSize,
                  topRight: true,
                  color: widget.isSelected
                      ? AppColors.secondaryContainer
                      : AppColors.outlineVariant,
                ),
              ),
              // Main content
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? AppColors.secondaryFixed
                          : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: widget.isSelected
                            ? AppColors.secondaryContainer.withValues(
                                alpha: 0.4,
                              )
                            : AppColors.outlineVariant.withValues(alpha: 0.5),
                        width: 1.0,
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 28,
                      color: widget.isSelected
                          ? AppColors.onSecondaryFixedVariant
                          : AppColors.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(width: AppSpacing.lg),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: AppTypography.headlineLgMobile.copyWith(
                            color: AppColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          widget.description,
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // Selection indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isSelected
                          ? AppColors.secondaryContainer
                          : Colors.transparent,
                      border: Border.all(
                        color: widget.isSelected
                            ? AppColors.secondaryContainer
                            : AppColors.outlineVariant,
                        width: 2.0,
                      ),
                    ),
                    child: widget.isSelected
                        ? const Icon(
                            Icons.check,
                            size: 12,
                            color: AppColors.onSecondaryContainer,
                          )
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Corner Technical Mark — Stitch login card detail
// ─────────────────────────────────────────────────────────────
class _CornerMark extends StatelessWidget {
  final double size;
  final Color color;
  final bool topLeft;
  final bool topRight;

  const _CornerMark({
    required this.size,
    required this.color,
    this.topLeft = false,
    this.topRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerMarkPainter(
          color: color.withValues(alpha: 0.4),
          topLeft: topLeft,
          topRight: topRight,
        ),
      ),
    );
  }
}

class _CornerMarkPainter extends CustomPainter {
  final Color color;
  final bool topLeft;
  final bool topRight;

  _CornerMarkPainter({
    required this.color,
    required this.topLeft,
    required this.topRight,
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// Continue Button — disabled until role is selected
// ─────────────────────────────────────────────────────────────
class _ContinueButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _ContinueButton({required this.enabled, required this.onPressed});

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: widget.enabled
                ? (_hovered ? AppColors.primary : AppColors.primaryContainer)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue',
                style: AppTypography.buttonText.copyWith(
                  color: widget.enabled
                      ? AppColors.onPrimary
                      : AppColors.outline,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedSlide(
                duration: const Duration(milliseconds: 200),
                offset: (_hovered && widget.enabled)
                    ? const Offset(0.3, 0)
                    : Offset.zero,
                child: Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: widget.enabled
                      ? AppColors.onPrimary
                      : AppColors.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
