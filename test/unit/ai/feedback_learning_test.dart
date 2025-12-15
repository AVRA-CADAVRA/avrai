import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spots/core/ai/feedback_learning.dart' show UserFeedbackAnalyzer, FeedbackEvent, FeedbackType, FeedbackAnalysisResult, BehavioralPattern, SatisfactionPrediction, FeedbackLearningInsights;
import 'package:spots/core/ai/personality_learning.dart' show PersonalityLearning;

import 'feedback_learning_test.mocks.dart';

@GenerateMocks([SharedPreferences, PersonalityLearning])
void main() {
  group('UserFeedbackAnalyzer', () {
    late UserFeedbackAnalyzer analyzer;
    late MockSharedPreferences mockPrefs;
    late MockPersonalityLearning mockPersonalityLearning;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      mockPersonalityLearning = MockPersonalityLearning();
      
      analyzer = UserFeedbackAnalyzer(
        prefs: mockPrefs,
        personalityLearning: mockPersonalityLearning,
      );
    });

    group('Feedback Analysis', () {
      test('should analyze feedback without errors', () async {
        const userId = 'test-user-123';
        final feedback = FeedbackEvent(
          type: FeedbackType.recommendation,
          satisfaction: 0.8,
          metadata: {},
          timestamp: DateTime.now(),
        );

        when(mockPrefs.getString(any)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final result = await analyzer.analyzeFeedback(userId, feedback);

        expect(result, isA<FeedbackAnalysisResult>());
        expect(result.userId, equals(userId));
        expect(result.feedback, equals(feedback));
        expect(result.confidenceScore, greaterThanOrEqualTo(0.0));
        expect(result.confidenceScore, lessThanOrEqualTo(1.0));
      });

      test('should handle different feedback types', () async {
        const userId = 'test-user-123';
        final feedback = FeedbackEvent(
          type: FeedbackType.spotExperience,
          satisfaction: 0.6,
          metadata: {},
          timestamp: DateTime.now(),
        );

        when(mockPrefs.getString(any)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final result = await analyzer.analyzeFeedback(userId, feedback);

        expect(result, isA<FeedbackAnalysisResult>());
        expect(result.feedback.type, equals(FeedbackType.spotExperience));
      });
    });

    group('Behavioral Pattern Identification', () {
      test('should identify behavioral patterns without errors', () async {
        const userId = 'test-user-123';

        when(mockPrefs.getString(any)).thenReturn(null);

        final patterns = await analyzer.identifyBehavioralPatterns(userId);

        expect(patterns, isA<List<BehavioralPattern>>());
      });

      test('should return empty list for insufficient feedback history', () async {
        const userId = 'new-user';

        when(mockPrefs.getString(any)).thenReturn(null);

        final patterns = await analyzer.identifyBehavioralPatterns(userId);

        expect(patterns, isEmpty);
      });
    });

    group('Dimension Extraction', () {
      test('should extract new dimensions without errors', () async {
        const userId = 'test-user-123';

        when(mockPrefs.getString(any)).thenReturn(null);

        // Provide recent feedback input (required by updated API)
        final dimensions = await analyzer.extractNewDimensions(userId, const []);

        expect(dimensions, isA<Map<String, double>>());
      });
    });

    group('Satisfaction Prediction', () {
      test('should predict user satisfaction without errors', () async {
        const userId = 'test-user-123';
        final scenario = {
          'type': 'spot_recommendation',
          'category': 'food',
        };

        when(mockPrefs.getString(any)).thenReturn(null);

        final prediction = await analyzer.predictUserSatisfaction(userId, scenario);

        expect(prediction, isA<SatisfactionPrediction>());
        expect(prediction.predictedSatisfaction, greaterThanOrEqualTo(0.0));
        expect(prediction.predictedSatisfaction, lessThanOrEqualTo(1.0));
        expect(prediction.confidence, greaterThanOrEqualTo(0.0));
        expect(prediction.confidence, lessThanOrEqualTo(1.0));
      });
    });

    group('Feedback Insights', () {
      test('should get feedback insights without errors', () async {
        const userId = 'test-user-123';

        when(mockPrefs.getString(any)).thenReturn(null);

        final insights = await analyzer.getFeedbackInsights(userId);

        expect(insights, isA<FeedbackLearningInsights>());
        expect(insights.userId, equals(userId));
      });
    });
  });
}

