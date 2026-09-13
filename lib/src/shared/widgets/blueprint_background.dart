import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class BlueprintBackground extends StatelessWidget {
  final Widget child;

  const BlueprintBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _BlueprintPainter(),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _BlueprintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0).withOpacity(0.5)
      ..strokeWidth = 0.5;

    const double gridSize = 40.0;

    for (double i = 0; i <= size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i <= size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
