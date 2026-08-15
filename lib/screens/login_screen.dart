import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../theme/hexagon_clipper.dart';
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
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
                            'Waste Collection Management',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 36),

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
                            'Sign in with your Neptune login ID.',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Login ID input
                          TextFormField(
                            controller: _loginIdController,
                            textCapitalization: TextCapitalization.characters,
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
                            onPressed: _isSubmitting ? null : _handleLogin,
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

                          Text(
                            'Accounts are created by your Neptune administrator.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
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