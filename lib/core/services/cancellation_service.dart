import 'package:spots/core/models/cancellation.dart';
import 'package:spots/core/models/cancellation_initiator.dart';
import 'package:spots/core/models/refund_status.dart';
import 'package:spots/core/models/refund_policy.dart';
import 'package:spots/core/models/payment.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/refund_service.dart';
import 'package:spots/core/services/logger.dart';
import 'package:uuid/uuid.dart';

/// Cancellation Service
/// 
/// Handles event and ticket cancellations with refund processing.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to trust and user protection
/// - Enables fair cancellation policies
/// - Supports transparent refund processing
/// - Creates pathways for dispute resolution
/// 
/// **Responsibilities:**
/// - Process attendee ticket cancellations
/// - Process host event cancellations
/// - Process emergency cancellations (weather, force majeure)
/// - Calculate refunds based on policy
/// - Integrate with RefundService for processing
/// 
/// **Usage:**
/// ```dart
/// final cancellationService = CancellationService(
///   paymentService,
///   eventService,
///   refundService,
/// );
/// 
/// // Attendee cancels ticket
/// final cancellation = await cancellationService.attendeeCancelTicket(
///   eventId: 'event-123',
///   attendeeId: 'user-456',
/// );
/// ```
class CancellationService {
  static const String _logName = 'CancellationService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();
  
  final PaymentService _paymentService;
  final ExpertiseEventService _eventService;
  final RefundService _refundService;
  
  // In-memory storage for cancellations (in production, use database)
  final Map<String, Cancellation> _cancellations = {};
  
  CancellationService({
    required PaymentService paymentService,
    required ExpertiseEventService eventService,
    required RefundService refundService,
  }) : _paymentService = paymentService,
       _eventService = eventService,
       _refundService = refundService;
  
  /// Attendee cancels their ticket
  /// 
  /// **Flow:**
  /// 1. Get event and payment records
  /// 2. Calculate time until event
  /// 3. Calculate refund based on RefundPolicy
  /// 4. Create cancellation record
  /// 5. Process refund through RefundService
  /// 6. Notify host (spot reopened)
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// - `attendeeId`: User ID cancelling ticket
  /// 
  /// **Returns:**
  /// Cancellation record with refund status
  /// 
  /// **Throws:**
  /// - `Exception` if event not found
  /// - `Exception` if payment not found
  /// - `Exception` if refund processing fails
  Future<Cancellation> attendeeCancelTicket({
    required String eventId,
    required String attendeeId,
  }) async {
    try {
      _logger.info('Processing attendee cancellation: event=$eventId, attendee=$attendeeId', tag: _logName);
      
      // Step 1: Get event
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        throw Exception('Event not found: $eventId');
      }
      
      // Step 2: Get payment for this attendee and event
      final payment = await _getPaymentForAttendee(eventId, attendeeId);
      if (payment == null) {
        throw Exception('Payment not found for attendee $attendeeId and event $eventId');
      }
      
      // Step 3: Calculate time until event
      final timeUntilEvent = event.startTime.difference(DateTime.now());
      
      // Step 4: Calculate refund based on policy
      final hoursUntilEvent = timeUntilEvent.inHours.toDouble();
      final policy = RefundPolicy.standard();
      final platformFee = payment.amount * 0.10; // 10% platform fee
      // For attendee cancellations, refund is calculated on amount minus platform fee
      final refundableAmount = payment.amount - platformFee;
      final refundAmount = policy.calculateRefundAmount(
        ticketPrice: refundableAmount,
        hoursUntilEvent: hoursUntilEvent,
        isForceMajeure: false,
      );
      
      // Step 5: Create cancellation record
      final cancellation = Cancellation(
        id: 'cancellation_${_uuid.v4()}',
        eventId: eventId,
        userId: attendeeId,
        initiator: CancellationInitiator.attendee,
        reason: 'Attendee cancelled',
        refundStatus: RefundStatus.pending,
        paymentIds: [payment.id],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        refundAmount: refundAmount,
        isFullEventCancellation: false,
        isForceMajeure: false,
      );
      
      await _saveCancellation(cancellation);
      
      // Step 6: Process refund
      if (refundAmount > 0) {
        try {
          final distributions = await _refundService.processRefund(
            paymentId: payment.id,
            amount: refundAmount,
            cancellationId: cancellation.id,
          );
          
          // Update cancellation with refund status
          final updatedCancellation = cancellation.copyWith(
            refundStatus: RefundStatus.completed,
            refundProcessedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _saveCancellation(updatedCancellation);
          
          _logger.info('Attendee cancellation processed: ${cancellation.id}, refund: \$${refundAmount.toStringAsFixed(2)}', tag: _logName);
          
          // Step 7: Notify host (spot reopened)
          await _notifyHostOfCancellation(event.host.id, eventId, cancellation.id);
          
          return updatedCancellation;
        } catch (e) {
          _logger.error('Refund processing failed', error: e, tag: _logName);
          
          // Update cancellation with failed status
          final failedCancellation = cancellation.copyWith(
            refundStatus: RefundStatus.failed,
            updatedAt: DateTime.now(),
          );
          await _saveCancellation(failedCancellation);
          
          throw Exception('Refund processing failed: ${e.toString()}');
        }
      } else {
        // No refund (day of event)
        _logger.info('No refund available (day of event): ${cancellation.id}', tag: _logName);
        
        final noRefundCancellation = cancellation.copyWith(
          refundStatus: RefundStatus.completed,
          refundProcessedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _saveCancellation(noRefundCancellation);
        
        await _notifyHostOfCancellation(event.host.id, eventId, cancellation.id);
        
        return noRefundCancellation;
      }
    } catch (e) {
      _logger.error('Error processing attendee cancellation', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Host cancels entire event
  /// 
  /// **Flow:**
  /// 1. Get event and all payments
  /// 2. Calculate time until event
  /// 3. Full refund for all attendees (including platform fee)
  /// 4. Apply host penalty if last-minute (<48 hours)
  /// 5. Create cancellation record
  /// 6. Process batch refunds
  /// 7. Notify all attendees
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// - `hostId`: Host user ID
  /// - `reason`: Reason for cancellation
  /// 
  /// **Returns:**
  /// Cancellation record with refund status
  /// 
  /// **Throws:**
  /// - `Exception` if event not found
  /// - `Exception` if host doesn't own event
  /// - `Exception` if refund processing fails
  Future<Cancellation> hostCancelEvent({
    required String eventId,
    required String hostId,
    required String reason,
  }) async {
    try {
      _logger.info('Processing host cancellation: event=$eventId, host=$hostId', tag: _logName);
      
      // Step 1: Get event
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        throw Exception('Event not found: $eventId');
      }
      
      // Step 2: Verify host owns event
      if (event.host.id != hostId) {
        throw Exception('User $hostId does not own event $eventId');
      }
      
      // Step 3: Get all payments for this event
      final payments = await _getAllPaymentsForEvent(eventId);
      
      // Step 4: Calculate time until event
      final timeUntilEvent = event.startTime.difference(DateTime.now());
      
      // Step 5: Calculate total refunds (full refund for all attendees)
      final totalRefunds = payments.fold<double>(0.0, (sum, payment) => sum + payment.amount);
      
      // Step 6: Host penalty if cancellation is last-minute (<48 hours)
      final hoursUntilEvent = timeUntilEvent.inHours;
      final hostPenalty = hoursUntilEvent < 48;
      final penaltyAmount = hostPenalty ? totalRefunds * 0.10 : 0.0;
      
      // Step 7: Create cancellation record
      final cancellation = Cancellation(
        id: 'cancellation_${_uuid.v4()}',
        eventId: eventId,
        userId: hostId,
        initiator: CancellationInitiator.host,
        reason: reason,
        refundStatus: RefundStatus.pending,
        paymentIds: payments.map((p) => p.id).toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        refundAmount: totalRefunds,
        isFullEventCancellation: true,
        isForceMajeure: false,
        metadata: {
          'hostPenalty': hostPenalty,
          'penaltyAmount': penaltyAmount,
        },
      );
      
      await _saveCancellation(cancellation);
      
      // Step 8: Process batch refunds
      if (totalRefunds > 0) {
        try {
          final distributions = await _refundService.processBatchRefunds(
            payments: payments,
            cancellationId: cancellation.id,
            fullRefund: true, // Full refund including platform fee
          );
          
          // Update cancellation with refund status
          final updatedCancellation = cancellation.copyWith(
            refundStatus: RefundStatus.completed,
            refundProcessedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _saveCancellation(updatedCancellation);
          
          _logger.info('Host cancellation processed: ${cancellation.id}, total refunds: \$${totalRefunds.toStringAsFixed(2)}', tag: _logName);
          
          // Step 9: Apply host penalty if applicable
          if (hostPenalty) {
            await _applyHostPenalty(hostId, penaltyAmount);
          }
          
          // Step 10: Notify all attendees
          await _notifyAttendeesOfCancellation(payments, reason);
          
          return updatedCancellation;
        } catch (e) {
          _logger.error('Batch refund processing failed', error: e, tag: _logName);
          
          // Update cancellation with failed status
          final failedCancellation = cancellation.copyWith(
            refundStatus: RefundStatus.failed,
            updatedAt: DateTime.now(),
          );
          await _saveCancellation(failedCancellation);
          
          throw Exception('Batch refund processing failed: ${e.toString()}');
        }
      } else {
        // No payments to refund
        final noRefundCancellation = cancellation.copyWith(
          refundStatus: RefundStatus.completed,
          refundProcessedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _saveCancellation(noRefundCancellation);
        
        await _notifyAttendeesOfCancellation(payments, reason);
        
        return noRefundCancellation;
      }
    } catch (e) {
      _logger.error('Error processing host cancellation', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Emergency cancellation (weather, force majeure)
  /// 
  /// **Flow:**
  /// 1. Get event and all payments
  /// 2. Full refund for all attendees (no penalties)
  /// 3. Create cancellation record
  /// 4. Process batch refunds
  /// 5. Notify all attendees
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// - `reason`: Reason for emergency cancellation
  /// - `weatherRelated`: Whether this is weather-related
  /// 
  /// **Returns:**
  /// Cancellation record with refund status
  /// 
  /// **Throws:**
  /// - `Exception` if event not found
  /// - `Exception` if refund processing fails
  Future<Cancellation> emergencyCancelEvent({
    required String eventId,
    required String reason,
    required bool weatherRelated,
  }) async {
    try {
      _logger.info('Processing emergency cancellation: event=$eventId, weather=$weatherRelated', tag: _logName);
      
      // Step 1: Get event
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        throw Exception('Event not found: $eventId');
      }
      
      // Step 2: Get all payments for this event
      final payments = await _getAllPaymentsForEvent(eventId);
      
      // Step 3: Calculate total refunds (full refund for all attendees)
      final totalRefunds = payments.fold<double>(0.0, (sum, payment) => sum + payment.amount);
      
      // Step 4: Create cancellation record
      final cancellation = Cancellation(
        id: 'cancellation_${_uuid.v4()}',
        eventId: eventId,
        userId: event.host.id, // Host is affected user
        initiator: weatherRelated ? CancellationInitiator.weather : CancellationInitiator.platform,
        reason: reason,
        refundStatus: RefundStatus.pending,
        paymentIds: payments.map((p) => p.id).toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        refundAmount: totalRefunds,
        isFullEventCancellation: true,
        isForceMajeure: true,
      );
      
      await _saveCancellation(cancellation);
      
      // Step 5: Process batch refunds (full refund including platform fee)
      if (totalRefunds > 0) {
        try {
          final distributions = await _refundService.processBatchRefunds(
            payments: payments,
            cancellationId: cancellation.id,
            fullRefund: true, // Full refund including platform fee
          );
          
          // Update cancellation with refund status
          final updatedCancellation = cancellation.copyWith(
            refundStatus: RefundStatus.completed,
            refundProcessedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _saveCancellation(updatedCancellation);
          
          _logger.info('Emergency cancellation processed: ${cancellation.id}, total refunds: \$${totalRefunds.toStringAsFixed(2)}', tag: _logName);
          
          // Step 6: Notify all attendees
          await _notifyAttendeesOfCancellation(payments, reason);
          
          return updatedCancellation;
        } catch (e) {
          _logger.error('Batch refund processing failed', error: e, tag: _logName);
          
          // Update cancellation with failed status
          final failedCancellation = cancellation.copyWith(
            refundStatus: RefundStatus.failed,
            updatedAt: DateTime.now(),
          );
          await _saveCancellation(failedCancellation);
          
          throw Exception('Batch refund processing failed: ${e.toString()}');
        }
      } else {
        // No payments to refund
        final noRefundCancellation = cancellation.copyWith(
          refundStatus: RefundStatus.completed,
          refundProcessedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _saveCancellation(noRefundCancellation);
        
        await _notifyAttendeesOfCancellation(payments, reason);
        
        return noRefundCancellation;
      }
    } catch (e) {
      _logger.error('Error processing emergency cancellation', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Get cancellation by ID
  Future<Cancellation?> getCancellation(String cancellationId) async {
    try {
      return _cancellations[cancellationId];
    } catch (e) {
      _logger.error('Error getting cancellation', error: e, tag: _logName);
      return null;
    }
  }
  
  /// Get cancellations for an event
  Future<List<Cancellation>> getCancellationsForEvent(String eventId) async {
    try {
      return _cancellations.values
          .where((c) => c.eventId == eventId)
          .toList();
    } catch (e) {
      _logger.error('Error getting cancellations for event', error: e, tag: _logName);
      return [];
    }
  }
  
  // Private helper methods
  
  Future<Payment?> _getPaymentForAttendee(String eventId, String attendeeId) async {
    try {
      // Use PaymentService method to get payment for specific user and event
      return _paymentService.getPaymentForEventAndUser(eventId, attendeeId);
    } catch (e) {
      _logger.error('Error getting payment for attendee', error: e, tag: _logName);
      return null;
    }
  }
  
  Future<List<Payment>> _getAllPaymentsForEvent(String eventId) async {
    try {
      // Use PaymentService method to get all payments for event
      return _paymentService.getPaymentsForEvent(eventId);
    } catch (e) {
      _logger.error('Error getting payments for event', error: e, tag: _logName);
      return [];
    }
  }
  
  Future<void> _saveCancellation(Cancellation cancellation) async {
    // In production, save to database
    _cancellations[cancellation.id] = cancellation;
  }
  
  Future<void> _notifyHostOfCancellation(String hostId, String eventId, String cancellationId) async {
    // In production, send notification to host
    _logger.info('Notifying host $hostId of cancellation $cancellationId for event $eventId', tag: _logName);
    // TODO: Implement notification system
  }
  
  Future<void> _notifyAttendeesOfCancellation(List<Payment> payments, String reason) async {
    // In production, send notifications to all attendees
    _logger.info('Notifying ${payments.length} attendees of cancellation: $reason', tag: _logName);
    // TODO: Implement notification system
  }
  
  Future<void> _applyHostPenalty(String hostId, double penaltyAmount) async {
    // In production, deduct penalty from host's next payout
    _logger.info('Applying host penalty: host=$hostId, amount=\$${penaltyAmount.toStringAsFixed(2)}', tag: _logName);
    // TODO: Implement penalty system
  }
}

