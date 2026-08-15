import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/api_models.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/async_states.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/request_card.dart';
import 'rider_request_workflow_screen.dart';

/// Rider: all requests assigned to me (any status). Tapping an ACCEPTED
/// request resumes the collection workflow.
class RiderJobsScreen extends StatefulWidget {
  const RiderJobsScreen({super.key});

  @override
  State<RiderJobsScreen> createState() => _RiderJobsScreenState();
}

class _RiderJobsScreenState extends State<RiderJobsScreen> {
  Timer? _poller;
  int _reloadTick = 0;

  Future<List<CollectionRequest>> _load() =>
      context.read<AppState>().api.rider.myRequests();

  @override
  void initState() {
    super.initState();
    _poller = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) setState(() => _reloadTick++);
      },
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppTheme.primaryGreen),
            tooltip: 'Refresh',
            onPressed: () => setState(() => _reloadTick++),
          ),
        ],
      ),
      body: AsyncView<List<CollectionRequest>>(
        key: ValueKey(_reloadTick),
        future: _load,
        loadingMessage: 'Loading your jobs…',
        builder: (context, requests) {
          if (requests.isEmpty) {
            return const EmptyView(
              icon: Icons.local_shipping_outlined,
              title: 'No jobs assigned yet',
              subtitle: 'Accept an available request to start collecting.',
            );
          }
          final active = requests
              .where((r) => r.status == RequestStatus.accepted)
              .toList();
          return RefreshIndicator(
            onRefresh: () async => setState(() => _reloadTick++),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: requests.length + (active.isEmpty ? 0 : 1),
              itemBuilder: (context, index) {
                if (active.isNotEmpty && index == 0) {
                  return LiquidGlassCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_rounded,
                              color: AppTheme.pureWhite, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${active.length} active job(s) — tap to continue',
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.pureWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final request = requests[index - (active.isEmpty ? 0 : 1)];
                final isActive = request.status == RequestStatus.accepted;
                return RequestCard(
                  request: request,
                  onTap: isActive
                      ? () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RiderRequestWorkflowScreen(initialRequest: request),
                            ),
                          );
                          setState(() => _reloadTick++);
                        }
                      : null,
                  trailing: isActive
                      ? SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RiderRequestWorkflowScreen(
                                    initialRequest: request,
                                  ),
                                ),
                              );
                              setState(() => _reloadTick++);
                            },
                            icon: const Icon(Icons.arrow_forward_rounded,
                                size: 18),
                            label: Text(
                              'Continue Collection',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        )
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}