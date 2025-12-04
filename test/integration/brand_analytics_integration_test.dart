import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/brand_analytics_service.dart';
import 'package:spots/core/services/sponsorship_service.dart';
import 'package:spots/core/services/product_tracking_service.dart';
import 'package:spots/core/services/product_sales_service.dart';
import 'package:spots/core/services/revenue_split_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/services/business_service.dart';
import 'package:spots/core/services/business_account_service.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/brand_account.dart';
import 'package:spots/core/models/unified_user.dart';
import '../../fixtures/model_factories.dart';

/// Integration tests for brand-analytics flow
/// 
/// Tests the integration between brand sponsorships and analytics:
/// 1. ROI tracking for brands
/// 2. Performance metrics
/// 3. Brand exposure analytics
/// 4. Event performance tracking
void main() {
  group('Brand-Analytics Integration Tests', () {
    late BrandAnalyticsService analyticsService;
    late SponsorshipService sponsorshipService;
    late ProductTrackingService productTrackingService;
    late ProductSalesService productSalesService;
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
      productTrackingService = ProductTrackingService(
        sponsorshipService: sponsorshipService,
        revenueSplitService: revenueSplitService,
      );
      productSalesService = ProductSalesService(
        productTrackingService: productTrackingService,
        revenueSplitService: revenueSplitService,
      );
      analyticsService = BrandAnalyticsService(
        sponsorshipService: sponsorshipService,
        productTrackingService: productTrackingService,
        productSalesService: productSalesService,
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

    test('brand ROI calculation flow', () async {
      // Step 1: Create sponsorship
      await sponsorshipService.registerBrand(testBrand);

      testSponsorship = await sponsorshipService.createSponsorship(
        eventId: testEvent.id,
        brandId: testBrand.id,
        type: SponsorshipType.financial,
        contributionAmount: 500.00,
        vibeCompatibilityScore: 0.75,
      );

      // Step 2: Calculate brand ROI
      final roi = await analyticsService.calculateBrandROI(
        brandId: testBrand.id,
      );

      // Assert
      expect(roi, isA<BrandROI>());
      expect(roi.brandId, equals(testBrand.id));
      expect(roi.totalInvestment, greaterThanOrEqualTo(0.0));
      expect(roi.totalRevenue, greaterThanOrEqualTo(0.0));
    });

    test('brand performance metrics flow', () async {
      // Step 1: Create sponsorship
      await sponsorshipService.registerBrand(testBrand);

      testSponsorship = await sponsorshipService.createSponsorship(
        eventId: testEvent.id,
        brandId: testBrand.id,
        type: SponsorshipType.financial,
        contributionAmount: 500.00,
        vibeCompatibilityScore: 0.75,
      );

      // Step 2: Get brand performance
      final performance = await analyticsService.getBrandPerformance(
        brandId: testBrand.id,
      );

      // Assert
      expect(performance, isA<BrandPerformance>());
      expect(performance.brandId, equals(testBrand.id));
      expect(performance.totalSponsorships, greaterThanOrEqualTo(0));
    });

    test('brand exposure analytics flow', () async {
      // Step 1: Create sponsorship
      await sponsorshipService.registerBrand(testBrand);

      testSponsorship = await sponsorshipService.createSponsorship(
        eventId: testEvent.id,
        brandId: testBrand.id,
        type: SponsorshipType.financial,
        contributionAmount: 500.00,
        vibeCompatibilityScore: 0.75,
      );

      // Step 2: Analyze brand exposure
      final exposure = await analyticsService.analyzeBrandExposure(
        brandId: testBrand.id,
        eventId: testEvent.id,
      );

      // Assert
      expect(exposure, isA<BrandExposure>());
      expect(exposure.brandId, equals(testBrand.id));
      expect(exposure.eventId, equals(testEvent.id));
    });

    test('event performance tracking flow', () async {
      // Step 1: Create sponsorship
      await sponsorshipService.registerBrand(testBrand);

      testSponsorship = await sponsorshipService.createSponsorship(
        eventId: testEvent.id,
        brandId: testBrand.id,
        type: SponsorshipType.financial,
        contributionAmount: 500.00,
        vibeCompatibilityScore: 0.75,
      );

      // Step 2: Get event performance
      final performance = await analyticsService.getEventPerformance(
        eventId: testEvent.id,
      );

      // Assert
      expect(performance, isA<EventPerformance>());
      expect(performance.eventId, equals(testEvent.id));
      expect(performance.totalSponsorships, greaterThanOrEqualTo(1));
      expect(performance.totalSponsorshipValue, greaterThanOrEqualTo(500.00));
    });
  });
}

