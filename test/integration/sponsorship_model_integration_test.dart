import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/brand_account.dart';
import 'package:spots/core/models/product_tracking.dart';
import 'package:spots/core/models/multi_party_sponsorship.dart';
import 'package:spots/core/models/brand_discovery.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/models/sponsorship_integration.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/business_account.dart';
import '../../helpers/test_helpers.dart';
import '../../fixtures/model_factories.dart';

/// Sponsorship Model Integration Tests
/// 
/// Agent 3: Models & Testing (Week 10)
/// 
/// Tests the integration of Brand Sponsorship models with existing Partnership models:
/// - Sponsorship ↔ EventPartnership relationships
/// - Multi-party sponsorship with revenue splits
/// - Product tracking with sponsorship
/// - Brand discovery with partnership events
/// - Model relationship verification
/// 
/// **Test Scenarios:**
/// - Scenario 1: Sponsorship with Event Partnership
/// - Scenario 2: Multi-Party Sponsorship Integration
/// - Scenario 3: Product Tracking with Sponsorship
/// - Scenario 4: Brand Discovery with Partnership Events
/// - Scenario 5: Revenue Split with Sponsorships
void main() {
  group('Sponsorship Model Integration Tests', () {
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

    group('Scenario 1: Sponsorship with Event Partnership', () {
      test('should link sponsorship to event partnership', () {
        // Arrange
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
          contributionAmount: 500.00,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act
        final hasSponsors = partnership.hasSponsorships([sponsorship]);
        final eventSponsorships = partnership.getSponsorships([sponsorship]);
        final totalValue = partnership.getTotalSponsorshipValue([sponsorship]);

        // Assert
        expect(hasSponsors, isTrue);
        expect(eventSponsorships.length, equals(1));
        expect(eventSponsorships.first.id, equals('sponsor-123'));
        expect(totalValue, equals(500.00));
      });

      test('should handle multiple sponsorships for same event', () {
        // Arrange
        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-456',
          userId: 'user-123',
          businessId: 'business-123',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final sponsorship1 = Sponsorship(
          id: 'sponsor-1',
          eventId: 'event-456',
          brandId: 'brand-1',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final sponsorship2 = Sponsorship(
          id: 'sponsor-2',
          eventId: 'event-456',
          brandId: 'brand-2',
          type: SponsorshipType.product,
          productValue: 300.00,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act
        final eventSponsorships = partnership.getSponsorships([sponsorship1, sponsorship2]);
        final totalValue = partnership.getTotalSponsorshipValue([sponsorship1, sponsorship2]);

        // Assert
        expect(eventSponsorships.length, equals(2));
        expect(totalValue, equals(800.00));
      });
    });

    group('Scenario 2: Multi-Party Sponsorship Integration', () {
      test('should link multi-party sponsorship to event', () {
        // Arrange
        final multiParty = MultiPartySponsorship(
          id: 'multi-sponsor-123',
          eventId: 'event-456',
          brandIds: ['brand-1', 'brand-2', 'brand-3'],
          revenueSplitConfiguration: {
            'brand-1': 40.0,
            'brand-2': 35.0,
            'brand-3': 25.0,
          },
          totalContributionValue: 1000.00,
          agreementStatus: MultiPartyAgreementStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act
        final brandIds = SponsorshipIntegration.getBrandIdsFromMultiParty(multiParty);
        final totalValue = SponsorshipIntegration.getMultiPartyTotalValue(multiParty);
        final isValid = multiParty.isRevenueSplitValid;

        // Assert
        expect(brandIds.length, equals(3));
        expect(brandIds, containsAll(['brand-1', 'brand-2', 'brand-3']));
        expect(totalValue, equals(1000.00));
        expect(isValid, isTrue);
      });

      test('should verify individual sponsorship is part of multi-party', () {
        // Arrange
        final sponsorship = Sponsorship(
          id: 'sponsor-1',
          eventId: 'event-456',
          brandId: 'brand-1',
          type: SponsorshipType.financial,
          contributionAmount: 400.00,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final multiParty = MultiPartySponsorship(
          id: 'multi-sponsor-123',
          eventId: 'event-456',
          brandIds: ['brand-1', 'brand-2', 'brand-3'],
          agreementStatus: MultiPartyAgreementStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act
        final isPartOf = SponsorshipIntegration.isPartOfMultiParty(
          sponsorship,
          multiParty,
        );

        // Assert
        expect(isPartOf, isTrue);
      });
    });

    group('Scenario 3: Product Tracking with Sponsorship', () {
      test('should link product tracking to sponsorship', () {
        // Arrange
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.product,
          productValue: 500.00,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final productTracking = ProductTracking(
          id: 'product-track-123',
          sponsorshipId: 'sponsor-123',
          productName: 'Premium Olive Oil',
          quantityProvided: 20,
          quantitySold: 15,
          unitPrice: 25.00,
          totalSales: 375.00,
          platformFee: 37.50,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act & Assert
        expect(productTracking.sponsorshipId, equals(sponsorship.id));
        expect(productTracking.totalSales, equals(375.00));
        expect(productTracking.platformFee, equals(37.50));
        expect(productTracking.quantityRemaining, equals(5));
      });

      test('should calculate revenue distribution correctly', () {
        // Arrange
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

        // Act
        final netRevenue = productTracking.netRevenue;
        final totalDistributed = productTracking.revenueDistribution.values
            .fold<double>(0.0, (sum, amount) => sum + amount);

        // Assert
        expect(netRevenue, equals(337.50)); // 375 - 37.50
        expect(totalDistributed, equals(337.50));
      });
    });

    group('Scenario 4: Brand Discovery with Partnership Events', () {
      test('should match brands to partnership events', () {
        // Arrange
        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-456',
          userId: 'user-123',
          businessId: 'business-123',
          vibeCompatibilityScore: 0.85,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final vibeCompatibility = VibeCompatibility(
          overallScore: 85.0,
          valueAlignment: 90.0,
          styleCompatibility: 80.0,
          qualityFocus: 85.0,
          audienceAlignment: 85.0,
        );

        final brandMatch = BrandMatch(
          brandId: 'brand-123',
          brandName: 'Premium Oil Co.',
          compatibilityScore: 85.0,
          vibeCompatibility: vibeCompatibility,
          matchReasons: ['Value alignment', 'Quality focus'],
        );

        final discovery = BrandDiscovery(
          id: 'discovery-123',
          eventId: 'event-456',
          searchCriteria: {
            'category': 'Food & Beverage',
            'minContribution': 500.0,
          },
          matchingResults: [brandMatch],
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act
        final viableMatches = discovery.viableMatches;
        final hasViable = discovery.hasViableMatches;

        // Assert
        expect(hasViable, isTrue);
        expect(viableMatches.length, equals(1));
        expect(viableMatches.first.compatibilityScore, greaterThanOrEqualTo(70.0));
        expect(viableMatches.first.meetsThreshold, isTrue);
      });
    });

    group('Scenario 5: Revenue Split with Sponsorships', () {
      test('should include sponsorships in revenue split', () {
        // Arrange
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          revenueSharePercentage: 20.0,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final revenueSplit = RevenueSplit.nWay(
          id: 'split-123',
          eventId: 'event-456',
          totalAmount: 1000.00,
          ticketsSold: 20,
          parties: [
            SplitParty(
              partyId: 'user-123',
              type: SplitPartyType.user,
              percentage: 40.0,
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
        final includesSponsors = SponsorshipIntegration.revenueSplitIncludesSponsorships(
          revenueSplit,
          [sponsorship],
        );

        // Assert
        expect(includesSponsors, isTrue);
        expect(revenueSplit.parties.length, equals(3));
        expect(revenueSplit.isValid, isTrue);
      });

      test('should calculate multi-party revenue split correctly', () {
        // Arrange
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

        final revenueSplit = RevenueSplit.nWay(
          id: 'split-123',
          eventId: 'event-456',
          totalAmount: 2000.00,
          ticketsSold: 25,
          parties: [
            SplitParty(
              partyId: 'user-123',
              type: SplitPartyType.user,
              percentage: 40.0,
            ),
            SplitParty(
              partyId: 'business-123',
              type: SplitPartyType.business,
              percentage: 30.0,
            ),
            SplitParty(
              partyId: 'brand-1',
              type: SplitPartyType.sponsor,
              percentage: 18.0, // 60% of 30% sponsor allocation
            ),
            SplitParty(
              partyId: 'brand-2',
              type: SplitPartyType.sponsor,
              percentage: 12.0, // 40% of 30% sponsor allocation
            ),
          ],
        );

        // Act & Assert
        expect(multiParty.isRevenueSplitValid, isTrue);
        expect(revenueSplit.isValid, isTrue);
        expect(revenueSplit.parties.length, equals(4));
      });
    });

    group('Model Relationship Verification', () {
      test('should verify all model relationships are correct', () {
        // Arrange
        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-456',
          userId: 'user-123',
          businessId: 'business-123',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final productTracking = ProductTracking(
          id: 'product-track-123',
          sponsorshipId: 'sponsor-123',
          productName: 'Premium Olive Oil',
          quantityProvided: 20,
          unitPrice: 25.00,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act & Assert - Verify relationships
        expect(sponsorship.eventId, equals(partnership.eventId),
            reason: 'Sponsorship should reference same event as partnership');
        expect(productTracking.sponsorshipId, equals(sponsorship.id),
            reason: 'Product tracking should reference sponsorship');
        expect(partnership.hasSponsorships([sponsorship]), isTrue,
            reason: 'Partnership should detect associated sponsorships');
      });

      test('should verify brand account relationships', () {
        // Arrange
        final brand = BrandAccount(
          id: 'brand-123',
          name: 'Premium Oil Co.',
          brandType: 'Food & Beverage',
          contactEmail: 'partnerships@premiumoil.com',
          verificationStatus: BrandVerificationStatus.verified,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act & Assert
        expect(sponsorship.brandId, equals(brand.id),
            reason: 'Sponsorship should reference brand account');
        expect(brand.isVerified, isTrue,
            reason: 'Brand should be verified to sponsor');
        expect(brand.canSponsor, isTrue,
            reason: 'Verified brand should be able to sponsor');
      });
    });

    group('Scenario 6: Payment & Revenue Integration', () {
      test('should integrate payments with sponsored events', () {
        // Arrange
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          status: SponsorshipStatus.active,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final payment = Payment(
          id: 'payment-123',
          eventId: 'event-456',
          userId: 'user-789',
          amount: 75.00,
          status: PaymentStatus.completed,
          quantity: 1,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act & Assert
        expect(payment.eventId, equals(sponsorship.eventId));
        expect(payment.isSuccessful, isTrue);
      });

      test('should calculate revenue split with sponsorship', () {
        // Arrange
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          revenueSharePercentage: 20.0,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final revenueSplit = RevenueSplit.nWay(
          id: 'split-123',
          eventId: 'event-456',
          totalAmount: 1000.00,
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
        final includesSponsors = SponsorshipIntegration.revenueSplitIncludesSponsorships(
          revenueSplit,
          [sponsorship],
        );
        final sponsorAmount = revenueSplit.parties
            .firstWhere((p) => p.partyId == 'brand-123')
            .amount ?? 0.0;

        // Assert
        expect(includesSponsors, isTrue);
        expect(revenueSplit.isValid, isTrue);
        expect(sponsorAmount, greaterThan(0));
      });

      test('should integrate product sales with revenue split', () {
        // Arrange
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

        // Act
        final totalSales = productTracking.totalSales;
        final platformFee = productTracking.platformFee;
        final netRevenue = productTracking.netRevenue;
        final brandShare = productTracking.revenueDistribution['brand-123'] ?? 0.0;

        // Assert
        expect(totalSales, equals(375.00));
        expect(platformFee, equals(37.50));
        expect(netRevenue, equals(337.50));
        expect(brandShare, equals(202.50));
      });
    });
  });
}

