import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/core/router/app_router.dart';
import 'src/core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: ArchiDraftApp()));
}

/// Root application widget for Archi Draft.
///
/// Wrapped in ProviderScope for Riverpod state management.
/// Uses GoRouter for declarative routing.
/// Theme follows docs/06_design/BRAND_AND_DESIGN_DIRECTION.md.
class ArchiDraftApp extends ConsumerWidget {
  const ArchiDraftApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Archi Draft',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
