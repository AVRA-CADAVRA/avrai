import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/cancellation.dart';
import 'package:spots/core/models/cancellation_initiator.dart';
import 'package:spots/core/models/refund_status.dart';

/// SPOTS Cancellation Model Unit Tests
/// Date: December 1, 2025
/// Purpose: Test Cancellation model functionality
/// 
/// Test Coverage:
/// - Model Creation: Constructor and properties
/// - Status Checks: Refund status validation
/// - Initiator Checks: Force majeure, host/attendee initiated
/// - JSON Serialization: toJson/fromJson
/// - Equality: Equatable implementation
/// - Copy With: Field updates
/// 
/// Dependencies:
/// - CancellationInitiator: Initiator enum
/// - RefundStatus: Refund status enum

void main() {
  group('Cancellation', () {
    late Cancellation cancellation;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 12, 1, 14, 0);
      
      cancellation = Cancellation(
        id: 'cancellation-123',
        eventId: 'event-456',
        userId: 'user-789',
        initiator: CancellationInitiator.attendee,
        reason: 'Unable to attend',
        refundStatus: RefundStatus.pending,
        paymentIds: ['payment-1', 'payment-2'],
        createdAt: testDate,
        updatedAt: testDate,
        refundAmount: 50.0,
        isFullEventCancellation: false,
        isForceMajeure: false,
      );
    });

    group('Constructor and Properties', () {
      test('should create cancellation with all required fields', () {
        expect(cancellation.id, 'cancellation-123');
        expect(cancellation.eventId, 'event-456');
        expect(cancellation.userId, 'user-789');
        expect(cancellation.initiator, CancellationInitiator.attendee);
        expect(cancellation.reason, 'Unable to attend');
        expect(cancellation.refundStatus, RefundStatus.pending);
        expect(cancellation.paymentIds, ['payment-1', 'payment-2']);
        expect(cancellation.refundAmount, 50.0);
        expect(cancellation.isFullEventCancellation, false);
        expect(cancellation.isForceMajeure, false);
      });

      test('should create cancellation with default values', () {
        final minimalCancellation = Cancellation(
          id: 'cancellation-1',
          eventId: 'event-1',
          userId: 'user-1',
          initiator: CancellationInitiator.host,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(minimalCancellation.reason, isNull);
        expect(minimalCancellation.refundStatus, RefundStatus.pending);
        expect(minimalCancellation.paymentIds, isEmpty);
        expect(minimalCancellation.refundAmount, isNull);
        expect(minimalCancellation.isFullEventCancellation, false);
        expect(minimalCancellation.isForceMajeure, false);
        expect(minimalCancellation.metadata, isEmpty);
      });
    });

    group('Status Checks', () {
      test('should identify pending refund status', () {
        expect(cancellation.refundStatus, RefundStatus.pending);
        expect(cancellation.refundStatus.isInProgress, true);
      });

      test('should identify completed refund status', () {
        final completed = cancellation.copyWith(
          refundStatus: RefundStatus.completed,
          refundProcessedAt: testDate.add(const Duration(hours: 1)),
        );
        expect(completed.refundStatus.isSuccessful, true);
        expect(completed.refundStatus.isTerminal, true);
      });

      test('should identify failed refund status', () {
        final failed = cancellation.copyWith(
          refundStatus: RefundStatus.failed,
        );
        expect(failed.refundStatus.isTerminal, true);
        expect(failed.refundStatus.isSuccessful, false);
      });
    });

    group('Initiator Checks', () {
      test('should identify attendee-initiated cancellation', () {
        expect(cancellation.initiator.isAttendeeInitiated, true);
        expect(cancellation.initiator.isHostInitiated, false);
      });

      test('should identify host-initiated cancellation', () {
        final hostCancellation = cancellation.copyWith(
          initiator: CancellationInitiator.host,
        );
        expect(hostCancellation.initiator.isHostInitiated, true);
        expect(hostCancellation.initiator.isAttendeeInitiated, false);
      });

      test('should identify force majeure cancellation', () {
        final weatherCancellation = cancellation.copyWith(
          initiator: CancellationInitiator.weather,
          isForceMajeure: true,
        );
        expect(weatherCancellation.initiator.isForceMajeure, true);
        expect(weatherCancellation.isForceMajeure, true);
      });

      test('should identify platform-initiated as force majeure', () {
        final platformCancellation = cancellation.copyWith(
          initiator: CancellationInitiator.platform,
          isForceMajeure: true,
        );
        expect(platformCancellation.initiator.isForceMajeure, true);
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final json = cancellation.toJson();

        expect(json['id'], 'cancellation-123');
        expect(json['eventId'], 'event-456');
        expect(json['userId'], 'user-789');
        expect(json['initiator'], 'attendee');
        expect(json['reason'], 'Unable to attend');
        expect(json['refundStatus'], 'pending');
        expect(json['paymentIds'], ['payment-1', 'payment-2']);
        expect(json['refundAmount'], 50.0);
        expect(json['isFullEventCancellation'], false);
        expect(json['isForceMajeure'], false);
      });

      test('should deserialize from JSON correctly', () {
        final json = cancellation.toJson();
        final deserialized = Cancellation.fromJson(json);

        expect(deserialized.id, cancellation.id);
        expect(deserialized.eventId, cancellation.eventId);
        expect(deserialized.userId, cancellation.userId);
        expect(deserialized.initiator, cancellation.initiator);
        expect(deserialized.reason, cancellation.reason);
        expect(deserialized.refundStatus, cancellation.refundStatus);
        expect(deserialized.paymentIds, cancellation.paymentIds);
        expect(deserialized.refundAmount, cancellation.refundAmount);
      });

      test('should handle null optional fields in JSON', () {
        final minimalCancellation = Cancellation(
          id: 'cancellation-1',
          eventId: 'event-1',
          userId: 'user-1',
          initiator: CancellationInitiator.host,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final json = minimalCancellation.toJson();
        final deserialized = Cancellation.fromJson(json);

        expect(deserialized.reason, isNull);
        expect(deserialized.refundProcessedAt, isNull);
        expect(deserialized.refundAmount, isNull);
      });
    });

    group('Equality', () {
      test('should be equal when all properties match', () {
        final cancellation2 = cancellation.copyWith();
        expect(cancellation, equals(cancellation2));
      });

      test('should not be equal when properties differ', () {
        final cancellation2 = cancellation.copyWith(
          refundStatus: RefundStatus.completed,
        );
        expect(cancellation, isNot(equals(cancellation2)));
      });
    });

    group('Copy With', () {
      test('should create copy with updated fields', () {
        final updated = cancellation.copyWith(
          refundStatus: RefundStatus.completed,
          refundProcessedAt: testDate.add(const Duration(hours: 1)),
          refundAmount: 75.0,
        );

        expect(updated.refundStatus, RefundStatus.completed);
        expect(updated.refundProcessedAt, isNotNull);
        expect(updated.refundAmount, 75.0);
        expect(updated.id, cancellation.id); // Unchanged
      });

      test('should preserve all fields when copying', () {
        final copied = cancellation.copyWith();
        expect(copied, equals(cancellation));
      });
    });
  });
}

