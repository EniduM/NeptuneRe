import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../theme/hexagon_clipper.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/neptune_logo_footer.dart';
import 'login_screen.dart';

/// Entry screen from the mockup flow.
///
/// The selected role is used only as an expected role hint. Real routing after
/// login always uses the backend `user.role` from POST /auth/login.
class RoleLandingScreen extends StatelessWidget {
  const RoleLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: SizedBox(
                        width: 96,
                        height: 96,
                        child: Stack(
                          children: [
                            ClipPath(
                              clipper: HexagonClipper(),
                              child: Container(
                                color: AppTheme.primaryGreen,
                                child: const Center(
                                  child: Icon(
                                    Icons.recycling_rounded,
                                    size: 54,
                                    color: AppTheme.pureWhite,
                                  ),
                                ),
                              ),
                            ),
                            CustomPaint(
                              size: const Size(96, 96),
                              painter: HexagonBorderPainter(
                                color: AppTheme.lightGreen,
                                strokeWidth: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Neptune Recyclers',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.darkBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose your app role to continue',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _RoleChoiceCard(
                      title: 'I AM COLLECTOR',
                      subtitle: 'Create requests and track pickup status',
                      icon: Icons.eco_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(
                              expectedRole: 'COLLECTOR',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _RoleChoiceCard(
                      title: 'I AM RIDER',
                      subtitle: 'Accept jobs and complete collections',
                      icon: Icons.local_shipping_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(
                              expectedRole: 'RIDER',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const NeptuneLogoFooter(),
          ],
        ),
      ),
    );
  }
}

class _RoleChoiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      borderRadius: BorderRadius.circular(20),
      fillOpacity: 0.66,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: ClipPath(
                    clipper: HexagonClipper(),
                    child: Container(
                      color: AppTheme.primaryGreen,
                      child: Icon(icon, color: AppTheme.pureWhite, size: 30),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.darkBlack,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppTheme.primaryGreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}