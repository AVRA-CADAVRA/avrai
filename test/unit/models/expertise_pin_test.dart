import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:spots/core/models/expertise_pin.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/theme/colors.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for ExpertisePin model
/// Tests pin creation, JSON serialization, helper methods, and feature unlocking
void main() {
  group('ExpertisePin Model Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Constructor and Properties', () {
      test('should create pin with required fields', () {
        final pin = ExpertisePin(
          id: 'pin-123',
          userId: 'user-123',
          category: 'Coffee',
          level: ExpertiseLevel.local,
          earnedAt: testDate,
          earnedReason: 'Created 5 respected lists',
        );

        expect(pin.id, equals('pin-123'));
        expect(pin.userId, equals('user-123'));
        expect(pin.category, equals('Coffee'));
        expect(pin.level, equals(ExpertiseLevel.local));
        expect(pin.earnedAt, equals(testDate));
        expect(pin.earnedReason, equals('Created 5 respected lists'));
        
        // Test default values
        expect(pin.location, isNull);
        expect(pin.contributionCount, equals(0));
        expect(pin.communityTrustScore, equals(0.0));
        expect(pin.unlockedFeatures, isEmpty);
      });

      test('should create pin with all fields', () {
        final pin = ExpertisePin(
          id: 'pin-123',
          userId: 'user-123',
          category: 'Coffee',
          level: ExpertiseLevel.city,
          location: 'Brooklyn',
          earnedAt: testDate,
          earnedReason: 'Created 10 respected lists',
          contributionCount: 10,
          communityTrustScore: 0.85,
          unlockedFeatures: ['event_hosting'],
        );

        expect(pin.location, equals('Brooklyn'));
        expect(pin.contributionCount, equals(10));
        expect(pin.communityTrustScore, equals(0.85));
        expect(pin.unlockedFeatures, equals(['event_hosting']));
      });
    });

    group('fromMapEntry Factory', () {
      test('should create pin from map entry with all fields', () {
        final pin = ExpertisePin.fromMapEntry(
          userId: 'user-123',
          category: 'Coffee',
          levelString: 'city',
          location: 'Brooklyn',
          earnedAt: testDate,
          earnedReason: 'Earned through contributions',
        );

        expect(pin.userId, equals('user-123'));
        expect(pin.category, equals('Coffee'));
        expect(pin.level, equals(ExpertiseLevel.city));
        expect(pin.location, equals('Brooklyn'));
        expect(pin.earnedAt, equals(testDate));
        expect(pin.earnedReason, equals('Earned through contributions'));
        expect(pin.id, contains('user-123'));
        expect(pin.id, contains('Coffee'));
        expect(pin.id, contains('city'));
      });

      test('should create pin with default values when optional fields are null', () {
        final pin = ExpertisePin.fromMapEntry(
          userId: 'user-123',
          category: 'Coffee',
          levelString: 'local',
        );

        expect(pin.level, equals(ExpertiseLevel.local));
        expect(pin.location, isNull);
        expect(pin.earnedReason, equals('Earned through community contributions'));
      });

      test('should default to local level for invalid level string', () {
        final pin = ExpertisePin.fromMapEntry(
          userId: 'user-123',
          category: 'Coffee',
          levelString: 'invalid',
        );

        expect(pin.level, equals(ExpertiseLevel.local));
      });
    });

    group('Display Methods', () {
      test('getDisplayTitle should include location when present', () {
        final pin = ExpertisePin(
          id: 'pin-123',
          userId: 'user-123',
          category: 'Coffee',
          level: ExpertiseLevel.city,
          location: 'Brooklyn',
          earnedAt: testDate,
          earnedReason: 'Test',
        );

        expect(pin.getDisplayTitle(), equals('Coffee Expert in Brooklyn'));
      });

      test('getDisplayTitle should exclude location when null', () {
        final pin = ExpertisePin(
          id: 'pin-123',
          userId: 'user-123',
          category: 'Coffee',
          level: ExpertiseLevel.global,
          earnedAt: testDate,
          earnedReason: 'Test',
        );

        expect(pin.getDisplayTitle(), equals('Coffee Expert'));
      });

      test('getFullDescription should include level emoji and location', () {
        final pin = ExpertisePin(
          id: 'pin-123',
          userId: 'user-123',
          category: 'Coffee',
          level: ExpertiseLevel.city,
          location: 'Brooklyn',
          earnedAt: testDate,
          earnedReason: 'Test',
        );

        final description = pin.getFullDescription();
        expect(description, contains('🏙️')); // City emoji
        expect(description, contains('City Level'));
        expect(description, contains('Coffee'));
        expect(description, contains('Brooklyn'));
      });

      test('getFullDescription should exclude location when null', () {
        final pin = ExpertisePin(
          id: 'pin-123',
          userId: 'user-123',
          category: 'Coffee',
          level: ExpertiseLevel.global,
          earnedAt: testDate,
          earnedReason: 'Test',
        );

        final description = pin.getFullDescription();
        expect(description, contains('Coffee'));
        expect(description, isNot(contains('('))); // No location parentheses
      });
    });

    group('Pin Color and Icon', () {
      test('getPinColor should return category-specific colors', () {
        final coffeePin = ExpertisePin(
          id: 'pin-1',
          userId: 'user-123',
          category: 'Coffee',
          level: ExpertiseLevel.local,
          earnedAt: testDate,
          earnedReason: 'Test',
        );
        expect(coffeePin.getPinColor(), equals(AppColors.grey700));

        final restaurantPin = ExpertisePin(
          id: 'pin-2',
          userId: 'user-123',
          category: 'Restaurants',
          level: ExpertiseLevel.local,
          earnedAt: testDate,
          earnedReason: 'Test',
        );
        expect(restaurantPin.getPinColor(), equals(AppColors.error));

        final bookstorePin = ExpertisePin(
          id: 'pin-3',
          userId: 'user-123',
          category: 'Bookstores',
          level: ExpertiseLevel.local,
          earnedAt: testDate,
          earnedReason: 'Test',
        );
        expect(bookstorePin.getPinColor(), equals(AppColors.electricGreen));
      });

      test('getPinColor should return grey for unknown category', () {
        final unknownPin = ExpertisePin(
          id: 'pin-1',
          userId: 'user-123',
          category: 'Unknown Category',
          level: ExpertiseLevel.local,
          earnedAt: testDate,
          earnedReason: 'Test',
        );
        expect(unknownPin.getPinColor(), equals(AppColors.grey500));
      });

      test('getPinIcon should return category-specific icons', () {
        final coffeePin = ExpertisePin(
          id: 'pin-1',
          userId: 'user-123',
          category: 'Coffee',
          level: ExpertiseLevel.local,
          earnedAt: testDate,
          earnedReason: 'Test',
        );
        expect(coffeePin.getPinIcon(), equals(Icons.local_cafe));

        final restaurantPin = ExpertisePin(
          id: 'pin-2',
          userId: 'user-123',
          category: 'Restaurants',
          level: ExpertiseLevel.local,
          earnedAt: testDate,
          earnedReason: 'Test',
        );
        expect(restaurantPin.getPinIcon(), equals(Icons.restaurant));
      });

      test('getPinIcon should return place icon for unknown category', () {
        final unknownPin = ExpertisePin(
          id: 'pin-1',
          userId: 'user-123',
          category: 'Unknown Category',
          level: ExpertiseLevel.local,
          earnedAt: testDate,
          earnedReason: 'Test',
        );
        expect(unknownPin.getPinIcon(), equals(Icons.place));
      });
    });

    group('Feature Unlocking', () {
      test('unlocksEventHosting should return true for local level and above', () {
        // Local level unlocks event hosting
        expect(
          ExpertisePin(
            id: 'pin-local',
            userId: 'user-123',
            category: 'Coffee',
            level: ExpertiseLevel.local,
            earnedAt: testDate,
            earnedReason: 'Test',
          ).unlocksEventHosting(),
          isTrue,
        );

        // City level also unlocks event hosting (expanded scope)
        expect(
          ExpertisePin(
            id: 'pin-1',
            userId: 'user-123',
            category: 'Coffee',
            level: ExpertiseLevel.city,
            earnedAt: testDate,
            earnedReason: 'Test',
          ).unlocksEventHosting(),
          isTrue,
        );

        // Regional level and above also unlock event hosting
        expect(
          ExpertisePin(
            id: 'pin-2',
            userId: 'user-123',
            category: 'Coffee',
            level: ExpertiseLevel.regional,
            earnedAt: testDate,
            earnedReason: 'Test',
          ).unlocksEventHosting(),
          isTrue,
        );
      });

      test('unlocksExpertValidation should return true for regional level and above', () {
        expect(
          ExpertisePin(
            id: 'pin-1',
            userId: 'user-123',
            category: 'Coffee',
            level: ExpertiseLevel.regional,
            earnedAt: testDate,
            earnedReason: 'Test',
          ).unlocksExpertValidation(),
          isTrue,
        );

        expect(
          ExpertisePin(
            id: 'pin-2',
            userId: 'user-123',
            category: 'Coffee',
            level: ExpertiseLevel.national,
            earnedAt: testDate,
            earnedReason: 'Test',
          ).unlocksExpertValidation(),
          isTrue,
        );
      });

      test('unlocksExpertValidation should return false for city level and below', () {
        expect(
          ExpertisePin(
            id: 'pin-1',
            userId: 'user-123',
            category: 'Coffee',
            level: ExpertiseLevel.city,
            earnedAt: testDate,
            earnedReason: 'Test',
          ).unlocksExpertValidation(),
          isFalse,
        );

        expect(
          ExpertisePin(
            id: 'pin-2',
            userId: 'user-123',
            category: 'Coffee',
            level: ExpertiseLevel.local,
            earnedAt: testDate,
            earnedReason: 'Test',
          ).unlocksExpertValidation(),
          isFalse,
        );
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final pin = ExpertisePin(
          id: 'pin-123',
          userId: 'user-123',
          category: 'Coffee',
          level: ExpertiseLevel.city,
          location: 'Brooklyn',
          earnedAt: testDate,
          earnedReason: 'Created 10 lists',
          contributionCount: 10,
          communityTrustScore: 0.85,
          unlockedFeatures: ['event_hosting'],
        );

        final json = pin.toJson();

        expect(json['id'], equals('pin-123'));
        expect(json['userId'], equals('user-123'));
        expect(json['category'], equals('Coffee'));
        expect(json['level'], equals('city'));
        expect(json['location'], equals('Brooklyn'));
        expect(json['earnedAt'], equals(testDate.toIso8601String()));
        expect(json['earnedReason'], equals('Created 10 lists'));
        expect(json['contributionCount'], equals(10));
        expect(json['communityTrustScore'], equals(0.85));
        expect(json['unlockedFeatures'], equals(['event_hosting']));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'pin-123',
          'userId': 'user-123',
          'category': 'Coffee',
          'level': 'city',
          'location': 'Brooklyn',
          'earnedAt': testDate.toIso8601String(),
          'earnedReason': 'Created 10 lists',
          'contributionCount': 10,
          'communityTrustScore': 0.85,
          'unlockedFeatures': ['event_hosting'],
        };

        final pin = ExpertisePin.fromJson(json);

        expect(pin.id, equals('pin-123'));
        expect(pin.userId, equals('user-123'));
        expect(pin.category, equals('Coffee'));
        expect(pin.level, equals(ExpertiseLevel.city));
        expect(pin.location, equals('Brooklyn'));
        expect(pin.earnedAt, equals(testDate));
        expect(pin.earnedReason, equals('Created 10 lists'));
        expect(pin.contributionCount, equals(10));
        expect(pin.communityTrustScore, equals(0.85));
        expect(pin.unlockedFeatures, equals(['event_hosting']));
      });

      test('should handle null optional fields in JSON', () {
        final json = {
          'id': 'pin-123',
          'userId': 'user-123',
          'category': 'Coffee',
          'level': 'local',
          'earnedAt': testDate.toIso8601String(),
          'earnedReason': 'Test',
        };

        final pin = ExpertisePin.fromJson(json);

        expect(pin.location, isNull);
        expect(pin.contributionCount, equals(0));
        expect(pin.communityTrustScore, equals(0.0));
        expect(pin.unlockedFeatures, isEmpty);
      });

      test('should default to local level for invalid level in JSON', () {
        final json = {
          'id': 'pin-123',
          'userId': 'user-123',
          'category': 'Coffee',
          'level': 'invalid',
          'earnedAt': testDate.toIso8601String(),
          'earnedReason': 'Test',
        };

        final pin = ExpertisePin.fromJson(json);

        expect(pin.level, equals(ExpertiseLevel.local));
      });
    });

    group('copyWith', () {
      test('should create copy with modified fields', () {
        final original = ExpertisePin(
          id: 'pin-123',
          userId: 'user-123',
          category: 'Coffee',
          level: ExpertiseLevel.local,
          earnedAt: testDate,
          earnedReason: 'Original reason',
        );

        final updated = original.copyWith(
          level: ExpertiseLevel.city,
          location: 'Brooklyn',
          earnedReason: 'Updated reason',
        );

        expect(updated.id, equals('pin-123')); // Unchanged
        expect(updated.level, equals(ExpertiseLevel.city)); // Changed
        expect(updated.location, equals('Brooklyn')); // Changed
        expect(updated.earnedReason, equals('Updated reason')); // Changed
        expect(updated.category, equals('Coffee')); // Unchanged
      });

      test('should create copy with null fields', () {
        final original = ExpertisePin(
          id: 'pin-123',
          userId: 'user-123',
          category: 'Coffee',
          level: ExpertiseLevel.city,
          location: 'Brooklyn',
          earnedAt: testDate,
          earnedReason: 'Test',
        );

        final updated = original.copyWith(location: null);

        expect(updated.location, isNull);
        expect(updated.category, equals('Coffee')); // Unchanged
      });
    });

    group('Equality', () {
      test('should be equal when all properties match', () {
        final pin1 = ExpertisePin(
          id: 'pin-123',
          userId: 'user-123',
          category: 'Coffee',
          level: ExpertiseLevel.city,
          earnedAt: testDate,
          earnedReason: 'Test',
        );

        final pin2 = ExpertisePin(
          id: 'pin-123',
          userId: 'user-123',
          category: 'Coffee',
          level: ExpertiseLevel.city,
          earnedAt: testDate,
          earnedReason: 'Test',
        );

        expect(pin1, equals(pin2));
      });

      test('should not be equal when properties differ', () {
        final pin1 = ExpertisePin(
          id: 'pin-123',
          userId: 'user-123',
          category: 'Coffee',
          level: ExpertiseLevel.local,
          earnedAt: testDate,
          earnedReason: 'Test',
        );

        final pin2 = ExpertisePin(
          id: 'pin-123',
          userId: 'user-123',
          category: 'Coffee',
          level: ExpertiseLevel.city, // Different level
          earnedAt: testDate,
          earnedReason: 'Test',
        );

        expect(pin1, isNot(equals(pin2)));
      });
    });
  });
}

