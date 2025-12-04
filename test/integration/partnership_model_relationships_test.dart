import 'package:flutter_test/flutter_test.dart';
import '../helpers/integration_test_helpers.dart';
import '../helpers/test_helpers.dart';
import '../fixtures/model_factories.dart';

/// Partnership Model Relationships Test
/// 
/// Agent 3: Models & Testing (Week 13)
/// 
/// Tests model relationships:
/// - Partnership ↔ Event
/// - Partnership ↔ Business
/// - Partnership ↔ Payment
/// - Partnership ↔ Revenue Split
/// 
/// **Test Scenarios:**
/// - Scenario 1: Partnership ↔ Event Relationship
/// - Scenario 2: Partnership ↔ Business Relationship
/// - Scenario 3: Partnership ↔ Payment Relationship
/// - Scenario 4: Partnership ↔ Revenue Split Relationship
/// - Scenario 5: Complete Relationship Chain
void main() {
  group('Partnership Model Relationships Test', () {
    late DateTime testDate;
    
    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });
    
    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });
    
    group('Scenario 1: Partnership ↔ Event Relationship', () {
      test('should maintain relationship between partnership and event', () {
        // Arrange
        final host = IntegrationTestHelpers.createExpertUser();
        final event = IntegrationTestHelpers.createPaidEvent(
          host: host,
          price: 50.00,
        );
        final business = IntegrationTestHelpers.createVerifiedBusinessAccount();
        
        // Create partnership with event reference
        final partnership = IntegrationTestHelpers.createTestPartnership(
          eventId: event.id,
          userId: host.id,
          businessId: business.id,
          vibeCompatibilityScore: 0.85,
        );
        
        // Verify relationship
        expect(partnership.eventId, equals(event.id));
        expect(partnership.userId, equals(host.id));
        expect(partnership.businessId, equals(business.id));
        
        // Partnership references event
        expect(partnership.eventId, isNotNull);
        expect(partnership.eventId, isNotEmpty);
      });
      
      test('should support multiple partnerships for same event', () {
        // Arrange
        final host = IntegrationTestHelpers.createExpertUser();
        final event = IntegrationTestHelpers.createPaidEvent(host: host);
        final business1 = IntegrationTestHelpers.createVerifiedBusinessAccount(
          id: 'business-1',
        );
        final business2 = IntegrationTestHelpers.createVerifiedBusinessAccount(
          id: 'business-2',
        );
        
        // Create multiple partnerships for same event
        final partnership1 = IntegrationTestHelpers.createTestPartnership(
          eventId: event.id,
          userId: host.id,
          businessId: business1.id,
        );
        final partnership2 = IntegrationTestHelpers.createTestPartnership(
          eventId: event.id,
          userId: host.id,
          businessId: business2.id,
        );
        
        // Verify both partnerships reference same event
        expect(partnership1.eventId, equals(event.id));
        expect(partnership2.eventId, equals(event.id));
        expect(partnership1.eventId, equals(partnership2.eventId));
        
        // Verify different business partners
        expect(partnership1.businessId, equals(business1.id));
        expect(partnership2.businessId, equals(business2.id));
        expect(partnership1.businessId, isNot(equals(partnership2.businessId)));
      });
    });
    
    group('Scenario 2: Partnership ↔ Business Relationship', () {
      test('should maintain relationship between partnership and business', () {
        // Arrange
        final host = IntegrationTestHelpers.createExpertUser();
        final event = IntegrationTestHelpers.createPaidEvent(host: host);
        final business = IntegrationTestHelpers.createVerifiedBusinessAccount(
          id: 'business-123',
          name: 'Test Restaurant',
        );
        
        // Create partnership with business reference
        final partnership = IntegrationTestHelpers.createTestPartnership(
          eventId: event.id,
          userId: host.id,
          businessId: business.id,
        );
        
        // Verify relationship
        expect(partnership.businessId, equals(business.id));
        expect(partnership.userId, equals(host.id));
        
        // Partnership references business
        expect(partnership.businessId, isNotNull);
        expect(partnership.businessId, isNotEmpty);
      });
      
      test('should support business with multiple partnerships', () {
        // Arrange
        final host1 = IntegrationTestHelpers.createExpertUser(id: 'host-1');
        final host2 = IntegrationTestHelpers.createExpertUser(id: 'host-2');
        final business = IntegrationTestHelpers.createVerifiedBusinessAccount(
          id: 'business-123',
        );
        final event1 = IntegrationTestHelpers.createPaidEvent(host: host1);
        final event2 = IntegrationTestHelpers.createPaidEvent(host: host2);
        
        // Create partnerships for same business with different events
        final partnership1 = IntegrationTestHelpers.createTestPartnership(
          eventId: event1.id,
          userId: host1.id,
          businessId: business.id,
        );
        final partnership2 = IntegrationTestHelpers.createTestPartnership(
          eventId: event2.id,
          userId: host2.id,
          businessId: business.id,
        );
        
        // Verify both partnerships reference same business
        expect(partnership1.businessId, equals(business.id));
        expect(partnership2.businessId, equals(business.id));
        expect(partnership1.businessId, equals(partnership2.businessId));
        
        // Verify different events
        expect(partnership1.eventId, equals(event1.id));
        expect(partnership2.eventId, equals(event2.id));
        expect(partnership1.eventId, isNot(equals(partnership2.eventId)));
      });
    });
    
    group('Scenario 3: Partnership ↔ Payment Relationship', () {
      test('should maintain relationship between partnership and payment', () {
        // Arrange
        final host = IntegrationTestHelpers.createExpertUser();
        final business = IntegrationTestHelpers.createVerifiedBusinessAccount();
        final event = IntegrationTestHelpers.createPaidEvent(
          host: host,
          price: 50.00,
        );
        final attendee = ModelFactories.createTestUser();
        
        // Create partnership
        final partnership = IntegrationTestHelpers.createApprovedPartnership(
          eventId: event.id,
          userId: host.id,
          businessId: business.id,
        );
        
        // Create payment for event with partnership
        final payment = IntegrationTestHelpers.createSuccessfulPayment(
          eventId: event.id,
          userId: attendee.id,
          amount: 50.00,
        );
        
        // Verify relationship
        expect(payment.eventId, equals(event.id));
        expect(partnership.eventId, equals(event.id));
        
        // Payment and partnership reference same event
        expect(payment.eventId, equals(partnership.eventId));
        
        // Payment can be linked to partnership through event
        // (Partnership service can find partnerships for event)
      });
      
      test('should support multiple payments for partnership event', () {
        // Arrange
        final host = IntegrationTestHelpers.createExpertUser();
        final business = IntegrationTestHelpers.createVerifiedBusinessAccount();
        final event = IntegrationTestHelpers.createPaidEvent(
          host: host,
          price: 25.00,
        );
        
        // Create partnership
        final partnership = IntegrationTestHelpers.createApprovedPartnership(
          eventId: event.id,
          userId: host.id,
          businessId: business.id,
        );
        
        // Create multiple payments
        final payment1 = IntegrationTestHelpers.createSuccessfulPayment(
          eventId: event.id,
          userId: 'attendee-1',
          amount: 25.00,
        );
        final payment2 = IntegrationTestHelpers.createSuccessfulPayment(
          eventId: event.id,
          userId: 'attendee-2',
          amount: 25.00,
        );
        
        // Verify all payments reference same event as partnership
        expect(payment1.eventId, equals(event.id));
        expect(payment2.eventId, equals(event.id));
        expect(partnership.eventId, equals(event.id));
        
        expect(payment1.eventId, equals(partnership.eventId));
        expect(payment2.eventId, equals(partnership.eventId));
      });
    });
    
    group('Scenario 4: Partnership ↔ Revenue Split Relationship', () {
      test('should maintain relationship between partnership and revenue split', () {
        // Arrange
        final host = IntegrationTestHelpers.createExpertUser();
        final business = IntegrationTestHelpers.createVerifiedBusinessAccount();
        final event = IntegrationTestHelpers.createPaidEvent(
          host: host,
          price: 100.00,
        );
        
        // Create partnership
        final partnership = IntegrationTestHelpers.createApprovedPartnership(
          eventId: event.id,
          userId: host.id,
          businessId: business.id,
        );
        
        // Create revenue split
        final revenueSplit = IntegrationTestHelpers.createTestRevenueSplit(
          eventId: event.id,
          totalAmount: 100.00,
          ticketsSold: 1,
        );
        
        // Link partnership to revenue split
        final partnershipWithSplit = partnership.copyWith(
          revenueSplitId: revenueSplit.id,
        );
        
        // Verify relationship
        expect(partnershipWithSplit.revenueSplitId, equals(revenueSplit.id));
        expect(partnershipWithSplit.eventId, equals(event.id));
        expect(revenueSplit.eventId, equals(event.id));
        
        // Partnership and revenue split reference same event
        expect(partnershipWithSplit.eventId, equals(revenueSplit.eventId));
      });
      
      test('should support revenue split with multiple partners', () {
        // Arrange
        final host = IntegrationTestHelpers.createExpertUser();
        final business1 = IntegrationTestHelpers.createVerifiedBusinessAccount(
          id: 'business-1',
        );
        final business2 = IntegrationTestHelpers.createVerifiedBusinessAccount(
          id: 'business-2',
        );
        final event = IntegrationTestHelpers.createPaidEvent(
          host: host,
          price: 150.00,
        );
        
        // Create partnerships
        final partnership1 = IntegrationTestHelpers.createApprovedPartnership(
          eventId: event.id,
          userId: host.id,
          businessId: business1.id,
        );
        final partnership2 = IntegrationTestHelpers.createApprovedPartnership(
          eventId: event.id,
          userId: host.id,
          businessId: business2.id,
        );
        
        // Create revenue split for multi-party event
        final revenueSplit = IntegrationTestHelpers.createTestRevenueSplit(
          eventId: event.id,
          totalAmount: 150.00,
          ticketsSold: 1,
        );
        
        // Link partnerships to revenue split
        final partnership1WithSplit = partnership1.copyWith(
          revenueSplitId: revenueSplit.id,
        );
        final partnership2WithSplit = partnership2.copyWith(
          revenueSplitId: revenueSplit.id,
        );
        
        // Verify relationships
        expect(partnership1WithSplit.revenueSplitId, equals(revenueSplit.id));
        expect(partnership2WithSplit.revenueSplitId, equals(revenueSplit.id));
        expect(partnership1WithSplit.eventId, equals(revenueSplit.eventId));
        expect(partnership2WithSplit.eventId, equals(revenueSplit.eventId));
        
        // All partnerships reference same revenue split
        expect(partnership1WithSplit.revenueSplitId, 
            equals(partnership2WithSplit.revenueSplitId));
      });
    });
    
    group('Scenario 5: Complete Relationship Chain', () {
      test('should maintain complete relationship chain: Event → Partnership → Business → Payment → Revenue Split', () {
        // Arrange
        final host = IntegrationTestHelpers.createExpertUser();
        final business = IntegrationTestHelpers.createVerifiedBusinessAccount();
        final event = IntegrationTestHelpers.createPaidEvent(
          host: host,
          price: 100.00,
        );
        final attendee = ModelFactories.createTestUser();
        
        // Create partnership (Event ↔ Partnership ↔ Business)
        final partnership = IntegrationTestHelpers.createApprovedPartnership(
          eventId: event.id,
          userId: host.id,
          businessId: business.id,
        );
        
        // Create payment (Event ↔ Payment)
        final payment = IntegrationTestHelpers.createSuccessfulPayment(
          eventId: event.id,
          userId: attendee.id,
          amount: 100.00,
        );
        
        // Create revenue split (Event ↔ Revenue Split)
        final revenueSplit = IntegrationTestHelpers.createTestRevenueSplit(
          eventId: event.id,
          totalAmount: 100.00,
          ticketsSold: 1,
        );
        
        // Link partnership to revenue split (Partnership ↔ Revenue Split)
        final partnershipWithSplit = partnership.copyWith(
          revenueSplitId: revenueSplit.id,
        );
        
        // Verify complete relationship chain
        // Event → Partnership
        expect(partnershipWithSplit.eventId, equals(event.id));
        
        // Partnership → Business
        expect(partnershipWithSplit.businessId, equals(business.id));
        expect(partnershipWithSplit.userId, equals(host.id));
        
        // Event → Payment
        expect(payment.eventId, equals(event.id));
        
        // Partnership → Revenue Split
        expect(partnershipWithSplit.revenueSplitId, equals(revenueSplit.id));
        
        // Revenue Split → Event
        expect(revenueSplit.eventId, equals(event.id));
        
        // All relationships maintained through event
        expect(partnershipWithSplit.eventId, equals(payment.eventId));
        expect(partnershipWithSplit.eventId, equals(revenueSplit.eventId));
        expect(payment.eventId, equals(revenueSplit.eventId));
      });
    });
  });
}

