// Spot Reservation Badge Widget
//
// Phase 15: Reservation System Implementation
// Section 15.2.3: Reservation Integration with Spots
//
// Widget for displaying reservation availability on spots

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/app_theme.dart';

/// Spot Reservation Badge Widget
///
/// **Purpose:** Display reservation availability status on spot cards and details
///
/// **Features:**
/// - Available badge (can make reservation)
/// - Unavailable badge (fully booked or closed)
/// - Limited availability badge (few spots left)
/// - Has reservation badge (user already has reservation)
/// - Compact mode for cards
/// - Full mode for details
class SpotReservationBadgeWidget extends StatelessWidget {
  final bool isAvailable;
  final bool hasExistingReservation;
  final int? availableCapacity;
  final bool compact;
  final VoidCallback? onTap;

  const SpotReservationBadgeWidget({
    super.key,
    required this.isAvailable,
    this.hasExistingReservation = false,
    this.availableCapacity,
    this.compact = true,
    this.onTap,
  });

  String _getBadgeText() {
    if (hasExistingReservation) {
      return compact ? 'Reserved' : 'You have a reservation';
    }
    if (!isAvailable) {
      return compact ? 'Unavailable' : 'Reservations unavailable';
    }
    if (availableCapacity != null && availableCapacity! > 0 && availableCapacity! <= 5) {
      return compact ? '$availableCapacity left' : '$availableCapacity spots left';
    }
    return compact ? 'Available' : 'Reservations available';
  }

  Color _getBadgeColor() {
    if (hasExistingReservation) {
      return AppTheme.successColor;
    }
    if (!isAvailable) {
      return AppTheme.errorColor;
    }
    if (availableCapacity != null && availableCapacity! > 0 && availableCapacity! <= 5) {
      return AppTheme.warningColor;
    }
    return AppTheme.successColor;
  }

  IconData _getBadgeIcon() {
    if (hasExistingReservation) {
      return Icons.check_circle;
    }
    if (!isAvailable) {
      return Icons.cancel;
    }
    if (availableCapacity != null && availableCapacity! > 0 && availableCapacity! <= 5) {
      return Icons.warning_amber_rounded;
    }
    return Icons.event_available;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getBadgeColor();
    final icon = _getBadgeIcon();
    final text = _getBadgeText();

    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );

    if (onTap != null && !hasExistingReservation && isAvailable) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        child: badge,
      );
    }

    return badge;
  }
}
