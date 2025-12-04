import 'package:flutter/material.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/pages/payment/checkout_page.dart';
import 'package:spots/presentation/pages/events/event_details_page.dart';

/// Payment Failure Page
/// Agent 2: Event Discovery & Hosting UI (Section 2, Task 2.2)
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - Error message
/// - Retry button
/// - Support information
/// - Navigation back to event
class PaymentFailurePage extends StatelessWidget {
  final ExpertiseEvent event;
  final String errorMessage;
  final String? errorCode;
  final int quantity;

  const PaymentFailurePage({
    super.key,
    required this.event,
    required this.errorMessage,
    this.errorCode,
    required this.quantity,
  });

  String _getUserFriendlyMessage() {
    // Provide user-friendly error messages based on error codes
    if (errorCode != null) {
      switch (errorCode) {
        case 'EVENT_NOT_FOUND':
          return 'This event is no longer available.';
        case 'EVENT_NOT_PAID':
          return 'This event is free and does not require payment.';
        case 'PRICE_MISMATCH':
          return 'The ticket price has changed. Please try again.';
        case 'INSUFFICIENT_CAPACITY':
          return 'Sorry, there are not enough tickets available.';
        case 'USER_CANNOT_ATTEND':
          return 'You cannot attend this event.';
        case 'PAYMENT_INTENT_FAILED':
          return 'We couldn\'t process your payment. Please try again.';
        case 'PAYMENT_PROCESSING_ERROR':
          return 'An error occurred while processing your payment.';
        case 'NOT_INITIALIZED':
          return 'Payment service is not available. Please try again later.';
        default:
          return errorMessage;
      }
    }
    return errorMessage;
  }

  String _getSupportMessage() {
    if (errorCode != null) {
      switch (errorCode) {
        case 'INSUFFICIENT_CAPACITY':
        case 'EVENT_NOT_FOUND':
          return 'Please check the event details and try again.';
        case 'PAYMENT_INTENT_FAILED':
        case 'PAYMENT_PROCESSING_ERROR':
          return 'If this problem persists, please contact support.';
        default:
          return 'If you continue to experience issues, please contact support for assistance.';
      }
    }
    return 'If you continue to experience issues, please contact support for assistance.';
  }

  @override
  Widget build(BuildContext context) {
    final userFriendlyMessage = _getUserFriendlyMessage();
    final supportMessage = _getSupportMessage();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Payment Failed',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.error,
        foregroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Error Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 80,
                    color: AppColors.error,
                  ),
                ),

                const SizedBox(height: 24),

                // Error Message
                Text(
                  'Payment Failed',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                Text(
                  userFriendlyMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Error Details Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (errorCode != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Error Code: $errorCode',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Support Message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.electricGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.electricGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.electricGreen),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          supportMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutPage(event: event),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailsPage(event: event),
                        ),
                      );
                    },
                    icon: const Icon(Icons.event, size: 20),
                    label: const Text('Back to Event'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppColors.grey300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: Text(
                    'Back to Home',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),

                const SizedBox(height: 24),

                // Support Contact
                Text(
                  'Need help?',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () {
                    // TODO: Open support contact
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Support contact coming soon'),
                      ),
                    );
                  },
                  child: Text(
                    'Contact Support',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

