import 'package:avrai/core/controllers/base/workflow_controller.dart';
import 'package:avrai/core/controllers/base/controller_result.dart';
import 'package:avrai/core/services/sales_tax_service.dart';
import 'package:avrai/core/services/payment_event_service.dart';
import 'package:avrai/core/models/expertise_event.dart';
import 'package:avrai/core/models/unified_user.dart';
import 'package:avrai/core/models/payment.dart';
import 'package:avrai/core/models/payment_intent.dart';
import 'package:avrai/core/models/revenue_split.dart';
import 'dart:developer' as developer;

/// Payment Processing Controller
///
/// Orchestrates the complete payment processing workflow for event ticket purchases.
/// Coordinates multiple services to handle payment validation, tax calculation,
/// payment processing, event registration, and receipt generation.
///
/// **Flow:**
/// 1. Validate payment data
/// 2. Calculate sales tax
/// 3. Calculate revenue split (includes tax in total)
/// 4. Process Stripe payment
/// 5. Update event (add attendee)
/// 6. Generate receipt (if ReceiptService available)
/// 7. Return unified result
///
/// **Usage:**
/// ```dart
/// final controller = GetIt.instance<PaymentProcessingController>();
/// final result = await controller.processEventPayment(
///   event: event,
///   buyer: user,
///   quantity: 2,
/// );
/// if (result.isSuccess) {
///   // Payment successful
///   final payment = result.payment!;
///   final taxAmount = result.taxAmount;
/// } else {
///   // Handle error
///   developer.log('Payment processing failed: ${result.error}',
///     name: 'PaymentProcessingController');
/// }
/// ```
class PaymentProcessingController
    implements WorkflowController<PaymentData, PaymentProcessingResult> {
  static const String _logName = 'PaymentProcessingController';

  final SalesTaxService _salesTaxService;
  final PaymentEventService _paymentEventService;

  PaymentProcessingController({
    required SalesTaxService salesTaxService,
    required PaymentEventService paymentEventService,
  })  : _salesTaxService = salesTaxService,
        _paymentEventService = paymentEventService;

  /// Process event payment
  ///
  /// Complete payment processing workflow:
  /// 1. Validate payment data
  /// 2. Calculate sales tax
  /// 3. Calculate revenue split
  /// 4. Process payment via PaymentService
  /// 5. Register user for event
  /// 6. Return unified result
  ///
  /// **Parameters:**
  /// - `event`: Event to purchase tickets for
  /// - `buyer`: User making the purchase
  /// - `quantity`: Number of tickets (default: 1)
  ///
  /// **Returns:**
  /// PaymentProcessingResult with payment details, tax, and registration status
  Future<PaymentProcessingResult> processEventPayment({
    required ExpertiseEvent event,
    required UnifiedUser buyer,
    int quantity = 1,
  }) async {
    try {
      developer.log(
        'Processing event payment: event=${event.id}, buyer=${buyer.id}, quantity=$quantity',
        name: _logName,
      );

      // Step 1: Validate payment data
      final validation = validatePayment(
        event: event,
        buyer: buyer,
        quantity: quantity,
      );
      if (!validation.isValid) {
        return PaymentProcessingResult.failure(
          error: validation.firstError ?? 'Payment validation failed',
          errorCode: 'VALIDATION_FAILED',
          validationErrors: validation.fieldErrors,
        );
      }

      // Step 2: Calculate sales tax
      SalesTaxCalculation? taxCalculation;
      double taxAmount = 0.0;
      if (event.isPaid && event.price != null && event.price! > 0) {
        try {
          taxCalculation = await _salesTaxService.calculateSalesTax(
            eventId: event.id,
            ticketPrice: event.price!,
          );
          taxAmount = taxCalculation.taxAmount * quantity;
        } catch (e) {
          developer.log(
            'Sales tax calculation failed: $e',
            name: _logName,
            error: e,
          );
          // Continue without tax - log warning but don't fail payment
        }
      }

      // Step 3: Calculate total amount (price + tax)
      final ticketPrice = event.price ?? 0.0;
      final subtotal = ticketPrice * quantity;
      final totalAmount = subtotal + taxAmount;

      // Step 4: Process payment via PaymentEventService (handles payment + registration)
      final paymentResult = await _paymentEventService.processEventPayment(
        event: event,
        user: buyer,
        quantity: quantity,
      );

      if (!paymentResult.isSuccess) {
        return PaymentProcessingResult.failure(
          error: paymentResult.errorMessage ?? 'Payment processing failed',
          errorCode: paymentResult.errorCode ?? 'PAYMENT_FAILED',
          payment: paymentResult.payment,
        );
      }

      // Step 5: Get updated event (with new attendee count)
      final updatedEvent = paymentResult.event;
      if (updatedEvent == null) {
        return PaymentProcessingResult.failure(
          error: 'Event not found after payment',
          errorCode: 'EVENT_NOT_FOUND',
          payment: paymentResult.payment,
        );
      }

      // Step 6: Generate receipt (if ReceiptService available)
      // TODO(Phase 8.11): Implement receipt generation when ReceiptService is available
      // For now, receipt generation is handled by UI (PaymentSuccessPage)

      developer.log(
        'Payment processing successful: payment=${paymentResult.payment?.id}, taxAmount=$taxAmount',
        name: _logName,
      );

      // Get payment intent from payment if available
      PaymentIntent? paymentIntent;
      if (paymentResult.payment?.stripePaymentIntentId != null) {
        // PaymentIntent would need to be retrieved from PaymentService
        // For now, leave as null - can be added later if needed
      }

      // For free events, payment may be null - that's okay
      if (paymentResult.payment == null && event.isPaid) {
        return PaymentProcessingResult.failure(
          error: 'Payment record not found for paid event',
          errorCode: 'PAYMENT_NOT_FOUND',
        );
      }

      return PaymentProcessingResult.success(
        payment: paymentResult.payment, // May be null for free events
        paymentIntent: paymentIntent,
        revenueSplit: paymentResult.revenueSplit,
        taxCalculation: taxCalculation,
        taxAmount: taxAmount,
        subtotal: subtotal,
        totalAmount: totalAmount,
        event: updatedEvent,
        quantity: quantity,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error processing payment',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return PaymentProcessingResult.failure(
        error: 'Payment processing failed: ${e.toString()}',
        errorCode: 'PROCESSING_ERROR',
      );
    }
  }

  /// Process refund
  ///
  /// Processes a refund for a completed payment.
  ///
  /// **Parameters:**
  /// - `paymentId`: Payment ID to refund
  /// - `reason`: Reason for refund
  ///
  /// **Returns:**
  /// PaymentProcessingResult with refund details
  ///
  /// **Note:** Refund functionality not yet implemented in PaymentService
  Future<PaymentProcessingResult> processRefund({
    required String paymentId,
    required String reason,
  }) async {
    try {
      developer.log(
        'Processing refund: payment=$paymentId, reason=$reason',
        name: _logName,
      );

      // TODO(Phase 8.11): Implement refund processing when PaymentService.refund() is available
      // For now, return failure indicating refunds are not yet supported
      return PaymentProcessingResult.failure(
        error: 'Refund processing is not yet implemented',
        errorCode: 'REFUND_NOT_IMPLEMENTED',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error processing refund',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return PaymentProcessingResult.failure(
        error: 'Refund processing failed: ${e.toString()}',
        errorCode: 'REFUND_ERROR',
      );
    }
  }

  /// Validate payment data
  ///
  /// Validates payment request before processing.
  /// Checks event availability, user eligibility, and payment requirements.
  ///
  /// **Parameters:**
  /// - `event`: Event to purchase tickets for
  /// - `buyer`: User making the purchase
  /// - `quantity`: Number of tickets
  ///
  /// **Returns:**
  /// ValidationResult with any validation errors
  ValidationResult validatePayment({
    required ExpertiseEvent event,
    required UnifiedUser buyer,
    required int quantity,
  }) {
    final errors = <String, String>{};
    final generalErrors = <String>[];

    // Validate event exists and is available
    if (event.status != EventStatus.upcoming) {
      errors['event'] = 'Event is not available for purchase';
    }

    // Validate event hasn't started
    if (DateTime.now().isAfter(event.startTime)) {
      errors['event'] = 'Event has already started';
    }

    // Validate quantity
    if (quantity <= 0) {
      errors['quantity'] = 'Quantity must be greater than 0';
    }

    // Validate capacity
    final availableSpots = event.maxAttendees - event.attendeeCount;
    if (quantity > availableSpots) {
      errors['quantity'] =
          'Insufficient capacity. Only $availableSpots tickets available';
    }

    // Validate user can attend (expertise/geographic scope)
    // This checks attendeeIds, so we check it first to get the more specific error
    if (!event.canUserAttend(buyer.id)) {
      // Check if it's because user is already registered
      if (event.attendeeIds.contains(buyer.id)) {
        errors['buyer'] = 'User is already registered for this event';
      } else {
        errors['buyer'] =
            'User cannot attend this event (expertise or geographic scope restriction)';
      }
    }

    // Validate paid event has price
    if (event.isPaid && (event.price == null || event.price! <= 0)) {
      errors['event'] = 'Paid event must have a valid price';
    }

    if (errors.isNotEmpty || generalErrors.isNotEmpty) {
      return ValidationResult.invalid(
        fieldErrors: errors,
        generalErrors: generalErrors,
      );
    }

    return ValidationResult.valid();
  }

  // WorkflowController implementation

  @override
  Future<PaymentProcessingResult> execute(PaymentData input) async {
    return processEventPayment(
      event: input.event,
      buyer: input.buyer,
      quantity: input.quantity,
    );
  }

  @override
  ValidationResult validate(PaymentData input) {
    return validatePayment(
      event: input.event,
      buyer: input.buyer,
      quantity: input.quantity,
    );
  }

  @override
  Future<void> rollback(PaymentProcessingResult result) async {
    // TODO(Phase 8.11): Implement rollback logic if needed
    // For payments, rollback would involve refunding the payment
    // This is complex and should be handled carefully
    if (result.isSuccess && result.payment != null) {
      developer.log(
        'Rollback requested for payment: ${result.payment!.id}',
        name: _logName,
      );
      // For now, rollback is not implemented - manual intervention required
    }
  }
}

/// Payment data input for PaymentProcessingController
///
/// Encapsulates all data needed to process a payment.
class PaymentData {
  final ExpertiseEvent event;
  final UnifiedUser buyer;
  final int quantity;

  const PaymentData({
    required this.event,
    required this.buyer,
    this.quantity = 1,
  });
}

/// Payment Processing Result
///
/// Unified result for payment processing operations.
/// Extends ControllerResult and includes all payment-related data.
class PaymentProcessingResult extends ControllerResult {
  /// Payment record (if successful)
  final Payment? payment;

  /// Payment intent (if created)
  final PaymentIntent? paymentIntent;

  /// Revenue split calculation
  final RevenueSplit? revenueSplit;

  /// Sales tax calculation
  final SalesTaxCalculation? taxCalculation;

  /// Tax amount (calculated)
  final double taxAmount;

  /// Subtotal (price * quantity)
  final double subtotal;

  /// Total amount (subtotal + tax)
  final double totalAmount;

  /// Updated event (with new attendee count)
  final ExpertiseEvent? event;

  /// Number of tickets purchased
  final int quantity;

  /// Validation errors (if validation failed)
  final Map<String, String>? validationErrors;

  const PaymentProcessingResult({
    required super.success,
    super.error,
    super.errorCode,
    super.metadata,
    this.payment,
    this.paymentIntent,
    this.revenueSplit,
    this.taxCalculation,
    this.taxAmount = 0.0,
    this.subtotal = 0.0,
    this.totalAmount = 0.0,
    this.event,
    this.quantity = 0,
    this.validationErrors,
  });

  /// Create successful payment result
  factory PaymentProcessingResult.success({
    Payment? payment, // May be null for free events
    PaymentIntent? paymentIntent,
    RevenueSplit? revenueSplit,
    SalesTaxCalculation? taxCalculation,
    required double taxAmount,
    required double subtotal,
    required double totalAmount,
    required ExpertiseEvent event,
    required int quantity,
  }) {
    return PaymentProcessingResult(
      success: true,
      payment: payment,
      paymentIntent: paymentIntent,
      revenueSplit: revenueSplit,
      taxCalculation: taxCalculation,
      taxAmount: taxAmount,
      subtotal: subtotal,
      totalAmount: totalAmount,
      event: event,
      quantity: quantity,
      metadata: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Create failed payment result
  factory PaymentProcessingResult.failure({
    required String error,
    String? errorCode,
    Payment? payment,
    Map<String, String>? validationErrors,
  }) {
    return PaymentProcessingResult(
      success: false,
      error: error,
      errorCode: errorCode,
      payment: payment,
      validationErrors: validationErrors,
      metadata: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        payment,
        paymentIntent,
        revenueSplit,
        taxCalculation,
        taxAmount,
        subtotal,
        totalAmount,
        event,
        quantity,
        validationErrors,
      ];
}
