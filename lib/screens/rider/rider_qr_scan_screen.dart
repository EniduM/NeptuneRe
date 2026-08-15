import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../models/api_models.dart';
import '../../providers/app_state.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';

/// Rider: scan the Collector's permanent QR and verify it server-side via
/// POST /rider/collection-requests/:id/verify-qr.
///
/// Pops `true` when verification succeeds (returns to the workflow hub).
class RiderQrScanScreen extends StatefulWidget {
  final CollectionRequest request;

  const RiderQrScanScreen({super.key, required this.request});

  @override
  State<RiderQrScanScreen> createState() => _RiderQrScanScreenState();
}

class _RiderQrScanScreenState extends State<RiderQrScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  final TextEditingController _manualController = TextEditingController();
  bool _isVerifying = false;
  bool _verified = false;
  String? _error;

  @override
  void dispose() {
    _scannerController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty && !_isVerifying && !_verified) {
        _manualController.text = value;
        _verify(value);
        break;
      }
    }
  }

  Future<void> _verify(String token) async {
    if (_isVerifying || _verified) return;
    final trimmed = token.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _isVerifying = true;
      _error = null;
    });
    try {
      await context
          .read<AppState>()
          .api
          .rider
          .verifyQr(requestId: widget.request.id, qrToken: trimmed);
      if (!mounted) return;
      setState(() => _verified = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR verified — Collector identity confirmed.'),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.statusCode == 409
            ? 'This QR does not match the Collector for this request.'
            : e.message;
      });
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Collector QR'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Camera scanner frame
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 300,
              decoration: BoxDecoration(
                color: AppTheme.darkBlack,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    if (!_verified)
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: _onDetect,
                        errorBuilder: (context, error) =>
                            _buildScannerFallback(),
                      )
                    else
                      _buildVerifiedOverlay(),
                    if (!_verified) ...[
                      Center(
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.lightGreen.withValues(alpha: 0.8),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.qr_code_2_rounded,
                              size: 90,
                              color:
                                  AppTheme.lightGreen.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.darkBlack.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'SCAN COLLECTOR QR',
                              style: GoogleFonts.outfit(
                                color: AppTheme.lightGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Verification status
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: _verified
                  ? _buildStatusCard(
                      icon: Icons.verified_rounded,
                      color: AppTheme.primaryGreen,
                      title: 'Collector Verified',
                      subtitle: 'Identity confirmed. You can now enter the weight.',
                    )
                  : _isVerifying
                      ? _buildStatusCard(
                          icon: Icons.hourglass_top_rounded,
                          color: AppTheme.primaryGreen,
                          title: 'Verifying…',
                          subtitle: 'Checking QR token with the server.',
                        )
                      : _error != null
                          ? _buildStatusCard(
                              icon: Icons.error_rounded,
                              color: Colors.redAccent,
                              title: 'Verification Failed',
                              subtitle: _error!,
                            )
                          : _buildStatusCard(
                              icon: Icons.qr_code_scanner_rounded,
                              color: AppTheme.textMuted,
                              title: 'Scan the Collector\'s permanent QR',
                              subtitle:
                                  'The QR card must belong to the Collector linked to this request.',
                            ),
            ),

            // Manual entry fallback
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.mintGreen,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.lightGreen),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.keyboard_rounded,
                          color: AppTheme.primaryGreen, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Manual QR input (if scanning fails):',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualController,
                          enabled: !_verified,
                          decoration: const InputDecoration(
                            hintText: 'Paste or type the QR token',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _verified
                            ? null
                            : () => _verify(_manualController.text),
                        child: Text(
                          _isVerifying ? '…' : 'Verify',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_verified)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(
                      'Continue to Weight Entry',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.darkBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
  }

  Widget _buildVerifiedOverlay() {
    return Container(
      color: AppTheme.primaryGreen,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, color: AppTheme.pureWhite, size: 72),
            SizedBox(height: 8),
            Text(
              'VERIFIED',
              style: TextStyle(
                color: AppTheme.pureWhite,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerFallback() {
    return Container(
      color: const Color(0xFF1F2937),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 42,
              color: AppTheme.lightGreen,
            ),
            const SizedBox(height: 8),
            Text(
              'Camera Scanner Ready',
              style: GoogleFonts.outfit(
                color: AppTheme.pureWhite,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Or type the QR token below',
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}