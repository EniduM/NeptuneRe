import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/hexagon_clipper.dart';
import '../widgets/neptune_logo_footer.dart';
import 'collector/collector_dashboard_screen.dart';
import 'collector/collector_profile_screen.dart';
import 'collector/collector_requests_screen.dart';
import 'rider/rider_dashboard_screen.dart';
import 'rider/rider_jobs_screen.dart';
import 'rider/rider_profile_screen.dart';

/// Role-based navigation shell.
///
/// COLLECTOR: Dashboard · Requests · Profile
/// RIDER:     Available · My Jobs · Profile
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (!appState.isAuthenticated && !appState.isDemoSession) {
      return const SizedBox.shrink();
    }

    if (appState.isCollector) {
      return _buildCollectorShell();
    }
    if (appState.isRider) {
      return _buildRiderShell();
    }

    // ADMIN and unknown roles cannot use the mobile workflows.
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: AppTheme.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                'This account role is not supported on mobile.\nOnly COLLECTOR and RIDER accounts can sign in here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => appState.logout(),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollectorShell() {
    final pages = <Widget>[
      const CollectorDashboardScreen(),
      const CollectorRequestsScreen(),
      const CollectorProfileScreen(),
    ];
    final items = [
      ('Home', Icons.home_rounded),
      ('My Requests', Icons.list_alt_rounded),
      ('Profile', Icons.person_rounded),
    ];

    return _shell(pages, items, index: _currentIndex);
  }

  Widget _buildRiderShell() {
    final pages = <Widget>[
      const RiderDashboardScreen(),
      const RiderJobsScreen(),
      const RiderProfileScreen(),
    ];
    final items = [
      ('Available', Icons.shopping_bag_rounded),
      ('My Jobs', Icons.local_shipping_rounded),
      ('Profile', Icons.person_rounded),
    ];

    return _shell(pages, items, index: _currentIndex);
  }

  Widget _shell(
    List<Widget> pages,
    List<(String, IconData)> items, {
    required int index,
  }) {
    final selectedIndex = index < items.length ? index : 0;
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NeptuneLogoFooter(compact: true),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.62),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.82),
                  width: 1,
                ),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: AppTheme.primaryGreen,
              unselectedItemColor: AppTheme.textMuted,
              selectedLabelStyle: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              unselectedLabelStyle: GoogleFonts.outfit(
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              elevation: 0,
              items: [
                for (final (label, icon) in items)
                  BottomNavigationBarItem(
                    icon: Icon(icon),
                    activeIcon: _buildActiveHexIcon(icon),
                    label: label,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveHexIcon(IconData iconData) {
    return SizedBox(
      width: 28,
      height: 28,
      child: ClipPath(
        clipper: HexagonClipper(),
        child: Container(
          color: AppTheme.primaryGreen,
          child: Center(
            child: Icon(
              iconData,
              color: AppTheme.pureWhite,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}