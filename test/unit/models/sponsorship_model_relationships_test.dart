import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/brand_account.dart';
import 'package:spots/core/models/product_tracking.dart';
import 'package:spots/core/models/multi_party_sponsorship.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/models/payment.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/sponsorship_integration.dart';
import '../../helpers/test_helpers.dart';
import '../../fixtures/model_factories.dart';

/// Sponsorship Model Relationships Verification Tests
/// 
/// Agent 3: Models & Testing (Week 11)
/// 
/// Verifies all model relationships work correctly with payment/revenue:
/// - Sponsorship ↔ Payment relationships
/// - Sponsorship ↔ RevenueSplit relationships
/// - ProductTracking ↔ RevenueSplit relationships
/// - Multi-party relationships
/// - Brand account relationships
void main() {
  group('Sponsorship Model Relationships Verification', () {
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

    group('Payment Relationships', () {
      test('should link payment to sponsored event correctly', () {
        // Arrange
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
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
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act & Assert
        expect(payment.eventId, equals(sponsorship.eventId),
            reason: 'Payment should reference same event as sponsorship');
        expect(payment.isSuccessful, isTrue,
            reason: 'Payment should be successful for active sponsorship');
      });

      test('should aggregate payments for sponsored event', () {
        // Arrange
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          status: SponsorshipStatus.active,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final payments = List.generate(5, (i) => Payment(
          id: 'payment-$i',
          eventId: 'event-456',
          userId: 'user-$i',
          amount: 75.00,
          status: PaymentStatus.completed,
          createdAt: testDate,
          updatedAt: testDate,
        ));

        // Act
        final totalRevenue = payments
            .where((p) => p.eventId == sponsorship.eventId && p.isSuccessful)
            .fold<double>(0.0, (sum, p) => sum + p.totalAmount);

        // Assert
        expect(totalRevenue, equals(375.00));
      });
    });

    group('Revenue Split Relationships', () {
      test('should link revenue split to sponsorship correctly', () {
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
        final sponsorParty = revenueSplit.parties.firstWhere(
          (p) => p.partyId == sponsorship.brandId,
        );

        // Assert
        expect(includesSponsors, isTrue,
            reason: 'Revenue split should include sponsorships');
        expect(sponsorParty.type, equals(SplitPartyType.sponsor),
            reason: 'Sponsor should be marked as sponsor type');
        expect(sponsorParty.percentage, equals(20.0),
            reason: 'Sponsor percentage should match sponsorship');
        expect(revenueSplit.isValid, isTrue,
            reason: 'Revenue split should be valid');
      });
    });

    group('Product Tracking Relationships', () {
      test('should link product tracking to sponsorship and revenue', () {
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

        // Act & Assert
        expect(productTracking.sponsorshipId, equals(sponsorship.id),
            reason: 'Product tracking should reference sponsorship');
        expect(productTracking.totalSales, equals(375.00),
            reason: 'Product tracking should track total sales');
        expect(productTracking.revenueDistribution.containsKey('brand-123'), isTrue,
            reason: 'Revenue distribution should include brand');
      });
    });

    group('Multi-Party Relationships', () {
      test('should verify multi-party sponsorship relationships', () {
        // Arrange
        final sponsorship1 = Sponsorship(
          id: 'sponsor-1',
          eventId: 'event-456',
          brandId: 'brand-1',
          type: SponsorshipType.financial,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final sponsorship2 = Sponsorship(
          id: 'sponsor-2',
          eventId: 'event-456',
          brandId: 'brand-2',
          type: SponsorshipType.financial,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final multiParty = MultiPartySponsorship(
          id: 'multi-sponsor-123',
          eventId: 'event-456',
          brandIds: ['brand-1', 'brand-2'],
          revenueSplitConfiguration: {
            'brand-1': 60.0,
            'brand-2': 40.0,
          },
          agreementStatus: MultiPartyAgreementStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act
        final isPartOf1 = SponsorshipIntegration.isPartOfMultiParty(
          sponsorship1,
          multiParty,
        );
        final isPartOf2 = SponsorshipIntegration.isPartOfMultiParty(
          sponsorship2,
          multiParty,
        );
        final isValid = multiParty.isRevenueSplitValid;

        // Assert
        expect(isPartOf1, isTrue,
            reason: 'Sponsorship 1 should be part of multi-party');
        expect(isPartOf2, isTrue,
            reason: 'Sponsorship 2 should be part of multi-party');
        expect(isValid, isTrue,
            reason: 'Multi-party revenue split should be valid');
      });
    });

    group('Brand Account Relationships', () {
      test('should verify brand account can sponsor events', () {
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
            reason: 'Brand should be verified');
        expect(brand.canSponsor, isTrue,
            reason: 'Verified brand should be able to sponsor');
      });
    });

    group('Complete Payment/Revenue Flow', () {
      test('should verify complete payment to revenue split flow', () {
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
          revenueSharePercentage: 20.0,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

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

        final revenueSplit = RevenueSplit.nWay(
          id: 'split-123',
          eventId: 'event-456',
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

        // Act
        final hasSponsors = partnership.hasSponsorships([sponsorship]);
        final includesSponsors = SponsorshipIntegration.revenueSplitIncludesSponsorships(
          revenueSplit,
          [sponsorship],
        );
        final sponsorAmount = revenueSplit.parties
            .firstWhere((p) => p.partyId == 'brand-123')
            .amount ?? 0.0;

        // Assert
        expect(hasSponsors, isTrue);
        expect(includesSponsors, isTrue);
        expect(revenueSplit.isValid, isTrue);
        expect(sponsorAmount, greaterThan(0));
      });
    });
  });
}

