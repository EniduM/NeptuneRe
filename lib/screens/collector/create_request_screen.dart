import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../services/api_client.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/hexagon_clipper.dart';
import '../../widgets/liquid_glass.dart';

/// Collector creates a collection request using the current GPS location.
class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  double? _latitude;
  double? _longitude;
  String? _locationStatus;
  bool _isLocating = false;
  bool _isSubmitting = false;

  Future<void> _captureLocation() async {
    setState(() {
      _isLocating = true;
      _locationStatus = null;
    });
    try {
      final position = await LocationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationStatus = 'Location captured from GPS';
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _locationStatus = e.message;
        _latitude = null;
        _longitude = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationStatus = 'Unable to read GPS location. Please try again.';
        _latitude = null;
        _longitude = null;
      });
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _submit() async {
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Capture your GPS location first'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      // Backend contract: POST /collector/collection-requests accepts only
      // { latitude, longitude }.
      final created = await appState.api.collector.createRequest(
        latitude: _latitude!,
        longitude: _longitude!,
      );
      if (!mounted) return;
      Navigator.pop(context, created);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Collection request created — awaiting a Rider.'),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
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
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Collection Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                    width: 48,
                    height: 48,
                    child: ClipPath(
                      clipper: HexagonClipper(),
                      child: Container(
                        color: AppTheme.pureWhite,
                        child: const Center(
                          child: Icon(
                            Icons.my_location_rounded,
                            color: AppTheme.primaryGreen,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your current GPS position will be sent with the request so a Rider can find you.',
                      style: GoogleFonts.outfit(
                        color: AppTheme.pureWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              ),
            ),
            const SizedBox(height: 20),

            // GPS capture
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLocating ? null : _captureLocation,
                icon: _isLocating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppTheme.pureWhite,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.gps_fixed_rounded),
                label: Text(_isLocating ? 'Locating…' : 'Use My Current Location'),
              ),
            ),
            const SizedBox(height: 16),

            // Location preview
            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GPS Location',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_latitude != null && _longitude != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.place_rounded,
                            color: AppTheme.primaryGreen, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${_latitude!.toStringAsFixed(7)}, ${_longitude!.toStringAsFixed(7)}',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkBlack,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.mintGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Latitude must be -90 to 90 • Longitude -180 to 180',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Text(
                      _locationStatus ?? 'Tap the button above to capture your position.',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: _locationStatus != null
                            ? Colors.redAccent
                            : AppTheme.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppTheme.pureWhite,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isSubmitting ? 'Submitting…' : 'Submit Collection Request',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}