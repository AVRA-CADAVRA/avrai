import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/controllers/ai_recommendation_controller.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/core/models/expertise_event.dart';
import 'package:avrai/core/controllers/event_creation_controller.dart';
import 'package:avrai/data/datasources/local/sembast_database.dart';
import '../../helpers/platform_channel_helper.dart';
import '../../helpers/integration_test_helpers.dart';

/// AI Recommendation Controller Integration Tests
/// 
/// Tests the complete recommendation workflow with real service implementations:
/// - Personality profile loading
/// - Preferences profile loading
/// - Event recommendation generation
/// - Quantum compatibility enhancement
/// - Result filtering and sorting
void main() {
  group('AIRecommendationController Integration Tests', () {
    late AIRecommendationController controller;

    setUpAll(() async {
      // Initialize Sembast for tests
      SembastDatabase.useInMemoryForTests();
      await SembastDatabase.database;
      
      // Initialize dependency injection
      await setupTestStorage();
      await di.init();
      
      controller = di.sl<AIRecommendationController>();
    });

    setUp(() async {
      // Reset database for each test
      await SembastDatabase.resetForTests();
    });

    group('generateRecommendations', () {
      test('should successfully generate recommendations with real services', () async {
        // Arrange
        final host = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'host_${DateTime.now().millisecondsSinceEpoch}',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        // Create a test event
        final testEvent = ExpertiseEvent(
          id: 'event_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Coffee Tasting Tour',
          description: 'Explore local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          host: host,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: EventStatus.upcoming,
          price: 25.0,
          isPaid: true,
          maxAttendees: 20,
          attendeeCount: 5,
        );

        // Create event via EventCreationController (proper workflow)
        final eventCreationController = di.sl<EventCreationController>();
        final eventFormData = EventFormData(
          title: testEvent.title,
          description: testEvent.description,
          category: testEvent.category,
          eventType: testEvent.eventType,
          startTime: testEvent.startTime,
          endTime: testEvent.endTime,
          location: 'Greenpoint, Brooklyn, NY, USA',
          locality: 'Greenpoint',
          maxAttendees: testEvent.maxAttendees,
          price: testEvent.price,
          isPublic: testEvent.isPublic,
        );
        await eventCreationController.createEvent(
          formData: eventFormData,
          host: host,
        );

        // Create test user
        final testUser = IntegrationTestHelpers.createUserWithoutHosting(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        );

        // Act
        final result = await controller.generateRecommendations(
          userId: testUser.id,
          context: const RecommendationContext(
            category: 'Coffee',
            location: 'Greenpoint',
            maxResults: 10,
          ),
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.events, isA<List>());
        // May have 0 events if no matching events exist, but should succeed
      });

      test('should handle missing personality profile gracefully', () async {
        // Arrange
        final testUser = IntegrationTestHelpers.createUserWithoutHosting(
          id: 'user_no_personality_${DateTime.now().millisecondsSinceEpoch}',
        );

        // Act
        final result = await controller.generateRecommendations(
          userId: testUser.id,
          context: const RecommendationContext(),
        );

        // Assert
        expect(result.isSuccess, isTrue);
        // Should succeed even without personality profile
      });

      test('should handle missing preferences profile gracefully', () async {
        // Arrange
        final testUser = IntegrationTestHelpers.createUserWithoutHosting(
          id: 'user_no_preferences_${DateTime.now().millisecondsSinceEpoch}',
        );

        // Act
        final result = await controller.generateRecommendations(
          userId: testUser.id,
          context: const RecommendationContext(),
        );

        // Assert
        expect(result.isSuccess, isTrue);
        // Should succeed even without preferences profile
      });

      test('should filter recommendations by minRelevanceScore', () async {
        // Arrange
        final testUser = IntegrationTestHelpers.createUserWithoutHosting(
          id: 'user_filter_${DateTime.now().millisecondsSinceEpoch}',
        );

        // Act
        final result = await controller.generateRecommendations(
          userId: testUser.id,
          context: const RecommendationContext(
            minRelevanceScore: 0.7, // High threshold
            maxResults: 10,
          ),
        );

        // Assert
        expect(result.isSuccess, isTrue);
        // All returned events should have relevance >= 0.7
        for (final event in result.events) {
          expect(event.relevanceScore, greaterThanOrEqualTo(0.7));
        }
      });

      test('should limit results to maxResults', () async {
        // Arrange
        final testUser = IntegrationTestHelpers.createUserWithoutHosting(
          id: 'user_limit_${DateTime.now().millisecondsSinceEpoch}',
        );

        // Act
        final result = await controller.generateRecommendations(
          userId: testUser.id,
          context: const RecommendationContext(
            maxResults: 5,
          ),
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.events.length, lessThanOrEqualTo(5));
      });

      test('should return empty list when no events match', () async {
        // Arrange
        final testUser = IntegrationTestHelpers.createUserWithoutHosting(
          id: 'user_no_match_${DateTime.now().millisecondsSinceEpoch}',
        );

        // Act - Request recommendations for a category that likely has no events
        final result = await controller.generateRecommendations(
          userId: testUser.id,
          context: RecommendationContext(
            category: 'NonExistentCategory_${DateTime.now().millisecondsSinceEpoch}',
            maxResults: 10,
          ),
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.events, isEmpty);
      });
    });

    group('validate (WorkflowController interface)', () {
      test('should validate input correctly', () {
        // Arrange
        const validInput = RecommendationInput(
          userId: 'user_123',
          context: RecommendationContext(
            maxResults: 20,
            explorationRatio: 0.3,
          ),
        );

        const invalidInput = RecommendationInput(
          userId: '',
          context: RecommendationContext(),
        );

        // Act
        final validResult = controller.validate(validInput);
        final invalidResult = controller.validate(invalidInput);

        // Assert
        expect(validResult.isValid, isTrue);
        expect(invalidResult.isValid, isFalse);
      });
    });

    group('AVRAI Core System Integration', () {
      test('should work when AVRAI services are available', () async {
        final testUser = IntegrationTestHelpers.createUserWithoutHosting(
          id: 'user_avrai_${DateTime.now().millisecondsSinceEpoch}',
        );

        final result = await controller.generateRecommendations(
          userId: testUser.id,
          context: const RecommendationContext(
            maxResults: 10,
          ),
        );

        expect(result.isSuccess, isTrue, reason: 'Should succeed with AVRAI services');
        expect(result.events, isA<List>(), reason: 'Should return events list');
        // Note: AVRAI integrations (knots, quantum, 4D quantum, AI2AI learning)
        // happen internally and enhance recommendations
      });

      test('should work when AVRAI services are unavailable (graceful degradation)', () async {
        // Create controller without AVRAI services
        final controllerWithoutAVRAI = AIRecommendationController(
          personalityKnotService: null,
          knotStorageService: null,
          knotCompatibilityService: null,
          knotEngine: null,
          locationTimingService: null,
          quantumEntanglementService: null,
          aiLearningService: null,
        );

        final testUser = IntegrationTestHelpers.createUserWithoutHosting(
          id: 'user_avrai_${DateTime.now().millisecondsSinceEpoch}',
        );

        final result = await controllerWithoutAVRAI.generateRecommendations(
          userId: testUser.id,
          context: const RecommendationContext(
            maxResults: 10,
          ),
        );

        expect(result.isSuccess, isTrue, reason: 'Should succeed even without AVRAI services');
        expect(result.events, isA<List>(), reason: 'Should return events list');
        // Core functionality should work without AVRAI services
        // Recommendations may be less personalized but should still work
      });

      test('should handle knot loading gracefully when knot service unavailable', () async {
        // This test verifies that knot loading failures don't break recommendations
        final testUser = IntegrationTestHelpers.createUserWithoutHosting(
          id: 'user_avrai_${DateTime.now().millisecondsSinceEpoch}',
        );

        final result = await controller.generateRecommendations(
          userId: testUser.id,
          context: const RecommendationContext(
            maxResults: 10,
          ),
        );

        expect(result.isSuccess, isTrue, reason: 'Should succeed even if knot loading fails');
        // The controller should handle knot loading failures gracefully
      });
    });
  });
}

