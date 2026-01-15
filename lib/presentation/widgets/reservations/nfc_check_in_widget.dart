// NFC Check-In Widget
//
// Phase 10.1: Multi-Layered Check-In System
// Proximity-triggered NFC check-in UI component
//
// Displays NFC check-in option when user is in proximity to check-in location.

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/models/spot.dart';
import 'package:avrai/core/services/reservation_check_in_service.dart';
import 'package:avrai/core/services/reservation_proximity_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/data/repositories/spots_repository_impl.dart';
import 'package:avrai/domain/repositories/spots_repository.dart';

/// NFC Check-In Widget
///
/// **Purpose:** Displays proximity-triggered NFC check-in option
///
/// **Features:**
/// - Monitors proximity to check-in location
/// - Shows NFC check-in button when in proximity
/// - Handles NFC tag reading
/// - Performs multi-layer validation
/// - Shows check-in result
///
/// **Phase 10.1:** Multi-layered proximity-triggered check-in system
class NFCCheckInWidget extends StatefulWidget {
  final Reservation reservation;
  final Spot? spot; // Optional: if null, will fetch from repository
  final VoidCallback? onCheckInComplete;

  const NFCCheckInWidget({
    super.key,
    required this.reservation,
    this.spot,
    this.onCheckInComplete,
  });

  @override
  State<NFCCheckInWidget> createState() => _NFCCheckInWidgetState();
}

class _NFCCheckInWidgetState extends State<NFCCheckInWidget> {
  static const String _logName = 'NFCCheckInWidget';

  late final ReservationCheckInService _checkInService;
  late final ReservationProximityService _proximityService;

  bool _isInProximity = false;
  bool _isCheckingProximity = false;
  bool _isCheckingIn = false;
  String? _error;
  Spot? _spot;

  @override
  void initState() {
    super.initState();
    _checkInService = di.sl<ReservationCheckInService>();
    _proximityService = di.sl<ReservationProximityService>();
    _loadSpot();
    _startProximityMonitoring();
  }

  /// Load spot from repository if not provided
  Future<void> _loadSpot() async {
    if (widget.spot != null) {
      setState(() {
        _spot = widget.spot;
      });
      return;
    }

    // Load spot from repository
    try {
      final repository = di.sl<SpotsRepository>();
      if (repository is SpotsRepositoryImpl) {
        final spot = await repository.getSpotById(widget.reservation.targetId);
        if (mounted) {
          setState(() {
            _spot = spot;
          });
        }
      }
    } catch (e) {
      developer.log(
        'Error loading spot: $e',
        name: _logName,
      );
    }
  }

  /// Start monitoring proximity to check-in location
  Future<void> _startProximityMonitoring() async {
    if (_spot == null) {
      // Wait for spot to load
      await Future.delayed(const Duration(seconds: 1));
      if (_spot == null) {
        developer.log(
          'Spot not loaded, cannot monitor proximity',
          name: _logName,
        );
        return;
      }
    }

    // Check proximity periodically
    _checkProximity();
    // Check every 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _startProximityMonitoring();
      }
    });
  }

  /// Check if user is in proximity to check-in location
  Future<void> _checkProximity() async {
    if (_spot == null || _isCheckingProximity) {
      return;
    }

    setState(() {
      _isCheckingProximity = true;
    });

    try {
      // Get current location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Check proximity
      final inProximity = await _proximityService.isInProximity(
        spot: _spot!,
        userLat: position.latitude,
        userLon: position.longitude,
      );

      if (mounted) {
        setState(() {
          _isInProximity = inProximity;
          _isCheckingProximity = false;
        });
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error checking proximity: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() {
          _isCheckingProximity = false;
          _error = 'Failed to check proximity: ${e.toString()}';
        });
      }
    }
  }

  /// Handle NFC check-in
  Future<void> _handleNFCCheckIn() async {
    if (_spot == null) {
      setState(() {
        _error = 'Spot information not available';
      });
      return;
    }

    setState(() {
      _isCheckingIn = true;
      _error = null;
    });

    try {
      // Get current location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Try to read NFC tag (optional - if user taps phone to tag)
      NFCPayload? nfcPayload;
      try {
        nfcPayload = await _checkInService.readNFCTag();
        developer.log(
          nfcPayload != null
              ? 'NFC tag read: reservationId=${nfcPayload.reservationId}'
              : 'No NFC tag detected',
          name: _logName,
        );
      } catch (e) {
        developer.log(
          'NFC tag read failed (optional): $e',
          name: _logName,
        );
        // Continue without NFC payload (proximity-based check-in)
      }

      // Perform check-in with multi-layer validation
      final result = await _checkInService.checkInViaNFC(
        reservationId: widget.reservation.id,
        spot: _spot!,
        userLat: position.latitude,
        userLon: position.longitude,
        nfcPayload: nfcPayload,
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Checked in successfully! (Confidence: ${(result.confidenceScore * 100).toStringAsFixed(1)}%)',
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );

          // Notify parent
          widget.onCheckInComplete?.call();
        } else {
          setState(() {
            _error = result.error ?? 'Check-in failed';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Check-in failed'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error during NFC check-in: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() {
          _error = 'Check-in failed: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_spot == null) {
      return const SizedBox.shrink(); // Don't show until spot is loaded
    }

    // Only show NFC check-in option when in proximity
    if (!_isInProximity) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.nfc,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tap to Check In',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re near the check-in location. Tap your phone to check in.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.errorColor,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isCheckingIn ? null : _handleNFCCheckIn,
            icon: _isCheckingIn
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.nfc),
            label: Text(_isCheckingIn ? 'Checking In...' : 'Tap to Check In'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
