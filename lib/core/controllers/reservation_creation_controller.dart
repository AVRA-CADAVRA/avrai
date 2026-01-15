// Reservation Creation Controller
//
// Phase 15: Reservation System Implementation
// Section 15.1.2.5: Reservation Creation Controller (Skeleton First)
//
// Orchestrates the complete reservation creation workflow, coordinating
// multiple services for complex multi-step reservation creation.
//
// **Architecture Pattern:**
// ```
// UI → BLoC → ReservationCreationController → Multiple Services → Repository
// ```
//
// **Workflow:**
// 1. Validate input data
// 2. Check availability (via ReservationAvailabilityService - TODO)
// 3. Check rate limits (via ReservationRateLimitService - TODO)
// 4. Check business hours (via ReservationAvailabilityService - TODO)
// 5. Calculate compatibility (via QuantumMatchingController - ✅)
// 6. Create quantum state (via ReservationQuantumService - ✅)
// 7. Handle queue if limited seats (via ReservationTicketQueueService - TODO)
// 8. Handle waitlist if sold out (via ReservationWaitlistService - TODO)
// 9. Create reservation (via ReservationService - ✅)
// 10. Send notifications (via ReservationNotificationService - TODO)
// 11. Return unified result

import 'dart:developer' as developer;

import 'package:avrai/core/controllers/base/workflow_controller.dart';
import 'package:avrai/core/controllers/base/controller_result.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/controllers/quantum_matching_controller.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/services/reservation_quantum_service.dart';
import 'package:avrai/core/services/reservation_availability_service.dart';
import 'package:avrai/core/services/reservation_rate_limit_service.dart';
import 'package:avrai/core/services/reservation_ticket_queue_service.dart';
import 'package:avrai/core/services/reservation_waitlist_service.dart';
import 'package:avrai/core/services/reservation_notification_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:get_it/get_it.dart';

/// Input model for reservation creation
class ReservationCreationInput {
  /// User ID (will be converted to agentId internally)
  final String userId;

  /// Reservation type (spot, business, event)
  final ReservationType type;

  /// Target ID (spot ID, business ID, or event ID)
  final String targetId;

  /// Reservation time
  final DateTime reservationTime;

  /// Party size (number of people)
  final int partySize;

  /// Ticket count (can be different from partySize if business has limit)
  final int? ticketCount;

  /// Special requests
  final String? specialRequests;

  /// Ticket price (if paid reservation)
  final double? ticketPrice;

  /// Deposit amount (if deposit required)
  final double? depositAmount;

  /// Seat ID (if seating chart used)
  final String? seatId;

  /// Optional user data (shared with business/host if user consents)
  final Map<String, dynamic>? userData;

  const ReservationCreationInput({
    required this.userId,
    required this.type,
    required this.targetId,
    required this.reservationTime,
    required this.partySize,
    this.ticketCount,
    this.specialRequests,
    this.ticketPrice,
    this.depositAmount,
    this.seatId,
    this.userData,
  });
}

/// Result class for reservation creation controller
class ReservationCreationResult extends ControllerResult {
  /// Created reservation (null if error)
  final Reservation? reservation;

  /// Compatibility score (from quantum matching)
  final double? compatibilityScore;

  /// Queue position (if limited seats, null if not queued)
  final int? queuePosition;

  /// Waitlist position (if sold out, null if not waitlisted)
  final int? waitlistPosition;

  const ReservationCreationResult({
    required super.success,
    super.error,
    super.errorCode,
    super.metadata,
    this.reservation,
    this.compatibilityScore,
    this.queuePosition,
    this.waitlistPosition,
  });

  /// Create successful result
  factory ReservationCreationResult.success({
    required Reservation reservation,
    double? compatibilityScore,
    int? queuePosition,
    int? waitlistPosition,
    Map<String, dynamic>? metadata,
  }) {
    return ReservationCreationResult(
      success: true,
      reservation: reservation,
      compatibilityScore: compatibilityScore,
      queuePosition: queuePosition,
      waitlistPosition: waitlistPosition,
      metadata: metadata,
    );
  }

  /// Create failure result
  factory ReservationCreationResult.failure({
    required String error,
    String? errorCode,
    Map<String, dynamic>? metadata,
  }) {
    return ReservationCreationResult(
      success: false,
      error: error,
      errorCode: errorCode,
      metadata: metadata,
    );
  }

  @override
  List<Object?> get props => [
        success,
        error,
        errorCode,
        metadata,
        reservation,
        compatibilityScore,
        queuePosition,
        waitlistPosition,
      ];
}

/// Reservation Creation Controller
///
/// Orchestrates the complete reservation creation workflow:
/// 1. Validates input data
/// 2. Checks availability (TODO: ReservationAvailabilityService)
/// 3. Checks rate limits (TODO: ReservationRateLimitService)
/// 4. Checks business hours (TODO: ReservationAvailabilityService)
/// 5. Calculates compatibility (✅ QuantumMatchingController)
/// 6. Creates quantum state (✅ ReservationQuantumService)
/// 7. Handles queue if limited seats (TODO: ReservationTicketQueueService)
/// 8. Handles waitlist if sold out (TODO: ReservationWaitlistService)
/// 9. Creates reservation (✅ ReservationService)
/// 10. Sends notifications (TODO: ReservationNotificationService)
/// 11. Returns unified result
///
/// **Architecture Pattern:**
/// ```
/// UI → BLoC → ReservationCreationController → Multiple Services → Repository
/// ```
class ReservationCreationController
    implements
        WorkflowController<ReservationCreationInput,
            ReservationCreationResult> {
  static const String _logName = 'ReservationCreationController';

  // Existing services (✅ Available)
  final ReservationService _reservationService;
  // ignore: unused_field - Reserved for future quantum state creation integration
  final ReservationQuantumService _quantumService;
  // ignore: unused_field - Reserved for future compatibility calculation integration
  final QuantumMatchingController _quantumController;
  // ignore: unused_field - Reserved for future agentId conversion if needed
  final AgentIdService _agentIdService;
  // ignore: unused_field - Reserved for future atomic timestamp integration
  final AtomicClockService _atomicClock;

  // ✅ Available services
  final ReservationAvailabilityService? _availabilityService; // ✅ Phase 15.1.4
  final ReservationRateLimitService? _rateLimitService; // ✅ Phase 15.1.8
  final ReservationTicketQueueService? _ticketQueueService; // ✅ Phase 15.1.3
  final ReservationWaitlistService? _waitlistService; // ✅ Phase 15.1.9
  final ReservationNotificationService? _notificationService; // ✅ Phase 15.1.7

  ReservationCreationController({
    ReservationService? reservationService,
    ReservationQuantumService? quantumService,
    QuantumMatchingController? quantumController,
    AgentIdService? agentIdService,
    AtomicClockService? atomicClock,
    ReservationAvailabilityService? availabilityService,
    ReservationRateLimitService? rateLimitService,
    ReservationTicketQueueService? ticketQueueService,
  })  : _reservationService =
            reservationService ?? GetIt.instance<ReservationService>(),
        _quantumService =
            quantumService ?? GetIt.instance<ReservationQuantumService>(),
        _quantumController =
            quantumController ?? GetIt.instance<QuantumMatchingController>(),
        _agentIdService = agentIdService ?? GetIt.instance<AgentIdService>(),
        _atomicClock = atomicClock ?? GetIt.instance<AtomicClockService>(),
        _availabilityService = availabilityService ??
            (GetIt.instance.isRegistered<ReservationAvailabilityService>()
                ? GetIt.instance<ReservationAvailabilityService>()
                : null),
        _rateLimitService = rateLimitService ??
            (GetIt.instance.isRegistered<ReservationRateLimitService>()
                ? GetIt.instance<ReservationRateLimitService>()
                : null),
        _ticketQueueService = ticketQueueService ??
            (GetIt.instance.isRegistered<ReservationTicketQueueService>()
                ? GetIt.instance<ReservationTicketQueueService>()
                : null),
        _waitlistService =
            GetIt.instance.isRegistered<ReservationWaitlistService>()
                ? GetIt.instance<ReservationWaitlistService>()
                : null,
        _notificationService =
            GetIt.instance.isRegistered<ReservationNotificationService>()
                ? GetIt.instance<ReservationNotificationService>()
                : null;

  @override
  Future<ReservationCreationResult> execute(
      ReservationCreationInput input) async {
    developer.log(
      '🎯 Starting reservation creation workflow: type=${input.type}, targetId=${input.targetId}',
      name: _logName,
    );

    try {
      // STEP 1: Validate input data
      final validation = validate(input);
      if (!validation.isValid) {
        developer.log(
          '❌ Validation failed: ${validation.allErrors.join(", ")}',
          name: _logName,
        );
        return ReservationCreationResult.failure(
          error: validation.firstError ?? 'Validation failed',
          errorCode: 'VALIDATION_ERROR',
          metadata: {'validationErrors': validation.allErrors},
        );
      }

      // STEP 2: Check availability (✅ ReservationAvailabilityService)
      if (_availabilityService != null) {
        try {
          final availability = await _availabilityService!.checkAvailability(
            type: input.type,
            targetId: input.targetId,
            reservationTime: input.reservationTime,
            partySize: input.partySize,
            ticketCount: input.ticketCount,
          );
          if (!availability.isAvailable) {
            return ReservationCreationResult.failure(
              error: availability.reason ?? 'Not available',
              errorCode: 'NOT_AVAILABLE',
              metadata: {
                'waitlistAvailable': availability.waitlistAvailable,
              },
            );
          }
        } catch (e) {
          developer.log(
            '⚠️ Availability check failed (non-fatal): $e',
            name: _logName,
          );
          // Continue - availability check failure is non-fatal
        }
      }

      // STEP 3: Check rate limits (✅ ReservationRateLimitService)
      if (_rateLimitService != null) {
        try {
          final rateLimitCheck = await _rateLimitService!.checkRateLimit(
            userId: input.userId,
            type: input.type,
            targetId: input.targetId,
            reservationTime: input.reservationTime,
          );
          if (!rateLimitCheck.allowed) {
            return ReservationCreationResult.failure(
              error: rateLimitCheck.reason ?? 'Rate limit exceeded',
              errorCode: 'RATE_LIMIT_EXCEEDED',
              metadata: {
                'retryAfter': rateLimitCheck.retryAfter,
                'resetAt': rateLimitCheck.resetAt?.toIso8601String(),
              },
            );
          }
        } catch (e) {
          developer.log(
            '⚠️ Rate limit check failed (non-fatal): $e',
            name: _logName,
          );
          // Continue - rate limit check failure is non-fatal
        }
      }

      // STEP 4: Check business hours (✅ ReservationAvailabilityService)
      if (_availabilityService != null && input.type != ReservationType.event) {
        try {
          final isWithinHours =
              await _availabilityService!.isWithinBusinessHours(
            businessId: input.targetId,
            reservationTime: input.reservationTime,
          );
          if (!isWithinHours) {
            return ReservationCreationResult.failure(
              error: 'Reservation time is outside business hours',
              errorCode: 'OUTSIDE_BUSINESS_HOURS',
            );
          }

          // Check if business is closed (holidays/closures)
          final isClosed = await _availabilityService!.isBusinessClosed(
            businessId: input.targetId,
            reservationTime: input.reservationTime,
          );
          if (isClosed) {
            return ReservationCreationResult.failure(
              error: 'Business is closed at this time',
              errorCode: 'BUSINESS_CLOSED',
            );
          }
        } catch (e) {
          developer.log(
            '⚠️ Business hours check failed (non-fatal): $e',
            name: _logName,
          );
          // Continue - business hours check failure is non-fatal
        }
      }

      // STEP 5: Calculate compatibility (✅ QuantumMatchingController)
      double? compatibilityScore;
      try {
        // TODO(Phase 15.1.2): Integrate QuantumMatchingController for compatibility
        // For now, skip compatibility calculation (will be added when controller is integrated)
        developer.log(
          '⏳ Compatibility calculation skipped (will be integrated)',
          name: _logName,
        );
        // final matchingInput = MatchingInput(...);
        // final matchingResult = await _quantumController.execute(matchingInput);
        // compatibilityScore = matchingResult.matchingResult?.compatibilityScore;
      } catch (e) {
        developer.log(
          '⚠️ Compatibility calculation failed (non-fatal): $e',
          name: _logName,
        );
        // Continue - compatibility is informative, not blocking
      }

      // STEP 6: Create quantum state (✅ ReservationQuantumService)
      // Note: Quantum state is created inside ReservationService.createReservation()
      // This step is handled automatically by the service

      // STEP 7: Handle queue if limited seats (✅ ReservationTicketQueueService)
      int? queuePosition;
      if (_ticketQueueService != null) {
        try {
          // TODO(Phase 15.1.3): Determine if event has limited seats
          // For now, queue handling is optional (only for events with capacity limits)
          // final queueEntry = await _ticketQueueService!.queueTicketRequest(
          //   userId: input.userId,
          //   type: input.type,
          //   targetId: input.targetId,
          //   reservationTime: input.reservationTime,
          //   ticketCount: input.ticketCount ?? input.partySize,
          // );
          // queueEntryId = queueEntry.id;
          // queuePosition = await _ticketQueueService!.getQueuePosition(
          //   userId: input.userId,
          //   queueEntryId: queueEntry.id,
          // );
        } catch (e) {
          developer.log(
            '⚠️ Queue handling failed (non-fatal): $e',
            name: _logName,
          );
          // Continue - queue handling failure is non-fatal
        }
      }

      // STEP 8: Handle waitlist if sold out (✅ ReservationWaitlistService)
      int? waitlistPosition;
      if (_waitlistService != null) {
        try {
          // TODO(Phase 15.1.9): Determine if event is sold out
          // For now, waitlist handling is optional (only for sold-out events)
          // final waitlistEntry = await _waitlistService!.addToWaitlist(
          //   userId: input.userId,
          //   type: input.type,
          //   targetId: input.targetId,
          //   reservationTime: input.reservationTime,
          //   ticketCount: input.ticketCount ?? input.partySize,
          // );
          // waitlistPosition = waitlistEntry.position;
        } catch (e) {
          developer.log(
            '⚠️ Waitlist handling failed (non-fatal): $e',
            name: _logName,
          );
          // Continue - waitlist handling failure is non-fatal
        }
      }

      // STEP 9: Create reservation (✅ ReservationService)
      Reservation reservation;
      try {
        reservation = await _reservationService.createReservation(
          userId: input.userId,
          type: input.type,
          targetId: input.targetId,
          reservationTime: input.reservationTime,
          partySize: input.partySize,
          ticketCount: input.ticketCount,
          specialRequests: input.specialRequests,
          ticketPrice: input.ticketPrice,
          depositAmount: input.depositAmount,
          seatId: input.seatId,
          userData: input.userData,
        );
        developer.log(
          '✅ Reservation created: ${reservation.id}',
          name: _logName,
        );
      } catch (e, stackTrace) {
        developer.log(
          '❌ Reservation creation failed: $e',
          name: _logName,
          error: e,
          stackTrace: stackTrace,
        );
        return ReservationCreationResult.failure(
          error: e.toString().replaceFirst('Exception: ', ''),
          errorCode: 'CREATION_ERROR',
        );
      }

      // STEP 10: Send notifications (✅ ReservationNotificationService)
      if (_notificationService != null) {
        try {
          await _notificationService!.sendConfirmation(reservation);
          await _notificationService!.scheduleReminders(reservation);
        } catch (e) {
          developer.log(
            '⚠️ Notification sending failed (non-fatal): $e',
            name: _logName,
          );
          // Continue - notification failure is non-fatal
        }
      }

      // STEP 11: Return success result
      return ReservationCreationResult.success(
        reservation: reservation,
        compatibilityScore: compatibilityScore,
        queuePosition: queuePosition,
        waitlistPosition: waitlistPosition,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Unexpected error in reservation creation workflow: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return ReservationCreationResult.failure(
        error: 'Unexpected error: $e',
        errorCode: 'UNEXPECTED_ERROR',
      );
    }
  }

  @override
  ValidationResult validate(ReservationCreationInput input) {
    final fieldErrors = <String, String>{};
    final generalErrors = <String>[];

    // User ID validation
    if (input.userId.trim().isEmpty) {
      fieldErrors['userId'] = 'User ID is required';
    }

    // Target ID validation
    if (input.targetId.trim().isEmpty) {
      fieldErrors['targetId'] = 'Target ID is required';
    }

    // Reservation time validation
    if (input.reservationTime.isBefore(DateTime.now())) {
      fieldErrors['reservationTime'] = 'Reservation time must be in the future';
    }

    // Party size validation
    if (input.partySize < 1) {
      fieldErrors['partySize'] = 'Party size must be at least 1';
    } else if (input.partySize > 100) {
      fieldErrors['partySize'] = 'Party size cannot exceed 100';
    }

    // Ticket count validation
    if (input.ticketCount != null) {
      if (input.ticketCount! < 1) {
        fieldErrors['ticketCount'] = 'Ticket count must be at least 1';
      } else if (input.ticketCount! > input.partySize) {
        fieldErrors['ticketCount'] = 'Ticket count cannot exceed party size';
      }
    }

    // Ticket price validation
    if (input.ticketPrice != null && input.ticketPrice! < 0) {
      fieldErrors['ticketPrice'] = 'Ticket price cannot be negative';
    }

    // Deposit validation
    if (input.depositAmount != null) {
      if (input.depositAmount! < 0) {
        fieldErrors['depositAmount'] = 'Deposit cannot be negative';
      }
      if (input.ticketPrice != null &&
          input.depositAmount! > input.ticketPrice!) {
        fieldErrors['depositAmount'] = 'Deposit cannot exceed ticket price';
      }
    }

    if (fieldErrors.isNotEmpty || generalErrors.isNotEmpty) {
      return ValidationResult.invalid(
        fieldErrors: fieldErrors,
        generalErrors: generalErrors,
      );
    }

    return ValidationResult.valid();
  }

  @override
  Future<void> rollback(ReservationCreationResult result) async {
    // Rollback: Cancel reservation if it was created
    if (result.success && result.reservation != null) {
      try {
        developer.log(
          '🔄 Rolling back reservation: ${result.reservation!.id}',
          name: _logName,
        );
        await _reservationService.cancelReservation(
          reservationId: result.reservation!.id,
          reason: 'Workflow rollback',
          applyPolicy: false, // Don't apply policy on rollback
        );
        developer.log(
          '✅ Reservation rollback complete',
          name: _logName,
        );
      } catch (e) {
        developer.log(
          '⚠️ Reservation rollback failed: $e',
          name: _logName,
          error: e,
        );
        // Continue - rollback failure is logged but doesn't throw
      }
    }
  }
}
