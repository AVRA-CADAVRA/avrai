import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/contextual_personality_service.dart';
import 'package:spots/core/models/personality_profile.dart';
import '../fixtures/model_factories.dart';
import '../helpers/test_helpers.dart';

/// SPOTS Contextual Personality Integration Tests
/// Date: December 1, 2025
/// Purpose: Test ContextualPersonalityService integration with personality learning
/// 
/// Test Coverage:
/// - Personality change classification integration
/// - Transition detection integration
/// - Context-aware personality updates
/// - AI2AI learning integration
/// - User action integration
/// 
/// Dependencies:
/// - ContextualPersonalityService: Change classification
/// - PersonalityProfile: Core personality model
/// - ContextualPersonality: Context-specific personality

void main() {
  group('Contextual Personality Integration Tests', () {
    late ContextualPersonalityService service;
    late PersonalityProfile testProfile;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      
      service = ContextualPersonalityService();
      
      testProfile = ModelFactories.createTestPersonalityProfile(
        userId: 'user-123',
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Personality Change Classification Integration', () {
      test('should classify small changes as context updates', () async {
        // Arrange
        final smallChanges = {
          'adventurous': 0.05, // Small change
        };
        
        // Act
        final classification = await service.classifyChange(
          currentProfile: testProfile,
          proposedChanges: smallChanges,
          activeContext: 'coffee',
          changeSource: 'user_action',
        );
        
        // Assert
        expect(classification, equals('context'));
      });

      test('should classify user actions as core updates when no context', () async {
        // Arrange
        final changes = {
          'adventurous': 0.20, // Significant change
        };
        
        // Act
        final classification = await service.classifyChange(
          currentProfile: testProfile,
          proposedChanges: changes,
          activeContext: null,
          changeSource: 'user_action',
        );
        
        // Assert
        expect(classification, equals('core'));
      });

      test('should resist large AI2AI changes', () async {
        // Arrange
        final largeChanges = {
          'adventurous': 0.60, // Large change
        };
        
        // Act
        final classification = await service.classifyChange(
          currentProfile: testProfile,
          proposedChanges: largeChanges,
          activeContext: null,
          changeSource: 'ai2ai',
        );
        
        // Assert
        expect(classification, equals('resist'));
      });
    });

    group('Transition Detection Integration', () {
      test('should detect authentic transitions from change history', () async {
        // Arrange
        final recentChanges = List.generate(10, (i) => {
          'adventurous': 0.05 * (i + 1), // Gradual increase
        });
        
        // Act
        final transition = await service.detectTransition(
          profile: testProfile,
          recentChanges: recentChanges,
          window: const Duration(days: 30),
        );
        
        // Assert
        expect(transition, isNotNull);
        expect(transition!.isAuthentic, isTrue);
      });

      test('should return null for insufficient change data', () async {
        // Arrange
        final fewChanges = [
          {'adventurous': 0.10},
          {'adventurous': 0.15},
        ];
        
        // Act
        final transition = await service.detectTransition(
          profile: testProfile,
          recentChanges: fewChanges,
          window: const Duration(days: 30),
        );
        
        // Assert
        expect(transition, isNull);
      });
    });

    group('Context-Aware Updates Integration', () {
      test('should route context-specific changes to context layer', () async {
        // Arrange
        final changes = {
          'adventurous': 0.20,
        };
        
        // Act
        final classification = await service.classifyChange(
          currentProfile: testProfile,
          proposedChanges: changes,
          activeContext: 'coffee',
          changeSource: 'user_action',
        );
        
        // Assert
        expect(classification, equals('context'));
      });
    });
  });
}

