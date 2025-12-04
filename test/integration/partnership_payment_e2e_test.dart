import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/payment.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/services/revenue_split_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/business_service.dart';
import 'package:spots/core/services/stripe_service.dart';
import '../helpers/integration_test_helpers.dart';
import '../fixtures/integration_test_fixtures.dart';

// Mock dependencies
class MockStripeService extends Mock implements StripeService {}
class MockExpertiseEventService extends Mock implements ExpertiseEventService {}
class MockBusinessService extends Mock implements BusinessService {}
class MockBusinessAccountService extends Mock implements BusinessAccountService {}

/// Partnership Payment End-to-End Integration Test
/// 
/// Agent 1: Backend & Integration (Week 8)
/// 
/// Tests complete partnership payment workflow end-to-end:
/// 1. Create partnership
/// 2. Approve partnership
/// 3. Lock revenue split
/// 4. Process payment
/// 5. Distribute payments to partners
/// 
/// **Full Workflow:**
/// - Complete partnership creation → payment → distribution flow
/// - Tests all integration points
/// - Validates revenue splits and payouts
void main() {
  group('Partnership Payment End-to-End Integration Tests', () {
    late PartnershipService partnershipService;
    late PaymentService paymentService;
    late RevenueSplitService revenueSplitService;
    late MockStripeService mockStripeService;
    late MockExpertiseEventService mockEventService;
    late MockBusinessService mockBusinessService;
    
    setUp(() {
      mockStripeService = MockStripeService();
      mockEventService = MockExpertiseEventService();
      mockBusinessService = MockBusinessService();
      
      partnershipService = PartnershipService(
        eventService: mockEventService,
        businessService: mockBusinessService,
      );
      
      revenueSplitService = RevenueSplitService(
        partnershipService: partnershipService,
      );
      
      paymentService = PaymentService(
        mockStripeService,
        mockEventService,
        partnershipService: partnershipService,
        revenueSplitService: revenueSplitService,
      );
      
      // Setup Stripe mock
      when(() => mockStripeService.isInitialized).thenReturn(true);
      when(() => mockStripeService.initializeStripe())
          .thenAnswer((_) async => {});
    });
    
    tearDown(() {
      reset(mockStripeService);
      reset(mockEventService);
      reset(mockBusinessService);
    });
    
    group('Full Partnership Payment Workflow', () {
      test('should complete full partnership payment workflow', () async {
        // ============================================
        // STEP 1: Create Event
        // ============================================
        final scenario = IntegrationTestFixtures.eventHostingScenario();
        final event = scenario['event'] as ExpertiseEvent;
        final host = scenario['host'] as UnifiedUser;
        final attendee = IntegrationTestHelpers.createTestUser();
        
        when(() => mockEventService.getEventById(any()))
            .thenAnswer((_) async => event);
        
        // ============================================
        // STEP 2: Create Partnership
        // ============================================
        final business = IntegrationTestHelpers.createTestBusinessAccount(
          id: 'business-1',
          name: 'Test Restaurant',
          isVerified: true,
        );
        
        when(() => mockBusinessService.getBusinessById(any()))
            .thenAnswer((_) async => business);
        when(() => mockBusinessService.checkBusinessEligibility(any()))
            .thenAnswer((_) async => true);
        
        final partnership = await partnershipService.createPartnership(
          eventId: event.id,
          userId: host.id,
          businessId: business.id,
          vibeCompatibilityScore: 0.80, // 80% compatibility
        );
        
        expect(partnership, isNotNull);
        expect(partnership.status, equals(PartnershipStatus.proposed));
        
        // ============================================
        // STEP 3: Approve Partnership
        // ============================================
        final userApproved = await partnershipService.approvePartnership(
          partnershipId: partnership.id,
          approvedBy: host.id,
        );
        
        expect(userApproved.userApproved, isTrue);
        
        final businessApproved = await partnershipService.approvePartnership(
          partnershipId: partnership.id,
          approvedBy: business.id,
        );
        
        expect(businessApproved.isApproved, isTrue);
        expect(businessApproved.status, equals(PartnershipStatus.locked));
        
        // ============================================
        // STEP 4: Create Revenue Split
        // ============================================
        when(() => partnershipService.getPartnershipById(any()))
            .thenAnswer((_) async => businessApproved);
        
        final revenueSplit = await revenueSplitService.calculateFromPartnership(
          partnershipId: partnership.id,
          totalAmount: 100.00,
          ticketsSold: 1,
        );
        
        expect(revenueSplit, isNotNull);
        expect(revenueSplit.partnershipId, equals(partnership.id));
        expect(revenueSplit.parties.length, equals(2)); // User + Business
        
        // ============================================
        // STEP 5: Lock Revenue Split (Pre-Event)
        // ============================================
        final lockedSplit = await revenueSplitService.lockSplit(
          revenueSplitId: revenueSplit.id,
          lockedBy: host.id,
        );
        
        expect(lockedSplit.isLocked, isTrue);
        expect(lockedSplit.lockedBy, equals(host.id));
        
        // ============================================
        // STEP 6: Process Payment
        // ============================================
        when(() => partnershipService.getPartnershipsForEvent(any()))
            .thenAnswer((_) async => [businessApproved]);
        when(() => revenueSplitService.calculateFromPartnership(
          partnershipId: any(named: 'partnershipId'),
          totalAmount: any(named: 'totalAmount'),
          ticketsSold: any(named: 'ticketsSold'),
        )).thenAnswer((_) async => lockedSplit);
        
        await paymentService.initialize();
        
        final paymentResult = await paymentService.purchaseEventTicket(
          eventId: event.id,
          userId: attendee.id,
          ticketPrice: event.price!,
          quantity: 1,
        );
        
        expect(paymentResult.isSuccess, isTrue);
        expect(paymentResult.revenueSplit, isNotNull);
        expect(paymentResult.revenueSplit!.parties.length, equals(2));
        
        // ============================================
        // STEP 7: Distribute Payments
        // ============================================
        when(() => revenueSplitService.getRevenueSplit(any()))
            .thenAnswer((_) async => lockedSplit);
        
        final payoutAmounts = await revenueSplitService.distributePayments(
          revenueSplitId: lockedSplit.id,
          eventEndTime: event.endTime,
        );
        
        expect(payoutAmounts.length, equals(2));
        expect(payoutAmounts[host.id], isNotNull);
        expect(payoutAmounts[business.id], isNotNull);
        
        // ============================================
        // VERIFY: Complete Workflow
        // ============================================
        // Partnership created and approved ✅
        // Revenue split created and locked ✅
        // Payment processed ✅
        // Payments distributed ✅
        
        expect(businessApproved.isLocked, isTrue);
        expect(lockedSplit.isLocked, isTrue);
        expect(paymentResult.isSuccess, isTrue);
        expect(payoutAmounts.isNotEmpty, isTrue);
      });
      
      test('should handle 3-party partnership correctly', () async {
        // Arrange: User + Business + Sponsor
        final event = IntegrationTestHelpers.createTestEvent(
          host: IntegrationTestHelpers.createExpertUser(),
        );
        final business = IntegrationTestHelpers.createTestBusinessAccount(
          id: 'business-1',
          isVerified: true,
        );
        
        // Create N-way split with 3 parties
        final revenueSplit = RevenueSplit.nWay(
          id: 'split-1',
          eventId: event.id,
          totalAmount: 1000.00,
          ticketsSold: 10,
          parties: [
            SplitParty(
              partyId: 'user-1',
              type: SplitPartyType.user,
              percentage: 40.0,
            ),
            SplitParty(
              partyId: 'business-1',
              type: SplitPartyType.business,
              percentage: 35.0,
            ),
            SplitParty(
              partyId: 'sponsor-1',
              type: SplitPartyType.sponsor,
              percentage: 25.0,
            ),
          ],
        );
        
        // Assert
        expect(revenueSplit.parties.length, equals(3));
        expect(revenueSplit.isValid, isTrue);
        
        // Verify split amounts
        final splitAmount = revenueSplit.splitAmount; // After fees
        expect(splitAmount, closeTo(870.00, 0.01)); // ~$1000 - $100 - $30
        
        // Verify party amounts
        expect(revenueSplit.parties[0].amount, closeTo(348.00, 0.01)); // 40% of $870
        expect(revenueSplit.parties[1].amount, closeTo(304.50, 0.01)); // 35% of $870
        expect(revenueSplit.parties[2].amount, closeTo(217.50, 0.01)); // 25% of $870
      });
    });
  });
}

