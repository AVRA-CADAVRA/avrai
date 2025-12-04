import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/payment.dart';
import 'package:spots/core/models/payment_status.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/sponsorship_integration.dart';
import '../helpers/test_helpers.dart';
import '../fixtures/model_factories.dart';

/// Sponsorship Payment Flow Integration Tests
/// 
/// Agent 3: Models & Testing (Week 12)
/// 
/// Tests payment flows with sponsorships:
/// - Ticket payments for sponsored events
/// - Revenue split calculation with sponsors
/// - Multi-party payment distribution
/// - Product sales payments
/// 
/// **Test Scenarios:**
/// - Scenario 1: Ticket Payments for Sponsored Events
/// - Scenario 2: Revenue Split with Sponsorships
/// - Scenario 3: Multi-Party Payment Distribution
/// - Scenario 4: Product Sales Payment Flow
void main() {
  group('Sponsorship Payment Flow Integration Tests', () {
    late DateTime testDate;
    late UnifiedUser testUser;
    late BusinessAccount testBusiness;

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
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Scenario 1: Ticket Payments for Sponsored Events', () {
      test('should process payments for sponsored event', () {
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
          quantity: 1,
          createdAt: testDate,
          updatedAt: testDate,
        ));

        // Act
        final totalRevenue = payments
            .where((p) => p.eventId == sponsorship.eventId && p.isSuccessful)
            .fold<double>(0.0, (sum, p) => sum + p.totalAmount);

        // Assert
        expect(totalRevenue, equals(375.00));
        expect(payments.every((p) => p.isSuccessful), isTrue);
      });

      test('should calculate revenue split from payments', () {
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

        final totalAmount = payments
            .where((p) => p.isSuccessful)
            .fold<double>(0.0, (sum, p) => sum + p.totalAmount);

        final revenueSplit = RevenueSplit.nWay(
          id: 'split-123',
          eventId: 'event-456',
          totalAmount: totalAmount,
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
        expect(revenueSplit.platformFee, closeTo(15.00, 0.01)); // 10% of 150
      });
    });

    group('Scenario 2: Revenue Split with Sponsorships', () {
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

    group('Scenario 3: Multi-Party Payment Distribution', () {
      test('should distribute payments across multiple parties including sponsors', () {
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

        final totalRevenue = 1000.00;
        final revenueSplit = RevenueSplit.nWay(
          id: 'split-123',
          eventId: 'event-456',
          partnershipId: partnership.id,
          totalAmount: totalRevenue,
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
        final userAmount = revenueSplit.parties
            .firstWhere((p) => p.partyId == 'user-123')
            .amount ?? 0.0;
        final businessAmount = revenueSplit.parties
            .firstWhere((p) => p.partyId == 'business-123')
            .amount ?? 0.0;
        final sponsorAmount = revenueSplit.parties
            .firstWhere((p) => p.partyId == 'brand-123')
            .amount ?? 0.0;

        // Assert
        expect(revenueSplit.isValid, isTrue);
        expect(userAmount + businessAmount + sponsorAmount, closeTo(revenueSplit.splitAmount, 0.01));
        expect(sponsorAmount, greaterThan(0));
      });
    });

    group('Scenario 4: Product Sales Payment Flow', () {
      test('should track product sales payments', () {
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

        // Simulate product sales payments
        final productPayments = [
          Payment(
            id: 'product-payment-1',
            eventId: 'event-456',
            userId: 'buyer-1',
            amount: 25.00,
            status: PaymentStatus.completed,
            quantity: 1,
            metadata: {
              'productTrackingId': 'product-track-123',
              'sponsorshipId': 'sponsor-123',
            },
            createdAt: testDate,
            updatedAt: testDate,
          ),
          Payment(
            id: 'product-payment-2',
            eventId: 'event-456',
            userId: 'buyer-2',
            amount: 25.00,
            status: PaymentStatus.completed,
            quantity: 1,
            metadata: {
              'productTrackingId': 'product-track-123',
              'sponsorshipId': 'sponsor-123',
            },
            createdAt: testDate,
            updatedAt: testDate,
          ),
        ];

        // Act
        final totalProductSales = productPayments
            .where((p) => p.isSuccessful && p.metadata['sponsorshipId'] == 'sponsor-123')
            .fold<double>(0.0, (sum, p) => sum + p.totalAmount);

        // Assert
        expect(totalProductSales, equals(50.00));
        expect(productPayments.every((p) => p.isSuccessful), isTrue);
      });
    });
  });
}

