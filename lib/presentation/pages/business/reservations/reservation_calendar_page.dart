// Reservation Calendar Page
//
// Phase 15: Reservation System Implementation
// Section 15.3.1: Business Reservation Dashboard
//
// Page for displaying reservations in calendar format

import 'package:flutter/material.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/widgets/business/reservations/reservation_calendar_widget.dart';
import 'package:avrai/presentation/widgets/reservations/reservation_card_widget.dart';
import 'package:avrai/presentation/pages/reservations/reservation_detail_page.dart';
import 'package:avrai/injection_container.dart' as di;

/// Reservation Calendar Page
///
/// **Purpose:** Display reservations in a calendar view for business owners
///
/// **Features:**
/// - Calendar month view
/// - Select date to view reservations
/// - List reservations for selected date
class ReservationCalendarPage extends StatefulWidget {
  final String businessId;

  const ReservationCalendarPage({
    super.key,
    required this.businessId,
  });

  @override
  State<ReservationCalendarPage> createState() => _ReservationCalendarPageState();
}

class _ReservationCalendarPageState extends State<ReservationCalendarPage> {
  late final ReservationService _reservationService;
  List<Reservation> _allReservations = [];
  DateTime? _selectedDate;
  List<Reservation> _selectedDateReservations = [];
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
          _allReservations = reservations;
          _isLoading = false;
        });

        // Select today if available
        if (_selectedDate == null) {
          _selectDate(DateTime.now());
        }
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

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      final selectedDateOnly = DateTime(date.year, date.month, date.day);

      _selectedDateReservations = _allReservations.where((reservation) {
        final reservationDate = DateTime(
          reservation.reservationTime.year,
          reservation.reservationTime.month,
          reservation.reservationTime.day,
        );
        return reservationDate == selectedDateOnly;
      }).toList();

      // Sort by time
      _selectedDateReservations.sort((a, b) =>
          a.reservationTime.compareTo(b.reservationTime));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation Calendar'),
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
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Calendar Widget
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        child: ReservationCalendarWidget(
                          reservations: _allReservations,
                          onDateSelected: _selectDate,
                        ),
                      ),
                    ),

                    // Selected Date Reservations
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          border: Border(
                            top: BorderSide(color: AppColors.grey300, width: 1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedDate != null
                                        ? '${_formatDate(_selectedDate!)} (${_selectedDateReservations.length})'
                                        : 'Select a date',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: _selectedDateReservations.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.event_busy,
                                            size: 48,
                                            color: AppColors.grey400,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'No reservations',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: AppColors.textSecondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      itemCount: _selectedDateReservations.length,
                                      itemBuilder: (context, index) {
                                        final reservation = _selectedDateReservations[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: ReservationCardWidget(
                                            reservation: reservation,
                                            onTap: () async {
                                              final result = await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ReservationDetailPage(
                                                    reservationId: reservation.id,
                                                  ),
                                                ),
                                              );
                                              if (result == true) {
                                                _loadReservations();
                                              }
                                            },
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
