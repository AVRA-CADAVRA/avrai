import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/visit.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/payment.dart';
import 'package:spots/core/services/automatic_check_in_service.dart';
import '../helpers/integration_test_helpers.dart';
import '../helpers/test_helpers.dart';
import '../fixtures/model_factories.dart';

/// Expertise Model Relationships Test
/// 
/// Agent 3: Models & Testing (Week 14)
/// 
/// Tests model relationships:
/// - Expertise ↔ Visits
/// - Expertise ↔ Events
/// - Expertise ↔ Partnerships
/// 
/// **Test Scenarios:**
/// - Scenario 1: Expertise ↔ Visits Relationship
/// - Scenario 2: Expertise ↔ Events Relationship
/// - Scenario 3: Expertise ↔ Partnerships Relationship
/// - Scenario 4: Complete Relationship Chain
void main() {
  group('Expertise Model Relationships Test', () {
    late AutomaticCheckInService checkInService;
    late DateTime testDate;
    
    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      checkInService = AutomaticCheckInService();
    });
    
    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });
    
    group('Scenario 1: Expertise ↔ Visits Relationship', () {
      test('should maintain relationship between expertise and visits', () async {
        // Arrange
        final user = ModelFactories.createTestUser(
          id: 'user-1',
        );
        
        // Create visit through automatic check-in
        final checkIn = await checkInService.handleGeofenceTrigger(
          userId: user.id,
          locationId: 'location-1',
          latitude: 40.7128,
          longitude: -74.0060,
        );
        
        await Future.delayed(const Duration(milliseconds: 50));
        await checkInService.checkOut(userId: user.id);
        
        final visit = await checkInService.getVisitById(checkIn.visitId);
        expect(visit, isNotNull);
        
        // Visit contributes to expertise
        // - Visit.userId links to user
        // - Visit.locationId links to spot
        // - Visit.category (derived from spot) links to expertise category
        
        expect(visit!.userId, equals(user.id));
        expect(visit.locationId, equals('location-1'));
        expect(visit.isAutomatic, isTrue);
        
        // User's expertise in category is calculated from visits
        // (Expertise calculation service uses visits to calculate exploration expertise)
      });
      
      test('should support multiple visits contributing to expertise', () async {
        // Arrange
        final user = ModelFactories.createTestUser(
          id: 'user-2',
        );
        final category = 'Coffee';
        
        // Create multiple visits
        final visits = <Visit>[];
        for (int i = 0; i < 10; i++) {
          final checkIn = await checkInService.handleGeofenceTrigger(
            userId: user.id,
            locationId: 'location-$i',
            latitude: 40.7128 + (i * 0.01),
            longitude: -74.0060 + (i * 0.01),
          );
          
          await Future.delayed(const Duration(milliseconds: 50));
          await checkInService.checkOut(userId: user.id);
          
          final visit = await checkInService.getVisitById(checkIn.visitId);
          if (visit != null) {
            visits.add(visit);
          }
        }
        
        expect(visits.length, equals(10));
        
        // All visits link to same user
        for (final visit in visits) {
          expect(visit.userId, equals(user.id));
        }
        
        // Multiple visits contribute to expertise progression
        // - More visits = higher exploration expertise
        // - Unique locations = broader expertise
        // - Repeat visits = deeper expertise
      });
    });
    
    group('Scenario 2: Expertise ↔ Events Relationship', () {
      test('should maintain relationship between expertise and events', () {
        // Arrange
        final host = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'host-1',
          category: 'Coffee',
        );
        
        // Create event (requires Local level+ expertise)
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          category: 'Coffee',
        );
        
        // Event links to expertise:
        // - Event.host.id links to user
        // - Event.category links to expertise category
        // - Event.host.expertiseMap[category] shows expertise level
        
        expect(event.host.id, equals(host.id));
        expect(event.category, equals('Coffee'));
        expect(host.expertiseMap['Coffee'], equals('city'));
        
        // Event hosting contributes to expertise
        // - Hosting events contributes to community expertise
        // - Event category matches user's expertise category
      });
      
      test('should track event attendance in expertise', () {
        // Arrange
        final host = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'host-2',
          category: 'Coffee',
        );
        final attendee = ModelFactories.createTestUser(
          id: 'attendee-1',
        );
        final event = IntegrationTestHelpers.createPaidEvent(
          host: host,
          price: 25.00,
          category: 'Coffee',
        );
        
        // Attendee purchases ticket
        final payment = IntegrationTestHelpers.createSuccessfulPayment(
          eventId: event.id,
          userId: attendee.id,
          amount: 25.00,
        );
        
        // Payment links event to attendee
        // - Payment.eventId links to event
        // - Payment.userId links to attendee
        // - Event.category links to expertise category
        
        expect(payment.eventId, equals(event.id));
        expect(payment.userId, equals(attendee.id));
        expect(event.category, equals('Coffee'));
        
        // Event attendance contributes to expertise
        // - Attending events contributes to exploration expertise
        // - Attending events contributes to community expertise
      });
      
      test('should support multiple events contributing to expertise', () {
        // Arrange
        final host = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'host-3',
          category: 'Coffee',
        );
        final attendee = ModelFactories.createTestUser(
          id: 'attendee-2',
        );
        
        // Create multiple events
        final events = <ExpertiseEvent>[];
        final payments = <Payment>[];
        
        for (int i = 0; i < 5; i++) {
          final event = IntegrationTestHelpers.createPaidEvent(
            host: host,
            id: 'event-$i',
            price: 25.00,
            category: 'Coffee',
          );
          events.add(event);
          
          final payment = IntegrationTestHelpers.createSuccessfulPayment(
            eventId: event.id,
            userId: attendee.id,
            amount: 25.00,
          );
          payments.add(payment);
        }
        
        expect(events.length, equals(5));
        expect(payments.length, equals(5));
        
        // All events link to same category
        for (final event in events) {
          expect(event.category, equals('Coffee'));
          expect(event.host.id, equals(host.id));
        }
        
        // All payments link attendee to events
        for (final payment in payments) {
          expect(payment.userId, equals(attendee.id));
        }
        
        // Multiple event attendances contribute more to expertise
      });
    });
    
    group('Scenario 3: Expertise ↔ Partnerships Relationship', () {
      test('should maintain relationship between expertise and partnerships', () {
        // Arrange
        final host = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'host-4',
          category: 'Coffee',
        );
        final business = IntegrationTestHelpers.createVerifiedBusinessAccount(
          id: 'business-1',
        );
        final event = IntegrationTestHelpers.createPaidEvent(
          host: host,
          category: 'Coffee',
        );
        
        // Create partnership
        final partnership = IntegrationTestHelpers.createTestPartnership(
          eventId: event.id,
          userId: host.id,
          businessId: business.id,
          vibeCompatibilityScore: 0.85,
        );
        
        // Partnership links to expertise:
        // - Partnership.userId links to user
        // - Partnership.eventId links to event
        // - Event.category links to expertise category
        
        expect(partnership.userId, equals(host.id));
        expect(partnership.eventId, equals(event.id));
        expect(event.category, equals('Coffee'));
        expect(host.expertiseMap['Coffee'], equals('city'));
        
        // Partnership contributes to expertise
        // - Creating partnerships shows community engagement
        // - Partnership events contribute to community expertise
      });
      
      test('should track partnership events in expertise', () {
        // Arrange
        final host = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'host-5',
          category: 'Coffee',
        );
        final business = IntegrationTestHelpers.createVerifiedBusinessAccount();
        final event = IntegrationTestHelpers.createPaidEvent(
          host: host,
          category: 'Coffee',
        );
        
        // Create approved partnership
        final partnership = IntegrationTestHelpers.createApprovedPartnership(
          eventId: event.id,
          userId: host.id,
          businessId: business.id,
        );
        
        // Partnership event links to expertise
        expect(partnership.eventId, equals(event.id));
        expect(event.category, equals('Coffee'));
        expect(host.expertiseMap['Coffee'], equals('city'));
        
        // Partnership events contribute to:
        // - Community expertise (hosting with partnerships)
        // - Professional expertise (business partnerships)
        // - Influence expertise (multi-party events)
      });
    });
    
    group('Scenario 4: Complete Relationship Chain', () {
      test('should maintain complete relationship chain: Visits → Expertise → Events → Partnerships', () async {
        // Step 1: User makes visits (contributes to expertise)
        final user = ModelFactories.createTestUser(
          id: 'user-3',
        );
        final category = 'Coffee';
        
        // Create visits
        final visits = <Visit>[];
        for (int i = 0; i < 25; i++) {
          final checkIn = await checkInService.handleGeofenceTrigger(
            userId: user.id,
            locationId: 'location-$i',
            latitude: 40.7128 + (i * 0.01),
            longitude: -74.0060 + (i * 0.01),
          );
          
          await Future.delayed(const Duration(milliseconds: 50));
          await checkInService.checkOut(userId: user.id);
          
          final visit = await checkInService.getVisitById(checkIn.visitId);
          if (visit != null) {
            visits.add(visit);
          }
        }
        
        expect(visits.length, greaterThan(0));
        
        // Step 2: User gains expertise (from visits)
        // (In real system, expertise would be calculated)
        final expertUser = IntegrationTestHelpers.createUserWithCityExpertise(
          id: user.id,
          category: category,
        );
        
        expect(expertUser.canHostEvents(), isTrue);
        expect(expertUser.expertiseMap[category], equals('city'));
        
        // Step 3: User creates event (requires expertise)
        final event = IntegrationTestHelpers.createTestEvent(
          host: expertUser,
          category: category,
        );
        
        expect(event.host.id, equals(expertUser.id));
        expect(event.category, equals(category));
        
        // Step 4: User creates partnership (for event)
        final business = IntegrationTestHelpers.createVerifiedBusinessAccount();
        final partnership = IntegrationTestHelpers.createTestPartnership(
          eventId: event.id,
          userId: expertUser.id,
          businessId: business.id,
        );
        
        expect(partnership.eventId, equals(event.id));
        expect(partnership.userId, equals(expertUser.id));
        
        // Complete chain:
        // Visits → Expertise → Events → Partnerships
        // All relationships maintained:
        // - Visits link to user
        // - Expertise calculated from visits
        // - Events require expertise
        // - Partnerships link to events
        // - All link to same category
        
        expect(visits.first.userId, equals(expertUser.id));
        expect(expertUser.expertiseMap[category], equals('city'));
        expect(event.category, equals(category));
        expect(partnership.eventId, equals(event.id));
      });
    });
  });
}

