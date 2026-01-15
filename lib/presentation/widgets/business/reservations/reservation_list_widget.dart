// Reservation List Widget
//
// Phase 15: Reservation System Implementation
// Section 15.3.1: Business Reservation Dashboard
//
// Widget for displaying filtered list of reservations with quick actions

import 'package:flutter/material.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/widgets/reservations/reservation_card_widget.dart';
import 'package:avrai/injection_container.dart' as di;

/// Reservation List Widget
///
/// **Purpose:** Display filtered list of reservations with quick actions
///
/// **Features:**
/// - Filter by status
/// - Filter by date range
/// - Filter by time
/// - Quick actions (confirm, cancel, mark no-show)
class ReservationListWidget extends StatefulWidget {
  final List<Reservation> reservations;
  final Function(Reservation)? onReservationUpdated;

  const ReservationListWidget({
    super.key,
    required this.reservations,
    this.onReservationUpdated,
  });

  @override
  State<ReservationListWidget> createState() => _ReservationListWidgetState();
}

class _ReservationListWidgetState extends State<ReservationListWidget> {
  late final ReservationService _reservationService;
  ReservationStatus? _statusFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  List<Reservation> _filteredReservations = [];

  @override
  void initState() {
    super.initState();
    _reservationService = di.sl<ReservationService>();
    _applyFilters();
  }

  @override
  void didUpdateWidget(ReservationListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reservations != widget.reservations) {
      _applyFilters();
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredReservations = widget.reservations.where((reservation) {
        // Status filter
        if (_statusFilter != null && reservation.status != _statusFilter) {
          return false;
        }

        // Date range filter
        if (_startDate != null || _endDate != null) {
          final reservationDate = DateTime(
            reservation.reservationTime.year,
            reservation.reservationTime.month,
            reservation.reservationTime.day,
          );
          final start = _startDate != null
              ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day)
              : null;
          final end = _endDate != null
              ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day)
              : null;

          if (start != null && reservationDate.isBefore(start)) {
            return false;
          }
          if (end != null && reservationDate.isAfter(end)) {
            return false;
          }
        }

        // Time filter
        if (_startTime != null || _endTime != null) {
          final reservationTime =
              TimeOfDay.fromDateTime(reservation.reservationTime);
          if (_startTime != null && _isBefore(reservationTime, _startTime!)) {
            return false;
          }
          if (_endTime != null && _isAfter(reservationTime, _endTime!)) {
            return false;
          }
        }

        return true;
      }).toList();

      // Sort by date (upcoming first)
      _filteredReservations
          .sort((a, b) => a.reservationTime.compareTo(b.reservationTime));
    });
  }

  bool _isBefore(TimeOfDay a, TimeOfDay b) {
    if (a.hour < b.hour) return true;
    if (a.hour > b.hour) return false;
    return a.minute < b.minute;
  }

  bool _isAfter(TimeOfDay a, TimeOfDay b) {
    if (a.hour > b.hour) return true;
    if (a.hour < b.hour) return false;
    return a.minute > b.minute;
  }

  Future<void> _handleQuickAction(
    Reservation reservation,
    String action,
  ) async {
    try {
      Reservation? updated;
      switch (action) {
        case 'confirm':
          updated =
              await _reservationService.confirmReservation(reservation.id);
          break;
        case 'cancel':
          // For cancel, we'd need a reason dialog - for now, just mark as cancelled
          // In a real implementation, show a dialog for reason
          break;
        case 'no_show':
          updated = await _reservationService.markNoShow(
              reservationId: reservation.id);
          break;
      }

      if (!mounted) return;

      if (updated != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reservation ${action}ed successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onReservationUpdated?.call(updated);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final start = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (start == null || !mounted) return;

    final end = await showDatePicker(
      context: context,
      initialDate: _endDate ?? start,
      firstDate: start,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (end == null || !mounted) return;

    setState(() {
      _startDate = start;
      _endDate = end;
    });
    _applyFilters();
  }

  Future<void> _selectTimeRange() async {
    final start = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (start == null || !mounted) return;

    final end = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 22, minute: 0),
    );
    if (end == null || !mounted) return;

    setState(() {
      _startTime = start;
      _endTime = end;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filters
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Status Filter
                    FilterChip(
                      label: Text(
                          _statusFilter?.name.toUpperCase() ?? 'All Status'),
                      selected: _statusFilter != null,
                      onSelected: (selected) {
                        setState(() {
                          _statusFilter =
                              selected ? ReservationStatus.pending : null;
                        });
                        _applyFilters();
                      },
                    ),
                    // Date Range Filter
                    FilterChip(
                      label: Text(
                        _startDate != null && _endDate != null
                            ? 'Date Range'
                            : 'All Dates',
                      ),
                      selected: _startDate != null && _endDate != null,
                      onSelected: (selected) {
                        if (selected) {
                          _selectDateRange();
                        } else {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                          _applyFilters();
                        }
                      },
                    ),
                    // Time Range Filter
                    FilterChip(
                      label: Text(
                        _startTime != null && _endTime != null
                            ? 'Time Range'
                            : 'All Times',
                      ),
                      selected: _startTime != null && _endTime != null,
                      onSelected: (selected) {
                        if (selected) {
                          _selectTimeRange();
                        } else {
                          setState(() {
                            _startTime = null;
                            _endTime = null;
                          });
                          _applyFilters();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Reservations List
        Expanded(
          child: _filteredReservations.isEmpty
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
                        'No reservations found',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredReservations.length,
                  itemBuilder: (context, index) {
                    final reservation = _filteredReservations[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: Column(
                          children: [
                            ReservationCardWidget(
                              reservation: reservation,
                              onTap: () {
                                // Navigate to detail page - handled by parent
                              },
                            ),
                            // Quick Actions
                            if (reservation.status == ReservationStatus.pending)
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _handleQuickAction(
                                          reservation, 'confirm'),
                                      icon: const Icon(Icons.check, size: 18),
                                      label: const Text('Confirm'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.success,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _handleQuickAction(
                                          reservation, 'cancel'),
                                      icon: const Icon(Icons.cancel, size: 18),
                                      label: const Text('Cancel'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.errorColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (reservation.status ==
                                    ReservationStatus.confirmed &&
                                reservation.reservationTime
                                    .isBefore(DateTime.now()))
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _handleQuickAction(
                                          reservation, 'no_show'),
                                      icon: const Icon(Icons.person_off,
                                          size: 18),
                                      label: const Text('Mark No-Show'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.warning,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
