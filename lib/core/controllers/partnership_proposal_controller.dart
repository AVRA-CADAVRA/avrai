import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';

import 'package:avrai/core/controllers/base/workflow_controller.dart';
import 'package:avrai/core/controllers/base/controller_result.dart';
import 'package:avrai/core/models/event_partnership.dart';
import 'package:avrai/core/models/revenue_split.dart';
import 'package:avrai/core/services/partnership_service.dart';
import 'package:avrai/core/services/business_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_knot/services/knot/cross_entity_compatibility_service.dart';
import 'package:avrai_quantum/services/quantum/location_timing_quantum_state_service.dart';
import 'package:avrai_quantum/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai/core/services/quantum/quantum_matching_ai_learning_service.dart';

/// Partnership Proposal Controller
/// 
/// Orchestrates the complete partnership proposal workflow. Coordinates validation,
/// business compatibility checks, revenue split calculation, proposal creation, and
/// proposal acceptance/rejection.
/// 
/// **Responsibilities:**
/// - Validate partnership proposal
/// - Check business compatibility (via PartnershipService)
/// - Calculate revenue split (via RevenueSplitService)
/// - Create partnership proposal (via PartnershipService)
/// - Send proposal to business (when NotificationService available)
/// - Handle proposal acceptance/rejection
/// - Return unified result with errors
/// 
/// **Dependencies:**
/// - `PartnershipService` - Create partnerships and check compatibility
/// - `BusinessService` - Validate business existence
/// - `RevenueSplitService` - Calculate revenue splits
/// - `AtomicClockService` - Mandatory for timestamps (Phase 8.3+)
/// 
/// **Usage:**
/// ```dart
/// final controller = PartnershipProposalController();
/// final result = await controller.createProposal(
///   eventId: 'event_123',
///   proposerId: 'user_456',
///   businessId: 'business_789',
///   data: PartnershipProposalData(
///     revenueSplit: RevenueSplit(...),
///     sharedResponsibilities: ['Venue', 'Marketing'],
///   ),
/// );
/// 
/// if (result.isSuccess) {
///   // Proposal created successfully
/// } else {
///   // Handle errors
/// }
/// ```
class PartnershipProposalController
    implements WorkflowController<PartnershipProposalInput, PartnershipProposalResult> {
  static const String _logName = 'PartnershipProposalController';

  final PartnershipService _partnershipService;
  final BusinessService _businessService;
  // ignore: unused_field
  final AtomicClockService _atomicClock; // Reserved for future timestamp-based proposal tracking
  
  // AVRAI Core System Integration (optional, graceful degradation)
  final CrossEntityCompatibilityService? _knotCompatibilityService;
  final LocationTimingQuantumStateService? _locationTimingService;
  final QuantumEntanglementService? _quantumEntanglementService;
  final QuantumMatchingAILearningService? _aiLearningService;

  PartnershipProposalController({
    PartnershipService? partnershipService,
    BusinessService? businessService,
    AtomicClockService? atomicClock,
    CrossEntityCompatibilityService? knotCompatibilityService,
    LocationTimingQuantumStateService? locationTimingService,
    QuantumEntanglementService? quantumEntanglementService,
    QuantumMatchingAILearningService? aiLearningService,
  })  : _partnershipService =
            partnershipService ?? GetIt.instance<PartnershipService>(),
        _businessService =
            businessService ?? GetIt.instance<BusinessService>(),
        _atomicClock = atomicClock ?? GetIt.instance<AtomicClockService>(),
        _knotCompatibilityService = knotCompatibilityService ??
            (GetIt.instance.isRegistered<CrossEntityCompatibilityService>()
                ? GetIt.instance<CrossEntityCompatibilityService>()
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

  /// Create partnership proposal
  /// 
  /// Orchestrates the complete partnership proposal workflow:
  /// 1. Validate input
  /// 2. Verify business exists
  /// 3. Check partnership eligibility (via PartnershipService)
  /// 4. Calculate revenue split (if applicable)
  /// 5. Create partnership proposal (via PartnershipService)
  /// 6. Return unified result
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID for the partnership
  /// - `proposerId`: User ID proposing the partnership
  /// - `businessId`: Business ID being proposed to
  /// - `data`: Partnership proposal data (revenue split, responsibilities, etc.)
  /// 
  /// **Returns:**
  /// `PartnershipProposalResult` with success/failure and error details
  Future<PartnershipProposalResult> createProposal({
    required String eventId,
    required String proposerId,
    required String businessId,
    required PartnershipProposalData data,
  }) async {
    try {
      developer.log(
        'Creating partnership proposal: eventId=$eventId, proposerId=$proposerId, businessId=$businessId',
        name: _logName,
      );

      // Step 1: Validate input
      final input = PartnershipProposalInput(
        eventId: eventId,
        proposerId: proposerId,
        businessId: businessId,
        data: data,
      );

      final validationResult = validate(input);
      if (!validationResult.isValid) {
        return PartnershipProposalResult.failure(
          error: validationResult.allErrors.join(', '),
          errorCode: 'VALIDATION_ERROR',
        );
      }

      // Step 2: Verify business exists
      final business = await _businessService.getBusinessById(businessId);
      if (business == null) {
        return PartnershipProposalResult.failure(
          error: 'Business not found',
          errorCode: 'BUSINESS_NOT_FOUND',
        );
      }

      // Step 3: Calculate revenue split (if provided in data)
      RevenueSplit? revenueSplit = data.revenueSplit;
      if (revenueSplit == null && data.calculateRevenueSplit) {
        try {
          // Calculate default revenue split (e.g., 50/50)
          // This is a placeholder - actual calculation would depend on event details
          developer.log(
            'Revenue split calculation requested but not yet implemented',
            name: _logName,
          );
          // For now, leave revenueSplit as null - PartnershipService will handle it
        } catch (e) {
          developer.log(
            'Error calculating revenue split: $e',
            name: _logName,
            error: e,
          );
          // Don't fail the whole proposal if revenue split calculation fails
        }
      }

      // Step 4: Create partnership proposal via PartnershipService
      // Note: PartnershipService handles:
      // - Event validation
      // - Partnership eligibility checks
      // - Vibe compatibility calculation (70%+ threshold)
      final partnership = await _partnershipService.createPartnership(
        eventId: eventId,
        userId: proposerId,
        businessId: businessId,
        agreement: data.agreement,
        type: data.type ?? PartnershipType.eventBased,
        sharedResponsibilities: data.sharedResponsibilities ?? [],
        venueLocation: data.venueLocation,
        vibeCompatibilityScore: data.vibeCompatibilityScore,
      );

      developer.log(
        'Partnership proposal created: id=${partnership.id}, status=${partnership.status}',
        name: _logName,
      );

      // Step 5: AVRAI Core System Integration (optional, graceful degradation)
      
      // 5.1: Calculate knot compatibility (expert ↔ business)
      if (_knotCompatibilityService != null) {
        try {
          developer.log(
            '🎯 Calculating knot compatibility for partnership proposal',
            name: _logName,
          );
          
          // Note: Full implementation would require expert and business personality knots
          // This is a placeholder for future knot compatibility calculation
          developer.log(
            'ℹ️ Knot compatibility calculation deferred (requires expert and business knots)',
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
      
      // 5.2: Calculate quantum compatibility (expert ↔ business)
      if (_quantumEntanglementService != null) {
        try {
          developer.log(
            '🔬 Calculating quantum compatibility for partnership proposal',
            name: _logName,
          );
          
          // Note: Full implementation would create quantum states and calculate compatibility
          // This is a placeholder for future quantum compatibility calculation
          developer.log(
            'ℹ️ Quantum compatibility calculation deferred (requires quantum states)',
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
      
      // 5.3: Create 4D quantum states for compatibility calculation
      if (_locationTimingService != null && data.venueLocation != null) {
        try {
          developer.log(
            '🌐 Creating 4D quantum location state for partnership venue',
            name: _logName,
          );
          
          // Parse venue location and create quantum state
          // Note: Full implementation would parse location and create quantum state
          developer.log(
            'ℹ️ Venue location quantum state creation deferred (requires location parsing)',
            name: _logName,
          );
        } catch (e) {
          developer.log(
            '⚠️ Location quantum state creation failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - location quantum state is optional
        }
      }
      
      // 5.4: Learn from partnership outcomes via AI2AI mesh (optional, fire-and-forget)
      if (_aiLearningService != null) {
        try {
          developer.log(
            '🤖 AI2AI learning service available (learning deferred to matching)',
            name: _logName,
          );
          // Note: Actual learning happens when matches occur, not during proposal creation
          // This is a placeholder for future partnership-based learning
        } catch (e) {
          developer.log(
            '⚠️ AI2AI learning failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - AI2AI learning is optional and non-blocking
        }
      }
      
      // Step 6: Send proposal to business (when NotificationService available)
      // TODO(Phase 8.12): Integrate NotificationService when available
      // For now, notifications are handled by PartnershipService placeholder methods

      return PartnershipProposalResult.success(
        partnership: partnership,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error creating partnership proposal: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return PartnershipProposalResult.failure(
        error: 'Unexpected error: $e',
        errorCode: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Accept partnership proposal
  /// 
  /// Accepts a partnership proposal, updating approval status.
  /// 
  /// **Parameters:**
  /// - `partnershipId`: Partnership ID to accept
  /// - `acceptorId`: User ID accepting (user or business)
  /// - `isBusiness`: Whether acceptor is the business (true) or user (false)
  /// 
  /// **Returns:**
  /// `PartnershipProposalResult` with success/failure
  Future<PartnershipProposalResult> acceptProposal({
    required String partnershipId,
    required String acceptorId,
    required bool isBusiness,
  }) async {
    try {
      developer.log(
        'Accepting partnership proposal: partnershipId=$partnershipId, acceptorId=$acceptorId, isBusiness=$isBusiness',
        name: _logName,
      );

      // Get partnership
      final partnership = await _partnershipService.getPartnershipById(partnershipId);
      if (partnership == null) {
        return PartnershipProposalResult.failure(
          error: 'Partnership not found',
          errorCode: 'PARTNERSHIP_NOT_FOUND',
        );
      }

      // Verify acceptor is authorized
      final isAuthorized = isBusiness
          ? partnership.businessId == acceptorId
          : partnership.userId == acceptorId;

      if (!isAuthorized) {
        return PartnershipProposalResult.failure(
          error: 'User not authorized to accept this proposal',
          errorCode: 'PERMISSION_DENIED',
        );
      }

      // Approve partnership via PartnershipService
      final updatedPartnership = await _partnershipService.approvePartnership(
        partnershipId: partnershipId,
        approvedBy: acceptorId,
      );

      developer.log(
        'Partnership proposal accepted: id=$partnershipId',
        name: _logName,
      );

      return PartnershipProposalResult.success(
        partnership: updatedPartnership,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error accepting partnership proposal: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return PartnershipProposalResult.failure(
        error: 'Unexpected error: $e',
        errorCode: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Reject partnership proposal
  /// 
  /// Rejects a partnership proposal with optional reason.
  /// 
  /// **Parameters:**
  /// - `partnershipId`: Partnership ID to reject
  /// - `rejectorId`: User ID rejecting (user or business)
  /// - `isBusiness`: Whether rejector is the business (true) or user (false)
  /// - `reason`: Optional reason for rejection
  /// 
  /// **Returns:**
  /// `PartnershipProposalResult` with success/failure
  Future<PartnershipProposalResult> rejectProposal({
    required String partnershipId,
    required String rejectorId,
    required bool isBusiness,
    String? reason,
  }) async {
    try {
      developer.log(
        'Rejecting partnership proposal: partnershipId=$partnershipId, rejectorId=$rejectorId, reason=$reason',
        name: _logName,
      );

      // Get partnership
      final partnership = await _partnershipService.getPartnershipById(partnershipId);
      if (partnership == null) {
        return PartnershipProposalResult.failure(
          error: 'Partnership not found',
          errorCode: 'PARTNERSHIP_NOT_FOUND',
        );
      }

      // Verify rejector is authorized
      final isAuthorized = isBusiness
          ? partnership.businessId == rejectorId
          : partnership.userId == rejectorId;

      if (!isAuthorized) {
        return PartnershipProposalResult.failure(
          error: 'User not authorized to reject this proposal',
          errorCode: 'PERMISSION_DENIED',
        );
      }

      // Update partnership status to cancelled
      final updatedPartnership = await _partnershipService.updatePartnershipStatus(
        partnershipId: partnershipId,
        status: PartnershipStatus.cancelled,
      );

      developer.log(
        'Partnership proposal rejected: id=$partnershipId',
        name: _logName,
      );

      return PartnershipProposalResult.success(
        partnership: updatedPartnership,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error rejecting partnership proposal: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return PartnershipProposalResult.failure(
        error: 'Unexpected error: $e',
        errorCode: 'UNEXPECTED_ERROR',
      );
    }
  }

  @override
  Future<PartnershipProposalResult> execute(PartnershipProposalInput input) async {
    return createProposal(
      eventId: input.eventId,
      proposerId: input.proposerId,
      businessId: input.businessId,
      data: input.data,
    );
  }

  @override
  ValidationResult validate(PartnershipProposalInput input) {
    final errors = <String, String>{};
    final generalErrors = <String>[];

    // Validate eventId
    if (input.eventId.trim().isEmpty) {
      errors['eventId'] = 'Event ID is required';
    }

    // Validate proposerId
    if (input.proposerId.trim().isEmpty) {
      errors['proposerId'] = 'Proposer ID is required';
    }

    // Validate businessId
    if (input.businessId.trim().isEmpty) {
      errors['businessId'] = 'Business ID is required';
    }

    // Validate revenue split percentages if provided
    // Note: RevenueSplit model uses SplitParty list, not direct percentages
    // This validation is a placeholder - actual validation would check SplitParty percentages
    if (input.data.revenueSplit != null) {
      final split = input.data.revenueSplit!;
      final totalPercentage = split.parties.fold<double>(
        0.0,
        (sum, party) => sum + party.percentage,
      );
      if ((totalPercentage - 100.0).abs() > 0.01) {
        errors['revenueSplit'] =
            'Revenue split percentages must total 100% (currently ${totalPercentage.toStringAsFixed(1)}%)';
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
  Future<void> rollback(PartnershipProposalResult result) async {
    // Rollback partnership proposal (cancel partnership)
    if (result.success && result.partnership != null) {
      try {
        await _partnershipService.updatePartnershipStatus(
          partnershipId: result.partnership!.id,
          status: PartnershipStatus.cancelled,
        );

        developer.log(
          'Rolled back partnership proposal: partnershipId=${result.partnership!.id}',
          name: _logName,
        );
      } catch (e) {
        developer.log(
          'Error rolling back partnership proposal: $e',
          name: _logName,
          error: e,
        );
        // Don't rethrow - rollback failures should be logged but not block
      }
    }
  }
}

/// Partnership Proposal Input
/// 
/// Input data for partnership proposal
class PartnershipProposalInput {
  final String eventId;
  final String proposerId;
  final String businessId;
  final PartnershipProposalData data;

  PartnershipProposalInput({
    required this.eventId,
    required this.proposerId,
    required this.businessId,
    required this.data,
  });
}

/// Partnership Proposal Data
/// 
/// Data for creating a partnership proposal
class PartnershipProposalData {
  final RevenueSplit? revenueSplit;
  final bool calculateRevenueSplit;
  final PartnershipAgreement? agreement;
  final PartnershipType? type;
  final List<String>? sharedResponsibilities;
  final String? venueLocation;
  final double? vibeCompatibilityScore;

  PartnershipProposalData({
    this.revenueSplit,
    this.calculateRevenueSplit = false,
    this.agreement,
    this.type,
    this.sharedResponsibilities,
    this.venueLocation,
    this.vibeCompatibilityScore,
  });
}

/// Partnership Proposal Result
/// 
/// Unified result for partnership proposal operations
class PartnershipProposalResult extends ControllerResult {
  final EventPartnership? partnership;

  const PartnershipProposalResult._({
    required super.success,
    required super.error,
    required super.errorCode,
    this.partnership,
  });

  factory PartnershipProposalResult.success({
    required EventPartnership partnership,
  }) {
    return PartnershipProposalResult._(
      success: true,
      error: null,
      errorCode: null,
      partnership: partnership,
    );
  }

  factory PartnershipProposalResult.failure({
    required String error,
    required String errorCode,
  }) {
    return PartnershipProposalResult._(
      success: false,
      error: error,
      errorCode: errorCode,
      partnership: null,
    );
  }
}

