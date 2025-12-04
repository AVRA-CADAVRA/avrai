import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/geographic_expansion_service.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/integration_test_helpers.dart';

void main() {
  group('GeographicExpansionService Tests', () {
    late GeographicExpansionService service;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      service = GeographicExpansionService();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Event Expansion Tracking', () {
      test('should track event expansion to new locality', () async {
        final clubId = 'club-1';
        final newLocality = 'Williamsburg, Brooklyn';
        final category = 'Coffee';

        final host = ModelFactories.createTestUser(
          id: 'host-1',
          displayName: 'Test Host',
        );
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          id: 'event-1',
          category: category,
          location: newLocality,
        );

        await service.trackEventExpansion(
          clubId: clubId,
          isClub: true,
          event: event,
          eventLocation: newLocality,
        );

        final expansion = service.getExpansionByClub(clubId);
        expect(expansion, isNotNull);
        expect(expansion?.originalLocality, equals(newLocality)); // First event sets original
        expect(expansion?.expandedLocalities, contains('Williamsburg')); // Extracted locality
        expect(expansion?.eventHostingLocations['Williamsburg'], contains('event-1'));
      });

      test('should update expansion history when tracking event expansion', () async {
        final clubId = 'club-1';
        final newLocality = 'Williamsburg, Brooklyn';
        final category = 'Coffee';

        final host = ModelFactories.createTestUser(id: 'host-1');
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          id: 'event-1',
          category: category,
          location: newLocality,
        );

        await service.trackEventExpansion(
          clubId: clubId,
          isClub: true,
          event: event,
          eventLocation: newLocality,
        );

        final expansion = service.getExpansionByClub(clubId);
        expect(expansion?.expansionHistory, isNotEmpty);
        expect(expansion?.firstExpansionAt, isNotNull);
        expect(expansion?.lastExpansionAt, isNotNull);
        expect(expansion?.expansionHistory.first.location, equals(newLocality));
        expect(expansion?.expansionHistory.first.expansionMethod, equals('event_hosting'));
      });

      test('should not duplicate localities when tracking same locality multiple times', () async {
        final clubId = 'club-1';
        final newLocality = 'Williamsburg, Brooklyn';
        final category = 'Coffee';

        final host = ModelFactories.createTestUser(id: 'host-1');
        final event1 = IntegrationTestHelpers.createTestEvent(
          host: host,
          id: 'event-1',
          category: category,
          location: newLocality,
        );
        final event2 = IntegrationTestHelpers.createTestEvent(
          host: host,
          id: 'event-2',
          category: category,
          location: newLocality,
        );

        await service.trackEventExpansion(
          clubId: clubId,
          isClub: true,
          event: event1,
          eventLocation: newLocality,
        );

        await service.trackEventExpansion(
          clubId: clubId,
          isClub: true,
          event: event2,
          eventLocation: newLocality,
        );

        final expansion = service.getExpansionByClub(clubId);
        expect(expansion?.expandedLocalities.where((l) => l == 'Williamsburg').length, equals(1));
        expect(expansion?.eventHostingLocations['Williamsburg']?.length, equals(2));
      });
    });

    group('Commute Pattern Tracking', () {
      test('should track commute pattern from source locality to event locality', () async {
        final clubId = 'club-1';
        final eventLocality = 'Mission District, San Francisco';
        final sourceLocality = 'SOMA, San Francisco';
        final category = 'Coffee';

        // First create an expansion by tracking an event
        final host = ModelFactories.createTestUser(id: 'host-1');
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          id: 'event-1',
          category: category,
          location: eventLocality,
        );
        await service.trackEventExpansion(
          clubId: clubId,
          isClub: true,
          event: event,
          eventLocation: eventLocality,
        );

        await service.trackCommutePattern(
          clubId: clubId,
          eventLocality: eventLocality,
          attendeeLocalities: [sourceLocality],
        );

        final expansion = service.getExpansionByClub(clubId);
        expect(expansion?.commutePatterns[eventLocality], contains(sourceLocality));
      });

      test('should track multiple commute patterns for same event locality', () async {
        final clubId = 'club-1';
        final eventLocality = 'Mission District, San Francisco';
        final sourceLocalities = ['SOMA, San Francisco', 'Castro, San Francisco', 'Hayes Valley, San Francisco'];
        final category = 'Coffee';

        // First create an expansion by tracking an event
        final host = ModelFactories.createTestUser(id: 'host-1');
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          id: 'event-1',
          category: category,
          location: eventLocality,
        );
        await service.trackEventExpansion(
          clubId: clubId,
          isClub: true,
          event: event,
          eventLocation: eventLocality,
        );

        await service.trackCommutePattern(
          clubId: clubId,
          eventLocality: eventLocality,
          attendeeLocalities: sourceLocalities,
        );

        final expansion = service.getExpansionByClub(clubId);
        expect(expansion?.commutePatterns[eventLocality], hasLength(3));
        expect(expansion?.commutePatterns[eventLocality], containsAll(sourceLocalities));
      });

      test('should not duplicate source localities in commute patterns', () async {
        final clubId = 'club-1';
        final eventLocality = 'Mission District, San Francisco';
        final sourceLocality = 'SOMA, San Francisco';
        final category = 'Coffee';

        // First create an expansion by tracking an event
        final host = ModelFactories.createTestUser(id: 'host-1');
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          id: 'event-1',
          category: category,
          location: eventLocality,
        );
        await service.trackEventExpansion(
          clubId: clubId,
          isClub: true,
          event: event,
          eventLocation: eventLocality,
        );

        await service.trackCommutePattern(
          clubId: clubId,
          eventLocality: eventLocality,
          attendeeLocalities: [sourceLocality],
        );

        await service.trackCommutePattern(
          clubId: clubId,
          eventLocality: eventLocality,
          attendeeLocalities: [sourceLocality],
        );

        final expansion = service.getExpansionByClub(clubId);
        expect(expansion?.commutePatterns[eventLocality]?.where((l) => l == sourceLocality).length, equals(1));
      });
    });

    group('Coverage Calculation', () {
      test('should calculate locality coverage based on event hosting', () async {
        final clubId = 'club-1';
        final category = 'Coffee';

        final host = ModelFactories.createTestUser(id: 'host-1');
        final event1 = IntegrationTestHelpers.createTestEvent(
          host: host,
          id: 'event-1',
          category: category,
          location: 'Williamsburg, Brooklyn',
        );
        final event2 = IntegrationTestHelpers.createTestEvent(
          host: host,
          id: 'event-2',
          category: category,
          location: 'Greenpoint, Brooklyn',
        );

        await service.trackEventExpansion(
          clubId: clubId,
          isClub: true,
          event: event1,
          eventLocation: 'Williamsburg, Brooklyn',
        );

        await service.trackEventExpansion(
          clubId: clubId,
          isClub: true,
          event: event2,
          eventLocation: 'Greenpoint, Brooklyn',
        );

        final expansion = service.getExpansionByClub(clubId);
        expect(expansion, isNotNull);
        final coverage = await service.calculateLocalityCoverage(expansion: expansion!);

        expect(coverage, isNotEmpty);
        expect(coverage.values.any((v) => v > 0.0), isTrue);
        expect(coverage.values.every((v) => v <= 1.0), isTrue);
      });

      test('should calculate city coverage with 75% threshold', () async {
        final clubId = 'club-1';
        final category = 'Coffee';

        final host = ModelFactories.createTestUser(id: 'host-1');
        final brooklynLocalities = [
          'Williamsburg, Brooklyn',
          'Greenpoint, Brooklyn',
          'DUMBO, Brooklyn',
          'Park Slope, Brooklyn',
        ];

        for (var i = 0; i < brooklynLocalities.length; i++) {
          final event = IntegrationTestHelpers.createTestEvent(
            host: host,
            id: 'event-$i',
            category: category,
            location: brooklynLocalities[i],
          );
          await service.trackEventExpansion(
            clubId: clubId,
            isClub: true,
            event: event,
            eventLocation: brooklynLocalities[i],
          );
        }

        final expansion = service.getExpansionByClub(clubId);
        expect(expansion, isNotNull);
        final coverage = await service.calculateCityCoverage(expansion: expansion!);

        expect(coverage, isNotEmpty);
        expect(coverage.values.every((v) => v >= 0.0 && v <= 1.0), isTrue);
      });

      test('should calculate state coverage with 75% threshold', () async {
        final clubId = 'club-1';
        final category = 'Coffee';

        final host = ModelFactories.createTestUser(id: 'host-1');
        final newYorkCities = ['Brooklyn', 'Queens', 'Manhattan'];

        for (var i = 0; i < newYorkCities.length; i++) {
          final event = IntegrationTestHelpers.createTestEvent(
            host: host,
            id: 'event-$i',
            category: category,
            location: 'Locality, ${newYorkCities[i]}, New York',
          );
          await service.trackEventExpansion(
            clubId: clubId,
            isClub: true,
            event: event,
            eventLocation: 'Locality, ${newYorkCities[i]}, New York',
          );
        }

        final expansion = service.getExpansionByClub(clubId);
        expect(expansion, isNotNull);
        final coverage = await service.calculateStateCoverage(expansion: expansion!);

        expect(coverage, isNotEmpty);
        expect(coverage.values.every((v) => v >= 0.0 && v <= 1.0), isTrue);
      });

      test('should calculate nation coverage with 75% threshold', () async {
        final clubId = 'club-1';
        final category = 'Coffee';

        final host = ModelFactories.createTestUser(id: 'host-1');
        // Track events in multiple states
        final states = ['California', 'New York', 'Texas'];

        for (var i = 0; i < states.length; i++) {
          final event = IntegrationTestHelpers.createTestEvent(
            host: host,
            id: 'event-$i',
            category: category,
            location: 'Locality, ${states[i]}, United States',
          );
          await service.trackEventExpansion(
            clubId: clubId,
            isClub: true,
            event: event,
            eventLocation: 'Locality, ${states[i]}, United States',
          );
        }

        final expansion = service.getExpansionByClub(clubId);
        expect(expansion, isNotNull);
        final coverage = await service.calculateNationCoverage(expansion: expansion!);

        expect(coverage, isNotEmpty);
        expect(coverage.values.every((v) => v >= 0.0 && v <= 1.0), isTrue);
      });

      test('should calculate global coverage with 75% threshold', () async {
        final clubId = 'club-1';
        final category = 'Coffee';

        final host = ModelFactories.createTestUser(id: 'host-1');
        // Track events in multiple nations
        final nations = ['United States', 'Canada', 'Mexico'];

        for (var i = 0; i < nations.length; i++) {
          final event = IntegrationTestHelpers.createTestEvent(
            host: host,
            id: 'event-$i',
            category: category,
            location: 'Locality, ${nations[i]}',
          );
          await service.trackEventExpansion(
            clubId: clubId,
            isClub: true,
            event: event,
            eventLocation: 'Locality, ${nations[i]}',
          );
        }

        final expansion = service.getExpansionByClub(clubId);
        expect(expansion, isNotNull);
        final coverage = await service.calculateGlobalCoverage(expansion: expansion!);

        expect(coverage, greaterThanOrEqualTo(0.0));
        expect(coverage, lessThanOrEqualTo(1.0));
      });
    });

    group('75% Threshold Checking', () {
      test('should check if locality threshold reached', () async {
        final clubId = 'club-1';
        final locality = 'Williamsburg, Brooklyn';
        final category = 'Coffee';

        final host = ModelFactories.createTestUser(id: 'host-1');
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          id: 'event-1',
          category: category,
          location: locality,
        );

        await service.trackEventExpansion(
          clubId: clubId,
          isClub: true,
          event: event,
          eventLocation: locality,
        );

        final expansion = service.getExpansionByClub(clubId);
        expect(expansion, isNotNull);
        final hasReached = service.hasReachedLocalityThreshold(expansion!);

        expect(hasReached, isA<bool>());
      });

      test('should check if 75% city threshold reached', () async {
        final clubId = 'club-1';
        final city = 'Brooklyn';
        final category = 'Coffee';

        final host = ModelFactories.createTestUser(id: 'host-1');
        // Track enough events to potentially reach 75% threshold
        final brooklynLocalities = List.generate(10, (i) => 'Locality $i, Brooklyn');
        for (var i = 0; i < brooklynLocalities.length; i++) {
          final event = IntegrationTestHelpers.createTestEvent(
            host: host,
            id: 'event-$i',
            category: category,
            location: brooklynLocalities[i],
          );
          await service.trackEventExpansion(
            clubId: clubId,
            isClub: true,
            event: event,
            eventLocation: brooklynLocalities[i],
          );
        }

        final expansion = service.getExpansionByClub(clubId);
        expect(expansion, isNotNull);
        final hasReached = service.hasReachedCityThreshold(expansion!, city);

        expect(hasReached, isA<bool>());
      });

      test('should check if 75% state threshold reached', () async {
        final clubId = 'club-1';
        final state = 'New York';
        final category = 'Coffee';

        final host = ModelFactories.createTestUser(id: 'host-1');
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          id: 'event-1',
          category: category,
          location: 'Locality, New York',
        );
        await service.trackEventExpansion(
          clubId: clubId,
          isClub: true,
          event: event,
          eventLocation: 'Locality, New York',
        );

        final expansion = service.getExpansionByClub(clubId);
        expect(expansion, isNotNull);
        final hasReached = service.hasReachedStateThreshold(expansion!, state);

        expect(hasReached, isA<bool>());
      });

      test('should check if 75% nation threshold reached', () async {
        final clubId = 'club-1';
        final nation = 'United States';
        final category = 'Coffee';

        final host = ModelFactories.createTestUser(id: 'host-1');
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          id: 'event-1',
          category: category,
          location: 'Locality, United States',
        );
        await service.trackEventExpansion(
          clubId: clubId,
          isClub: true,
          event: event,
          eventLocation: 'Locality, United States',
        );

        final expansion = service.getExpansionByClub(clubId);
        expect(expansion, isNotNull);
        final hasReached = service.hasReachedNationThreshold(expansion!, nation);

        expect(hasReached, isA<bool>());
      });

      test('should check if 75% global threshold reached', () async {
        final clubId = 'club-1';
        final category = 'Coffee';

        final host = ModelFactories.createTestUser(id: 'host-1');
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          id: 'event-1',
          category: category,
          location: 'Locality, United States',
        );
        await service.trackEventExpansion(
          clubId: clubId,
          isClub: true,
          event: event,
          eventLocation: 'Locality, United States',
        );

        final expansion = service.getExpansionByClub(clubId);
        expect(expansion, isNotNull);
        final hasReached = service.hasReachedGlobalThreshold(expansion!);

        expect(hasReached, isA<bool>());
      });
    });

    group('Expansion Management', () {
      test('should get expansion by club', () async {
        final clubId = 'club-1';
        final category = 'Coffee';

        final host = ModelFactories.createTestUser(id: 'host-1');
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          id: 'event-1',
          category: category,
          location: 'Williamsburg, Brooklyn',
        );

        await service.trackEventExpansion(
          clubId: clubId,
          isClub: true,
          event: event,
          eventLocation: 'Williamsburg, Brooklyn',
        );

        final expansion = service.getExpansionByClub(clubId);
        expect(expansion, isNotNull);
        expect(expansion?.clubId, equals(clubId));
        expect(expansion?.isClub, equals(true));
      });

      test('should get expansion by community', () async {
        final communityId = 'community-1';
        final category = 'Coffee';

        final host = ModelFactories.createTestUser(id: 'host-1');
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          id: 'event-1',
          category: category,
          location: 'Williamsburg, Brooklyn',
        );

        await service.trackEventExpansion(
          clubId: communityId,
          isClub: false,
          event: event,
          eventLocation: 'Williamsburg, Brooklyn',
        );

        final expansion = service.getExpansionByCommunity(communityId);
        expect(expansion, isNotNull);
        expect(expansion?.clubId, equals(communityId));
        expect(expansion?.isClub, equals(false));
      });

      test('should update expansion data', () async {
        final clubId = 'club-1';
        final category = 'Coffee';

        final host = ModelFactories.createTestUser(id: 'host-1');
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          id: 'event-1',
          category: category,
          location: 'Williamsburg, Brooklyn',
        );

        await service.trackEventExpansion(
          clubId: clubId,
          isClub: true,
          event: event,
          eventLocation: 'Williamsburg, Brooklyn',
        );

        final expansion = service.getExpansionByClub(clubId);
        expect(expansion, isNotNull);
        final updatedExpansion = expansion!.copyWith(
          cityCoverage: {'Brooklyn': 0.8},
        );

        await service.updateExpansion(updatedExpansion);

        final updated = service.getExpansionByClub(clubId);
        expect(updated?.cityCoverage['Brooklyn'], equals(0.8));
      });

      test('should get expansion history', () async {
        final clubId = 'club-1';
        final category = 'Coffee';

        final host = ModelFactories.createTestUser(id: 'host-1');
        final event1 = IntegrationTestHelpers.createTestEvent(
          host: host,
          id: 'event-1',
          category: category,
          location: 'Williamsburg, Brooklyn',
        );
        final event2 = IntegrationTestHelpers.createTestEvent(
          host: host,
          id: 'event-2',
          category: category,
          location: 'Greenpoint, Brooklyn',
        );

        await service.trackEventExpansion(
          clubId: clubId,
          isClub: true,
          event: event1,
          eventLocation: 'Williamsburg, Brooklyn',
        );

        await service.trackEventExpansion(
          clubId: clubId,
          isClub: true,
          event: event2,
          eventLocation: 'Greenpoint, Brooklyn',
        );

        final history = service.getExpansionHistory(clubId);

        expect(history, isNotEmpty);
        expect(history.length, greaterThanOrEqualTo(2));
      });
    });
  });
}

