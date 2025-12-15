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
import '../../helpers/platform_channel_helper.dart';

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

    // Removed: Property assignment tests
    // Payment service partnership tests focus on business logic (partnership checking, revenue split calculation, payment distribution), not property assignment

    group('hasPartnership', () {
      test(
          'should return true if event has partnership, return false if event has no partnership, or return false if partnership service not available',
          () async {
        // Test business logic: partnership checking
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => [testPartnership]);
        final hasPartnership1 = await service.hasPartnership('event-123');
        expect(hasPartnership1, isTrue);

        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []);
        final hasPartnership2 = await service.hasPartnership('event-123');
        expect(hasPartnership2, isFalse);

        final serviceWithoutPartnership = PaymentService(
          mockStripeService,
          mockEventService,
        );
        final hasPartnership3 =
            await serviceWithoutPartnership.hasPartnership('event-123');
        expect(hasPartnership3, isFalse);
      });
    });

    group('calculatePartnershipRevenueSplit', () {
      test(
          'should calculate revenue split for partnership event, throw exception if partnership services not available, throw exception if no partnership found, or use existing revenue split if available',
          () async {
        // Test business logic: revenue split calculation
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => [testPartnership]);
        when(mockRevenueSplitService.calculateFromPartnership(
          partnershipId: 'partnership-123',
          totalAmount: 100.00,
          ticketsSold: 4,
        )).thenAnswer((_) async => testRevenueSplit);
        final revenueSplit1 = await service.calculatePartnershipRevenueSplit(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 4,
        );
        expect(revenueSplit1, isA<RevenueSplit>());
        expect(revenueSplit1.eventId, equals('event-123'));
        expect(revenueSplit1.partnershipId, equals('partnership-123'));
        expect(revenueSplit1.parties, hasLength(2));
        expect(revenueSplit1.parties[0].partyId, equals('user-123'));
        expect(revenueSplit1.parties[1].partyId, equals('business-123'));

        final serviceWithoutServices = PaymentService(
          mockStripeService,
          mockEventService,
        );
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

        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []);
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
        final revenueSplit2 = await service.calculatePartnershipRevenueSplit(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 4,
        );
        expect(revenueSplit2, isNotNull);
        verify(mockRevenueSplitService.getRevenueSplit('split-123')).called(1);
      });
    });

    group('distributePartnershipPayment', () {
      test(
          'should distribute payment to partnership parties, throw exception if payment not found, or throw exception if partnership not found',
          () async {
        // Test business logic: payment distribution
        final payment1 = Payment(
          id: 'payment-123',
          eventId: 'event-123',
          userId: 'user-456',
          amount: 100.00,
          status: PaymentStatus.completed,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        service.upsertPaymentForTests(payment1);
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipById('partnership-123'))
            .thenAnswer((_) async =>
                testPartnership.copyWith(revenueSplitId: 'split-123'));
        when(mockRevenueSplitService.getRevenueSplit(any))
            .thenAnswer((_) async => testRevenueSplit);
        when(mockRevenueSplitService.distributePayments(
          revenueSplitId: anyNamed('revenueSplitId'),
          eventEndTime: anyNamed('eventEndTime'),
        )).thenAnswer((_) async => {
              'user-123': 43.50,
              'business-123': 43.50,
            });
        final distribution1 = await service.distributePartnershipPayment(
          paymentId: 'payment-123',
          partnershipId: 'partnership-123',
        );
        expect(distribution1, isA<Map<String, double>>());
        expect(distribution1['user-123'], equals(43.50));
        expect(distribution1['business-123'], equals(43.50));

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

        final payment2 = Payment(
          id: 'payment-456',
          eventId: 'event-123',
          userId: 'user-456',
          amount: 100.00,
          status: PaymentStatus.completed,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        service.upsertPaymentForTests(payment2);
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipById('partnership-123'))
            .thenAnswer((_) async => null);
        expect(
          () => service.distributePartnershipPayment(
            paymentId: payment2.id,
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
      test(
          'should use partnership revenue split for partnership events, or use solo revenue split for non-partnership events',
          () async {
        // Test business logic: ticket purchase with partnership handling
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
          amount: 10000,
          currency: 'usd',
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) async => 'pi_test123_secret');
        final result1 = await service.purchaseEventTicket(
          eventId: 'event-123',
          userId: 'user-456',
          ticketPrice: 25.00,
          quantity: 4,
        );
        expect(result1.isSuccess, isTrue);
        expect(result1.revenueSplit, isNotNull);
        expect(result1.revenueSplit?.partnershipId, equals('partnership-123'));
        expect(result1.revenueSplit?.parties, hasLength(2));
        verify(mockRevenueSplitService.calculateFromPartnership(
          partnershipId: 'partnership-123',
          totalAmount: 100.00,
          ticketsSold: 4,
        )).called(1);

        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []);
        final result2 = await service.purchaseEventTicket(
          eventId: 'event-123',
          userId: 'user-789',
          ticketPrice: 25.00,
          quantity: 4,
        );
        expect(result2.isSuccess, isTrue);
        expect(result2.revenueSplit, isNotNull);
        expect(result2.revenueSplit?.partnershipId, isNull);
        expect(result2.revenueSplit?.parties, isEmpty);
        verifyNever(mockRevenueSplitService.calculateFromPartnership(
          partnershipId: anyNamed('partnershipId'),
          totalAmount: anyNamed('totalAmount'),
          ticketsSold: anyNamed('ticketsSold'),
        ));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
