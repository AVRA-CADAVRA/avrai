// Reservation Transfer Widget
//
// Phase 10.4: Reservation Sharing & Transfer
// Widget for transferring reservation ownership to another user
//
// Allows users to transfer reservations with compatibility prediction

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/services/reservation_sharing_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/injection_container.dart' as di;

/// Reservation Transfer Widget
///
/// **Purpose:** Allow users to transfer reservation ownership to another user
///
/// **Features:**
/// - User search/selection
/// - Compatibility prediction display
/// - Transfer confirmation
/// - Loading states
/// - Error handling
/// - Success feedback
///
/// **Phase 10.4:** Reservation transfer with full AVRAI system integration
class ReservationTransferWidget extends StatefulWidget {
  final Reservation reservation;
  final VoidCallback? onTransferComplete;
  final VoidCallback? onCancel;

  const ReservationTransferWidget({
    super.key,
    required this.reservation,
    this.onTransferComplete,
    this.onCancel,
  });

  @override
  State<ReservationTransferWidget> createState() =>
      _ReservationTransferWidgetState();
}

class _ReservationTransferWidgetState extends State<ReservationTransferWidget> {
  static const String _logName = 'ReservationTransferWidget';

  late final ReservationSharingService _sharingService;

  final TextEditingController _userSearchController = TextEditingController();
  String? _selectedUserId;
  String? _selectedUserName;
  double? _predictedCompatibility;
  bool _isLoading = false;
  bool _isPredictingCompatibility = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sharingService = di.sl<ReservationSharingService>();
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    super.dispose();
  }

  /// Predict compatibility for transfer
  Future<void> _predictCompatibility() async {
    if (_selectedUserId == null) {
      return;
    }

    setState(() {
      _isPredictingCompatibility = true;
    });

    try {
      // TODO(Phase 10.4): Implement compatibility prediction
      // TODO(Phase 10.4): Get current user ID from auth context for prediction
      // For now, simulate with a placeholder
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _predictedCompatibility = 0.75; // Placeholder compatibility score
          _isPredictingCompatibility = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPredictingCompatibility = false;
        });
      }
    }
  }

  /// Transfer reservation to selected user
  Future<void> _transferReservation() async {
    if (_selectedUserId == null) {
      setState(() {
        _error = 'Please select a user to transfer to';
      });
      return;
    }

    // Confirm transfer
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer Reservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to transfer this reservation?',
            ),
            const SizedBox(height: 8),
            Text(
              'Transferring to: $_selectedUserName',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_predictedCompatibility != null) ...[
              const SizedBox(height: 8),
              Text(
                'Predicted Compatibility: ${(_predictedCompatibility! * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: _predictedCompatibility! > 0.7
                      ? AppTheme.successColor
                      : _predictedCompatibility! > 0.5
                          ? AppTheme.warningColor
                          : AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone. The reservation will be transferred to the new owner.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Transfer'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    // TODO(Phase 10.4): Get current user ID from auth context
    final fromUserId = 'user_placeholder'; // Replace with actual userId

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _sharingService.transferReservation(
        reservationId: widget.reservation.id,
        fromUserId: fromUserId,
        toUserId: _selectedUserId!,
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Reservation transferred to $_selectedUserName successfully',
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );

          // Notify parent
          widget.onTransferComplete?.call();
        } else {
          setState(() {
            _error = result.error ?? 'Failed to transfer reservation';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to transfer reservation'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error transferring reservation: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() {
          _error = 'Failed to transfer: ${e.toString()}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to transfer: ${e.toString()}'),
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

  /// Show user search dialog
  Future<void> _showUserSearch() async {
    // TODO(Phase 10.4): Implement user search functionality
    // For now, show a simple dialog with text input
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: TextEditingController(),
              decoration: const InputDecoration(
                labelText: 'User ID or Email',
                hintText: 'Enter user ID or email',
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.pop(context, {
                    'userId': value,
                    'userName': value,
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: Full user search coming soon',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
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
            child: const Text('Select'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _selectedUserId = result['userId'];
        _selectedUserName = result['userName'];
        _predictedCompatibility = null; // Reset compatibility
      });
      await _predictCompatibility();
    }
  }

  Color _getCompatibilityColor(double compatibility) {
    if (compatibility > 0.7) {
      return AppTheme.successColor;
    } else if (compatibility > 0.5) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.errorColor;
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
                Icons.swap_horiz,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Transfer Reservation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Reservation Info
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
                const Text(
                  'Reservation Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Type: ${widget.reservation.type.name}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Time: ${widget.reservation.reservationTime.toLocal().toString().split('.')[0]}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Party Size: ${widget.reservation.partySize}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // User Selection
          const Text(
            'Transfer To',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showUserSearch,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Select User',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person, color: AppTheme.primaryColor),
                suffixIcon: Icon(Icons.search),
              ),
              child: Text(
                _selectedUserName ?? 'Tap to search for user',
                style: TextStyle(
                  color: _selectedUserName != null
                      ? AppColors.black
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),

          // Compatibility Prediction
          if (_selectedUserId != null) ...[
            const SizedBox(height: 16),
            if (_isPredictingCompatibility)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_predictedCompatibility != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getCompatibilityColor(_predictedCompatibility!)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getCompatibilityColor(_predictedCompatibility!),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _predictedCompatibility! > 0.7
                              ? Icons.check_circle
                              : _predictedCompatibility! > 0.5
                                  ? Icons.warning
                                  : Icons.error,
                          color:
                              _getCompatibilityColor(_predictedCompatibility!),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Predicted Compatibility',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_predictedCompatibility! * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getCompatibilityColor(_predictedCompatibility!),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _predictedCompatibility! > 0.7
                          ? 'High compatibility - Transfer recommended'
                          : _predictedCompatibility! > 0.5
                              ? 'Moderate compatibility - Transfer may work'
                              : 'Low compatibility - Transfer not recommended',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getCompatibilityColor(_predictedCompatibility!),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          // Warning
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.warningColor),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.warningColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Transferring a reservation will permanently change ownership. This action cannot be undone.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.warningColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

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
                  onPressed: _isLoading ? null : _transferReservation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
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
                      : const Text('Transfer Reservation'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
