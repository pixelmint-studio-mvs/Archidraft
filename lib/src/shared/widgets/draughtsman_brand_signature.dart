import 'package:flutter/material.dart';

/// Architectural animated brand signature: "DRAUGHTSMAN STUDIO".
///
/// Designed to evoke:
/// - Technical drafting and architectural drawing.
/// - Precision linework with measurement marks and registration ticks.
/// - Blueprint geometry.
/// - Refined letter-spacing transition that settles the wordmark.
/// - Respects `prefers-reduced-motion` / `disableAnimations`.
class DraughtsmanBrandSignature extends StatefulWidget {
  final bool compact;
  final Color? color;

  const DraughtsmanBrandSignature({
    super.key,
    this.compact = false,
    this.color,
  });

  @override
  State<DraughtsmanBrandSignature> createState() =>
      _DraughtsmanBrandSignatureState();
}

class _DraughtsmanBrandSignatureState extends State<DraughtsmanBrandSignature>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _lineWidthAnim;
  late final Animation<double> _opacityAnim;
  late final Animation<double> _spacingAnim;
  late final Animation<double> _ticksOpacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 1. Line draws out from center
    _lineWidthAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Drafting guide ticks appear
    _ticksOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    // 3. Wordmark fades in with line-reveal
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.75, curve: Curves.easeOut),
      ),
    );

    // 4. Subtle letter-spacing settling into place
    _spacingAnim = Tween<double>(
      begin: widget.compact ? 5.0 : 7.0,
      end: widget.compact ? 2.8 : 4.2,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations) {
      return _buildContent(1.0, 1.0, widget.compact ? 2.8 : 4.2, 1.0);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return _buildContent(
          _lineWidthAnim.value,
          _opacityAnim.value,
          _spacingAnim.value,
          _ticksOpacityAnim.value,
        );
      },
    );
  }

  Widget _buildContent(
    double lineProgress,
    double textOpacity,
    double letterSpacing,
    double ticksOpacity,
  ) {
    final primaryColor = widget.color ?? const Color(0xFF1E293B);
    final guideColor = primaryColor.withValues(alpha: 0.28 * ticksOpacity);
    final fontSize = widget.compact ? 10.5 : 13.0;

    return Semantics(
      label: 'DRAUGHTSMAN STUDIO',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top architectural drafting guide line with registration ticks
          SizedBox(
            width: widget.compact ? 160 : 220,
            height: 6,
            child: CustomPaint(
              painter: _DraftingGuidePainter(
                progress: lineProgress,
                ticksOpacity: ticksOpacity,
                color: guideColor,
              ),
            ),
          ),
          const SizedBox(height: 5),

          // Typeset Studio Wordmark
          Opacity(
            opacity: textOpacity,
            child: Text(
              'DRAUGHTSMAN STUDIO',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: letterSpacing,
                color: primaryColor,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 5),

          // Bottom architectural drafting guide line
          SizedBox(
            width: widget.compact ? 160 : 220,
            height: 6,
            child: CustomPaint(
              painter: _DraftingGuidePainter(
                progress: lineProgress,
                ticksOpacity: ticksOpacity,
                color: guideColor,
                isBottom: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for precision architectural drafting linework with end ticks
class _DraftingGuidePainter extends CustomPainter {
  final double progress;
  final double ticksOpacity;
  final Color color;
  final bool isBottom;

  _DraftingGuidePainter({
    required this.progress,
    required this.ticksOpacity,
    required this.color,
    this.isBottom = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.75
      ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    final halfWidth = (size.width / 2) * progress;
    final centerX = size.width / 2;
    final startX = centerX - halfWidth;
    final endX = centerX + halfWidth;

    // Horizontal guideline
    canvas.drawLine(Offset(startX, centerY), Offset(endX, centerY), paint);

    // Architectural registration ticks at ends and center
    if (ticksOpacity > 0 && progress > 0.4) {
      final tickPaint = Paint()
        ..color = color
        ..strokeWidth = 0.75;

      const tickHeight = 2.5;

      // Left tick
      canvas.drawLine(
        Offset(startX, centerY - tickHeight),
        Offset(startX, centerY + tickHeight),
        tickPaint,
      );

      // Right tick
      canvas.drawLine(
        Offset(endX, centerY - tickHeight),
        Offset(endX, centerY + tickHeight),
        tickPaint,
      );

      // Center crosshair mark
      canvas.drawLine(
        Offset(centerX, centerY - 1.5),
        Offset(centerX, centerY + 1.5),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DraftingGuidePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ticksOpacity != ticksOpacity ||
        oldDelegate.color != color;
  }
}
