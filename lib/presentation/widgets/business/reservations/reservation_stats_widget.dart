// Reservation Stats Widget
//
// Phase 15: Reservation System Implementation
// Section 15.3.1: Business Reservation Dashboard
//
// Widget for displaying reservation statistics for business owners

import 'package:flutter/material.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/widgets/business/business_stats_card.dart';

/// Reservation Stats Widget
///
/// **Purpose:** Display key reservation statistics for business owners
///
/// **Features:**
/// - Total reservations count
/// - Pending reservations count
/// - Confirmed reservations count
/// - Today's reservations count
/// - Revenue (if paid reservations)
class ReservationStatsWidget extends StatelessWidget {
  final List<Reservation> reservations;

  const ReservationStatsWidget({
    super.key,
    required this.reservations,
  });

  /// Calculate statistics from reservations
  Map<String, dynamic> _calculateStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int total = reservations.length;
    int pending = 0;
    int confirmed = 0;
    int todayCount = 0;

    for (final reservation in reservations) {
      // Count by status
      if (reservation.status == ReservationStatus.pending) {
        pending++;
      } else if (reservation.status == ReservationStatus.confirmed) {
        confirmed++;
      }

      // Count today's reservations
      final reservationDate = DateTime(
        reservation.reservationTime.year,
        reservation.reservationTime.month,
        reservation.reservationTime.day,
      );
      if (reservationDate == today) {
        todayCount++;
      }
    }

    return {
      'total': total,
      'pending': pending,
      'confirmed': confirmed,
      'today': todayCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            BusinessStatsCard(
              label: 'Total',
              value: '${stats['total']}',
              icon: Icons.event_available,
              color: AppTheme.primaryColor,
            ),
            BusinessStatsCard(
              label: 'Pending',
              value: '${stats['pending']}',
              icon: Icons.pending,
              color: AppColors.warning,
            ),
            BusinessStatsCard(
              label: 'Confirmed',
              value: '${stats['confirmed']}',
              icon: Icons.check_circle,
              color: AppColors.success,
            ),
            BusinessStatsCard(
              label: "Today's",
              value: '${stats['today']}',
              icon: Icons.today,
              color: AppColors.electricGreen,
            ),
          ],
        ),
      ],
    );
  }
}
