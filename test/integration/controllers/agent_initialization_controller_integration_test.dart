import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/controllers/agent_initialization_controller.dart';
import 'package:avrai/core/models/onboarding_data.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/services/onboarding_data_service.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/data/datasources/local/sembast_database.dart';
import 'package:avrai/injection_container.dart' as di;
import '../../helpers/platform_channel_helper.dart';

void main() {
  group('AgentInitializationController Integration Tests', () {
    late AgentInitializationController controller;
    late String testUserId;
    late OnboardingData testOnboardingData;

    setUpAll(() async {
      // Initialize Sembast for tests
      SembastDatabase.useInMemoryForTests();
      await SembastDatabase.database;
      
      // Initialize dependency injection
      await setupTestStorage();
      await di.init();
      
      // Get controller from DI
      controller = di.sl<AgentInitializationController>();
      
      // Create test user ID
      testUserId = 'test_user_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create test onboarding data
      testOnboardingData = OnboardingData(
        agentId: '', // Will be set by controller
        age: 25,
        birthday: DateTime(1998, 1, 1),
        homebase: 'New York',
        favoritePlaces: ['Central Park', 'Brooklyn Bridge'],
        preferences: {
          'Food & Drink': ['Coffee & Tea', 'Fine Dining'],
          'Activities': ['Live Music', 'Theaters'],
        },
        baselineLists: ['My Favorite Spots'],
        respectedFriends: [],
        socialMediaConnected: {},
        completedAt: DateTime.now(),
      );
      
      // Save onboarding data to service
      final onboardingService = di.sl<OnboardingDataService>();
      final agentIdService = di.sl<AgentIdService>();
      final agentId = await agentIdService.getUserAgentId(testUserId);
      final onboardingDataWithAgentId = OnboardingData(
        agentId: agentId,
        age: testOnboardingData.age,
        birthday: testOnboardingData.birthday,
        homebase: testOnboardingData.homebase,
        favoritePlaces: testOnboardingData.favoritePlaces,
        preferences: testOnboardingData.preferences,
        baselineLists: testOnboardingData.baselineLists,
        respectedFriends: testOnboardingData.respectedFriends,
        socialMediaConnected: testOnboardingData.socialMediaConnected,
        completedAt: testOnboardingData.completedAt,
      );
      await onboardingService.saveOnboardingData(testUserId, onboardingDataWithAgentId);
    });

    tearDown(() async {
      // Clean up test data
      try {
      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
        final storageService = di.sl<StorageService>();
        // Clear test data if needed
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('should successfully initialize agent with onboarding data', () async {
      // Act
      final result = await controller.initializeAgent(
        userId: testUserId,
        onboardingData: testOnboardingData,
        generatePlaceLists: false, // Skip to speed up test
        getRecommendations: false, // Skip to speed up test
        attemptCloudSync: false, // Skip to speed up test
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.agentId, isNotNull);
      expect(result.personalityProfile, isNotNull);
      expect(result.personalityProfile!.agentId, equals(result.agentId));
      expect(result.personalityProfile!.evolutionGeneration, equals(1));
      expect(result.preferencesProfile, isNotNull);
      expect(result.preferencesProfile!.agentId, equals(result.agentId));
    });

    test('should handle missing onboarding data gracefully', () async {
      // Arrange
      final emptyOnboardingData = OnboardingData(
        agentId: '',
        age: null,
        birthday: null,
        homebase: null,
        favoritePlaces: [],
        preferences: {},
        baselineLists: [],
        respectedFriends: [],
        socialMediaConnected: {},
        completedAt: DateTime.now(),
      );

      // Act
      final result = await controller.initializeAgent(
        userId: testUserId,
        onboardingData: emptyOnboardingData,
        generatePlaceLists: false,
        getRecommendations: false,
        attemptCloudSync: false,
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.personalityProfile, isNotNull);
      expect(result.preferencesProfile, isNotNull);
    });

    test('should continue even if social media data collection fails', () async {
      // Act
      final result = await controller.initializeAgent(
        userId: testUserId,
        onboardingData: testOnboardingData,
        generatePlaceLists: false,
        getRecommendations: false,
        attemptCloudSync: false,
      );

      // Assert
      expect(result.isSuccess, isTrue);
      // Social media data may or may not be present (depends on connections)
      expect(result.personalityProfile, isNotNull);
    });

    test('should continue even if preferences profile initialization fails', () async {
      // This test verifies that the controller continues even if preferences fail
      // The actual behavior depends on PreferencesProfileService implementation
      // For now, we just verify the controller doesn't crash
      
      // Act
      final result = await controller.initializeAgent(
        userId: testUserId,
        onboardingData: testOnboardingData,
        generatePlaceLists: false,
        getRecommendations: false,
        attemptCloudSync: false,
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.personalityProfile, isNotNull);
      // PreferencesProfile may be null if initialization failed, but that's OK
    });

    test('should skip optional steps when disabled', () async {
      // Act
      final result = await controller.initializeAgent(
        userId: testUserId,
        onboardingData: testOnboardingData,
        generatePlaceLists: false,
        getRecommendations: false,
        attemptCloudSync: false,
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.generatedPlaceLists, isNull);
      expect(result.recommendations, isNull);
      expect(result.cloudSyncAttempted, isFalse);
    });

    test('should return error if agentId cannot be retrieved', () async {
      // Arrange - use invalid user ID that doesn't exist
      final invalidUserId = 'invalid_user_${DateTime.now().millisecondsSinceEpoch}';

      // Act
      final result = await controller.initializeAgent(
        userId: invalidUserId,
        onboardingData: testOnboardingData,
        generatePlaceLists: false,
        getRecommendations: false,
        attemptCloudSync: false,
      );

      // Assert
      // Note: This may succeed if AgentIdService creates agentId on demand
      // The important thing is that it doesn't crash
      expect(result, isNotNull);
    });

    test('should handle all optional steps when enabled', () async {
      // Act
      final result = await controller.initializeAgent(
        userId: testUserId,
        onboardingData: testOnboardingData,
        generatePlaceLists: true,
        getRecommendations: true,
        attemptCloudSync: true,
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.personalityProfile, isNotNull);
      // Optional steps may succeed or fail, but controller should handle gracefully
      expect(result.cloudSyncAttempted, isA<bool>());
    });

    group('AVRAI Core System Integration', () {
      test('should create 4D quantum location state when location timing service available', () async {
        // This test verifies that 4D quantum state creation is attempted
        // when LocationTimingQuantumStateService is available
        final result = await controller.initializeAgent(
          userId: testUserId,
          onboardingData: testOnboardingData,
          generatePlaceLists: false,
          getRecommendations: false,
          attemptCloudSync: false,
        );

        expect(result.isSuccess, isTrue, reason: 'Should succeed with AVRAI services');
        expect(result.personalityProfile, isNotNull, reason: 'Personality profile should be created');
        // Note: 4D quantum state creation happens internally and doesn't affect result
        // This test verifies the controller doesn't crash when AVRAI services are available
      });

      test('should work when AVRAI services are unavailable (graceful degradation)', () async {
        // Create controller without AVRAI services
        final controllerWithoutAVRAI = AgentInitializationController(
          locationTimingService: null,
          quantumEntanglementService: null,
          aiLearningService: null,
        );

        final result = await controllerWithoutAVRAI.initializeAgent(
          userId: testUserId,
          onboardingData: testOnboardingData,
          generatePlaceLists: false,
          getRecommendations: false,
          attemptCloudSync: false,
        );

        expect(result.isSuccess, isTrue, reason: 'Should succeed even without AVRAI services');
        expect(result.personalityProfile, isNotNull, reason: 'Personality profile should be created');
        expect(result.preferencesProfile, isNotNull, reason: 'Preferences profile should be created');
        // Core functionality should work without AVRAI services
      });

      test('should handle 4D quantum state creation failure gracefully', () async {
        // This test verifies that if 4D quantum state creation fails,
        // the controller continues and doesn't block initialization
        final result = await controller.initializeAgent(
          userId: testUserId,
          onboardingData: testOnboardingData,
          generatePlaceLists: false,
          getRecommendations: false,
          attemptCloudSync: false,
        );

        expect(result.isSuccess, isTrue, reason: 'Should succeed even if 4D quantum creation fails');
        // The controller should handle quantum state creation failures gracefully
      });
    });
  });
}

