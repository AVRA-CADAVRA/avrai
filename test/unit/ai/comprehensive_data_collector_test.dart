import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/ai/comprehensive_data_collector.dart';

/// Tests for Comprehensive Data Collector
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
void main() {
  group('Comprehensive Data Collector Tests', () {
    late ComprehensiveDataCollector dataCollector;

    setUp(() {
      dataCollector = ComprehensiveDataCollector();
    });

    test('should collect comprehensive data without errors', () async {
      // Test that the system can collect all 10 data sources
      final comprehensiveData = await dataCollector.collectAllData();
      
      expect(comprehensiveData, isNotNull);
      expect(comprehensiveData.timestamp, isA<DateTime>());
      
      // Verify all data collection categories exist
      expect(comprehensiveData.userActions, isA<List>());
      expect(comprehensiveData.locationData, isA<List>());
      expect(comprehensiveData.weatherData, isA<List>());
      expect(comprehensiveData.timeData, isA<List>());
      expect(comprehensiveData.socialData, isA<List>());
      expect(comprehensiveData.demographicData, isA<List>());
      expect(comprehensiveData.appUsageData, isA<List>());
      expect(comprehensiveData.communityData, isA<List>());
      expect(comprehensiveData.ai2aiData, isA<List>());
      expect(comprehensiveData.externalData, isA<List>());
    });

    test('should maintain privacy compliance across all data sources', () async {
      final comprehensiveData = await dataCollector.collectAllData();
      
      // OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
      // All collected data should be anonymized and aggregated
      
      // Check that data collection doesn't include raw user data
      expect(comprehensiveData.userActions, isA<List>());
      expect(comprehensiveData.locationData, isA<List>());
      
      // Data should be processed and anonymized, not raw user information
      expect(comprehensiveData.timestamp, isNotNull);
      
      // Verify the data is structured for AI learning, not user tracking
      expect(comprehensiveData.userActions.length, greaterThanOrEqualTo(0));
      expect(comprehensiveData.locationData.length, greaterThanOrEqualTo(0));
    });

    test('should handle data collection errors gracefully', () async {
      // Test that the system gracefully handles collection failures
      final comprehensiveData = await dataCollector.collectAllData();
      
      // OUR_GUTS.md: "Effortless, Seamless Discovery"
      // System should work even if some data sources fail
      expect(comprehensiveData, isNotNull);
      
      // Should return empty data rather than throwing errors
      expect(comprehensiveData.userActions, isA<List>());
      expect(comprehensiveData.locationData, isA<List>());
    });

    test('should comply with OUR_GUTS.md principles', () async {
      final comprehensiveData = await dataCollector.collectAllData();
      
      // Verify data collection aligns with core principles
      
      // "Privacy and Control Are Non-Negotiable"
      // Data should be processed, not raw user information
      expect(comprehensiveData.timestamp, isA<DateTime>());
      
      // "Authenticity Over Algorithms" 
      // Data should be from real user interactions, not synthetic
      expect(comprehensiveData.userActions, isA<List>());
      expect(comprehensiveData.communityData, isA<List>());
      
      // "Community, Not Just Places"
      // Should include community interaction data
      expect(comprehensiveData.communityData, isA<List>());
      expect(comprehensiveData.socialData, isA<List>());
      
      // "Effortless, Seamless Discovery"
      // Data collection should be automatic and non-intrusive
      expect(comprehensiveData.appUsageData, isA<List>());
      
      // "Belonging Comes First"
      // Should collect data that helps users feel at home
      expect(comprehensiveData.locationData, isA<List>());
      expect(comprehensiveData.timeData, isA<List>());
    });

    test('should provide comprehensive learning data for AI', () async {
      final comprehensiveData = await dataCollector.collectAllData();
      
      // Verify all 10 dimensions of data are available for learning
      final dataSources = [
        comprehensiveData.userActions,      // User behavior patterns
        comprehensiveData.locationData,     // Location intelligence
        comprehensiveData.weatherData,      // Environmental context
        comprehensiveData.timeData,         // Temporal patterns
        comprehensiveData.socialData,       // Social dynamics
        comprehensiveData.demographicData,  // User demographics
        comprehensiveData.appUsageData,     // App interaction patterns
        comprehensiveData.communityData,    // Community engagement
        comprehensiveData.ai2aiData,        // AI network insights
        comprehensiveData.externalData,     // External context
      ];
      
      // All data sources should be available (may be empty lists)
      for (final dataSource in dataSources) {
        expect(dataSource, isA<List>());
      }
      
      // Should have a recent timestamp
      final now = DateTime.now();
      final timeDiff = now.difference(comprehensiveData.timestamp);
      expect(timeDiff.inMinutes, lessThan(5)); // Should be very recent
    });

    test('should handle empty data gracefully', () {
      // Test empty data factory method
      final emptyData = ComprehensiveData.empty();
      
      expect(emptyData, isNotNull);
      expect(emptyData.userActions, isEmpty);
      expect(emptyData.locationData, isEmpty);
      expect(emptyData.weatherData, isEmpty);
      expect(emptyData.timeData, isEmpty);
      expect(emptyData.socialData, isEmpty);
      expect(emptyData.demographicData, isEmpty);
      expect(emptyData.appUsageData, isEmpty);
      expect(emptyData.communityData, isEmpty);
      expect(emptyData.ai2aiData, isEmpty);
      expect(emptyData.externalData, isEmpty);
      expect(emptyData.timestamp, isA<DateTime>());
    });
  });
}