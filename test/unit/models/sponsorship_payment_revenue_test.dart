import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/multi_party_sponsorship.dart';
import 'package:spots/core/models/product_tracking.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/models/payment.dart';
import 'package:spots/core/models/payment_status.dart';
import 'package:spots/core/models/sponsorship_integration.dart';
import 'dart:convert';
import 'dart:io';
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
  // #region agent log
  void _dbgLog({
    required String runId,
    required String hypothesisId,
    required String location,
    required String message,
    Map<String, dynamic>? data,
  }) {
    try {
      final payload = <String, dynamic>{
        'id': 'log_${DateTime.now().millisecondsSinceEpoch}_$hypothesisId',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'sessionId': 'debug-session',
        'runId': runId,
        'hypothesisId': hypothesisId,
        'location': location,
        'message': message,
        'data': data ?? <String, dynamic>{},
      };
      File('/Users/reisgordon/SPOTS/.cursor/debug.log')
          .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
    } catch (_) {
      // Avoid breaking tests if logging fails.
    }
  }
  // #endregion

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
      test('should correctly track and aggregate payments for sponsored events',
          () {
        // Test business logic: payment tracking and aggregation
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
        ];

        // Test business logic: payment aggregation
        final totalRevenue = payments
            .where((p) => p.eventId == sponsorship.eventId && p.isSuccessful)
            .fold<double>(0.0, (sum, p) => sum + p.totalAmount);

        expect(totalRevenue, equals(150.00));
        expect(payments.first.isSuccessful, isTrue);
      });
    });

    group('Revenue Split with Sponsorships', () {
      test(
          'should correctly calculate revenue splits with single and multiple sponsors',
          () {
        // Test business logic: revenue split calculation with sponsorships
        final singleSponsor = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-789',
          type: SponsorshipType.financial,
          revenueSharePercentage: 20.0,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final singleSplit = RevenueSplit.nWay(
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
              partyId: singleSponsor.brandId,
              type: SplitPartyType.sponsor,
              percentage: 20.0,
            ),
          ],
        );

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

        final multiSplit = RevenueSplit.nWay(
          id: 'split-456',
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

        // Test business logic: sponsorship integration
        expect(
            SponsorshipIntegration.revenueSplitIncludesSponsorships(
                singleSplit, [singleSponsor]),
            isTrue);
        expect(
            SponsorshipIntegration.revenueSplitIncludesSponsorships(
                multiSplit, [sponsorship1, sponsorship2]),
            isTrue);
        expect(singleSplit.isValid, isTrue);
        expect(multiSplit.isValid, isTrue);
        // Net after fees for multiSplit:
        // - platformFee: 10% of 2000.00 = 200.00
        // - processingFee: 2.9% of 2000.00 (58.00) + $0.30 * 25 tickets (7.50) = 65.50
        // => splitAmount = 2000.00 - 200.00 - 65.50 = 1734.50
        expect(multiSplit.splitAmount, closeTo(1734.50, 0.01));
      });
    });

    group('Product Sales Revenue Attribution', () {
      test('should correctly calculate product sales revenue and distribution', () {
        // Test business logic: product revenue calculation and distribution
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

        final productTracking2 = ProductTracking(
          id: 'product-track-456',
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

        // Test business logic: revenue calculation
        final netRevenue = productTracking.netRevenue;
        final brandShare = productTracking.revenueDistribution['brand-789'] ?? 0.0;
        final totalDistributed = productTracking.revenueDistribution.values
            .fold<double>(0.0, (sum, amount) => sum + amount);
        final totalNetRevenue = productTracking.netRevenue + productTracking2.netRevenue;

        expect(netRevenue, equals(337.50));
        expect(brandShare, equals(202.50));
        expect(totalDistributed, closeTo(netRevenue, 0.01)); // Distribution matches net
        expect(totalNetRevenue, equals(652.50)); // Multiple products aggregated
      });
    });

    group('Multi-Party Revenue Distribution', () {
      test('should correctly calculate multi-party revenue split with fee deductions', () {
        // Test business logic: multi-party revenue split calculation
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
              percentage: 18.0,
            ),
            SplitParty(
              partyId: 'brand-2',
              type: SplitPartyType.sponsor,
              percentage: 12.0,
            ),
          ],
        );

        // Test business logic: validation and amount calculation
        expect(multiParty.isRevenueSplitValid, isTrue);
        expect(revenueSplit.isValid, isTrue);
        // Net after fees:
        // total=2000.00, platformFee=10% (200.00),
        // processingFee=2.9% (58.00) + $0.30 * 25 tickets (7.50) = 65.50
        // => splitAmount = 2000.00 - 200.00 - 65.50 = 1734.50
        expect(revenueSplit.splitAmount, closeTo(1734.50, 0.01));
        final brand1Amount = revenueSplit.parties
            .firstWhere((p) => p.partyId == 'brand-1')
            .amount ?? 0.0;
        expect(brand1Amount, closeTo(312.21, 0.01)); // 18% of 1734.50
      });
    });

    group('Hybrid Sponsorship Revenue', () {
      test('should correctly calculate total brand revenue from ticket and product sales', () {
        // Test business logic: hybrid sponsorship revenue aggregation
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

        // Test business logic: total contribution and revenue aggregation
        expect(sponsorship.totalContributionValue, equals(700.00));
        final ticketBrandShare = ticketRevenueSplit.parties
            .firstWhere((p) => p.partyId == 'brand-789')
            .amount ?? 0.0;
        final productBrandShare = productTracking.revenueDistribution['brand-789'] ?? 0.0;
        final totalBrandRevenue = ticketBrandShare + productBrandShare;

        // Net after fees for ticketRevenueSplit:
        // total=1500.00, platformFee=10% (150.00),
        // processingFee=2.9% (43.50) + $0.30 * 20 tickets (6.00) = 49.50
        // => splitAmount = 1500.00 - 150.00 - 49.50 = 1300.50
        // brand share = 20% of 1300.50 = 260.10
        expect(ticketBrandShare, closeTo(260.10, 0.01));
        expect(productBrandShare, equals(202.50));
        expect(totalBrandRevenue, closeTo(462.60, 0.01));
      });
    });
  });
}
