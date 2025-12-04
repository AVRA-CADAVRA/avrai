import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/services/sponsorship_service.dart';
import 'package:spots/core/services/revenue_split_service.dart';
import 'package:spots/core/services/stripe_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/services/business_service.dart';
import 'package:spots/core/services/business_account_service.dart';
import 'package:spots/core/config/stripe_config.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/models/brand_account.dart';
import 'package:spots/core/models/unified_user.dart';
import '../../fixtures/model_factories.dart';

/// Integration tests for brand-payment flow
/// 
/// Tests the integration between brand sponsorships and payment processing:
/// 1. Payment for event with brand sponsorship
/// 2. Revenue split calculation with brands
/// 3. Multi-party revenue distribution
void main() {
  group('Brand-Payment Integration Tests', () {
    late PaymentService paymentService;
    late SponsorshipService sponsorshipService;
    late RevenueSplitService revenueSplitService;
    late ExpertiseEventService eventService;
    late PartnershipService partnershipService;
    late BusinessService businessService;
    late UnifiedUser testUser;
    late ExpertiseEvent testEvent;
    late BrandAccount testBrand;
    late Sponsorship testSponsorship;

    setUp(() {
      eventService = ExpertiseEventService();
      final businessAccountService = BusinessAccountService();
      businessService = BusinessService(accountService: businessAccountService);
      partnershipService = PartnershipService(
        eventService: eventService,
        businessService: businessService,
      );
      sponsorshipService = SponsorshipService(
        eventService: eventService,
        partnershipService: partnershipService,
        businessService: businessService,
      );
      revenueSplitService = RevenueSplitService(
        partnershipService: partnershipService,
        sponsorshipService: sponsorshipService,
      );

      final stripeConfig = StripeConfig.test();
      final stripeService = StripeService(stripeConfig);
      paymentService = PaymentService(
        stripeService,
        eventService,
        partnershipService: partnershipService,
        revenueSplitService: revenueSplitService,
      );

      testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test User',
      );
      testUser = testUser.copyWith(
        expertiseMap: {
          'Coffee': 'city',
        },
      );

      testEvent = ExpertiseEvent(
        id: 'event-123',
        title: 'Brand Event',
        description: 'An event with brand sponsorship',
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

      testBrand = BrandAccount(
        id: 'brand-123',
        name: 'Test Brand',
        brandType: 'Coffee Roaster',
        contactEmail: 'test@brand.com',
        verificationStatus: BrandVerificationStatus.verified,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('payment for event with brand sponsorship calculates brand revenue split', () async {
      // Step 1: Register brand and create sponsorship
      await sponsorshipService.registerBrand(testBrand);

      testSponsorship = await sponsorshipService.createSponsorship(
        eventId: testEvent.id,
        brandId: testBrand.id,
        type: SponsorshipType.financial,
        contributionAmount: 500.00,
        vibeCompatibilityScore: 0.75,
      );

      // Approve sponsorship
      await sponsorshipService.updateSponsorshipStatus(
        sponsorshipId: testSponsorship.id,
        status: SponsorshipStatus.approved,
      );

      // Step 2: Initialize payment service
      await paymentService.initialize();

      // Step 3: Calculate brand revenue split
      final revenueSplit = await revenueSplitService.calculateNWayBrandSplit(
        eventId: testEvent.id,
        totalAmount: 1000.00,
        ticketsSold: 20,
      );

      // Assert
      expect(revenueSplit, isA<RevenueSplit>());
      expect(revenueSplit.parties, isNotEmpty);
      // Should include brand in parties
      expect(revenueSplit.parties.any((p) => p.partyId == testBrand.id), isTrue);
    });

    test('revenue split includes platform and processing fees for brand events', () async {
      // Step 1: Create sponsorship
      await sponsorshipService.registerBrand(testBrand);

      final sponsorship = await sponsorshipService.createSponsorship(
        eventId: testEvent.id,
        brandId: testBrand.id,
        type: SponsorshipType.financial,
        contributionAmount: 500.00,
        vibeCompatibilityScore: 0.75,
      );

      // Step 2: Calculate brand revenue split
      final revenueSplit = await revenueSplitService.calculateNWayBrandSplit(
        eventId: testEvent.id,
        totalAmount: 1000.00,
        ticketsSold: 20,
      );

      // Assert fees are calculated
      expect(revenueSplit.platformFee, equals(100.00)); // 10% of 1000.00
      expect(revenueSplit.processingFee, closeTo(30.80, 0.01)); // (1000 * 0.029) + (0.30 * 20)

      // Assert parties receive remaining amount
      final netAmount = revenueSplit.totalAmount - revenueSplit.platformFee - revenueSplit.processingFee;
      final totalPartyAmounts = revenueSplit.parties.fold<double>(
        0.0,
        (sum, party) => sum + (party.amount ?? 0.0),
      );
      expect(totalPartyAmounts, closeTo(netAmount, 0.01));
    });

    test('hybrid sponsorship split (cash + product)', () async {
      // Step 1: Create hybrid sponsorship
      await sponsorshipService.registerBrand(testBrand);

      final sponsorship = await sponsorshipService.createSponsorship(
        eventId: testEvent.id,
        brandId: testBrand.id,
        type: SponsorshipType.hybrid,
        contributionAmount: 500.00,
        productValue: 300.00,
        vibeCompatibilityScore: 0.75,
      );

      // Step 2: Calculate hybrid split
      final parties = [
        SplitParty(
          partyId: 'user-123',
          type: SplitPartyType.user,
          percentage: 40.0,
          name: 'User',
        ),
        SplitParty(
          partyId: 'brand-123',
          type: SplitPartyType.sponsor,
          percentage: 60.0,
          name: 'Brand',
        ),
      ];

      final splits = await revenueSplitService.calculateHybridSplit(
        eventId: testEvent.id,
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
  });
}

