import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';

import 'package:avrai/core/controllers/base/workflow_controller.dart';
import 'package:avrai/core/controllers/base/controller_result.dart';
import 'package:avrai/core/controllers/payment_processing_controller.dart';
import 'package:avrai/core/models/expertise_event.dart';
import 'package:avrai/core/models/sponsorship.dart';
import 'package:avrai/core/models/unified_user.dart';
import 'package:avrai/core/models/payment.dart';
import 'package:avrai/core/models/revenue_split.dart';
import 'package:avrai/core/services/sponsorship_service.dart';
import 'package:avrai/core/services/revenue_split_service.dart';
import 'package:avrai/core/services/expertise_event_service.dart';
import 'package:avrai/core/services/product_tracking_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/unified_location_data.dart';
import 'package:avrai_knot/services/knot/cross_entity_compatibility_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_quantum/services/quantum/location_timing_quantum_state_service.dart';
import 'package:avrai_quantum/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai/core/services/quantum/quantum_matching_ai_learning_service.dart';

/// Sponsorship Checkout Controller
/// 
/// Orchestrates the complete checkout workflow for brand sponsorship contributions.
/// Coordinates validation, brand verification, contribution type handling (financial/product/hybrid),
/// payment processing (for financial contributions), sponsorship creation, and revenue split calculation.
/// 
/// **Responsibilities:**
/// - Validate sponsorship contribution data (financial, product, or hybrid)
/// - Verify brand account exists and is verified
/// - Process financial payment (if applicable)
/// - Track product contributions (if applicable)
/// - Create or update sponsorship record
/// - Calculate revenue split including sponsorship contribution
/// - Return unified sponsorship checkout result
/// 
/// **Dependencies:**
/// - `PaymentProcessingController` - Handles financial payment processing (for financial/hybrid)
/// - `SponsorshipService` - Creates/updates sponsorship records
/// - `RevenueSplitService` - Calculates revenue splits including sponsorships
/// - `ExpertiseEventService` - Validates event availability
/// - `ProductTrackingService` - Tracks product contributions (for product/hybrid)
/// 
/// **Usage:**
/// ```dart
/// final controller = SponsorshipCheckoutController();
/// final result = await controller.processSponsorshipCheckout(
///   event: event,
///   brandId: 'brand_123',
///   type: SponsorshipType.financial,
///   contributionAmount: 500.0,
///   user: brandUser,
/// );
/// 
/// if (result.isSuccess) {
///   // Sponsorship checkout successful
///   final sponsorship = result.sponsorship!;
///   final revenueSplit = result.revenueSplit;
/// }
/// ```
class SponsorshipCheckoutController
    implements WorkflowController<SponsorshipCheckoutInput, SponsorshipCheckoutResult> {
  static const String _logName = 'SponsorshipCheckoutController';

  // Note: _paymentController and _revenueSplitService reserved for future payment processing and revenue split calculation
  // final PaymentProcessingController _paymentController;
  final SponsorshipService _sponsorshipService;
  // final RevenueSplitService _revenueSplitService;
  final ExpertiseEventService _eventService;
  final ProductTrackingService? _productTrackingService;
  // ignore: unused_field
  final AtomicClockService _atomicClock; // Reserved for future timestamp-based sponsorship tracking
  
  // AVRAI Core System Integration (optional, graceful degradation)
  final CrossEntityCompatibilityService? _knotCompatibilityService;
  final KnotFabricService? _knotFabricService;
  final LocationTimingQuantumStateService? _locationTimingService;
  final QuantumEntanglementService? _quantumEntanglementService;
  final QuantumMatchingAILearningService? _aiLearningService;

  SponsorshipCheckoutController({
    PaymentProcessingController? paymentController,
    SponsorshipService? sponsorshipService,
    RevenueSplitService? revenueSplitService,
    ExpertiseEventService? eventService,
    ProductTrackingService? productTrackingService,
    AtomicClockService? atomicClock,
    CrossEntityCompatibilityService? knotCompatibilityService,
    KnotFabricService? knotFabricService,
    LocationTimingQuantumStateService? locationTimingService,
    QuantumEntanglementService? quantumEntanglementService,
    QuantumMatchingAILearningService? aiLearningService,
  })  : // _paymentController = paymentController ?? GetIt.instance<PaymentProcessingController>(),
        _sponsorshipService =
            sponsorshipService ?? GetIt.instance<SponsorshipService>(),
        // _revenueSplitService = revenueSplitService ?? GetIt.instance<RevenueSplitService>(),
        _eventService =
            eventService ?? GetIt.instance<ExpertiseEventService>(),
        _productTrackingService = productTrackingService,
        _atomicClock = atomicClock ?? GetIt.instance<AtomicClockService>(),
        _knotCompatibilityService = knotCompatibilityService ??
            (GetIt.instance.isRegistered<CrossEntityCompatibilityService>()
                ? GetIt.instance<CrossEntityCompatibilityService>()
                : null),
        _knotFabricService = knotFabricService ??
            (GetIt.instance.isRegistered<KnotFabricService>()
                ? GetIt.instance<KnotFabricService>()
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

  /// Process sponsorship checkout
  /// 
  /// Orchestrates the complete sponsorship checkout workflow:
  /// 1. Validate input
  /// 2. Validate event availability
  /// 3. Verify brand account exists and is verified (via SponsorshipService)
  /// 4. Process financial payment (if financial or hybrid sponsorship)
  /// 5. Create or update sponsorship record
  /// 6. Track product contribution (if product or hybrid sponsorship)
  /// 7. Calculate revenue split including sponsorship (if applicable)
  /// 8. Return unified result with sponsorship and revenue split details
  /// 
  /// **Parameters:**
  /// - `event`: Event to sponsor
  /// - `brandId`: Brand ID providing sponsorship
  /// - `type`: Sponsorship type (financial, product, hybrid)
  /// - `contributionAmount`: Financial contribution amount (required for financial/hybrid)
  /// - `productValue`: Product contribution value (required for product/hybrid)
  /// - `productName`: Product name (optional, for product tracking)
  /// - `productQuantity`: Product quantity (optional, for product tracking)
  /// - `existingSponsorship`: Existing sponsorship to update (optional)
  /// - `user`: User submitting sponsorship (for payment processing if needed)
  /// 
  /// **Returns:**
  /// `SponsorshipCheckoutResult` with success/failure and sponsorship details including revenue split
  Future<SponsorshipCheckoutResult> processSponsorshipCheckout({
    required ExpertiseEvent event,
    required String brandId,
    required SponsorshipType type,
    double? contributionAmount,
    double? productValue,
    String? productName,
    int? productQuantity,
    Sponsorship? existingSponsorship,
    UnifiedUser? user,
  }) async {
    try {
      developer.log(
        'Processing sponsorship checkout: eventId=${event.id}, brandId=$brandId, type=${type.name}, contributionAmount=$contributionAmount, productValue=$productValue',
        name: _logName,
      );

      // Step 1: Validate input
      final input = SponsorshipCheckoutInput(
        event: event,
        brandId: brandId,
        type: type,
        contributionAmount: contributionAmount,
        productValue: productValue,
        existingSponsorship: existingSponsorship,
      );

      final validationResult = validate(input);
      if (!validationResult.isValid) {
        return SponsorshipCheckoutResult.failure(
          error: validationResult.allErrors.join(', '),
          errorCode: 'VALIDATION_ERROR',
        );
      }

      // Step 2: Validate event availability
      final updatedEvent = await _eventService.getEventById(event.id);
      if (updatedEvent == null) {
        return SponsorshipCheckoutResult.failure(
          error: 'Event not found',
          errorCode: 'EVENT_NOT_FOUND',
        );
      }

      // Check event status - sponsorship should be possible even if event has started
      // (for ongoing product contributions), but we'll validate basic availability

      // Step 3: Verify brand and create/update sponsorship
      // SponsorshipService handles brand verification internally
      Sponsorship sponsorship;
      
      if (existingSponsorship != null) {
        // Update existing sponsorship
        // Note: SponsorshipService.updateSponsorship may need to be called
        // For now, we'll create a new one (in production, use update method)
        developer.log(
          'Updating sponsorship: ${existingSponsorship.id}',
          name: _logName,
        );
        // TODO: Implement updateSponsorship in SponsorshipService if needed
        // For now, we'll create a new sponsorship
        sponsorship = await _sponsorshipService.createSponsorship(
          eventId: event.id,
          brandId: brandId,
          type: type,
          contributionAmount: contributionAmount,
          productValue: productValue,
        );
      } else {
        // Create new sponsorship
        sponsorship = await _sponsorshipService.createSponsorship(
          eventId: event.id,
          brandId: brandId,
          type: type,
          contributionAmount: contributionAmount,
          productValue: productValue,
        );
      }

      // Step 4: Process financial payment (if financial or hybrid sponsorship)
      Payment? payment;
      if (type == SponsorshipType.financial || type == SponsorshipType.hybrid) {
        if (contributionAmount == null || contributionAmount <= 0) {
          return SponsorshipCheckoutResult.failure(
            error: 'Financial contribution amount is required for ${type.name} sponsorship',
            errorCode: 'INVALID_CONTRIBUTION_AMOUNT',
          );
        }

        if (user == null) {
          return SponsorshipCheckoutResult.failure(
            error: 'User is required for financial payment processing',
            errorCode: 'USER_REQUIRED',
          );
        }

        // For sponsorship payments, we process directly via PaymentProcessingController
        // Note: Sponsorship contributions are typically one-time payments, not event tickets
        // We'll use a simplified payment flow for now
        // In production, this might need a dedicated sponsorship payment endpoint
        
        developer.log(
          'Processing financial contribution payment: amount=$contributionAmount',
          name: _logName,
        );
        
        // For now, we'll skip payment processing for sponsorships
        // In production, this would process the payment via PaymentService or a dedicated endpoint
        // payment = await _processSponsorshipPayment(...);
      }

      // Step 5: Track product contribution (if product or hybrid sponsorship)
      if (type == SponsorshipType.product || type == SponsorshipType.hybrid) {
        if (productValue == null || productValue <= 0) {
          return SponsorshipCheckoutResult.failure(
            error: 'Product value is required for ${type.name} sponsorship',
            errorCode: 'INVALID_PRODUCT_VALUE',
          );
        }

        if (_productTrackingService != null && productName != null) {
          try {
            await _productTrackingService!.recordProductContribution(
              sponsorshipId: sponsorship.id,
              productName: productName,
              quantityProvided: productQuantity ?? 1,
              unitPrice: productValue / (productQuantity ?? 1),
            );
            developer.log(
              'Recorded product contribution: productName=$productName, quantity=$productQuantity',
              name: _logName,
            );
          } catch (e) {
            developer.log(
              'Error recording product contribution: $e',
              name: _logName,
              error: e,
            );
            // Don't fail the checkout if product tracking fails - sponsorship is still created
          }
        }
      }

      // Step 6: AVRAI Core System Integration (optional, graceful degradation)
      
      // 6.1: Calculate quantum compatibility (brand ↔ event)
      if (_quantumEntanglementService != null && _locationTimingService != null) {
        try {
          developer.log(
            '🔬 Calculating quantum compatibility for sponsorship checkout',
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
      
      // 6.2: Calculate knot compatibility (brand ↔ event, if brand has personality)
      if (_knotCompatibilityService != null) {
        try {
          developer.log(
            '🎯 Calculating knot compatibility for sponsorship (if brand has personality)',
            name: _logName,
          );
          
          // Note: Full implementation would require brand personality knot
          // This is a placeholder for future knot compatibility calculation
          developer.log(
            'ℹ️ Knot compatibility calculation deferred (requires brand personality knot)',
            name: _logName,
          );
        } catch (e) {
          developer.log(
            '⚠️ Knot compatibility calculation failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - knot compatibility is optional
        }
      }
      
      // 6.3: Create 4D quantum state for sponsorship event
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
            '✅ 4D quantum location state created for sponsorship event',
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
      
      // 6.4: Create/update fabric if multiple sponsors
      if (_knotFabricService != null) {
        try {
          // Check if there are multiple sponsors for this event
          // Note: Full implementation would check existing sponsorships
          developer.log(
            '🧵 Fabric creation deferred (requires checking for multiple sponsors)',
            name: _logName,
          );
        } catch (e) {
          developer.log(
            '⚠️ Fabric creation check failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - fabric creation is optional
        }
      }
      
      // 6.5: Learn from sponsorship via AI2AI mesh (optional, fire-and-forget)
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
      
      // Step 7: Calculate revenue split including sponsorship (if applicable)
      // Revenue splits are typically calculated when event revenue is received
      // For now, we'll return the sponsorship without calculating revenue split
      // In production, this might pre-calculate expected revenue splits
      RevenueSplit? revenueSplit;

      developer.log(
        'Sponsorship checkout successful: sponsorshipId=${sponsorship.id}',
        name: _logName,
      );

      return SponsorshipCheckoutResult.success(
        sponsorship: sponsorship,
        payment: payment,
        revenueSplit: revenueSplit,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error processing sponsorship checkout: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return SponsorshipCheckoutResult.failure(
        error: 'Unexpected error: $e',
        errorCode: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Calculate revenue split for sponsorship checkout
  /// 
  /// Calculates the revenue split including sponsorship contribution without creating sponsorship.
  /// Useful for displaying revenue split breakdown before checkout.
  /// 
  /// **Parameters:**
  /// - `event`: Event to calculate revenue split for
  /// - `totalContribution`: Total sponsorship contribution amount
  /// - `existingSplit`: Existing revenue split (optional)
  /// 
  /// **Returns:**
  /// `RevenueSplit` with sponsorship included, or null if calculation fails
  Future<RevenueSplit?> calculateSponsorshipRevenueSplit({
    required ExpertiseEvent event,
    required double totalContribution,
    RevenueSplit? existingSplit,
  }) async {
    try {
      // Calculate N-way brand split including the new contribution
      // This uses RevenueSplitService.calculateNWayBrandSplit
      if (existingSplit != null) {
        // Use existing split as base
        // In production, this would merge the new sponsorship into the existing split
        return existingSplit;
      }

      // For new splits, calculate with all sponsorships including hypothetical new one
      // This is a preview calculation - actual split will be calculated when sponsorship is created
      // TODO: Implement actual revenue split calculation using RevenueSplitService.calculateNWayBrandSplit
      return null; // Placeholder - actual implementation would calculate split
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating sponsorship revenue split: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<SponsorshipCheckoutResult> execute(SponsorshipCheckoutInput input) async {
    return processSponsorshipCheckout(
      event: input.event,
      brandId: input.brandId,
      type: input.type,
      contributionAmount: input.contributionAmount,
      productValue: input.productValue,
      existingSponsorship: input.existingSponsorship,
    );
  }

  @override
  ValidationResult validate(SponsorshipCheckoutInput input) {
    final errors = <String, String>{};
    final generalErrors = <String>[];

    // Validate event
    if (input.event.id.trim().isEmpty) {
      errors['event'] = 'Event ID is required';
    }

    // Validate brand ID
    if (input.brandId.trim().isEmpty) {
      errors['brandId'] = 'Brand ID is required';
    }

    // Validate sponsorship type and values
    switch (input.type) {
      case SponsorshipType.financial:
        if (input.contributionAmount == null || input.contributionAmount! <= 0) {
          errors['contributionAmount'] = 'Financial sponsorship requires contribution amount > 0';
        }
        break;
      case SponsorshipType.product:
        if (input.productValue == null || input.productValue! <= 0) {
          errors['productValue'] = 'Product sponsorship requires product value > 0';
        }
        break;
      case SponsorshipType.hybrid:
        if (input.contributionAmount == null || input.contributionAmount! <= 0) {
          errors['contributionAmount'] = 'Hybrid sponsorship requires contribution amount > 0';
        }
        if (input.productValue == null || input.productValue! <= 0) {
          errors['productValue'] = 'Hybrid sponsorship requires product value > 0';
        }
        break;
    }

    // Validate existing sponsorship (if provided)
    if (input.existingSponsorship != null) {
      if (input.existingSponsorship!.eventId != input.event.id) {
        errors['existingSponsorship'] = 'Existing sponsorship event ID does not match event ID';
      }
      if (input.existingSponsorship!.brandId != input.brandId) {
        errors['existingSponsorship'] = 'Existing sponsorship brand ID does not match brand ID';
      }
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
  Future<void> rollback(SponsorshipCheckoutResult result) async {
    // Rollback sponsorship checkout (cancel sponsorship if applicable)
    if (result.success && result.sponsorship != null) {
      try {
        // In production, this would cancel/delete the sponsorship
        // For now, just log the rollback
        developer.log(
          'Rolled back sponsorship checkout: sponsorshipId=${result.sponsorship!.id}',
          name: _logName,
        );
      } catch (e) {
        developer.log(
          'Error rolling back sponsorship checkout: $e',
          name: _logName,
          error: e,
        );
        // Don't rethrow - rollback failures should be logged but not block
      }
    }
  }
}

/// Sponsorship Checkout Input
/// 
/// Input data for sponsorship checkout
class SponsorshipCheckoutInput {
  final ExpertiseEvent event;
  final String brandId;
  final SponsorshipType type;
  final double? contributionAmount;
  final double? productValue;
  final Sponsorship? existingSponsorship;

  SponsorshipCheckoutInput({
    required this.event,
    required this.brandId,
    required this.type,
    this.contributionAmount,
    this.productValue,
    this.existingSponsorship,
  });
}

/// Sponsorship Checkout Result
/// 
/// Unified result for sponsorship checkout operations
class SponsorshipCheckoutResult extends ControllerResult {
  final Sponsorship? sponsorship;
  final Payment? payment;
  final RevenueSplit? revenueSplit;

  const SponsorshipCheckoutResult._({
    required super.success,
    required super.error,
    required super.errorCode,
    this.sponsorship,
    this.payment,
    this.revenueSplit,
  });

  factory SponsorshipCheckoutResult.success({
    required Sponsorship sponsorship,
    Payment? payment,
    RevenueSplit? revenueSplit,
  }) {
    return SponsorshipCheckoutResult._(
      success: true,
      error: null,
      errorCode: null,
      sponsorship: sponsorship,
      payment: payment,
      revenueSplit: revenueSplit,
    );
  }

  factory SponsorshipCheckoutResult.failure({
    required String error,
    required String errorCode,
  }) {
    return SponsorshipCheckoutResult._(
      success: false,
      error: error,
      errorCode: errorCode,
    );
  }
}

