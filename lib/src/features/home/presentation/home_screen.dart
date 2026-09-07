import 'package:flutter/material.dart';

/// Placeholder home screen for Phase 1 route validation.
///
/// This screen serves as the initial landing page.
/// Ref: docs/04_development/DEVELOPMENT_ROADMAP.md (Phase 1)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archi Draft')),
      body: const Center(child: Text('Welcome to Archi Draft')),
    );
  }
}
