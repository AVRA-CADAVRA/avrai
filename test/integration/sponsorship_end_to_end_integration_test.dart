import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/brand_account.dart';
import 'package:spots/core/models/brand_discovery.dart';
import 'package:spots/core/models/product_tracking.dart';
import 'package:spots/core/models/payment.dart';
import 'package:spots/core/models/payment_status.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/models/multi_party_sponsorship.dart';
import 'package:spots/core/models/sponsorship_integration.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/business_account.dart';
import '../helpers/test_helpers.dart';
import '../fixtures/model_factories.dart';

/// Sponsorship End-to-End Integration Tests
/// 
/// Agent 3: Models & Testing (Week 12)
/// 
/// Tests complete end-to-end sponsorship flows:
/// - Complete brand discovery to sponsorship flow
/// - Complete sponsorship to payment flow
/// - Complete product tracking flow
/// - Complete multi-party sponsorship flow
/// 
/// **Test Scenarios:**
/// - Scenario 1: Complete Brand Discovery → Sponsorship Flow
/// - Scenario 2: Complete Sponsorship → Payment → Revenue Split Flow
/// - Scenario 3: Complete Product Sponsorship Flow
/// - Scenario 4: Complete Multi-Party Sponsorship Flow
/// - Scenario 5: Complete Hybrid Sponsorship Flow
void main() {
  group('Sponsorship End-to-End Integration Tests', () {
    late DateTime testDate;
    late UnifiedUser testUser;
    late BusinessAccount testBusiness;
    late BrandAccount testBrand;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Expert User',
      );
      testBusiness = BusinessAccount(
        id: 'business-123',
        name: 'Test Restaurant',
        email: 'test@restaurant.com',
        businessType: 'Restaurant',
        createdAt: testDate,
        updatedAt: testDate,
        createdBy: 'user-123',
      );
      testBrand = BrandAccount(
        id: 'brand-123',
        name: 'Premium Oil Co.',
        brandType: 'Food & Beverage',
        contactEmail: 'partnerships@premiumoil.com',
        verificationStatus: BrandVerificationStatus.verified,
        createdAt: testDate,
        updatedAt: testDate,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Scenario 1: Complete Brand Discovery → Sponsorship Flow', () {
      test('should complete full flow from discovery to active sponsorship', () {
        // Step 1: Create partnership
        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-456',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Step 2: Brand discovery
        final brandMatch = BrandMatch(
          brandId: 'brand-123',
          brandName: 'Premium Oil Co.',
          compatibilityScore: 85.0,
          vibeCompatibility: VibeCompatibility(
            overallScore: 85.0,
            valueAlignment: 90.0,
            styleCompatibility: 80.0,
            qualityFocus: 85.0,
            audienceAlignment: 85.0,
          ),
          matchReasons: ['Value alignment', 'Quality focus'],
        );

        final discovery = BrandDiscovery(
          id: 'discovery-123',
          eventId: 'event-456',
          searchCriteria: {'category': 'Food & Beverage'},
          matchingResults: [brandMatch],
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Step 3: Create sponsorship proposal
        var sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          revenueSharePercentage: 20.0,
          status: SponsorshipStatus.proposed,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Step 4: Approve sponsorship
        sponsorship = sponsorship.copyWith(
          status: SponsorshipStatus.approved,
          agreementSignedAt: testDate,
          agreementSignedBy: 'brand-rep-123',
        );

        // Step 5: Lock sponsorship
        sponsorship = sponsorship.copyWith(
          status: SponsorshipStatus.locked,
        );

        // Step 6: Activate sponsorship
        sponsorship = sponsorship.copyWith(
          status: SponsorshipStatus.active,
        );

        // Assert
        expect(discovery.hasViableMatches, isTrue);
        expect(sponsorship.isActive, isTrue);
        expect(sponsorship.isLocked, isTrue);
        expect(partnership.hasSponsorships([sponsorship]), isTrue);
      });
    });

    group('Scenario 2: Complete Sponsorship → Payment → Revenue Split Flow', () {
      test('should complete full payment and revenue split flow', () {
        // Step 1: Create partnership with sponsorship
        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-456',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          revenueSharePercentage: 20.0,
          status: SponsorshipStatus.active,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Step 2: Process ticket payments
        final payments = [
          Payment(
            id: 'payment-1',
            eventId: 'event-456',
            userId: 'user-1',
            amount: 75.00,
            status: PaymentStatus.completed,
            createdAt: testDate,
            updatedAt: testDate,
          ),
          Payment(
            id: 'payment-2',
            eventId: 'event-456',
            userId: 'user-2',
            amount: 75.00,
            status: PaymentStatus.completed,
            createdAt: testDate,
            updatedAt: testDate,
          ),
        ];

        final totalRevenue = payments
            .where((p) => p.isSuccessful)
            .fold<double>(0.0, (sum, p) => sum + p.totalAmount);

        // Step 3: Calculate revenue split
        final revenueSplit = RevenueSplit.nWay(
          id: 'split-123',
          eventId: 'event-456',
          partnershipId: partnership.id,
          totalAmount: totalRevenue,
          ticketsSold: payments.length,
          parties: [
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
          ],
        );

        // Assert
        expect(totalRevenue, equals(150.00));
        expect(revenueSplit.isValid, isTrue);
        expect(SponsorshipIntegration.revenueSplitIncludesSponsorships(
          revenueSplit,
          [sponsorship],
        ), isTrue);
        expect(revenueSplit.parties.length, equals(3));
      });
    });

    group('Scenario 3: Complete Product Sponsorship Flow', () {
      test('should complete full product sponsorship flow', () {
        // Step 1: Create product sponsorship
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.product,
          productValue: 500.00,
          status: SponsorshipStatus.active,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Step 2: Track products provided
        var productTracking = ProductTracking(
          id: 'product-track-123',
          sponsorshipId: 'sponsor-123',
          productName: 'Premium Olive Oil',
          quantityProvided: 20,
          unitPrice: 25.00,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Step 3: Record product sales
        final sales = [
          ProductSale(
            id: 'sale-1',
            productTrackingId: 'product-track-123',
            buyerId: 'buyer-1',
            quantity: 2,
            unitPrice: 25.00,
            totalAmount: 50.00,
            soldAt: testDate,
            paymentStatus: PaymentStatus.completed,
          ),
          ProductSale(
            id: 'sale-2',
            productTrackingId: 'product-track-123',
            buyerId: 'buyer-2',
            quantity: 1,
            unitPrice: 25.00,
            totalAmount: 25.00,
            soldAt: testDate,
            paymentStatus: PaymentStatus.completed,
          ),
        ];

        productTracking = productTracking.copyWith(
          quantitySold: 3,
          totalSales: 75.00,
          platformFee: 7.50,
          sales: sales,
          revenueDistribution: {
            'brand-123': 40.50,
            'user-123': 16.88,
            'business-123': 10.12,
          },
        );

        // Assert
        expect(productTracking.sponsorshipId, equals(sponsorship.id));
        expect(productTracking.quantitySold, equals(3));
        expect(productTracking.totalSales, equals(75.00));
        expect(productTracking.sales.length, equals(2));
        expect(productTracking.revenueDistribution.containsKey('brand-123'), isTrue);
      });
    });

    group('Scenario 4: Complete Multi-Party Sponsorship Flow', () {
      test('should complete full multi-party sponsorship flow', () {
        // Step 1: Create partnership
        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-456',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Step 2: Create individual sponsorships
        final sponsorship1 = Sponsorship(
          id: 'sponsor-1',
          eventId: 'event-456',
          brandId: 'brand-1',
          type: SponsorshipType.financial,
          revenueSharePercentage: 15.0,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final sponsorship2 = Sponsorship(
          id: 'sponsor-2',
          eventId: 'event-456',
          brandId: 'brand-2',
          type: SponsorshipType.financial,
          revenueSharePercentage: 10.0,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Step 3: Create multi-party sponsorship
        final multiParty = MultiPartySponsorship(
          id: 'multi-sponsor-123',
          eventId: 'event-456',
          brandIds: ['brand-1', 'brand-2'],
          revenueSplitConfiguration: {
            'brand-1': 60.0,
            'brand-2': 40.0,
          },
          totalContributionValue: 1000.00,
          agreementStatus: MultiPartyAgreementStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Step 4: Calculate revenue split
        final revenueSplit = RevenueSplit.nWay(
          id: 'split-123',
          eventId: 'event-456',
          totalAmount: 2000.00,
          ticketsSold: 25,
          parties: [
            SplitParty(
              partyId: 'user-123',
              type: SplitPartyType.user,
              percentage: 50.0,
            ),
            SplitParty(
              partyId: 'business-123',
              type: SplitPartyType.business,
              percentage: 25.0,
            ),
            SplitParty(
              partyId: 'brand-1',
              type: SplitPartyType.sponsor,
              percentage: 15.0,
            ),
            SplitParty(
              partyId: 'brand-2',
              type: SplitPartyType.sponsor,
              percentage: 10.0,
            ),
          ],
        );

        // Assert
        expect(multiParty.isRevenueSplitValid, isTrue);
        expect(SponsorshipIntegration.isPartOfMultiParty(sponsorship1, multiParty), isTrue);
        expect(SponsorshipIntegration.isPartOfMultiParty(sponsorship2, multiParty), isTrue);
        expect(revenueSplit.isValid, isTrue);
        expect(revenueSplit.parties.length, equals(4));
      });
    });

    group('Scenario 5: Complete Hybrid Sponsorship Flow', () {
      test('should complete full hybrid sponsorship flow', () {
        // Step 1: Create hybrid sponsorship
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.hybrid,
          contributionAmount: 300.00,
          productValue: 400.00,
          revenueSharePercentage: 20.0,
          status: SponsorshipStatus.active,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Step 2: Track product sales
        final productTracking = ProductTracking(
          id: 'product-track-123',
          sponsorshipId: 'sponsor-123',
          productName: 'Premium Olive Oil',
          quantityProvided: 20,
          quantitySold: 15,
          unitPrice: 25.00,
          totalSales: 375.00,
          platformFee: 37.50,
          revenueDistribution: {
            'brand-123': 202.50,
            'user-123': 84.38,
            'business-123': 50.62,
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Step 3: Calculate ticket revenue split
        final ticketRevenueSplit = RevenueSplit.nWay(
          id: 'split-tickets',
          eventId: 'event-456',
          totalAmount: 1500.00,
          ticketsSold: 20,
          parties: [
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
          ],
        );

        // Act
        final totalContribution = sponsorship.totalContributionValue;
        final ticketBrandShare = ticketRevenueSplit.parties
            .firstWhere((p) => p.partyId == 'brand-123')
            .amount ?? 0.0;
        final productBrandShare = productTracking.revenueDistribution['brand-123'] ?? 0.0;
        final totalBrandRevenue = ticketBrandShare + productBrandShare;

        // Assert
        expect(totalContribution, equals(700.00));
        expect(ticketBrandShare, greaterThan(0));
        expect(productBrandShare, equals(202.50));
        expect(totalBrandRevenue, greaterThan(400.00));
      });
    });
  });
}

