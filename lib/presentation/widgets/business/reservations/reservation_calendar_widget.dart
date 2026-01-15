// Reservation Calendar Widget
//
// Phase 15: Reservation System Implementation
// Section 15.3.1: Business Reservation Dashboard
//
// Widget for displaying reservations in a calendar format

import 'package:flutter/material.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';

/// Reservation Calendar Widget
///
/// **Purpose:** Display reservations in a calendar month view
///
/// **Features:**
/// - Month view with calendar grid
/// - Highlight days with reservations
/// - Show reservation count per day
/// - Navigate between months
class ReservationCalendarWidget extends StatefulWidget {
  final List<Reservation> reservations;
  final Function(DateTime)? onDateSelected;

  const ReservationCalendarWidget({
    super.key,
    required this.reservations,
    this.onDateSelected,
  });

  @override
  State<ReservationCalendarWidget> createState() => _ReservationCalendarWidgetState();
}

class _ReservationCalendarWidgetState extends State<ReservationCalendarWidget> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
  }

  /// Get reservations for a specific date
  List<Reservation> _getReservationsForDate(DateTime date) {
    return widget.reservations.where((reservation) {
      final reservationDate = DateTime(
        reservation.reservationTime.year,
        reservation.reservationTime.month,
        reservation.reservationTime.day,
      );
      final checkDate = DateTime(date.year, date.month, date.day);
      return reservationDate == checkDate;
    }).toList();
  }

  /// Get first day of month
  DateTime _firstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get last day of month
  DateTime _lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Get days in month for calendar grid
  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = _firstDayOfMonth(month);
    final lastDay = _lastDayOfMonth(month);
    final firstDayOfWeek = firstDay.weekday % 7; // 0 = Sunday, 6 = Saturday

    final days = <DateTime>[];

    // Add padding days from previous month
    for (int i = 0; i < firstDayOfWeek; i++) {
      days.add(firstDay.subtract(Duration(days: firstDayOfWeek - i)));
    }

    // Add days of current month
    for (int i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(month.year, month.month, i));
    }

    // Fill remaining days to complete grid (42 = 6 weeks * 7 days)
    final remainingDays = 42 - days.length;
    for (int i = 1; i <= remainingDays; i++) {
      days.add(DateTime(month.year, month.month + 1, i));
    }

    return days;
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth(_focusedMonth);
    final today = DateTime.now();
    final currentMonth = DateTime(_focusedMonth.year, _focusedMonth.month);

    return Column(
      children: [
        // Month Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousMonth,
              ),
              Text(
                '${_focusedMonth.year} ${_getMonthName(_focusedMonth.month)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextMonth,
              ),
            ],
          ),
        ),

        // Day Headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),

        const SizedBox(height: 8),

        // Calendar Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final date = days[index];
              final isCurrentMonth = date.month == currentMonth.month;
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final dayReservations = _getReservationsForDate(date);
              final hasReservations = dayReservations.isNotEmpty;

              return InkWell(
                onTap: isCurrentMonth
                    ? () {
                        widget.onDateSelected?.call(date);
                      }
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: isToday
                        ? Border.all(color: AppTheme.primaryColor, width: 2)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isCurrentMonth
                              ? (isToday ? AppTheme.primaryColor : AppColors.textPrimary)
                              : AppColors.textSecondary,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (hasReservations)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (hasReservations)
                        Text(
                          '${dayReservations.length}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
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

  String _getMonthName(int month) {
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
    return months[month - 1];
  }
}
