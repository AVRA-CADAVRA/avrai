import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/services/revenue_split_service.dart';
import 'package:spots/core/services/stripe_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/business_service.dart';
import 'package:spots/core/services/business_account_service.dart';
import 'package:spots/core/config/stripe_config.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/models/payment_result.dart';
import 'package:spots/core/models/unified_user.dart';
import '../../fixtures/model_factories.dart';

/// Integration tests for payment-partnership flow
/// 
/// Tests the integration between payment processing and partnerships:
/// 1. Payment for partnership event
/// 2. Revenue split calculation for partnerships
/// 3. Payment distribution to partnership parties
void main() {
  group('Payment-Partnership Integration Tests', () {
    late PaymentService paymentService;
    late PartnershipService partnershipService;
    late RevenueSplitService revenueSplitService;
    late ExpertiseEventService eventService;
    late BusinessService businessService;
    late UnifiedUser testUser;
    late ExpertiseEvent testEvent;
    late EventPartnership testPartnership;

    setUp(() {
      eventService = ExpertiseEventService();
      final businessAccountService = BusinessAccountService();
      businessService = BusinessService(accountService: businessAccountService);
      partnershipService = PartnershipService(
        eventService: eventService,
        businessService: businessService,
      );
      revenueSplitService = RevenueSplitService(
        partnershipService: partnershipService,
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
        title: 'Partnership Event',
        description: 'An event with partnership',
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
    });

    test('payment for partnership event calculates partnership revenue split', () async {
      // Step 1: Create business and partnership
      final business = await businessService.createBusinessAccount(
        name: 'Test Business',
        email: 'test@business.com',
        businessType: 'Restaurant',
        createdBy: 'user-123',
      );
      final verifiedBusiness = business.copyWith(isVerified: true);

      testPartnership = await partnershipService.createPartnership(
        eventId: testEvent.id,
        userId: testUser.id,
        businessId: verifiedBusiness.id,
        vibeCompatibilityScore: 0.75,
      );

      // Approve partnership
      await partnershipService.approvePartnership(
        partnershipId: testPartnership.id,
        approvedBy: testUser.id,
      );
      await partnershipService.approvePartnership(
        partnershipId: testPartnership.id,
        approvedBy: verifiedBusiness.id,
      );

      // Step 2: Initialize payment service
      await paymentService.initialize();

      // Step 3: Process payment for partnership event
      // Note: This test requires Stripe mocks or test mode
      // For now, we'll test the revenue split calculation directly

      // Verify partnership is detected
      final hasPartnership = await paymentService.hasPartnership(testEvent.id);
      expect(hasPartnership, isTrue);

      // Step 4: Calculate partnership revenue split
      final revenueSplit = await paymentService.calculatePartnershipRevenueSplit(
        eventId: testEvent.id,
        totalAmount: 100.00,
        ticketsSold: 4,
      );

      expect(revenueSplit, isA<RevenueSplit>());
      expect(revenueSplit.partnershipId, equals(testPartnership.id));
      expect(revenueSplit.parties, hasLength(2)); // User + Business
      expect(revenueSplit.parties[0].partyId, equals(testUser.id));
      expect(revenueSplit.parties[1].partyId, equals(verifiedBusiness.id));
    });

    test('revenue split includes platform and processing fees', () async {
      // Step 1: Create partnership
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

      // Step 2: Calculate revenue split
      final revenueSplit = await revenueSplitService.calculateFromPartnership(
        partnershipId: partnership.id,
        totalAmount: 100.00,
        ticketsSold: 4,
      );

      // Assert fees are calculated
      expect(revenueSplit.platformFee, equals(10.00)); // 10% of 100.00
      expect(revenueSplit.processingFee, closeTo(4.10, 0.01)); // (100 * 0.029) + (0.30 * 4)

      // Assert parties receive remaining amount
      final netAmount = revenueSplit.totalAmount - revenueSplit.platformFee - revenueSplit.processingFee;
      final totalPartyAmounts = revenueSplit.parties.fold<double>(
        0.0,
        (sum, party) => sum + (party.amount ?? 0.0),
      );
      expect(totalPartyAmounts, closeTo(netAmount, 0.01));
    });

    test('payment distribution to partnership parties', () async {
      // Step 1: Create partnership and revenue split
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

      final revenueSplit = await revenueSplitService.calculateFromPartnership(
        partnershipId: partnership.id,
        totalAmount: 100.00,
        ticketsSold: 4,
      );

      // Step 2: Lock revenue split
      final locked = await revenueSplitService.lockSplit(
        revenueSplitId: revenueSplit.id,
        lockedBy: testUser.id,
      );

      expect(locked.isLocked, isTrue);

      // Step 3: Distribute payments
      final eventEndTime = DateTime.now().add(const Duration(days: 7, hours: 2));
      final distribution = await revenueSplitService.distributePayments(
        revenueSplitId: locked.id,
        eventEndTime: eventEndTime,
      );

      expect(distribution, isA<Map<String, double>>());
      expect(distribution[testUser.id], isNotNull);
      expect(distribution[verifiedBusiness.id], isNotNull);
    });
  });
}
