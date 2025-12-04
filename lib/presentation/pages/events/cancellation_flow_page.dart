import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/cancellation.dart';
import 'package:spots/core/models/refund_status.dart';
import 'package:spots/core/services/cancellation_service.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/refund_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';

/// Cancellation Flow Page
/// 
/// Agent 2: Phase 5, Week 16-17 - Cancellation UI
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - Multi-step cancellation flow
/// - Reason selection
/// - Refund preview
/// - Policy explanation
/// - Confirmation step
/// - Processing status
class CancellationFlowPage extends StatefulWidget {
  final ExpertiseEvent event;
  final bool isHost; // true if host is cancelling, false if attendee

  const CancellationFlowPage({
    super.key,
    required this.event,
    this.isHost = false,
  });

  @override
  State<CancellationFlowPage> createState() => _CancellationFlowPageState();
}

class _CancellationFlowPageState extends State<CancellationFlowPage> {
  final CancellationService _cancellationService = CancellationService(
    paymentService: GetIt.instance<PaymentService>(),
    eventService: GetIt.instance<ExpertiseEventService>(),
    refundService: GetIt.instance<RefundService>(),
  );

  int _currentStep = 0;
  String? _selectedReason;
  double? _refundAmount;
  Cancellation? _cancellation;
  bool _isProcessing = false;
  String? _error;

  // Cancellation reasons
  final List<String> _attendeeReasons = [
    'Unable to attend',
    'Schedule conflict',
    'Found a better option',
    'Changed my mind',
    'Other',
  ];

  final List<String> _hostReasons = [
    'Unexpected circumstances',
    'Low attendance',
    'Venue issue',
    'Weather concerns',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _calculateRefundPreview();
  }

  Future<void> _calculateRefundPreview() async {
    if (widget.isHost) {
      // Host cancellation - full refunds for all attendees
      setState(() {
        _refundAmount = null; // Will be calculated on confirmation
      });
      return;
    }

    // Attendee cancellation - calculate refund
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) return;

      final paymentService = GetIt.instance<PaymentService>();
      final payments = await paymentService.getPaymentsForEvent(widget.event.id);
      final userPayment = payments.firstWhere(
        (p) => p.userId == authState.user.id,
        orElse: () => payments.first,
      );

      final timeUntilEvent = widget.event.startTime.difference(DateTime.now());
      final hoursUntilEvent = timeUntilEvent.inHours.toDouble();
      
      // Use standard refund policy
      final platformFee = userPayment.amount * 0.10;
      final refundableAmount = userPayment.amount - platformFee;
      
      // Simple calculation (matches CancellationService logic)
      double refundAmount = 0.0;
      if (hoursUntilEvent > 48) {
        refundAmount = refundableAmount; // Full refund
      } else if (hoursUntilEvent > 24) {
        refundAmount = refundableAmount * 0.5; // 50% refund
      } else {
        refundAmount = 0.0; // No refund
      }

      setState(() {
        _refundAmount = refundAmount;
      });
        } catch (e) {
      // Ignore errors in preview
    }
  }

  Future<void> _processCancellation() async {
    if (_selectedReason == null) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('Please sign in to cancel');
      }

      final userId = authState.user.id;
      Cancellation cancellation;

      if (widget.isHost) {
        // Host cancellation
        cancellation = await _cancellationService.hostCancelEvent(
          eventId: widget.event.id,
          hostId: userId,
          reason: _selectedReason!,
        );
      } else {
        // Attendee cancellation
        cancellation = await _cancellationService.attendeeCancelTicket(
          eventId: widget.event.id,
          attendeeId: userId,
        );
      }

      setState(() {
        _cancellation = cancellation;
        _currentStep = 4; // Success step
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.isHost ? 'Cancel Event' : 'Cancel Ticket',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isProcessing) {
      return _buildProcessingStep();
    }

    if (_cancellation != null) {
      return _buildSuccessStep();
    }

    return Stepper(
      currentStep: _currentStep,
      onStepContinue: _canProceedToNextStep() ? () {
        if (_currentStep == 3) {
          // Final confirmation - process cancellation
          _processCancellation();
        } else {
          setState(() {
            _currentStep++;
          });
        }
      } : null,
      onStepCancel: _currentStep > 0 ? () {
        setState(() {
          _currentStep--;
        });
      } : null,
      steps: [
        _buildReasonStep(),
        _buildRefundPreviewStep(),
        _buildPolicyStep(),
        _buildConfirmationStep(),
      ],
    );
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return _selectedReason != null;
      case 1:
      case 2:
        return true;
      case 3:
        return true;
      default:
        return false;
    }
  }

  Step _buildReasonStep() {
    final reasons = widget.isHost ? _hostReasons : _attendeeReasons;

    return Step(
      title: Text(
        'Reason for Cancellation',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isHost
                ? 'Please select a reason for cancelling this event:'
                : 'Please select a reason for cancelling your ticket:',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...reasons.map((reason) {
            return RadioListTile<String>(
              title: Text(
                reason,
                style: TextStyle(color: AppColors.textPrimary),
              ),
              value: reason,
              groupValue: _selectedReason,
              onChanged: (value) {
                setState(() {
                  _selectedReason = value;
                });
              },
              activeColor: AppTheme.primaryColor,
            );
          }),
        ],
      ),
      isActive: _currentStep >= 0,
      state: _currentStep > 0
          ? StepState.complete
          : (_selectedReason != null ? StepState.indexed : StepState.indexed),
    );
  }

  Step _buildRefundPreviewStep() {
    return Step(
      title: Text(
        'Refund Preview',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isHost) ...[
            Text(
              'As the event host, cancelling this event will:',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.money_off,
              title: 'Full Refunds',
              description: 'All attendees will receive full refunds',
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.warning,
              title: 'Host Penalty',
              description: widget.event.startTime.difference(DateTime.now()).inHours < 48
                  ? 'You may incur a penalty for last-minute cancellation (< 48 hours)'
                  : 'No penalty (cancelled more than 48 hours before event)',
            ),
          ] else ...[
            Text(
              'Refund Information:',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            if (_refundAmount != null && _refundAmount! > 0) ...[
              _buildInfoCard(
                icon: Icons.check_circle,
                title: 'Refund Available',
                description: 'You will receive \$${_refundAmount!.toStringAsFixed(2)} refund',
                color: AppColors.electricGreen,
              ),
            ] else if (_refundAmount != null && _refundAmount! == 0) ...[
              _buildInfoCard(
                icon: Icons.cancel,
                title: 'No Refund',
                description: 'Cancellation is less than 24 hours before the event. No refund available.',
                color: AppColors.error,
              ),
            ] else ...[
              _buildInfoCard(
                icon: Icons.info,
                title: 'Calculating...',
                description: 'Refund amount will be calculated based on cancellation time',
              ),
            ],
          ],
        ],
      ),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
    );
  }

  Step _buildPolicyStep() {
    return Step(
      title: Text(
        'Refund Policy',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Standard Refund Policy:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildPolicyItem(
            'More than 48 hours before event',
            'Full refund (minus 10% platform fee)',
            Icons.check_circle,
            AppColors.electricGreen,
          ),
          const SizedBox(height: 12),
          _buildPolicyItem(
            '24-48 hours before event',
            '50% refund (minus 10% platform fee)',
            Icons.info,
            AppTheme.warningColor,
          ),
          const SizedBox(height: 12),
          _buildPolicyItem(
            'Less than 24 hours before event',
            'No refund available',
            Icons.cancel,
            AppColors.error,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Note: Force majeure events (weather, emergencies) always receive full refunds.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
    );
  }

  Step _buildConfirmationStep() {
    return Step(
      title: Text(
        'Confirm Cancellation',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text(
                      'Are you sure?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.isHost
                      ? 'Cancelling this event will notify all attendees and process refunds. This action cannot be undone.'
                      : 'Cancelling your ticket will process your refund (if applicable). This action cannot be undone.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Summary:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildSummaryItem('Event', widget.event.title),
          _buildSummaryItem('Reason', _selectedReason ?? 'Not selected'),
          if (!widget.isHost && _refundAmount != null)
            _buildSummaryItem(
              'Refund',
              _refundAmount! > 0
                  ? '\$${_refundAmount!.toStringAsFixed(2)}'
                  : 'No refund',
            ),
        ],
      ),
      isActive: _currentStep >= 3,
      state: StepState.indexed,
    );
  }

  Widget _buildProcessingStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Processing cancellation...',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we process your refund.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    final refundStatus = _cancellation!.refundStatus;
    final hasRefund = _cancellation!.refundAmount != null && _cancellation!.refundAmount! > 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              refundStatus == RefundStatus.completed
                  ? Icons.check_circle
                  : Icons.info,
              size: 80,
              color: refundStatus == RefundStatus.completed
                  ? AppColors.electricGreen
                  : AppTheme.warningColor,
            ),
            const SizedBox(height: 24),
            Text(
              widget.isHost ? 'Event Cancelled' : 'Ticket Cancelled',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.isHost
                  ? 'All attendees have been notified and refunds are being processed.'
                  : 'Your cancellation has been processed.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasRefund) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.electricGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Refund Amount',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${_cancellation!.refundAmount!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.electricGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      refundStatus == RefundStatus.completed
                          ? 'Refund processed successfully'
                          : 'Refund is being processed',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.primaryColor).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (color ?? AppTheme.primaryColor).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(String time, String refund, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                refund,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

