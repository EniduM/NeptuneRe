import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'screens/splash_screen.dart';
import 'services/api_client.dart';
import 'services/api_service.dart';
import 'services/token_storage.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const SplashScreen(),
    );
  }
}