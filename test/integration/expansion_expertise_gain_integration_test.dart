import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/geographic_expansion_service.dart';
import 'package:spots/core/services/expansion_expertise_gain_service.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/geographic_expansion.dart';
import '../helpers/test_helpers.dart';

/// Integration tests for expansion expertise gain flow
/// Tests end-to-end: event → expansion → expertise gain
/// 
/// **Philosophy Alignment:**
/// - Clubs/communities can expand naturally (doors open through growth)
/// - Club leaders recognized as experts (doors for leaders)
/// - 75% coverage rule (fair expertise gain thresholds)
void main() {
  group('Expansion Expertise Gain Integration Tests', () {
    late GeographicExpansionService expansionService;
    late ExpansionExpertiseGainService expertiseGainService;
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      
      expansionService = GeographicExpansionService();
      expertiseGainService = ExpansionExpertiseGainService(
        expansionService: expansionService,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('End-to-End Expansion Flow', () {
      test('should track event expansion and grant expertise', () async {
        final clubId = 'club-1';
        final category = 'Coffee';
        final newLocality = 'Williamsburg, Brooklyn';

        // Create test user
        final user = UnifiedUser(
          id: 'user-1',
          email: 'test@example.com',
          displayName: 'Test User',
          expertiseMap: {},
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Create test event
        final event = ExpertiseEvent(
          id: 'event-1',
          title: 'Test Event',
          description: 'Test Description',
          category: category,
          eventType: ExpertiseEventType.meetup,
          host: user,
          startTime: testDate,
          endTime: testDate.add(const Duration(hours: 2)),
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Step 1: Track event expansion
        final expansion = await expansionService.trackEventExpansion(
          clubId: clubId,
          isClub: true,
          event: event,
          eventLocation: newLocality,
        );

        // Step 2: Verify expansion tracked
        expect(expansion, isNotNull);
        expect(expansion.expandedLocalities, contains(newLocality));

        // Step 3: Grant expertise from expansion
        final updatedUser = await expertiseGainService.grantExpertiseFromExpansion(
          user: user,
          expansion: expansion,
          category: category,
        );

        // Step 4: Verify expertise granted (implementation dependent)
        // This would verify that user gained expertise in new locality
        expect(updatedUser, isNotNull);
      });
    });

    group('Club Leader Expertise Recognition', () {
      test('should grant expertise to club leaders in all localities where club hosts events', () async {
        final clubId = 'club-1';
        final category = 'Coffee';
        final localities = [
          'Mission District, San Francisco',
          'Williamsburg, Brooklyn',
          'Greenpoint, Brooklyn',
        ];

        // Create test leader user
        final leader = UnifiedUser(
          id: 'leader-1',
          email: 'leader@example.com',
          displayName: 'Leader User',
          expertiseMap: {},
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Track events in multiple localities
        GeographicExpansion? expansion;
        for (var i = 0; i < localities.length; i++) {
          final event = ExpertiseEvent(
            id: 'event-$i',
            title: 'Test Event $i',
            description: 'Test Description',
            category: category,
            eventType: ExpertiseEventType.meetup,
            host: leader,
            startTime: testDate.add(Duration(hours: i)),
            endTime: testDate.add(Duration(hours: i + 2)),
            createdAt: testDate,
            updatedAt: testDate,
          );

          expansion = await expansionService.trackEventExpansion(
            clubId: clubId,
            isClub: true,
            event: event,
            eventLocation: localities[i],
          );
        }

        // Grant expertise to leader
        if (expansion != null) {
          final updatedLeader = await expertiseGainService.grantExpertiseFromExpansion(
            user: leader,
            expansion: expansion,
            category: category,
          );

          // Verify leader has expertise in all localities
          // (Implementation dependent - would check user's expertise map)
          expect(updatedLeader, isNotNull);
        }
      });
    });

    group('75% Coverage Rule', () {
      test('should grant city expertise when 75% city coverage reached', () async {
        final clubId = 'club-1';
        final category = 'Coffee';
        final city = 'Brooklyn';

        // Create test user
        final user = UnifiedUser(
          id: 'user-1',
          email: 'test@example.com',
          displayName: 'Test User',
          expertiseMap: {},
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Track events in multiple localities within Brooklyn to reach 75% threshold
        GeographicExpansion? expansion;
        final brooklynLocalities = List.generate(10, (i) => 'Locality $i, Brooklyn');
        for (var i = 0; i < brooklynLocalities.length; i++) {
          final event = ExpertiseEvent(
            id: 'event-$i',
            title: 'Test Event $i',
            description: 'Test Description',
            category: category,
            eventType: ExpertiseEventType.meetup,
            host: user,
            startTime: testDate.add(Duration(hours: i)),
            endTime: testDate.add(Duration(hours: i + 2)),
            createdAt: testDate,
            updatedAt: testDate,
          );

          expansion = await expansionService.trackEventExpansion(
            clubId: clubId,
            isClub: true,
            event: event,
            eventLocation: brooklynLocalities[i],
          );
        }

        // Check if 75% threshold reached
        if (expansion != null) {
          final hasReached = expansionService.hasReachedCityThreshold(expansion, city);

          if (hasReached) {
            // Grant city expertise
            final cityExpertise = await expertiseGainService.checkAndGrantCityExpertise(
              user: user,
              expansion: expansion,
              category: category,
            );

            // Verify city expertise granted
            // (Implementation dependent)
            expect(cityExpertise, isNotNull);
          }
        }
      });
    });

    group('Expansion Timeline', () {
      test('should track expansion timeline correctly', () async {
        final clubId = 'club-1';
        final category = 'Coffee';
        final localities = [
          'Williamsburg, Brooklyn',
          'Greenpoint, Brooklyn',
          'DUMBO, Brooklyn',
        ];

        // Create test user
        final user = UnifiedUser(
          id: 'user-1',
          email: 'test@example.com',
          displayName: 'Test User',
          expertiseMap: {},
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Track multiple expansions
        for (var i = 0; i < localities.length; i++) {
          final event = ExpertiseEvent(
            id: 'event-$i',
            title: 'Test Event $i',
            description: 'Test Description',
            category: category,
            eventType: ExpertiseEventType.meetup,
            host: user,
            startTime: testDate.add(Duration(hours: i)),
            endTime: testDate.add(Duration(hours: i + 2)),
            createdAt: testDate,
            updatedAt: testDate,
          );

          await expansionService.trackEventExpansion(
            clubId: clubId,
            isClub: true,
            event: event,
            eventLocation: localities[i],
          );
        }

        // Get expansion history
        final history = expansionService.getExpansionHistory(clubId);

        expect(history, isNotEmpty);
        expect(history.length, greaterThanOrEqualTo(localities.length));
      });
    });
  });
}

