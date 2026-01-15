// Dispute Form Widget
//
// Phase 15: Reservation System Implementation
// Section 15.2.2: Reservation Management UI
//
// Widget for filing disputes for extenuating circumstances

import 'package:flutter/material.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';

/// Dispute Form Widget
///
/// **Purpose:** Allow users to file disputes for extenuating circumstances
///
/// **Features:**
/// - Dispute reason selection
/// - Description input
/// - Evidence upload (future)
/// - Form validation
/// - Submit handler
class DisputeFormWidget extends StatefulWidget {
  final Reservation reservation;
  final Function(DisputeReason reason, String description)? onSubmit;
  final Function(String)? onError;
  final bool isLoading;

  const DisputeFormWidget({
    super.key,
    required this.reservation,
    this.onSubmit,
    this.onError,
    this.isLoading = false,
  });

  @override
  State<DisputeFormWidget> createState() => _DisputeFormWidgetState();
}

class _DisputeFormWidgetState extends State<DisputeFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  DisputeReason? _selectedReason;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String _getReasonLabel(DisputeReason reason) {
    switch (reason) {
      case DisputeReason.injury:
        return 'Injury preventing attendance';
      case DisputeReason.illness:
        return 'Illness preventing attendance';
      case DisputeReason.death:
        return 'Death in family';
      case DisputeReason.other:
        return 'Other extenuating circumstances';
    }
  }

  IconData _getReasonIcon(DisputeReason reason) {
    switch (reason) {
      case DisputeReason.injury:
        return Icons.local_hospital;
      case DisputeReason.illness:
        return Icons.sick;
      case DisputeReason.death:
        return Icons.wb_twilight;
      case DisputeReason.other:
        return Icons.help_outline;
    }
  }

  void _submitDispute() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedReason == null) {
      widget.onError?.call('Please select a dispute reason');
      return;
    }

    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      widget.onError?.call('Please provide a description');
      return;
    }

    widget.onSubmit?.call(_selectedReason!, description);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'File a Dispute',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'If you have extenuating circumstances that prevented you from attending, you can file a dispute for review. Approved disputes may qualify for refunds even outside the normal cancellation policy.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Dispute Reason *',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...DisputeReason.values.map((reason) {
            final isSelected = _selectedReason == reason;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedReason = reason;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppColors.grey300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getReasonIcon(reason),
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getReasonLabel(reason),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryColor,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description *',
              hintText: 'Please provide details about your extenuating circumstances...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description, color: AppTheme.primaryColor),
            ),
            maxLines: 5,
            maxLength: 1000,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please provide a description';
              }
              if (value.trim().length < 20) {
                return 'Description must be at least 20 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: widget.isLoading ? null : _submitDispute,
            icon: widget.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : const Icon(Icons.send),
            label: Text(widget.isLoading ? 'Submitting...' : 'Submit Dispute'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
