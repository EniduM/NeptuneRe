import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/hexagon_clipper.dart';

/// Rider profile: identity from /auth/me, workflow help and logout.
class RiderProfileScreen extends StatelessWidget {
  const RiderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Rider Profile'),
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
        title: const Text('Rider Profile'),
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
                                    : 'R',
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
                    'RIDER',
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

            // Collection workflow help
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.mintGreen,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.lightGreen),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.route_rounded,
                          color: AppTheme.primaryGreen, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'How a collection works',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.darkBlack,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _helpRow(1, 'Accept an available request'),
                  _helpRow(2, 'Drive to the Collector location (map + navigate)'),
                  _helpRow(3, 'Scan the Collector\'s permanent QR'),
                  _helpRow(4, 'Enter the TOTAL weight in kg'),
                  _helpRow(5, 'Complete the collection — record saved'),
                  const SizedBox(height: 8),
                  Text(
                    'There is no bag count — the total weight is the only measure entered.',
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

  Widget _helpRow(int step, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: GoogleFonts.outfit(
                  color: AppTheme.pureWhite,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(fontSize: 12.5, color: AppTheme.darkBlack),
            ),
          ),
        ],
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