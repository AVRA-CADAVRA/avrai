import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/payment_intent.dart';
import 'package:spots/core/models/payment_status.dart';

/// SPOTS PaymentIntent Model Unit Tests
/// Date: December 1, 2025
/// Purpose: Test PaymentIntent model functionality
/// 
/// Test Coverage:
/// - Model Creation: Constructor and properties
/// - Status Checks: Terminal states, success
/// - JSON Serialization: toJson/fromJson
/// - Equality: Equatable implementation
/// - Copy With: Field updates
/// 
/// Dependencies:
/// - PaymentStatus: Payment status enum

void main() {
  group('PaymentIntent', () {
    late PaymentIntent paymentIntent;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 12, 1, 14, 0);
      
      paymentIntent = PaymentIntent(
        id: 'pi_1234567890',
        clientSecret: 'pi_1234567890_secret_abc',
        amount: 2500, // $25.00
        currency: 'usd',
        status: PaymentStatus.pending,
        createdAt: testDate,
        eventId: 'event-456',
        userId: 'user-789',
      );
    });

    group('Constructor and Properties', () {
      test('should create payment intent with all required fields', () {
        expect(paymentIntent.id, 'pi_1234567890');
        expect(paymentIntent.clientSecret, 'pi_1234567890_secret_abc');
        expect(paymentIntent.amount, 2500);
        expect(paymentIntent.currency, 'usd');
        expect(paymentIntent.status, PaymentStatus.pending);
        expect(paymentIntent.eventId, 'event-456');
        expect(paymentIntent.userId, 'user-789');
      });

      test('should create payment intent with default values', () {
        final minimalIntent = PaymentIntent(
          id: 'pi_1',
          clientSecret: 'pi_1_secret',
          amount: 1000,
          currency: 'usd',
          status: PaymentStatus.pending,
          createdAt: testDate,
        );

        expect(minimalIntent.updatedAt, isNull);
        expect(minimalIntent.paymentMethodId, isNull);
        expect(minimalIntent.eventId, isNull);
        expect(minimalIntent.userId, isNull);
        expect(minimalIntent.metadata, isEmpty);
      });
    });

    group('Status Checks', () {
      test('should identify pending status', () {
        expect(paymentIntent.status, PaymentStatus.pending);
        expect(paymentIntent.status.isTerminal, false);
      });

      test('should identify completed status', () {
        final completed = paymentIntent.copyWith(
          status: PaymentStatus.completed,
        );
        expect(completed.status.isSuccessful, true);
        expect(completed.status.isTerminal, true);
      });

      test('should identify failed status', () {
        final failed = paymentIntent.copyWith(
          status: PaymentStatus.failed,
        );
        expect(failed.status.isTerminal, true);
        expect(failed.status.isSuccessful, false);
      });

      test('should identify refunded status', () {
        final refunded = paymentIntent.copyWith(
          status: PaymentStatus.refunded,
        );
        expect(refunded.status.isTerminal, true);
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final json = paymentIntent.toJson();

        expect(json['id'], 'pi_1234567890');
        expect(json['clientSecret'], 'pi_1234567890_secret_abc');
        expect(json['amount'], 2500);
        expect(json['currency'], 'usd');
        expect(json['status'], 'pending');
        expect(json['eventId'], 'event-456');
        expect(json['userId'], 'user-789');
      });

      test('should deserialize from JSON correctly', () {
        final json = paymentIntent.toJson();
        final deserialized = PaymentIntent.fromJson(json);

        expect(deserialized.id, paymentIntent.id);
        expect(deserialized.clientSecret, paymentIntent.clientSecret);
        expect(deserialized.amount, paymentIntent.amount);
        expect(deserialized.currency, paymentIntent.currency);
        expect(deserialized.status, paymentIntent.status);
      });
    });

    group('Equality', () {
      test('should be equal when all properties match', () {
        final intent2 = paymentIntent.copyWith();
        expect(paymentIntent, equals(intent2));
      });

      test('should not be equal when properties differ', () {
        final intent2 = paymentIntent.copyWith(
          status: PaymentStatus.completed,
        );
        expect(paymentIntent, isNot(equals(intent2)));
      });
    });

    group('Copy With', () {
      test('should create copy with updated fields', () {
        final updated = paymentIntent.copyWith(
          status: PaymentStatus.completed,
          updatedAt: testDate.add(const Duration(hours: 1)),
          paymentMethodId: 'pm_123',
        );

        expect(updated.status, PaymentStatus.completed);
        expect(updated.updatedAt, isNotNull);
        expect(updated.paymentMethodId, 'pm_123');
        expect(updated.id, paymentIntent.id); // Unchanged
      });
    });
  });
}

