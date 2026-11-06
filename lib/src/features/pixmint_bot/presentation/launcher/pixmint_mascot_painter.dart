import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/pixmint_bot_theme.dart';
import '../animation/mascot_animation_state.dart';

/// High-performance vector CustomPainter rendering the official PIXMINT BOT character.
///
/// Faithfully reproduces the character sheet design by PixelMint Studio MVS:
/// - Smooth ceramic white squircle head chassis with pearlescent gradient and subtle emerald rim
/// - Curved obsidian black glossy visor screen with reflection highlight
/// - Signature glowing cyan-emerald capsule eyes with reactive state expressions
/// - Top mint sprout leaf antenna with subtle breathing illumination
/// - Side ear pods with glowing green neon rings
/// - Optional orbital neon ring with satellite indicator dot
/// - Full 3D torso chassis with official green leaf chest emblem when [useFullMascot] is true
class PixmintMascotPainter extends CustomPainter {
  final MascotAnimationState state;
  final double eyeGlowProgress; // 0.0 to 1.0 breathing animation
  final double blinkProgress; // 0.0 (wide open) to 1.0 (closed)
  final double antennaPulseProgress; // 0.0 to 1.0 subtle antenna illumination
  final double visorScanProgress; // 0.0 to 1.0 scanning beam position for thinking
  final double headTiltAngle; // Radians for organic head tilt
  final bool isThinking; // Backwards compatibility flag
  final bool showOrbitalRing;
  final bool showSatelliteDot;
  final double satelliteAngle;
  final bool useFullMascot;

  PixmintMascotPainter({
    this.state = MascotAnimationState.idle,
    this.eyeGlowProgress = 1.0,
    this.blinkProgress = 0.0,
    this.antennaPulseProgress = 0.0,
    this.visorScanProgress = 0.0,
    this.headTiltAngle = 0.0,
    this.isThinking = false,
    this.showOrbitalRing = false,
    this.showSatelliteDot = false,
    this.satelliteAngle = -math.pi / 4.2,
    this.useFullMascot = false,
  });

  MascotAnimationState get _effectiveState {
    if (state != MascotAnimationState.idle) return state;
    if (isThinking) return MascotAnimationState.thinking;
    return MascotAnimationState.idle;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final minDim = math.min(size.width, size.height);
    final effectiveState = _effectiveState;
    final primaryColor = effectiveState.glowColor;

    // ── 1. Orbital Glowing Ring & Satellite Dot ─────────────────────────────
    if (showOrbitalRing) {
      final ringRadius = (minDim / 2) * 0.94;

      // Outer aura
      final ringAuraPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = minDim * 0.08
        ..color = primaryColor.withValues(
          alpha: 0.18 * eyeGlowProgress,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(center, ringRadius, ringAuraPaint);

      // Sharp glowing ring
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.8, minDim * 0.035)
        ..shader = SweepGradient(
          colors: [
            primaryColor,
            PixmintBotTheme.cyan,
            PixmintBotTheme.emerald,
            primaryColor,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: ringRadius));

      canvas.drawCircle(center, ringRadius, ringPaint);

      // Satellite dot at orbiting angle
      if (showSatelliteDot) {
        final dotCenter = Offset(
          center.dx + ringRadius * math.cos(satelliteAngle),
          center.dy + ringRadius * math.sin(satelliteAngle),
        );
        final dotRadius = minDim * 0.085;

        // Dot glow
        canvas.drawCircle(
          dotCenter,
          dotRadius * 1.6,
          Paint()
            ..color = primaryColor.withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );

        // Dot solid core
        canvas.drawCircle(
          dotCenter,
          dotRadius,
          Paint()
            ..shader = RadialGradient(
              colors: [
                const Color(0xFF6EE7B7),
                primaryColor,
                effectiveState.accentColor,
              ],
            ).createShader(Rect.fromCircle(center: dotCenter, radius: dotRadius)),
        );
      }
    }

    // Geometry layout parameters
    final mascotScale = showOrbitalRing ? 0.74 : (useFullMascot ? 0.88 : 0.92);
    final headWidth = minDim * (useFullMascot ? 0.62 : 0.78) * mascotScale;
    final headHeight = minDim * (useFullMascot ? 0.52 : 0.68) * mascotScale;
    final headCenterY = useFullMascot
        ? center.dy - minDim * 0.16 * mascotScale
        : center.dy;
    final headCenter = Offset(center.dx, headCenterY);

    // ── 2. Full Chibi Torso Chassis with Green Leaf Emblem ──────────────────
    if (useFullMascot) {
      _paintFullBodyChassis(
        canvas,
        center,
        headCenter,
        minDim * mascotScale,
        primaryColor,
        effectiveState,
      );
    }

    // Canvas transform for organic head tilt
    canvas.save();
    canvas.translate(headCenter.dx, headCenter.dy);
    if (headTiltAngle != 0.0) {
      canvas.rotate(headTiltAngle);
    }
    canvas.translate(-headCenter.dx, -headCenter.dy);

    // ── 3. Side Ear Pods with Green Neon Rings ──────────────────────────────
    final earWidth = headWidth * 0.16;
    final earHeight = headHeight * 0.44;
    final earY = headCenter.dy;

    for (final isLeft in [true, false]) {
      final earX = isLeft
          ? headCenter.dx - headWidth * 0.48
          : headCenter.dx + headWidth * 0.48;

      final earRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(earX, earY),
          width: earWidth,
          height: earHeight,
        ),
        Radius.circular(earWidth * 0.5),
      );

      // Ear shadow & ceramic body
      canvas.drawRRect(
        earRect,
        Paint()..color = const Color(0xFFE2E8F0),
      );

      // Ear glowing neon ring
      canvas.drawRRect(
        earRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, minDim * 0.02)
          ..color = primaryColor,
      );
    }

    // ── 4. Sprout / Leaf Antenna at Top Center ──────────────────────────────
    final sproutCenter = Offset(headCenter.dx, headCenter.dy - headHeight * 0.52);
    final sproutSize = headHeight * 0.22;

    final sproutPath = Path()
      ..moveTo(sproutCenter.dx, sproutCenter.dy + sproutSize * 0.2)
      ..cubicTo(
        sproutCenter.dx - sproutSize * 0.4,
        sproutCenter.dy - sproutSize * 0.4,
        sproutCenter.dx - sproutSize * 0.2,
        sproutCenter.dy - sproutSize * 0.9,
        sproutCenter.dx,
        sproutCenter.dy - sproutSize,
      )
      ..cubicTo(
        sproutCenter.dx + sproutSize * 0.5,
        sproutCenter.dy - sproutSize * 0.8,
        sproutCenter.dx + sproutSize * 0.3,
        sproutCenter.dy - sproutSize * 0.2,
        sproutCenter.dx,
        sproutCenter.dy + sproutSize * 0.2,
      )
      ..close();

    // Sprout breathing illumination
    final antennaGlowAlpha = (0.35 + 0.35 * antennaPulseProgress).clamp(0.0, 1.0);
    canvas.drawPath(
      sproutPath,
      Paint()
        ..color = primaryColor.withValues(alpha: antennaGlowAlpha)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          2.0 + 3.0 * antennaPulseProgress,
        ),
    );

    // Sprout gradient fill
    canvas.drawPath(
      sproutPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF6EE7B7),
            primaryColor,
          ],
        ).createShader(
          Rect.fromCircle(center: sproutCenter, radius: sproutSize),
        ),
    );

    // ── 5. Ceramic White Chassis (Squircle Head) ────────────────────────────
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: headCenter,
        width: headWidth,
        height: headHeight,
      ),
      Radius.circular(headHeight * 0.46),
    );

    // Head soft drop shadow
    canvas.drawRRect(
      headRect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Head white ceramic gradient (glossy pearl to subtle silver)
    final headPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF8FAFC),
          Color(0xFFE2E8F0),
        ],
        stops: [0.0, 0.6, 1.0],
      ).createShader(headRect.outerRect);

    canvas.drawRRect(headRect, headPaint);

    // Subtle emerald / status edge rim
    canvas.drawRRect(
      headRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, minDim * 0.015)
        ..color = primaryColor.withValues(alpha: 0.3),
    );

    // ── 6. Dark Glossy Visor Screen ─────────────────────────────────────────
    final visorWidth = headWidth * 0.78;
    final visorHeight = headHeight * 0.62;
    final visorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(headCenter.dx, headCenter.dy + headHeight * 0.02),
        width: visorWidth,
        height: visorHeight,
      ),
      Radius.circular(visorHeight * 0.42),
    );

    // Visor dark background
    canvas.drawRRect(
      visorRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0C1924),
            Color(0xFF050D14),
          ],
        ).createShader(visorRect.outerRect),
    );

    // ── 7. Thinking Visor Scanning Beam ─────────────────────────────────────
    if (effectiveState == MascotAnimationState.thinking || isThinking) {
      canvas.save();
      canvas.clipRRect(visorRect);
      final scanX = visorRect.left + visorRect.width * (visorScanProgress % 1.0);
      final scanWidth = visorWidth * 0.28;

      final scanPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            primaryColor.withValues(alpha: 0.25),
            Colors.white.withValues(alpha: 0.55),
            primaryColor.withValues(alpha: 0.25),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromLTWH(scanX - scanWidth / 2, visorRect.top, scanWidth, visorHeight),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawRect(
        Rect.fromLTWH(scanX - scanWidth / 2, visorRect.top, scanWidth, visorHeight),
        scanPaint,
      );
      canvas.restore();
    }

    // ── 8. Reactive Eyes (Multi-State + Natural Blinking) ───────────────────
    _paintEyes(
      canvas,
      headCenter,
      headHeight,
      visorWidth,
      visorHeight,
      primaryColor,
      effectiveState,
      minDim,
    );

    // Subtle small mouth dash (as in character sheet)
    if (effectiveState != MascotAnimationState.success) {
      final mouthWidth = visorWidth * 0.14;
      final eyeY = headCenter.dy + headHeight * 0.03;
      final eyeHeight = visorHeight * 0.44;
      canvas.drawLine(
        Offset(headCenter.dx - mouthWidth / 2, eyeY + eyeHeight * 0.65),
        Offset(headCenter.dx + mouthWidth / 2, eyeY + eyeHeight * 0.65),
        Paint()
          ..color = primaryColor.withValues(alpha: 0.55)
          ..strokeWidth = math.max(1.0, minDim * 0.015)
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── 9. Glossy Visor Highlight Reflection ────────────────────────────────
    final reflectionPath = Path()
      ..moveTo(visorRect.left + 4, visorRect.top + 3)
      ..lineTo(visorRect.right - 10, visorRect.top + 3)
      ..lineTo(visorRect.left + 4, visorRect.top + visorHeight * 0.35)
      ..close();

    canvas.drawPath(
      reflectionPath,
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );

    canvas.restore();
  }

  void _paintEyes(
    Canvas canvas,
    Offset headCenter,
    double headHeight,
    double visorWidth,
    double visorHeight,
    Color primaryColor,
    MascotAnimationState effectiveState,
    double minDim,
  ) {
    final eyeWidth = visorWidth * 0.22;
    final eyeSpacing = visorWidth * 0.24;
    final eyeY = headCenter.dy + headHeight * 0.03;

    final leftEyeCenter = Offset(headCenter.dx - eyeSpacing, eyeY);
    final rightEyeCenter = Offset(headCenter.dx + eyeSpacing, eyeY);

    // Blinking squashes eye height vertically
    final blinkScale = (1.0 - (blinkProgress * 0.90)).clamp(0.06, 1.0);

    // State-specific eye base height
    final double baseEyeHeight;
    switch (effectiveState) {
      case MascotAnimationState.thinking:
        baseEyeHeight = visorHeight * 0.26;
        break;
      case MascotAnimationState.offline:
        baseEyeHeight = visorHeight * 0.14;
        break;
      case MascotAnimationState.error:
        baseEyeHeight = visorHeight * 0.32;
        break;
      default:
        baseEyeHeight = visorHeight * 0.44;
        break;
    }

    final eyeHeight = baseEyeHeight * blinkScale;
    final glowIntensity = (effectiveState.baseGlowIntensity * (0.75 + 0.25 * eyeGlowProgress))
        .clamp(0.1, 1.0);

    // ── Expression: Success Happy Arcs (^ ^) ────────────────────────────────
    if (effectiveState == MascotAnimationState.success && blinkProgress < 0.3) {
      for (final eyeCenter in [leftEyeCenter, rightEyeCenter]) {
        final arcPath = Path()
          ..moveTo(eyeCenter.dx - eyeWidth * 0.44, eyeCenter.dy + eyeWidth * 0.15)
          ..quadraticBezierTo(
            eyeCenter.dx,
            eyeCenter.dy - eyeWidth * 0.45,
            eyeCenter.dx + eyeWidth * 0.44,
            eyeCenter.dy + eyeWidth * 0.15,
          );

        // Radiant emerald arc glow
        canvas.drawPath(
          arcPath,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(3.0, eyeWidth * 0.32)
            ..strokeCap = StrokeCap.round
            ..color = primaryColor.withValues(alpha: 0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );

        // Crisp inner stroke
        canvas.drawPath(
          arcPath,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(2.0, eyeWidth * 0.22)
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFF6EE7B7),
        );
      }
      return;
    }

    // ── Expression: Standard Glowing Capsule Eyes ───────────────────────────
    for (final eyeCenter in [leftEyeCenter, rightEyeCenter]) {
      final eyeRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: eyeCenter,
          width: eyeWidth,
          height: math.max(2.0, eyeHeight),
        ),
        Radius.circular(eyeWidth * 0.48),
      );

      // Eye outer bloom glow
      if (effectiveState != MascotAnimationState.offline) {
        canvas.drawRRect(
          eyeRect,
          Paint()
            ..color = primaryColor.withValues(
              alpha: 0.55 * glowIntensity,
            )
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }

      // Eye neon core
      canvas.drawRRect(
        eyeRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: effectiveState == MascotAnimationState.offline
                ? [
                    const Color(0xFF94A3B8),
                    const Color(0xFF64748B),
                  ]
                : (effectiveState == MascotAnimationState.error
                    ? [
                        const Color(0xFFFDE68A),
                        const Color(0xFFF59E0B),
                        const Color(0xFFEF4444),
                      ]
                    : [
                        const Color(0xFF6EE7B7),
                        primaryColor,
                        effectiveState.accentColor,
                      ]),
          ).createShader(eyeRect.outerRect),
      );

      // Eye specular white gleam (only when eye is open)
      if (blinkScale > 0.4 && effectiveState != MascotAnimationState.offline) {
        canvas.drawCircle(
          Offset(eyeCenter.dx - eyeWidth * 0.22, eyeCenter.dy - eyeHeight * 0.22),
          math.max(1.2, eyeWidth * 0.18),
          Paint()..color = Colors.white.withValues(alpha: 0.85),
        );
      }
    }
  }

  void _paintFullBodyChassis(
    Canvas canvas,
    Offset center,
    Offset headCenter,
    double scaleDim,
    Color primaryColor,
    MascotAnimationState effectiveState,
  ) {
    final torsoCenter = Offset(center.dx, center.dy + scaleDim * 0.20);
    final torsoWidth = scaleDim * 0.46;
    final torsoHeight = scaleDim * 0.38;

    // Contact ground drop shadow
    final shadowWidth = torsoWidth * 1.1;
    final shadowHeight = scaleDim * 0.08;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + scaleDim * 0.46),
        width: shadowWidth,
        height: shadowHeight,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Dark collar connector
    final collarRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, headCenter.dy + scaleDim * 0.24),
        width: torsoWidth * 0.48,
        height: scaleDim * 0.06,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      collarRect,
      Paint()..color = const Color(0xFF0F172A),
    );

    // Ceramic white torso chassis
    final torsoRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: torsoCenter,
        width: torsoWidth,
        height: torsoHeight,
      ),
      Radius.circular(torsoWidth * 0.42),
    );

    // Torso shadow & pearlescent chassis
    canvas.drawRRect(
      torsoRect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawRRect(
      torsoRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF1F5F9),
            Color(0xFFCBD5E1),
          ],
        ).createShader(torsoRect.outerRect),
    );

    // Emerald rim light
    canvas.drawRRect(
      torsoRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, scaleDim * 0.015)
        ..color = primaryColor.withValues(alpha: 0.28),
    );

    // Official Green Leaf Chest Emblem
    final leafCenter = Offset(center.dx, torsoCenter.dy - torsoHeight * 0.05);
    final leafSize = torsoWidth * 0.28;

    final leafPath = Path()
      ..moveTo(leafCenter.dx, leafCenter.dy - leafSize * 0.6)
      ..cubicTo(
        leafCenter.dx + leafSize * 0.5,
        leafCenter.dy - leafSize * 0.3,
        leafCenter.dx + leafSize * 0.5,
        leafCenter.dy + leafSize * 0.3,
        leafCenter.dx,
        leafCenter.dy + leafSize * 0.6,
      )
      ..cubicTo(
        leafCenter.dx - leafSize * 0.5,
        leafCenter.dy + leafSize * 0.3,
        leafCenter.dx - leafSize * 0.5,
        leafCenter.dy - leafSize * 0.3,
        leafCenter.dx,
        leafCenter.dy - leafSize * 0.6,
      )
      ..close();

    // Emblem emerald glow
    canvas.drawPath(
      leafPath,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Emblem fill
    canvas.drawPath(
      leafPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6EE7B7),
            primaryColor,
            const Color(0xFF047857),
          ],
        ).createShader(
          Rect.fromCircle(center: leafCenter, radius: leafSize),
        ),
    );

    // Leaf central vein and side ribs
    final veinPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = math.max(1.0, leafSize * 0.08)
      ..strokeCap = StrokeCap.round;

    // Central stem
    canvas.drawLine(
      Offset(leafCenter.dx, leafCenter.dy - leafSize * 0.44),
      Offset(leafCenter.dx, leafCenter.dy + leafSize * 0.46),
      veinPaint,
    );

    // Lateral ribs
    final ribWidth = leafSize * 0.22;
    canvas.drawLine(
      Offset(leafCenter.dx, leafCenter.dy - leafSize * 0.15),
      Offset(leafCenter.dx + ribWidth, leafCenter.dy - leafSize * 0.30),
      veinPaint,
    );
    canvas.drawLine(
      Offset(leafCenter.dx, leafCenter.dy - leafSize * 0.0),
      Offset(leafCenter.dx - ribWidth, leafCenter.dy - leafSize * 0.15),
      veinPaint,
    );
    canvas.drawLine(
      Offset(leafCenter.dx, leafCenter.dy + leafSize * 0.15),
      Offset(leafCenter.dx + ribWidth * 0.85, leafCenter.dy + leafSize * 0.02),
      veinPaint,
    );

    // Side arms / floating shoulder pods
    final armWidth = torsoWidth * 0.18;
    final armHeight = torsoHeight * 0.6;
    final armY = torsoCenter.dy;

    for (final isLeft in [true, false]) {
      final armX = isLeft
          ? torsoCenter.dx - torsoWidth * 0.58
          : torsoCenter.dx + torsoWidth * 0.58;

      final armRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(armX, armY),
          width: armWidth,
          height: armHeight,
        ),
        Radius.circular(armWidth * 0.5),
      );

      canvas.drawRRect(
        armRect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFE2E8F0),
            ],
          ).createShader(armRect.outerRect),
      );
    }
  }

  @override
  bool shouldRepaint(covariant PixmintMascotPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.eyeGlowProgress != eyeGlowProgress ||
        oldDelegate.blinkProgress != blinkProgress ||
        oldDelegate.antennaPulseProgress != antennaPulseProgress ||
        oldDelegate.visorScanProgress != visorScanProgress ||
        oldDelegate.headTiltAngle != headTiltAngle ||
        oldDelegate.isThinking != isThinking ||
        oldDelegate.showOrbitalRing != showOrbitalRing ||
        oldDelegate.showSatelliteDot != showSatelliteDot ||
        oldDelegate.satelliteAngle != satelliteAngle ||
        oldDelegate.useFullMascot != useFullMascot;
  }
}

/// Living, multi-state mascot avatar widget for PIXMINT BOT.
///
/// Features:
/// - Continuous subtle floating motion with desynchronized body sway
/// - Natural-looking randomized blinking (not a predictable loop)
/// - Soft emerald eye glow with state-driven expression transitions
/// - Occasional subtle antenna pulse illumination
/// - Respects [MediaQuery.disableAnimations] for accessibility
/// - Automatic lifecycle pause on backgrounding to conserve battery
class PixmintRobotAvatar extends StatefulWidget {
  final double size;
  final MascotAnimationState? state;
  final bool isThinking;
  final bool animate;
  final bool showOrbitalRing;
  final bool showSatelliteDot;
  final bool useFullMascot; // Show 3D body with leaf emblem if true
  final bool useAssetImage; // Prefer high-res transparent artwork with layered transforms
  final VoidCallback? onTap;

  const PixmintRobotAvatar({
    super.key,
    this.size = 48.0,
    this.state,
    this.isThinking = false,
    this.animate = true,
    this.showOrbitalRing = false,
    this.showSatelliteDot = false,
    this.useFullMascot = false,
    this.useAssetImage = false,
    this.onTap,
  });

  @override
  State<PixmintRobotAvatar> createState() => _PixmintRobotAvatarState();
}

class _PixmintRobotAvatarState extends State<PixmintRobotAvatar>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  late AnimationController _swayController;
  late Animation<double> _swayAnimation;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  late AnimationController _antennaController;
  late Animation<double> _antennaAnimation;

  Timer? _blinkTimer;
  Timer? _transientStateTimer;
  final math.Random _random = math.Random();

  MascotAnimationState? _internalStateOverride;

  MascotAnimationState get _effectiveState {
    if (_internalStateOverride != null) return _internalStateOverride!;
    if (widget.state != null) return widget.state!;
    if (widget.isThinking) return MascotAnimationState.thinking;
    return MascotAnimationState.idle;
  }

  bool get _shouldAnimate {
    if (!widget.animate) return false;
    // Disable infinite ticks in test environment
    if (!kIsWeb &&
        WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 1. Continuous subtle vertical floating motion (2600ms period)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _floatAnimation = Tween<double>(begin: -3.5, end: 3.5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    // 2. Desynchronized gentle head tilt / body sway (3400ms period)
    _swayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );
    _swayAnimation = Tween<double>(begin: -0.035, end: 0.035).animate(
      CurvedAnimation(parent: _swayController, curve: Curves.easeInOutSine),
    );

    // 3. Soft emerald eye glow breathing (1900ms period)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
    _glowAnimation = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // 4. Natural randomized eye blink controller (160ms squash & stretch)
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _blinkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    // 5. Visor scanning beam for thinking state (1300ms continuous sweep)
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    );

    // 6. Occasional subtle antenna illumination (3100ms period)
    _antennaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3100),
    );
    _antennaAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _antennaController, curve: Curves.easeInOut),
    );

    if (_shouldAnimate) {
      _startContinuousMotion();
      _scheduleNextBlink();
    }

    _handleStateSideEffects(_effectiveState);
  }

  void _startContinuousMotion() {
    _floatController.repeat(reverse: true);
    _swayController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
    _antennaController.repeat(reverse: true);
    if (_effectiveState == MascotAnimationState.thinking) {
      _scanController.repeat();
    }
  }

  void _pauseContinuousMotion() {
    _floatController.stop();
    _swayController.stop();
    _glowController.stop();
    _antennaController.stop();
    _scanController.stop();
    _blinkTimer?.cancel();
  }

  void _scheduleNextBlink() {
    _blinkTimer?.cancel();
    if (!_shouldAnimate || !mounted) return;

    // Varied, randomized interval between 2.4s and 6.0s for organic natural blinks
    final nextDelayMs = 2400 + _random.nextInt(3600);
    _blinkTimer = Timer(Duration(milliseconds: nextDelayMs), () {
      if (!mounted || !_shouldAnimate) return;
      if (_effectiveState != MascotAnimationState.offline) {
        _blinkController.forward().then((_) {
          if (mounted) {
            _blinkController.reverse().then((_) => _scheduleNextBlink());
          }
        });
      } else {
        _scheduleNextBlink();
      }
    });
  }

  void _handleStateSideEffects(MascotAnimationState state) {
    if (state == MascotAnimationState.thinking) {
      if (_shouldAnimate && !_scanController.isAnimating) {
        _scanController.repeat();
      }
    } else {
      if (_scanController.isAnimating) {
        _scanController.stop();
        _scanController.reset();
      }
    }

    // Auto-revert transient states like greeting or success back to idle
    _transientStateTimer?.cancel();
    if (!_shouldAnimate) return;
    if (state == MascotAnimationState.greeting) {
      _transientStateTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted && _internalStateOverride == null) {
          setState(() => _internalStateOverride = MascotAnimationState.idle);
        }
      });
    } else if (state == MascotAnimationState.success) {
      _transientStateTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted && _internalStateOverride == null) {
          setState(() => _internalStateOverride = MascotAnimationState.idle);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant PixmintRobotAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (_shouldAnimate) {
        _startContinuousMotion();
        _scheduleNextBlink();
      } else {
        _pauseContinuousMotion();
      }
    }

    if (widget.state != oldWidget.state || widget.isThinking != oldWidget.isThinking) {
      _internalStateOverride = null;
      _handleStateSideEffects(_effectiveState);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _pauseContinuousMotion();
    } else if (state == AppLifecycleState.resumed && _shouldAnimate) {
      _startContinuousMotion();
      _scheduleNextBlink();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _blinkTimer?.cancel();
    _transientStateTimer?.cancel();
    _floatController.dispose();
    _swayController.dispose();
    _glowController.dispose();
    _blinkController.dispose();
    _scanController.dispose();
    _antennaController.dispose();
    super.dispose();
  }

  void _triggerGreetingWave() {
    if (!mounted || !_shouldAnimate) return;
    setState(() => _internalStateOverride = MascotAnimationState.greeting);
    _transientStateTimer?.cancel();
    _transientStateTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted && _internalStateOverride == MascotAnimationState.greeting) {
        setState(() => _internalStateOverride = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final disableMotion = mediaQuery?.disableAnimations ?? false;
    final effectiveAnimate = _shouldAnimate && !disableMotion;
    final currentState = _effectiveState;

    final primaryAuraColor = currentState.glowColor;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _floatController,
          _swayController,
          _glowController,
          _blinkController,
          _scanController,
          _antennaController,
        ]),
        builder: (context, child) {
          final floatOffset = effectiveAnimate ? _floatAnimation.value : 0.0;
          final swayAngle = effectiveAnimate ? _swayAnimation.value : 0.0;
          final glowVal = effectiveAnimate ? _glowAnimation.value : 1.0;
          final blinkVal = effectiveAnimate ? _blinkAnimation.value : 0.0;
          final scanVal = effectiveAnimate ? _scanAnimation.value : 0.0;
          final antennaVal = effectiveAnimate ? _antennaAnimation.value : 0.0;

          Widget content;

          if (widget.useFullMascot || widget.useAssetImage) {
            // Layered official high-resolution transparent mascot artwork
            content = _buildLayeredArtwork(
              floatOffset,
              swayAngle,
              glowVal,
              primaryAuraColor,
              currentState,
            );
          } else {
            // Precision vector CustomPainter
            content = Transform.translate(
              offset: Offset(0, floatOffset),
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: PixmintMascotPainter(
                  state: currentState,
                  eyeGlowProgress: glowVal,
                  blinkProgress: blinkVal,
                  antennaPulseProgress: antennaVal,
                  visorScanProgress: scanVal,
                  headTiltAngle: swayAngle,
                  isThinking: widget.isThinking,
                  showOrbitalRing: widget.showOrbitalRing,
                  showSatelliteDot: widget.showSatelliteDot,
                  useFullMascot: widget.useFullMascot,
                ),
              ),
            );
          }

          if (widget.onTap != null) {
            content = GestureDetector(
              onTap: widget.onTap,
              child: content,
            );
          } else if (widget.useFullMascot) {
            content = GestureDetector(
              onTap: _triggerGreetingWave,
              child: content,
            );
          }

          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: content,
          );
        },
      ),
    );
  }

  Widget _buildLayeredArtwork(
    double floatOffset,
    double swayAngle,
    double glowVal,
    Color auraColor,
    MascotAnimationState currentState,
  ) {
    final assetPath = (currentState == MascotAnimationState.greeting || widget.useFullMascot)
        ? 'assets/images/pixmint_bot_waving.png'
        : 'assets/images/pixmint_bot_mascot.png';

    // Scale ground contact shadow inversely with float translation
    final shadowScale = (1.0 - (floatOffset / 14.0)).clamp(0.65, 1.25);
    final shadowAlpha = (0.28 - (floatOffset / 40.0)).clamp(0.12, 0.42);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // 1. Soft breathing ground shadow underneath
        Positioned(
          bottom: 2,
          child: Container(
            width: widget.size * 0.55 * shadowScale,
            height: widget.size * 0.12 * shadowScale,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: shadowAlpha),
              borderRadius: BorderRadius.all(
                Radius.elliptical(
                  widget.size * 0.55 * shadowScale,
                  widget.size * 0.12 * shadowScale,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: shadowAlpha * 0.8),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),

        // 2. Dynamic breathing radial emerald aura backlight
        if (currentState != MascotAnimationState.offline)
          Positioned(
            top: widget.size * 0.15 + floatOffset,
            child: Container(
              width: widget.size * 0.72,
              height: widget.size * 0.72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    auraColor.withValues(alpha: 0.28 * glowVal),
                    auraColor.withValues(alpha: 0.08 * glowVal),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

        // 3. Official character artwork with organic floating & sway
        Transform.translate(
          offset: Offset(0, floatOffset),
          child: Transform.rotate(
            angle: swayAngle,
            child: ColorFiltered(
              colorFilter: currentState == MascotAnimationState.offline
                  ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                  : (currentState == MascotAnimationState.error
                      ? ColorFilter.mode(
                          Colors.amber.withValues(alpha: 0.18),
                          BlendMode.srcATop,
                        )
                      : const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.dst,
                        )),
              child: Opacity(
                opacity: currentState == MascotAnimationState.offline ? 0.6 : 1.0,
                child: Image.asset(
                  assetPath,
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, error, stackTrace) {
                    // Fallback to high-fidelity vector painter
                    return CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: PixmintMascotPainter(
                        state: currentState,
                        eyeGlowProgress: glowVal,
                        useFullMascot: true,
                        showOrbitalRing: widget.showOrbitalRing,
                        showSatelliteDot: widget.showSatelliteDot,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
