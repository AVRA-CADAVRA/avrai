import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/cancellation.dart';
import 'package:spots/core/models/refund_status.dart';
import 'package:spots/core/models/refund_distribution.dart';
import 'package:spots/core/models/refund_policy.dart';
import 'package:spots/core/models/payment.dart';
import 'package:spots/core/models/payment_status.dart';
import 'package:spots/core/models/expertise_event.dart';
import '../../fixtures/model_factories.dart';

/// Integration tests for cancellation and refund flow
/// 
/// Tests model relationships and data flow for:
/// 1. Attendee cancellation → Refund processing
/// 2. Host cancellation → Full refunds
/// 3. Emergency cancellation → Force majeure handling
void main() {
  group('Cancellation Flow Integration Tests', () {
    late ExpertiseEvent testEvent;
    late Payment testPayment;

    setUp(() {
      final testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test Host',
      );

      testEvent = ExpertiseEvent(
        id: 'event-123',
        title: 'Coffee Workshop',
        description: 'Learn about coffee',
        category: 'Coffee',
        eventType: ExpertiseEventType.workshop,
        host: testUser,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        price: 50.0,
        isPaid: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testPayment = Payment(
        id: 'payment-123',
        eventId: testEvent.id,
        userId: 'attendee-456',
        amount: 50.0,
        status: PaymentStatus.completed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('attendee cancellation creates cancellation with pending refund', () {
      final cancellation = Cancellation(
        id: 'cancellation-123',
        eventId: testEvent.id,
        userId: testPayment.userId,
        initiator: CancellationInitiator.attendee,
        reason: 'Unable to attend',
        refundStatus: RefundStatus.pending,
        paymentIds: [testPayment.id],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(cancellation.eventId, equals(testEvent.id));
      expect(cancellation.initiator, equals(CancellationInitiator.attendee));
      expect(cancellation.refundStatus, equals(RefundStatus.pending));
      expect(cancellation.paymentIds, contains(testPayment.id));
      expect(cancellation.isFullEventCancellation, isFalse);
      expect(cancellation.isForceMajeure, isFalse);
    });

    test('host cancellation creates full event cancellation', () {
      final cancellation = Cancellation(
        id: 'cancellation-456',
        eventId: testEvent.id,
        userId: testEvent.host.id,
        initiator: CancellationInitiator.host,
        reason: 'Host emergency',
        refundStatus: RefundStatus.pending,
        paymentIds: [testPayment.id],
        isFullEventCancellation: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(cancellation.initiator, equals(CancellationInitiator.host));
      expect(cancellation.isFullEventCancellation, isTrue);
      expect(cancellation.isHostInitiated, isTrue);
    });

    test('emergency cancellation is force majeure', () {
      final cancellation = Cancellation(
        id: 'cancellation-789',
        eventId: testEvent.id,
        userId: 'platform',
        initiator: CancellationInitiator.weather,
        reason: 'Severe weather warning',
        refundStatus: RefundStatus.pending,
        paymentIds: [testPayment.id],
        isForceMajeure: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(cancellation.initiator.isForceMajeure, isTrue);
      expect(cancellation.isForceMajeure, isTrue);
    });

    test('refund policy calculates refund amount correctly', () {
      final policy = RefundPolicy.standard();
      
      // Full refund (> 48 hours)
      final fullRefund = policy.calculateRefundAmount(
        ticketPrice: 50.0,
        hoursUntilEvent: 72,
        isForceMajeure: false,
      );
      expect(fullRefund, equals(50.0));

      // Partial refund (24-48 hours)
      final partialRefund = policy.calculateRefundAmount(
        ticketPrice: 50.0,
        hoursUntilEvent: 36,
        isForceMajeure: false,
      );
      expect(partialRefund, equals(25.0)); // 50% refund

      // No refund (< 24 hours)
      final noRefund = policy.calculateRefundAmount(
        ticketPrice: 50.0,
        hoursUntilEvent: 12,
        isForceMajeure: false,
      );
      expect(noRefund, equals(0.0));

      // Force majeure always gets full refund
      final forceMajeureRefund = policy.calculateRefundAmount(
        ticketPrice: 50.0,
        hoursUntilEvent: 12,
        isForceMajeure: true,
      );
      expect(forceMajeureRefund, equals(50.0));
    });

    test('refund distribution creates refund record', () {
      final distribution = RefundDistribution(
        userId: testPayment.userId,
        role: 'attendee',
        amount: 50.0,
        stripeRefundId: 're_1234567890',
        completedAt: DateTime.now(),
        statusMessage: 'Refund processed successfully',
        metadata: const {},
      );

      expect(distribution.userId, equals(testPayment.userId));
      expect(distribution.amount, equals(50.0));
      expect(distribution.isProcessed, isTrue);
    });

    test('cancellation to refund distribution flow', () {
      // Step 1: Create cancellation
      final cancellation = Cancellation(
        id: 'cancellation-123',
        eventId: testEvent.id,
        userId: testPayment.userId,
        initiator: CancellationInitiator.attendee,
        refundStatus: RefundStatus.processing,
        paymentIds: [testPayment.id],
        refundAmount: 50.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Step 2: Create refund distribution
      final distribution = RefundDistribution(
        userId: cancellation.userId,
        role: 'attendee',
        amount: cancellation.refundAmount!,
        stripeRefundId: 're_1234567890',
        completedAt: DateTime.now(),
        metadata: {'cancellationId': cancellation.id},
      );

      // Step 3: Update cancellation with refund status
      final updatedCancellation = cancellation.copyWith(
        refundStatus: RefundStatus.completed,
        refundProcessedAt: distribution.completedAt,
      );

      expect(updatedCancellation.refundStatus, equals(RefundStatus.completed));
      expect(updatedCancellation.isRefundCompleted, isTrue);
      expect(distribution.amount, equals(cancellation.refundAmount));
    });

    test('multiple payments cancellation handles all refunds', () {
      final payment1 = testPayment;
      final payment2 = testPayment.copyWith(
        id: 'payment-456',
        userId: 'attendee-789',
      );

      final cancellation = Cancellation(
        id: 'cancellation-full',
        eventId: testEvent.id,
        userId: testEvent.host.id,
        initiator: CancellationInitiator.host,
        refundStatus: RefundStatus.pending,
        paymentIds: [payment1.id, payment2.id],
        isFullEventCancellation: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(cancellation.paymentIds.length, equals(2));
      expect(cancellation.paymentIds, contains(payment1.id));
      expect(cancellation.paymentIds, contains(payment2.id));
    });
  });
}

