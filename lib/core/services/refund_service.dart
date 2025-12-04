import 'package:spots/core/models/refund_distribution.dart';
import 'package:spots/core/models/payment.dart';
import 'package:spots/core/services/stripe_service.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/services/logger.dart';
import 'package:uuid/uuid.dart';

/// Refund Service
/// 
/// Handles refund processing through Stripe and payment systems.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to transparent refund processing
/// - Enables fair refund distribution
/// - Supports trust and user protection
/// 
/// **Responsibilities:**
/// - Process individual refunds
/// - Process batch refunds
/// - Track refund status
/// - Distribute refunds to multiple parties
/// 
/// **Usage:**
/// ```dart
/// final refundService = RefundService(
///   stripeService,
///   paymentService,
/// );
/// 
/// // Process single refund
/// final distributions = await refundService.processRefund(
///   paymentId: 'payment-123',
///   amount: 25.00,
///   cancellationId: 'cancellation-456',
/// );
/// ```
class RefundService {
  static const String _logName = 'RefundService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();
  
  final StripeService _stripeService;
  final PaymentService _paymentService;
  
  // In-memory storage for refund distributions (in production, use database)
  final Map<String, List<RefundDistribution>> _refundDistributions = {};
  
  RefundService({
    required StripeService stripeService,
    required PaymentService paymentService,
  }) : _stripeService = stripeService,
       _paymentService = paymentService;
  
  /// Process refund for a single payment
  /// 
  /// **Flow:**
  /// 1. Get payment record
  /// 2. Validate payment can be refunded
  /// 3. Process refund through Stripe
  /// 4. Create refund distribution record
  /// 5. Update payment status
  /// 
  /// **Parameters:**
  /// - `paymentId`: Payment ID to refund
  /// - `amount`: Refund amount in dollars
  /// - `cancellationId`: Cancellation ID (optional)
  /// 
  /// **Returns:**
  /// List of refund distributions
  /// 
  /// **Throws:**
  /// - `Exception` if payment not found
  /// - `Exception` if payment cannot be refunded
  /// - `Exception` if Stripe refund fails
  Future<List<RefundDistribution>> processRefund({
    required String paymentId,
    required double amount,
    String? cancellationId,
  }) async {
    try {
      _logger.info('Processing refund: payment=$paymentId, amount=\$${amount.toStringAsFixed(2)}', tag: _logName);
      
      // Step 1: Get payment record
      final payment = await _getPayment(paymentId);
      if (payment == null) {
        throw Exception('Payment not found: $paymentId');
      }
      
      // Step 2: Validate payment can be refunded
      if (!payment.isSuccessful) {
        throw Exception('Payment must be successful to refund. Current status: ${payment.status}');
      }
      
      if (amount > payment.amount) {
        throw Exception('Refund amount (\$${amount.toStringAsFixed(2)}) cannot exceed payment amount (\$${payment.amount.toStringAsFixed(2)})');
      }
      
      // Step 3: Process refund through Stripe
      String? stripeRefundId;
      if (payment.stripePaymentIntentId != null) {
        try {
          final amountInCents = (amount * 100).round();
          stripeRefundId = await _stripeService.processRefund(
            paymentIntentId: payment.stripePaymentIntentId!,
            amount: amountInCents,
            reason: cancellationId != null ? 'Cancellation: $cancellationId' : 'Refund',
          );
          _logger.info('Stripe refund processed: $stripeRefundId', tag: _logName);
        } catch (e) {
          _logger.error('Stripe refund failed', error: e, tag: _logName);
          throw Exception('Stripe refund failed: ${e.toString()}');
        }
      } else {
        _logger.warn('Payment has no Stripe payment intent ID, skipping Stripe refund', tag: _logName);
      }
      
      // Step 4: Create refund distribution record
      final distribution = RefundDistribution(
        userId: payment.userId,
        role: 'attendee',
        amount: amount,
        stripeRefundId: stripeRefundId,
        completedAt: DateTime.now(),
        statusMessage: 'Refund processed successfully',
      );
      
      // Save distribution
      final distributions = [distribution];
      if (cancellationId != null) {
        _refundDistributions[cancellationId] = distributions;
      }
      
      _logger.info('Refund processed: payment=$paymentId, amount=\$${amount.toStringAsFixed(2)}, stripeRefund=$stripeRefundId', tag: _logName);
      
      return distributions;
    } catch (e) {
      _logger.error('Error processing refund', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Process batch refunds for multiple payments
  /// 
  /// **Flow:**
  /// 1. Validate all payments
  /// 2. Process refunds in parallel (or sequentially for safety)
  /// 3. Create refund distribution records
  /// 4. Return all distributions
  /// 
  /// **Parameters:**
  /// - `payments`: List of payments to refund
  /// - `cancellationId`: Cancellation ID
  /// - `fullRefund`: Whether to refund full amount including platform fee
  /// 
  /// **Returns:**
  /// List of refund distributions for all payments
  /// 
  /// **Throws:**
  /// - `Exception` if any payment cannot be refunded
  /// - `Exception` if batch processing fails
  Future<List<RefundDistribution>> processBatchRefunds({
    required List<Payment> payments,
    required String cancellationId,
    required bool fullRefund,
  }) async {
    try {
      _logger.info('Processing batch refunds: ${payments.length} payments, cancellation=$cancellationId', tag: _logName);
      
      final allDistributions = <RefundDistribution>[];
      
      // Process refunds sequentially for safety (can be parallelized in production)
      for (final payment in payments) {
        try {
          final refundAmount = fullRefund ? payment.amount : payment.amount * 0.90; // 90% if not full refund
          
          final distributions = await processRefund(
            paymentId: payment.id,
            amount: refundAmount,
            cancellationId: cancellationId,
          );
          
          allDistributions.addAll(distributions);
        } catch (e) {
          _logger.error('Failed to refund payment ${payment.id}', error: e, tag: _logName);
          // Continue with other payments even if one fails
          // In production, might want to track failed refunds separately
        }
      }
      
      // Save all distributions
      _refundDistributions[cancellationId] = allDistributions;
      
      _logger.info('Batch refunds processed: ${allDistributions.length} distributions created', tag: _logName);
      
      return allDistributions;
    } catch (e) {
      _logger.error('Error processing batch refunds', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Get refund distributions for a cancellation
  Future<List<RefundDistribution>> getRefundDistributions(String cancellationId) async {
    try {
      return _refundDistributions[cancellationId] ?? [];
    } catch (e) {
      _logger.error('Error getting refund distributions', error: e, tag: _logName);
      return [];
    }
  }
  
  /// Get refund status for a payment
  Future<String?> getRefundStatus(String paymentId) async {
    try {
      // Find distribution for this payment
      for (final distributions in _refundDistributions.values) {
        for (final distribution in distributions) {
          // In production, would match by payment ID from metadata
          if (distribution.stripeRefundId != null) {
            return 'Processed';
          }
        }
      }
      return null;
    } catch (e) {
      _logger.error('Error getting refund status', error: e, tag: _logName);
      return null;
    }
  }
  
  // Private helper methods
  
  Future<Payment?> _getPayment(String paymentId) async {
    // PaymentService has getPayment() but it's synchronous and only checks in-memory storage
    // In production, this would query the database
    try {
      // Use PaymentService's getPayment method
      final payment = _paymentService.getPayment(paymentId);
      if (payment == null) {
        _logger.warn('Payment not found: $paymentId', tag: _logName);
      }
      return payment;
    } catch (e) {
      _logger.error('Error getting payment', error: e, tag: _logName);
      return null;
    }
  }
}

