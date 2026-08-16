import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../services/api_client.dart';
import 'main_navigation_screen.dart';
import '../theme/app_theme.dart';
import '../theme/hexagon_clipper.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/neptune_logo_footer.dart';

/// JWT login screen: authenticates via POST /auth/login.
/// Uses loginId (e.g. COLLECTOR001 / RIDER001), not email.
class LoginScreen extends StatefulWidget {
  final String? expectedRole;

  const LoginScreen({super.key, this.expectedRole});

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
      debugPrint('Login attempt started for ${_loginIdController.text.trim()}');
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.login(
        loginId: _loginIdController.text.trim(),
        password: _passwordController.text,
      );
      final actualRole = appState.currentUser?.role;
      debugPrint('Login succeeded. Backend role: $actualRole');
      if (!mounted) return;
      if (widget.expectedRole != null && widget.expectedRole != actualRole) {
        debugPrint(
          'Role mismatch. Expected ${widget.expectedRole}, got $actualRole',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Role mismatch: you chose ${widget.expectedRole}, but this account is $actualRole. Routing by backend role.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
      debugPrint('Navigated to MainNavigationScreen after login');
    } on ApiException catch (e) {
      debugPrint('Login API error: ${e.statusCode} ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      debugPrint('Login unexpected error');
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
      appBar: AppBar(
        title: Text(widget.expectedRole == null ? 'Sign In' : '${widget.expectedRole} Login'),
      ),
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
                                  widget.expectedRole == null
                                      ? 'Sign in with your assigned Neptune login ID.'
                                      : 'Sign in with your assigned Neptune login ID for ${widget.expectedRole}.',
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
