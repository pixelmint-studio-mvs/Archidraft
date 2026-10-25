import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'src/core/router/app_router.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/api/data/api_client.dart';
import 'src/shared/widgets/3d/monogram_viewer_stub.dart'
    if (dart.library.ui_web) 'src/shared/widgets/3d/monogram_viewer_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initPlatform3DViewer();
  
  // Validate API URL configuration early at startup (fails fast in release builds if unconfigured or insecure)
  ApiClient.resolveBaseUrl();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const ProviderScope(child: ArchiDraftApp()));
}

class ArchiDraftApp extends ConsumerWidget {
  const ArchiDraftApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Archi Draft',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}


