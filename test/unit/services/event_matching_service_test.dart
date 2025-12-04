import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/event_matching_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/geographic_scope_service.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/expertise_level.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/integration_test_helpers.dart';

import 'event_matching_service_test.mocks.dart';

@GenerateMocks([ExpertiseEventService, GeographicScopeService])
void main() {
  group('EventMatchingService Tests', () {
    late EventMatchingService service;
    late MockExpertiseEventService mockEventService;
    late MockGeographicScopeService mockGeographicScopeService;
    late UnifiedUser expert;
    late UnifiedUser user;

    setUp(() {
      mockEventService = MockExpertiseEventService();
      mockGeographicScopeService = MockGeographicScopeService();

      service = EventMatchingService(
        eventService: mockEventService,
        geographicScopeService: mockGeographicScopeService,
      );

      // Create expert with local expertise
      expert = IntegrationTestHelpers.createUserWithLocalExpertise(
        id: 'expert-1',
        category: 'food',
        location: 'Mission District, San Francisco',
      );

      // Create user looking for events
      user = IntegrationTestHelpers.createUser(
        id: 'user-1',
        location: 'Mission District, San Francisco',
      );
    });

    group('calculateMatchingScore', () {
      test('should return score between 0.0 and 1.0', () async {
        // Mock events hosted by expert
        final events = [
          IntegrationTestHelpers.createExpertiseEvent(
            id: 'event-1',
            host: expert,
            category: 'food',
            location: 'Mission District, San Francisco',
          ),
        ];

        when(mockEventService.getEventsByHost(expert))
            .thenAnswer((_) async => events);

        final score = await service.calculateMatchingScore(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        expect(score, greaterThanOrEqualTo(0.0));
        expect(score, lessThanOrEqualTo(1.0));
      });

      test('should return higher score for experts with more events', () async {
        // Expert with 1 event
        final events1 = [
          IntegrationTestHelpers.createExpertiseEvent(
            id: 'event-1',
            host: expert,
            category: 'food',
            location: 'Mission District, San Francisco',
          ),
        ];

        // Expert with 5 events
        final events5 = List.generate(5, (i) {
          return IntegrationTestHelpers.createExpertiseEvent(
            id: 'event-$i',
            host: expert,
            category: 'food',
            location: 'Mission District, San Francisco',
          );
        });

        when(mockEventService.getEventsByHost(expert))
            .thenAnswer((_) async => events1);

        final score1 = await service.calculateMatchingScore(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        when(mockEventService.getEventsByHost(expert))
            .thenAnswer((_) async => events5);

        final score5 = await service.calculateMatchingScore(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        // Expert with more events should have higher score
        expect(score5, greaterThan(score1));
      });

      test('should apply locality-specific weighting', () async {
        // Expert in same locality as user
        final localExpert = expert.copyWith(
          location: 'Mission District, San Francisco',
        );

        // Expert in different locality
        final remoteExpert = expert.copyWith(
          location: 'SOMA, San Francisco',
        );

        final events = [
          IntegrationTestHelpers.createExpertiseEvent(
            id: 'event-1',
            host: localExpert,
            category: 'food',
            location: 'Mission District, San Francisco',
          ),
        ];

        when(mockEventService.getEventsByHost(localExpert))
            .thenAnswer((_) async => events);

        final localScore = await service.calculateMatchingScore(
          expert: localExpert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        when(mockEventService.getEventsByHost(remoteExpert))
            .thenAnswer((_) async => events);

        final remoteScore = await service.calculateMatchingScore(
          expert: remoteExpert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        // Local expert should have higher score due to locality weighting
        expect(localScore, greaterThan(remoteScore));
      });

      test('should return 0.0 when expert has no events', () async {
        when(mockEventService.getEventsByHost(expert))
            .thenAnswer((_) async => []);

        final score = await service.calculateMatchingScore(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        expect(score, equals(0.0));
      });

      test('should handle errors gracefully', () async {
        when(mockEventService.getEventsByHost(expert))
            .thenThrow(Exception('Service error'));

        final score = await service.calculateMatchingScore(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        // Should return 0.0 on error
        expect(score, equals(0.0));
      });
    });

    group('getMatchingSignals', () {
      test('should return matching signals with all components', () async {
        final events = [
          IntegrationTestHelpers.createExpertiseEvent(
            id: 'event-1',
            host: expert,
            category: 'food',
            location: 'Mission District, San Francisco',
            attendeeCount: 10,
            maxAttendees: 20,
          ),
        ];

        when(mockEventService.getEventsByHost(expert))
            .thenAnswer((_) async => events);

        final signals = await service.getMatchingSignals(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        expect(signals.eventsHostedCount, equals(1));
        expect(signals.averageRating, greaterThan(0.0));
        expect(signals.followersCount, greaterThanOrEqualTo(0));
        expect(signals.localityWeight, greaterThan(0.0));
        expect(signals.localityWeight, lessThanOrEqualTo(1.0));
      });

      test('should calculate locality weight correctly for same locality', () async {
        final events = [
          IntegrationTestHelpers.createExpertiseEvent(
            id: 'event-1',
            host: expert,
            category: 'food',
            location: 'Mission District, San Francisco',
          ),
        ];

        when(mockEventService.getEventsByHost(expert))
            .thenAnswer((_) async => events);

        final signals = await service.getMatchingSignals(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        // Expert in same locality should have high weight (1.0)
        expect(signals.localityWeight, equals(1.0));
      });

      test('should calculate locality weight correctly for different locality', () async {
        final remoteExpert = expert.copyWith(
          location: 'SOMA, San Francisco',
        );

        final events = [
          IntegrationTestHelpers.createExpertiseEvent(
            id: 'event-1',
            host: remoteExpert,
            category: 'food',
            location: 'SOMA, San Francisco',
          ),
        ];

        when(mockEventService.getEventsByHost(remoteExpert))
            .thenAnswer((_) async => events);

        final signals = await service.getMatchingSignals(
          expert: remoteExpert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        // Expert in different locality should have lower weight
        expect(signals.localityWeight, lessThan(1.0));
        expect(signals.localityWeight, greaterThanOrEqualTo(0.0));
      });

      test('should return empty signals on error', () async {
        when(mockEventService.getEventsByHost(expert))
            .thenThrow(Exception('Service error'));

        final signals = await service.getMatchingSignals(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        expect(signals.eventsHostedCount, equals(0));
        expect(signals.localityWeight, equals(0.0));
      });

      test('should filter events by category', () async {
        final foodEvents = [
          IntegrationTestHelpers.createExpertiseEvent(
            id: 'event-1',
            host: expert,
            category: 'food',
            location: 'Mission District, San Francisco',
          ),
        ];

        final coffeeEvents = [
          IntegrationTestHelpers.createExpertiseEvent(
            id: 'event-2',
            host: expert,
            category: 'coffee',
            location: 'Mission District, San Francisco',
          ),
        ];

        when(mockEventService.getEventsByHost(expert))
            .thenAnswer((_) async => [...foodEvents, ...coffeeEvents]);

        final signals = await service.getMatchingSignals(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        // Should only count food events
        expect(signals.eventsHostedCount, equals(1));
      });

      test('should calculate event growth signal', () async {
        // Create events with growing attendance
        final events = [
          IntegrationTestHelpers.createExpertiseEvent(
            id: 'event-1',
            host: expert,
            category: 'food',
            location: 'Mission District, San Francisco',
            attendeeCount: 5,
            maxAttendees: 20,
            startTime: DateTime.now().subtract(const Duration(days: 30)),
          ),
          IntegrationTestHelpers.createExpertiseEvent(
            id: 'event-2',
            host: expert,
            category: 'food',
            location: 'Mission District, San Francisco',
            attendeeCount: 15,
            maxAttendees: 20,
            startTime: DateTime.now().subtract(const Duration(days: 15)),
          ),
        ];

        when(mockEventService.getEventsByHost(expert))
            .thenAnswer((_) async => events);

        final signals = await service.getMatchingSignals(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        // Event growth should be positive (attendance increased)
        expect(signals.eventGrowthScore, greaterThan(0.5));
      });
    });

    group('Local Expert Priority', () {
      test('should prioritize local experts in their locality', () async {
        // Local expert hosting in their locality
        final localExpert = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'local-expert-1',
          category: 'food',
          location: 'Mission District, San Francisco',
        );

        // City expert hosting in same locality
        final cityExpert = IntegrationTestHelpers.createUserWithExpertise(
          id: 'city-expert-1',
          category: 'food',
          level: ExpertiseLevel.city,
        ).copyWith(location: 'San Francisco');

        final localEvents = [
          IntegrationTestHelpers.createExpertiseEvent(
            id: 'event-1',
            host: localExpert,
            category: 'food',
            location: 'Mission District, San Francisco',
          ),
        ];

        final cityEvents = [
          IntegrationTestHelpers.createExpertiseEvent(
            id: 'event-2',
            host: cityExpert,
            category: 'food',
            location: 'Mission District, San Francisco',
          ),
        ];

        when(mockEventService.getEventsByHost(localExpert))
            .thenAnswer((_) async => localEvents);

        when(mockEventService.getEventsByHost(cityExpert))
            .thenAnswer((_) async => cityEvents);

        final localScore = await service.calculateMatchingScore(
          expert: localExpert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        final cityScore = await service.calculateMatchingScore(
          expert: cityExpert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        // Local expert should have higher score due to locality matching
        // (Note: This test verifies locality weighting, which prioritizes local experts)
        expect(localScore, greaterThanOrEqualTo(cityScore));
      });
    });
  });
}

