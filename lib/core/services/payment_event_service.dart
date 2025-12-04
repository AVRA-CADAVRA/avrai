import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/payment.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/services/logger.dart';

/// Payment Event Service
/// 
/// Bridge service that coordinates payment processing with event registration.
/// Handles the complete flow: payment → registration for paid events.
/// 
/// **Usage:**
/// ```dart
/// final paymentEventService = PaymentEventService(
///   paymentService,
///   eventService,
/// );
/// final result = await paymentEventService.processEventPayment(
///   event: event,
///   user: user,
///   quantity: 1,
/// );
/// ```
/// 
/// **Why This Service Exists:**
/// - Agent 1 cannot modify ExpertiseEventService (Agent 2 owns it)
/// - Need to coordinate payment + registration flow
/// - Provides single entry point for event payment processing
class PaymentEventService {
  static const String _logName = 'PaymentEventService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  
  final PaymentService _paymentService;
  final ExpertiseEventService _eventService;
  
  PaymentEventService(
    this._paymentService,
    this._eventService,
  );
  
  /// Process event payment and registration
  /// 
  /// Complete flow for event payment and registration:
  /// 1. For paid events: Process payment first
  /// 2. On payment success: Register user for event
  /// 3. For free events: Register directly (no payment)
  /// 
  /// **Parameters:**
  /// - `event`: Event to register for
  /// - `user`: User registering
  /// - `quantity`: Number of tickets (default: 1)
  /// 
  /// **Returns:**
  /// PaymentEventResult with payment and registration status
  /// 
  /// **Throws:**
  /// - `Exception` if event registration fails after payment
  Future<PaymentEventResult> processEventPayment({
    required ExpertiseEvent event,
    required UnifiedUser user,
    int quantity = 1,
  }) async {
    try {
      _logger.info('Processing event payment: event=${event.id}, user=${user.id}, quantity=$quantity', tag: _logName);
      
      // For free events, register directly
      if (!event.isPaid || event.price == null || event.price == 0) {
        _logger.info('Free event - registering directly', tag: _logName);
        
        try {
          await _eventService.registerForEvent(event, user);
          return PaymentEventResult.success(
            payment: null, // No payment for free events
            event: event,
            registered: true,
          );
        } catch (e) {
          _logger.error('Free event registration failed', error: e, tag: _logName);
          return PaymentEventResult.failure(
            errorMessage: 'Registration failed: ${e.toString()}',
            errorCode: 'REGISTRATION_FAILED',
          );
        }
      }
      
      // For paid events, process payment first
      _logger.info('Paid event - processing payment first', tag: _logName);
      
      // Step 1: Process payment
      final paymentResult = await _paymentService.purchaseEventTicket(
        eventId: event.id,
        userId: user.id,
        ticketPrice: event.price!,
        quantity: quantity,
      );
      
      if (!paymentResult.isSuccess) {
        _logger.warn('Payment failed - not registering user', tag: _logName);
        return PaymentEventResult.failure(
          errorMessage: paymentResult.errorMessage ?? 'Payment failed',
          errorCode: paymentResult.errorCode ?? 'PAYMENT_FAILED',
          payment: paymentResult.payment,
        );
      }
      
      // Step 2: Payment successful - register for event
      _logger.info('Payment successful - registering user for event', tag: _logName);
      
      try {
        // Get updated event (in case attendee count changed)
        final updatedEvent = await _eventService.getEventById(event.id);
        if (updatedEvent == null) {
          throw Exception('Event not found after payment');
        }
        
        // Register user for event
        await _eventService.registerForEvent(updatedEvent, user);
        
        _logger.info('User registered for event after successful payment', tag: _logName);
        
        return PaymentEventResult.success(
          payment: paymentResult.payment,
          event: updatedEvent,
          registered: true,
          revenueSplit: paymentResult.revenueSplit,
        );
      } catch (e) {
        _logger.error('Registration failed after payment - payment already processed!', error: e, tag: _logName);
        
        // CRITICAL: Payment succeeded but registration failed
        // This is a problem - user paid but not registered
        // In production, this would trigger a refund or manual intervention
        
        return PaymentEventResult.failure(
          errorMessage: 'Payment succeeded but registration failed. Please contact support.',
          errorCode: 'REGISTRATION_FAILED_AFTER_PAYMENT',
          payment: paymentResult.payment, // Payment was successful
          registered: false,
        );
      }
    } catch (e) {
      _logger.error('Error processing event payment', error: e, tag: _logName);
      return PaymentEventResult.failure(
        errorMessage: 'Payment processing failed: ${e.toString()}',
        errorCode: 'PROCESSING_ERROR',
      );
    }
  }
  
  /// Refund event payment
  /// 
  /// Stub for future implementation (Phase 5: Operations & Compliance).
  /// 
  /// **Parameters:**
  /// - `paymentId`: Payment ID to refund
  /// - `eventId`: Event ID
  /// - `userId`: User ID requesting refund
  /// 
  /// **Returns:**
  /// Refund result
  /// 
  /// **Note:** Full refund functionality will be implemented in Phase 5 (Weeks 15-20).
  Future<RefundResult> refundEventPayment({
    required String paymentId,
    required String eventId,
    required String userId,
  }) async {
    try {
      _logger.info('Refunding event payment: payment=$paymentId, event=$eventId', tag: _logName);
      
      // TODO: Implement refund logic in Phase 5
      // 1. Verify payment exists and is refundable
      // 2. Process refund through Stripe
      // 3. Cancel event registration
      // 4. Update event attendee count
      // 5. Return refund result
      
      throw UnimplementedError(
        'Refund functionality will be implemented in Phase 5 (Operations & Compliance, Weeks 15-20)'
      );
    } catch (e) {
      _logger.error('Error refunding event payment', error: e, tag: _logName);
      rethrow;
    }
  }
}

/// Payment Event Result
/// 
/// Represents the result of processing event payment and registration.
class PaymentEventResult {
  /// Whether payment and registration were successful
  final bool isSuccess;
  
  /// Payment record (if paid event)
  final Payment? payment;
  
  /// Event (may be updated with new attendee count)
  final ExpertiseEvent? event;
  
  /// Whether user was registered for event
  final bool registered;
  
  /// Revenue split (if paid event)
  final RevenueSplit? revenueSplit;
  
  /// Error message (if failed)
  final String? errorMessage;
  
  /// Error code (if failed)
  final String? errorCode;
  
  /// When result was created
  final DateTime timestamp;

  const PaymentEventResult({
    required this.isSuccess,
    this.payment,
    this.event,
    this.registered = false,
    this.revenueSplit,
    this.errorMessage,
    this.errorCode,
    required this.timestamp,
  });

  /// Create successful result
  factory PaymentEventResult.success({
    Payment? payment,
    required ExpertiseEvent event,
    required bool registered,
    RevenueSplit? revenueSplit,
  }) {
    return PaymentEventResult(
      isSuccess: true,
      payment: payment,
      event: event,
      registered: registered,
      revenueSplit: revenueSplit,
      timestamp: DateTime.now(),
    );
  }

  /// Create failed result
  factory PaymentEventResult.failure({
    required String errorMessage,
    String? errorCode,
    Payment? payment,
    bool registered = false,
  }) {
    return PaymentEventResult(
      isSuccess: false,
      errorMessage: errorMessage,
      errorCode: errorCode,
      payment: payment,
      registered: registered,
      timestamp: DateTime.now(),
    );
  }
}

/// Refund Result
/// 
/// Represents the result of a refund operation.
/// 
/// **Note:** This is a stub for future implementation (Phase 5).
class RefundResult {
  final bool isSuccess;
  final String? refundId;
  final String? errorMessage;
  final DateTime timestamp;

  const RefundResult({
    required this.isSuccess,
    this.refundId,
    this.errorMessage,
    required this.timestamp,
  });

  factory RefundResult.success({required String refundId}) {
    return RefundResult(
      isSuccess: true,
      refundId: refundId,
      timestamp: DateTime.now(),
    );
  }

  factory RefundResult.failure({required String errorMessage}) {
    return RefundResult(
      isSuccess: false,
      errorMessage: errorMessage,
      timestamp: DateTime.now(),
    );
  }
}

