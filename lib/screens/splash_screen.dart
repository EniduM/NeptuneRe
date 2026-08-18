import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass.dart';
import 'main_navigation_screen.dart';
import 'role_landing_screen.dart';

/// Startup gate: restores the persisted JWT session before deciding
/// between Login and the role-based main navigation.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (appState.isRestoringSession) {
      return Scaffold(
        body: Center(
          child: LiquidGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/neptune_logo.jpg',
                    width: 88,
                    height: 88,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                    strokeWidth: 2.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'NEPTUNE RECYCLERS',
                  style: TextStyle(
                    color: AppTheme.darkBlack,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!appState.isAuthenticated && !appState.isDemoSession) {
      return const RoleLandingScreen();
    }

    return const MainNavigationScreen();
  }
}
