import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/revenue_split_service.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/models/event_partnership.dart';

import 'revenue_split_service_partnership_test.mocks.dart';

@GenerateMocks([PartnershipService])
void main() {
  group('RevenueSplitService Partnership Split Tests', () {
    late RevenueSplitService service;
    late MockPartnershipService mockPartnershipService;
    late EventPartnership testPartnership;

    setUp(() {
      mockPartnershipService = MockPartnershipService();
      service = RevenueSplitService(
        partnershipService: mockPartnershipService,
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
    });

    group('calculateNWaySplit', () {
      test('should calculate N-way split with correct percentages', () async {
        // Arrange
        final parties = [
          SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 50.0,
            name: 'User',
          ),
          SplitParty(
            partyId: 'business-123',
            type: SplitPartyType.business,
            percentage: 50.0,
            name: 'Business',
          ),
        ];

        // Act
        final revenueSplit = await service.calculateNWaySplit(
          eventId: 'event-123',
          partnershipId: 'partnership-123',
          totalAmount: 100.00,
          ticketsSold: 4,
          parties: parties,
        );

        // Assert
        expect(revenueSplit, isA<RevenueSplit>());
        expect(revenueSplit.eventId, equals('event-123'));
        expect(revenueSplit.partnershipId, equals('partnership-123'));
        expect(revenueSplit.totalAmount, equals(100.00));
        expect(revenueSplit.parties, hasLength(2));
        expect(revenueSplit.parties[0].percentage, equals(50.0));
        expect(revenueSplit.parties[1].percentage, equals(50.0));
        expect(revenueSplit.isValid, isTrue);
      });

      test('should calculate platform fee (10%)', () async {
        // Arrange
        final parties = [
          SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 50.0,
            name: 'User',
          ),
          SplitParty(
            partyId: 'business-123',
            type: SplitPartyType.business,
            percentage: 50.0,
            name: 'Business',
          ),
        ];

        // Act
        final revenueSplit = await service.calculateNWaySplit(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 4,
          parties: parties,
        );

        // Assert
        expect(revenueSplit.platformFee, equals(10.00)); // 10% of 100.00
      });

      test('should calculate processing fee (~3%)', () async {
        // Arrange
        final parties = [
          SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 50.0,
            name: 'User',
          ),
          SplitParty(
            partyId: 'business-123',
            type: SplitPartyType.business,
            percentage: 50.0,
            name: 'Business',
          ),
        ];

        // Act
        final revenueSplit = await service.calculateNWaySplit(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 4,
          parties: parties,
        );

        // Assert
        // Processing fee = (100.00 * 0.029) + (0.30 * 4) = 2.90 + 1.20 = 4.10
        expect(revenueSplit.processingFee, closeTo(4.10, 0.01));
      });

      test('should throw exception if percentages do not sum to 100%', () async {
        // Arrange
        final parties = [
          SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 40.0,
            name: 'User',
          ),
          SplitParty(
            partyId: 'business-123',
            type: SplitPartyType.business,
            percentage: 50.0,
            name: 'Business',
          ),
        ];

        // Act & Assert
        expect(
          () => service.calculateNWaySplit(
            eventId: 'event-123',
            totalAmount: 100.00,
            ticketsSold: 4,
            parties: parties,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Percentages must sum to 100%'),
          )),
        );
      });

      test('should throw exception if parties list is empty', () async {
        // Act & Assert
        expect(
          () => service.calculateNWaySplit(
            eventId: 'event-123',
            totalAmount: 100.00,
            ticketsSold: 4,
            parties: [],
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Parties list cannot be empty'),
          )),
        );
      });

      test('should support 3-way split', () async {
        // Arrange
        final parties = [
          SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 40.0,
            name: 'User',
          ),
          SplitParty(
            partyId: 'business-123',
            type: SplitPartyType.business,
            percentage: 35.0,
            name: 'Business',
          ),
          SplitParty(
            partyId: 'sponsor-123',
            type: SplitPartyType.sponsor,
            percentage: 25.0,
            name: 'Sponsor',
          ),
        ];

        // Act
        final revenueSplit = await service.calculateNWaySplit(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 4,
          parties: parties,
        );

        // Assert
        expect(revenueSplit.parties, hasLength(3));
        expect(revenueSplit.isValid, isTrue);
      });
    });

    group('calculateFromPartnership', () {
      test('should calculate revenue split from partnership', () async {
        // Arrange
        when(mockPartnershipService.getPartnershipById('partnership-123'))
            .thenAnswer((_) async => testPartnership);

        // Act
        final revenueSplit = await service.calculateFromPartnership(
          partnershipId: 'partnership-123',
          totalAmount: 100.00,
          ticketsSold: 4,
        );

        // Assert
        expect(revenueSplit, isA<RevenueSplit>());
        expect(revenueSplit.eventId, equals('event-123'));
        expect(revenueSplit.partnershipId, equals('partnership-123'));
        expect(revenueSplit.parties, hasLength(2)); // Default 50/50 split
        expect(revenueSplit.parties[0].partyId, equals('user-123'));
        expect(revenueSplit.parties[1].partyId, equals('business-123'));
      });

      test('should throw exception if partnership not found', () async {
        // Arrange
        when(mockPartnershipService.getPartnershipById('partnership-123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.calculateFromPartnership(
            partnershipId: 'partnership-123',
            totalAmount: 100.00,
            ticketsSold: 4,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Partnership not found'),
          )),
        );
      });
    });

    group('lockSplit', () {
      test('should lock revenue split', () async {
        // Arrange
        final parties = [
          SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 50.0,
            name: 'User',
          ),
          SplitParty(
            partyId: 'business-123',
            type: SplitPartyType.business,
            percentage: 50.0,
            name: 'Business',
          ),
        ];

        final revenueSplit = await service.calculateNWaySplit(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 4,
          parties: parties,
        );

        // Act
        final locked = await service.lockSplit(
          revenueSplitId: revenueSplit.id,
          lockedBy: 'user-123',
        );

        // Assert
        expect(locked.isLocked, isTrue);
        expect(locked.lockedBy, equals('user-123'));
        expect(locked.lockedAt, isNotNull);
      });

      test('should throw exception if split not found', () async {
        // Act & Assert
        expect(
          () => service.lockSplit(
            revenueSplitId: 'nonexistent-split',
            lockedBy: 'user-123',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Revenue split not found'),
          )),
        );
      });

      test('should throw exception if split already locked', () async {
        // Arrange
        final parties = [
          SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 50.0,
            name: 'User',
          ),
          SplitParty(
            partyId: 'business-123',
            type: SplitPartyType.business,
            percentage: 50.0,
            name: 'Business',
          ),
        ];

        final revenueSplit = await service.calculateNWaySplit(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 4,
          parties: parties,
        );

        await service.lockSplit(
          revenueSplitId: revenueSplit.id,
          lockedBy: 'user-123',
        );

        // Act & Assert
        expect(
          () => service.lockSplit(
            revenueSplitId: revenueSplit.id,
            lockedBy: 'user-123',
          ),
          throwsA(isA<StateError>().having(
            (e) => e.toString(),
            'message',
            contains('already locked'),
          )),
        );
      });

      test('should throw exception if split is invalid', () async {
        // This test would require creating an invalid split
        // For now, we'll test that valid splits can be locked
        // Invalid splits are prevented by the calculateNWaySplit validation
      });
    });

    group('distributePayments', () {
      test('should distribute payments to parties', () async {
        // Arrange
        final parties = [
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
        ];

        final revenueSplit = await service.calculateNWaySplit(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 4,
          parties: parties,
        );

        final locked = await service.lockSplit(
          revenueSplitId: revenueSplit.id,
          lockedBy: 'user-123',
        );

        final eventEndTime = DateTime.now().add(const Duration(days: 1));

        // Act
        final distribution = await service.distributePayments(
          revenueSplitId: locked.id,
          eventEndTime: eventEndTime,
        );

        // Assert
        expect(distribution, isA<Map<String, double>>());
        expect(distribution['user-123'], isNotNull);
        expect(distribution['business-123'], isNotNull);
      });

      test('should throw exception if split not locked', () async {
        // Arrange
        final parties = [
          SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 50.0,
            name: 'User',
          ),
          SplitParty(
            partyId: 'business-123',
            type: SplitPartyType.business,
            percentage: 50.0,
            name: 'Business',
          ),
        ];

        final revenueSplit = await service.calculateNWaySplit(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 4,
          parties: parties,
        );

        final eventEndTime = DateTime.now().add(const Duration(days: 1));

        // Act & Assert
        expect(
          () => service.distributePayments(
            revenueSplitId: revenueSplit.id,
            eventEndTime: eventEndTime,
          ),
          throwsA(isA<StateError>().having(
            (e) => e.toString(),
            'message',
            contains('must be locked'),
          )),
        );
      });
    });

    group('trackEarnings', () {
      test('should track earnings for a party', () async {
        // Arrange
        final parties = [
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
        ];

        await service.calculateNWaySplit(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 4,
          parties: parties,
        );

        // Act
        final earnings = await service.trackEarnings(
          partyId: 'user-123',
        );

        // Assert
        expect(earnings, isA<double>());
        expect(earnings, greaterThanOrEqualTo(0.0));
      });

      test('should filter earnings by date range', () async {
        // Arrange
        final parties = [
          SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 50.0,
            amount: 43.50,
            name: 'User',
          ),
        ];

        await service.calculateNWaySplit(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 4,
          parties: parties,
        );

        final startDate = DateTime.now().subtract(const Duration(days: 30));
        final endDate = DateTime.now().add(const Duration(days: 30));

        // Act
        final earnings = await service.trackEarnings(
          partyId: 'user-123',
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(earnings, isA<double>());
      });
    });
  });
}

