import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/app_state.dart';
import 'screens/splash_screen.dart';
import 'services/api_client.dart';
import 'services/api_service.dart';
import 'services/token_storage.dart';
import 'theme/app_theme.dart';
import 'widgets/liquid_glass.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Used ONLY for live rider tracking (Firebase Realtime Database).
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed — live tracking will be unavailable: $e');
  }
  final tokenStorage = TokenStorage();
  ApiClient.initialize(tokenProvider: tokenStorage.readAccessToken);
  final apiService = ApiService(ApiClient.instance);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(api: apiService, tokenStorage: tokenStorage),
      child: const NeptuneApp(),
    ),
  );
}

class NeptuneApp extends StatelessWidget {
  const NeptuneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neptune Recyclers',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        return LiquidGlassBackground(child: child ?? const SizedBox.shrink());
      },
      home: const SplashScreen(),
    );
  }
}
