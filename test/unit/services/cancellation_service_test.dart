import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/cancellation_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/services/revenue_split_service.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/payment.dart';
import 'package:spots/core/models/cancellation.dart';
import 'package:spots/core/models/cancellation_initiator.dart';
import 'package:spots/core/models/refund_status.dart';
import 'package:spots/core/models/payment_status.dart';

import 'cancellation_service_test.mocks.dart';

@GenerateMocks([
  ExpertiseEventService,
  PaymentService,
  RevenueSplitService,
])
void main() {
  group('CancellationService', () {
    late CancellationService service;
    late MockExpertiseEventService mockEventService;
    late MockPaymentService mockPaymentService;
    late MockRevenueSplitService mockRevenueSplitService;
    
    late ExpertiseEvent testEvent;
    late Payment testPayment;

    setUp(() {
      mockEventService = MockExpertiseEventService();
      mockPaymentService = MockPaymentService();
      mockRevenueSplitService = MockRevenueSplitService();
      
      service = CancellationService(
        eventService: mockEventService,
        paymentService: mockPaymentService,
        revenueSplitService: mockRevenueSplitService,
      );

      testEvent = ExpertiseEvent(
        id: 'event-123',
        host: UnifiedUser(
          id: 'host-123',
          name: 'Test Host',
        ),
        title: 'Test Event',
        description: 'Test Description',
        startTime: DateTime.now().add(const Duration(days: 5)),
        endTime: DateTime.now().add(const Duration(days: 5, hours: 2)),
        maxAttendees: 50,
        attendeeCount: 10,
        eventType: ExpertiseEventType.workshop,
        isPaid: true,
        price: 25.00,
        location: 'Test Location',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
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

    group('attendeeCancelTicket', () {
      test('should create cancellation and process refund for valid cancellation', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPaymentService.getPaymentForEventAndUser('event-123', 'user-456'))
            .thenAnswer((_) => testPayment);

        // Act
        final cancellation = await service.attendeeCancelTicket(
          eventId: 'event-123',
          attendeeId: 'user-456',
          paymentId: 'payment-123',
        );

        // Assert
        expect(cancellation, isA<Cancellation>());
        expect(cancellation.eventId, equals('event-123'));
        expect(cancellation.initiator, equals(CancellationInitiator.attendee));
        expect(cancellation.refundStatus, equals(RefundStatus.pending));
        verify(mockEventService.getEventById('event-123')).called(1);
      });

      test('should throw exception if event not found', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.attendeeCancelTicket(
            eventId: 'event-123',
            attendeeId: 'user-456',
            paymentId: 'payment-123',
          ),
          throwsException,
        );
      });
    });

    group('hostCancelEvent', () {
      test('should create cancellation and process batch refunds', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPaymentService.getPaymentsForEvent('event-123'))
            .thenAnswer((_) => [testPayment]);

        // Act
        final cancellation = await service.hostCancelEvent(
          eventId: 'event-123',
          hostId: 'host-123',
          reason: 'Host cancellation',
        );

        // Assert
        expect(cancellation, isA<Cancellation>());
        expect(cancellation.eventId, equals('event-123'));
        expect(cancellation.initiator, equals(CancellationInitiator.host));
        expect(cancellation.reason, equals('Host cancellation'));
        verify(mockEventService.getEventById('event-123')).called(1);
      });
    });

    group('emergencyCancelEvent', () {
      test('should create emergency cancellation with full refund', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPaymentService.getPaymentsForEvent('event-123'))
            .thenAnswer((_) => [testPayment]);

        // Act
        final cancellation = await service.emergencyCancelEvent(
          eventId: 'event-123',
          reason: 'Weather emergency',
          weatherRelated: true,
        );

        // Assert
        expect(cancellation, isA<Cancellation>());
        expect(cancellation.eventId, equals('event-123'));
        expect(cancellation.initiator, equals(CancellationInitiator.weather));
        expect(cancellation.reason, equals('Weather emergency'));
        verify(mockEventService.getEventById('event-123')).called(1);
      });
    });

    group('getCancellationById', () {
      test('should return cancellation if exists', () async {
        // Arrange
        final testCancellation = await service.attendeeCancelTicket(
          eventId: 'event-123',
          attendeeId: 'user-456',
          paymentId: 'payment-123',
        );
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPaymentService.getPaymentForEventAndUser('event-123', 'user-456'))
            .thenAnswer((_) => testPayment);

        // Act
        final cancellation = await service.getCancellationById(testCancellation.id);

        // Assert
        expect(cancellation, isNotNull);
        expect(cancellation?.id, equals(testCancellation.id));
      });

      test('should return null if cancellation not found', () async {
        // Act
        final cancellation = await service.getCancellationById('non-existent');

        // Assert
        expect(cancellation, isNull);
      });
    });

    group('getCancellationsForEvent', () {
      test('should return all cancellations for event', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPaymentService.getPaymentForEventAndUser('event-123', 'user-456'))
            .thenAnswer((_) => testPayment);
        when(mockPaymentService.getPaymentsForEvent('event-123'))
            .thenAnswer((_) => [testPayment]);

        await service.attendeeCancelTicket(
          eventId: 'event-123',
          attendeeId: 'user-456',
          paymentId: 'payment-123',
        );
        await service.hostCancelEvent(
          eventId: 'event-123',
          hostId: 'host-123',
          reason: 'Host cancellation',
        );

        // Act
        final cancellations = await service.getCancellationsForEvent('event-123');

        // Assert
        expect(cancellations, isNotEmpty);
        expect(cancellations.length, greaterThanOrEqualTo(2));
        expect(cancellations.every((c) => c.eventId == 'event-123'), isTrue);
      });
    });
  });
}

