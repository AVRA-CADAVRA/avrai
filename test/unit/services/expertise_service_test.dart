import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/expertise_service.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/models/expertise_pin.dart';
import 'package:spots/core/models/expertise_progress.dart';
import '../../fixtures/model_factories.dart';

/// Expertise Service Tests
/// OUR_GUTS.md: "Pins, Not Badges" - Tests expertise calculation based on authentic contributions
void main() {
  group('ExpertiseService Tests', () {
    late ExpertiseService service;

    setUp(() {
      service = ExpertiseService();
    });

    group('calculateExpertiseLevel', () {
      test('should return local level for minimum contributions', () {
        final level = service.calculateExpertiseLevel(
          respectedListsCount: 1,
          thoughtfulReviewsCount: 0,
          spotsReviewedCount: 0,
          communityTrustScore: 0.5,
        );

        expect(level, equals(ExpertiseLevel.local));
      });

      test('should return local level for 10+ thoughtful reviews', () {
        final level = service.calculateExpertiseLevel(
          respectedListsCount: 0,
          thoughtfulReviewsCount: 10,
          spotsReviewedCount: 0,
          communityTrustScore: 0.5,
        );

        expect(level, equals(ExpertiseLevel.local));
      });

      test('should return city level for 3+ respected lists', () {
        final level = service.calculateExpertiseLevel(
          respectedListsCount: 3,
          thoughtfulReviewsCount: 0,
          spotsReviewedCount: 0,
          communityTrustScore: 0.5,
        );

        expect(level, equals(ExpertiseLevel.city));
      });

      test('should return city level for 25+ thoughtful reviews', () {
        final level = service.calculateExpertiseLevel(
          respectedListsCount: 0,
          thoughtfulReviewsCount: 25,
          spotsReviewedCount: 0,
          communityTrustScore: 0.5,
        );

        expect(level, equals(ExpertiseLevel.city));
      });

      test('should return regional level for 6+ respected lists', () {
        final level = service.calculateExpertiseLevel(
          respectedListsCount: 6,
          thoughtfulReviewsCount: 0,
          spotsReviewedCount: 0,
          communityTrustScore: 0.5,
        );

        expect(level, equals(ExpertiseLevel.regional));
      });

      test('should return regional level for 50+ thoughtful reviews', () {
        final level = service.calculateExpertiseLevel(
          respectedListsCount: 0,
          thoughtfulReviewsCount: 50,
          spotsReviewedCount: 0,
          communityTrustScore: 0.5,
        );

        expect(level, equals(ExpertiseLevel.regional));
      });

      test('should return national level for 11+ respected lists', () {
        final level = service.calculateExpertiseLevel(
          respectedListsCount: 11,
          thoughtfulReviewsCount: 0,
          spotsReviewedCount: 0,
          communityTrustScore: 0.5,
        );

        expect(level, equals(ExpertiseLevel.national));
      });

      test('should return national level for 100+ thoughtful reviews', () {
        final level = service.calculateExpertiseLevel(
          respectedListsCount: 0,
          thoughtfulReviewsCount: 100,
          spotsReviewedCount: 0,
          communityTrustScore: 0.5,
        );

        expect(level, equals(ExpertiseLevel.national));
      });

      test('should return global level for 21+ respected lists with high trust', () {
        final level = service.calculateExpertiseLevel(
          respectedListsCount: 21,
          thoughtfulReviewsCount: 0,
          spotsReviewedCount: 0,
          communityTrustScore: 0.8,
        );

        expect(level, equals(ExpertiseLevel.global));
      });

      test('should use location parameter', () {
        final level = service.calculateExpertiseLevel(
          respectedListsCount: 3,
          thoughtfulReviewsCount: 0,
          spotsReviewedCount: 0,
          communityTrustScore: 0.5,
          location: 'San Francisco',
        );

        expect(level, equals(ExpertiseLevel.city));
      });
    });

    group('getUserPins', () {
      test('should return pins from user expertise map', () {
        final user = ModelFactories.createTestUser(
          id: 'test-user',
          tags: ['food', 'travel'],
        ).copyWith(
          expertiseMap: {
            'food': 'city',
            'travel': 'local',
          },
        );

        final pins = service.getUserPins(user);

        expect(pins, isA<List<ExpertisePin>>());
        expect(pins.length, equals(2));
        expect(pins[0].category, equals('food'));
        expect(pins[1].category, equals('travel'));
      });

      test('should return empty list for user with no expertise', () {
        final user = ModelFactories.createTestUser(
          id: 'test-user',
          tags: [],
        );

        final pins = service.getUserPins(user);

        expect(pins, isEmpty);
      });
    });

    group('calculateProgress', () {
      test('should calculate progress toward next level', () {
        final progress = service.calculateProgress(
          category: 'food',
          location: 'San Francisco',
          currentLevel: ExpertiseLevel.local,
          respectedListsCount: 1,
          thoughtfulReviewsCount: 5,
          spotsReviewedCount: 10,
          communityTrustScore: 0.6,
        );

        expect(progress, isA<ExpertiseProgress>());
        expect(progress.category, equals('food'));
        expect(progress.location, equals('San Francisco'));
        expect(progress.currentLevel, equals(ExpertiseLevel.local));
        expect(progress.nextLevel, equals(ExpertiseLevel.city));
        expect(progress.progressPercentage, greaterThanOrEqualTo(0.0));
        expect(progress.progressPercentage, lessThanOrEqualTo(100.0));
        expect(progress.nextSteps, isNotEmpty);
      });

      test('should return 100% progress for highest level', () {
        final progress = service.calculateProgress(
          category: 'food',
          location: null,
          currentLevel: ExpertiseLevel.global,
          respectedListsCount: 25,
          thoughtfulReviewsCount: 250,
          spotsReviewedCount: 100,
          communityTrustScore: 0.9,
        );

        expect(progress.progressPercentage, equals(100.0));
        expect(progress.nextLevel, isNull);
      });

      test('should include contribution breakdown', () {
        final progress = service.calculateProgress(
          category: 'food',
          location: 'San Francisco',
          currentLevel: ExpertiseLevel.local,
          respectedListsCount: 2,
          thoughtfulReviewsCount: 8,
          spotsReviewedCount: 15,
          communityTrustScore: 0.6,
        );

        expect(progress.contributionBreakdown, isA<Map<String, int>>());
        expect(progress.contributionBreakdown['lists'], equals(2));
        expect(progress.contributionBreakdown['reviews'], equals(8));
        expect(progress.contributionBreakdown['spots'], equals(15));
      });
    });

    group('canEarnPin', () {
      test('should return true for minimum contributions and trust', () {
        final canEarn = service.canEarnPin(
          category: 'food',
          respectedListsCount: 1,
          thoughtfulReviewsCount: 0,
          communityTrustScore: 0.5,
        );

        expect(canEarn, isTrue);
      });

      test('should return true for 10+ reviews and trust', () {
        final canEarn = service.canEarnPin(
          category: 'food',
          respectedListsCount: 0,
          thoughtfulReviewsCount: 10,
          communityTrustScore: 0.5,
        );

        expect(canEarn, isTrue);
      });

      test('should return false for insufficient contributions', () {
        final canEarn = service.canEarnPin(
          category: 'food',
          respectedListsCount: 0,
          thoughtfulReviewsCount: 5,
          communityTrustScore: 0.5,
        );

        expect(canEarn, isFalse);
      });

      test('should return false for low trust', () {
        final canEarn = service.canEarnPin(
          category: 'food',
          respectedListsCount: 1,
          thoughtfulReviewsCount: 0,
          communityTrustScore: 0.3,
        );

        expect(canEarn, isFalse);
      });
    });

    group('getExpertiseStory', () {
      test('should generate story with lists and reviews', () {
        final story = service.getExpertiseStory(
          category: 'food',
          level: ExpertiseLevel.city,
          respectedListsCount: 3,
          thoughtfulReviewsCount: 10,
          location: 'San Francisco',
        );

        expect(story, isA<String>());
        expect(story, contains('food'));
        expect(story, contains('City'));
        expect(story, contains('San Francisco'));
        expect(story, contains('3'));
        expect(story, contains('10'));
      });

      test('should generate story with only lists', () {
        final story = service.getExpertiseStory(
          category: 'food',
          level: ExpertiseLevel.local,
          respectedListsCount: 1,
          thoughtfulReviewsCount: 0,
        );

        expect(story, contains('lists'));
        expect(story, isNot(contains('reviews')));
      });

      test('should generate story with only reviews', () {
        final story = service.getExpertiseStory(
          category: 'food',
          level: ExpertiseLevel.local,
          respectedListsCount: 0,
          thoughtfulReviewsCount: 10,
        );

        expect(story, contains('reviews'));
        expect(story, isNot(contains('lists')));
      });
    });

    group('getUnlockedFeatures', () {
      test('should return features for local level', () {
        final features = service.getUnlockedFeatures(ExpertiseLevel.local);
        expect(features, contains('event_hosting'));
      });

      test('should return features for city level', () {
        final features = service.getUnlockedFeatures(ExpertiseLevel.city);
        expect(features, contains('event_hosting')); // City level also unlocks event hosting
      });

      test('should return features for regional level', () {
        final features = service.getUnlockedFeatures(ExpertiseLevel.regional);
        expect(features, contains('event_hosting'));
        expect(features, contains('expert_validation'));
      });

      test('should return features for national level', () {
        final features = service.getUnlockedFeatures(ExpertiseLevel.national);
        expect(features, contains('event_hosting'));
        expect(features, contains('expert_validation'));
        expect(features, contains('expert_curation'));
      });

      test('should return features for global level', () {
        final features = service.getUnlockedFeatures(ExpertiseLevel.global);
        expect(features, contains('event_hosting'));
        expect(features, contains('expert_validation'));
        expect(features, contains('expert_curation'));
        expect(features, contains('community_leadership'));
      });

      test('should return empty list for local level', () {
        final features = service.getUnlockedFeatures(ExpertiseLevel.local);
        expect(features, isEmpty);
      });
    });
  });
}

