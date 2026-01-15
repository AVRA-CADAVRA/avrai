// Ticket Count Picker Widget
//
// Phase 15: Reservation System Implementation
// Section 15.2.1: Reservation Creation UI
//
// Widget for selecting ticket count (can differ from party size)

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/app_theme.dart';

/// Ticket Count Picker Widget
///
/// **Purpose:** Allow users to select ticket count (can be different from party size)
///
/// **Features:**
/// - Number input or stepper
/// - Validation (min 1, max based on business limit or party size)
/// - Shows difference from party size
/// - Business limit enforcement
class TicketCountPickerWidget extends StatelessWidget {
  final int initialTicketCount;
  final int partySize;
  final int? maxTickets;
  final Function(int) onTicketCountChanged;
  final bool showDifference;

  const TicketCountPickerWidget({
    super.key,
    required this.initialTicketCount,
    required this.partySize,
    this.maxTickets,
    required this.onTicketCountChanged,
    this.showDifference = true,
  });

  int get _maxTickets => maxTickets ?? partySize;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        int ticketCount = initialTicketCount.clamp(1, _maxTickets);
        final difference = ticketCount - partySize;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppTheme.primaryColor,
                  onPressed: ticketCount > 1
                      ? () {
                          setState(() {
                            ticketCount = ticketCount - 1;
                          });
                          onTicketCountChanged(ticketCount);
                        }
                      : null,
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: ticketCount.toString(),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Ticket Count',
                      border: const OutlineInputBorder(),
                      prefixIcon:
                          const Icon(Icons.confirmation_number, color: AppTheme.primaryColor),
                      helperText:
                          maxTickets != null && maxTickets! < partySize
                              ? 'Business limit: $maxTickets tickets'
                              : 'Can be different from party size if business has limits',
                    ),
                    onChanged: (value) {
                      final count = int.tryParse(value) ?? 1;
                      final clampedCount = count.clamp(1, _maxTickets);
                      setState(() {
                        ticketCount = clampedCount;
                      });
                      onTicketCountChanged(ticketCount);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter ticket count';
                      }
                      final count = int.tryParse(value);
                      if (count == null || count < 1) {
                        return 'Ticket count must be at least 1';
                      }
                      if (count > _maxTickets) {
                        return 'Ticket count cannot exceed $_maxTickets';
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppTheme.primaryColor,
                  onPressed: ticketCount < _maxTickets
                      ? () {
                          setState(() {
                            ticketCount = ticketCount + 1;
                          });
                          onTicketCountChanged(ticketCount);
                        }
                      : null,
                ),
              ],
            ),
            if (showDifference && difference != 0)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: difference > 0
                      ? AppTheme.warningColor.withValues(alpha: 0.1)
                      : AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: difference > 0 ? AppTheme.warningColor : AppTheme.primaryColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      difference > 0 ? Icons.info_outline : Icons.check_circle_outline,
                      color: difference > 0 ? AppTheme.warningColor : AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        difference > 0
                            ? '$difference more ${difference == 1 ? 'ticket' : 'tickets'} than party size'
                            : '${difference.abs()} fewer ${difference.abs() == 1 ? 'ticket' : 'tickets'} than party size',
                        style: TextStyle(
                          color: difference > 0 ? AppTheme.warningColor : AppTheme.primaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
