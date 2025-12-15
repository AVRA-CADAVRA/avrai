import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/trending_analysis_service.dart';
import '../../helpers/platform_channel_helper.dart';

/// Trending Analysis Service Tests
/// Tests trending analysis functionality
void main() {

  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  group('TrendingAnalysisService Tests', () {
    group('analyzeTrends', () {
      test('should analyze trends and return analysis map', () {
        final data = [
          {'topic': 'coffee', 'location': 'San Francisco'},
          {'topic': 'restaurants', 'location': 'New York'},
        ];

        final analysis = TrendingAnalysisService.analyzeTrends(data);

        expect(analysis, isA<Map<String, dynamic>>());
        expect(analysis['trendingTopics'], isA<List<String>>());
        expect(analysis['trendingLocations'], isA<List<String>>());
        expect(analysis['trendingActivities'], isA<List<String>>());
      });

      test('should return trending topics list', () {
        final data = [
          {'topic': 'coffee', 'count': 10},
          {'topic': 'restaurants', 'count': 5},
        ];

        final analysis = TrendingAnalysisService.analyzeTrends(data);

        expect(analysis['trendingTopics'], isA<List<String>>());
      });

      test('should return trending locations list', () {
        final data = [
          {'location': 'San Francisco', 'count': 15},
          {'location': 'New York', 'count': 8},
        ];

        final analysis = TrendingAnalysisService.analyzeTrends(data);

        expect(analysis['trendingLocations'], isA<List<String>>());
      });

      test('should return trending activities list', () {
        final data = [
          {'activity': 'dining', 'count': 20},
          {'activity': 'exploring', 'count': 12},
        ];

        final analysis = TrendingAnalysisService.analyzeTrends(data);

        expect(analysis['trendingActivities'], isA<List<String>>());
      });

      test('should handle empty data list', () {
        final data = <Map<String, dynamic>>[];

        final analysis = TrendingAnalysisService.analyzeTrends(data);

        expect(analysis, isA<Map<String, dynamic>>());
        expect(analysis['trendingTopics'], isA<List<String>>());
        expect(analysis['trendingLocations'], isA<List<String>>());
        expect(analysis['trendingActivities'], isA<List<String>>());
      });

      test('should handle complex data', () {
        final data = [
          {
            'topic': 'coffee',
            'location': 'San Francisco',
            'activity': 'exploring',
            'timestamp': DateTime.now().toIso8601String(),
          },
          {
            'topic': 'restaurants',
            'location': 'New York',
            'activity': 'dining',
            'timestamp': DateTime.now().toIso8601String(),
          },
        ];

        final analysis = TrendingAnalysisService.analyzeTrends(data);

        expect(analysis, isA<Map<String, dynamic>>());
        expect(analysis['trendingTopics'], isA<List<String>>());
        expect(analysis['trendingLocations'], isA<List<String>>());
        expect(analysis['trendingActivities'], isA<List<String>>());
      });
    });
  });
}

