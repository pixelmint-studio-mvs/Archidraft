import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'src/core/router/app_router.dart';
import 'src/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
