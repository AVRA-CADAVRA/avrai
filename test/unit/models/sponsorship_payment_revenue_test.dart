import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/multi_party_sponsorship.dart';
import 'package:spots/core/models/product_tracking.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/models/payment.dart';
import 'package:spots/core/models/payment_status.dart';
import 'package:spots/core/models/sponsorship_integration.dart';
import '../../helpers/test_helpers.dart';

/// Sponsorship Payment & Revenue Model Tests
/// 
/// Agent 3: Models & Testing (Week 11)
/// 
/// Tests payment and revenue models with sponsorship scenarios:
/// - Payment tracking for sponsored events
/// - Revenue split with sponsorships
/// - Product sales revenue attribution
/// - Multi-party revenue distribution
/// - Hybrid sponsorship revenue splits
void main() {
  group('Sponsorship Payment & Revenue Model Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Payment with Sponsorship Events', () {
      test('should create payment for sponsored event', () {
        // Arrange
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-789',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          status: SponsorshipStatus.approved,
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
        expect(payment.totalAmount, equals(75.00));
      });

      test('should track multiple payments for sponsored event', () {
        // Arrange
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-789',
          type: SponsorshipType.financial,
          status: SponsorshipStatus.active,
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
          Payment(
            id: 'payment-3',
            eventId: 'event-456',
            userId: 'user-3',
            amount: 75.00,
            status: PaymentStatus.completed,
            createdAt: testDate,
            updatedAt: testDate,
          ),
        ];

        // Act
        final totalRevenue = payments
            .where((p) => p.eventId == sponsorship.eventId && p.isSuccessful)
            .fold<double>(0.0, (sum, p) => sum + p.totalAmount);

        // Assert
        expect(totalRevenue, equals(225.00));
      });
    });

    group('Revenue Split with Sponsorships', () {
      test('should create revenue split with sponsor party', () {
        // Arrange
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-789',
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
              percentage: 50.0,
            ),
            SplitParty(
              partyId: 'business-123',
              type: SplitPartyType.business,
              percentage: 30.0,
            ),
            SplitParty(
              partyId: sponsorship.brandId,
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
        expect(includesSponsors, isTrue);
        expect(sponsorParty.type, equals(SplitPartyType.sponsor));
        expect(sponsorParty.percentage, equals(20.0));
        expect(revenueSplit.isValid, isTrue);
      });

      test('should calculate revenue split with multiple sponsors', () {
        // Arrange
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

        // Act
        final includesSponsors = SponsorshipIntegration.revenueSplitIncludesSponsorships(
          revenueSplit,
          [sponsorship1, sponsorship2],
        );
        final sponsorParties = revenueSplit.parties
            .where((p) => p.type == SplitPartyType.sponsor)
            .toList();

        // Assert
        expect(includesSponsors, isTrue);
        expect(sponsorParties.length, equals(2));
        expect(revenueSplit.isValid, isTrue);
        expect(revenueSplit.splitAmount, closeTo(1740.00, 0.01));
      });
    });

    group('Product Sales Revenue Attribution', () {
      test('should attribute product sales revenue correctly', () {
        // Arrange
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-789',
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
            'brand-789': 202.50, // 60% of net
            'user-123': 84.38,   // 25% of net
            'business-123': 50.62, // 15% of net
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act
        final netRevenue = productTracking.netRevenue;
        final brandShare = productTracking.revenueDistribution['brand-789'] ?? 0.0;
        final totalDistributed = productTracking.revenueDistribution.values
            .fold<double>(0.0, (sum, amount) => sum + amount);

        // Assert
        expect(netRevenue, equals(337.50));
        expect(brandShare, equals(202.50));
        expect(totalDistributed, closeTo(netRevenue, 0.01));
      });

      test('should calculate product sales with multiple sponsors', () {
        // Arrange
        final sponsorship1 = Sponsorship(
          id: 'sponsor-1',
          eventId: 'event-456',
          brandId: 'brand-1',
          type: SponsorshipType.product,
          status: SponsorshipStatus.active,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final sponsorship2 = Sponsorship(
          id: 'sponsor-2',
          eventId: 'event-456',
          brandId: 'brand-2',
          type: SponsorshipType.product,
          status: SponsorshipStatus.active,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final productTracking1 = ProductTracking(
          id: 'product-track-1',
          sponsorshipId: 'sponsor-1',
          productName: 'Premium Olive Oil',
          quantityProvided: 20,
          quantitySold: 15,
          unitPrice: 25.00,
          totalSales: 375.00,
          platformFee: 37.50,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final productTracking2 = ProductTracking(
          id: 'product-track-2',
          sponsorshipId: 'sponsor-2',
          productName: 'Premium Wine',
          quantityProvided: 10,
          quantitySold: 10,
          unitPrice: 35.00,
          totalSales: 350.00,
          platformFee: 35.00,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act
        final totalProductSales = productTracking1.totalSales + productTracking2.totalSales;
        final totalPlatformFee = productTracking1.platformFee + productTracking2.platformFee;
        final totalNetRevenue = productTracking1.netRevenue + productTracking2.netRevenue;

        // Assert
        expect(totalProductSales, equals(725.00));
        expect(totalPlatformFee, equals(72.50));
        expect(totalNetRevenue, equals(652.50));
      });
    });

    group('Multi-Party Revenue Distribution', () {
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

        // Act
        final isValid = multiParty.isRevenueSplitValid && revenueSplit.isValid;
        final splitAmount = revenueSplit.splitAmount;
        final brand1Amount = revenueSplit.parties
            .firstWhere((p) => p.partyId == 'brand-1')
            .amount ?? 0.0;
        final brand2Amount = revenueSplit.parties
            .firstWhere((p) => p.partyId == 'brand-2')
            .amount ?? 0.0;

        // Assert
        expect(isValid, isTrue);
        expect(splitAmount, closeTo(1740.00, 0.01));
        expect(brand1Amount, closeTo(313.20, 0.01)); // 18% of 1740
        expect(brand2Amount, closeTo(208.80, 0.01)); // 12% of 1740
      });
    });

    group('Hybrid Sponsorship Revenue', () {
      test('should handle hybrid sponsorship with cash and product', () {
        // Arrange
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-789',
          type: SponsorshipType.hybrid,
          contributionAmount: 300.00,
          productValue: 400.00,
          revenueSharePercentage: 20.0,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Ticket sales revenue split
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
              partyId: 'brand-789',
              type: SplitPartyType.sponsor,
              percentage: 20.0,
            ),
          ],
        );

        // Product sales revenue
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
            'brand-789': 202.50,
            'user-123': 84.38,
            'business-123': 50.62,
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act
        final totalContribution = sponsorship.totalContributionValue;
        final ticketBrandShare = ticketRevenueSplit.parties
            .firstWhere((p) => p.partyId == 'brand-789')
            .amount ?? 0.0;
        final productBrandShare = productTracking.revenueDistribution['brand-789'] ?? 0.0;
        final totalBrandRevenue = ticketBrandShare + productBrandShare;

        // Assert
        expect(totalContribution, equals(700.00));
        expect(ticketBrandShare, closeTo(261.00, 0.01)); // 20% of 1305 (after fees)
        expect(productBrandShare, equals(202.50));
        expect(totalBrandRevenue, closeTo(463.50, 0.01));
      });
    });
  });
}

