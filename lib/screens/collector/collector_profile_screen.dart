import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/hexagon_clipper.dart';

/// Collector profile: identity from /auth/me and the permanent QR section.
///
/// The Collector's permanent QR encodes their `qrToken`. The backend does
/// not currently expose the collector's own qrToken through any collector
/// endpoint (it is admin-only today). This section is wired to render the QR
/// from `qrToken` as soon as an API field provides it; until then a clear
/// "not available" state is shown instead of fabricated data.
class CollectorProfileScreen extends StatelessWidget {
  const CollectorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Collector Profile'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_off_rounded,
                  size: 48,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  'Profile unavailable',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlack,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No authenticated user is available right now.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collector Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: () => _showLogoutDialog(context, appState),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Identity card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.pureWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      children: [
                        ClipPath(
                          clipper: HexagonClipper(),
                          child: Container(
                            color: AppTheme.primaryGreen,
                            child: Center(
                              child: Text(
                                user!.loginId.isNotEmpty
                                    ? user.loginId[0].toUpperCase()
                                    : 'C',
                                style: GoogleFonts.outfit(
                                  color: AppTheme.pureWhite,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 36,
                                ),
                              ),
                            ),
                          ),
                        ),
                        CustomPaint(
                          size: const Size(80, 80),
                          painter: HexagonBorderPainter(
                            color: AppTheme.lightGreen,
                            strokeWidth: 2.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.loginId,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBlack,
                    ),
                  ),
                  Text(
                    'COLLECTOR',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Full name and contact details are managed by the Neptune administrator.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Permanent QR section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.pureWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_2_rounded,
                          color: AppTheme.primaryGreen, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Your Permanent QR Code',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkBlack,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Show this QR to the Rider when they arrive. It proves your identity — never scan a QR as a Collector.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // QR availability state.
                  //
                  // The backend currently has no collector-facing endpoint
                  // that returns this collector's qrToken (it is managed via
                  // ADMIN APIs). When a collector API exposes `qrToken`,
                  // render QrImageView(data: qrToken) here — the QR value the
                  // Rider scans is exactly this token, verified server-side
                  // by POST /rider/collection-requests/:id/verify-qr.
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.qr_code_2_rounded,
                            size: 32,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'QR code unavailable',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkBlack,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Your QR token is not exposed by the backend yet. Use your printed/issued QR card until then.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'QR scanning is performed by Riders only.',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Account card
            Container(
              decoration: BoxDecoration(
                color: AppTheme.pureWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.mintGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.verified_user_rounded,
                          color: AppTheme.primaryGreen),
                    ),
                    title: Text(
                      'Account Status',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.darkBlack,
                      ),
                    ),
                    subtitle: Text(
                      user.status,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: Colors.redAccent),
                    ),
                    title: Text(
                      'Logout of Account',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.redAccent,
                      ),
                    ),
                    onTap: () => _showLogoutDialog(context, appState),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Confirm Logout',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to sign out of Neptune Recyclers?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              appState.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}