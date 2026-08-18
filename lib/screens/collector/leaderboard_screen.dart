import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/api_models.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/hexagon_clipper.dart';
import '../../widgets/async_states.dart';
import '../../widgets/liquid_glass.dart';

/// Collector leaderboard: top collectors by total weight collected.
///
/// Real data from `GET /collector/leaderboard` (optionally
/// `?period=month` for the current calendar month). Ranks, weights and
/// collection counts come from the backend as-is; the app never calculates
/// or reorders them.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _reloadTick = 0;
  String? _period; // null = All Time, 'month' = This Month

  void _setPeriod(String? period) {
    if (_period == period) return;
    setState(() => _period = period);
  }

  Future<List<LeaderboardEntry>> _load() {
    return context.read<AppState>().api.collector.leaderboard(period: _period);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.primaryGreen,
            ),
            tooltip: 'Refresh',
            onPressed: () => setState(() => _reloadTick++),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _PeriodChip(
                  label: 'All Time',
                  selected: _period == null,
                  onTap: () => _setPeriod(null),
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: 'This Month',
                  selected: _period == 'month',
                  onTap: () => _setPeriod('month'),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncView<List<LeaderboardEntry>>(
              key: ValueKey('leaderboard-$_period-$_reloadTick'),
              future: _load,
              loadingMessage: 'Loading leaderboard…',
              builder: (context, entries) {
                if (entries.isEmpty) {
                  return const EmptyView(
                    icon: Icons.emoji_events_outlined,
                    title: 'No completed collections yet',
                    subtitle:
                        'Leaderboard rankings will appear once collectors start completing collections.',
                  );
                }
                final currentUser = context.read<AppState>().currentUser;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) =>
                      _buildRow(entries[index], currentUser),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(LeaderboardEntry entry, AuthUser? currentUser) {
    final isYou =
        entry.collectorId.isNotEmpty && entry.collectorId == currentUser?.id;
    final medal = _medalFor(entry.rank);

    final content = Row(
      children: [
        // Rank badge
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: medal?.color ?? const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: medal != null
                ? Icon(medal.icon, size: 16, color: AppTheme.pureWhite)
                : Text(
                    '${entry.rank}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkBlack,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        // Avatar
        SizedBox(
          width: 40,
          height: 40,
          child: ClipPath(
            clipper: HexagonClipper(),
            child: Container(
              color: isYou
                  ? AppTheme.primaryGreen
                  : AppTheme.lightGreen.withValues(alpha: 0.35),
              child: Center(
                child: Text(
                  entry.fullName.isNotEmpty
                      ? entry.fullName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.outfit(
                    color: isYou ? AppTheme.pureWhite : AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Name + count
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      entry.fullName,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkBlack,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isYou) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'You',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.pureWhite,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${entry.totalCollections} collections',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        // Weight
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.totalWeightKg.toStringAsFixed(1)} kg',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isYou ? AppTheme.primaryGreen : AppTheme.darkBlack,
              ),
            ),
            Text(
              'total weight',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ],
    );

    if (!isYou) {
      return LiquidGlassCard(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(14),
        child: content,
      );
    }

    // Highlight the logged-in collector's own row: mint frame + green border.
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.mintGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: LiquidGlassCard(
          padding: const EdgeInsets.all(12),
          borderRadius: BorderRadius.circular(14),
          fillOpacity: 0.72,
          child: content,
        ),
      ),
    );
  }

  ({Color color, IconData icon})? _medalFor(int rank) {
    return switch (rank) {
      1 => (color: const Color(0xFFE6B93D), icon: Icons.emoji_events_rounded),
      2 => (color: const Color(0xFF9AA5B1), icon: Icons.military_tech_rounded),
      3 => (
        color: const Color(0xFFC88A5A),
        icon: Icons.workspace_premium_rounded,
      ),
      _ => null,
    };
  }
}

/// Pill toggle for the leaderboard period (All Time / This Month),
/// matching the app's chip styling.
class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryGreen : AppTheme.mintGreen,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppTheme.primaryGreen
                : AppTheme.lightGreen.withValues(alpha: 0.6),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? AppTheme.pureWhite : AppTheme.primaryGreen,
          ),
        ),
      ),
    );
  }
}
