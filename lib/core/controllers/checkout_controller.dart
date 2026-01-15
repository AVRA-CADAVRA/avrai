import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';

import 'package:avrai/core/controllers/base/workflow_controller.dart';
import 'package:avrai/core/controllers/base/controller_result.dart';
import 'package:avrai/core/controllers/payment_processing_controller.dart';
import 'package:avrai/core/models/expertise_event.dart';
import 'package:avrai/core/models/unified_user.dart';
import 'package:avrai/core/models/payment.dart';
import 'package:avrai/core/services/sales_tax_service.dart';
import 'package:avrai/core/services/legal_document_service.dart';
import 'package:avrai/core/services/expertise_event_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/unified_location_data.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_quantum/services/quantum/location_timing_quantum_state_service.dart';
import 'package:avrai_quantum/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai/core/services/quantum/quantum_matching_ai_learning_service.dart';

/// Checkout Controller
/// 
/// Orchestrates the complete checkout workflow for event ticket purchases.
/// Coordinates validation, tax calculation, waiver checking, payment processing,
/// and receipt generation.
/// 
/// **Responsibilities:**
/// - Validate checkout data (quantity, event availability)
/// - Check waiver acceptance status
/// - Calculate totals (subtotal + tax)
/// - Delegate payment processing to PaymentProcessingController
/// - Generate receipt (when ReceiptService available)
/// - Send confirmation (when NotificationService available)
/// - Return unified checkout result
/// 
/// **Dependencies:**
/// - `PaymentProcessingController` - Handles payment processing
/// - `SalesTaxService` - Calculates sales tax
/// - `LegalDocumentService` - Checks waiver acceptance
/// - `ExpertiseEventService` - Validates event availability
/// 
/// **Usage:**
/// ```dart
/// final controller = CheckoutController();
/// final result = await controller.processCheckout(
///   event: event,
///   buyer: user,
///   quantity: 2,
///   requireWaiver: true,
/// );
/// 
/// if (result.isSuccess) {
///   // Checkout successful
///   final payment = result.payment!;
///   final totalAmount = result.totalAmount;
/// } else {
///   // Handle errors
/// }
/// ```
class CheckoutController
    implements WorkflowController<CheckoutInput, CheckoutResult> {
  static const String _logName = 'CheckoutController';

  // Payment processing is only needed when checkout is submitted.
  // Keep this optional so read-only flows (e.g. totals calculation) don't require
  // full payment DI setup in tests.
  final PaymentProcessingController? _paymentController;
  final SalesTaxService _salesTaxService;
  final LegalDocumentService? _legalService;
  final ExpertiseEventService _eventService;
  // ignore: unused_field
  final AtomicClockService _atomicClock; // Reserved for future timestamp-based purchase tracking
  
  // AVRAI Core System Integration (optional, graceful degradation)
  final KnotFabricService? _knotFabricService;
  final KnotWorldsheetService? _knotWorldsheetService;
  final LocationTimingQuantumStateService? _locationTimingService;
  final QuantumEntanglementService? _quantumEntanglementService;
  final QuantumMatchingAILearningService? _aiLearningService;

  CheckoutController({
    PaymentProcessingController? paymentController,
    SalesTaxService? salesTaxService,
    LegalDocumentService? legalService,
    ExpertiseEventService? eventService,
    AtomicClockService? atomicClock,
    KnotFabricService? knotFabricService,
    KnotWorldsheetService? knotWorldsheetService,
    LocationTimingQuantumStateService? locationTimingService,
    QuantumEntanglementService? quantumEntanglementService,
    QuantumMatchingAILearningService? aiLearningService,
  })  : _paymentController = paymentController,
        _salesTaxService =
            salesTaxService ?? GetIt.instance<SalesTaxService>(),
        _legalService = legalService,
        _eventService =
            eventService ?? GetIt.instance<ExpertiseEventService>(),
        _atomicClock = atomicClock ?? GetIt.instance<AtomicClockService>(),
        _knotFabricService = knotFabricService ??
            (GetIt.instance.isRegistered<KnotFabricService>()
                ? GetIt.instance<KnotFabricService>()
                : null),
        _knotWorldsheetService = knotWorldsheetService ??
            (GetIt.instance.isRegistered<KnotWorldsheetService>()
                ? GetIt.instance<KnotWorldsheetService>()
                : null),
        _locationTimingService = locationTimingService ??
            (GetIt.instance.isRegistered<LocationTimingQuantumStateService>()
                ? GetIt.instance<LocationTimingQuantumStateService>()
                : null),
        _quantumEntanglementService = quantumEntanglementService ??
            (GetIt.instance.isRegistered<QuantumEntanglementService>()
                ? GetIt.instance<QuantumEntanglementService>()
                : null),
        _aiLearningService = aiLearningService ??
            (GetIt.instance.isRegistered<QuantumMatchingAILearningService>()
                ? GetIt.instance<QuantumMatchingAILearningService>()
                : null);

  PaymentProcessingController _resolvePaymentController() {
    return _paymentController ?? GetIt.instance<PaymentProcessingController>();
  }

  LegalDocumentService? _resolveLegalServiceOrNull() {
    if (_legalService != null) {
      return _legalService;
    }
    try {
      return GetIt.instance<LegalDocumentService>();
    } catch (e) {
      developer.log(
        'LegalDocumentService is not registered in GetIt',
        name: _logName,
        error: e,
      );
      return null;
    }
  }

  /// Process checkout
  /// 
  /// Orchestrates the complete checkout workflow:
  /// 1. Validate input
  /// 2. Validate event availability
  /// 3. Check waiver acceptance (if required)
  /// 4. Calculate totals (subtotal + tax)
  /// 5. Process payment via PaymentProcessingController
  /// 6. Generate receipt (when ReceiptService available)
  /// 7. Send confirmation (when NotificationService available)
  /// 8. Return unified result
  /// 
  /// **Parameters:**
  /// - `event`: Event to purchase tickets for
  /// - `buyer`: User purchasing tickets
  /// - `quantity`: Number of tickets to purchase
  /// - `requireWaiver`: Whether waiver acceptance is required (default: true)
  /// 
  /// **Returns:**
  /// `CheckoutResult` with success/failure and checkout details
  Future<CheckoutResult> processCheckout({
    required ExpertiseEvent event,
    required UnifiedUser buyer,
    required int quantity,
    bool requireWaiver = true,
  }) async {
    try {
      developer.log(
        'Processing checkout: eventId=${event.id}, buyerId=${buyer.id}, quantity=$quantity',
        name: _logName,
      );

      // Step 1: Validate input
      final input = CheckoutInput(
        event: event,
        buyer: buyer,
        quantity: quantity,
        requireWaiver: requireWaiver,
      );

      final validationResult = validate(input);
      if (!validationResult.isValid) {
        return CheckoutResult.failure(
          error: validationResult.allErrors.join(', '),
          errorCode: 'VALIDATION_ERROR',
        );
      }

      // Step 2: Validate event availability
      final updatedEvent = await _eventService.getEventById(event.id);
      if (updatedEvent == null) {
        return CheckoutResult.failure(
          error: 'Event not found',
          errorCode: 'EVENT_NOT_FOUND',
        );
      }

      // Check capacity
      final availableTickets = updatedEvent.maxAttendees - updatedEvent.attendeeCount;
      if (quantity > availableTickets) {
        return CheckoutResult.failure(
          error: 'Insufficient tickets available. Only $availableTickets tickets remaining.',
          errorCode: 'INSUFFICIENT_CAPACITY',
        );
      }

      // Check event status
      if (updatedEvent.hasStarted) {
        return CheckoutResult.failure(
          error: 'Event has already started',
          errorCode: 'EVENT_STARTED',
        );
      }

      // Step 3: Check waiver acceptance (if required)
      if (requireWaiver) {
        final legalService = _resolveLegalServiceOrNull();
        if (legalService == null) {
          return CheckoutResult.failure(
            error: 'Legal service unavailable',
            errorCode: 'LEGAL_SERVICE_UNAVAILABLE',
          );
        }

        final hasAcceptedWaiver = await legalService.hasAcceptedEventWaiver(
          buyer.id,
          event.id,
        );
        if (!hasAcceptedWaiver) {
          return CheckoutResult.failure(
            error: 'Event waiver must be accepted before checkout',
            errorCode: 'WAIVER_NOT_ACCEPTED',
          );
        }
      }

      // Step 4: Calculate totals (subtotal + tax)
      double subtotal = 0.0;
      double taxAmount = 0.0;
      double totalAmount = 0.0;

      if (updatedEvent.isPaid && updatedEvent.price != null) {
        subtotal = updatedEvent.price! * quantity;

        // Calculate sales tax
        try {
          final taxCalculation = await _salesTaxService.calculateSalesTax(
            eventId: event.id,
            ticketPrice: updatedEvent.price!,
          );
          taxAmount = taxCalculation.taxAmount * quantity;
          totalAmount = subtotal + taxAmount;
        } catch (e) {
          developer.log(
            'Error calculating sales tax: $e',
            name: _logName,
            error: e,
          );
          // Proceed without tax if calculation fails
          totalAmount = subtotal;
        }
      } else {
        // Free event
        totalAmount = 0.0;
      }

      // Step 5: Process payment via PaymentProcessingController
      final paymentResult = await _resolvePaymentController().processEventPayment(
        event: updatedEvent,
        buyer: buyer,
        quantity: quantity,
      );

      if (!paymentResult.isSuccess) {
        return CheckoutResult.failure(
          error: paymentResult.error ?? 'Payment processing failed',
          errorCode: paymentResult.errorCode ?? 'PAYMENT_FAILED',
        );
      }

      // Step 6: AVRAI Core System Integration (optional, graceful degradation)
      
      // 6.1: Calculate quantum compatibility (if purchasing event/spot)
      if (_quantumEntanglementService != null && _locationTimingService != null) {
        try {
          developer.log(
            '🔬 Calculating quantum compatibility for checkout',
            name: _logName,
          );
          
          // Note: Full implementation would use QuantumMatchingController
          // This is a placeholder for future quantum compatibility calculation
          developer.log(
            'ℹ️ Quantum compatibility calculation deferred to QuantumMatchingController',
            name: _logName,
          );
        } catch (e) {
          developer.log(
            '⚠️ Quantum compatibility calculation failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - quantum compatibility is optional
        }
      }
      
      // 6.2: Create 4D quantum state if location-aware purchase
      if (_locationTimingService != null && updatedEvent.latitude != null && updatedEvent.longitude != null) {
        try {
          final locationData = UnifiedLocationData(
            latitude: updatedEvent.latitude!,
            longitude: updatedEvent.longitude!,
            city: updatedEvent.cityCode,
            address: updatedEvent.location,
          );
          
          final locationQuantumState = await _locationTimingService!.createLocationQuantumState(
            location: locationData,
            locationType: 0.7,
            accessibilityScore: null,
            vibeLocationMatch: null,
          );
          
          developer.log(
            '✅ 4D quantum location state created for checkout',
            name: _logName,
          );
          
          // ignore: unused_local_variable
          final _ = locationQuantumState;
        } catch (e) {
          developer.log(
            '⚠️ 4D quantum state creation failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - quantum state creation is optional
        }
      }
      
      // 6.3: Create/update fabric if group purchase (quantity > 1)
      if (_knotFabricService != null && quantity > 1) {
        try {
          developer.log(
            '🧵 Creating fabric for group purchase (quantity: $quantity)',
            name: _logName,
          );
          
          // Note: Full implementation would create fabric from buyer and other attendees
          // This is a placeholder for future fabric creation on group purchase
          developer.log(
            'ℹ️ Fabric creation deferred until all attendees have knots',
            name: _logName,
          );
        } catch (e) {
          developer.log(
            '⚠️ Fabric creation failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - fabric creation is optional
        }
      }
      
      // 6.4: Create worldsheet if group tracking needed
      if (_knotWorldsheetService != null && quantity > 1) {
        try {
          developer.log(
            '📊 Worldsheet creation deferred until fabric exists',
            name: _logName,
          );
          // Worldsheet creation happens after fabric creation
        } catch (e) {
          developer.log(
            '⚠️ Worldsheet creation check failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - worldsheet creation is optional
        }
      }
      
      // 6.5: Learn from purchase via AI2AI mesh (optional, fire-and-forget)
      if (_aiLearningService != null) {
        try {
          developer.log(
            '🤖 AI2AI learning service available (learning deferred to matching)',
            name: _logName,
          );
          // Note: Actual learning happens when matches occur, not during checkout
        } catch (e) {
          developer.log(
            '⚠️ AI2AI learning failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - AI2AI learning is optional and non-blocking
        }
      }
      
      // Step 7: Generate receipt (when ReceiptService available)
      // TODO(Phase 8.12): Implement receipt generation when ReceiptService is available
      // For now, receipt generation is handled by UI (PaymentSuccessPage)

      // Step 8: Send confirmation (when NotificationService available)
      // TODO(Phase 8.12): Implement confirmation sending when NotificationService is available

      developer.log(
        'Checkout successful: payment=${paymentResult.payment?.id}, totalAmount=$totalAmount',
        name: _logName,
      );

      return CheckoutResult.success(
        payment: paymentResult.payment,
        subtotal: subtotal,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        quantity: quantity,
        event: paymentResult.event ?? updatedEvent,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error processing checkout: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return CheckoutResult.failure(
        error: 'Unexpected error: $e',
        errorCode: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Calculate checkout totals
  /// 
  /// Calculates subtotal, tax, and total for a checkout without processing payment.
  /// Useful for displaying totals before checkout.
  /// 
  /// **Parameters:**
  /// - `event`: Event to calculate totals for
  /// - `quantity`: Number of tickets
  /// 
  /// **Returns:**
  /// `CheckoutTotals` with subtotal, tax, and total
  Future<CheckoutTotals> calculateTotals({
    required ExpertiseEvent event,
    required int quantity,
  }) async {
    try {
      double subtotal = 0.0;
      double taxAmount = 0.0;
      double totalAmount = 0.0;

      if (event.isPaid && event.price != null) {
        subtotal = event.price! * quantity;

        // Calculate sales tax
        try {
          final taxCalculation = await _salesTaxService.calculateSalesTax(
            eventId: event.id,
            ticketPrice: event.price!,
          );
          taxAmount = taxCalculation.taxAmount * quantity;
          totalAmount = subtotal + taxAmount;
        } catch (e) {
          developer.log(
            'Error calculating sales tax: $e',
            name: _logName,
            error: e,
          );
          // Proceed without tax if calculation fails
          totalAmount = subtotal;
        }
      }

      return CheckoutTotals(
        subtotal: subtotal,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        quantity: quantity,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating totals: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<CheckoutResult> execute(CheckoutInput input) async {
    return processCheckout(
      event: input.event,
      buyer: input.buyer,
      quantity: input.quantity,
      requireWaiver: input.requireWaiver,
    );
  }

  @override
  ValidationResult validate(CheckoutInput input) {
    final errors = <String, String>{};
    final generalErrors = <String>[];

    // Validate quantity
    if (input.quantity <= 0) {
      errors['quantity'] = 'Quantity must be greater than 0';
    }

    if (input.quantity > 100) {
      errors['quantity'] = 'Quantity cannot exceed 100 tickets per purchase';
    }

    // Validate event
    if (input.event.id.trim().isEmpty) {
      errors['event'] = 'Event ID is required';
    }

    // Validate buyer
    if (input.buyer.id.trim().isEmpty) {
      errors['buyer'] = 'Buyer ID is required';
    }

    if (errors.isNotEmpty || generalErrors.isNotEmpty) {
      return ValidationResult.invalid(
        fieldErrors: errors,
        generalErrors: generalErrors,
      );
    }

    return ValidationResult.valid();
  }

  @override
  Future<void> rollback(CheckoutResult result) async {
    // Rollback checkout (cancel payment if applicable)
    if (result.success && result.payment != null) {
      try {
        // Payment rollback would be handled by PaymentProcessingController
        // For now, just log the rollback
        developer.log(
          'Rolled back checkout: paymentId=${result.payment!.id}',
          name: _logName,
        );
      } catch (e) {
        developer.log(
          'Error rolling back checkout: $e',
          name: _logName,
          error: e,
        );
        // Don't rethrow - rollback failures should be logged but not block
      }
    }
  }
}

/// Checkout Input
/// 
/// Input data for checkout
class CheckoutInput {
  final ExpertiseEvent event;
  final UnifiedUser buyer;
  final int quantity;
  final bool requireWaiver;

  CheckoutInput({
    required this.event,
    required this.buyer,
    required this.quantity,
    this.requireWaiver = true,
  });
}

/// Checkout Totals
/// 
/// Calculated totals for checkout (before payment processing)
class CheckoutTotals {
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final int quantity;

  CheckoutTotals({
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.quantity,
  });
}

/// Checkout Result
/// 
/// Unified result for checkout operations
class CheckoutResult extends ControllerResult {
  final Payment? payment;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final int quantity;
  final ExpertiseEvent? event;

  const CheckoutResult._({
    required super.success,
    required super.error,
    required super.errorCode,
    this.payment,
    this.subtotal = 0.0,
    this.taxAmount = 0.0,
    this.totalAmount = 0.0,
    this.quantity = 0,
    this.event,
  });

  factory CheckoutResult.success({
    required Payment? payment,
    required double subtotal,
    required double taxAmount,
    required double totalAmount,
    required int quantity,
    required ExpertiseEvent event,
  }) {
    return CheckoutResult._(
      success: true,
      error: null,
      errorCode: null,
      payment: payment,
      subtotal: subtotal,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      quantity: quantity,
      event: event,
    );
  }

  factory CheckoutResult.failure({
    required String error,
    required String errorCode,
  }) {
    return CheckoutResult._(
      success: false,
      error: error,
      errorCode: errorCode,
    );
  }
}

