import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/dispute.dart';
import 'package:spots/core/models/dispute_status.dart';
import 'package:spots/core/models/dispute_type.dart';
import 'package:spots/core/models/cancellation.dart';
import 'package:spots/core/models/cancellation_initiator.dart';
import 'package:spots/core/models/refund_status.dart';
import 'package:spots/core/models/payment.dart';
import 'package:spots/core/models/payment_status.dart';
import 'package:spots/core/models/event_partnership.dart';

/// Integration tests for dispute resolution flow
/// 
/// Tests model relationships and data flow for:
/// 1. Dispute submission → Resolution workflow
void main() {
  group('Dispute Resolution Integration Tests', () {
    test('cancellation dispute creates dispute record', () {
      final cancellation = Cancellation(
        id: 'cancellation-123',
        eventId: 'event-456',
        userId: 'user-789',
        initiator: CancellationInitiator.attendee,
        refundStatus: RefundStatus.disputed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final dispute = Dispute(
        id: 'dispute-123',
        eventId: cancellation.eventId,
        reporterId: cancellation.userId,
        reportedId: 'host-123', // Host being reported
        type: DisputeType.cancellation,
        description: 'Refund not received after cancellation',
        createdAt: DateTime.now(),
        metadata: {
          'cancellationId': cancellation.id,
        },
      );

      expect(dispute.eventId, equals(cancellation.eventId));
      expect(dispute.type, equals(DisputeType.cancellation));
      expect(dispute.metadata['cancellationId'], equals(cancellation.id));
      expect(dispute.status, equals(DisputeStatus.pending));
    });

    test('payment dispute creates dispute record', () {
      final payment = Payment(
        id: 'payment-123',
        eventId: 'event-456',
        userId: 'user-789',
        amount: 50.0,
        status: PaymentStatus.completed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final dispute = Dispute(
        id: 'dispute-456',
        eventId: payment.eventId,
        reporterId: payment.userId,
        reportedId: 'host-123', // Host being reported
        type: DisputeType.payment,
        description: 'Incorrect charge amount',
        createdAt: DateTime.now(),
        metadata: {
          'paymentId': payment.id,
        },
      );

      expect(dispute.type, equals(DisputeType.payment));
      expect(dispute.metadata['paymentId'], equals(payment.id));
    });

    test('partnership dispute creates dispute record', () {
      final partnership = EventPartnership(
        id: 'partnership-123',
        eventId: 'event-456',
        userId: 'user-1',
        businessId: 'business-1',
        status: PartnershipStatus.disputed,
        type: PartnershipType.eventBased,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final dispute = Dispute(
        id: 'dispute-789',
        eventId: partnership.eventId,
        reporterId: partnership.userId,
        reportedId: partnership.businessId,
        type: DisputeType.partnership,
        description: 'Revenue split disagreement',
        createdAt: DateTime.now(),
        metadata: {
          'partnershipId': partnership.id,
        },
      );

      expect(dispute.type, equals(DisputeType.partnership));
      expect(dispute.metadata['partnershipId'], equals(partnership.id));
      expect(dispute.reportedId, contains(partnership.businessId));
    });

    test('dispute messages create conversation thread', () {
      final dispute = Dispute(
        id: 'dispute-123',
        eventId: 'event-456',
        reporterId: 'user-789',
        reportedId: 'host-123',
        type: DisputeType.cancellation,
        description: 'Refund issue',
        createdAt: DateTime.now(),
        status: DisputeStatus.inReview,
      );

      final message1 = DisputeMessage(
        senderId: dispute.reporterId,
        message: 'I did not receive my refund',
        timestamp: DateTime.now(),
      );

      final message2 = DisputeMessage(
        senderId: 'admin-1',
        message: 'We are investigating your refund issue',
        isAdminMessage: true,
        timestamp: DateTime.now().add(const Duration(hours: 1)),
      );

      final updatedDispute = dispute.copyWith(
        messages: [message1, message2],
        status: DisputeStatus.inReview,
      );

      expect(updatedDispute.messages.length, equals(2));
      expect(updatedDispute.status, equals(DisputeStatus.inReview));
      expect(updatedDispute.messages.last.message, contains('investigating'));
      expect(updatedDispute.messages.first.message, contains('refund'));
    });

    test('dispute resolution workflow updates status', () {
      final dispute = Dispute(
        id: 'dispute-123',
        eventId: 'event-456',
        reporterId: 'user-789',
        reportedId: 'host-123',
        type: DisputeType.cancellation,
        description: 'Refund issue',
        createdAt: DateTime.now(),
      );

      // Step 1: Admin assigned
      final assigned = dispute.copyWith(
        status: DisputeStatus.inReview,
        assignedAdminId: 'admin-1',
        assignedAt: DateTime.now(),
      );

      expect(assigned.assignedAdminId, isNotNull);
      expect(assigned.status, equals(DisputeStatus.inReview));

      // Step 2: Resolution completed
      final resolved = assigned.copyWith(
        status: DisputeStatus.resolved,
        resolution: 'Refund processed, issue resolved',
        resolvedAt: DateTime.now(),
        resolutionDetails: {
          'outcome': 'resolved_in_favor_of_user',
        },
      );

      expect(resolved.isResolved, isTrue);
      expect(resolved.resolution, isNotNull);
      expect(resolved.resolvedAt, isNotNull);
    });

    test('multiple disputes for same event', () {
      final dispute1 = Dispute(
        id: 'd1',
        eventId: 'event-123',
        reporterId: 'user-1',
        reportedId: 'host-123',
        type: DisputeType.payment,
        description: 'Payment issue 1',
        createdAt: DateTime.now(),
      );

      final dispute2 = Dispute(
        id: 'd2',
        eventId: 'event-123',
        reporterId: 'user-2',
        reportedId: 'host-123',
        type: DisputeType.event,
        description: 'Event quality issue',
        createdAt: DateTime.now(),
      );

      final allDisputes = [dispute1, dispute2];
      final eventDisputes = allDisputes
          .where((d) => d.eventId == 'event-123')
          .toList();

      expect(eventDisputes.length, equals(2));
      expect(eventDisputes.any((d) => d.type == DisputeType.payment), isTrue);
      expect(eventDisputes.any((d) => d.type == DisputeType.event), isTrue);
    });
  });
}
