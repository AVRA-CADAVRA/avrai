// Business Reservations Page
//
// Phase 15: Reservation System Implementation
// Section 15.2.4: Reservation Integration with Businesses
//
// Page for business owners to manage reservations for their business

import 'package:flutter/material.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/pages/reservations/reservation_detail_page.dart';
import 'package:avrai/presentation/widgets/reservations/reservation_card_widget.dart';
import 'package:avrai/injection_container.dart' as di;

/// Business Reservations Page
/// 
/// Shows all reservations for a business (for business owners)
/// 
/// Features:
/// - Display business reservations
/// - Filter by status (pending, confirmed, cancelled, past)
/// - View reservation details
class BusinessReservationsPage extends StatefulWidget {
  final String businessId;

  const BusinessReservationsPage({
    super.key,
    required this.businessId,
  });

  @override
  State<BusinessReservationsPage> createState() => _BusinessReservationsPageState();
}

class _BusinessReservationsPageState extends State<BusinessReservationsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final ReservationService _reservationService;

  List<Reservation> _pendingReservations = [];
  List<Reservation> _confirmedReservations = [];
  List<Reservation> _cancelledReservations = [];
  List<Reservation> _pastReservations = [];

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _reservationService = di.sl<ReservationService>();
    _loadReservations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all reservations for this business
      final reservations = await _reservationService.getReservationsForTarget(
        type: ReservationType.business,
        targetId: widget.businessId,
      );

      // Separate by status
      final now = DateTime.now();
      final pending = <Reservation>[];
      final confirmed = <Reservation>[];
      final cancelled = <Reservation>[];
      final past = <Reservation>[];

      for (final reservation in reservations) {
        if (reservation.status == ReservationStatus.cancelled) {
          cancelled.add(reservation);
        } else if (reservation.reservationTime.isBefore(now)) {
          past.add(reservation);
        } else if (reservation.status == ReservationStatus.pending) {
          pending.add(reservation);
        } else if (reservation.status == ReservationStatus.confirmed) {
          confirmed.add(reservation);
        }
      }

      // Sort by date (upcoming first)
      pending.sort((a, b) => a.reservationTime.compareTo(b.reservationTime));
      confirmed.sort((a, b) => a.reservationTime.compareTo(b.reservationTime));
      cancelled.sort((a, b) => b.reservationTime.compareTo(a.reservationTime));
      past.sort((a, b) => b.reservationTime.compareTo(a.reservationTime));

      setState(() {
        _pendingReservations = pending;
        _confirmedReservations = confirmed;
        _cancelledReservations = cancelled;
        _pastReservations = past;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load reservations: $e';
        _isLoading = false;
      });
    }
  }

  List<Reservation> _getReservationsForTab(int index) {
    switch (index) {
      case 0:
        return _pendingReservations;
      case 1:
        return _confirmedReservations;
      case 2:
        return _cancelledReservations;
      case 3:
        return _pastReservations;
      default:
        return [];
    }
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Pending (${_pendingReservations.length})';
      case 1:
        return 'Confirmed (${_confirmedReservations.length})';
      case 2:
        return 'Cancelled (${_cancelledReservations.length})';
      case 3:
        return 'Past (${_pastReservations.length})';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Reservations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: _getTabTitle(0)),
            Tab(text: _getTabTitle(1)),
            Tab(text: _getTabTitle(2)),
            Tab(text: _getTabTitle(3)),
          ],
        ),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
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
          : TabBarView(
              controller: _tabController,
              children: List.generate(4, (index) {
                final reservations = _getReservationsForTab(index);
                return _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadReservations,
                        child: reservations.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.event_busy,
                                      size: 64,
                                      color: AppColors.grey400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No ${_getTabTitle(index).split(' ')[0].toLowerCase()} reservations',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: reservations.length,
                                padding: const EdgeInsets.all(16),
                                itemBuilder: (context, i) {
                                  final reservation = reservations[i];
                                  return ReservationCardWidget(
                                    reservation: reservation,
                                    onTap: () async {
                                      final result = await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => ReservationDetailPage(
                                            reservationId: reservation.id,
                                          ),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadReservations();
                                      }
                                    },
                                  );
                                },
                              ),
                      );
              }),
            ),
    );
  }
}
