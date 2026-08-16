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
import '../../widgets/liquid_glass.dart';
import 'collector_request_detail_screen.dart';
import 'create_request_screen.dart';

/// Collector dashboard: today's assignment, quick create CTA and a
/// recent request summary.
class CollectorDashboardScreen extends StatefulWidget {
  const CollectorDashboardScreen({super.key});

  @override
  State<CollectorDashboardScreen> createState() =>
      _CollectorDashboardScreenState();
}

class _CollectorDashboardScreenState extends State<CollectorDashboardScreen> {
  int _reloadTick = 0;
  String? _assignmentError;

  /// The request returned by the 201 response from the create screen. Kept
  /// locally so the PENDING status from the POST response shows immediately
  /// instead of waiting for the next server refresh.
  CollectionRequest? _justCreated;

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

  Future<List<CollectionRequest>> _loadRecent() async {
    final all = await context.read<AppState>().api.collector.myRequests();
    final recent = all.take(3).toList();
    final created = _justCreated;
    if (created != null && !recent.any((r) => r.id == created.id)) {
      recent.insert(0, created);
    }
    return recent;
  }

  Future<List<CollectionRequest>> _loadAllRequests() async {
    final all = await context.read<AppState>().api.collector.myRequests();
    final created = _justCreated;
    if (created != null && !all.any((r) => r.id == created.id)) {
      return [created, ...all];
    }
    return all;
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
            LiquidGlassCard(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
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
            ),
            const SizedBox(height: 16),

            Text(
              'Request Overview',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkBlack,
              ),
            ),
            const SizedBox(height: 8),
            AsyncView<List<CollectionRequest>>(
              key: ValueKey('counts$_reloadTick'),
              future: _loadAllRequests,
              loadingMessage: 'Loading request counts…',
              builder: (context, requests) {
                final total = requests.length;
                final pending = requests
                    .where((r) => r.status == RequestStatus.pending)
                    .length;
                final completed = requests
                    .where((r) => r.status == RequestStatus.completed)
                    .length;
                final accepted = requests
                    .where((r) => r.status == RequestStatus.accepted)
                    .length;
                final cancelled = requests
                    .where((r) => r.status == RequestStatus.cancelled)
                    .length;
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _countCard(
                            'Requests',
                            total,
                            Icons.list_alt_rounded,
                            AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _countCard(
                            'Pending',
                            pending,
                            Icons.hourglass_top_rounded,
                            const Color(0xFFEF6C00),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _countCard(
                            'Completed',
                            completed,
                            Icons.check_circle_rounded,
                            AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LiquidGlassCard(
                      padding: const EdgeInsets.all(12),
                      borderRadius: BorderRadius.circular(14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.pie_chart_rounded,
                            size: 17,
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Current status: Pending $pending • Accepted $accepted • Completed $completed • Cancelled $cancelled',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),

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
                  return LiquidGlassCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(16),
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
                return LiquidGlassCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: BorderRadius.circular(16),
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
                  final created = await Navigator.push<CollectionRequest>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateRequestScreen(),
                    ),
                  );
                  if (created != null) {
                    setState(() => _justCreated = created);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CollectorRequestDetailScreen(
                          requestId: created.id,
                        ),
                      ),
                    );
                  }
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

  Widget _countCard(String label, int value, IconData icon, Color color) {
    return LiquidGlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.darkBlack,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniRequestTile(CollectionRequest request) {
    return LiquidGlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(14),
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