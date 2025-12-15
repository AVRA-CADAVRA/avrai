import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/personality_analysis_service.dart';
import '../../helpers/platform_channel_helper.dart';

/// Personality Analysis Service Tests
/// Tests personality analysis functionality
void main() {

  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  group('PersonalityAnalysisService Tests', () {
    group('analyzePersonality', () {
      test('should analyze personality and return analysis map', () {
        final userData = {
          'userId': 'user-123',
          'preferences': {'food': 'Italian', 'music': 'Jazz'},
        };

        final analysis = PersonalityAnalysisService.analyzePersonality(userData);

        expect(analysis, isA<Map<String, dynamic>>());
        expect(analysis['traits'], isA<Map<String, double>>());
        expect(analysis['preferences'], isA<Map<String, double>>());
        expect(analysis['compatibility'], isA<Map<String, double>>());
      });

      test('should return traits map', () {
        final userData = {
          'userId': 'user-123',
        };

        final analysis = PersonalityAnalysisService.analyzePersonality(userData);

        expect(analysis['traits'], isA<Map<String, double>>());
      });

      test('should return preferences map', () {
        final userData = {
          'userId': 'user-123',
          'preferences': {'food': 'Italian'},
        };

        final analysis = PersonalityAnalysisService.analyzePersonality(userData);

        expect(analysis['preferences'], isA<Map<String, double>>());
      });

      test('should return compatibility map', () {
        final userData = {
          'userId': 'user-123',
        };

        final analysis = PersonalityAnalysisService.analyzePersonality(userData);

        expect(analysis['compatibility'], isA<Map<String, double>>());
      });

      test('should handle empty user data', () {
        final userData = <String, dynamic>{};

        final analysis = PersonalityAnalysisService.analyzePersonality(userData);

        expect(analysis, isA<Map<String, dynamic>>());
        expect(analysis['traits'], isA<Map<String, double>>());
        expect(analysis['preferences'], isA<Map<String, double>>());
        expect(analysis['compatibility'], isA<Map<String, double>>());
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
        };

        final analysis = PersonalityAnalysisService.analyzePersonality(userData);

        expect(analysis, isA<Map<String, dynamic>>());
        expect(analysis['traits'], isA<Map<String, double>>());
        expect(analysis['preferences'], isA<Map<String, double>>());
        expect(analysis['compatibility'], isA<Map<String, double>>());
      });

      test('should handle user data with personality dimensions', () {
        final userData = {
          'userId': 'user-123',
          'personality': {
            'exploration_eagerness': 0.8,
            'community_orientation': 0.6,
          },
        };

        final analysis = PersonalityAnalysisService.analyzePersonality(userData);

        expect(analysis, isA<Map<String, dynamic>>());
        expect(analysis['traits'], isA<Map<String, double>>());
      });
    });
  });
}

