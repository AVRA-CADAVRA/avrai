// Party Size Picker Widget
//
// Phase 15: Reservation System Implementation
// Section 15.2.1: Reservation Creation UI
//
// Widget for selecting party size

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/app_theme.dart';

/// Party Size Picker Widget
///
/// **Purpose:** Allow users to select party size for reservations
///
/// **Features:**
/// - Number input or stepper
/// - Validation (min 1, max 100)
/// - Large group handling (warnings for large groups)
class PartySizePickerWidget extends StatelessWidget {
  final int initialPartySize;
  final int? maxPartySize;
  final Function(int) onPartySizeChanged;
  final bool showLargeGroupWarning;

  const PartySizePickerWidget({
    super.key,
    required this.initialPartySize,
    this.maxPartySize,
    required this.onPartySizeChanged,
    this.showLargeGroupWarning = true,
  });

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        int partySize = initialPartySize;
        final maxSize = maxPartySize ?? 100;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppTheme.primaryColor,
                  onPressed: partySize > 1
                      ? () {
                          setState(() {
                            partySize = partySize - 1;
                          });
                          onPartySizeChanged(partySize);
                        }
                      : null,
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: partySize.toString(),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Party Size',
                      border: OutlineInputBorder(),
                      prefixIcon:
                          Icon(Icons.people, color: AppTheme.primaryColor),
                    ),
                    onChanged: (value) {
                      final size = int.tryParse(value) ?? 1;
                      final clampedSize = size.clamp(1, maxSize);
                      setState(() {
                        partySize = clampedSize;
                      });
                      onPartySizeChanged(partySize);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter party size';
                      }
                      final size = int.tryParse(value);
                      if (size == null || size < 1) {
                        return 'Party size must be at least 1';
                      }
                      if (size > maxSize) {
                        return 'Party size cannot exceed $maxSize';
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppTheme.primaryColor,
                  onPressed: partySize < maxSize
                      ? () {
                          setState(() {
                            partySize = partySize + 1;
                          });
                          onPartySizeChanged(partySize);
                        }
                      : null,
                ),
              ],
            ),
            if (showLargeGroupWarning && partySize > 20)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warningColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppTheme.warningColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Large groups may require special arrangements. Please contact the business directly.',
                        style: const TextStyle(
                          color: AppTheme.warningColor,
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
