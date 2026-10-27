import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

final Set<String> _registeredViewTypes = <String>{};

/// Initializes the 3D viewer subsystem on Web startup.
void initPlatform3DViewer() {
  // Eager registration or warm-up hook called from main.dart
}

Widget buildPlatform3DViewer({
  required String assetPath,
  required bool autoRotate,
  required String rotationSpeed,
  required bool interactive,
  required String fallbackImagePath,
  bool respectReducedMotion = false,
}) {
  final queryParams = [
    'autoRotate=$autoRotate',
    'respectReducedMotion=$respectReducedMotion',
    'rotationSpeed=${Uri.encodeQueryComponent(rotationSpeed)}',
    'interactive=$interactive',
  ].join('&');

  final sanitizedSpeed = rotationSpeed.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
  final viewType =
      'archi-draft-hex-monogram-3d-${autoRotate}_${respectReducedMotion}_${sanitizedSpeed}_$interactive';

  if (!_registeredViewTypes.contains(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final iframe = web.HTMLIFrameElement()
          ..src = 'models_viewer_frame.html?$queryParams'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = 'transparent'
          ..style.pointerEvents = interactive ? 'auto' : 'none'
          ..allow = 'autoplay; fullscreen; vr';
        return iframe;
      },
    );
    _registeredViewTypes.add(viewType);
  }

  return HtmlElementView(viewType: viewType);
}
