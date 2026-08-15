import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/api_models.dart';
import '../../providers/app_state.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../theme/hexagon_clipper.dart';
import '../../utils/formatters.dart';
import '../../widgets/async_states.dart';
import 'create_request_screen.dart';
import 'leaderboard_screen.dart';

/// Collector dashboard: today's assignment, quick create CTA,
/// recent request summary and a clearly visible leaderboard section.
class CollectorDashboardScreen extends StatefulWidget {
  const CollectorDashboardScreen({super.key});

  @override
  State<CollectorDashboardScreen> createState() =>
      _CollectorDashboardScreenState();
}

class _CollectorDashboardScreenState extends State<CollectorDashboardScreen> {
  int _reloadTick = 0;
  String? _assignmentError;

  Future<DailyAssignment?> _loadAssignment() async {
    try {
      final assignment = await context.read<AppState>().api.collector.todayAssignment();
      _assignmentError = null;
      if (!mounted) return assignment;
      setState(() {});
      return assignment;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // No assignment today — this is a normal state.
        _assignmentError = null;
        if (mounted) setState(() {});
        return null;
      }
      _assignmentError = e.message;
      if (mounted) setState(() {});
      return null;
    }
  }

  Future<List<LeaderboardEntry>> _loadLeaderboard() =>
      context.read<AppState>().api.collector.leaderboard(period: 'month');

  Future<List<CollectionRequest>> _loadRecent() async {
    final all = await context.read<AppState>().api.collector.myRequests();
    return all.take(3).toList();
  }

  void _refreshAll() {
    setState(() => _reloadTick++);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryGreen),
            tooltip: 'Refresh',
            onPressed: _refreshAll,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshAll();
          await Future.delayed(const Duration(milliseconds: 400));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // Greeting header
            Container(
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
                        child: Center(
                          child: Text(
                            (user?.loginId ?? 'C').substring(0, 1),
                            style: GoogleFonts.outfit(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
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
                          'Hello, ${user?.loginId ?? ''}',
                          style: GoogleFonts.outfit(
                            color: AppTheme.pureWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Collector • ${formatDate(DateTime.now())}',
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
            const SizedBox(height: 16),

            // Today's Assignment card
            Text(
              "Today's Assignment",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkBlack,
              ),
            ),
            const SizedBox(height: 8),
            AsyncView<DailyAssignment?>(
              future: _loadAssignment,
              loadingMessage: 'Checking assignment…',
              builder: (context, assignment) {
                if (assignment == null) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_busy_rounded,
                          color: AppTheme.textMuted,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _assignmentError ??
                                'No assignment for today. You can still create a collection request.',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.lightGreen, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: ClipPath(
                          clipper: HexagonClipper(),
                          child: Container(
                            color: AppTheme.primaryGreen,
                            child: const Center(
                              child: Icon(
                                Icons.calendar_today_rounded,
                                color: AppTheme.pureWhite,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assignment for ${formatDate(DateTime.now())}',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.darkBlack,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${assignment.collector.fullName} • ${assignment.collector.mobile}',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Create Request CTA
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateRequestScreen(),
                    ),
                  );
                  _refreshAll();
                },
                icon: const Icon(Icons.add_location_alt_rounded),
                label: Text(
                  'Create Collection Request',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Leaderboard section (top performers this month)
            Row(
              children: [
                const Icon(Icons.leaderboard_rounded,
                    color: AppTheme.primaryGreen, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Leaderboard',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlack,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _openFullLeaderboard,
                  child: Text(
                    'View All',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AsyncView<List<LeaderboardEntry>>(
              key: ValueKey('lb$_reloadTick'),
              future: _loadLeaderboard,
              loadingMessage: 'Loading leaderboard…',
              builder: (context, entries) {
                if (entries.isEmpty) {
                  return const EmptyView(
                    icon: Icons.emoji_events_outlined,
                    title: 'No collections yet',
                    subtitle: 'Leaderboard updates once collections are completed.',
                  );
                }
                return Column(
                  children: [
                    for (final entry in entries.take(5))
                      _buildLeaderboardTile(entry),
                    if (entries.length > 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: TextButton(
                          onPressed: _openFullLeaderboard,
                          child: Text(
                            'Show all ${entries.length} collectors',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Recent requests
            Row(
              children: [
                const Icon(Icons.history_rounded,
                    color: AppTheme.primaryGreen, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Recent Requests',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AsyncView<List<CollectionRequest>>(
              key: ValueKey('recent$_reloadTick'),
              future: _loadRecent,
              loadingMessage: 'Loading requests…',
              builder: (context, requests) {
                if (requests.isEmpty) {
                  return const EmptyView(
                    icon: Icons.inbox_outlined,
                    title: 'No requests yet',
                    subtitle: 'Create your first collection request above.',
                  );
                }
                return Column(
                  children: [
                    for (final request in requests)
                      _buildMiniRequestTile(request),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _openFullLeaderboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
    );
  }

  Widget _buildLeaderboardTile(LeaderboardEntry entry) {
    final (badgeColor, icon) = switch (entry.rank) {
      1 => (AppTheme.gold, Icons.military_tech_rounded),
      2 => (AppTheme.silver, Icons.military_tech_rounded),
      3 => (AppTheme.bronze, Icons.military_tech_rounded),
      _ => (AppTheme.lightGreen, null),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: ClipPath(
              clipper: HexagonClipper(),
              child: Container(
                color: badgeColor,
                child: Center(
                  child: icon != null
                      ? Icon(icon, color: AppTheme.pureWhite, size: 18)
                      : Text(
                          '#${entry.rank}',
                          style: GoogleFonts.outfit(
                            color: AppTheme.pureWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.fullName,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.darkBlack,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${formatWeight(entry.totalWeightKg)} kg',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entry.totalCollections} jobs',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniRequestTile(CollectionRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded,
              size: 18, color: AppTheme.primaryGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${request.latitude.toStringAsFixed(5)}, ${request.longitude.toStringAsFixed(5)}',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.darkBlack,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            statusLabel(request.status),
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _statusColor(request.status),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(RequestStatus status) => switch (status) {
        RequestStatus.pending => const Color(0xFFEF6C00),
        RequestStatus.accepted => const Color(0xFF1565C0),
        RequestStatus.completed => AppTheme.primaryGreen,
        RequestStatus.cancelled => AppTheme.textMuted,
      };
}