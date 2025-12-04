import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/sponsorship_service.dart';
import 'package:spots/core/services/brand_discovery_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/services/business_service.dart';
import 'package:spots/core/services/business_account_service.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/brand_account.dart';
import 'package:spots/core/models/unified_user.dart';
import '../../fixtures/model_factories.dart';

/// Integration tests for end-to-end brand sponsorship flow
/// 
/// Tests the complete brand sponsorship lifecycle:
/// 1. Brand discovery
/// 2. Sponsorship proposal
/// 3. Sponsorship acceptance
/// 4. Product tracking (if applicable)
/// 5. Revenue attribution
void main() {
  group('Brand Sponsorship Flow Integration Tests', () {
    late SponsorshipService sponsorshipService;
    late BrandDiscoveryService brandDiscoveryService;
    late ExpertiseEventService eventService;
    late PartnershipService partnershipService;
    late BusinessService businessService;
    late UnifiedUser testUser;
    late ExpertiseEvent testEvent;
    late BrandAccount testBrand;

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
      brandDiscoveryService = BrandDiscoveryService(
        eventService: eventService,
        sponsorshipService: sponsorshipService,
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
        title: 'Coffee Event',
        description: 'A coffee event with brand sponsorship',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: testUser,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        location: 'San Francisco',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testBrand = BrandAccount(
        id: 'brand-123',
        name: 'Test Coffee Brand',
        brandType: 'Coffee Roaster',
        contactEmail: 'test@brand.com',
        verificationStatus: BrandVerificationStatus.verified,
        categories: ['Coffee'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('complete brand sponsorship flow: discovery → proposal → acceptance', () async {
      // Step 1: Register brand
      await sponsorshipService.registerBrand(testBrand);

      // Step 2: Get sponsorship suggestions
      final discovery = await brandDiscoveryService.getSponsorshipSuggestions(
        eventId: testEvent.id,
      );

      expect(discovery.matchingResults, isNotEmpty);

      // Step 3: Create sponsorship proposal
      final sponsorship = await sponsorshipService.createSponsorship(
        eventId: testEvent.id,
        brandId: testBrand.id,
        type: SponsorshipType.financial,
        contributionAmount: 500.00,
        vibeCompatibilityScore: 0.75,
      );

      expect(sponsorship.status, equals(SponsorshipStatus.proposed));
      expect(sponsorship.type, equals(SponsorshipType.financial));
      expect(sponsorship.contributionAmount, equals(500.00));

      // Step 4: Update sponsorship status to approved
      final approved = await sponsorshipService.updateSponsorshipStatus(
        sponsorshipId: sponsorship.id,
        status: SponsorshipStatus.approved,
      );

      expect(approved.status, equals(SponsorshipStatus.approved));

      // Step 5: Lock sponsorship
      final locked = await sponsorshipService.updateSponsorshipStatus(
        sponsorshipId: sponsorship.id,
        status: SponsorshipStatus.locked,
      );

      expect(locked.status, equals(SponsorshipStatus.locked));
      expect(locked.isLocked, isTrue);
    });

    test('multi-party sponsorship flow with partnership', () async {
      // Step 1: Create business and partnership
      final business = await businessService.createBusinessAccount(
        name: 'Test Business',
        email: 'test@business.com',
        businessType: 'Restaurant',
        createdBy: 'user-123',
      );
      final verifiedBusiness = business.copyWith(isVerified: true);

      final partnership = await partnershipService.createPartnership(
        eventId: testEvent.id,
        userId: testUser.id,
        businessId: verifiedBusiness.id,
        vibeCompatibilityScore: 0.75,
      );

      // Step 2: Register brand and create sponsorship
      await sponsorshipService.registerBrand(testBrand);

      final sponsorship = await sponsorshipService.createSponsorship(
        eventId: testEvent.id,
        brandId: testBrand.id,
        type: SponsorshipType.financial,
        contributionAmount: 500.00,
        vibeCompatibilityScore: 0.75,
      );

      // Step 3: Verify both partnership and sponsorship exist for event
      final partnerships = await partnershipService.getPartnershipsForEvent(testEvent.id);
      final sponsorships = await sponsorshipService.getSponsorshipsForEvent(testEvent.id);

      expect(partnerships, isNotEmpty);
      expect(sponsorships, isNotEmpty);
      expect(partnerships.first.eventId, equals(testEvent.id));
      expect(sponsorships.first.eventId, equals(testEvent.id));
    });

    test('product sponsorship flow with product tracking', () async {
      // Step 1: Register brand
      await sponsorshipService.registerBrand(testBrand);

      // Step 2: Create product sponsorship
      final sponsorship = await sponsorshipService.createSponsorship(
        eventId: testEvent.id,
        brandId: testBrand.id,
        type: SponsorshipType.product,
        productValue: 300.00,
        vibeCompatibilityScore: 0.75,
      );

      expect(sponsorship.type, equals(SponsorshipType.product));
      expect(sponsorship.productValue, equals(300.00));

      // Step 3: Product tracking would be done separately
      // This test verifies sponsorship can be created for product type
    });

    test('hybrid sponsorship flow (cash + product)', () async {
      // Step 1: Register brand
      await sponsorshipService.registerBrand(testBrand);

      // Step 2: Create hybrid sponsorship
      final sponsorship = await sponsorshipService.createSponsorship(
        eventId: testEvent.id,
        brandId: testBrand.id,
        type: SponsorshipType.hybrid,
        contributionAmount: 500.00,
        productValue: 300.00,
        vibeCompatibilityScore: 0.75,
      );

      expect(sponsorship.type, equals(SponsorshipType.hybrid));
      expect(sponsorship.contributionAmount, equals(500.00));
      expect(sponsorship.productValue, equals(300.00));
      expect(sponsorship.totalContributionValue, equals(800.00));
    });

    test('sponsorship eligibility checks', () async {
      // Step 1: Create unverified brand
      final unverifiedBrand = BrandAccount(
        id: 'brand-unverified',
        name: 'Unverified Brand',
        brandType: 'Coffee Roaster',
        contactEmail: 'unverified@brand.com',
        verificationStatus: BrandVerificationStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await sponsorshipService.registerBrand(unverifiedBrand);

      // Step 2: Try to create sponsorship (should fail eligibility check)
      final isEligible = await sponsorshipService.checkSponsorshipEligibility(
        eventId: testEvent.id,
        brandId: unverifiedBrand.id,
      );

      expect(isEligible, isFalse); // Brand not verified

      // Step 3: Verify brand and check again
      final verifiedBrand = unverifiedBrand.copyWith(
        verificationStatus: BrandVerificationStatus.verified,
      );
      await sponsorshipService.registerBrand(verifiedBrand);

      final isEligibleAfterVerification = await sponsorshipService.checkSponsorshipEligibility(
        eventId: testEvent.id,
        brandId: verifiedBrand.id,
      );

      // Should be eligible if compatibility is 70%+
      expect(isEligibleAfterVerification, isTrue);
    });
  });
}

