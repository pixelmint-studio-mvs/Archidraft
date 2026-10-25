import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

const String kHexMonogram3DViewType = 'archi-draft-hex-monogram-3d';
bool _isWebRegistered = false;

void initPlatform3DViewer() {
  if (!_isWebRegistered) {
    ui_web.platformViewRegistry.registerViewFactory(
      kHexMonogram3DViewType,
      (int viewId) {
        final iframe = web.HTMLIFrameElement()
          ..src = 'models_viewer_frame.html'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = 'transparent'
          ..style.pointerEvents = 'none'
          ..allow = 'autoplay; fullscreen; vr';
        return iframe;
      },
    );
    _isWebRegistered = true;
  }
}

Widget buildPlatform3DViewer({
  required String assetPath,
  required bool autoRotate,
  required String rotationSpeed,
  required bool interactive,
  required String fallbackImagePath,
}) {
  initPlatform3DViewer();
  return const HtmlElementView(viewType: kHexMonogram3DViewType);
}
