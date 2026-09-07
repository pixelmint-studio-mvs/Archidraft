import 'package:flutter/material.dart';

/// Placeholder login screen for Phase 1 route validation.
///
/// This screen contains NO authentication logic, Firebase integration,
/// or registration flows. Those belong to Phase 3.
/// Ref: docs/04_development/DEVELOPMENT_ROADMAP.md
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const Center(
        child: Text('Login — Placeholder (Phase 3)'),
      ),
    );
  }
}
