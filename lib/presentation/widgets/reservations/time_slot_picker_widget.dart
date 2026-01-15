// Time Slot Picker Widget
//
// Phase 15: Reservation System Implementation
// Section 15.2.1: Reservation Creation UI
//
// Widget for selecting available time slots based on business hours

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/services/reservation_availability_service.dart';

/// Time Slot Picker Widget
///
/// **Purpose:** Allow users to select available time slots based on business hours
///
/// **Features:**
/// - Date selection
/// - Time slot generation based on business hours
/// - Blocks unavailable time slots
/// - Shows available/blocked slots visually
/// - Respects business closures/holidays
class TimeSlotPickerWidget extends StatefulWidget {
  final ReservationAvailabilityService? availabilityService;
  final ReservationType? type;
  final String? targetId;
  final DateTime? initialDate;
  final DateTime? initialTime;
  final Function(DateTime) onTimeSelected;
  final Function(String)? onError;

  const TimeSlotPickerWidget({
    super.key,
    this.availabilityService,
    this.type,
    this.targetId,
    this.initialDate,
    this.initialTime,
    required this.onTimeSelected,
    this.onError,
  });

  @override
  State<TimeSlotPickerWidget> createState() => _TimeSlotPickerWidgetState();
}

class _TimeSlotPickerWidgetState extends State<TimeSlotPickerWidget> {
  DateTime? _selectedDate;
  DateTime? _selectedTime;
  List<TimeSlot> _availableSlots = [];
  bool _isLoading = false;
  bool _isClosed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedTime = widget.initialTime;
    if (_selectedDate != null) {
      _loadAvailableSlots();
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (!mounted || picked == null) return;

    setState(() {
      _selectedDate = picked;
      _selectedTime = null;
    });
    await _loadAvailableSlots();
  }

  Future<void> _loadAvailableSlots() async {
    if (_selectedDate == null ||
        widget.availabilityService == null ||
        widget.targetId == null ||
        widget.type == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _isClosed = false;
    });

    try {
      // Check if business is closed
      if (widget.type != ReservationType.event) {
        // Convert date to DateTime with noon time for business closure check
        final reservationTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          12, // noon
        );
        final isClosed = await widget.availabilityService!.isBusinessClosed(
          businessId: widget.targetId!,
          reservationTime: reservationTime,
        );

        if (isClosed) {
          setState(() {
            _isClosed = true;
            _availableSlots = [];
            _isLoading = false;
          });
          return;
        }
      }

      // Generate available time slots
      // TODO(Phase 15.2.1): Integrate with actual business hours model
      // For now, generate default slots (9 AM - 10 PM, 30-minute intervals)
      final slots = _generateDefaultTimeSlots(_selectedDate!);

      // Filter out slots outside business hours
      final availableSlots = <TimeSlot>[];
      for (final slot in slots) {
        if (widget.type != ReservationType.event) {
          final isWithinHours =
              await widget.availabilityService!.isWithinBusinessHours(
            businessId: widget.targetId!,
            reservationTime: slot.startTime,
          );

          if (isWithinHours && slot.isAvailable) {
            availableSlots.add(slot);
          }
        } else {
          // For events, all generated slots are available
          if (slot.isAvailable) {
            availableSlots.add(slot);
          }
        }
      }

      setState(() {
        _availableSlots = availableSlots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load available time slots: $e';
        _isLoading = false;
      });
      if (widget.onError != null) {
        widget.onError!(_error!);
      }
    }
  }

  /// Generate default time slots (9 AM - 10 PM, 30-minute intervals)
  List<TimeSlot> _generateDefaultTimeSlots(DateTime date) {
    final slots = <TimeSlot>[];
    final startHour = 9;
    final endHour = 22;

    for (int hour = startHour; hour < endHour; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final startTime = DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );
        final endTime = startTime.add(const Duration(minutes: 30));

        slots.add(TimeSlot(
          startTime: startTime,
          endTime: endTime,
          isAvailable: true,
          availableCapacity: -1, // -1 means unlimited
        ));
      }
    }

    return slots;
  }

  void _selectTimeSlot(TimeSlot slot) {
    setState(() {
      _selectedTime = slot.startTime;
    });
    widget.onTimeSelected(slot.startTime);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Date Selection
        InkWell(
          onTap: _selectDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Select Date',
              border: OutlineInputBorder(),
              prefixIcon:
                  Icon(Icons.calendar_today, color: AppTheme.primaryColor),
            ),
            child: Text(
              _selectedDate != null
                  ? '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}'
                  : 'Select date',
              style: TextStyle(
                color: _selectedDate != null
                    ? AppColors.black
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Time Slots
        if (_selectedDate != null) ...[
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_isClosed)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.warningColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.warningColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Business is closed on this date',
                      style: const TextStyle(color: AppTheme.warningColor),
                    ),
                  ),
                ],
              ),
            )
          else if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.errorColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.errorColor),
                    ),
                  ),
                ],
              ),
            )
          else if (_availableSlots.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'No available time slots for this date',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Time Slots',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableSlots.map((slot) {
                    final isSelected = _selectedTime != null &&
                        _selectedTime!.isAtSameMomentAs(slot.startTime);
                    return ChoiceChip(
                      label: Text(
                        '${slot.startTime.hour.toString().padLeft(2, '0')}:${slot.startTime.minute.toString().padLeft(2, '0')}',
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          _selectTimeSlot(slot);
                        }
                      },
                      selectedColor:
                          AppTheme.primaryColor.withValues(alpha: 0.3),
                      checkmarkColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
        ],
      ],
    );
  }
}
