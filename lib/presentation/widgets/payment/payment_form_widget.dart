import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:get_it/get_it.dart';

/// Payment Form Widget
/// Agent 2: Event Discovery & Hosting UI (Section 2, Task 2.2)
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - Card input fields (simplified for MVP - uses text fields)
/// - Payment button
/// - Error display
/// - Loading states
/// 
/// **Note:** In production, this should use Stripe's card input widget for PCI compliance.
/// For MVP, we use basic text fields to demonstrate the payment flow.
class PaymentFormWidget extends StatefulWidget {
  final double amount;
  final int quantity;
  final String eventId;
  final Function(String paymentId, String paymentIntentId) onPaymentSuccess;
  final Function(String errorMessage, String? errorCode) onPaymentFailure;
  final bool isProcessing;
  final Function(bool) onProcessingChange;

  const PaymentFormWidget({
    super.key,
    required this.amount,
    required this.quantity,
    required this.eventId,
    required this.onPaymentSuccess,
    required this.onPaymentFailure,
    this.isProcessing = false,
    required this.onProcessingChange,
  });

  @override
  State<PaymentFormWidget> createState() => _PaymentFormWidgetState();
}

class _PaymentFormWidgetState extends State<PaymentFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardholderNameController = TextEditingController();
  final _paymentService = GetIt.instance<PaymentService>();
  String? _error;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardholderNameController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _error = null;
      widget.onProcessingChange(true);
    });

    try {
      // Get current user
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('User must be signed in to make a payment');
      }

      final userId = authState.user.id;
      final ticketPrice = widget.amount / widget.quantity;

      // Step 1: Create payment intent (purchaseEventTicket)
      final result = await _paymentService.purchaseEventTicket(
        eventId: widget.eventId,
        userId: userId,
        ticketPrice: ticketPrice,
        quantity: widget.quantity,
      );

      if (!result.isSuccess) {
        throw Exception(result.errorMessage ?? 'Payment failed');
      }

      if (result.payment == null || result.paymentIntent == null) {
        throw Exception('Payment intent creation failed');
      }

      final payment = result.payment!;
      final paymentIntent = result.paymentIntent!;

      // Step 2: Confirm payment
      // Note: In production, this would use Stripe's confirmCardPayment with the payment method
      // For MVP, we simulate payment confirmation
      try {
        await _paymentService.confirmPayment(
          paymentId: payment.id,
          paymentIntentId: paymentIntent.id,
        );

        // Step 3: Success - call callback
        widget.onPaymentSuccess(payment.id, paymentIntent.id);
      } catch (e) {
        // Payment confirmation failed
        await _paymentService.handlePaymentFailure(
          paymentId: payment.id,
          errorMessage: e.toString(),
        );
        throw e;
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        widget.onProcessingChange(false);
      });

      if (mounted) {
        widget.onPaymentFailure(_error!, null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Payment form',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Payment Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          const SizedBox(height: 20),

          // Cardholder Name
          Semantics(
            label: 'Cardholder name',
            textField: true,
            child: TextFormField(
              controller: _cardholderNameController,
              decoration: InputDecoration(
                labelText: 'Cardholder Name',
                hintText: 'John Doe',
                hintStyle: TextStyle(color: AppColors.textHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.grey100,
                prefixIcon: Icon(Icons.person, color: AppColors.textSecondary),
              ),
              style: TextStyle(color: AppColors.textPrimary),
              textCapitalization: TextCapitalization.words,
              enabled: !widget.isProcessing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Cardholder name is required';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),

          // Card Number
          Semantics(
            label: 'Card number',
            textField: true,
            hint: 'Enter your card number',
            child: TextFormField(
              controller: _cardNumberController,
              decoration: InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
                hintStyle: TextStyle(color: AppColors.textHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.grey100,
                prefixIcon: Icon(Icons.credit_card, color: AppColors.textSecondary),
              ),
              style: TextStyle(color: AppColors.textPrimary),
              keyboardType: TextInputType.number,
              enabled: !widget.isProcessing,
              maxLength: 19, // 16 digits + 3 spaces
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Card number is required';
                }
                // Basic validation (remove spaces)
                final cardNumber = value.replaceAll(' ', '');
                if (cardNumber.length < 13 || cardNumber.length > 19) {
                  return 'Invalid card number';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),

          // Expiry and CVV Row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  decoration: InputDecoration(
                    labelText: 'Expiry (MM/YY)',
                    hintText: '12/25',
                    hintStyle: TextStyle(color: AppColors.textHint),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.grey100,
                    prefixIcon: Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 20),
                  ),
                  style: TextStyle(color: AppColors.textPrimary),
                  keyboardType: TextInputType.number,
                  enabled: !widget.isProcessing,
                  maxLength: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Expiry is required';
                    }
                    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                      return 'Invalid format (MM/YY)';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                    hintStyle: TextStyle(color: AppColors.textHint),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.grey100,
                    prefixIcon: Icon(Icons.lock, color: AppColors.textSecondary, size: 20),
                  ),
                  style: TextStyle(color: AppColors.textPrimary),
                  keyboardType: TextInputType.number,
                  enabled: !widget.isProcessing,
                  maxLength: 4,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'CVV is required';
                    }
                    if (value.length < 3 || value.length > 4) {
                      return 'Invalid CVV';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
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
                  Icon(Icons.error_outline, color: AppColors.error, size: 20),
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
          ],

          const SizedBox(height: 24),

          // Payment Button
          Semantics(
            label: 'Pay ${widget.amount.toStringAsFixed(2)}',
            button: true,
            enabled: !widget.isProcessing,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(0, 44), // Minimum touch target
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: widget.isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Pay \$${widget.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Security Notice
          Row(
            children: [
              Icon(Icons.lock, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Your payment is secure and encrypted',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

