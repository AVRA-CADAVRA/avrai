// Reservation Form Widget
//
// Phase 15: Reservation System Implementation
// Section 15.2.1: Reservation Creation UI
//
// Reusable form widget for reservation creation

import 'package:flutter/material.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';

/// Reservation Form Widget
///
/// **Purpose:** Reusable form widget for reservation creation
///
/// **Features:**
/// - Type selection
/// - Target selection
/// - Date/time picker
/// - Party size input
/// - Ticket count input
/// - Special requests
class ReservationFormWidget extends StatefulWidget {
  final ReservationType? initialType;
  final String? initialTargetId;
  final DateTime? initialReservationTime;
  final int? initialPartySize;
  final int? initialTicketCount;
  final String? initialSpecialRequests;
  final Function(ReservationType?) onTypeChanged;
  final Function(String?) onTargetChanged;
  final Function(DateTime?) onReservationTimeChanged;
  final Function(int) onPartySizeChanged;
  final Function(int) onTicketCountChanged;
  final Function(String?) onSpecialRequestsChanged;
  final List<Map<String, dynamic>> availableTargets;

  const ReservationFormWidget({
    super.key,
    this.initialType,
    this.initialTargetId,
    this.initialReservationTime,
    this.initialPartySize,
    this.initialTicketCount,
    this.initialSpecialRequests,
    required this.onTypeChanged,
    required this.onTargetChanged,
    required this.onReservationTimeChanged,
    required this.onPartySizeChanged,
    required this.onTicketCountChanged,
    required this.onSpecialRequestsChanged,
    required this.availableTargets,
  });

  @override
  State<ReservationFormWidget> createState() => _ReservationFormWidgetState();
}

class _ReservationFormWidgetState extends State<ReservationFormWidget> {
  late ReservationType? _selectedType;
  late String? _selectedTargetId;
  late DateTime? _reservationTime;
  late int _partySize;
  late int _ticketCount;
  final TextEditingController _specialRequestsController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedTargetId = widget.initialTargetId;
    _reservationTime = widget.initialReservationTime;
    _partySize = widget.initialPartySize ?? 1;
    _ticketCount = widget.initialTicketCount ?? 1;
    _specialRequestsController.text = widget.initialSpecialRequests ?? '';
  }

  @override
  void dispose() {
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _selectReservationTime() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _reservationTime ?? now.add(const Duration(days: 1)),
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

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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

    if (time != null) {
      setState(() {
        _reservationTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
      });
      widget.onReservationTimeChanged(_reservationTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Reservation Type
        DropdownButtonFormField<ReservationType>(
          value: _selectedType,
          decoration: const InputDecoration(
            labelText: 'Reservation Type',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.event, color: AppTheme.primaryColor),
          ),
          items: ReservationType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.toString().split('.').last.toUpperCase()),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedType = value;
              _selectedTargetId = null;
            });
            widget.onTypeChanged(value);
          },
        ),

        const SizedBox(height: 16),

        // Target Selection
        if (_selectedType != null && widget.availableTargets.isNotEmpty)
          DropdownButtonFormField<String>(
            value: _selectedTargetId,
            decoration: InputDecoration(
              labelText: _selectedType == ReservationType.event
                  ? 'Select Event'
                  : _selectedType == ReservationType.spot
                      ? 'Select Spot'
                      : 'Select Business',
              border: const OutlineInputBorder(),
              prefixIcon:
                  const Icon(Icons.location_on, color: AppTheme.primaryColor),
            ),
            items: widget.availableTargets.map((target) {
              return DropdownMenuItem(
                value: target['id'] as String,
                child: Text(target['title'] as String),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTargetId = value;
              });
              widget.onTargetChanged(value);
            },
          ),

        const SizedBox(height: 16),

        // Reservation Time
        InkWell(
          onTap: _selectReservationTime,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Reservation Time',
              border: OutlineInputBorder(),
              prefixIcon:
                  Icon(Icons.calendar_today, color: AppTheme.primaryColor),
            ),
            child: Text(
              _reservationTime != null
                  ? _reservationTime!.toLocal().toString().split('.')[0]
                  : 'Select date and time',
              style: TextStyle(
                color: _reservationTime != null
                    ? AppColors.black
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Party Size
        TextFormField(
          initialValue: _partySize.toString(),
          decoration: const InputDecoration(
            labelText: 'Party Size',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.people, color: AppTheme.primaryColor),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final size = int.tryParse(value) ?? 1;
            setState(() {
              _partySize = size;
              _ticketCount = size; // Default ticket count to party size
            });
            widget.onPartySizeChanged(_partySize);
            widget.onTicketCountChanged(_ticketCount);
          },
        ),

        const SizedBox(height: 16),

        // Ticket Count
        TextFormField(
          initialValue: _ticketCount.toString(),
          decoration: const InputDecoration(
            labelText: 'Ticket Count',
            border: OutlineInputBorder(),
            prefixIcon:
                Icon(Icons.confirmation_number, color: AppTheme.primaryColor),
            helperText:
                'Can be different from party size if business has limits',
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final count = int.tryParse(value) ?? 1;
            setState(() {
              _ticketCount = count;
            });
            widget.onTicketCountChanged(_ticketCount);
          },
        ),

        const SizedBox(height: 16),

        // Special Requests
        TextFormField(
          controller: _specialRequestsController,
          decoration: const InputDecoration(
            labelText: 'Special Requests (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note, color: AppTheme.primaryColor),
          ),
          maxLines: 3,
          onChanged: (value) {
            widget.onSpecialRequestsChanged(value.isEmpty ? null : value);
          },
        ),
      ],
    );
  }
}
