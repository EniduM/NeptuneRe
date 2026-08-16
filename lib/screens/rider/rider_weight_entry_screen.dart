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

/// Rider: enter the TOTAL weight (kg) of the collected waste, select the
/// vehicle, and complete the collection (POST .../complete).
///
/// There is no bag-count feature — the total weight is the only measure.
class RiderWeightEntryScreen extends StatefulWidget {
  final CollectionRequest request;
  final bool qrVerified;

  const RiderWeightEntryScreen({
    super.key,
    required this.request,
    required this.qrVerified,
  });

  @override
  State<RiderWeightEntryScreen> createState() => _RiderWeightEntryScreenState();
}

class _RiderWeightEntryScreenState extends State<RiderWeightEntryScreen> {
  final TextEditingController _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Vehicle? _selectedVehicle;
  bool _isSubmitting = false;
  bool _completed = false;
  CompleteCollectionResponse? _result;

  Future<List<Vehicle>> _loadVehicles() =>
      context.read<AppState>().api.rider.vehicles();

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (_isSubmitting || _completed) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a vehicle'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final weight = double.parse(_weightController.text.trim());
      final completed = await context.read<AppState>().api.rider.complete(
            requestId: widget.request.id,
            vehicleId: _selectedVehicle!.id,
            weightKg: weight,
          );
      if (!mounted) return;
      setState(() {
        _result = completed;
        _completed = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Complete Collection')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppTheme.mintGreen,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppTheme.primaryGreen, width: 3),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 52,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Collection Completed!',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlack,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'The request and collection record are saved.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                if (_result != null)
                  LiquidGlassCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: [
                        _successRow(
                          Icons.monitor_weight_rounded,
                          'Total weight',
                          '${formatWeight(_result!.collection.weightKg)} kg',
                        ),
                        const SizedBox(height: 10),
                        _successRow(
                          Icons.local_shipping_rounded,
                          'Vehicle',
                          _result!.collection.vehicle == null
                              ? '—'
                              : '${_result!.collection.vehicle!.vehicleCode} (${_result!.collection.vehicle!.vehicleType})',
                        ),
                        const SizedBox(height: 10),
                        _successRow(
                          Icons.receipt_long_rounded,
                          'Request ID',
                          _result!.request.id.substring(0, 8).toUpperCase(),
                        ),
                        const SizedBox(height: 10),
                        _successRow(
                          Icons.inventory_2_rounded,
                          'Collection ID',
                          _result!.collection.id.substring(0, 8).toUpperCase(),
                        ),
                        const SizedBox(height: 10),
                        _successRow(
                          Icons.check_circle_rounded,
                          'Request status',
                          '${statusLabel(_result!.request.status)} • ${formatDateTime(_result!.request.completedAt)}',
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Enter Total Weight')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Collector summary
            LiquidGlassCard(
              padding: const EdgeInsets.all(14),
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: ClipPath(
                      clipper: HexagonClipper(),
                      child: Container(
                        color: AppTheme.primaryGreen,
                        child: Center(
                          child: Text(
                            (widget.request.collector?.fullName ?? 'C')
                                .isNotEmpty
                                ? (widget.request.collector!.fullName)[0]
                                    .toUpperCase()
                                : 'C',
                            style: GoogleFonts.outfit(
                              color: AppTheme.pureWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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
                          widget.request.collector?.fullName ?? 'Collector',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.darkBlack,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.request.latitude.toStringAsFixed(5)}, ${widget.request.longitude.toStringAsFixed(5)}',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.mintGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded,
                            size: 14, color: AppTheme.primaryGreen),
                        const SizedBox(width: 4),
                        Text(
                          widget.qrVerified ? 'QR OK' : 'QR NOT VERIFIED',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: widget.qrVerified
                                ? AppTheme.primaryGreen
                                : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Total Weight (kg)',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Weigh the collected waste and enter the TOTAL weight in kilograms.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Weight in kg',
                      hintText: 'e.g. 45.5',
                      prefixIcon: const Icon(Icons.monitor_weight_outlined,
                          color: AppTheme.primaryGreen),
                      suffixText: 'kg',
                      suffixStyle: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    validator: (val) {
                      final value = val?.trim() ?? '';
                      final parsed = double.tryParse(value);
                      if (parsed == null) {
                        return 'Enter a valid weight';
                      }
                      if (parsed <= 0) {
                        return 'Weight must be greater than 0';
                      }
                      if (parsed > 100000) {
                        return 'Weight looks too large — check the value';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Select Vehicle',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose the vehicle used for this collection.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildVehiclePicker(),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _complete,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppTheme.pureWhite,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(Icons.check_circle_rounded),
                      label: Text(
                        _isSubmitting
                            ? 'Completing…'
                            : 'Complete Collection',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// PENDING BACKEND: no rider-accessible endpoint exists to list vehicles.
  /// RiderApi.vehicles() currently returns a local mock list from
  /// lib/config/mock_vehicles.dart, but completion still calls the real
  /// POST /rider/collection-requests/:id/complete endpoint.
  Widget _buildVehiclePicker() {
    return AsyncView<List<Vehicle>>(
      future: _loadVehicles,
      loadingMessage: 'Loading vehicles…',
      builder: (context, vehicles) {
        final active = vehicles.where((v) => v.isActive).toList();
        if (active.isEmpty) {
          return LiquidGlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFB45309), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'No active vehicles available',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'A vehicle must be assigned by the Neptune administrator before a collection can be completed.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          );
        }
        return DropdownButtonFormField<Vehicle>(
          initialValue: _selectedVehicle,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Vehicle',
            prefixIcon: Icon(Icons.local_shipping_outlined,
                color: AppTheme.primaryGreen),
          ),
          items: [
            for (final vehicle in active)
              DropdownMenuItem(
                value: vehicle,
                child: Text(
                  '${vehicle.vehicleCode} — ${vehicle.vehicleType}',
                  style: GoogleFonts.outfit(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (v) => setState(() => _selectedVehicle = v),
        );
      },
    );
  }

  Widget _successRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryGreen),
        const SizedBox(width: 10),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              color: AppTheme.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkBlack,
            ),
          ),
        ),
      ],
    );
  }
}