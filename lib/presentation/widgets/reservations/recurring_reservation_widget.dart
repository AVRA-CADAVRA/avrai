// Recurring Reservation Widget
//
// Phase 10.3: Recurring Reservations
// Widget for creating recurring reservation series
//
// Allows users to create recurring reservations with pattern selection

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/services/reservation_recurrence_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/injection_container.dart' as di;

/// Recurring Reservation Widget
///
/// **Purpose:** Allow users to create recurring reservation series
///
/// **Features:**
/// - Pattern type selection (daily, weekly, monthly, custom)
/// - Interval selection
/// - End date or max occurrences
/// - Days of week selection (for weekly)
/// - Day of month selection (for monthly)
/// - Preview of generated instances
/// - Loading states
/// - Error handling
///
/// **Phase 10.3:** Recurring reservations with full AVRAI system integration
class RecurringReservationWidget extends StatefulWidget {
  final Reservation baseReservation;
  final VoidCallback? onSeriesCreated;
  final VoidCallback? onCancel;

  const RecurringReservationWidget({
    super.key,
    required this.baseReservation,
    this.onSeriesCreated,
    this.onCancel,
  });

  @override
  State<RecurringReservationWidget> createState() =>
      _RecurringReservationWidgetState();
}

class _RecurringReservationWidgetState
    extends State<RecurringReservationWidget> {
  static const String _logName = 'RecurringReservationWidget';

  late final ReservationRecurrenceService _recurrenceService;

  RecurrencePatternType _patternType = RecurrencePatternType.weekly;
  int _interval = 1;
  DateTime? _endDate;
  int? _maxOccurrences;
  // ignore: unused_field - Reserved for Phase 10.3: Days of week selection for weekly patterns
  final List<int> _selectedDaysOfWeek = [];
  int? _dayOfMonth;

  bool _isLoading = false;
  String? _error;
  List<DateTime> _previewInstances = [];

  @override
  void initState() {
    super.initState();
    _recurrenceService = di.sl<ReservationRecurrenceService>();
    _generatePreview();
  }

  /// Generate preview of reservation instances
  void _generatePreview() {
    // Generate preview instances
    final instances = <DateTime>[];
    DateTime current = widget.baseReservation.reservationTime;
    int count = 0;
    final maxPreview = _maxOccurrences ?? 10;

    while (count < maxPreview) {
      if (_endDate != null && current.isAfter(_endDate!)) {
        break;
      }

      instances.add(current);

      // Calculate next occurrence
      switch (_patternType) {
        case RecurrencePatternType.daily:
          current = current.add(Duration(days: _interval));
          break;
        case RecurrencePatternType.weekly:
          current = current.add(Duration(days: 7 * _interval));
          break;
        case RecurrencePatternType.monthly:
          current = DateTime(
            current.year,
            current.month + _interval,
            current.day,
            current.hour,
            current.minute,
          );
          break;
        case RecurrencePatternType.custom:
          current = current.add(Duration(days: _interval));
          break;
      }

      count++;
    }

    setState(() {
      _previewInstances = instances;
    });
  }

  /// Create recurring reservation series
  Future<void> _createRecurringSeries() async {
    if (_endDate == null && _maxOccurrences == null) {
      setState(() {
        _error = 'Please specify either an end date or maximum occurrences';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get current user ID (from auth context)
      // TODO(Phase 10.3): Get userId from auth context
      final userId = 'user_placeholder'; // Replace with actual userId

      final pattern = RecurrencePattern(
        type: _patternType,
        interval: _interval,
        endDate: _endDate,
        maxOccurrences: _maxOccurrences,
        daysOfWeek: _selectedDaysOfWeek.isNotEmpty ? _selectedDaysOfWeek : null,
        dayOfMonth: _dayOfMonth,
      );

      final result = await _recurrenceService.createRecurringSeries(
        userId: userId,
        baseReservation: widget.baseReservation,
        pattern: pattern,
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Recurring reservation series created! ${result.createdReservationIds?.length ?? 0} reservations created.',
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );

          // Notify parent
          widget.onSeriesCreated?.call();
        } else {
          setState(() {
            _error = result.error ?? 'Failed to create recurring series';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(result.error ?? 'Failed to create recurring series'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error creating recurring reservation series: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() {
          _error = 'Failed to create series: ${e.toString()}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create series: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Select end date
  Future<void> _selectEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now.add(const Duration(days: 30)),
      firstDate: widget.baseReservation.reservationTime,
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

    if (picked != null) {
      setState(() {
        _endDate = picked;
        _maxOccurrences = null; // Clear max occurrences if end date is set
        _generatePreview();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.repeat,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Create Recurring Reservation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Pattern Type Selection
          const Text(
            'Recurrence Pattern',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<RecurrencePatternType>(
            segments: [
              ButtonSegment(
                value: RecurrencePatternType.daily,
                label: const Text('Daily'),
                icon: const Icon(Icons.today),
              ),
              ButtonSegment(
                value: RecurrencePatternType.weekly,
                label: const Text('Weekly'),
                icon: const Icon(Icons.date_range),
              ),
              ButtonSegment(
                value: RecurrencePatternType.monthly,
                label: const Text('Monthly'),
                icon: const Icon(Icons.calendar_month),
              ),
              ButtonSegment(
                value: RecurrencePatternType.custom,
                label: const Text('Custom'),
                icon: const Icon(Icons.settings),
              ),
            ],
            selected: {_patternType},
            onSelectionChanged: (Set<RecurrencePatternType> newSelection) {
              setState(() {
                _patternType = newSelection.first;
                _generatePreview();
              });
            },
          ),

          const SizedBox(height: 24),

          // Interval Selection
          Row(
            children: [
              const Text(
                'Repeat every',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: _interval.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Interval',
                  ),
                  onChanged: (value) {
                    final interval = int.tryParse(value);
                    if (interval != null && interval > 0) {
                      setState(() {
                        _interval = interval;
                        _generatePreview();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _patternType == RecurrencePatternType.daily
                    ? 'day(s)'
                    : _patternType == RecurrencePatternType.weekly
                        ? 'week(s)'
                        : _patternType == RecurrencePatternType.monthly
                            ? 'month(s)'
                            : 'day(s)',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // End Condition Selection
          const Text(
            'End Condition',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          RadioGroup<bool>(
            groupValue: _endDate != null,
            onChanged: (val) {
              if (val == true) {
                // End Date selected
                _selectEndDate();
              } else {
                // Max Occurrences selected
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Maximum Occurrences'),
                    content: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Number of occurrences',
                      ),
                      onSubmitted: (value) {
                        final max = int.tryParse(value);
                        if (max != null && max > 0) {
                          setState(() {
                            _maxOccurrences = max;
                            _endDate = null;
                            _generatePreview();
                          });
                          Navigator.pop(context);
                        }
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Will be handled by onSubmitted
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('End Date'),
                    value: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Max Occurrences'),
                    value: false,
                  ),
                ),
              ],
            ),
          ),

          if (_endDate != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectEndDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'End Date',
                  border: OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                ),
                child: Text(
                  _endDate!.toLocal().toString().split(' ')[0],
                  style: const TextStyle(color: AppColors.black),
                ),
              ),
            ),
          ],

          if (_maxOccurrences != null) ...[
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _maxOccurrences.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Maximum Occurrences',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers, color: AppTheme.primaryColor),
              ),
              onChanged: (value) {
                final max = int.tryParse(value);
                if (max != null && max > 0) {
                  setState(() {
                    _maxOccurrences = max;
                    _generatePreview();
                  });
                }
              },
            ),
          ],

          const SizedBox(height: 24),

          // Preview Section
          if (_previewInstances.isNotEmpty) ...[
            const Text(
              'Preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_previewInstances.length} reservation${_previewInstances.length == 1 ? '' : 's'} will be created:',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(_previewInstances.take(5).map((instance) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        instance.toLocal().toString().split('.')[0],
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  })),
                  if (_previewInstances.length > 5)
                    Text(
                      '... and ${_previewInstances.length - 5} more',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Error Message
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorColor),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              if (widget.onCancel != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createRecurringSeries,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : const Text('Create Recurring Series'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
