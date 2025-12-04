import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/brand_account.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/business_account.dart';
import 'package:spots/core/services/sponsorship_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/services/business_service.dart';
import '../helpers/integration_test_helpers.dart';
import '../fixtures/model_factories.dart';

// Mock dependencies
class MockExpertiseEventService extends Mock implements ExpertiseEventService {}
class MockPartnershipService extends Mock implements PartnershipService {}
class MockBusinessService extends Mock implements BusinessService {}

/// Sponsorship Services Integration Tests
/// 
/// Agent 1: Backend & Integration (Week 12)
/// 
/// Tests service-level integration for brand sponsorships:
/// - SponsorshipService CRUD operations
/// - Sponsorship eligibility checking
/// - Vibe compatibility matching (70%+ threshold)
/// - Status transitions
/// - Integration with Partnership service
/// 
/// **Test Scenarios:**
/// - Scenario 1: Sponsorship Creation Flow
/// - Scenario 2: Sponsorship Status Transitions
/// - Scenario 3: Eligibility Checking
/// - Scenario 4: Compatibility Calculation
/// - Scenario 5: Integration with Partnership Service
void main() {
  group('Sponsorship Services Integration Tests', () {
    late SponsorshipService sponsorshipService;
    late MockExpertiseEventService mockEventService;
    late MockPartnershipService mockPartnershipService;
    late MockBusinessService mockBusinessService;
    
    late DateTime testDate;
    late ExpertiseEvent testEvent;
    late UnifiedUser testUser;
    late BusinessAccount testBusiness;
    late BrandAccount testBrand;
    
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
      
      testEvent = IntegrationTestHelpers.createPaidEvent(
        host: testUser,
        id: 'event-456',
        title: 'Gourmet Dinner',
        category: 'Food & Beverage',
        price: 75.00,
      );
    });
    
    tearDown(() {
      reset(mockEventService);
      reset(mockPartnershipService);
      reset(mockBusinessService);
      TestHelpers.teardownTestEnvironment();
    });
    
    group('Scenario 1: Sponsorship Creation Flow', () {
      test('should create financial sponsorship successfully', () async {
        // Arrange
        when(() => mockEventService.getEventById('event-456'))
            .thenAnswer((_) async => testEvent);
        
        await sponsorshipService.registerBrand(testBrand);
        
        // Mock eligibility check
        when(() => mockPartnershipService.getPartnershipsForEvent('event-456'))
            .thenAnswer((_) async => []);
        
        // Act
        final sponsorship = await sponsorshipService.createSponsorship(
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          vibeCompatibilityScore: 0.75, // 75% compatibility
        );
        
        // Assert
        expect(sponsorship, isNotNull);
        expect(sponsorship.eventId, equals('event-456'));
        expect(sponsorship.brandId, equals('brand-123'));
        expect(sponsorship.type, equals(SponsorshipType.financial));
        expect(sponsorship.contributionAmount, equals(500.00));
        expect(sponsorship.status, equals(SponsorshipStatus.proposed));
      });
      
      test('should create product sponsorship successfully', () async {
        // Arrange
        when(() => mockEventService.getEventById('event-456'))
            .thenAnswer((_) async => testEvent);
        
        await sponsorshipService.registerBrand(testBrand);
        
        // Act
        final sponsorship = await sponsorshipService.createSponsorship(
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.product,
          productValue: 400.00,
          vibeCompatibilityScore: 0.80, // 80% compatibility
        );
        
        // Assert
        expect(sponsorship, isNotNull);
        expect(sponsorship.type, equals(SponsorshipType.product));
        expect(sponsorship.productValue, equals(400.00));
        expect(sponsorship.totalContributionValue, equals(400.00));
      });
      
      test('should create hybrid sponsorship successfully', () async {
        // Arrange
        when(() => mockEventService.getEventById('event-456'))
            .thenAnswer((_) async => testEvent);
        
        await sponsorshipService.registerBrand(testBrand);
        
        // Act
        final sponsorship = await sponsorshipService.createSponsorship(
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.hybrid,
          contributionAmount: 300.00,
          productValue: 400.00,
          vibeCompatibilityScore: 0.75,
        );
        
        // Assert
        expect(sponsorship, isNotNull);
        expect(sponsorship.type, equals(SponsorshipType.hybrid));
        expect(sponsorship.totalContributionValue, equals(700.00));
      });
      
      test('should throw exception if compatibility below 70%', () async {
        // Arrange
        when(() => mockEventService.getEventById('event-456'))
            .thenAnswer((_) async => testEvent);
        
        await sponsorshipService.registerBrand(testBrand);
        
        // Act & Assert
        expect(
          () => sponsorshipService.createSponsorship(
            eventId: 'event-456',
            brandId: 'brand-123',
            type: SponsorshipType.financial,
            contributionAmount: 500.00,
            vibeCompatibilityScore: 0.65, // 65% - below threshold
          ),
          throwsA(isA<Exception>()),
        );
      });
      
      test('should throw exception if event not found', () async {
        // Arrange
        when(() => mockEventService.getEventById('event-456'))
            .thenAnswer((_) async => null);
        
        // Act & Assert
        expect(
          () => sponsorshipService.createSponsorship(
            eventId: 'event-456',
            brandId: 'brand-123',
            type: SponsorshipType.financial,
            contributionAmount: 500.00,
          ),
          throwsA(isA<Exception>()),
        );
      });
      
      test('should throw exception if brand not verified', () async {
        // Arrange
        when(() => mockEventService.getEventById('event-456'))
            .thenAnswer((_) async => testEvent);
        
        final unverifiedBrand = testBrand.copyWith(
          verificationStatus: BrandVerificationStatus.pending,
        );
        await sponsorshipService.registerBrand(unverifiedBrand);
        
        // Act & Assert
        expect(
          () => sponsorshipService.createSponsorship(
            eventId: 'event-456',
            brandId: 'brand-123',
            type: SponsorshipType.financial,
            contributionAmount: 500.00,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
    
    group('Scenario 2: Sponsorship Status Transitions', () {
      test('should update sponsorship status through valid transitions', () async {
        // Arrange
        when(() => mockEventService.getEventById('event-456'))
            .thenAnswer((_) async => testEvent);
        
        await sponsorshipService.registerBrand(testBrand);
        
        final sponsorship = await sponsorshipService.createSponsorship(
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          vibeCompatibilityScore: 0.75,
        );
        
        // Act - Transition: proposed -> approved
        final approved = await sponsorshipService.updateSponsorshipStatus(
          sponsorshipId: sponsorship.id,
          status: SponsorshipStatus.approved,
        );
        
        // Assert
        expect(approved.status, equals(SponsorshipStatus.approved));
        expect(approved.isApproved, isTrue);
      });
      
      test('should reject invalid status transitions', () async {
        // Arrange
        when(() => mockEventService.getEventById('event-456'))
            .thenAnswer((_) async => testEvent);
        
        await sponsorshipService.registerBrand(testBrand);
        
        final sponsorship = await sponsorshipService.createSponsorship(
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          vibeCompatibilityScore: 0.75,
        );
        
        // Act & Assert - Cannot go directly from proposed to active
        expect(
          () => sponsorshipService.updateSponsorshipStatus(
            sponsorshipId: sponsorship.id,
            status: SponsorshipStatus.active,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
    
    group('Scenario 3: Eligibility Checking', () {
      test('should return true if sponsorship is eligible', () async {
        // Arrange
        when(() => mockEventService.getEventById('event-456'))
            .thenAnswer((_) async => testEvent);
        
        await sponsorshipService.registerBrand(testBrand);
        
        // Act
        final isEligible = await sponsorshipService.checkSponsorshipEligibility(
          eventId: 'event-456',
          brandId: 'brand-123',
        );
        
        // Assert
        expect(isEligible, isTrue);
      });
      
      test('should return false if event has started', () async {
        // Arrange
        final pastEvent = testEvent.copyWith(
          startTime: testDate.subtract(const Duration(days: 1)),
        );
        when(() => mockEventService.getEventById('event-456'))
            .thenAnswer((_) async => pastEvent);
        
        await sponsorshipService.registerBrand(testBrand);
        
        // Act
        final isEligible = await sponsorshipService.checkSponsorshipEligibility(
          eventId: 'event-456',
          brandId: 'brand-123',
        );
        
        // Assert
        expect(isEligible, isFalse);
      });
      
      test('should return false if brand not verified', () async {
        // Arrange
        when(() => mockEventService.getEventById('event-456'))
            .thenAnswer((_) async => testEvent);
        
        final unverifiedBrand = testBrand.copyWith(
          verificationStatus: BrandVerificationStatus.pending,
        );
        await sponsorshipService.registerBrand(unverifiedBrand);
        
        // Act
        final isEligible = await sponsorshipService.checkSponsorshipEligibility(
          eventId: 'event-456',
          brandId: 'brand-123',
        );
        
        // Assert
        expect(isEligible, isFalse);
      });
    });
    
    group('Scenario 4: Compatibility Calculation', () {
      test('should calculate compatibility between brand and event', () async {
        // Arrange
        when(() => mockEventService.getEventById('event-456'))
            .thenAnswer((_) async => testEvent);
        
        await sponsorshipService.registerBrand(testBrand);
        
        // Act
        final compatibility = await sponsorshipService.calculateCompatibility(
          eventId: 'event-456',
          brandId: 'brand-123',
        );
        
        // Assert
        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });
    });
    
    group('Scenario 5: Integration with Partnership Service', () {
      test('should get sponsorships for event with partnership', () async {
        // Arrange
        when(() => mockEventService.getEventById('event-456'))
            .thenAnswer((_) async => testEvent);
        
        when(() => mockPartnershipService.getPartnershipsForEvent('event-456'))
            .thenAnswer((_) async => [
              EventPartnership(
                id: 'partnership-123',
                eventId: 'event-456',
                userId: 'user-123',
                businessId: 'business-123',
                createdAt: testDate,
                updatedAt: testDate,
              ),
            ]);
        
        await sponsorshipService.registerBrand(testBrand);
        
        final sponsorship = await sponsorshipService.createSponsorship(
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          vibeCompatibilityScore: 0.75,
        );
        
        // Act
        final sponsorships = await sponsorshipService.getSponsorshipsForEvent('event-456');
        
        // Assert
        expect(sponsorships, isNotEmpty);
        expect(sponsorships.first.id, equals(sponsorship.id));
      });
    });
  });
}

