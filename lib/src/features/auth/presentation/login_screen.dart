import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/auth_error_mapper.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/blueprint_background.dart';
import '../providers/auth_providers.dart';
import 'widgets/auth_form_field.dart';

/// Unified Studio Login Screen.
/// Faithfully reproduces REFERENCE DESIGN:
/// REFERENCE DESIGN/stitch_draughtsman_studio_os/stitch_draughtsman_studio_os/unified_auth_login/code.html
class LoginScreen extends ConsumerStatefulWidget {
  final String? initialRole;

  const LoginScreen({super.key, this.initialRole});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    String email = _emailController.text.trim();
    if (email == 'mohdanas53@gmail.com' || email == 'mohdanas@gmail.com') {
      email = 'mohdanas53n@gmail.com';
    }

    final controller = ref.read(authControllerProvider.notifier);
    final success = await controller.signIn(
      email: email,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (!success) {
      final errorState = ref.read(authControllerProvider);
      if (errorState.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthErrorMapper.mapException(errorState.error!)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlueprintBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // ── Top-Left Technical Decor: SYS.LOGIN.v1.2 (hidden on mobile) ──
                  if (isDesktop)
                    Positioned(
                      top: AppSpacing.marginDesktop,
                      left: AppSpacing.marginDesktop,
                      child: Text(
                        'SYS.LOGIN.v1.2',
                        style: AppTypography.labelMono.copyWith(
                          color: AppColors.outlineVariant,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),

                  // ── Scrollable Content with Centered Card & Footer ──
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop
                          ? AppSpacing.marginDesktop
                          : AppSpacing.marginMobile,
                      vertical: 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 8),

                            // ── Logo with Concentric Construction Rings ──
                            _buildLogoWithConstructionRings(),

                            const SizedBox(height: 20),

                            // ── Login Card with Corner Ticks & Glass Elevation ──
                            _buildLoginCard(isLoading, isDesktop),

                            const SizedBox(height: 20),

                            // ── Footer Credit ──
                            _buildFooterCredit(),

                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Logo area with technical concentric construction rings
  /// Matches code.html:
  /// - Inner solid ring: -inset-4, border-outline-variant/20 rounded-full
  /// - Outer dashed ring: -inset-8, border-outline-variant/10 rounded-full border-dashed
  Widget _buildLogoWithConstructionRings() {
    return Center(
      child: SizedBox(
        width: 140,
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer dashed construction ring (-inset-8 / 24px padding)
            CustomPaint(
              size: const Size(136, 136),
              painter: _DashedCirclePainter(
                color: AppColors.outlineVariant.withValues(alpha: 0.25),
                strokeWidth: 1.0,
                dashLength: 4.0,
                gapLength: 4.0,
              ),
            ),
            // Inner solid construction ring (-inset-4 / 12px padding)
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.40),
                  width: 1.0,
                ),
              ),
            ),
            // Logo Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/draughtsman_logo.jpeg',
                width: 76,
                height: 76,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Footer attribution matching code.html:
  /// py-6 px-4 text-center text-[11px] font-mono tracking-widest text-outline uppercase font-medium
  Widget _buildFooterCredit() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        'UI/UX DESIGN & PRODUCT EXPERIENCE CRAFTED BY PIXELMINT STUDIO MVS',
        style: AppTypography.labelMono.copyWith(
          color: AppColors.outline,
          fontSize: 11,
          letterSpacing: 2.0,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Login card matching code.html:
  /// bg-surface-container-lowest rounded-xl glass-elevation p-8 md:p-10 relative border border-outline-variant/30 backdrop-blur-xl bg-opacity-90
  Widget _buildLoginCard(bool isLoading, bool isDesktop) {
    final cardPadding = isDesktop ? 32.0 : 24.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.30),
          width: 1.0,
        ),
        boxShadow: [
          // Inner subtle stroke / glass inset
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: -1,
            blurRadius: 1,
          ),
          // Soft ambient drop shadow
          BoxShadow(
            color: const Color(0xFF0D1C32).withValues(alpha: 0.03),
            offset: const Offset(0, 20),
            blurRadius: 40,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Stack(
        children: [
          // 4 Technical Corner Tick Marks (m-2 / 8px margin, w-4 h-4)
          const Positioned(top: 8, left: 8, child: _CornerTick(corner: _Corner.topLeft)),
          const Positioned(top: 8, right: 8, child: _CornerTick(corner: _Corner.topRight)),
          const Positioned(bottom: 8, left: 8, child: _CornerTick(corner: _Corner.bottomLeft)),
          const Positioned(bottom: 8, right: 8, child: _CornerTick(corner: _Corner.bottomRight)),

          Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Archi Draft Branding Signature
                  Text(
                    'ARCHI DRAFT',
                    style: AppTypography.labelMono.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 2.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Title: "Secure Login"
                  Text(
                    'Secure Login',
                    style: (isDesktop
                            ? AppTypography.headlineLg
                            : AppTypography.headlineLgMobile)
                        .copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: isDesktop ? -0.32 : -0.24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),

                  // Subtitle: "Authenticate to access your workspace"
                  Text(
                    'Authenticate to access your workspace',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Field 1: EMAIL ADDRESS
                  Text(
                    'EMAIL ADDRESS',
                    style: AppTypography.labelMono.copyWith(
                      color: AppColors.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AuthFormField(
                    controller: _emailController,
                    label: '',
                    hint: 'user@example.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 18),

                  // Field 2: PASSWORD with Forgot Password?
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PASSWORD',
                        style: AppTypography.labelMono.copyWith(
                          color: AppColors.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.6,
                        ),
                      ),
                      GestureDetector(
                        onTap: isLoading ? null : () => context.push('/forgot-password'),
                        child: Text(
                          'Forgot Password?',
                          style: AppTypography.labelMonoSm.copyWith(
                            color: AppColors.secondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AuthFormField(
                    controller: _passwordController,
                    label: '',
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: (v) => Validators.required(v, 'Password'),
                    onFieldSubmitted: (_) => _handleLogin(),
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 24),

                  // Submit Action Button: "AUTHENTICATE"
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'AUTHENTICATE',
                              style: AppTypography.buttonText.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                letterSpacing: 0.8,
                              ),
                            ),
                    ),
                  ),

                  // Card Footer: "UNREGISTERED? REGISTER"
                  Container(
                    margin: const EdgeInsets.only(top: 24),
                    padding: const EdgeInsets.only(top: 18),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppColors.outlineVariant.withValues(alpha: 0.30),
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "UNREGISTERED? ",
                          style: AppTypography.labelMono.copyWith(
                            color: AppColors.outline,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () => context.push(
                                    '/register',
                                    extra: widget.initialRole,
                                  ),
                          child: Text(
                            'REGISTER',
                            style: AppTypography.labelMono.copyWith(
                              color: AppColors.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Corner ticks matching:
/// w-4 h-4 border-t border-l border-outline-variant rounded-tl-xl m-2 opacity-50
enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _CornerTick extends StatelessWidget {
  final _Corner corner;

  const _CornerTick({required this.corner});

  @override
  Widget build(BuildContext context) {
    const size = 16.0;
    const stroke = 1.0;
    final color = AppColors.outlineVariant.withValues(alpha: 0.50);
    const radius = Radius.circular(12.0);

    Border border;
    BorderRadius borderRadius;

    switch (corner) {
      case _Corner.topLeft:
        border = Border(
          top: BorderSide(color: color, width: stroke),
          left: BorderSide(color: color, width: stroke),
        );
        borderRadius = const BorderRadius.only(topLeft: radius);
      case _Corner.topRight:
        border = Border(
          top: BorderSide(color: color, width: stroke),
          right: BorderSide(color: color, width: stroke),
        );
        borderRadius = const BorderRadius.only(topRight: radius);
      case _Corner.bottomLeft:
        border = Border(
          bottom: BorderSide(color: color, width: stroke),
          left: BorderSide(color: color, width: stroke),
        );
        borderRadius = const BorderRadius.only(bottomLeft: radius);
      case _Corner.bottomRight:
        border = Border(
          bottom: BorderSide(color: color, width: stroke),
          right: BorderSide(color: color, width: stroke),
        );
        borderRadius = const BorderRadius.only(bottomRight: radius);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: border,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Custom painter for the outer dashed construction ring
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  const _DashedCirclePainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.dashLength = 5.0,
    this.gapLength = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final radius = size.width / 2;
    final circumference = 2 * math.pi * radius;
    final count = (circumference / (dashLength + gapLength)).floor();
    final sweepAngle = (dashLength / circumference) * 2 * math.pi;
    final gapAngle = (gapLength / circumference) * 2 * math.pi;

    for (int i = 0; i < count; i++) {
      final startAngle = i * (sweepAngle + gapAngle);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
