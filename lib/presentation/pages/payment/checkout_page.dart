import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/services/sales_tax_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/presentation/widgets/payment/payment_form_widget.dart';
import 'package:spots/presentation/pages/payment/payment_success_page.dart';
import 'package:spots/presentation/pages/payment/payment_failure_page.dart';
import 'package:spots/presentation/pages/legal/event_waiver_page.dart';
import 'package:spots/presentation/widgets/common/page_transitions.dart';
import 'package:spots/core/services/legal_document_service.dart';
import 'package:get_it/get_it.dart';

/// Checkout Page
/// Agent 2: Event Discovery & Hosting UI (Section 2, Task 2.2)
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - Display event details
/// - Show ticket price
/// - Quantity selector
/// - Display total amount
/// - Payment form integration
class CheckoutPage extends StatefulWidget {
  final ExpertiseEvent event;

  const CheckoutPage({
    super.key,
    required this.event,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _paymentService = GetIt.instance<PaymentService>();
  final _salesTaxService = SalesTaxService(
    eventService: GetIt.instance<ExpertiseEventService>(),
    paymentService: GetIt.instance<PaymentService>(),
  );
  final _legalService = LegalDocumentService(
    eventService: GetIt.instance<ExpertiseEventService>(),
  );
  int _quantity = 1;
  bool _isProcessing = false;
  bool _isLoadingTax = false;
  bool _hasAcceptedWaiver = false;
  bool _isCheckingWaiver = true;
  String? _error;
  double _salesTax = 0.0;
  double _taxRate = 0.0;
  bool _isTaxExempt = false;
  String? _exemptionReason;

  @override
  void initState() {
    super.initState();
    _calculateSalesTax();
    _checkWaiverStatus();
  }

  Future<void> _checkWaiverStatus() async {
    setState(() {
      _isCheckingWaiver = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final accepted = await _legalService.hasAcceptedEventWaiver(
          authState.user.id,
          widget.event.id,
        );
        setState(() {
          _hasAcceptedWaiver = accepted;
          _isCheckingWaiver = false;
        });
      } else {
        setState(() {
          _isCheckingWaiver = false;
        });
      }
    } catch (e) {
      setState(() {
        _isCheckingWaiver = false;
      });
    }
  }

  Future<void> _acceptWaiver() async {
    final result = await Navigator.push(
      context,
      PageTransitions.slideFromRight(
        EventWaiverPage(
          event: widget.event,
          requireAcceptance: true,
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _hasAcceptedWaiver = true;
      });
    }
  }

  Future<void> _calculateSalesTax() async {
    if (widget.event.price == null || widget.event.price == 0.0) return;

    setState(() {
      _isLoadingTax = true;
    });

    try {
      final calculation = await _salesTaxService.calculateSalesTax(
        eventId: widget.event.id,
        ticketPrice: widget.event.price!,
      );

      setState(() {
        _salesTax = calculation.taxAmount * _quantity;
        _taxRate = calculation.taxRate;
        _isTaxExempt = calculation.isTaxExempt;
        _exemptionReason = calculation.exemptionReason;
        _isLoadingTax = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTax = false;
        // Don't show error, just proceed without tax
      });
    }
  }

  @override
  void didUpdateWidget(CheckoutPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event.id != widget.event.id || oldWidget.event.price != widget.event.price) {
      _calculateSalesTax();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketPrice = widget.event.price ?? 0.0;
    final subtotal = ticketPrice * _quantity;
    final totalAmount = subtotal + _salesTax;
    final availableTickets = widget.event.maxAttendees - widget.event.attendeeCount;

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
                ],
              ),
            ),

            const SizedBox(height: 20),

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

                  // Subtotal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '\$${subtotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Sales Tax
                  if (_isLoadingTax)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sales Tax',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    )
                  else if (_isTaxExempt)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Sales Tax',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: AppColors.electricGreen,
                                ),
                              ],
                            ),
                            Text(
                              'Tax-Exempt',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.electricGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (_exemptionReason != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _exemptionReason!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Sales Tax',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (_taxRate > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${_taxRate.toStringAsFixed(2)}%)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '\$${_salesTax.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Divider(color: AppColors.grey300),
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
                                ? () => setState(() => _quantity--)
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
                                ? () => setState(() => _quantity++)
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

            // Event Waiver Section
            if (_isCheckingWaiver)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!_hasAcceptedWaiver) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: AppTheme.warningColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Event Waiver Required',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You must accept the event waiver before completing your purchase.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _acceptWaiver,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppColors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Review & Accept Waiver'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Payment Form (only show if waiver accepted)
            if (_hasAcceptedWaiver)
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

