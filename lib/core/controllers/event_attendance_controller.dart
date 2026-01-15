import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';

import 'package:avrai/core/controllers/base/workflow_controller.dart';
import 'package:avrai/core/controllers/base/controller_result.dart';
import 'package:avrai/core/controllers/payment_processing_controller.dart';
import 'package:avrai/core/models/expertise_event.dart';
import 'package:avrai/core/models/unified_user.dart';
import 'package:avrai/core/models/payment.dart';
import 'package:avrai/core/services/expertise_event_service.dart';
import 'package:avrai/core/services/preferences_profile_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/unified_location_data.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_quantum/services/quantum/location_timing_quantum_state_service.dart';
import 'package:avrai_quantum/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai/core/services/quantum/quantum_matching_ai_learning_service.dart';

/// Event Attendance Controller
///
/// Orchestrates the complete event attendance workflow. Coordinates availability
/// checks, payment processing (for paid events), registration, confirmation, and
/// preference updates.
///
/// **Responsibilities:**
/// - Check event availability
/// - Process payment (if paid) via PaymentProcessingController
/// - Register attendee (if free event or after payment)
/// - Send confirmation (when NotificationService available)
/// - Update user preferences based on event attendance
/// - Return unified result with errors
///
/// **Dependencies:**
/// - `ExpertiseEventService` - Register for events
/// - `PaymentProcessingController` - Process payments for paid events
/// - `PreferencesProfileService` - Update preferences
/// - `AgentIdService` - Get agentId for privacy-protected operations
///
/// **Usage:**
/// ```dart
/// final controller = EventAttendanceController();
/// final result = await controller.registerForEvent(
///   event: event,
///   attendee: user,
///   quantity: 1,
/// );
///
/// if (result.isSuccess) {
///   // Registration successful
/// } else {
///   // Handle errors
/// }
/// ```
class EventAttendanceController
    implements WorkflowController<AttendanceData, AttendanceResult> {
  static const String _logName = 'EventAttendanceController';

  final ExpertiseEventService _eventService;
  final PaymentProcessingController? _paymentController;
  final PreferencesProfileService? _preferencesService;
  final AgentIdService? _agentIdService;
  final AtomicClockService _atomicClock;

  // AVRAI Core System Integration (optional, graceful degradation)
  final PersonalityKnotService? _personalityKnotService;
  final KnotFabricService? _knotFabricService;
  final KnotWorldsheetService? _knotWorldsheetService;
  final KnotEvolutionStringService? _knotStringService;
  final LocationTimingQuantumStateService? _locationTimingService;
  final QuantumEntanglementService? _quantumEntanglementService;
  final QuantumMatchingAILearningService? _aiLearningService;

  EventAttendanceController({
    ExpertiseEventService? eventService,
    PaymentProcessingController? paymentController,
    PreferencesProfileService? preferencesService,
    AgentIdService? agentIdService,
    AtomicClockService? atomicClock,
    PersonalityKnotService? personalityKnotService,
    KnotFabricService? knotFabricService,
    KnotWorldsheetService? knotWorldsheetService,
    KnotEvolutionStringService? knotStringService,
    LocationTimingQuantumStateService? locationTimingService,
    QuantumEntanglementService? quantumEntanglementService,
    QuantumMatchingAILearningService? aiLearningService,
  })  : _eventService = eventService ?? GetIt.instance<ExpertiseEventService>(),
        _paymentController =
            paymentController ?? GetIt.instance<PaymentProcessingController>(),
        _preferencesService =
            preferencesService ?? GetIt.instance<PreferencesProfileService>(),
        _agentIdService = agentIdService ?? GetIt.instance<AgentIdService>(),
        _atomicClock = atomicClock ?? GetIt.instance<AtomicClockService>(),
        _personalityKnotService = personalityKnotService ??
            (GetIt.instance.isRegistered<PersonalityKnotService>()
                ? GetIt.instance<PersonalityKnotService>()
                : null),
        _knotFabricService = knotFabricService ??
            (GetIt.instance.isRegistered<KnotFabricService>()
                ? GetIt.instance<KnotFabricService>()
                : null),
        _knotWorldsheetService = knotWorldsheetService ??
            (GetIt.instance.isRegistered<KnotWorldsheetService>()
                ? GetIt.instance<KnotWorldsheetService>()
                : null),
        _knotStringService = knotStringService ??
            (GetIt.instance.isRegistered<KnotEvolutionStringService>()
                ? GetIt.instance<KnotEvolutionStringService>()
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

  /// Register for an event
  ///
  /// Orchestrates the complete attendance workflow:
  /// 1. Validate input
  /// 2. Check event availability
  /// 3. Process payment (if paid) via PaymentProcessingController
  /// 4. Register attendee
  /// 5. Update preferences
  /// 6. Send confirmation (when NotificationService available)
  /// 7. Return unified result
  ///
  /// **Parameters:**
  /// - `event`: Event to register for
  /// - `attendee`: User registering
  /// - `quantity`: Number of tickets (default: 1)
  ///
  /// **Returns:**
  /// `AttendanceResult` with success/failure and error details
  Future<AttendanceResult> registerForEvent({
    required ExpertiseEvent event,
    required UnifiedUser attendee,
    int quantity = 1,
  }) async {
    try {
      developer.log(
        'Starting event registration: event=${event.id}, user=${attendee.id}, quantity=$quantity',
        name: _logName,
      );

      // Step 1: Validate input
      final validationResult = validate(AttendanceData(
        event: event,
        attendee: attendee,
        quantity: quantity,
      ));
      if (!validationResult.isValid) {
        return AttendanceResult.failure(
          error: validationResult.allErrors.join(', '),
          errorCode: 'VALIDATION_ERROR',
        );
      }

      // Step 2: Check event availability
      if (event.status != EventStatus.upcoming) {
        return AttendanceResult.failure(
          error: 'Event is not available for registration',
          errorCode: 'EVENT_NOT_AVAILABLE',
        );
      }

      if (DateTime.now().isAfter(event.startTime)) {
        return AttendanceResult.failure(
          error: 'Event has already started',
          errorCode: 'EVENT_STARTED',
        );
      }

      // Check capacity
      final availableSpots = event.maxAttendees - event.attendeeCount;
      if (quantity > availableSpots) {
        return AttendanceResult.failure(
          error:
              'Insufficient capacity. Only $availableSpots tickets available',
          errorCode: 'INSUFFICIENT_CAPACITY',
        );
      }

      // Check if user can attend (expertise/geographic scope)
      if (!event.canUserAttend(attendee.id)) {
        if (event.attendeeIds.contains(attendee.id)) {
          return AttendanceResult.failure(
            error: 'User is already registered for this event',
            errorCode: 'ALREADY_REGISTERED',
          );
        } else {
          return AttendanceResult.failure(
            error:
                'User cannot attend this event (expertise or geographic scope restriction)',
            errorCode: 'ATTENDANCE_RESTRICTED',
          );
        }
      }

      // Step 3: Process payment (if paid event)
      Payment? payment;
      ExpertiseEvent? updatedEvent;
      if (event.isPaid && event.price != null && event.price! > 0) {
        // Use PaymentProcessingController for paid events
        if (_paymentController == null) {
          return AttendanceResult.failure(
            error: 'Payment processing not available',
            errorCode: 'PAYMENT_NOT_AVAILABLE',
          );
        }

        final paymentResult = await _paymentController!.processEventPayment(
          event: event,
          buyer: attendee,
          quantity: quantity,
        );

        if (!paymentResult.isSuccess) {
          return AttendanceResult.failure(
            error: paymentResult.error ?? 'Payment processing failed',
            errorCode: paymentResult.errorCode ?? 'PAYMENT_FAILED',
            validationErrors: paymentResult.validationErrors,
          );
        }

        payment = paymentResult.payment;
        // PaymentProcessingController already registers the user via PaymentEventService
        // Reload event to get updated attendee count
        try {
          updatedEvent = await _eventService.getEventById(event.id);
          updatedEvent ??= event.copyWith(
            attendeeIds: [...event.attendeeIds, attendee.id],
            attendeeCount: event.attendeeCount + quantity,
          );
        } catch (e) {
          developer.log('Error reloading event after payment: $e',
              name: _logName);
          // Fallback: Create expected updated event
          updatedEvent = event.copyWith(
            attendeeIds: [...event.attendeeIds, attendee.id],
            attendeeCount: event.attendeeCount + quantity,
          );
        }
      } else {
        // Step 4: Register for free event
        for (int i = 0; i < quantity; i++) {
          await _eventService.registerForEvent(event, attendee);
        }

        // Reload event to get updated attendee count
        try {
          updatedEvent = await _eventService.getEventById(event.id);
        } catch (e) {
          developer.log('Error reloading event after registration: $e',
              name: _logName);
          // Create updated event manually as fallback
          updatedEvent = event.copyWith(
            attendeeIds: [...event.attendeeIds, attendee.id],
            attendeeCount: event.attendeeCount + quantity,
          );
        }
      }

      if (updatedEvent == null) {
        return AttendanceResult.failure(
          error: 'Failed to reload event after registration',
          errorCode: 'EVENT_RELOAD_FAILED',
        );
      }

      // Step 5: Update user preferences (if service available)
      if (_preferencesService != null && _agentIdService != null) {
        try {
          // Get agentId for privacy-protected preferences access
          final agentId = await _agentIdService!.getUserAgentId(attendee.id);
          final preferences =
              await _preferencesService!.getPreferencesProfile(agentId);
          if (preferences != null) {
            // Record event attendance in preferences
            // This helps the AI learn user interests
            // TODO(Phase 8.12): Implement preference learning from event attendance
            // For now, preferences are updated implicitly through recommendation system
            developer.log(
              'Preferences profile found for agent: ${agentId.substring(0, 10)}...',
              name: _logName,
            );
          }
        } catch (e) {
          developer.log(
            'Error updating preferences: $e',
            name: _logName,
            error: e,
          );
          // Don't fail registration if preference update fails
        }
      }

      // Step 6: AVRAI Core System Integration (optional, graceful degradation)

      // 6.1: Calculate quantum compatibility (user ↔ event)
      if (_quantumEntanglementService != null &&
          _locationTimingService != null) {
        try {
          developer.log(
            '🔬 Calculating quantum compatibility for attendance',
            name: _logName,
          );

          // Create quantum states for user and event
          // Note: Full quantum state creation would require personality profiles
          // This is a placeholder for future quantum compatibility calculation
          // The actual calculation would use QuantumMatchingController
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

      // 6.2: Create 4D quantum location state for attendance
      if (_locationTimingService != null &&
          updatedEvent.latitude != null &&
          updatedEvent.longitude != null) {
        try {
          // Use atomic clock for timestamp consistency
          final timestamp = await _atomicClock.getAtomicTimestamp();

          final locationData = UnifiedLocationData(
            latitude: updatedEvent.latitude!,
            longitude: updatedEvent.longitude!,
            city: updatedEvent.cityCode,
            address: updatedEvent.location,
          );

          final locationQuantumState =
              await _locationTimingService!.createLocationQuantumState(
            location: locationData,
            locationType: 0.7, // Default
            accessibilityScore: null,
            vibeLocationMatch: null,
          );

          // Create timing quantum state from event start time
          final timingQuantumState = await _locationTimingService!
              .createTimingQuantumStateFromDateTime(
            preferredTime: updatedEvent.startTime,
            frequencyPreference: 0.5,
            durationPreference: 0.5,
            timingVibeMatch: null,
          );

          developer.log(
            '✅ 4D quantum states created for attendance (timestamp: ${timestamp.serverTime})',
            name: _logName,
          );

          // ignore: unused_local_variable
          final _ = [locationQuantumState, timingQuantumState];
        } catch (e) {
          developer.log(
            '⚠️ 4D quantum state creation failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - quantum state creation is optional
        }
      }

      // 6.3: Create/update fabric for group attendance (if quantity > 1)
      if (_knotFabricService != null &&
          _personalityKnotService != null &&
          quantity > 1) {
        try {
          developer.log(
            '🧵 Creating fabric for group attendance (quantity: $quantity)',
            name: _logName,
          );

          // Get attendee knots (if available)
          // For now, fabric creation is deferred until all attendees have knots
          // This is a placeholder for future fabric creation on group attendance
          // Use _personalityKnotService to verify it's available
          final _ = _personalityKnotService;
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

      // 6.4: Create/update worldsheet for group tracking (if group attendance)
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

      // 6.5: Predict string evolution for recurring attendance (if applicable)
      if (_knotStringService != null) {
        try {
          // Check if this is recurring attendance (would be tracked separately)
          // For now, string evolution is deferred to future recurring event support
          developer.log(
            'ℹ️ String evolution prediction deferred (recurring attendance not yet supported)',
            name: _logName,
          );
        } catch (e) {
          developer.log(
            '⚠️ String evolution prediction failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - string evolution is optional
        }
      }

      // 6.6: Learn from successful attendance via AI2AI mesh (optional, fire-and-forget)
      if (_aiLearningService != null) {
        try {
          // Create MatchingResult for learning
          // Note: Full MatchingResult creation would require quantum states
          // This is a placeholder for future AI2AI learning from attendance
          developer.log(
            '🤖 AI2AI learning service available (learning deferred to matching)',
            name: _logName,
          );
          // Note: Actual learning happens when matches occur, not during attendance
          // This is a placeholder for future attendance-based learning
        } catch (e) {
          developer.log(
            '⚠️ AI2AI learning failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - AI2AI learning is optional and non-blocking
        }
      }

      // Step 7: Send confirmation (when NotificationService available)
      // TODO(Phase 8.12): Implement confirmation notification
      // For now, confirmation is handled by UI (success page/message)

      developer.log(
        'Event registration completed successfully: event=${event.id}, user=${attendee.id}',
        name: _logName,
      );

      return AttendanceResult.success(
        event: updatedEvent,
        payment: payment,
        quantity: quantity,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error registering for event: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return AttendanceResult.failure(
        error: 'Unexpected error: $e',
        errorCode: 'UNEXPECTED_ERROR',
      );
    }
  }

  @override
  Future<AttendanceResult> execute(AttendanceData input) async {
    return registerForEvent(
      event: input.event,
      attendee: input.attendee,
      quantity: input.quantity,
    );
  }

  @override
  ValidationResult validate(AttendanceData input) {
    final errors = <String, String>{};
    final generalErrors = <String>[];

    // Validate event
    if (input.event.id.isEmpty) {
      errors['event'] = 'Event ID is required';
    }

    // Validate attendee
    if (input.attendee.id.isEmpty) {
      errors['attendee'] = 'Attendee ID is required';
    }

    // Validate quantity
    if (input.quantity <= 0) {
      errors['quantity'] = 'Quantity must be greater than 0';
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
  Future<void> rollback(AttendanceResult result) async {
    // Rollback attendance registration
    // This would unregister the user from the event
    // For now, rollback is not implemented as registration is generally
    // considered final (users should use cancellation flow instead)
    // If needed in the future, can implement unregistration here
  }
}

/// Attendance Data
///
/// Input data for event attendance
class AttendanceData {
  final ExpertiseEvent event;
  final UnifiedUser attendee;
  final int quantity;

  AttendanceData({
    required this.event,
    required this.attendee,
    this.quantity = 1,
  });
}

/// Attendance Result
///
/// Unified result for event attendance operations
class AttendanceResult extends ControllerResult {
  final ExpertiseEvent? event;
  final Payment? payment;
  final int? quantity;
  final Map<String, String>? validationErrors;

  const AttendanceResult._({
    required super.success,
    required super.error,
    required super.errorCode,
    this.event,
    this.payment,
    this.quantity,
    this.validationErrors,
  });

  factory AttendanceResult.success({
    required ExpertiseEvent event,
    Payment? payment,
    int? quantity,
  }) {
    return AttendanceResult._(
      success: true,
      error: null,
      errorCode: null,
      event: event,
      payment: payment,
      quantity: quantity,
    );
  }

  factory AttendanceResult.failure({
    required String error,
    required String errorCode,
    Map<String, String>? validationErrors,
  }) {
    return AttendanceResult._(
      success: false,
      error: error,
      errorCode: errorCode,
      event: null,
      payment: null,
      quantity: null,
      validationErrors: validationErrors,
    );
  }
}
