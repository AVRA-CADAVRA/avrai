import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/revenue_split_service.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/services/sponsorship_service.dart';
import 'package:spots/core/services/product_tracking_service.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/sponsorship.dart';

import 'revenue_split_service_brand_test.mocks.dart';

@GenerateMocks([
  PartnershipService,
  SponsorshipService,
  ProductTrackingService,
])
void main() {
  group('RevenueSplitService Brand Sponsorship Tests', () {
    late RevenueSplitService service;
    late MockPartnershipService mockPartnershipService;
    late MockSponsorshipService mockSponsorshipService;
    late MockProductTrackingService mockProductTrackingService;
    late EventPartnership testPartnership;
    late Sponsorship testSponsorship1;
    late Sponsorship testSponsorship2;

    setUp(() {
      mockPartnershipService = MockPartnershipService();
      mockSponsorshipService = MockSponsorshipService();
      mockProductTrackingService = MockProductTrackingService();

      service = RevenueSplitService(
        partnershipService: mockPartnershipService,
        sponsorshipService: mockSponsorshipService,
        productTrackingService: mockProductTrackingService,
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

      testSponsorship1 = Sponsorship(
        id: 'sponsorship-1',
        eventId: 'event-123',
        brandId: 'brand-1',
        type: SponsorshipType.financial,
        contributionAmount: 500.00,
        status: SponsorshipStatus.approved,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testSponsorship2 = Sponsorship(
        id: 'sponsorship-2',
        eventId: 'event-123',
        brandId: 'brand-2',
        type: SponsorshipType.product,
        productValue: 300.00,
        status: SponsorshipStatus.approved,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    group('calculateNWayBrandSplit', () {
      test('should calculate N-way brand split with partnership and brands', () async {
        // Arrange
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => [testPartnership]);
        when(mockSponsorshipService.getSponsorshipsForEvent('event-123'))
            .thenAnswer((_) async => [testSponsorship1, testSponsorship2]);

        // Act
        final revenueSplit = await service.calculateNWayBrandSplit(
          eventId: 'event-123',
          totalAmount: 1000.00,
          ticketsSold: 20,
        );

        // Assert
        expect(revenueSplit, isA<RevenueSplit>());
        expect(revenueSplit.eventId, equals('event-123'));
        expect(revenueSplit.parties.length, greaterThanOrEqualTo(4)); // user + business + 2 brands
        expect(revenueSplit.parties.any((p) => p.partyId == 'user-123'), isTrue);
        expect(revenueSplit.parties.any((p) => p.partyId == 'business-123'), isTrue);
        expect(revenueSplit.parties.any((p) => p.partyId == 'brand-1'), isTrue);
        expect(revenueSplit.parties.any((p) => p.partyId == 'brand-2'), isTrue);
      });

      test('should use provided brand percentages', () async {
        // Arrange
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => [testPartnership]);
        when(mockSponsorshipService.getSponsorshipsForEvent('event-123'))
            .thenAnswer((_) async => [testSponsorship1, testSponsorship2]);

        // Act
        final revenueSplit = await service.calculateNWayBrandSplit(
          eventId: 'event-123',
          totalAmount: 1000.00,
          ticketsSold: 20,
          brandPercentages: {
            'brand-1': 15.0,
            'brand-2': 10.0,
          },
        );

        // Assert
        final brand1Party = revenueSplit.parties.firstWhere(
          (p) => p.partyId == 'brand-1',
        );
        final brand2Party = revenueSplit.parties.firstWhere(
          (p) => p.partyId == 'brand-2',
        );
        expect(brand1Party.percentage, equals(15.0));
        expect(brand2Party.percentage, equals(10.0));
      });

      test('should throw exception if SponsorshipService not available', () async {
        // Arrange
        final serviceWithoutSponsorship = RevenueSplitService(
          partnershipService: mockPartnershipService,
        );

        // Act & Assert
        expect(
          () => serviceWithoutSponsorship.calculateNWayBrandSplit(
            eventId: 'event-123',
            totalAmount: 1000.00,
            ticketsSold: 20,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('SponsorshipService not available'),
          )),
        );
      });

      test('should calculate equal split among brands if percentages not provided', () async {
        // Arrange
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => [testPartnership]);
        when(mockSponsorshipService.getSponsorshipsForEvent('event-123'))
            .thenAnswer((_) async => [testSponsorship1, testSponsorship2]);

        // Act
        final revenueSplit = await service.calculateNWayBrandSplit(
          eventId: 'event-123',
          totalAmount: 1000.00,
          ticketsSold: 20,
        );

        // Assert
        // Partnership takes 50% (25% user + 25% business), brands split remaining 50%
        final brandParties = revenueSplit.parties.where(
          (p) => p.type == SplitPartyType.sponsor,
        ).toList();
        expect(brandParties.length, equals(2));
        // Each brand should get equal share of remaining percentage
        expect(brandParties[0].percentage, closeTo(brandParties[1].percentage, 0.01));
      });
    });

    group('calculateProductSalesSplit', () {
      test('should calculate product sales revenue split', () async {
        // Arrange
        final productTracking = ProductTracking(
          id: 'tracking-123',
          sponsorshipId: 'sponsorship-1',
          productName: 'Coffee Beans',
          quantityProvided: 100,
          quantitySold: 50,
          unitPrice: 15.00,
          totalSales: 750.00,
          platformFee: 75.00,
          sales: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockProductTrackingService.getProductTrackingById('tracking-123'))
            .thenAnswer((_) async => productTracking);
        when(mockSponsorshipService.getSponsorshipById('sponsorship-1'))
            .thenAnswer((_) async => testSponsorship1);

        // Act
        final revenueSplit = await service.calculateProductSalesSplit(
          productTrackingId: 'tracking-123',
          totalSales: 750.00,
        );

        // Assert
        expect(revenueSplit, isA<RevenueSplit>());
        expect(revenueSplit.totalAmount, equals(750.00));
        expect(revenueSplit.parties, hasLength(1));
        expect(revenueSplit.parties[0].partyId, equals('brand-1'));
        expect(revenueSplit.parties[0].type, equals(SplitPartyType.sponsor));
      });

      test('should throw exception if product tracking not found', () async {
        // Arrange
        when(mockProductTrackingService.getProductTrackingById('tracking-123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.calculateProductSalesSplit(
            productTrackingId: 'tracking-123',
            totalSales: 750.00,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Product tracking not found'),
          )),
        );
      });

      test('should calculate platform and processing fees correctly', () async {
        // Arrange
        final productTracking = ProductTracking(
          id: 'tracking-123',
          sponsorshipId: 'sponsorship-1',
          productName: 'Coffee Beans',
          quantityProvided: 100,
          quantitySold: 50,
          unitPrice: 15.00,
          totalSales: 750.00,
          platformFee: 75.00,
          sales: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockProductTrackingService.getProductTrackingById('tracking-123'))
            .thenAnswer((_) async => productTracking);
        when(mockSponsorshipService.getSponsorshipById('sponsorship-1'))
            .thenAnswer((_) async => testSponsorship1);

        // Act
        final revenueSplit = await service.calculateProductSalesSplit(
          productTrackingId: 'tracking-123',
          totalSales: 750.00,
        );

        // Assert
        expect(revenueSplit.platformFee, equals(75.00)); // 10% of 750.00
        expect(revenueSplit.processingFee, closeTo(22.05, 0.01)); // (750 * 0.029) + (0.30 * 50)
      });
    });

    group('calculateHybridSplit', () {
      test('should calculate hybrid split (cash + product)', () async {
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
            partyId: 'brand-1',
            type: SplitPartyType.sponsor,
            percentage: 25.0,
            name: 'Brand',
          ),
        ];

        // Act
        final splits = await service.calculateHybridSplit(
          eventId: 'event-123',
          cashAmount: 1000.00,
          productSalesAmount: 500.00,
          ticketsSold: 20,
          parties: parties,
        );

        // Assert
        expect(splits, isA<Map<String, RevenueSplit>>());
        expect(splits['cash'], isNotNull);
        expect(splits['product'], isNotNull);
        expect(splits['cash']?.totalAmount, equals(1000.00));
        expect(splits['product']?.totalAmount, equals(500.00));
      });

      test('should distribute product sales to sponsor parties', () async {
        // Arrange
        final parties = [
          SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 40.0,
            name: 'User',
          ),
          SplitParty(
            partyId: 'brand-1',
            type: SplitPartyType.sponsor,
            percentage: 60.0,
            name: 'Brand',
          ),
        ];

        // Act
        final splits = await service.calculateHybridSplit(
          eventId: 'event-123',
          cashAmount: 1000.00,
          productSalesAmount: 500.00,
          ticketsSold: 20,
          parties: parties,
        );

        // Assert
        final productSplit = splits['product'];
        expect(productSplit, isNotNull);
        // Product sales should be distributed to sponsor parties
        final sponsorParties = productSplit!.parties.where(
          (p) => p.type == SplitPartyType.sponsor,
        ).toList();
        expect(sponsorParties, isNotEmpty);
      });
    });
  });
}

