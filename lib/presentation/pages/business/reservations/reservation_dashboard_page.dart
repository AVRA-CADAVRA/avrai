// Reservation Dashboard Page
//
// Phase 15: Reservation System Implementation
// Section 15.3.1: Business Reservation Dashboard
//
// Main dashboard page for business owners to manage reservations

import 'package:flutter/material.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/widgets/business/reservations/reservation_stats_widget.dart';
import 'package:avrai/presentation/pages/business/reservations/reservation_calendar_page.dart';
import 'package:avrai/presentation/pages/business/business_reservations_page.dart';
import 'package:avrai/presentation/pages/business/reservations/business_reservation_analytics_page.dart';
import 'package:avrai/injection_container.dart' as di;

/// Reservation Dashboard Page
///
/// **Purpose:** Main dashboard for business reservation management
///
/// **Features:**
/// - Reservation statistics overview
/// - Navigation to calendar view
/// - Navigation to list view
/// - Quick actions overview
class ReservationDashboardPage extends StatefulWidget {
  final String businessId;

  const ReservationDashboardPage({
    super.key,
    required this.businessId,
  });

  @override
  State<ReservationDashboardPage> createState() =>
      _ReservationDashboardPageState();
}

class _ReservationDashboardPageState extends State<ReservationDashboardPage> {
  late final ReservationService _reservationService;
  List<Reservation> _reservations = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reservationService = di.sl<ReservationService>();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reservations = await _reservationService.getReservationsForTarget(
        type: ReservationType.business,
        targetId: widget.businessId,
      );

      if (mounted) {
        setState(() {
          _reservations = reservations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load reservations: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation Dashboard'),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: AppTheme.errorColor),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.errorColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadReservations,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadReservations,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statistics
                        ReservationStatsWidget(
                          reservations: _reservations,
                        ),
                        const SizedBox(height: 24),

                        // Navigation Cards
                        Text(
                          'Views',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
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
                          childAspectRatio: 1.8,
                          children: [
                            _buildNavigationCard(
                              context,
                              title: 'Calendar View',
                              subtitle: 'View by date',
                              icon: Icons.calendar_today,
                              color: AppTheme.primaryColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ReservationCalendarPage(
                                      businessId: widget.businessId,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildNavigationCard(
                              context,
                              title: 'List View',
                              subtitle: 'Filter & manage',
                              icon: Icons.list,
                              color: AppColors.electricGreen,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BusinessReservationsPage(
                                      businessId: widget.businessId,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildNavigationCard(
                              context,
                              title: 'Analytics',
                              subtitle: 'View insights',
                              icon: Icons.analytics,
                              color: AppTheme.primaryColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BusinessReservationAnalyticsPage(
                                      businessId: widget.businessId,
                                      type: ReservationType.business,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
