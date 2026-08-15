import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../theme/hexagon_clipper.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/neptune_logo_footer.dart';

/// JWT login screen: authenticates via POST /auth/login.
/// Uses loginId (e.g. COLLECTOR001 / RIDER001), not email.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.login(
        loginId: _loginIdController.text.trim(),
        password: _passwordController.text,
      );
      // Success: SplashScreen swaps to MainNavigationScreen automatically.
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to sign in. Please try again.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleSkipLogin() async {
    final role = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Explore without logging in',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBlack,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pick a role to preview its screens. Backend data will not load.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(sheetContext).pop('COLLECTOR'),
                icon: const Icon(
                  Icons.eco_outlined,
                  color: AppTheme.primaryGreen,
                ),
                label: const Text('Collector view'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(sheetContext).pop('RIDER'),
                icon: const Icon(
                  Icons.local_shipping_outlined,
                  color: AppTheme.primaryGreen,
                ),
                label: const Text('Rider view'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (role == null || !mounted) return;
    await Provider.of<AppState>(
      context,
      listen: false,
    ).enterDemoSession(role: role);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Hexagon background grid
          Positioned.fill(
            child: CustomPaint(
              painter: HexagonGridBackgroundPainter(
                gridColor: AppTheme.primaryGreen,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 32.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Development mode banner
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryGreen.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.build_circle_outlined,
                                size: 18,
                                color: AppTheme.primaryGreen,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Development mode',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        LiquidGlassCard(
                          padding: const EdgeInsets.all(22),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 8),
                                // Hero Hexagonal Logo
                                Center(
                                  child: SizedBox(
                                    width: 90,
                                    height: 90,
                                    child: Stack(
                                      children: [
                                        ClipPath(
                                          clipper: HexagonClipper(),
                                          child: Container(
                                            color: AppTheme.primaryGreen,
                                            child: const Center(
                                              child: Icon(
                                                Icons.recycling_rounded,
                                                size: 50,
                                                color: AppTheme.pureWhite,
                                              ),
                                            ),
                                          ),
                                        ),
                                        CustomPaint(
                                          size: const Size(90, 90),
                                          painter: HexagonBorderPainter(
                                            color: AppTheme.lightGreen,
                                            strokeWidth: 3.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Neptune Recyclers',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.darkBlack,
                                  ),
                                ),
                                Text(
                                  'Smart Waste Collection Platform',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                Text(
                                  'Welcome Back',
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkBlack,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Sign in with your assigned Neptune login ID.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Login ID input
                                TextFormField(
                                  controller: _loginIdController,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  autofillHints: const [AutofillHints.username],
                                  decoration: const InputDecoration(
                                    labelText: 'Login ID',
                                    hintText: 'e.g. COLLECTOR001',
                                    prefixIcon: Icon(
                                      Icons.badge_outlined,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter your login ID';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password input
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  autofillHints: const [AutofillHints.password],
                                  decoration: const InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Login Button
                                ElevatedButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : _handleLogin,
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: AppTheme.pureWhite,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text('Sign In'),
                                ),
                                const SizedBox(height: 16),

                                // Skip login (demo mode)
                                TextButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : _handleSkipLogin,
                                  child: const Text(
                                    'Skip for now — explore the app',
                                    style: TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Text(
                                  'Accounts are created by your Neptune administrator.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const NeptuneLogoFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
