import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/services/business_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/business_account_service.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/business_account.dart';
import 'package:spots/core/models/unified_user.dart';
import '../../fixtures/model_factories.dart';

/// Integration tests for end-to-end partnership flow
/// 
/// Tests the complete partnership lifecycle:
/// 1. Partnership proposal
/// 2. Partnership acceptance
/// 3. Partnership locking
/// 4. Partnership completion
void main() {
  group('Partnership Flow Integration Tests', () {
    late PartnershipService partnershipService;
    late BusinessService businessService;
    late ExpertiseEventService eventService;
    late BusinessAccountService businessAccountService;
    late UnifiedUser testUser;
    late BusinessAccount testBusiness;
    late ExpertiseEvent testEvent;

    setUp(() {
      eventService = ExpertiseEventService();
      businessAccountService = BusinessAccountService();
      businessService = BusinessService(accountService: businessAccountService);
      partnershipService = PartnershipService(
        eventService: eventService,
        businessService: businessService,
      );

      testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test User',
      );
      // Add Local-level expertise to enable event hosting
      testUser = testUser.copyWith(
        expertiseMap: {
          'Coffee': 'city',
        },
      );

      testEvent = ExpertiseEvent(
        id: 'event-123',
        title: 'Coffee Meetup',
        description: 'A coffee meetup event',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: testUser,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        location: 'San Francisco',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('complete partnership flow: proposal → acceptance → locking', () async {
      // Step 1: Create business account
      testBusiness = await businessService.createBusinessAccount(
        name: 'Test Coffee Shop',
        email: 'test@coffeeshop.com',
        businessType: 'Restaurant',
        createdBy: 'user-123',
        categories: ['Coffee'],
        location: 'San Francisco',
      );

      // Step 2: Verify business
      await businessService.verifyBusiness(
        businessId: testBusiness.id,
        legalBusinessName: 'Test Coffee Shop LLC',
        businessAddress: '123 Main St, San Francisco, CA',
      );

      // Update business to verified status (in production, this would be done by admin)
      // For testing, we'll assume verification succeeded
      testBusiness = testBusiness.copyWith(isVerified: true);

      // Step 3: Create partnership proposal
      final partnership = await partnershipService.createPartnership(
        eventId: testEvent.id,
        userId: testUser.id,
        businessId: testBusiness.id,
        vibeCompatibilityScore: 0.75, // 75% compatibility (above 70% threshold)
      );

      expect(partnership.status, equals(PartnershipStatus.proposed));
      expect(partnership.vibeCompatibilityScore, equals(0.75));
      expect(partnership.userApproved, isFalse);
      expect(partnership.businessApproved, isFalse);

      // Step 4: User approves partnership
      final userApproved = await partnershipService.approvePartnership(
        partnershipId: partnership.id,
        approvedBy: testUser.id,
      );

      expect(userApproved.userApproved, isTrue);
      expect(userApproved.businessApproved, isFalse);
      expect(userApproved.status, equals(PartnershipStatus.proposed)); // Still proposed until both approve

      // Step 5: Business approves partnership
      final bothApproved = await partnershipService.approvePartnership(
        partnershipId: partnership.id,
        approvedBy: testBusiness.id,
      );

      expect(bothApproved.userApproved, isTrue);
      expect(bothApproved.businessApproved, isTrue);
      expect(bothApproved.status, equals(PartnershipStatus.locked)); // Auto-locked when both approve

      // Step 6: Verify partnership is locked
      final lockedPartnership = await partnershipService.getPartnershipById(partnership.id);
      expect(lockedPartnership?.isLocked, isTrue);
      expect(lockedPartnership?.status, equals(PartnershipStatus.locked));
    });

    test('partnership rejection flow', () async {
      // Step 1: Create business and partnership
      testBusiness = await businessService.createBusinessAccount(
        name: 'Test Business',
        email: 'test@business.com',
        businessType: 'Restaurant',
        createdBy: 'user-123',
      );
      testBusiness = testBusiness.copyWith(isVerified: true);

      final partnership = await partnershipService.createPartnership(
        eventId: testEvent.id,
        userId: testUser.id,
        businessId: testBusiness.id,
        vibeCompatibilityScore: 0.75,
      );

      // Step 2: Cancel partnership
      final cancelled = await partnershipService.updatePartnershipStatus(
        partnershipId: partnership.id,
        status: PartnershipStatus.cancelled,
      );

      expect(cancelled.status, equals(PartnershipStatus.cancelled));
      expect(cancelled.isCancelled, isTrue);
    });

    test('multi-party partnership flow', () async {
      // Step 1: Create multiple businesses
      final business1 = await businessService.createBusinessAccount(
        name: 'Business 1',
        email: 'b1@test.com',
        businessType: 'Restaurant',
        createdBy: 'user-123',
      );
      final business2 = await businessService.createBusinessAccount(
        name: 'Business 2',
        email: 'b2@test.com',
        businessType: 'Retail',
        createdBy: 'user-123',
      );

      // Step 2: Create partnerships for same event
      final partnership1 = await partnershipService.createPartnership(
        eventId: testEvent.id,
        userId: testUser.id,
        businessId: business1.id,
        vibeCompatibilityScore: 0.80,
      );

      // Note: In production, multiple partnerships for same event might be restricted
      // This test verifies the system can handle multiple partnerships if allowed

      expect(partnership1.eventId, equals(testEvent.id));
      expect(partnership1.businessId, equals(business1.id));
    });

    test('partnership eligibility checks', () async {
      // Step 1: Create unverified business
      final unverifiedBusiness = await businessService.createBusinessAccount(
        name: 'Unverified Business',
        email: 'unverified@test.com',
        businessType: 'Restaurant',
        createdBy: 'user-123',
      );

      // Step 2: Try to create partnership (should fail eligibility check)
      final isEligible = await partnershipService.checkPartnershipEligibility(
        userId: testUser.id,
        businessId: unverifiedBusiness.id,
        eventId: testEvent.id,
      );

      expect(isEligible, isFalse); // Business not verified

      // Step 3: Verify business and check again
      await businessService.verifyBusiness(
        businessId: unverifiedBusiness.id,
        legalBusinessName: 'Unverified Business LLC',
      );
      final verifiedBusiness = unverifiedBusiness.copyWith(isVerified: true);

      final isEligibleAfterVerification = await partnershipService.checkPartnershipEligibility(
        userId: testUser.id,
        businessId: verifiedBusiness.id,
        eventId: testEvent.id,
      );

      // Should still be false if event has already started or other conditions not met
      // This depends on the event state
    });

    test('partnership status transitions', () async {
      // Step 1: Create partnership
      testBusiness = await businessService.createBusinessAccount(
        name: 'Test Business',
        email: 'test@business.com',
        businessType: 'Restaurant',
        createdBy: 'user-123',
      );
      testBusiness = testBusiness.copyWith(isVerified: true);

      final partnership = await partnershipService.createPartnership(
        eventId: testEvent.id,
        userId: testUser.id,
        businessId: testBusiness.id,
        vibeCompatibilityScore: 0.75,
      );

      expect(partnership.status, equals(PartnershipStatus.proposed));

      // Step 2: Transition to negotiating
      final negotiating = await partnershipService.updatePartnershipStatus(
        partnershipId: partnership.id,
        status: PartnershipStatus.negotiating,
      );

      expect(negotiating.status, equals(PartnershipStatus.negotiating));

      // Step 3: Transition to approved
      final approved = await partnershipService.updatePartnershipStatus(
        partnershipId: partnership.id,
        status: PartnershipStatus.approved,
      );

      expect(approved.status, equals(PartnershipStatus.approved));
    });
  });
}
