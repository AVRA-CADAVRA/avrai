import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/predictive_analysis_service.dart';
import '../../helpers/platform_channel_helper.dart';

/// Predictive Analysis Service Tests
/// Tests predictive analysis functionality
void main() {

  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  group('PredictiveAnalysisService Tests', () {
    group('predictUserBehavior', () {
      test('should predict user behavior and return analysis map', () {
        final userData = {
          'userId': 'user-123',
          'preferences': {'food': 'Italian', 'music': 'Jazz'},
        };

        final prediction = PredictiveAnalysisService.predictUserBehavior(userData);

        expect(prediction, isA<Map<String, dynamic>>());
        expect(prediction['nextActions'], isA<List<String>>());
        expect(prediction['recommendations'], isA<List<String>>());
        expect(prediction['confidence'], isA<double>());
      });

      test('should return confidence score', () {
        final userData = {
          'userId': 'user-123',
        };

        final prediction = PredictiveAnalysisService.predictUserBehavior(userData);

        expect(prediction['confidence'], isA<double>());
        expect(prediction['confidence'], greaterThanOrEqualTo(0.0));
        expect(prediction['confidence'], lessThanOrEqualTo(1.0));
      });

      test('should return next actions list', () {
        final userData = {
          'userId': 'user-123',
          'recentActivity': ['visited_spot', 'created_list'],
        };

        final prediction = PredictiveAnalysisService.predictUserBehavior(userData);

        expect(prediction['nextActions'], isA<List<String>>());
      });

      test('should return recommendations list', () {
        final userData = {
          'userId': 'user-123',
          'interests': ['food', 'travel'],
        };

        final prediction = PredictiveAnalysisService.predictUserBehavior(userData);

        expect(prediction['recommendations'], isA<List<String>>());
      });

      test('should handle empty user data', () {
        final userData = <String, dynamic>{};

        final prediction = PredictiveAnalysisService.predictUserBehavior(userData);

        expect(prediction, isA<Map<String, dynamic>>());
        expect(prediction['nextActions'], isA<List<String>>());
        expect(prediction['recommendations'], isA<List<String>>());
        expect(prediction['confidence'], isA<double>());
      });

      test('should handle complex user data', () {
        final userData = {
          'userId': 'user-123',
          'preferences': {
            'food': 'Italian',
            'music': 'Jazz',
            'activities': ['hiking', 'reading'],
          },
          'location': 'San Francisco',
          'age': 30,
          'recentSpots': [
            {'name': 'Spot 1', 'category': 'Restaurant'},
            {'name': 'Spot 2', 'category': 'Cafe'},
          ],
        };

        final prediction = PredictiveAnalysisService.predictUserBehavior(userData);

        expect(prediction, isA<Map<String, dynamic>>());
        expect(prediction['nextActions'], isA<List<String>>());
        expect(prediction['recommendations'], isA<List<String>>());
        expect(prediction['confidence'], isA<double>());
      });
    });
  });
}

