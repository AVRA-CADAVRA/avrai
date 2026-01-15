// Spot Card with Reservation
//
// Phase 15: Reservation System Implementation
// Section 15.2.3: Reservation Integration with Spots
//
// Wrapper widget that checks reservation status for a spot card

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/models/spot.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/services/reservation_availability_service.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/presentation/widgets/spots/spot_card.dart';
import 'package:avrai/presentation/pages/reservations/create_reservation_page.dart';

/// Wrapper widget that checks reservation status and displays spot card with reservation badge
class SpotCardWithReservation extends StatefulWidget {
  final Spot spot;
  final VoidCallback? onTap;

  const SpotCardWithReservation({
    super.key,
    required this.spot,
    this.onTap,
  });

  @override
  State<SpotCardWithReservation> createState() => _SpotCardWithReservationState();
}

class _SpotCardWithReservationState extends State<SpotCardWithReservation> {
  bool _hasExistingReservation = false;
  bool _isReservationAvailable = true;
  int? _availableCapacity;
  bool _hasCheckedOnce = false;

  @override
  void initState() {
    super.initState();
    // Delay check slightly to not block list rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkReservationStatus();
    });
  }

  Future<void> _checkReservationStatus() async {
    if (_hasCheckedOnce) return; // Only check once per widget lifecycle
    
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return; // No user, can't check reservations
    }

    try {
      final reservationService = di.sl<ReservationService>();
      final availabilityService = di.sl.isRegistered<ReservationAvailabilityService>()
          ? di.sl<ReservationAvailabilityService>()
          : null;

      final userId = authState.user.id;
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      // Check for existing reservation
      final userReservations = await reservationService.getUserReservationsForTarget(
        userId: userId,
        type: ReservationType.spot,
        targetId: widget.spot.id,
      );

      final hasActiveReservation = userReservations.any((r) =>
          r.status != ReservationStatus.cancelled &&
          r.reservationTime.isAfter(DateTime.now()));

      // Check availability (lightweight check - just basic availability)
      bool isAvailable = true;
      int? availableCapacity;

      if (availabilityService != null) {
        try {
          final availability = await availabilityService.checkAvailability(
            type: ReservationType.spot,
            targetId: widget.spot.id,
            reservationTime: tomorrow,
            partySize: 1,
          );

          isAvailable = availability.isAvailable;
          availableCapacity = availability.availableCapacity;
        } catch (e) {
          // If availability check fails, assume available
          isAvailable = true;
        }
      }

      if (mounted) {
        setState(() {
          _hasExistingReservation = hasActiveReservation;
          _isReservationAvailable = isAvailable;
          _availableCapacity = availableCapacity;
          _hasCheckedOnce = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isReservationAvailable = true; // Default to available on error
          _hasCheckedOnce = true;
        });
      }
    }
  }

  void _navigateToCreateReservation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateReservationPage(
          type: ReservationType.spot,
          targetId: widget.spot.id,
          targetTitle: widget.spot.name,
        ),
      ),
    ).then((_) {
      // Refresh reservation status after returning
      _hasCheckedOnce = false;
      _checkReservationStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SpotCard(
      spot: widget.spot,
      onTap: widget.onTap,
      isReservationAvailable: _hasCheckedOnce ? _isReservationAvailable : null,
      hasExistingReservation: _hasCheckedOnce ? _hasExistingReservation : null,
      availableCapacity: _availableCapacity,
      onReservationTap: _hasExistingReservation || !_isReservationAvailable 
          ? null 
          : _navigateToCreateReservation,
    );
  }
}
