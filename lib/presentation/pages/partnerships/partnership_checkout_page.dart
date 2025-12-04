import 'package:flutter/material.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/services/payment_event_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/widgets/payment/payment_form_widget.dart';
import 'package:spots/presentation/widgets/partnerships/revenue_split_display.dart';
import 'package:spots/presentation/pages/payment/payment_success_page.dart';
import 'package:spots/presentation/pages/payment/payment_failure_page.dart';
import 'package:spots/presentation/widgets/common/page_transitions.dart';
import 'package:get_it/get_it.dart';

/// Partnership Checkout Page
/// 
/// Enhanced checkout page for partnership events.
/// Shows revenue split breakdown and multi-party payment information.
/// 
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
/// 
/// **Features:**
/// - Event details display
/// - Partnership information
/// - Revenue split breakdown
/// - Multi-party payment display
/// - Payment form integration
class PartnershipCheckoutPage extends StatefulWidget {
  final ExpertiseEvent event;
  final EventPartnership? partnership;

  const PartnershipCheckoutPage({
    super.key,
    required this.event,
    this.partnership,
  });

  @override
  State<PartnershipCheckoutPage> createState() => _PartnershipCheckoutPageState();
}

class _PartnershipCheckoutPageState extends State<PartnershipCheckoutPage> {
  final _paymentService = GetIt.instance<PaymentService>();
  final _paymentEventService = GetIt.instance<PaymentEventService>();
  int _quantity = 1;
  bool _isProcessing = false;
  String? _error;
  RevenueSplit? _revenueSplit;

  @override
  void initState() {
    super.initState();
    _calculateRevenueSplit();
  }

  void _calculateRevenueSplit() {
    if (widget.event.price == null) return;

    final totalAmount = widget.event.price! * _quantity;
    
    if (widget.partnership != null && widget.partnership!.revenueSplit != null) {
      // Use existing revenue split from partnership
      _revenueSplit = widget.partnership!.revenueSplit;
    } else {
      // Calculate new revenue split
      _revenueSplit = _paymentService.calculateRevenueSplit(
        totalAmount: totalAmount,
        ticketsSold: _quantity,
        eventId: widget.event.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketPrice = widget.event.price ?? 0.0;
    final totalAmount = ticketPrice * _quantity;
    final availableTickets = widget.event.maxAttendees - widget.event.attendeeCount;
    final isPartnershipEvent = widget.partnership != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Details Card
            Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.event.getEventTypeEmoji(),
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.event.title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.event.getEventTypeDisplayName(),
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
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.calendar_today, _formatDateTime(widget.event.startTime)),
                  if (widget.event.location != null)
                    _buildDetailRow(Icons.location_on, widget.event.location!),
                  _buildDetailRow(Icons.people, '${widget.event.attendeeCount} / ${widget.event.maxAttendees} attendees'),
                  
                  // Partnership Info
                  if (isPartnershipEvent && widget.partnership!.business != null) ...[
                    const SizedBox(height: 12),
                    Divider(color: AppColors.grey300),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.handshake, size: 18, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Partnership Event with ${widget.partnership!.business!.name}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Revenue Split Display (if partnership event)
            if (isPartnershipEvent && _revenueSplit != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RevenueSplitDisplay(
                  split: _revenueSplit!,
                  showDetails: true,
                  showLockStatus: true,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Order Summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ticket Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ticket Price',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '\$${ticketPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Quantity Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quantity',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _quantity > 1 && !_isProcessing
                                ? () {
                                    setState(() {
                                      _quantity--;
                                      _calculateRevenueSplit();
                                    });
                                  }
                                : null,
                            icon: Icon(
                              Icons.remove_circle_outline,
                              color: _quantity > 1 && !_isProcessing
                                  ? AppTheme.primaryColor
                                  : AppColors.grey400,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_quantity',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _quantity < availableTickets && !_isProcessing
                                ? () {
                                    setState(() {
                                      _quantity++;
                                      _calculateRevenueSplit();
                                    });
                                  }
                                : null,
                            icon: Icon(
                              Icons.add_circle_outline,
                              color: _quantity < availableTickets && !_isProcessing
                                  ? AppTheme.primaryColor
                                  : AppColors.grey400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (availableTickets <= 5 && availableTickets > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Only $availableTickets tickets remaining!',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.warningColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                  Divider(color: AppColors.grey300),
                  const SizedBox(height: 16),

                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '\$${totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Payment Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PaymentFormWidget(
                amount: totalAmount,
                quantity: _quantity,
                eventId: widget.event.id,
                onPaymentSuccess: _handlePaymentSuccess,
                onPaymentFailure: _handlePaymentFailure,
                isProcessing: _isProcessing,
                onProcessingChange: (processing) {
                  setState(() {
                    _isProcessing = processing;
                  });
                },
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final weekday = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][dateTime.weekday - 1];
    final month = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][dateTime.month - 1];
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$weekday, $month ${dateTime.day} at $hour:${dateTime.minute.toString().padLeft(2, '0')} $ampm';
  }

  void _handlePaymentSuccess(String paymentId, String paymentIntentId) {
    Navigator.pushReplacement(
      context,
      PageTransitions.scaleAndFade(
        PaymentSuccessPage(
          event: widget.event,
          paymentId: paymentId,
          quantity: _quantity,
        ),
      ),
    );
  }

  void _handlePaymentFailure(String errorMessage, String? errorCode) {
    Navigator.pushReplacement(
      context,
      PageTransitions.fade(
        PaymentFailurePage(
          event: widget.event,
          errorMessage: errorMessage,
          errorCode: errorCode,
          quantity: _quantity,
        ),
      ),
    );
  }
}

