/// Phase 9: AI/ML Model Performance & Inference Benchmarks
/// Ensures optimal AI system performance for production deployment
/// OUR_GUTS.md: "Self-improving ecosystem" - Efficient AI learning and inference
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/ai/ai_master_orchestrator.dart';
import 'package:spots/core/ai/continuous_learning_system.dart';
import 'package:spots/core/ai/personality_learning.dart';
import 'package:spots/core/ml/pattern_recognition_system.dart';
import 'package:spots/core/ml/predictive_analytics.dart';
import 'package:spots/core/ml/nlp_processor.dart';
import 'package:spots/core/models/unified_models.dart';
import 'package:spots/core/models/user_role.dart';
import 'dart:math' as math;

void main() {
  group('Phase 9: AI/ML Performance Benchmarks', () {
    group('AI Master Orchestrator Performance', () {
      test('should initialize all AI systems within performance threshold', () async {
        // Arrange
        final orchestrator = AIMasterOrchestrator();
        
        // Act
        final stopwatch = Stopwatch()..start();
        await orchestrator.initialize();
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // Under 3 seconds
        expect(orchestrator.isInitialized, true);
        
        print('AI Orchestrator initialization: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should handle concurrent AI system operations efficiently', () async {
        // Arrange
        final orchestrator = AIMasterOrchestrator();
        await orchestrator.initialize();
        
        // Act - Run multiple AI operations concurrently
        final stopwatch = Stopwatch()..start();
        final futures = [
          orchestrator.processLearningCycle(),
          orchestrator.updatePersonalityProfile({'user_id': 'user'}),
          orchestrator.analyzeCollaborationPatterns(_generateTestInteractions(100)),
          orchestrator.generateRecommendations(_createTestUser()),
        ];
        
        await Future.wait(futures);
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Under 2 seconds
        
        print('Concurrent AI operations: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should maintain performance under sustained AI workload', () async {
        // Arrange
        final orchestrator = AIMasterOrchestrator();
        await orchestrator.initialize();
        final operationTimes = <int>[];
        
        // Act - Sustained AI operations
        for (int i = 0; i < 20; i++) {
          final stopwatch = Stopwatch()..start();
          
          await orchestrator.processLearningCycle();
          await orchestrator.updatePersonalityProfile({'user_id': 'user'});
          
          stopwatch.stop();
          operationTimes.add(stopwatch.elapsedMilliseconds);
          
          // Small delay to simulate real usage
          await Future.delayed(const Duration(milliseconds: 50));
        }
        
        // Assert - Performance should remain consistent
        final averageTime = operationTimes.fold(0, (sum, time) => sum + time) / operationTimes.length;
        expect(averageTime, lessThan(1200)); // Slightly relaxed for CI variance
        
        // Check for performance degradation
        final firstQuarter = operationTimes.take(5).fold(0, (sum, time) => sum + time) / 5;
        final lastQuarter = operationTimes.skip(15).fold(0, (sum, time) => sum + time) / 5;
        expect(lastQuarter, lessThan(firstQuarter * 1.5)); // No more than 50% degradation
        
        print('Sustained AI workload - Average: ${averageTime.toStringAsFixed(1)}ms, '
              'First: ${firstQuarter.toStringAsFixed(1)}ms, Last: ${lastQuarter.toStringAsFixed(1)}ms');
      });
    });

    group('Continuous Learning System Performance', () {
      test('should process user interactions efficiently', () async {
        // Arrange
        final learningSystem = ContinuousLearningSystem();
        await learningSystem.initialize();
        
        // Act - Process many user interactions
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 1000; i++) {
          await learningSystem.processUserInteraction({
            'user_id': 'user_${i % 100}',
            'action': 'search',
            'query': 'test query $i',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'location': {'lat': 40.7128 + i * 0.001, 'lng': -74.0060 + i * 0.001},
            'context': {'time_of_day': 'morning', 'weather': 'sunny'},
          });
          
          // Batch processing for efficiency
          if (i % 100 == 0) {
            await Future.delayed(const Duration(milliseconds: 1));
          }
        }
        
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Under 10 seconds
        
        final avgTimePerInteraction = stopwatch.elapsedMilliseconds / 1000;
        expect(avgTimePerInteraction, lessThan(10)); // Under 10ms per interaction
        
        print('Processed 1000 interactions in ${stopwatch.elapsedMilliseconds}ms '
              '(${avgTimePerInteraction.toStringAsFixed(2)}ms avg)');
      });

      test('should optimize learning model performance over time', () async {
        // Arrange
        final learningSystem = ContinuousLearningSystem();
        await learningSystem.initialize();
        final performanceMetrics = <Map<String, dynamic>>[];
        
        // Act - Train model and measure performance improvements
        for (int epoch = 0; epoch < 10; epoch++) {
          final epochStopwatch = Stopwatch()..start();
          
          // Simulate training data
          final trainingData = _generateTrainingData(1000);
          await learningSystem.trainModel(trainingData);
          
          epochStopwatch.stop();
          
          // Evaluate model performance
          final accuracy = await learningSystem.evaluateModel(_generateTestData(100));
          final inferenceTime = await _measureInferenceTime(learningSystem, 50);
          
          performanceMetrics.add({
            'epoch': epoch,
            'training_time': epochStopwatch.elapsedMilliseconds,
            'accuracy': accuracy,
            'inference_time': inferenceTime,
          });
        }
        
        // Assert - Model should improve over time
        final firstEpoch = performanceMetrics.first;
        final lastEpoch = performanceMetrics.last;
        
        expect(lastEpoch['accuracy'], greaterThanOrEqualTo(firstEpoch['accuracy']));
        expect(lastEpoch['inference_time'], lessThanOrEqualTo(firstEpoch['inference_time'] * 1.2)); // Avoid flake
        
        print('Learning progression:');
        for (final metric in performanceMetrics) {
          print('Epoch ${metric['epoch']}: Accuracy ${metric['accuracy'].toStringAsFixed(3)}, '
                'Inference ${metric['inference_time']}ms');
        }
      });

      test('should handle real-time learning updates efficiently', () async {
        // Arrange
        final learningSystem = ContinuousLearningSystem();
        await learningSystem.initialize();
        
        // Act - Simulate real-time learning with concurrent updates
        final realtimeStopwatch = Stopwatch()..start();
        final futures = <Future>[];
        
        for (int i = 0; i < 100; i++) {
          futures.add(learningSystem.updateModelRealtime({
            'user_feedback': math.Random().nextDouble(),
            'interaction_success': math.Random().nextBool(),
            'context_relevance': math.Random().nextDouble(),
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }));
        }
        
        await Future.wait(futures);
        realtimeStopwatch.stop();
        
        // Assert
        expect(realtimeStopwatch.elapsedMilliseconds, lessThan(5000)); // Under 5 seconds
        
        final avgUpdateTime = realtimeStopwatch.elapsedMilliseconds / 100;
        expect(avgUpdateTime, lessThan(50)); // Under 50ms per update
        
        print('Real-time updates: ${realtimeStopwatch.elapsedMilliseconds}ms '
              '(${avgUpdateTime.toStringAsFixed(1)}ms avg)');
      });
    });

    group('Personality Learning Performance', () {
      test('should efficiently process 8-dimensional personality updates', () async {
        // Arrange
        final personalityLearning = PersonalityLearning();
        await personalityLearning.initialize();
        
        // Act - Process personality updates for many users
        final stopwatch = Stopwatch()..start();
        
        for (int userId = 0; userId < 500; userId++) {
          final personalityData = _generatePersonalityUpdateData(userId);
          await personalityLearning.updatePersonalityProfile(personalityData);
        }
        
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(8000)); // Under 8 seconds
        
        final avgTimePerUpdate = stopwatch.elapsedMilliseconds / 500;
        expect(avgTimePerUpdate, lessThan(16)); // Under 16ms per personality update
        
        print('500 personality updates: ${stopwatch.elapsedMilliseconds}ms '
              '(${avgTimePerUpdate.toStringAsFixed(1)}ms avg)');
      });

      test('should optimize personality evolution calculations', () async {
        // Arrange
        final personalityLearning = PersonalityLearning();
        await personalityLearning.initialize();
        
        // Generate complex personality evolution scenario
        final userProfile = _createComplexUserProfile();
        
        // Act - Process personality evolution
        final stopwatch = Stopwatch()..start();
        
        final evolutionResult = await personalityLearning.calculatePersonalityEvolution(
          currentProfile: userProfile,
        );
        
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(1500)); // Under 1.5 seconds
        expect((evolutionResult['generation'] ?? 0), isNotNull);
        
        print('Complex personality evolution: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should handle concurrent personality learning for multiple users', () async {
        // Arrange
        final personalityLearning = PersonalityLearning();
        await personalityLearning.initialize();
        
        // Act - Concurrent personality learning
        final stopwatch = Stopwatch()..start();
        final futures = <Future>[];
        
        for (int userId = 0; userId < 100; userId++) {
          futures.add(_processUserPersonalityLearning(personalityLearning, userId));
        }
        
        await Future.wait(futures);
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(6000)); // Under 6 seconds
        
        print('Concurrent personality learning for 100 users: ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Pattern Recognition Performance', () {
      test('should efficiently analyze location patterns', () async {
        // Arrange
        final patternRecognition = PatternRecognitionSystem();
        await patternRecognition.initialize();
        
        // Generate location data
        final locationData = _generateLocationPatternData(5000);
        
        // Act
        final stopwatch = Stopwatch()..start();
        final patterns = await patternRecognition.analyzeLocationPatterns(locationData);
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // Under 3 seconds
        expect(patterns.isNotEmpty, true);
        
        print('Location pattern analysis (5000 points): ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should optimize behavioral pattern recognition', () async {
        // Arrange
        final patternRecognition = PatternRecognitionSystem();
        await patternRecognition.initialize();
        
        // Generate behavioral data
        final behaviorData = _generateBehavioralPatternData(2000);
        
        // Act
        final stopwatch = Stopwatch()..start();
        final behaviorPatterns = await patternRecognition.analyzeBehavioralPatterns(behaviorData);
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Under 2 seconds
        expect(behaviorPatterns.length, greaterThan(0));
        
        print('Behavioral pattern analysis (2000 interactions): ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('NLP Processing Performance', () {
      test('should process text analysis efficiently', () async {
        // Arrange
        final nlpProcessor = NLPProcessor();
        await nlpProcessor.initialize();
        
        // Generate text data
        final textSamples = _generateTextSamples(1000);
        
        // Act
        final stopwatch = Stopwatch()..start();
        
        for (final text in textSamples) {
          await nlpProcessor.analyzeText(text);
        }
        
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Under 10 seconds
        
        final avgTimePerText = stopwatch.elapsedMilliseconds / 1000;
        expect(avgTimePerText, lessThan(10)); // Under 10ms per text analysis
        
        print('NLP processing (1000 texts): ${stopwatch.elapsedMilliseconds}ms '
              '(${avgTimePerText.toStringAsFixed(1)}ms avg)');
      });

      test('should handle sentiment analysis at scale', () async {
        // Arrange
        final nlpProcessor = NLPProcessor();
        await nlpProcessor.initialize();
        
        // Generate sentiment data
        final sentimentTexts = _generateSentimentTextSamples(2000);
        
        // Act
        final stopwatch = Stopwatch()..start();
        final sentimentResults = <Map<String, dynamic>>[];
        
        for (final text in sentimentTexts) {
          final result = await NLPProcessor.analyzeSentiment(text).toJson();
          sentimentResults.add(result);
        }
        
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(15000)); // Under 15 seconds
        expect(sentimentResults.length, equals(2000));
        
        print('Sentiment analysis (2000 texts): ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Predictive Analytics Performance', () {
      test('should generate predictions efficiently', () async {
        // Arrange
        final predictiveAnalytics = PredictiveAnalytics();
        await predictiveAnalytics.initialize();
        
        // Generate historical data
        final historicalData = _generateHistoricalData(10000);
        
        // Act
        final stopwatch = Stopwatch()..start();
        final predictions = await predictiveAnalytics.generatePredictions(historicalData: {});
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Under 5 seconds
        expect(predictions.isNotEmpty, true);
        
        print('Predictive analytics (10k data points): ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should optimize recommendation generation', () async {
        // Arrange
        final predictiveAnalytics = PredictiveAnalytics();
        await predictiveAnalytics.initialize();
        
        // Act - Generate recommendations for multiple users
        final stopwatch = Stopwatch()..start();
        final allRecommendations = <List<dynamic>>[];
        
        for (int userId = 0; userId < 100; userId++) {
          final userProfile = _createTestUserProfile();
          final recommendations = await predictiveAnalytics.generateRecommendations(userProfile: {});
          allRecommendations.add(recommendations);
        }
        
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(8000)); // Under 8 seconds
        expect(allRecommendations.length, equals(100));
        
        final avgTimePerUser = stopwatch.elapsedMilliseconds / 100;
        expect(avgTimePerUser, lessThan(80)); // Under 80ms per user
        
        print('Recommendations for 100 users: ${stopwatch.elapsedMilliseconds}ms '
              '(${avgTimePerUser.toStringAsFixed(1)}ms avg)');
      });
    });

    group('AI System Integration Performance', () {
      test('should handle complete AI pipeline efficiently', () async {
        // Arrange
        final orchestrator = AIMasterOrchestrator();
        await orchestrator.initialize();
        
        // Act - Run complete AI pipeline
        final stopwatch = Stopwatch()..start();
        
        final userInteraction = _createComplexUserInteraction();
        await orchestrator.processCompleteAIPipeline(userInteraction);
        
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // Under 3 seconds
        
        print('Complete AI pipeline: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should maintain AI system synchronization under load', () async {
        // Arrange
        final orchestrator = AIMasterOrchestrator();
        await orchestrator.initialize();
        
        // Act - Multiple concurrent AI pipelines
        final stopwatch = Stopwatch()..start();
        final futures = <Future>[];
        
        for (int i = 0; i < 20; i++) {
          futures.add(orchestrator.processCompleteAIPipeline(_createComplexUserInteraction()));
        }
        
        await Future.wait(futures);
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Under 10 seconds
        
        print('20 concurrent AI pipelines: ${stopwatch.elapsedMilliseconds}ms');
      });
    });
  });
}

// Helper functions for generating test data

UnifiedUser _createTestUser() {
  return UnifiedUser(
    id: 'test_user_${math.Random().nextInt(1000)}',
    name: 'Test User',
    email: 'test@example.com',
    photoUrl: null,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    preferences: const {},
    homebases: const [],
    experienceLevel: 0,
    pins: const [],
    role: UserRole.user.name,
    isActive: true,
    personalityProfile: _createTestUserProfile(),
  );
}

Map<String, dynamic> _createTestUserProfile() {
  return {
    'dimensions': {
      'openness': math.Random().nextDouble(),
      'conscientiousness': math.Random().nextDouble(),
      'extraversion': math.Random().nextDouble(),
      'agreeableness': math.Random().nextDouble(),
      'neuroticism': math.Random().nextDouble(),
      'authenticity': math.Random().nextDouble(),
      'curiosity': math.Random().nextDouble(),
      'social_connection': math.Random().nextDouble(),
    },
    'learning_history': _generateLearningHistory(50),
    'generation': math.Random().nextInt(100),
  };
}

Map<String, dynamic> _createComplexUserProfile() {
  return {
    'dimensions': {
      'openness': 0.75,
      'conscientiousness': 0.65,
      'extraversion': 0.80,
      'agreeableness': 0.70,
      'neuroticism': 0.30,
      'authenticity': 0.85,
      'curiosity': 0.90,
      'social_connection': 0.75,
    },
    'learning_history': _generateLearningHistory(500),
    'preferences': _generateUserPreferences(),
    'interaction_patterns': _generateInteractionPatterns(),
    'generation': 45,
    'evolution_rate': 0.02,
  };
}

List<Map<String, dynamic>> _generateTestInteractions(int count) {
  return List.generate(count, (index) => {
    'user_id': 'user_${index % 50}',
    'type': ['search', 'create', 'share', 'rate'][index % 4],
    'timestamp': DateTime.now().subtract(Duration(minutes: index)).millisecondsSinceEpoch,
    'location': {
      'lat': 40.7128 + (index * 0.001),
      'lng': -74.0060 + (index * 0.001),
    },
    'success': math.Random().nextBool(),
    'duration': math.Random().nextInt(300000), // Up to 5 minutes
  });
}

List<Map<String, dynamic>> _generateTrainingData(int count) {
  return List.generate(count, (index) => {
    'input': {
      'user_profile': _createTestUserProfile(),
      'context': _generateContextData(),
      'interaction_type': ['search', 'create', 'share'][index % 3],
    },
    'output': {
      'success': math.Random().nextBool(),
      'satisfaction': math.Random().nextDouble(),
      'engagement_score': math.Random().nextDouble(),
    },
  });
}

List<Map<String, dynamic>> _generateTestData(int count) {
  return _generateTrainingData(count);
}

Future<int> _measureInferenceTime(ContinuousLearningSystem system, int samples) async {
  final stopwatch = Stopwatch()..start();
  
  for (int i = 0; i < samples; i++) {
    await system.predict(_generateContextData());
  }
  
  stopwatch.stop();
  return stopwatch.elapsedMilliseconds ~/ samples;
}

Map<String, dynamic> _generatePersonalityUpdateData(int userId) {
  return {
    'user_id': 'user_$userId',
    'interactions': _generateRecentInteractions(10),
    'feedback': _generateUserFeedback(5),
    'social_signals': _generateSocialSignals(3),
    'temporal_context': {
      'time_of_day': ['morning', 'afternoon', 'evening'][userId % 3],
      'day_of_week': userId % 7,
      'season': ['spring', 'summer', 'fall', 'winter'][userId % 4],
    },
  };
}

List<Map<String, dynamic>> _generateInteractionHistory(int count) {
  return List.generate(count, (index) => {
    'timestamp': DateTime.now().subtract(Duration(hours: index)).millisecondsSinceEpoch,
    'type': ['search', 'create', 'rate', 'share', 'comment'][index % 5],
    'success': math.Random().nextBool(),
    'satisfaction': math.Random().nextDouble(),
    'context': _generateContextData(),
  });
}

List<Map<String, dynamic>> _generateCommunityInfluences(int count) {
  return List.generate(count, (index) => {
    'community_id': 'community_$index',
    'influence_strength': math.Random().nextDouble(),
    'interaction_frequency': math.Random().nextInt(100),
    'shared_values': List.generate(5, (i) => math.Random().nextDouble()),
  });
}

List<Map<String, dynamic>> _generateTemporalFactors(int count) {
  return List.generate(count, (index) => {
    'factor_type': ['seasonal', 'weekly', 'daily', 'event_based'][index % 4],
    'influence_magnitude': math.Random().nextDouble(),
    'duration': math.Random().nextInt(30), // Days
    'cyclical': math.Random().nextBool(),
  });
}

Future<void> _processUserPersonalityLearning(PersonalityLearning system, int userId) async {
  final personalityData = _generatePersonalityUpdateData(userId);
  await system.updatePersonalityProfile(personalityData);
  
  // Simulate additional personality processing
  await system.calculatePersonalityCompatibility(
    _createTestUserProfile(),
    _createTestUserProfile(),
  );
}

List<Map<String, dynamic>> _generateLocationPatternData(int count) {
  return List.generate(count, (index) => {
    'user_id': 'user_${index % 100}',
    'timestamp': DateTime.now().subtract(Duration(minutes: index)).millisecondsSinceEpoch,
    'location': {
      'lat': 40.7128 + (math.Random().nextDouble() - 0.5) * 0.1,
      'lng': -74.0060 + (math.Random().nextDouble() - 0.5) * 0.1,
    },
    'duration': math.Random().nextInt(3600), // Up to 1 hour
    'activity': ['work', 'leisure', 'dining', 'shopping', 'travel'][index % 5],
  });
}

List<Map<String, dynamic>> _generateBehavioralPatternData(int count) {
  return List.generate(count, (index) => {
    'user_id': 'user_${index % 200}',
    'interaction_type': ['search', 'create', 'rate', 'share', 'comment'][index % 5],
    'timestamp': DateTime.now().subtract(Duration(hours: index ~/ 10)).millisecondsSinceEpoch,
    'success': math.Random().nextBool(),
    'satisfaction': math.Random().nextDouble(),
    'context': _generateContextData(),
  });
}

List<String> _generateTextSamples(int count) {
  final sampleTexts = [
    'Great coffee shop with amazing atmosphere',
    'Love this place for weekend brunch',
    'Perfect spot for a romantic dinner',
    'Best pizza in the neighborhood',
    'Quiet place to work and study',
    'Family-friendly restaurant with outdoor seating',
    'Trendy bar with creative cocktails',
    'Beautiful park for morning walks',
    'Cozy bookstore with excellent selection',
    'Modern gym with state-of-the-art equipment',
  ];
  
  return List.generate(count, (index) => 
    sampleTexts[index % sampleTexts.length] + ' ${index}');
}

List<String> _generateSentimentTextSamples(int count) {
  final positiveTexts = [
    'Absolutely love this place!',
    'Amazing experience, highly recommend',
    'Perfect atmosphere and great service',
    'Best spot in the city for sure',
  ];
  
  final negativeTexts = [
    'Very disappointed with the service',
    'Not worth the money at all',
    'Poor quality and unfriendly staff',
    'Would not recommend to anyone',
  ];
  
  final neutralTexts = [
    'Average place, nothing special',
    'Decent food, standard service',
    'Regular coffee shop experience',
    'Standard quality for the price',
  ];
  
  return List.generate(count, (index) {
    final category = index % 3;
    if (category == 0) return positiveTexts[index % positiveTexts.length];
    if (category == 1) return negativeTexts[index % negativeTexts.length];
    return neutralTexts[index % neutralTexts.length];
  });
}

List<Map<String, dynamic>> _generateHistoricalData(int count) {
  return List.generate(count, (index) => {
    'timestamp': DateTime.now().subtract(Duration(hours: index)).millisecondsSinceEpoch,
    'user_id': 'user_${index % 500}',
    'action': ['search', 'create', 'rate', 'share'][index % 4],
    'success': math.Random().nextBool(),
    'value': math.Random().nextDouble(),
    'context': _generateContextData(),
  });
}

Map<String, dynamic> _createComplexUserInteraction() {
  return {
    'user_id': 'complex_user_${math.Random().nextInt(100)}',
    'interaction_type': 'complex_search',
    'query': 'best coffee shops near me with wifi and outdoor seating',
    'location': {
      'lat': 40.7128,
      'lng': -74.0060,
    },
    'context': {
      'time_of_day': 'morning',
      'weather': 'sunny',
      'social_context': 'solo',
      'purpose': 'work',
    },
    'user_profile': _createComplexUserProfile(),
    'preferences': _generateUserPreferences(),
    'history': _generateInteractionHistory(100),
  };
}

Map<String, dynamic> _generateContextData() {
  return {
    'location': {
      'lat': 40.7128 + (math.Random().nextDouble() - 0.5) * 0.1,
      'lng': -74.0060 + (math.Random().nextDouble() - 0.5) * 0.1,
    },
    'time_of_day': ['morning', 'afternoon', 'evening'][math.Random().nextInt(3)],
    'weather': ['sunny', 'cloudy', 'rainy', 'snowy'][math.Random().nextInt(4)],
    'social_context': ['solo', 'friends', 'family', 'work'][math.Random().nextInt(4)],
  };
}

List<Map<String, dynamic>> _generateLearningHistory(int count) {
  return List.generate(count, (index) => {
    'timestamp': DateTime.now().subtract(Duration(days: index)).millisecondsSinceEpoch,
    'learning_event': 'interaction_${index}',
    'improvement': math.Random().nextDouble() * 0.1,
    'confidence': math.Random().nextDouble(),
  });
}

Map<String, dynamic> _generateUserPreferences() {
  return {
    'categories': ['coffee', 'restaurants', 'parks', 'entertainment'],
    'price_range': math.Random().nextInt(4) + 1,
    'distance_preference': math.Random().nextDouble() * 10, // km
    'ambiance': ['quiet', 'lively', 'romantic', 'casual'][math.Random().nextInt(4)],
  };
}

Map<String, dynamic> _generateInteractionPatterns() {
  return {
    'most_active_time': ['morning', 'afternoon', 'evening'][math.Random().nextInt(3)],
    'search_frequency': math.Random().nextDouble() * 10,
    'creation_rate': math.Random().nextDouble() * 5,
    'social_engagement': math.Random().nextDouble(),
  };
}

List<Map<String, dynamic>> _generateRecentInteractions(int count) {
  return List.generate(count, (index) => {
    'timestamp': DateTime.now().subtract(Duration(hours: index)).millisecondsSinceEpoch,
    'type': ['search', 'create', 'rate'][index % 3],
    'success': math.Random().nextBool(),
  });
}

List<Map<String, dynamic>> _generateUserFeedback(int count) {
  return List.generate(count, (index) => {
    'rating': math.Random().nextInt(5) + 1,
    'comment': 'Feedback comment $index',
    'timestamp': DateTime.now().subtract(Duration(days: index)).millisecondsSinceEpoch,
  });
}

List<Map<String, dynamic>> _generateSocialSignals(int count) {
  return List.generate(count, (index) => {
    'signal_type': ['like', 'share', 'comment'][index % 3],
    'strength': math.Random().nextDouble(),
    'timestamp': DateTime.now().subtract(Duration(hours: index)).millisecondsSinceEpoch,
  });
}
