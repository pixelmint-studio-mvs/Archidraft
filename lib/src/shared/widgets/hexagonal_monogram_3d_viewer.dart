import 'package:flutter/material.dart';

import '3d/monogram_viewer_stub.dart'
    if (dart.library.ui_web) '3d/monogram_viewer_web.dart';

/// Reusable 3D Viewer for the Architectural Hexagonal Monogram.
///
/// Features:
/// - Renders `assets/models/architectural_hexagonal_monogram.glb` with clean WebGL shaders.
/// - Continuous vertical-axis auto-rotation.
/// - Automatic centering and scaling.
/// - Supports reduced-motion accessibility preference.
/// - Graceful loading indicator and static fallback on unsupported runtimes.
class HexagonalMonogram3DViewer extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool autoRotate;
  final String rotationSpeed;
  final bool interactive;
  final String assetPath;
  final String fallbackImagePath;

  const HexagonalMonogram3DViewer({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.autoRotate = true,
    this.rotationSpeed = '36deg',
    this.interactive = false,
    this.assetPath = 'assets/models/architectural_hexagonal_monogram.glb',
    this.fallbackImagePath = 'assets/images/draughtsman_logo.jpeg',
  });

  @override
  State<HexagonalMonogram3DViewer> createState() =>
      _HexagonalMonogram3DViewerState();
}

class _HexagonalMonogram3DViewerState extends State<HexagonalMonogram3DViewer> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius =
        widget.borderRadius ?? BorderRadius.circular(12);

    if (_hasError) {
      return ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: Image.asset(
          widget.fallbackImagePath,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.contain,
        ),
      );
    }

    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final shouldAutoRotate = widget.autoRotate && !disableAnimations;

    Widget viewer;
    try {
      viewer = buildPlatform3DViewer(
        assetPath: widget.assetPath,
        autoRotate: shouldAutoRotate,
        rotationSpeed: widget.rotationSpeed,
        interactive: widget.interactive,
        fallbackImagePath: widget.fallbackImagePath,
      );
    } catch (_) {
      _hasError = true;
      viewer = Image.asset(
        widget.fallbackImagePath,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.contain,
      );
    }

    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: viewer,
      ),
    );
  }
}
