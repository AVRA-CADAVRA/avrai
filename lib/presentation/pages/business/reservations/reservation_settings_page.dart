// Reservation Settings Page
//
// Phase 15: Reservation System Implementation
// Section 15.3.2: Business Reservation Settings
//
// Main settings page for businesses to configure their reservation system

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/widgets/business/reservations/availability_settings_widget.dart';
import 'package:avrai/presentation/widgets/business/reservations/capacity_settings_widget.dart';
import 'package:avrai/presentation/widgets/business/reservations/time_slot_settings_widget.dart';
import 'package:avrai/presentation/widgets/business/reservations/pricing_settings_widget.dart';
import 'package:avrai/presentation/widgets/business/reservations/cancellation_policy_settings_widget.dart';
import 'package:avrai/presentation/widgets/business/reservations/rate_limit_settings_widget.dart';
import 'package:avrai/presentation/widgets/business/reservations/seating_chart_settings_widget.dart';
import 'package:avrai/presentation/widgets/business/reservations/notification_preferences_widget.dart';
import 'package:avrai/presentation/widgets/business/reservations/notification_history_widget.dart';

/// Reservation Settings Page
///
/// **Purpose:** Main settings page for business reservation configuration
///
/// **Features:**
/// - Business verification/setup
/// - Business hours configuration
/// - Holiday/closure calendar
/// - Capacity settings
/// - Time slot configuration
/// - Pricing settings
/// - Cancellation policy settings
/// - Rate limit settings
/// - Seating chart management
class ReservationSettingsPage extends StatefulWidget {
  final String businessId;

  const ReservationSettingsPage({
    super.key,
    required this.businessId,
  });

  @override
  State<ReservationSettingsPage> createState() =>
      _ReservationSettingsPageState();
}

class _ReservationSettingsPageState extends State<ReservationSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business Verification Section
            _buildSectionHeader(
              context,
              title: 'Business Setup',
              icon: Icons.business_center,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reservations Enabled',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        Switch(
                          value: true, // TODO: Get from business settings
                          onChanged: (value) {
                            // TODO: Save business reservation capability
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? 'Reservations enabled'
                                      : 'Reservations disabled',
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Allow customers to make reservations at your business',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Availability Settings
            _buildSectionHeader(
              context,
              title: 'Availability',
              icon: Icons.access_time,
            ),
            const SizedBox(height: 12),
            AvailabilitySettingsWidget(businessId: widget.businessId),
            const SizedBox(height: 24),

            // Capacity Settings
            _buildSectionHeader(
              context,
              title: 'Capacity',
              icon: Icons.people,
            ),
            const SizedBox(height: 12),
            CapacitySettingsWidget(businessId: widget.businessId),
            const SizedBox(height: 24),

            // Time Slot Settings
            _buildSectionHeader(
              context,
              title: 'Time Slots',
              icon: Icons.schedule,
            ),
            const SizedBox(height: 12),
            TimeSlotSettingsWidget(businessId: widget.businessId),
            const SizedBox(height: 24),

            // Pricing Settings
            _buildSectionHeader(
              context,
              title: 'Pricing',
              icon: Icons.attach_money,
            ),
            const SizedBox(height: 12),
            PricingSettingsWidget(businessId: widget.businessId),
            const SizedBox(height: 24),

            // Cancellation Policy Settings
            _buildSectionHeader(
              context,
              title: 'Cancellation Policy',
              icon: Icons.cancel_presentation,
            ),
            const SizedBox(height: 12),
            CancellationPolicySettingsWidget(businessId: widget.businessId),
            const SizedBox(height: 24),

            // Rate Limit Settings
            _buildSectionHeader(
              context,
              title: 'Rate Limits',
              icon: Icons.speed,
            ),
            const SizedBox(height: 12),
            RateLimitSettingsWidget(businessId: widget.businessId),
            const SizedBox(height: 24),

            // Seating Chart Settings
            _buildSectionHeader(
              context,
              title: 'Seating Charts',
              icon: Icons.event_seat,
            ),
            const SizedBox(height: 12),
            SeatingChartSettingsWidget(businessId: widget.businessId),
            const SizedBox(height: 24),

            // Notification Preferences
            _buildSectionHeader(
              context,
              title: 'Notifications',
              icon: Icons.notifications,
            ),
            const SizedBox(height: 12),
            NotificationPreferencesWidget(businessId: widget.businessId),
            const SizedBox(height: 24),

            // Notification History
            _buildSectionHeader(
              context,
              title: 'Notification History',
              icon: Icons.history,
            ),
            const SizedBox(height: 12),
            NotificationHistoryWidget(businessId: widget.businessId),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context,
      {required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}
