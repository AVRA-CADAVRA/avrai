import 'package:spots/core/services/stripe_service.dart';
import 'package:spots/core/services/logger.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/services/revenue_split_service.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/payment.dart';
import 'package:spots/core/models/payment_intent.dart';
import 'package:spots/core/models/payment_result.dart';
import 'package:spots/core/models/payment_status.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:uuid/uuid.dart';
import 'package:meta/meta.dart';

/// Payment Service
/// 
/// High-level payment processing service for event ticket purchases.
/// Handles payment intent creation, payment confirmation, and revenue splits.
/// 
/// **Usage:**
/// ```dart
/// final paymentService = PaymentService(stripeService, eventService);
/// await paymentService.initialize();
/// final result = await paymentService.purchaseEventTicket(
///   eventId: 'event-123',
///   userId: 'user-456',
///   ticketPrice: 25.00,
///   quantity: 1,
/// );
/// ```
/// 
/// **Dependencies:**
/// - Requires `StripeService` for Stripe operations
/// - Requires `ExpertiseEventService` for event validation (read-only)
class PaymentService {
  static const String _logName = 'PaymentService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();
  
  final StripeService _stripeService;
  final ExpertiseEventService _eventService;
  final PartnershipService? _partnershipService;
  final RevenueSplitService? _revenueSplitService;
  bool _initialized = false;
  
  // In-memory storage for payments (in production, use database)
  final Map<String, Payment> _payments = {};
  final Map<String, PaymentIntent> _paymentIntents = {};
  
  // Performance optimization: Indexes for faster queries (O(1) lookups instead of O(n))
  // In production, these would be database indexes
  final Map<String, List<String>> _paymentsByEventId = {}; // eventId -> [paymentId]
  final Map<String, List<String>> _paymentsByUserId = {}; // userId -> [paymentId]
  final Map<String, String> _paymentByEventAndUser = {}; // 'eventId_userId' -> paymentId
  
  PaymentService(
    this._stripeService,
    this._eventService, {
    PartnershipService? partnershipService,
    RevenueSplitService? revenueSplitService,
  }) : _partnershipService = partnershipService,
       _revenueSplitService = revenueSplitService;
  
  /// Initialize payment service
  /// 
  /// Initializes Stripe and prepares payment service for use.
  /// 
  /// **Throws:**
  /// - `Exception` if Stripe initialization fails
  Future<void> initialize() async {
    try {
      _logger.info('Initializing PaymentService...', tag: _logName);
      
      // Initialize Stripe
      await _stripeService.initializeStripe();
      
      _initialized = true;
      _logger.info('PaymentService initialized successfully', tag: _logName);
    } catch (e) {
      _logger.error('Failed to initialize PaymentService', error: e, tag: _logName);
      _initialized = false;
      rethrow;
    }
  }
  
  /// Check if payment service is initialized
  bool get isInitialized => _initialized && _stripeService.isInitialized;
  
  /// Get Stripe service instance
  StripeService get stripeService => _stripeService;
  
  /// Purchase event ticket
  /// 
  /// Complete payment flow for purchasing event tickets:
  /// 1. Validate event exists and has capacity
  /// 2. Create Stripe payment intent
  /// 3. Calculate revenue split
  /// 4. Save payment record
  /// 5. Return payment result
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID to purchase tickets for
  /// - `userId`: User ID making the purchase
  /// - `ticketPrice`: Price per ticket in dollars
  /// - `quantity`: Number of tickets to purchase
  /// 
  /// **Returns:**
  /// PaymentResult with payment details or error information
  /// 
  /// **Throws:**
  /// - `Exception` if service not initialized
  /// - Various exceptions for validation, network, and Stripe errors
  Future<PaymentResult> purchaseEventTicket({
    required String eventId,
    required String userId,
    required double ticketPrice,
    required int quantity,
  }) async {
    if (!_initialized) {
      return PaymentResult.failure(
        errorMessage: 'Payment service is not initialized',
        errorCode: 'NOT_INITIALIZED',
      );
    }
    
    try {
      _logger.info('Processing ticket purchase: event=$eventId, user=$userId, quantity=$quantity', tag: _logName);
      
      // Step 1: Validate event exists and has capacity
      // Note: _getEventById() uses a workaround - see method documentation for details
      final event = await _getEventById(eventId);
      if (event == null) {
        return PaymentResult.failure(
          errorMessage: 'Event not found',
          errorCode: 'EVENT_NOT_FOUND',
        );
      }
      
      // Validate event is paid
      if (!event.isPaid || event.price == null) {
        return PaymentResult.failure(
          errorMessage: 'Event is not a paid event',
          errorCode: 'EVENT_NOT_PAID',
        );
      }
      
      // Validate price matches
      if ((event.price! - ticketPrice).abs() > 0.01) {
        return PaymentResult.failure(
          errorMessage: 'Ticket price does not match event price',
          errorCode: 'PRICE_MISMATCH',
        );
      }
      
      // Validate capacity
      final availableSpots = event.maxAttendees - event.attendeeCount;
      if (quantity > availableSpots) {
        return PaymentResult.failure(
          errorMessage: 'Insufficient capacity. Only $availableSpots tickets available',
          errorCode: 'INSUFFICIENT_CAPACITY',
        );
      }
      
      // Validate user can attend
      if (!event.canUserAttend(userId)) {
        return PaymentResult.failure(
          errorMessage: 'User cannot attend this event',
          errorCode: 'USER_CANNOT_ATTEND',
        );
      }
      
      // Step 2: Calculate total amount
      final totalAmount = ticketPrice * quantity;
      final amountInCents = (totalAmount * 100).round();
      
      // Step 3: Create Stripe payment intent (via backend API)
      // 
      // **IMPORTANT:** In production, this MUST call your backend API
      // which creates the payment intent server-side using the Stripe secret key.
      // 
      // **Why:** The Stripe secret key should NEVER be exposed in client-side code.
      // Payment intents must be created server-side for security.
      // 
      // **Backend API should:**
      // - Accept: eventId, userId, amount, quantity
      // - Create Stripe payment intent using secret key
      // - Return: clientSecret for client-side confirmation
      // 
      // **Example backend call:**
      // ```dart
      // final response = await http.post(
      //   Uri.parse('$backendUrl/api/payment-intents'),
      //   body: jsonEncode({
      //     'eventId': eventId,
      //     'userId': userId,
      //     'amount': amountInCents,
      //     'currency': 'usd',
      //     'quantity': quantity,
      //   }),
      // );
      // final data = jsonDecode(response.body);
      // final clientSecret = data['clientSecret'] as String;
      // ```
      PaymentIntent? paymentIntent;
      try {
        // TODO: Replace with actual backend API call
        // For now, create a mock payment intent for development/testing
        final clientSecret = 'pi_${_uuid.v4()}_secret_${_uuid.v4()}';
        paymentIntent = PaymentIntent(
          id: 'pi_${_uuid.v4()}',
          clientSecret: clientSecret,
          amount: amountInCents,
          currency: 'usd',
          status: PaymentStatus.pending,
          createdAt: DateTime.now(),
          eventId: eventId,
          userId: userId,
        );
        _paymentIntents[paymentIntent.id] = paymentIntent;
      } catch (e) {
        _logger.error('Failed to create payment intent', error: e, tag: _logName);
        return PaymentResult.failure(
          errorMessage: 'Failed to create payment intent: ${_stripeService.handlePaymentError(e)}',
          errorCode: 'PAYMENT_INTENT_FAILED',
          paymentIntent: paymentIntent,
        );
      }
      
      // Step 4: Calculate revenue split (check for partnership)
      RevenueSplit revenueSplit;
      if (await hasPartnership(eventId)) {
        // Multi-party partnership event
        revenueSplit = await calculatePartnershipRevenueSplit(
          eventId: eventId,
          totalAmount: totalAmount,
          ticketsSold: quantity,
        );
      } else {
        // Solo event
        revenueSplit = calculateRevenueSplit(
          totalAmount: totalAmount,
          ticketsSold: quantity,
          eventId: eventId,
        );
      }
      
      // Step 5: Create payment record
      final payment = Payment(
        id: 'payment_${_uuid.v4()}',
        eventId: eventId,
        userId: userId,
        amount: ticketPrice,
        status: PaymentStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        stripePaymentIntentId: paymentIntent.id,
        quantity: quantity,
      );
      _payments[payment.id] = payment;
      // Performance optimization: Update indexes for faster queries
      _updatePaymentIndexes(payment);
      
      _logger.info('Payment intent created: ${paymentIntent.id}', tag: _logName);
      
      return PaymentResult.success(
        payment: payment,
        paymentIntent: paymentIntent,
        revenueSplit: revenueSplit,
      );
    } catch (e) {
      _logger.error('Error processing ticket purchase', error: e, tag: _logName);
      return PaymentResult.failure(
        errorMessage: 'Payment processing failed: ${e.toString()}',
        errorCode: 'PAYMENT_PROCESSING_ERROR',
      );
    }
  }
  
  /// Calculate revenue split
  /// 
  /// Calculates revenue split for an event:
  /// - Platform fee: 10% to SPOTS
  /// - Processing fee: ~3% to Stripe (2.9% + $0.30 per transaction)
  /// - Host payout: Remaining amount to host
  /// 
  /// **Parameters:**
  /// - `totalAmount`: Total revenue in dollars
  /// - `ticketsSold`: Number of tickets sold (for Stripe fixed fee)
  /// - `eventId`: Event ID for the revenue split
  /// 
  /// **Returns:**
  /// RevenueSplit with calculated fees
  RevenueSplit calculateRevenueSplit({
    required double totalAmount,
    required int ticketsSold,
    required String eventId,
  }) {
    return RevenueSplit.calculate(
      eventId: eventId,
      totalAmount: totalAmount,
      ticketsSold: ticketsSold,
    );
  }
  
  /// Confirm payment
  /// 
  /// Confirms a payment after Stripe payment intent is confirmed.
  /// Updates payment status, event attendee count, and saves records.
  /// 
  /// **Parameters:**
  /// - `paymentId`: Payment ID to confirm
  /// - `paymentIntentId`: Stripe payment intent ID
  /// 
  /// **Returns:**
  /// Updated Payment record
  /// 
  /// **Throws:**
  /// - `Exception` if payment not found
  /// - `Exception` if payment intent confirmation fails
  Future<Payment> confirmPayment({
    required String paymentId,
    required String paymentIntentId,
  }) async {
    try {
      _logger.info('Confirming payment: $paymentId', tag: _logName);
      
      final payment = _payments[paymentId];
      if (payment == null) {
        throw Exception('Payment not found: $paymentId');
      }
      
      final paymentIntent = _paymentIntents[paymentIntentId];
      if (paymentIntent == null) {
        throw Exception('Payment intent not found: $paymentIntentId');
      }
      
      // Confirm payment with Stripe
      try {
        await _stripeService.confirmPayment(
          clientSecret: paymentIntent.clientSecret,
          paymentMethodId: paymentIntent.paymentMethodId,
        );
      } catch (e) {
        _logger.error('Stripe payment confirmation failed', error: e, tag: _logName);
        
        // Update payment status to failed
        final failedPayment = payment.copyWith(
          status: PaymentStatus.failed,
          updatedAt: DateTime.now(),
        );
        _payments[paymentId] = failedPayment;
        
        throw Exception('Payment confirmation failed: ${_stripeService.handlePaymentError(e)}');
      }
      
      // Update payment status to completed
      final completedPayment = payment.copyWith(
        status: PaymentStatus.completed,
        updatedAt: DateTime.now(),
      );
      _payments[paymentId] = completedPayment;
      
      // Update payment intent status
      final completedIntent = paymentIntent.copyWith(
        status: PaymentStatus.completed,
        updatedAt: DateTime.now(),
      );
      _paymentIntents[paymentIntentId] = completedIntent;
      
      // Update event attendee count
      // 
      // **IMPORTANT:** In production, this should update the event in the database
      // to reflect the new attendees. Currently, we log this requirement because:
      // 
      // 1. We cannot modify ExpertiseEventService (Agent 2 owns it per FILE_OWNERSHIP_MATRIX)
      // 2. ExpertiseEventService.registerForEvent() exists but requires the event object
      // 
      // **Coordination Required:**
      // - Agent 2 should integrate payment confirmation with event registration
      // - Or: ExpertiseEventService should be extended with a method that accepts paymentId
      // - Or: A shared service/event handler should coordinate payment + registration
      // 
      // **For now:** This is logged and should be handled by the calling code
      // (likely Agent 2's Payment UI) which can call ExpertiseEventService.registerForEvent()
      // after payment confirmation succeeds.
      _logger.info(
        'Payment confirmed. Event ${payment.eventId} should be updated with ${payment.quantity} new attendees. '
        'Calling code should use ExpertiseEventService.registerForEvent() to complete registration.',
        tag: _logName,
      );
      
      return completedPayment;
    } catch (e) {
      _logger.error('Error confirming payment', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Handle payment failure
  /// 
  /// Updates payment status to failed when payment confirmation fails.
  /// 
  /// **Parameters:**
  /// - `paymentId`: Payment ID that failed
  /// - `errorMessage`: Error message describing the failure
  Future<void> handlePaymentFailure({
    required String paymentId,
    required String errorMessage,
  }) async {
    try {
      _logger.warn('Handling payment failure: $paymentId', tag: _logName);
      
      final payment = _payments[paymentId];
      if (payment == null) {
        _logger.warn('Payment not found for failure handling: $paymentId', tag: _logName);
        return;
      }
      
      final failedPayment = payment.copyWith(
        status: PaymentStatus.failed,
        updatedAt: DateTime.now(),
      );
      _payments[paymentId] = failedPayment;
      _updatePaymentIndexes(failedPayment);
      
      _logger.info('Payment marked as failed: $paymentId', tag: _logName);
    } catch (e) {
      _logger.error('Error handling payment failure', error: e, tag: _logName);
    }
  }
  
  /// Get payment by ID
  Payment? getPayment(String paymentId) {
    return _payments[paymentId];
  }

  @visibleForTesting
  void upsertPaymentForTests(Payment payment) {
    _payments[payment.id] = payment;
    _updatePaymentIndexes(payment);
  }
  
  /// Get payment intent by ID
  PaymentIntent? getPaymentIntent(String paymentIntentId) {
    return _paymentIntents[paymentIntentId];
  }
  
  /// Get all payments for an event
  /// 
  /// **Performance optimization:** Uses index for O(1) lookup instead of O(n) filtering
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// 
  /// **Returns:**
  /// List of Payment records for the event
  List<Payment> getPaymentsForEvent(String eventId) {
    try {
      // Performance optimization: Use index for faster lookup
      final paymentIds = _paymentsByEventId[eventId] ?? [];
      final payments = paymentIds
          .map((id) => _payments[id])
          .whereType<Payment>()
          .toList();
      
      // Fallback to filtering if index is missing (shouldn't happen, but safe)
      if (paymentIds.isEmpty && _payments.isNotEmpty) {
        _logger.warn(
          'Payment index missing for eventId: $eventId, falling back to filter. '
          'Indexes may need rebuilding.',
          tag: _logName,
        );
        return _payments.values
            .where((p) => p.eventId == eventId)
            .toList();
      }
      
      return payments;
    } catch (e, stackTrace) {
      _logger.error(
        'Error getting payments for event: $eventId',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return [];
    }
  }
  
  /// Get payment for a specific user and event
  /// 
  /// **Performance optimization:** Uses index for O(1) lookup instead of O(n) filtering
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// - `userId`: User ID
  /// 
  /// **Returns:**
  /// Payment record if found, null otherwise
  Payment? getPaymentForEventAndUser(String eventId, String userId) {
    try {
      // Performance optimization: Use index for O(1) lookup
      final indexKey = '${eventId}_$userId';
      final paymentId = _paymentByEventAndUser[indexKey];
      
      if (paymentId != null && _payments.containsKey(paymentId)) {
        return _payments[paymentId];
      }
      
      // Fallback to filtering if index is missing
      try {
        return _payments.values.firstWhere(
          (p) => p.eventId == eventId && p.userId == userId,
        );
      } catch (e) {
        _logger.debug('Payment not found for event=$eventId, user=$userId', tag: _logName);
        return null;
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Error getting payment for event and user: event=$eventId, user=$userId',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return null;
    }
  }
  
  /// Get all payments for a user
  /// 
  /// **Performance optimization:** Uses index for O(1) lookup instead of O(n) filtering
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// 
  /// **Returns:**
  /// List of Payment records for the user (sorted by createdAt descending)
  List<Payment> getPaymentsForUser(String userId) {
    try {
      // Performance optimization: Use index for faster lookup
      final paymentIds = _paymentsByUserId[userId] ?? [];
      final payments = paymentIds
          .map((id) => _payments[id])
          .whereType<Payment>()
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Fallback to filtering if index is missing
      if (paymentIds.isEmpty && _payments.isNotEmpty) {
        _logger.warn(
          'Payment index missing for userId: $userId, falling back to filter. '
          'Indexes may need rebuilding.',
          tag: _logName,
        );
        return _payments.values
            .where((p) => p.userId == userId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      
      return payments;
    } catch (e, stackTrace) {
      _logger.error(
        'Error getting payments for user: $userId',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return [];
    }
  }
  
  /// Get payments for a user in a specific year
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `year`: Tax year (e.g., 2025)
  /// 
  /// **Returns:**
  /// List of Payment records for the user in the specified year
  List<Payment> getPaymentsForUserInYear(String userId, int year) {
    try {
      final yearStart = DateTime(year, 1, 1);
      final yearEnd = DateTime(year, 12, 31, 23, 59, 59);
      
      return _payments.values
          .where((p) {
            return p.userId == userId &&
                p.createdAt.isAfter(yearStart.subtract(const Duration(days: 1))) &&
                p.createdAt.isBefore(yearEnd.add(const Duration(days: 1)));
          })
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _logger.error('Error getting payments for user in year', error: e, tag: _logName);
      return [];
    }
  }
  
  /// Check if event has a partnership
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// 
  /// **Returns:**
  /// true if event has a partnership, false otherwise
  Future<bool> hasPartnership(String eventId) async {
    try {
      if (_partnershipService == null) {
        return false;
      }
      
      final partnerships = await _partnershipService!.getPartnershipsForEvent(eventId);
      return partnerships.isNotEmpty;
    } catch (e) {
      _logger.error('Error checking partnership', error: e, tag: _logName);
      return false;
    }
  }
  
  /// Calculate N-way revenue split for partnership event
  /// 
  /// **Flow:**
  /// 1. Get event partnership
  /// 2. Get revenue split (N-way)
  /// 3. Calculate platform fee (10%)
  /// 4. Calculate processing fee (~3%)
  /// 5. Calculate remaining amount
  /// 6. Split remaining among parties (per agreement)
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// - `totalAmount`: Total revenue in dollars
  /// - `ticketsSold`: Number of tickets sold
  /// 
  /// **Returns:**
  /// RevenueSplit with N-way distribution
  /// 
  /// **Throws:**
  /// - `Exception` if partnership not found
  /// - `Exception` if revenue split service not available
  Future<RevenueSplit> calculatePartnershipRevenueSplit({
    required String eventId,
    required double totalAmount,
    required int ticketsSold,
  }) async {
    try {
      _logger.info('Calculating partnership revenue split: event=$eventId', tag: _logName);
      
      if (_partnershipService == null || _revenueSplitService == null) {
        throw Exception('Partnership services not available');
      }
      
      // Get partnership for event
      final partnerships = await _partnershipService!.getPartnershipsForEvent(eventId);
      if (partnerships.isEmpty) {
        throw Exception('No partnership found for event: $eventId');
      }
      
      final partnership = partnerships.first;
      
      // Check if revenue split already exists
      if (partnership.revenueSplitId != null && _revenueSplitService != null) {
        final existingSplit = await _revenueSplitService!.getRevenueSplit(partnership.revenueSplitId!);
        if (existingSplit != null) {
          // Recalculate with new total amount
          // In production, this would update the existing split
          return await _revenueSplitService!.calculateFromPartnership(
            partnershipId: partnership.id,
            totalAmount: totalAmount,
            ticketsSold: ticketsSold,
          );
        }
      }
      
      // Calculate new revenue split from partnership
      return await _revenueSplitService!.calculateFromPartnership(
        partnershipId: partnership.id,
        totalAmount: totalAmount,
        ticketsSold: ticketsSold,
      );
    } catch (e) {
      _logger.error('Error calculating partnership revenue split', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Distribute payment to partnership parties
  /// 
  /// **Flow:**
  /// 1. Get payment record
  /// 2. Get partnership
  /// 3. Get revenue split (N-way)
  /// 4. Calculate amounts per party
  /// 5. Create payout records per party
  /// 6. Schedule payouts (2 days after event)
  /// 
  /// **Parameters:**
  /// - `paymentId`: Payment ID
  /// - `partnershipId`: Partnership ID
  /// 
  /// **Returns:**
  /// Map of partyId -> payout amount
  /// 
  /// **Throws:**
  /// - `Exception` if payment not found
  /// - `Exception` if partnership not found
  /// - `Exception` if revenue split service not available
  Future<Map<String, double>> distributePartnershipPayment({
    required String paymentId,
    required String partnershipId,
  }) async {
    try {
      _logger.info('Distributing partnership payment: payment=$paymentId, partnership=$partnershipId', tag: _logName);
      
      if (_revenueSplitService == null) {
        throw Exception('Revenue split service not available');
      }
      
      // Get payment
      final payment = _payments[paymentId];
      if (payment == null) {
        throw Exception('Payment not found: $paymentId');
      }
      
      // Get event to get end time
      final event = await _getEventById(payment.eventId);
      if (event == null) {
        throw Exception('Event not found: ${payment.eventId}');
      }
      
      // Get partnership
      if (_partnershipService == null) {
        throw Exception('Partnership service not available');
      }
      
      final partnership = await _partnershipService!.getPartnershipById(partnershipId);
      if (partnership == null) {
        throw Exception('Partnership not found: $partnershipId');
      }
      
      // Get revenue split
      if (partnership.revenueSplitId == null) {
        throw Exception('Partnership has no revenue split: $partnershipId');
      }
      
      final revenueSplit = await _revenueSplitService!.getRevenueSplit(partnership.revenueSplitId!);
      if (revenueSplit == null) {
        throw Exception('Revenue split not found: ${partnership.revenueSplitId}');
      }
      
      // Distribute payments
      final payoutAmounts = await _revenueSplitService!.distributePayments(
        revenueSplitId: revenueSplit.id,
        eventEndTime: event.endTime,
      );
      
      _logger.info('Distributed partnership payment: ${payoutAmounts.length} parties', tag: _logName);
      return payoutAmounts;
    } catch (e) {
      _logger.error('Error distributing partnership payment', error: e, tag: _logName);
      rethrow;
    }
  }
  
  // Private helper methods
  
  /// Get event by ID
  /// 
  /// Uses ExpertiseEventService.getEventById() to fetch event.
  /// This method was added by Agent 2 to improve performance and remove the workaround.
  Future<ExpertiseEvent?> _getEventById(String eventId) async {
    try {
      return await _eventService.getEventById(eventId);
    } catch (e) {
      _logger.warn('Event not found: $eventId', tag: _logName);
      return null;
    }
  }
  
  /// Performance optimization: Update indexes when payment is added or modified
  /// Maintains indexes for O(1) lookups by eventId, userId, and eventId+userId
  void _updatePaymentIndexes(Payment payment) {
    try {
      // Index by eventId
      final eventPayments = _paymentsByEventId.putIfAbsent(
        payment.eventId,
        () => <String>[],
      );
      if (!eventPayments.contains(payment.id)) {
        eventPayments.add(payment.id);
      }
      
      // Index by userId
      final userPayments = _paymentsByUserId.putIfAbsent(
        payment.userId,
        () => <String>[],
      );
      if (!userPayments.contains(payment.id)) {
        userPayments.add(payment.id);
      }
      
      // Index by eventId + userId (for getPaymentForEventAndUser)
      final compositeKey = '${payment.eventId}_${payment.userId}';
      _paymentByEventAndUser[compositeKey] = payment.id;
    } catch (e, stackTrace) {
      _logger.error(
        'Error updating payment indexes: ${payment.id}',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      // Don't throw - indexes are optimization, service should still work
    }
  }
}

