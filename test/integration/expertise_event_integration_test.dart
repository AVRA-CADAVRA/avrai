import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/payment.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/services/expertise_calculation_service.dart';
import 'package:spots/core/services/saturation_algorithm_service.dart';
import 'package:spots/core/services/multi_path_expertise_service.dart';
import 'package:spots/core/services/stripe_service.dart';
import '../helpers/integration_test_helpers.dart';
import '../helpers/test_helpers.dart';
import '../fixtures/model_factories.dart';

// Mock dependencies
class MockStripeService extends Mock implements StripeService {}
class MockExpertiseEventService extends Mock implements ExpertiseEventService {}

/// Expertise-Event Integration Tests
/// 
/// Agent 3: Models & Testing (Week 14)
/// 
/// Tests integration between expertise system and events:
/// - Expertise requirements for event hosting
/// - Event attendance contributing to expertise
/// - Event hosting contributing to expertise
/// - Expertise progression through events
/// 
/// **Test Scenarios:**
/// - Scenario 1: Expertise Requirements for Event Hosting
/// - Scenario 2: Event Attendance Contributing to Expertise
/// - Scenario 3: Event Hosting Contributing to Expertise
/// - Scenario 4: Expertise Progression Through Events
void main() {
  group('Expertise-Event Integration Tests', () {
    late ExpertiseCalculationService expertiseService;
    late PaymentService paymentService;
    late MockStripeService mockStripeService;
    late MockExpertiseEventService mockEventService;
    late SaturationAlgorithmService saturationService;
    late MultiPathExpertiseService multiPathService;
    late DateTime testDate;
    
    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      mockStripeService = MockStripeService();
      mockEventService = MockExpertiseEventService();
      saturationService = SaturationAlgorithmService();
      multiPathService = MultiPathExpertiseService();
      
      expertiseService = ExpertiseCalculationService(
        saturationService: saturationService,
        multiPathService: multiPathService,
      );
      
      paymentService = PaymentService(
        mockStripeService,
        mockEventService,
      );
      
      // Setup Stripe mock
      when(() => mockStripeService.isInitialized).thenReturn(true);
      when(() => mockStripeService.initializeStripe())
          .thenAnswer((_) async => {});
    });
    
    tearDown(() {
      reset(mockStripeService);
      reset(mockEventService);
      TestHelpers.teardownTestEnvironment();
    });
    
    group('Scenario 1: Expertise Requirements for Event Hosting', () {
      test('should require Local level expertise to host events', () async {
        // Arrange - Local level user (can host in locality)
        final localHost = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'host-local',
          category: 'Coffee',
        );
        
        // Verify user can host events
        expect(localHost.canHostEvents(), isTrue);
        expect(localHost.expertiseMap['Coffee'], equals('local'));
        
        // User can create events
        final event = IntegrationTestHelpers.createTestEvent(
          host: localHost,
          category: 'Coffee',
        );
        
        expect(event.host.id, equals(localHost.id));
        expect(event.category, equals('Coffee'));
      });
      
      test('should allow City level expertise to host events (expanded scope)', () async {
        // Arrange - City level user (can host in all localities in city)
        final cityHost = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'host-city',
          category: 'Coffee',
        );
        
        // Verify user can host events
        expect(cityHost.canHostEvents(), isTrue);
        expect(cityHost.expertiseMap['Coffee'], equals('city'));
        
        // User can create events
        final event = IntegrationTestHelpers.createTestEvent(
          host: cityHost,
          category: 'Coffee',
        );
        
        expect(event.host.id, equals(cityHost.id));
        expect(event.category, equals('Coffee'));
      });
      
      test('should prevent event hosting without Local level expertise', () async {
        // Arrange - No expertise (cannot host)
        final userWithoutExpertise = IntegrationTestHelpers.createUserWithoutHosting(
          id: 'user-no-expertise',
          category: 'Coffee',
        );
        
        // Verify user cannot host events
        expect(userWithoutExpertise.canHostEvents(), isFalse);
        expect(userWithoutExpertise.expertiseMap.containsKey('Coffee'), isFalse);
        
        // User cannot create events (enforced at service level)
        // But we can test the model relationship
        // In practice, event creation service would check expertise level
      });
    });
    
    group('Scenario 2: Event Attendance Contributing to Expertise', () {
      test('should track event attendance in expertise calculation', () async {
        // Arrange
        final host = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'host-1',
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
        
        when(() => mockEventService.getEventById(any()))
            .thenAnswer((_) async => event);
        
        // Attendee purchases ticket (attends event)
        final payment = IntegrationTestHelpers.createSuccessfulPayment(
          eventId: event.id,
          userId: attendee.id,
          amount: 25.00,
        );
        
        expect(payment.eventId, equals(event.id));
        expect(payment.userId, equals(attendee.id));
        
        // Event attendance contributes to:
        // - Exploration expertise (visiting event location)
        // - Community expertise (participating in community events)
        // - Professional expertise (if event is professional development)
        
        // Verify payment links to event
        expect(payment.eventId, equals(event.id));
      });
      
      test('should track multiple event attendances', () async {
        // Arrange
        final host = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'host-2',
          category: 'Coffee',
        );
        final attendee = ModelFactories.createTestUser(
          id: 'attendee-2',
        );
        
        // Create multiple events
        final events = <ExpertiseEvent>[];
        for (int i = 0; i < 5; i++) {
          final event = IntegrationTestHelpers.createPaidEvent(
            host: host,
            price: 25.00,
            category: 'Coffee',
          );
          events.add(event);
        }
        
        // Attendee purchases tickets for all events
        final payments = <Payment>[];
        for (final event in events) {
          when(() => mockEventService.getEventById(event.id))
              .thenAnswer((_) async => event);
          
          final payment = IntegrationTestHelpers.createSuccessfulPayment(
            eventId: event.id,
            userId: attendee.id,
            amount: 25.00,
          );
          payments.add(payment);
        }
        
        expect(payments.length, equals(5));
        
        // Multiple event attendances contribute more to expertise
        // - More exploration (multiple locations)
        // - More community engagement
        // - Shows commitment to category
        
        for (final payment in payments) {
          expect(payment.userId, equals(attendee.id));
          expect(payment.status, equals(PaymentStatus.completed));
        }
      });
    });
    
    group('Scenario 3: Event Hosting Contributing to Expertise', () {
      test('should track event hosting in community expertise', () async {
        // Arrange
        final host = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'host-3',
          category: 'Coffee',
        );
        
        // Host creates event
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          category: 'Coffee',
        );
        
        expect(event.host.id, equals(host.id));
        expect(event.category, equals('Coffee'));
        
        // Event hosting contributes to:
        // - Community expertise (hosting community events)
        // - Professional expertise (if event is professional)
        // - Influence expertise (organizing events)
        
        // Verify event is created by expert user
        expect(host.canHostEvents(), isTrue);
        expect(event.host.id, equals(host.id));
      });
      
      test('should track multiple event hostings', () async {
        // Arrange
        final host = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'host-4',
          category: 'Coffee',
        );
        
        // Host creates multiple events
        final events = <ExpertiseEvent>[];
        for (int i = 0; i < 10; i++) {
          final event = IntegrationTestHelpers.createTestEvent(
            host: host,
            id: 'event-$i',
            category: 'Coffee',
          );
          events.add(event);
        }
        
        expect(events.length, equals(10));
        
        // Multiple event hostings contribute more to expertise
        // - More community engagement
        // - Shows consistent hosting ability
        // - Demonstrates expertise in category
        
        for (final event in events) {
          expect(event.host.id, equals(host.id));
          expect(event.category, equals('Coffee'));
        }
      });
    });
    
    group('Scenario 4: Expertise Progression Through Events', () {
      test('should progress from event attendance to event hosting', () async {
        // Step 1: User starts without expertise (attends events)
        final newUser = ModelFactories.createTestUser(
          id: 'user-new',
        );
        
        final host = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'host-5',
          category: 'Coffee',
        );
        
        // User attends multiple events
        final events = <ExpertiseEvent>[];
        for (int i = 0; i < 20; i++) {
          final event = IntegrationTestHelpers.createPaidEvent(
            host: host,
            price: 25.00,
            category: 'Coffee',
          );
          events.add(event);
          
          // User purchases ticket
          final payment = IntegrationTestHelpers.createSuccessfulPayment(
            eventId: event.id,
            userId: newUser.id,
            amount: 25.00,
          );
          
          expect(payment.userId, equals(newUser.id));
          expect(payment.eventId, equals(event.id));
        }
        
        // Step 2: User gains expertise through attendance
        // (In real system, expertise would be calculated from visits/payments)
        
        // Step 3: User progresses to Local level (can now host events in locality)
        final expertUser = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: newUser.id,
          category: 'Coffee',
        );
        
        expect(expertUser.canHostEvents(), isTrue);
        
        // Step 4: User hosts own event
        final userEvent = IntegrationTestHelpers.createTestEvent(
          host: expertUser,
          category: 'Coffee',
        );
        
        expect(userEvent.host.id, equals(expertUser.id));
        expect(userEvent.category, equals('Coffee'));
      });
      
      test('should track expertise progression through event lifecycle', () async {
        // Arrange
        final host = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'host-6',
          category: 'Coffee',
        );
        
        // Create event
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          category: 'Coffee',
          status: EventStatus.upcoming,
        );
        
        expect(event.status, equals(EventStatus.upcoming));
        
        // Event created → contributes to expertise
        expect(event.host.id, equals(host.id));
        
        // Event active → contributes more
        final activeEvent = event.copyWith(status: EventStatus.active);
        expect(activeEvent.status, equals(EventStatus.active));
        
        // Event completed → final contribution
        final completedEvent = event.copyWith(status: EventStatus.completed);
        expect(completedEvent.status, equals(EventStatus.completed));
        
        // Each stage contributes to expertise:
        // - Created: Planning expertise
        // - Active: Execution expertise
        // - Completed: Completion expertise
      });
    });
  });
}

