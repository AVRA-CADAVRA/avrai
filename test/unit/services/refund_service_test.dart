import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/refund_service.dart';
import 'package:spots/core/services/stripe_service.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/models/payment.dart';
import 'package:spots/core/models/refund_distribution.dart';
import 'package:spots/core/models/payment_status.dart';

import 'refund_service_test.mocks.dart';

@GenerateMocks([
  StripeService,
  PaymentService,
])
void main() {
  group('RefundService', () {
    late RefundService service;
    late MockStripeService mockStripeService;
    late MockPaymentService mockPaymentService;
    
    late Payment testPayment;

    setUp(() {
      mockStripeService = MockStripeService();
      mockPaymentService = MockPaymentService();
      
      service = RefundService(
        stripeService: mockStripeService,
        paymentService: mockPaymentService,
      );

      testPayment = Payment(
        id: 'payment-123',
        eventId: 'event-123',
        userId: 'user-456',
        amount: 25.00,
        status: PaymentStatus.completed,
        stripePaymentIntentId: 'pi_test123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    group('processRefund', () {
      test('should process refund successfully', () async {
        // Arrange
        when(mockStripeService.processRefund(
          paymentIntentId: 'pi_test123',
          amount: 2500,
          reason: anyNamed('reason'),
        )).thenAnswer((_) async => 're_test123');
        when(mockPaymentService.getPayment('payment-123'))
            .thenReturn(testPayment);

        // Act
        final result = await service.processRefund(
          paymentId: 'payment-123',
          amount: 25.00,
          cancellationId: 'cancellation-123',
        );

        // Assert
        expect(result, isA<List<RefundDistribution>>());
        expect(result.length, equals(1));
        expect(result.first.stripeRefundId, isNotNull);
        expect(result.first.completedAt, isNotNull);
        verify(mockStripeService.processRefund(
          paymentIntentId: 'pi_test123',
          amount: 2500,
          reason: anyNamed('reason'),
        )).called(1);
      });

      test('should handle refund failure', () async {
        // Arrange
        when(mockStripeService.processRefund(
          paymentIntentId: 'pi_test123',
          amount: 2500,
          reason: anyNamed('reason'),
        )).thenThrow(Exception('Stripe refund failed'));
        when(mockPaymentService.getPayment('payment-123'))
            .thenReturn(testPayment);

        // Act & Assert
        expect(
          () => service.processRefund(
            paymentId: 'payment-123',
            amount: 25.00,
            cancellationId: 'cancellation-123',
          ),
          throwsException,
        );
      });
    });

    group('processBatchRefunds', () {
      test('should process multiple refunds successfully', () async {
        // Arrange
        final payments = [
          testPayment,
          Payment(
            id: 'payment-456',
            eventId: 'event-123',
            userId: 'user-789',
            amount: 30.00,
            status: PaymentStatus.completed,
            stripePaymentIntentId: 'pi_test456',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockStripeService.processRefund(
          paymentIntentId: anyNamed('paymentIntentId'),
          amount: anyNamed('amount'),
          reason: anyNamed('reason'),
        )).thenAnswer((_) async => 're_test123');
        when(mockPaymentService.getPayment(any))
            .thenAnswer((invocation) => payments.firstWhere(
              (p) => p.id == invocation.positionalArguments[0],
              orElse: () => payments.first,
            ));

        // Act
        final results = await service.processBatchRefunds(
          payments: payments,
          cancellationId: 'cancellation-123',
          fullRefund: true,
        );

        // Assert
        expect(results, hasLength(2));
        expect(results.every((r) => r.completedAt != null), isTrue);
        verify(mockStripeService.processRefund(
          paymentIntentId: anyNamed('paymentIntentId'),
          amount: anyNamed('amount'),
          reason: anyNamed('reason'),
        )).called(2);
      });

      test('should handle partial batch refund failures', () async {
        // Arrange
        final payments = [
          testPayment,
          Payment(
            id: 'payment-456',
            eventId: 'event-123',
            userId: 'user-789',
            amount: 30.00,
            status: PaymentStatus.completed,
            stripePaymentIntentId: 'pi_test456',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockStripeService.processRefund(
          paymentIntentId: 'pi_test123',
          amount: 2500,
          reason: anyNamed('reason'),
        )).thenAnswer((_) async => 're_test123');
        when(mockStripeService.processRefund(
          paymentIntentId: 'pi_test456',
          amount: 3000,
          reason: anyNamed('reason'),
        )).thenThrow(Exception('Refund failed'));
        when(mockPaymentService.getPayment(any))
            .thenAnswer((invocation) => payments.firstWhere(
              (p) => p.id == invocation.positionalArguments[0],
              orElse: () => payments.first,
            ));

        // Act
        final results = await service.processBatchRefunds(
          payments: payments,
          cancellationId: 'cancellation-123',
          fullRefund: true,
        );

        // Assert
        expect(results, hasLength(1)); // Only first succeeds, second fails and is skipped
        expect(results[0].completedAt, isNotNull);
      });
    });
  });
}

