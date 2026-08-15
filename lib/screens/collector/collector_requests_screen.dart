import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/api_models.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/async_states.dart';
import '../../widgets/request_card.dart';
import 'collector_request_detail_screen.dart';

/// Collector: list of own collection requests (history + tracking).
class CollectorRequestsScreen extends StatefulWidget {
  const CollectorRequestsScreen({super.key});

  @override
  State<CollectorRequestsScreen> createState() =>
      _CollectorRequestsScreenState();
}

class _CollectorRequestsScreenState extends State<CollectorRequestsScreen> {
  int _reloadTick = 0;

  Future<List<CollectionRequest>> _load() =>
      context.read<AppState>().api.collector.myRequests();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryGreen),
            tooltip: 'Refresh',
            onPressed: () => setState(() => _reloadTick++),
          ),
        ],
      ),
      body: AsyncView<List<CollectionRequest>>(
        key: ValueKey(_reloadTick),
        future: _load,
        loadingMessage: 'Loading requests…',
        builder: (context, requests) {
          if (requests.isEmpty) {
            return const EmptyView(
              icon: Icons.inbox_outlined,
              title: 'No collection requests yet',
              subtitle: 'Create a request from the dashboard to get started.',
            );
          }
          final pending = requests
              .where((r) => r.status == RequestStatus.pending)
              .toList();
          return RefreshIndicator(
            onRefresh: () async =>
                setState(() => _reloadTick++),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: requests.length + (pending.isEmpty ? 0 : 1),
              itemBuilder: (context, index) {
                if (pending.isNotEmpty && index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.mintGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.hourglass_top_rounded,
                            size: 16,
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${pending.length} request(s) waiting for a Rider',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final request = requests[index - (pending.isEmpty ? 0 : 1)];
                return RequestCard(
                  request: request,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CollectorRequestDetailScreen(
                          requestId: request.id,
                        ),
                      ),
                    );
                    setState(() => _reloadTick++);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}