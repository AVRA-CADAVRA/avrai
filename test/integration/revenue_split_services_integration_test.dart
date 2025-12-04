import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/services/revenue_split_service.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/services/sponsorship_service.dart';
import 'package:spots/core/services/product_tracking_service.dart';
import '../helpers/integration_test_helpers.dart';

// Mock dependencies
class MockPartnershipService extends Mock implements PartnershipService {}
class MockSponsorshipService extends Mock implements SponsorshipService {}
class MockProductTrackingService extends Mock implements ProductTrackingService {}

/// Revenue Split Services Integration Tests
/// 
/// Agent 1: Backend & Integration (Week 12)
/// 
/// Tests service-level integration for revenue splits:
/// - N-way brand revenue splits (3+ parties)
/// - Product sales revenue splits
/// - Hybrid sponsorship splits (cash + product)
/// - Revenue split validation
/// - Payment distribution
/// 
/// **Test Scenarios:**
/// - Scenario 1: N-Way Brand Revenue Split
/// - Scenario 2: Product Sales Revenue Split
/// - Scenario 3: Hybrid Sponsorship Split
/// - Scenario 4: Revenue Split Validation
/// - Scenario 5: Payment Distribution
void main() {
  group('Revenue Split Services Integration Tests', () {
    late RevenueSplitService revenueSplitService;
    late MockPartnershipService mockPartnershipService;
    late MockSponsorshipService mockSponsorshipService;
    late MockProductTrackingService mockProductTrackingService;
    
    late DateTime testDate;
    
    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      
      mockPartnershipService = MockPartnershipService();
      mockSponsorshipService = MockSponsorshipService();
      mockProductTrackingService = MockProductTrackingService();
      
      revenueSplitService = RevenueSplitService(
        partnershipService: mockPartnershipService,
        sponsorshipService: mockSponsorshipService,
        productTrackingService: mockProductTrackingService,
      );
    });
    
    tearDown(() {
      reset(mockPartnershipService);
      reset(mockSponsorshipService);
      reset(mockProductTrackingService);
      TestHelpers.teardownTestEnvironment();
    });
    
    group('Scenario 1: N-Way Brand Revenue Split', () {
      test('should calculate N-way split with user + business + brand', () async {
        // Arrange
        when(() => mockSponsorshipService.getSponsorshipsForEvent('event-456'))
            .thenAnswer((_) async => [
              IntegrationTestHelpers.createTestSponsorship(
                id: 'sponsor-1',
                eventId: 'event-456',
                brandId: 'brand-1',
                type: SponsorshipType.financial,
                status: SponsorshipStatus.approved,
              ),
            ]);
        
        when(() => mockPartnershipService.getPartnershipsForEvent('event-456'))
            .thenAnswer((_) async => [
              EventPartnership(
                id: 'partnership-123',
                eventId: 'event-456',
                userId: 'user-123',
                businessId: 'business-123',
                createdAt: testDate,
                updatedAt: testDate,
              ),
            ]);
        
        // Act
        final revenueSplit = await revenueSplitService.calculateNWayBrandSplit(
          eventId: 'event-456',
          totalAmount: 1000.00,
          ticketsSold: 20,
        );
        
        // Assert
        expect(revenueSplit, isNotNull);
        expect(revenueSplit.eventId, equals('event-456'));
        expect(revenueSplit.isValid, isTrue);
        expect(revenueSplit.parties.length, greaterThanOrEqualTo(3)); // user + business + brand(s)
      });
      
      test('should include all sponsorships in revenue split', () async {
        // Arrange
        when(() => mockSponsorshipService.getSponsorshipsForEvent('event-456'))
            .thenAnswer((_) async => [
              IntegrationTestHelpers.createTestSponsorship(
                id: 'sponsor-1',
                eventId: 'event-456',
                brandId: 'brand-1',
                type: SponsorshipType.financial,
                status: SponsorshipStatus.approved,
              ),
              IntegrationTestHelpers.createTestSponsorship(
                id: 'sponsor-2',
                eventId: 'event-456',
                brandId: 'brand-2',
                type: SponsorshipType.financial,
                status: SponsorshipStatus.approved,
              ),
            ]);
        
        when(() => mockPartnershipService.getPartnershipsForEvent('event-456'))
            .thenAnswer((_) async => []);
        
        // Act
        final revenueSplit = await revenueSplitService.calculateNWayBrandSplit(
          eventId: 'event-456',
          totalAmount: 1000.00,
          ticketsSold: 20,
        );
        
        // Assert
        expect(revenueSplit.parties.where((p) => p.type == SplitPartyType.sponsor).length, equals(2));
      });
      
      test('should validate percentages sum to 100%', () async {
        // Arrange
        when(() => mockSponsorshipService.getSponsorshipsForEvent('event-456'))
            .thenAnswer((_) async => []);
        
        when(() => mockPartnershipService.getPartnershipsForEvent('event-456'))
            .thenAnswer((_) async => []);
        
        // Act & Assert - Should fail validation if percentages don't sum correctly
        // This is tested implicitly in the calculation method
        expect(
          () => revenueSplitService.calculateNWaySplit(
            eventId: 'event-456',
            totalAmount: 1000.00,
            ticketsSold: 20,
            parties: [
              SplitParty(
                partyId: 'party-1',
                type: SplitPartyType.user,
                percentage: 60.0, // Doesn't sum to 100%
              ),
            ],
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
    
    group('Scenario 2: Product Sales Revenue Split', () {
      test('should calculate product sales revenue split', () async {
        // Arrange
        final productTracking = IntegrationTestHelpers.createTestProductTracking(
          id: 'product-track-123',
          sponsorshipId: 'sponsor-123',
          quantitySold: 15,
          unitPrice: 25.00,
        );
        
        when(() => mockProductTrackingService.getProductTrackingById('product-track-123'))
            .thenAnswer((_) async => productTracking.copyWith(
              totalSales: 375.00,
            ));
        
        when(() => mockSponsorshipService.getSponsorshipById('sponsor-123'))
            .thenAnswer((_) async => IntegrationTestHelpers.createTestSponsorship(
              id: 'sponsor-123',
              eventId: 'event-456',
              brandId: 'brand-123',
              type: SponsorshipType.product,
            ));
        
        // Act
        final revenueSplit = await revenueSplitService.calculateProductSalesSplit(
          productTrackingId: 'product-track-123',
          totalSales: 375.00,
        );
        
        // Assert
        expect(revenueSplit, isNotNull);
        expect(revenueSplit.totalAmount, equals(375.00));
        expect(revenueSplit.platformFee, closeTo(37.50, 0.01)); // 10% of 375
        expect(revenueSplit.parties.length, equals(1));
        expect(revenueSplit.parties.first.type, equals(SplitPartyType.sponsor));
      });
    });
    
    group('Scenario 3: Hybrid Sponsorship Split', () {
      test('should calculate hybrid split (cash + product)', () async {
        // Arrange
        final parties = [
          SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 50.0,
          ),
          SplitParty(
            partyId: 'business-123',
            type: SplitPartyType.business,
            percentage: 30.0,
          ),
          SplitParty(
            partyId: 'brand-123',
            type: SplitPartyType.sponsor,
            percentage: 20.0,
          ),
        ];
        
        // Act
        final splits = await revenueSplitService.calculateHybridSplit(
          eventId: 'event-456',
          cashAmount: 500.00,
          productSalesAmount: 375.00,
          ticketsSold: 20,
          parties: parties,
        );
        
        // Assert
        expect(splits, isNotNull);
        expect(splits.containsKey('cash'), isTrue);
        expect(splits.containsKey('product'), isTrue);
        expect(splits['cash']!.totalAmount, equals(500.00));
        expect(splits['product']!.totalAmount, equals(375.00));
      });
    });
    
    group('Scenario 4: Revenue Split Validation', () {
      test('should validate that split is valid', () async {
        // Arrange
        final parties = [
          SplitParty(
            partyId: 'party-1',
            type: SplitPartyType.user,
            percentage: 50.0,
          ),
          SplitParty(
            partyId: 'party-2',
            type: SplitPartyType.business,
            percentage: 50.0,
          ),
        ];
        
        // Act
        final revenueSplit = await revenueSplitService.calculateNWaySplit(
          eventId: 'event-456',
          totalAmount: 1000.00,
          ticketsSold: 20,
          parties: parties,
        );
        
        // Assert
        expect(revenueSplit.isValid, isTrue);
        expect(revenueSplit.totalAmount, equals(1000.00));
      });
    });
    
    group('Scenario 5: Payment Distribution', () {
      test('should distribute payments to all parties', () async {
        // Arrange
        final parties = [
          SplitParty(
            partyId: 'party-1',
            type: SplitPartyType.user,
            percentage: 50.0,
          ),
          SplitParty(
            partyId: 'party-2',
            type: SplitPartyType.business,
            percentage: 30.0,
          ),
          SplitParty(
            partyId: 'party-3',
            type: SplitPartyType.sponsor,
            percentage: 20.0,
          ),
        ];
        
        final revenueSplit = await revenueSplitService.calculateNWaySplit(
          eventId: 'event-456',
          totalAmount: 1000.00,
          ticketsSold: 20,
          parties: parties,
        );
        
        final lockedSplit = await revenueSplitService.lockSplit(
          revenueSplitId: revenueSplit.id,
          lockedBy: 'user-123',
        );
        
        // Act
        final distribution = await revenueSplitService.distributePayments(
          revenueSplitId: lockedSplit.id,
          eventEndTime: testDate.add(const Duration(days: 1)),
        );
        
        // Assert
        expect(distribution, isNotEmpty);
        expect(distribution.length, equals(3));
        expect(distribution.values.every((amount) => amount > 0), isTrue);
      });
    });
  });
}

