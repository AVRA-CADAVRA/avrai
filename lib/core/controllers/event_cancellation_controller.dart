import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';

import 'package:avrai/core/controllers/base/workflow_controller.dart';
import 'package:avrai/core/controllers/base/controller_result.dart';
import 'package:avrai/core/models/cancellation.dart';
import 'package:avrai/core/models/expertise_event.dart';
import 'package:avrai/core/models/refund_status.dart';
import 'package:avrai/core/services/cancellation_service.dart';
import 'package:avrai/core/services/expertise_event_service.dart';
import 'package:avrai/core/services/payment_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai/core/services/quantum/quantum_matching_ai_learning_service.dart';

/// Event Cancellation Controller
/// 
/// Orchestrates the complete event cancellation workflow. Coordinates validation,
/// cancellation processing, refund handling, event status updates, and notifications.
/// 
/// **Responsibilities:**
/// - Validate cancellation reason
/// - Calculate refund amount (if applicable)
/// - Check cancellation policy
/// - Process cancellation via CancellationService
/// - Process refunds (handled by CancellationService)
/// - Update event status
/// - Notify attendees/host (when NotificationService available)
/// - Return unified result with errors
/// 
/// **Dependencies:**
/// - `CancellationService` - Process cancellations and refunds
/// - `ExpertiseEventService` - Update event status and get event details
/// - `AtomicClockService` - Mandatory for timestamps (Phase 8.3+)
/// 
/// **Usage:**
/// ```dart
/// final controller = EventCancellationController();
/// final result = await controller.cancelEvent(
///   eventId: 'event_123',
///   userId: 'user_456',
///   reason: 'Unable to attend',
///   isHost: false,
/// );
/// 
/// if (result.isSuccess) {
///   // Cancellation processed successfully
/// } else {
///   // Handle errors
/// }
/// ```
class EventCancellationController
    implements WorkflowController<CancellationInput, CancellationResult> {
  static const String _logName = 'EventCancellationController';

  final CancellationService _cancellationService;
  final ExpertiseEventService _eventService;
  final PaymentService _paymentService;
  
  // AVRAI Core System Integration (optional, graceful degradation)
  final KnotFabricService? _knotFabricService;
  final KnotWorldsheetService? _knotWorldsheetService;
  final QuantumMatchingAILearningService? _aiLearningService;

  EventCancellationController({
    CancellationService? cancellationService,
    ExpertiseEventService? eventService,
    PaymentService? paymentService,
    KnotFabricService? knotFabricService,
    KnotWorldsheetService? knotWorldsheetService,
    QuantumMatchingAILearningService? aiLearningService,
  })  : _cancellationService =
            cancellationService ?? GetIt.instance<CancellationService>(),
        _eventService =
            eventService ?? GetIt.instance<ExpertiseEventService>(),
        _paymentService =
            paymentService ?? GetIt.instance<PaymentService>(),
        _knotFabricService = knotFabricService ??
            (GetIt.instance.isRegistered<KnotFabricService>()
                ? GetIt.instance<KnotFabricService>()
                : null),
        _knotWorldsheetService = knotWorldsheetService ??
            (GetIt.instance.isRegistered<KnotWorldsheetService>()
                ? GetIt.instance<KnotWorldsheetService>()
                : null),
        _aiLearningService = aiLearningService ??
            (GetIt.instance.isRegistered<QuantumMatchingAILearningService>()
                ? GetIt.instance<QuantumMatchingAILearningService>()
                : null);

  /// Cancel event or ticket
  /// 
  /// Orchestrates the complete cancellation workflow:
  /// 1. Validate input
  /// 2. Get event details
  /// 3. Verify user permissions (host vs attendee)
  /// 4. Process cancellation via CancellationService
  /// 5. Update event status (if full event cancellation)
  /// 6. Return unified result
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID to cancel
  /// - `userId`: User ID cancelling (host or attendee)
  /// - `reason`: Reason for cancellation
  /// - `isHost`: Whether user is the host (true) or attendee (false)
  /// 
  /// **Returns:**
  /// `CancellationResult` with success/failure and error details
  Future<CancellationResult> cancelEvent({
    required String eventId,
    required String userId,
    required String reason,
    required bool isHost,
  }) async {
    try {
      developer.log(
        'Starting cancellation: eventId=$eventId, userId=$userId, isHost=$isHost',
        name: _logName,
      );

      // Step 1: Validate input
      final input = CancellationInput(
        eventId: eventId,
        userId: userId,
        reason: reason,
        isHost: isHost,
      );

      final validationResult = validate(input);
      if (!validationResult.isValid) {
        return CancellationResult.failure(
          error: validationResult.allErrors.join(', '),
          errorCode: 'VALIDATION_ERROR',
        );
      }

      // Step 2: Get event details
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        return CancellationResult.failure(
          error: 'Event not found',
          errorCode: 'EVENT_NOT_FOUND',
        );
      }

      // Step 3: Verify user permissions
      if (isHost && event.host.id != userId) {
        return CancellationResult.failure(
          error: 'User does not own this event',
          errorCode: 'PERMISSION_DENIED',
        );
      }

      // Step 4: Process cancellation via CancellationService
      final cancellation = isHost
          ? await _cancellationService.hostCancelEvent(
              eventId: eventId,
              hostId: userId,
              reason: reason,
            )
          : await _cancellationService.attendeeCancelTicket(
              eventId: eventId,
              attendeeId: userId,
            );

      developer.log(
        'Cancellation processed: id=${cancellation.id}, refundAmount=${cancellation.refundAmount}',
        name: _logName,
      );

      // Step 5: Update event status if full event cancellation
      if (cancellation.isFullEventCancellation) {
        try {
          // Update event status to cancelled
          await _eventService.updateEventStatus(
            event,
            EventStatus.cancelled,
          );

          developer.log(
            'Event status updated to cancelled: eventId=$eventId',
            name: _logName,
          );
        } catch (e) {
          developer.log(
            'Error updating event status: $e',
            name: _logName,
            error: e,
          );
          // Don't fail the whole cancellation if status update fails
          // Cancellation was successful, status update is secondary
        }
      }

      // Step 6: AVRAI Core System Integration (optional, graceful degradation)
      
      // 6.1: Update fabric if group event (remove attendee from fabric)
      if (_knotFabricService != null && event.maxAttendees > 1 && !isHost) {
        try {
          developer.log(
            '🧵 Updating fabric after attendee cancellation (group event)',
            name: _logName,
          );
          
          // Note: Full implementation would remove attendee's knot from fabric
          // This is a placeholder for future fabric update on cancellation
          developer.log(
            'ℹ️ Fabric update deferred (requires fabric ID and attendee knot)',
            name: _logName,
          );
        } catch (e) {
          developer.log(
            '⚠️ Fabric update failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - fabric update is optional
        }
      }
      
      // 6.2: Update worldsheet if group tracking exists
      if (_knotWorldsheetService != null && event.maxAttendees > 1 && !isHost) {
        try {
          developer.log(
            '📊 Worldsheet update deferred until fabric exists',
            name: _logName,
          );
          // Worldsheet update happens after fabric update
        } catch (e) {
          developer.log(
            '⚠️ Worldsheet update check failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - worldsheet update is optional
        }
      }
      
      // 6.3: Learn from cancellation via AI2AI mesh (optional, fire-and-forget)
      if (_aiLearningService != null) {
        try {
          developer.log(
            '🤖 AI2AI learning service available (learning deferred to matching)',
            name: _logName,
          );
          // Note: Actual learning happens when matches occur, not during cancellation
          // This is a placeholder for future cancellation-based learning
        } catch (e) {
          developer.log(
            '⚠️ AI2AI learning failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - AI2AI learning is optional and non-blocking
        }
      }
      
      // Step 7: Notify attendees/host (when NotificationService available)
      // TODO(Phase 8.12): Integrate NotificationService when available
      // For now, notifications are handled by CancellationService placeholder methods

      return CancellationResult.success(
        cancellation: cancellation,
        refundAmount: cancellation.refundAmount ?? 0.0,
        refundStatus: cancellation.refundStatus,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error cancelling event: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return CancellationResult.failure(
        error: 'Unexpected error: $e',
        errorCode: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Calculate refund amount for a cancellation (preview)
  /// 
  /// Calculates the refund amount without processing the cancellation.
  /// Used for showing users what they'll receive before they confirm.
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// - `userId`: User ID (attendee)
  /// 
  /// **Returns:**
  /// `RefundCalculation` with refund amount and policy details
  Future<RefundCalculation> calculateRefund({
    required String eventId,
    required String userId,
  }) async {
    try {
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        throw Exception('Event not found: $eventId');
      }

      // Get payment for this user and event
      final payment = _paymentService.getPaymentForEventAndUser(
        eventId,
        userId,
      );

      if (payment == null) {
        throw Exception('Payment not found for user $userId and event $eventId');
      }

      // Calculate time until event
      final timeUntilEvent = event.startTime.difference(DateTime.now());
      final hoursUntilEvent = timeUntilEvent.inHours.toDouble();

      // Calculate refund based on policy (matches CancellationService logic)
      final platformFee = payment.amount * 0.10; // 10% platform fee
      final refundableAmount = payment.amount - platformFee;

      double refundAmount = 0.0;
      if (hoursUntilEvent > 48) {
        refundAmount = refundableAmount; // Full refund
      } else if (hoursUntilEvent > 24) {
        refundAmount = refundableAmount * 0.5; // 50% refund
      } else {
        refundAmount = 0.0; // No refund
      }

      return RefundCalculation(
        refundAmount: refundAmount,
        originalAmount: payment.amount,
        platformFee: platformFee,
        hoursUntilEvent: hoursUntilEvent,
        isFullRefund: refundAmount == refundableAmount,
      );
    } catch (e) {
      developer.log(
        'Error calculating refund: $e',
        name: _logName,
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<CancellationResult> execute(CancellationInput input) async {
    return cancelEvent(
      eventId: input.eventId,
      userId: input.userId,
      reason: input.reason,
      isHost: input.isHost,
    );
  }

  @override
  ValidationResult validate(CancellationInput input) {
    final errors = <String, String>{};
    final generalErrors = <String>[];

    // Validate eventId
    if (input.eventId.trim().isEmpty) {
      errors['eventId'] = 'Event ID is required';
    }

    // Validate userId
    if (input.userId.trim().isEmpty) {
      errors['userId'] = 'User ID is required';
    }

    // Validate reason
    if (input.reason.trim().isEmpty) {
      errors['reason'] = 'Cancellation reason is required';
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
  Future<void> rollback(CancellationResult result) async {
    // Rollback cancellation (restore event status)
    if (result.success &&
        result.cancellation != null &&
        result.cancellation!.isFullEventCancellation) {
      try {
        final event = await _eventService.getEventById(result.cancellation!.eventId);
        if (event != null && event.status == EventStatus.cancelled) {
          // Restore event to previous status (default to upcoming)
          await _eventService.updateEventStatus(
            event,
            EventStatus.upcoming,
          );

          developer.log(
            'Rolled back event cancellation: eventId=${result.cancellation!.eventId}',
            name: _logName,
          );
        }
      } catch (e) {
        developer.log(
          'Error rolling back cancellation: $e',
          name: _logName,
          error: e,
        );
        // Don't rethrow - rollback failures should be logged but not block
      }
    }
  }
}

/// Cancellation Input
/// 
/// Input data for event cancellation
class CancellationInput {
  final String eventId;
  final String userId;
  final String reason;
  final bool isHost;

  CancellationInput({
    required this.eventId,
    required this.userId,
    required this.reason,
    required this.isHost,
  });
}

/// Cancellation Result
/// 
/// Unified result for cancellation operations
class CancellationResult extends ControllerResult {
  final Cancellation? cancellation;
  final double refundAmount;
  final RefundStatus? refundStatus;

  const CancellationResult._({
    required super.success,
    required super.error,
    required super.errorCode,
    this.cancellation,
    this.refundAmount = 0.0,
    this.refundStatus,
  });

  factory CancellationResult.success({
    required Cancellation cancellation,
    required double refundAmount,
    required RefundStatus refundStatus,
  }) {
    return CancellationResult._(
      success: true,
      error: null,
      errorCode: null,
      cancellation: cancellation,
      refundAmount: refundAmount,
      refundStatus: refundStatus,
    );
  }

  factory CancellationResult.failure({
    required String error,
    required String errorCode,
  }) {
    return CancellationResult._(
      success: false,
      error: error,
      errorCode: errorCode,
      cancellation: null,
      refundAmount: 0.0,
      refundStatus: null,
    );
  }
}

/// Refund Calculation
/// 
/// Preview of refund calculation for cancellation
class RefundCalculation {
  final double refundAmount;
  final double originalAmount;
  final double platformFee;
  final double hoursUntilEvent;
  final bool isFullRefund;

  RefundCalculation({
    required this.refundAmount,
    required this.originalAmount,
    required this.platformFee,
    required this.hoursUntilEvent,
    required this.isFullRefund,
  });
}

