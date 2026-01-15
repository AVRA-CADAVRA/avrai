// Spot Reservation Marker
//
// Phase 15: Reservation System Implementation
// Section 15.2.3: Reservation Integration with Spots
//
// Map marker widget with reservation availability indicator

import 'package:flutter/material.dart';
import 'package:avrai/core/models/spot.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';

/// Map marker with reservation availability indicator
class SpotReservationMarker extends StatelessWidget {
  final Spot spot;
  final bool? isReservationAvailable;
  final bool? hasExistingReservation;
  final VoidCallback? onTap;

  const SpotReservationMarker({
    super.key,
    required this.spot,
    this.isReservationAvailable,
    this.hasExistingReservation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main marker icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white,
                width: 2,
              ),
            ),
            child: Icon(
              _getCategoryIcon(spot.category),
              color: AppColors.white,
              size: 20,
            ),
          ),
          // Reservation indicator badge (top-right corner)
          if (isReservationAvailable != null || hasExistingReservation == true)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getReservationBadgeColor(),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  _getReservationIcon(),
                  color: AppColors.white,
                  size: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getReservationBadgeColor() {
    if (hasExistingReservation == true) {
      return AppTheme.successColor;
    }
    if (isReservationAvailable == true) {
      return AppTheme.successColor;
    }
    return AppColors.grey400; // Unavailable
  }

  IconData _getReservationIcon() {
    if (hasExistingReservation == true) {
      return Icons.check_circle;
    }
    if (isReservationAvailable == true) {
      return Icons.event_available;
    }
    return Icons.event_busy; // Unavailable
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'coffee':
        return Icons.coffee;
      case 'bakery':
        return Icons.cake;
      case 'park':
        return Icons.park;
      case 'restaurant':
        return Icons.restaurant;
      case 'attraction':
        return Icons.attractions;
      default:
        return Icons.place;
    }
  }
}
