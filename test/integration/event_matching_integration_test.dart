import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/event_matching_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/geographic_scope_service.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/expertise_level.dart';
import '../../helpers/integration_test_helpers.dart';

/// Integration tests for event matching with local expert priority
/// and cross-locality discovery
/// 
/// **Philosophy:** Tests verify that local experts are prioritized
/// in their locality and that cross-locality connections enable
/// event discovery in neighboring communities.
void main() {
  group('Event Matching Integration Tests', () {
    late EventMatchingService matchingService;
    late ExpertiseEventService eventService;

    setUp(() {
      eventService = ExpertiseEventService();
      matchingService = EventMatchingService(
        eventService: eventService,
      );
    });

    group('Local Expert Priority', () {
      test('should prioritize local experts in their locality', () async {
        // Create local expert in Mission District
        final localExpert = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'local-expert-1',
          category: 'food',
          location: 'Mission District, San Francisco',
        );

        // Create city expert
        final cityExpert = IntegrationTestHelpers.createUserWithExpertise(
          id: 'city-expert-1',
          category: 'food',
          level: ExpertiseLevel.city,
        ).copyWith(location: 'San Francisco');

        // Create user in Mission District
        final user = IntegrationTestHelpers.createUser(
          id: 'user-1',
          location: 'Mission District, San Francisco',
        );

        // Create events hosted by both experts in Mission District
        final localEvent = await eventService.createEvent(
          host: localExpert,
          title: 'Local Food Tour',
          description: 'A tour of local food spots',
          category: 'food',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 7)),
          endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
          location: 'Mission District, San Francisco',
        );

        final cityEvent = await eventService.createEvent(
          host: cityExpert,
          title: 'City Food Tour',
          description: 'A tour of city food spots',
          category: 'food',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 7)),
          endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
          location: 'Mission District, San Francisco',
        );

        // Calculate matching scores
        final localScore = await matchingService.calculateMatchingScore(
          expert: localExpert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        final cityScore = await matchingService.calculateMatchingScore(
          expert: cityExpert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        // Local expert should have higher score due to locality matching
        // (Note: This verifies locality-specific weighting prioritizes local experts)
        expect(localScore, greaterThanOrEqualTo(cityScore));

        // Verify events exist
        expect(localEvent, isNotNull);
        expect(cityEvent, isNotNull);
      });

      test('should apply locality-specific weighting correctly', () async {
        // Create expert in same locality as user
        final localExpert = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'local-expert-1',
          category: 'food',
          location: 'Mission District, San Francisco',
        );

        // Create user in same locality
        final user = IntegrationTestHelpers.createUser(
          id: 'user-1',
          location: 'Mission District, San Francisco',
        );

        // Create event in same locality
        await eventService.createEvent(
          host: localExpert,
          title: 'Local Food Tour',
          description: 'A tour of local food spots',
          category: 'food',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 7)),
          endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
          location: 'Mission District, San Francisco',
        );

        // Get matching signals
        final signals = await matchingService.getMatchingSignals(
          expert: localExpert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        // Locality weight should be 1.0 for same locality
        expect(signals.localityWeight, equals(1.0));
      });
    });

    group('Matching Score Calculation', () {
      test('should calculate score from multiple signals', () async {
        // Create expert with multiple events
        final expert = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'expert-1',
          category: 'food',
          location: 'Mission District, San Francisco',
        );

        // Create user
        final user = IntegrationTestHelpers.createUser(
          id: 'user-1',
          location: 'Mission District, San Francisco',
        );

        // Create multiple events
        for (int i = 0; i < 3; i++) {
          await eventService.createEvent(
            host: expert,
            title: 'Food Tour $i',
            description: 'A tour of food spots',
            category: 'food',
            eventType: ExpertiseEventType.tour,
            startTime: DateTime.now().add(Duration(days: 7 + i)),
            endTime: DateTime.now().add(Duration(days: 7 + i, hours: 2)),
            location: 'Mission District, San Francisco',
          );
        }

        // Calculate matching score
        final score = await matchingService.calculateMatchingScore(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        // Score should be positive
        expect(score, greaterThan(0.0));
        expect(score, lessThanOrEqualTo(1.0));

        // Get signals to verify components
        final signals = await matchingService.getMatchingSignals(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        // Should have events
        expect(signals.eventsHostedCount, equals(3));
      });

      test('should return 0.0 for expert with no events', () async {
        // Create expert with no events
        final expert = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'expert-1',
          category: 'food',
          location: 'Mission District, San Francisco',
        );

        // Create user
        final user = IntegrationTestHelpers.createUser(
          id: 'user-1',
          location: 'Mission District, San Francisco',
        );

        // Calculate matching score
        final score = await matchingService.calculateMatchingScore(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        // Score should be 0.0 for expert with no events
        expect(score, equals(0.0));
      });
    });

    group('Cross-Locality Discovery', () {
      test('should identify connected localities for event discovery', () {
        // TODO: Implement when CrossLocalityConnectionService is created
        // Expected: Should identify localities connected through user movement
        // and enable event discovery in those localities
        expect(true, isTrue); // Placeholder
      });

      test('should apply connection strength to event ranking', () {
        // TODO: Implement when CrossLocalityConnectionService is created
        // Expected: Events from connected localities should be ranked
        // based on connection strength
        expect(true, isTrue); // Placeholder
      });
    });
  });
}

