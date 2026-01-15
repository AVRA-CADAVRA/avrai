import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/models/unified_user.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/services/reservation_cancellation_policy_service.dart';
import 'package:avrai/core/services/reservation_dispute_service.dart';
import 'package:avrai/core/services/reservation_waitlist_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/reservations/reservation_status_widget.dart';
import 'package:avrai/presentation/widgets/reservations/reservation_actions_widget.dart';
import 'package:avrai/presentation/widgets/reservations/cancellation_policy_widget.dart';
import 'package:avrai/presentation/widgets/reservations/dispute_form_widget.dart';
import 'package:avrai/presentation/widgets/reservations/refund_status_widget.dart';
import 'package:avrai/presentation/widgets/reservations/nfc_check_in_widget.dart';
import 'package:avrai/presentation/widgets/reservations/calendar_sync_widget.dart';
import 'package:avrai/injection_container.dart' as di;

/// Reservation Detail Page
/// Phase 15: Reservation System Implementation
/// Section 15.2.2: Reservation Management UI
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Full reservation details
/// - Modification options (with limit display)
/// - Cancellation flow (with policy display)
/// - Dispute filing
/// - Refund status display
/// - Waitlist position (if applicable)
class ReservationDetailPage extends StatefulWidget {
  final String reservationId;

  const ReservationDetailPage({
    super.key,
    required this.reservationId,
  });

  @override
  State<ReservationDetailPage> createState() => _ReservationDetailPageState();
}

class _ReservationDetailPageState extends State<ReservationDetailPage> {
  late final ReservationService _reservationService;
  late final ReservationCancellationPolicyService? _cancellationPolicyService;
  late final ReservationDisputeService? _disputeService;
  late final ReservationWaitlistService? _waitlistService;

  Reservation? _reservation;
  bool _isLoading = false;
  bool _isCancelling = false;
  bool _isFilingDispute = false;
  bool _isModifying = false;
  String? _error;
  UnifiedUser? _currentUser;

  // Modification and policy state
  ModificationCheckResult? _modificationCheck;
  CancellationPolicy? _cancellationPolicy;
  bool _qualifiesForRefund = false;
  double? _refundAmount;
  int? _waitlistPosition;
  bool _showDisputeForm = false;

  @override
  void initState() {
    super.initState();
    _reservationService = di.sl<ReservationService>();
    _cancellationPolicyService =
        di.sl.isRegistered<ReservationCancellationPolicyService>()
            ? di.sl<ReservationCancellationPolicyService>()
            : null;
    _disputeService = di.sl.isRegistered<ReservationDisputeService>()
        ? di.sl<ReservationDisputeService>()
        : null;
    _waitlistService = di.sl.isRegistered<ReservationWaitlistService>()
        ? di.sl<ReservationWaitlistService>()
        : null;
    _loadReservation();
  }

  Future<void> _loadReservation() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      setState(() {
        _error = 'Please sign in to view reservation details';
      });
      return;
    }

    final user = authState.user;

    // Convert User to UnifiedUser
    _currentUser = UnifiedUser(
      id: user.id,
      email: user.email,
      displayName: user.displayName ?? user.name,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      isOnline: user.isOnline ?? false,
    );

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get all user reservations and find the one we need
      final reservations = await _reservationService.getUserReservations(
        userId: _currentUser!.id,
      );

      final reservation = reservations.firstWhere(
        (r) => r.id == widget.reservationId,
        orElse: () => throw Exception('Reservation not found'),
      );

      setState(() {
        _reservation = reservation;
        _isLoading = false;
      });

      // Load additional data
      await _loadModificationCheck();
      await _loadCancellationPolicy();
      await _loadWaitlistPosition();
    } catch (e, stackTrace) {
      developer.log(
        'Error loading reservation: $e',
        name: 'ReservationDetailPage',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() {
        _error = _getUserFriendlyErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadModificationCheck() async {
    if (_reservation == null || _currentUser == null) return;

    try {
      final check = await _reservationService.canModifyReservation(
        reservationId: _reservation!.id,
        newReservationTime:
            _reservation!.reservationTime, // Use current time for check
      );

      setState(() {
        _modificationCheck = check;
      });
    } catch (e) {
      // Ignore errors, modification check is optional
    }
  }

  Future<void> _loadCancellationPolicy() async {
    if (_reservation == null || _cancellationPolicyService == null) return;

    try {
      final policy = await _cancellationPolicyService!.getCancellationPolicy(
        type: _reservation!.type,
        targetId: _reservation!.targetId,
      );

      final qualifies = await _cancellationPolicyService!.qualifiesForRefund(
        reservation: _reservation!,
        cancellationTime: DateTime.now(),
      );

      final refund = await _cancellationPolicyService!.calculateRefund(
        reservation: _reservation!,
        cancellationTime: DateTime.now(),
      );

      setState(() {
        _cancellationPolicy = policy;
        _qualifiesForRefund = qualifies;
        _refundAmount = refund > 0 ? refund : null;
      });
    } catch (e) {
      // Ignore errors, policy check is optional
    }
  }

  Future<void> _loadWaitlistPosition() async {
    if (_reservation == null ||
        _currentUser == null ||
        _waitlistService == null ||
        _reservation!.status != ReservationStatus.pending) {
      return;
    }

    try {
      // Check if user is on waitlist for this reservation
      final position = await _waitlistService!.findWaitlistPosition(
        userId: _currentUser!.id,
        type: _reservation!.type,
        targetId: _reservation!.targetId,
        reservationTime: _reservation!.reservationTime,
      );

      setState(() {
        _waitlistPosition = position;
      });
    } catch (e) {
      // Ignore errors, waitlist check is optional
    }
  }

  Future<void> _cancelReservation() async {
    if (_reservation == null) return;

    // Show cancellation dialog with policy
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_cancellationPolicy != null)
                CancellationPolicyWidget(
                  policy: _cancellationPolicy!,
                  reservationTime: _reservation!.reservationTime,
                  ticketPrice: _reservation!.ticketPrice,
                  ticketCount: _reservation!.ticketCount,
                )
              else
                const Text('Are you sure you want to cancel this reservation?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, Keep Reservation'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isCancelling = true;
      _error = null;
    });

    try {
      await _reservationService.cancelReservation(
        reservationId: _reservation!.id,
        reason: 'User request',
      );

      // Reload reservation to get updated status
      await _loadReservation();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_qualifiesForRefund && _refundAmount != null
                ? 'Reservation cancelled. Refund of \$${_refundAmount!.toStringAsFixed(2)} will be processed.'
                : 'Reservation cancelled successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error cancelling reservation: $e',
        name: 'ReservationDetailPage',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() {
        _error = _getUserFriendlyErrorMessage(e);
        _isCancelling = false;
      });
    }
  }

  Future<void> _modifyReservation() async {
    if (_reservation == null || _modificationCheck?.canModify != true) {
      return;
    }

    setState(() {
      _isModifying = true;
      _error = null;
    });

    try {
      // Navigate to modification page (for now, just show a message)
      // TODO(Phase 15.2.2): Create reservation modification page
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Modification feature coming soon. Please cancel and create a new reservation.'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to modify reservation: $e';
      });
    } finally {
      setState(() {
        _isModifying = false;
      });
    }
  }

  Future<void> _fileDispute(DisputeReason reason, String description) async {
    if (_reservation == null ||
        _currentUser == null ||
        _disputeService == null) {
      return;
    }

    setState(() {
      _isFilingDispute = true;
      _error = null;
    });

    try {
      await _disputeService!.fileDispute(
        reservationId: _reservation!.id,
        userId: _currentUser!.id,
        reason: reason,
        description: description,
      );

      // Reload reservation to get updated dispute status
      await _loadReservation();

      if (mounted) {
        setState(() {
          _showDisputeForm = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Dispute filed successfully. We will review your request.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to file dispute: $e';
      });
    } finally {
      setState(() {
        _isFilingDispute = false;
      });
    }
  }

  Future<void> _checkIn() async {
    if (_reservation == null || _currentUser == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _reservationService.checkIn(_reservation!.id);

      // Reload reservation to get updated status
      await _loadReservation();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checked in successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to check in: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getTypeLabel(ReservationType type) {
    switch (type) {
      case ReservationType.event:
        return 'Event';
      case ReservationType.spot:
        return 'Spot';
      case ReservationType.business:
        return 'Business';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        actions: [
          if (_reservation != null &&
              _reservation!.status == ReservationStatus.confirmed)
            Semantics(
              label: 'Check in for reservation',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.check_circle),
                onPressed: _checkIn,
                tooltip: 'Check In',
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Semantics(
              label: 'Loading reservation details',
              child: const Center(child: CircularProgressIndicator()),
            )
          : _error != null
              ? Semantics(
                  label: 'Error loading reservation: $_error',
                  liveRegion: true,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppTheme.errorColor),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(color: AppTheme.errorColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Semantics(
                          label: 'Retry loading reservation',
                          button: true,
                          child: ElevatedButton(
                            onPressed: _loadReservation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: AppColors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _reservation == null
                  ? const Center(child: Text('Reservation not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Status Badge
                          ReservationStatusWidget(
                            status: _reservation!.status,
                          ),

                          const SizedBox(height: 24),

                          // Waitlist Position (if applicable)
                          if (_waitlistPosition != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: AppTheme.primaryColor),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      color: AppTheme.primaryColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Waitlist Position: #$_waitlistPosition',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (_waitlistPosition != null)
                            const SizedBox(height: 16),

                          // Modification Count
                          if (_modificationCheck != null &&
                              _modificationCheck!.modificationCount != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.warningColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: AppTheme.warningColor),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.edit,
                                      color: AppTheme.warningColor, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Modifications: ${_modificationCheck!.modificationCount}/3 (${_modificationCheck!.remainingModifications ?? 0} remaining)',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.warningColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (_modificationCheck != null &&
                              _modificationCheck!.modificationCount != null)
                            const SizedBox(height: 16),

                          // Reservation Type
                          _DetailRow(
                            icon: Icons.category,
                            label: 'Type',
                            value: _getTypeLabel(_reservation!.type),
                          ),

                          const SizedBox(height: 16),

                          // Target ID
                          _DetailRow(
                            icon: Icons.location_on,
                            label: 'Target',
                            value: _reservation!.targetId,
                          ),

                          const SizedBox(height: 16),

                          // Reservation Time
                          _DetailRow(
                            icon: Icons.calendar_today,
                            label: 'Reservation Time',
                            value: _reservation!.reservationTime
                                .toLocal()
                                .toString()
                                .split('.')[0],
                          ),

                          const SizedBox(height: 16),

                          // Party Size
                          _DetailRow(
                            icon: Icons.people,
                            label: 'Party Size',
                            value:
                                '${_reservation!.partySize} ${_reservation!.partySize == 1 ? 'person' : 'people'}',
                          ),

                          const SizedBox(height: 16),

                          // Ticket Count
                          _DetailRow(
                            icon: Icons.confirmation_number,
                            label: 'Tickets',
                            value: '${_reservation!.ticketCount}',
                          ),

                          if (_reservation!.specialRequests != null) ...[
                            const SizedBox(height: 16),
                            _DetailRow(
                              icon: Icons.note,
                              label: 'Special Requests',
                              value: _reservation!.specialRequests!,
                            ),
                          ],

                          if (_reservation!.ticketPrice != null) ...[
                            const SizedBox(height: 16),
                            _DetailRow(
                              icon: Icons.attach_money,
                              label: 'Ticket Price',
                              value:
                                  '\$${_reservation!.ticketPrice!.toStringAsFixed(2)}',
                            ),
                          ],

                          if (_reservation!.depositAmount != null) ...[
                            const SizedBox(height: 16),
                            _DetailRow(
                              icon: Icons.payment,
                              label: 'Deposit',
                              value:
                                  '\$${_reservation!.depositAmount!.toStringAsFixed(2)}',
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Refund Status (if cancelled)
                          if (_reservation!.status ==
                                  ReservationStatus.cancelled &&
                              _cancellationPolicyService != null)
                            RefundStatusWidget(
                              reservation: _reservation!,
                              qualifiesForRefund: _qualifiesForRefund,
                              refundAmount: _refundAmount,
                              refundIssued: _reservation!
                                      .metadata['refundIssued'] as bool? ??
                                  false,
                            ),

                          if (_reservation!.status ==
                              ReservationStatus.cancelled)
                            const SizedBox(height: 16),

                          // Dispute Form (if showing)
                          if (_showDisputeForm && _disputeService != null)
                            DisputeFormWidget(
                              reservation: _reservation!,
                              onSubmit: _fileDispute,
                              onError: (error) {
                                setState(() {
                                  _error = error;
                                });
                              },
                              isLoading: _isFilingDispute,
                            ),

                          if (_showDisputeForm) const SizedBox(height: 16),

                          // NFC Check-In Widget (Phase 10.1: Proximity-triggered NFC check-in)
                          if (_reservation != null &&
                              _reservation!.status ==
                                  ReservationStatus.confirmed &&
                              _reservation!.type == ReservationType.spot)
                            NFCCheckInWidget(
                              reservation: _reservation!,
                              onCheckInComplete: () async {
                                // Reload reservation after check-in
                                await _loadReservation();
                              },
                            ),

                          if (_reservation != null &&
                              _reservation!.status ==
                                  ReservationStatus.confirmed &&
                              _reservation!.type == ReservationType.spot)
                            const SizedBox(height: 16),

                          // Calendar Sync Widget (Phase 10.2: Calendar Integration)
                          if (_reservation != null &&
                              (_reservation!.status ==
                                      ReservationStatus.pending ||
                                  _reservation!.status ==
                                      ReservationStatus.confirmed))
                            CalendarSyncWidget(
                              reservation: _reservation!,
                              onSyncComplete: () async {
                                // Reload reservation after sync to get updated calendarEventId
                                await _loadReservation();
                              },
                              onUnsyncComplete: () async {
                                // Reload reservation after unsync
                                await _loadReservation();
                              },
                            ),

                          if (_reservation != null &&
                              (_reservation!.status ==
                                      ReservationStatus.pending ||
                                  _reservation!.status ==
                                      ReservationStatus.confirmed))
                            const SizedBox(height: 16),

                          // Actions Widget
                          ReservationActionsWidget(
                            reservation: _reservation!,
                            canModify: _modificationCheck?.canModify ?? false,
                            modificationCount:
                                _modificationCheck?.modificationCount,
                            modificationReason: _modificationCheck?.reason,
                            onCancel: _cancelReservation,
                            onModify: _modifyReservation,
                            onDispute: () {
                              setState(() {
                                _showDisputeForm = !_showDisputeForm;
                              });
                            },
                            onCheckIn: _checkIn,
                            isLoading: _isCancelling || _isModifying,
                          ),
                        ],
                      ),
                    ),
    );
  }

  /// Get user-friendly error message from exception
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Payment errors
    if (errorString.contains('payment') || errorString.contains('stripe')) {
      return 'Payment error. Please check your payment method and try again.';
    }

    // Network errors
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Connection error. Please check your internet connection and try again.';
    }

    // Not found errors
    if (errorString.contains('not found') ||
        errorString.contains('does not exist')) {
      return 'Reservation not found. It may have been deleted.';
    }

    // Validation errors
    if (errorString.contains('invalid') || errorString.contains('validation')) {
      return 'Invalid reservation data. Please try again.';
    }

    // Generic error
    return 'An error occurred. Please try again.';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
