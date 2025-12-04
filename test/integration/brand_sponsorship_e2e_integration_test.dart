import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/brand_account.dart';
import 'package:spots/core/models/brand_discovery.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/product_tracking.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/models/payment.dart';
import 'package:spots/core/models/payment_status.dart';
import 'package:spots/core/services/sponsorship_service.dart';
import 'package:spots/core/services/brand_discovery_service.dart';
import 'package:spots/core/services/product_tracking_service.dart';
import 'package:spots/core/services/revenue_split_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/services/business_service.dart';
import '../helpers/integration_test_helpers.dart';
import '../fixtures/model_factories.dart';

// Mock dependencies
class MockExpertiseEventService extends Mock implements ExpertiseEventService {}
class MockPartnershipService extends Mock implements PartnershipService {}
class MockBusinessService extends Mock implements BusinessService {}

/// Brand Sponsorship End-to-End Integration Tests
/// 
/// Agent 1: Backend & Integration (Week 12)
/// 
/// Tests complete end-to-end workflows for brand sponsorship:
/// - Complete brand discovery → sponsorship → payment flow
/// - Complete product sponsorship → sales → revenue attribution flow
/// - Complete hybrid sponsorship flow
/// - Complete multi-party sponsorship flow
/// 
/// **Test Scenarios:**
/// - Scenario 1: Complete Brand Discovery → Sponsorship → Payment Flow
/// - Scenario 2: Complete Product Sponsorship → Sales → Revenue Attribution Flow
/// - Scenario 3: Complete Hybrid Sponsorship Flow
/// - Scenario 4: Complete Multi-Party Sponsorship Flow
/// - Scenario 5: Complete Sponsorship Approval Workflow
void main() {
  group('Brand Sponsorship End-to-End Integration Tests', () {
    late SponsorshipService sponsorshipService;
    late BrandDiscoveryService brandDiscoveryService;
    late ProductTrackingService productTrackingService;
    late RevenueSplitService revenueSplitService;
    
    late MockExpertiseEventService mockEventService;
    late MockPartnershipService mockPartnershipService;
    late MockBusinessService mockBusinessService;
    
    late DateTime testDate;
    late ExpertiseEvent testEvent;
    late UnifiedUser testUser;
    late BusinessAccount testBusiness;
    late BrandAccount testBrand;
    late EventPartnership testPartnership;
    
    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      
      mockEventService = MockExpertiseEventService();
      mockPartnershipService = MockPartnershipService();
      mockBusinessService = MockBusinessService();
      
      sponsorshipService = SponsorshipService(
        eventService: mockEventService,
        partnershipService: mockPartnershipService,
        businessService: mockBusinessService,
      );
      
      brandDiscoveryService = BrandDiscoveryService(
        eventService: mockEventService,
        sponsorshipService: sponsorshipService,
      );
      
      productTrackingService = ProductTrackingService(
        sponsorshipService: sponsorshipService,
        revenueSplitService: null, // Optional for now
      );
      
      revenueSplitService = RevenueSplitService(
        partnershipService: mockPartnershipService,
        sponsorshipService: sponsorshipService,
        productTrackingService: productTrackingService,
      );
      
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
        categories: ['Gourmet', 'Premium Products'],
        contactEmail: 'partnerships@premiumoil.com',
        verificationStatus: BrandVerificationStatus.verified,
        createdAt: testDate,
        updatedAt: testDate,
      );
      
      testEvent = IntegrationTestHelpers.createPaidEvent(
        host: testUser,
        id: 'event-456',
        title: 'Gourmet Dinner',
        category: 'Food & Beverage',
        price: 75.00,
        startTime: testDate.add(const Duration(days: 7)),
      );
      
      testPartnership = EventPartnership(
        id: 'partnership-123',
        eventId: 'event-456',
        userId: 'user-123',
        businessId: 'business-123',
        status: PartnershipStatus.approved,
        createdAt: testDate,
        updatedAt: testDate,
      );
      
      // Setup common mocks
      when(() => mockEventService.getEventById('event-456'))
          .thenAnswer((_) async => testEvent);
      
      when(() => mockPartnershipService.getPartnershipsForEvent('event-456'))
          .thenAnswer((_) async => [testPartnership]);
      
      when(() => mockPartnershipService.getPartnershipById('partnership-123'))
          .thenAnswer((_) async => testPartnership);
    });
    
    tearDown(() {
      reset(mockEventService);
      reset(mockPartnershipService);
      reset(mockBusinessService);
      TestHelpers.teardownTestEnvironment();
    });
    
    group('Scenario 1: Complete Brand Discovery → Sponsorship → Payment Flow', () {
      test('should complete full workflow from discovery to revenue split', () async {
        // Step 1: Register brand
        await brandDiscoveryService.registerBrand(testBrand);
        await sponsorshipService.registerBrand(testBrand);
        
        // Step 2: Brand discovery - find brands for event
        final brandMatches = await brandDiscoveryService.findBrandsForEvent(
          eventId: 'event-456',
          minCompatibility: 0.70,
        );
        
        expect(brandMatches, isNotEmpty);
        expect(brandMatches.first.brandId, equals('brand-123'));
        expect(brandMatches.first.compatibilityScore, greaterThanOrEqualTo(70.0));
        
        // Step 3: Create sponsorship
        final sponsorship = await sponsorshipService.createSponsorship(
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          vibeCompatibilityScore: brandMatches.first.compatibilityScore / 100.0,
        );
        
        expect(sponsorship.status, equals(SponsorshipStatus.proposed));
        
        // Step 4: Approve sponsorship
        final approvedSponsorship = await sponsorshipService.updateSponsorshipStatus(
          sponsorshipId: sponsorship.id,
          status: SponsorshipStatus.approved,
        );
        
        expect(approvedSponsorship.status, equals(SponsorshipStatus.approved));
        
        // Step 5: Lock sponsorship
        final lockedSponsorship = await sponsorshipService.updateSponsorshipStatus(
          sponsorshipId: approvedSponsorship.id,
          status: SponsorshipStatus.locked,
        );
        
        expect(lockedSponsorship.isLocked, isTrue);
        
        // Step 6: Calculate revenue split
        final revenueSplit = await revenueSplitService.calculateNWayBrandSplit(
          eventId: 'event-456',
          totalAmount: 1500.00,
          ticketsSold: 20,
        );
        
        expect(revenueSplit.isValid, isTrue);
        expect(revenueSplit.parties.length, greaterThanOrEqualTo(3)); // user + business + brand
        
        // Step 7: Lock revenue split
        final lockedSplit = await revenueSplitService.lockSplit(
          revenueSplitId: revenueSplit.id,
          lockedBy: 'user-123',
        );
        
        expect(lockedSplit.isLocked, isTrue);
        
        // Step 8: Distribute payments (simulated after event)
        final distribution = await revenueSplitService.distributePayments(
          revenueSplitId: lockedSplit.id,
          eventEndTime: testEvent.startTime.add(const Duration(hours: 3)),
        );
        
        expect(distribution, isNotEmpty);
        expect(distribution.values.every((amount) => amount > 0), isTrue);
      });
    });
    
    group('Scenario 2: Complete Product Sponsorship → Sales → Revenue Attribution Flow', () {
      test('should complete full product sponsorship workflow', () async {
        // Step 1: Register brand
        await sponsorshipService.registerBrand(testBrand);
        
        // Step 2: Create product sponsorship
        final sponsorship = await sponsorshipService.createSponsorship(
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.product,
          productValue: 500.00,
          vibeCompatibilityScore: 0.75,
        );
        
        expect(sponsorship.type, equals(SponsorshipType.product));
        
        // Step 3: Record product contribution
        final productTracking = await productTrackingService.recordProductContribution(
          sponsorshipId: sponsorship.id,
          productName: 'Premium Olive Oil',
          quantityProvided: 20,
          unitPrice: 25.00,
        );
        
        expect(productTracking.quantityProvided, equals(20));
        expect(productTracking.quantityRemaining, equals(20));
        
        // Step 4: Record product sales
        final updatedTracking = await productTrackingService.recordProductSale(
          productTrackingId: productTracking.id,
          quantity: 5,
          buyerId: 'buyer-123',
          salePrice: 25.00,
        );
        
        expect(updatedTracking.quantitySold, equals(5));
        expect(updatedTracking.totalSales, equals(125.00));
        expect(updatedTracking.platformFee, closeTo(12.50, 0.01)); // 10% of 125
        
        // Step 5: Calculate revenue attribution
        final attribution = await productTrackingService.calculateRevenueAttribution(
          productTrackingId: updatedTracking.id,
        );
        
        expect(attribution, isNotEmpty);
        expect(attribution.containsKey('brand-123'), isTrue);
      });
    });
    
    group('Scenario 3: Complete Hybrid Sponsorship Flow', () {
      test('should complete full hybrid sponsorship workflow', () async {
        // Step 1: Register brand
        await sponsorshipService.registerBrand(testBrand);
        
        // Step 2: Create hybrid sponsorship
        final sponsorship = await sponsorshipService.createSponsorship(
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.hybrid,
          contributionAmount: 300.00,
          productValue: 400.00,
          vibeCompatibilityScore: 0.75,
        );
        
        expect(sponsorship.type, equals(SponsorshipType.hybrid));
        expect(sponsorship.totalContributionValue, equals(700.00));
        
        // Step 3: Record product contribution
        final productTracking = await productTrackingService.recordProductContribution(
          sponsorshipId: sponsorship.id,
          productName: 'Premium Olive Oil',
          quantityProvided: 15,
          unitPrice: 25.00,
        );
        
        // Step 4: Record product sales
        await productTrackingService.recordProductSale(
          productTrackingId: productTracking.id,
          quantity: 10,
          buyerId: 'buyer-123',
        );
        
        // Step 5: Calculate revenue splits (cash + product)
        final cashSplit = await revenueSplitService.calculateNWayBrandSplit(
          eventId: 'event-456',
          totalAmount: 1500.00, // Ticket sales
          ticketsSold: 20,
        );
        
        final productSalesAmount = 250.00; // 10 * 25
        final productSplit = await revenueSplitService.calculateProductSalesSplit(
          productTrackingId: productTracking.id,
          totalSales: productSalesAmount,
        );
        
        expect(cashSplit.isValid, isTrue);
        expect(productSplit.isValid, isTrue);
      });
    });
    
    group('Scenario 4: Complete Multi-Party Sponsorship Flow', () {
      test('should complete workflow with multiple brands', () async {
        // Step 1: Register multiple brands
        final brand1 = testBrand.copyWith(id: 'brand-1');
        final brand2 = testBrand.copyWith(id: 'brand-2');
        
        await sponsorshipService.registerBrand(brand1);
        await sponsorshipService.registerBrand(brand2);
        
        // Step 2: Create sponsorships for both brands
        final sponsorship1 = await sponsorshipService.createSponsorship(
          eventId: 'event-456',
          brandId: 'brand-1',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          vibeCompatibilityScore: 0.75,
        );
        
        final sponsorship2 = await sponsorshipService.createSponsorship(
          eventId: 'event-456',
          brandId: 'brand-2',
          type: SponsorshipType.financial,
          contributionAmount: 300.00,
          vibeCompatibilityScore: 0.80,
        );
        
        // Step 3: Approve both sponsorships
        await sponsorshipService.updateSponsorshipStatus(
          sponsorshipId: sponsorship1.id,
          status: SponsorshipStatus.approved,
        );
        
        await sponsorshipService.updateSponsorshipStatus(
          sponsorshipId: sponsorship2.id,
          status: SponsorshipStatus.approved,
        );
        
        // Step 4: Calculate N-way revenue split with multiple brands
        final revenueSplit = await revenueSplitService.calculateNWayBrandSplit(
          eventId: 'event-456',
          totalAmount: 2000.00,
          ticketsSold: 25,
        );
        
        expect(revenueSplit.isValid, isTrue);
        
        final sponsorParties = revenueSplit.parties
            .where((p) => p.type == SplitPartyType.sponsor)
            .toList();
        
        expect(sponsorParties.length, equals(2));
      });
    });
    
    group('Scenario 5: Complete Sponsorship Approval Workflow', () {
      test('should complete full approval workflow', () async {
        // Step 1: Register brand
        await sponsorshipService.registerBrand(testBrand);
        
        // Step 2: Create sponsorship (proposed)
        var sponsorship = await sponsorshipService.createSponsorship(
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          vibeCompatibilityScore: 0.75,
        );
        
        expect(sponsorship.status, equals(SponsorshipStatus.proposed));
        
        // Step 3: Negotiate (optional step)
        sponsorship = await sponsorshipService.updateSponsorshipStatus(
          sponsorshipId: sponsorship.id,
          status: SponsorshipStatus.negotiating,
        );
        
        expect(sponsorship.status, equals(SponsorshipStatus.negotiating));
        
        // Step 4: Approve
        sponsorship = await sponsorshipService.updateSponsorshipStatus(
          sponsorshipId: sponsorship.id,
          status: SponsorshipStatus.approved,
        );
        
        expect(sponsorship.status, equals(SponsorshipStatus.approved));
        expect(sponsorship.isApproved, isTrue);
        
        // Step 5: Lock (before event)
        sponsorship = await sponsorshipService.updateSponsorshipStatus(
          sponsorshipId: sponsorship.id,
          status: SponsorshipStatus.locked,
        );
        
        expect(sponsorship.isLocked, isTrue);
        expect(sponsorship.canBeModified, isFalse);
        
        // Step 6: Activate (event starts)
        sponsorship = await sponsorshipService.updateSponsorshipStatus(
          sponsorshipId: sponsorship.id,
          status: SponsorshipStatus.active,
        );
        
        expect(sponsorship.isActive, isTrue);
        
        // Step 7: Complete (event ends)
        sponsorship = await sponsorshipService.updateSponsorshipStatus(
          sponsorshipId: sponsorship.id,
          status: SponsorshipStatus.completed,
        );
        
        expect(sponsorship.status, equals(SponsorshipStatus.completed));
      });
    });
  });
}

