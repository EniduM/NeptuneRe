import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/api_models.dart';
import '../../providers/app_state.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/async_states.dart';
import '../../widgets/request_card.dart';
import 'rider_request_workflow_screen.dart';

/// Rider dashboard: all PENDING (available) collection requests, oldest
/// first, with auto-refresh every 30s and pull-to-refresh.
class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  Timer? _poller;
  int _reloadTick = 0;

  Future<List<CollectionRequest>> _load() =>
      context.read<AppState>().api.rider.pendingRequests();

  @override
  void initState() {
    super.initState();
    _poller = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted && !_isAccepting) setState(() => _reloadTick++);
      },
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  bool _isAccepting = false;

  Future<void> _accept(CollectionRequest request) async {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);

    CollectionRequest accepted;
    try {
      accepted = await context.read<AppState>().api.rider.acceptRequest(
            request.id,
          );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // 409 (already accepted by another Rider) and other failures:
      // refresh from the server instead of trusting any local state.
      setState(() {
        _isAccepting = false;
        _reloadTick++;
      });
      return;
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RiderRequestWorkflowScreen(initialRequest: accepted),
      ),
    );
    setState(() => _reloadTick++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Requests'),
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
        loadingMessage: 'Loading available requests…',
        builder: (context, requests) {
          if (requests.isEmpty) {
            return const EmptyView(
              icon: Icons.inbox_outlined,
              title: 'No available requests',
              subtitle:
                  'New requests appear here as Collectors create them. Pull down to refresh.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => _reloadTick++),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return RequestCard(
                  request: request,
                  trailing: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _isAccepting ? null : () => _accept(request),
                      icon: const Icon(Icons.check_circle_outline_rounded,
                          size: 18),
                      label: Text(
                        _isAccepting ? 'Booking…' : 'Accept Request',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}