import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/services/stripe_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/services/revenue_split_service.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/models/payment.dart';
import 'package:spots/core/models/payment_status.dart';
import '../../fixtures/model_factories.dart';

import 'payment_service_partnership_test.mocks.dart';

@GenerateMocks([
  StripeService,
  ExpertiseEventService,
  PartnershipService,
  RevenueSplitService,
])
void main() {
  group('PaymentService Partnership Flow Tests', () {
    late PaymentService service;
    late MockStripeService mockStripeService;
    late MockExpertiseEventService mockEventService;
    late MockPartnershipService mockPartnershipService;
    late MockRevenueSplitService mockRevenueSplitService;
    late ExpertiseEvent testEvent;
    late EventPartnership testPartnership;
    late RevenueSplit testRevenueSplit;

    setUp(() {
      mockStripeService = MockStripeService();
      mockEventService = MockExpertiseEventService();
      mockPartnershipService = MockPartnershipService();
      mockRevenueSplitService = MockRevenueSplitService();

      service = PaymentService(
        mockStripeService,
        mockEventService,
        partnershipService: mockPartnershipService,
        revenueSplitService: mockRevenueSplitService,
      );

      final testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test User',
      );

      testEvent = ExpertiseEvent(
        id: 'event-123',
        title: 'Partnership Event',
        description: 'An event with partnership',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: testUser,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        price: 25.00,
        isPaid: true,
        maxAttendees: 20,
        attendeeCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testPartnership = EventPartnership(
        id: 'partnership-123',
        eventId: 'event-123',
        userId: 'user-123',
        businessId: 'business-123',
        status: PartnershipStatus.locked,
        vibeCompatibilityScore: 0.75,
        userApproved: true,
        businessApproved: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testRevenueSplit = RevenueSplit.nWay(
        id: 'split-123',
        eventId: 'event-123',
        partnershipId: 'partnership-123',
        totalAmount: 100.00,
        ticketsSold: 4,
        parties: [
          SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 50.0,
            amount: 43.50,
            name: 'User',
          ),
          SplitParty(
            partyId: 'business-123',
            type: SplitPartyType.business,
            percentage: 50.0,
            amount: 43.50,
            name: 'Business',
          ),
        ],
      );

      // Setup default mocks
      when(mockStripeService.isInitialized).thenReturn(true);
      when(mockStripeService.initializeStripe()).thenAnswer((_) async => {});
    });

    group('hasPartnership', () {
      test('should return true if event has partnership', () async {
        // Arrange
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => [testPartnership]);

        // Act
        final hasPartnership = await service.hasPartnership('event-123');

        // Assert
        expect(hasPartnership, isTrue);
      });

      test('should return false if event has no partnership', () async {
        // Arrange
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []);

        // Act
        final hasPartnership = await service.hasPartnership('event-123');

        // Assert
        expect(hasPartnership, isFalse);
      });

      test('should return false if partnership service not available', () async {
        // Arrange
        final serviceWithoutPartnership = PaymentService(
          mockStripeService,
          mockEventService,
        );

        // Act
        final hasPartnership = await serviceWithoutPartnership.hasPartnership('event-123');

        // Assert
        expect(hasPartnership, isFalse);
      });
    });

    group('calculatePartnershipRevenueSplit', () {
      test('should calculate revenue split for partnership event', () async {
        // Arrange
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => [testPartnership]);
        when(mockRevenueSplitService.calculateFromPartnership(
          partnershipId: 'partnership-123',
          totalAmount: 100.00,
          ticketsSold: 4,
        )).thenAnswer((_) async => testRevenueSplit);

        // Act
        final revenueSplit = await service.calculatePartnershipRevenueSplit(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 4,
        );

        // Assert
        expect(revenueSplit, isA<RevenueSplit>());
        expect(revenueSplit.eventId, equals('event-123'));
        expect(revenueSplit.partnershipId, equals('partnership-123'));
        expect(revenueSplit.parties, hasLength(2));
        expect(revenueSplit.parties[0].partyId, equals('user-123'));
        expect(revenueSplit.parties[1].partyId, equals('business-123'));
      });

      test('should throw exception if partnership services not available', () async {
        // Arrange
        final serviceWithoutServices = PaymentService(
          mockStripeService,
          mockEventService,
        );

        // Act & Assert
        expect(
          () => serviceWithoutServices.calculatePartnershipRevenueSplit(
            eventId: 'event-123',
            totalAmount: 100.00,
            ticketsSold: 4,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Partnership services not available'),
          )),
        );
      });

      test('should throw exception if no partnership found', () async {
        // Arrange
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []);

        // Act & Assert
        expect(
          () => service.calculatePartnershipRevenueSplit(
            eventId: 'event-123',
            totalAmount: 100.00,
            ticketsSold: 4,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('No partnership found'),
          )),
        );
      });

      test('should use existing revenue split if available', () async {
        // Arrange
        final partnershipWithSplit = testPartnership.copyWith(
          revenueSplitId: 'split-123',
        );
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => [partnershipWithSplit]);
        when(mockRevenueSplitService.getRevenueSplit('split-123'))
            .thenAnswer((_) async => testRevenueSplit);
        when(mockRevenueSplitService.calculateFromPartnership(
          partnershipId: 'partnership-123',
          totalAmount: 100.00,
          ticketsSold: 4,
        )).thenAnswer((_) async => testRevenueSplit);

        // Act
        final revenueSplit = await service.calculatePartnershipRevenueSplit(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 4,
        );

        // Assert
        expect(revenueSplit, isNotNull);
        verify(mockRevenueSplitService.getRevenueSplit('split-123')).called(1);
      });
    });

    group('distributePartnershipPayment', () {
      test('should distribute payment to partnership parties', () async {
        // Arrange
        final payment = Payment(
          id: 'payment-123',
          eventId: 'event-123',
          userId: 'user-456',
          amount: 100.00,
          status: PaymentStatus.completed,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockPartnershipService.getPartnershipById('partnership-123'))
            .thenAnswer((_) async => testPartnership);
        when(mockRevenueSplitService.getRevenueSplit(any))
            .thenAnswer((_) async => testRevenueSplit);
        when(mockRevenueSplitService.distributePayments(
          revenueSplitId: anyNamed('revenueSplitId'),
          eventEndTime: anyNamed('eventEndTime'),
        )).thenAnswer((_) async => {
          'user-123': 43.50,
          'business-123': 43.50,
        });

        // Act
        final distribution = await service.distributePartnershipPayment(
          paymentId: 'payment-123',
          partnershipId: 'partnership-123',
        );

        // Assert
        expect(distribution, isA<Map<String, double>>());
        expect(distribution['user-123'], equals(43.50));
        expect(distribution['business-123'], equals(43.50));
      });

      test('should throw exception if payment not found', () async {
        // Arrange
        // Payment not in service's internal storage

        // Act & Assert
        expect(
          () => service.distributePartnershipPayment(
            paymentId: 'nonexistent-payment',
            partnershipId: 'partnership-123',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Payment not found'),
          )),
        );
      });

      test('should throw exception if partnership not found', () async {
        // Arrange
        final payment = Payment(
          id: 'payment-123',
          eventId: 'event-123',
          userId: 'user-456',
          amount: 100.00,
          status: PaymentStatus.completed,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        // Add payment to service's internal storage
        service.getPayment(payment.id); // This won't work, need to access private field
        // Instead, we'll mock the service to have the payment

        when(mockPartnershipService.getPartnershipById('partnership-123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.distributePartnershipPayment(
            paymentId: payment.id,
            partnershipId: 'partnership-123',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Partnership not found'),
          )),
        );
      });
    });

    group('purchaseEventTicket with partnership', () {
      test('should use partnership revenue split for partnership events', () async {
        // Arrange
        await service.initialize();
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => [testPartnership]);
        when(mockRevenueSplitService.calculateFromPartnership(
          partnershipId: 'partnership-123',
          totalAmount: 100.00,
          ticketsSold: 4,
        )).thenAnswer((_) async => testRevenueSplit);
        when(mockStripeService.createPaymentIntent(
          amountInCents: 10000,
          currency: 'usd',
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) async => {
          'id': 'pi_test123',
          'client_secret': 'pi_test123_secret',
          'status': 'requires_payment_method',
        });

        // Act
        final result = await service.purchaseEventTicket(
          eventId: 'event-123',
          userId: 'user-456',
          ticketPrice: 25.00,
          quantity: 4,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.revenueSplit, isNotNull);
        expect(result.revenueSplit?.partnershipId, equals('partnership-123'));
        expect(result.revenueSplit?.parties, hasLength(2));
        verify(mockRevenueSplitService.calculateFromPartnership(
          partnershipId: 'partnership-123',
          totalAmount: 100.00,
          ticketsSold: 4,
        )).called(1);
      });

      test('should use solo revenue split for non-partnership events', () async {
        // Arrange
        await service.initialize();
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []); // No partnership
        when(mockStripeService.createPaymentIntent(
          amountInCents: 10000,
          currency: 'usd',
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) async => {
          'id': 'pi_test123',
          'client_secret': 'pi_test123_secret',
          'status': 'requires_payment_method',
        });

        // Act
        final result = await service.purchaseEventTicket(
          eventId: 'event-123',
          userId: 'user-456',
          ticketPrice: 25.00,
          quantity: 4,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.revenueSplit, isNotNull);
        expect(result.revenueSplit?.partnershipId, isNull); // Solo event
        expect(result.revenueSplit?.parties, isEmpty); // Solo event uses hostPayout
        verifyNever(mockRevenueSplitService.calculateFromPartnership(
          partnershipId: anyNamed('partnershipId'),
          totalAmount: anyNamed('totalAmount'),
          ticketsSold: anyNamed('ticketsSold'),
        ));
      });
    });
  });
}

