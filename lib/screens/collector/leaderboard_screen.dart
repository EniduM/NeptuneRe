import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/api_models.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/hexagon_clipper.dart';
import '../../utils/formatters.dart';
import '../../widgets/async_states.dart';

/// Full collector leaderboard (GET /collector/leaderboard) with an
/// all-time / this-month toggle.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _monthOnly = true;
  int _reloadTick = 0;

  Future<List<LeaderboardEntry>> _load() =>
      context.read<AppState>().api.collector.leaderboard(
            period: _monthOnly ? 'month' : null,
          );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppTheme.primaryGreen),
            tooltip: 'Refresh',
            onPressed: () => setState(() => _reloadTick++),
          ),
        ],
      ),
      body: Column(
        children: [
          // Period toggle
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                _periodButton('This Month', true),
                _periodButton('All Time', false),
              ],
            ),
          ),

          // Banner Header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 54,
                  height: 54,
                  child: ClipPath(
                    clipper: HexagonClipper(),
                    child: Container(
                      color: AppTheme.pureWhite,
                      child: const Center(
                        child: Icon(
                          Icons.emoji_events_rounded,
                          color: AppTheme.gold,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Waste Collection Champions',
                        style: GoogleFonts.outfit(
                          color: AppTheme.pureWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ranked by total weight collected (kg)',
                        style: GoogleFonts.outfit(
                          color: AppTheme.pureWhite.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: AsyncView<List<LeaderboardEntry>>(
              key: ValueKey('$_reloadTick-$_monthOnly'),
              future: _load,
              loadingMessage: 'Loading leaderboard…',
              builder: (context, entries) {
                if (entries.isEmpty) {
                  return const EmptyView(
                    icon: Icons.emoji_events_outlined,
                    title: 'No collections yet',
                    subtitle:
                        'Leaderboard updates once collections are completed.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) =>
                      _buildTile(entries[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodButton(String label, bool month) {
    final selected = _monthOnly == month;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (selected) return;
          setState(() => _monthOnly = month);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.pureWhite : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: selected ? AppTheme.primaryGreen : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTile(LeaderboardEntry entry) {
    final (rankBadgeColor, medalIcon) = switch (entry.rank) {
      1 => (AppTheme.gold, Icons.military_tech_rounded),
      2 => (AppTheme.silver, Icons.military_tech_rounded),
      3 => (AppTheme.bronze, Icons.military_tech_rounded),
      _ => (AppTheme.lightGreen, null),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: entry.rank <= 3
              ? rankBadgeColor.withValues(alpha: 0.6)
              : const Color(0xFFE5E7EB),
          width: entry.rank <= 3 ? 1.5 : 1,
        ),
        boxShadow: entry.rank <= 3
            ? [
                BoxShadow(
                  color: rankBadgeColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              children: [
                ClipPath(
                  clipper: HexagonClipper(),
                  child: Container(
                    color: rankBadgeColor,
                    child: Center(
                      child: medalIcon != null
                          ? Icon(medalIcon,
                              color: AppTheme.pureWhite, size: 24)
                          : Text(
                              '#${entry.rank}',
                              style: GoogleFonts.outfit(
                                color: AppTheme.pureWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ),
                CustomPaint(
                  size: const Size(44, 44),
                  painter: HexagonBorderPainter(
                    color: AppTheme.pureWhite,
                    strokeWidth: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.fullName,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.darkBlack,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.totalCollections} collections',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${formatWeight(entry.totalWeightKg)} kg',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryGreen,
                ),
              ),
              Text(
                'Total Weight',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}