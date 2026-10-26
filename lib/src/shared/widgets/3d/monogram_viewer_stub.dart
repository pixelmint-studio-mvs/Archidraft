import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void initPlatform3DViewer() {
  // No-op on mobile/native platforms
}

Widget buildPlatform3DViewer({
  required String assetPath,
  required bool autoRotate,
  required String rotationSpeed,
  required bool interactive,
  required String fallbackImagePath,
  bool respectReducedMotion = false,
}) {
  if (WebViewPlatform.instance == null) {
    return Image.asset(
      fallbackImagePath,
      fit: BoxFit.contain,
    );
  }

  return ModelViewer(
    src: assetPath,
    alt: 'Archi Draft Architectural Hexagonal Monogram 3D',
    autoRotate: autoRotate,
    autoRotateDelay: 0,
    rotationPerSecond: rotationSpeed,
    orientation: '0 90deg 0',
    cameraControls: false,
    disableZoom: true,
    disablePan: true,
    disableTap: true,
    backgroundColor: Colors.transparent,
    shadowIntensity: 1.2,
    shadowSoftness: 0.5,
    cameraOrbit: '0deg 90deg 105%',
    fieldOfView: '32deg',
    loading: Loading.eager,
  );
}
