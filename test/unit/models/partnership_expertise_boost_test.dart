import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/partnership_expertise_boost.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for PartnershipExpertiseBoost model
/// Tests boost calculation structure, JSON serialization, and business logic
void main() {
  group('PartnershipExpertiseBoost Model Tests', () {
    setUp(() {
      TestHelpers.setupTestEnvironment();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Constructor and Properties', () {
      test('should create boost with required fields', () {
        final boost = PartnershipExpertiseBoost(
          totalBoost: 0.25,
        );

        expect(boost.totalBoost, equals(0.25));
        expect(boost.activeBoost, equals(0.0));
        expect(boost.completedBoost, equals(0.0));
        expect(boost.ongoingBoost, equals(0.0));
        expect(boost.vibeCompatibilityBoost, equals(0.0));
        expect(boost.revenueSuccessBoost, equals(0.0));
        expect(boost.feedbackBoost, equals(0.0));
        expect(boost.sameCategoryBoost, equals(0.0));
        expect(boost.relatedCategoryBoost, equals(0.0));
        expect(boost.unrelatedCategoryBoost, equals(0.0));
        expect(boost.countMultiplier, equals(1.0));
        expect(boost.partnershipCount, equals(0));
      });

      test('should create boost with all fields', () {
        final boost = PartnershipExpertiseBoost(
          totalBoost: 0.35,
          activeBoost: 0.10,
          completedBoost: 0.15,
          ongoingBoost: 0.08,
          vibeCompatibilityBoost: 0.04,
          revenueSuccessBoost: 0.06,
          feedbackBoost: 0.04,
          sameCategoryBoost: 0.20,
          relatedCategoryBoost: 0.10,
          unrelatedCategoryBoost: 0.05,
          countMultiplier: 1.2,
          partnershipCount: 4,
        );

        expect(boost.totalBoost, equals(0.35));
        expect(boost.activeBoost, equals(0.10));
        expect(boost.completedBoost, equals(0.15));
        expect(boost.ongoingBoost, equals(0.08));
        expect(boost.vibeCompatibilityBoost, equals(0.04));
        expect(boost.revenueSuccessBoost, equals(0.06));
        expect(boost.feedbackBoost, equals(0.04));
        expect(boost.sameCategoryBoost, equals(0.20));
        expect(boost.relatedCategoryBoost, equals(0.10));
        expect(boost.unrelatedCategoryBoost, equals(0.05));
        expect(boost.countMultiplier, equals(1.2));
        expect(boost.partnershipCount, equals(4));
      });
    });

    group('Business Logic', () {
      test('should identify when boost is zero', () {
        final boost = PartnershipExpertiseBoost(
          totalBoost: 0.0,
        );

        expect(boost.hasBoost, isFalse);
        expect(boost.boostPercentage, equals(0.0));
      });

      test('should identify when boost exists', () {
        final boost = PartnershipExpertiseBoost(
          totalBoost: 0.25,
        );

        expect(boost.hasBoost, isTrue);
        expect(boost.boostPercentage, equals(25.0));
      });

      test('should calculate boost percentage correctly', () {
        final boost = PartnershipExpertiseBoost(
          totalBoost: 0.35,
        );

        expect(boost.boostPercentage, equals(35.0));
      });

      test('should handle maximum boost (50%)', () {
        final boost = PartnershipExpertiseBoost(
          totalBoost: 0.50,
        );

        expect(boost.boostPercentage, equals(50.0));
        expect(boost.hasBoost, isTrue);
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final boost = PartnershipExpertiseBoost(
          totalBoost: 0.35,
          activeBoost: 0.10,
          completedBoost: 0.15,
          ongoingBoost: 0.08,
          vibeCompatibilityBoost: 0.04,
          revenueSuccessBoost: 0.06,
          feedbackBoost: 0.04,
          sameCategoryBoost: 0.20,
          relatedCategoryBoost: 0.10,
          unrelatedCategoryBoost: 0.05,
          countMultiplier: 1.2,
          partnershipCount: 4,
        );

        final json = boost.toJson();

        expect(json['totalBoost'], equals(0.35));
        expect(json['activeBoost'], equals(0.10));
        expect(json['completedBoost'], equals(0.15));
        expect(json['ongoingBoost'], equals(0.08));
        expect(json['vibeCompatibilityBoost'], equals(0.04));
        expect(json['revenueSuccessBoost'], equals(0.06));
        expect(json['feedbackBoost'], equals(0.04));
        expect(json['sameCategoryBoost'], equals(0.20));
        expect(json['relatedCategoryBoost'], equals(0.10));
        expect(json['unrelatedCategoryBoost'], equals(0.05));
        expect(json['countMultiplier'], equals(1.2));
        expect(json['partnershipCount'], equals(4));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'totalBoost': 0.28,
          'activeBoost': 0.08,
          'completedBoost': 0.12,
          'ongoingBoost': 0.06,
          'vibeCompatibilityBoost': 0.03,
          'revenueSuccessBoost': 0.05,
          'feedbackBoost': 0.03,
          'sameCategoryBoost': 0.15,
          'relatedCategoryBoost': 0.08,
          'unrelatedCategoryBoost': 0.05,
          'countMultiplier': 1.5,
          'partnershipCount': 7,
        };

        final boost = PartnershipExpertiseBoost.fromJson(json);

        expect(boost.totalBoost, equals(0.28));
        expect(boost.activeBoost, equals(0.08));
        expect(boost.completedBoost, equals(0.12));
        expect(boost.ongoingBoost, equals(0.06));
        expect(boost.vibeCompatibilityBoost, equals(0.03));
        expect(boost.revenueSuccessBoost, equals(0.05));
        expect(boost.feedbackBoost, equals(0.03));
        expect(boost.sameCategoryBoost, equals(0.15));
        expect(boost.relatedCategoryBoost, equals(0.08));
        expect(boost.unrelatedCategoryBoost, equals(0.05));
        expect(boost.countMultiplier, equals(1.5));
        expect(boost.partnershipCount, equals(7));
      });

      test('should handle missing optional fields in JSON', () {
        final minimalJson = {
          'totalBoost': 0.15,
        };

        final boost = PartnershipExpertiseBoost.fromJson(minimalJson);

        expect(boost.totalBoost, equals(0.15));
        expect(boost.activeBoost, equals(0.0));
        expect(boost.completedBoost, equals(0.0));
        expect(boost.ongoingBoost, equals(0.0));
        expect(boost.vibeCompatibilityBoost, equals(0.0));
        expect(boost.revenueSuccessBoost, equals(0.0));
        expect(boost.feedbackBoost, equals(0.0));
        expect(boost.sameCategoryBoost, equals(0.0));
        expect(boost.relatedCategoryBoost, equals(0.0));
        expect(boost.unrelatedCategoryBoost, equals(0.0));
        expect(boost.countMultiplier, equals(1.0));
        expect(boost.partnershipCount, equals(0));
      });

      test('should handle null values in JSON gracefully', () {
        final jsonWithNulls = {
          'totalBoost': 0.20,
          'activeBoost': null,
          'completedBoost': null,
          'ongoingBoost': null,
          'vibeCompatibilityBoost': null,
          'revenueSuccessBoost': null,
          'feedbackBoost': null,
          'sameCategoryBoost': null,
          'relatedCategoryBoost': null,
          'unrelatedCategoryBoost': null,
          'countMultiplier': null,
          'partnershipCount': null,
        };

        final boost = PartnershipExpertiseBoost.fromJson(jsonWithNulls);

        expect(boost.totalBoost, equals(0.20));
        expect(boost.activeBoost, equals(0.0));
        expect(boost.completedBoost, equals(0.0));
        expect(boost.countMultiplier, equals(1.0));
        expect(boost.partnershipCount, equals(0));
      });

      test('should handle JSON roundtrip correctly', () {
        final originalBoost = PartnershipExpertiseBoost(
          totalBoost: 0.35,
          activeBoost: 0.10,
          completedBoost: 0.15,
          ongoingBoost: 0.08,
          vibeCompatibilityBoost: 0.04,
          revenueSuccessBoost: 0.06,
          feedbackBoost: 0.04,
          sameCategoryBoost: 0.20,
          relatedCategoryBoost: 0.10,
          unrelatedCategoryBoost: 0.05,
          countMultiplier: 1.2,
          partnershipCount: 4,
        );

        final json = originalBoost.toJson();
        final reconstructed = PartnershipExpertiseBoost.fromJson(json);

        expect(reconstructed, equals(originalBoost));
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final original = PartnershipExpertiseBoost(
          totalBoost: 0.25,
          activeBoost: 0.10,
          partnershipCount: 3,
        );

        final updated = original.copyWith(
          totalBoost: 0.35,
          completedBoost: 0.15,
          partnershipCount: 5,
        );

        expect(updated.totalBoost, equals(0.35));
        expect(updated.activeBoost, equals(0.10)); // Unchanged
        expect(updated.completedBoost, equals(0.15));
        expect(updated.partnershipCount, equals(5));
      });

      test('should create copy without changing original', () {
        final original = PartnershipExpertiseBoost(
          totalBoost: 0.25,
          partnershipCount: 3,
        );

        final copy = original.copyWith(totalBoost: 0.35);

        expect(original.totalBoost, equals(0.25));
        expect(copy.totalBoost, equals(0.35));
      });
    });

    group('Equatable', () {
      test('should be equal when all properties match', () {
        final boost1 = PartnershipExpertiseBoost(
          totalBoost: 0.25,
          activeBoost: 0.10,
          completedBoost: 0.15,
          partnershipCount: 3,
        );

        final boost2 = PartnershipExpertiseBoost(
          totalBoost: 0.25,
          activeBoost: 0.10,
          completedBoost: 0.15,
          partnershipCount: 3,
        );

        expect(boost1, equals(boost2));
      });

      test('should not be equal when properties differ', () {
        final boost1 = PartnershipExpertiseBoost(
          totalBoost: 0.25,
          activeBoost: 0.10,
          partnershipCount: 3,
        );

        final boost2 = PartnershipExpertiseBoost(
          totalBoost: 0.25,
          activeBoost: 0.15, // Different
          partnershipCount: 3,
        );

        expect(boost1, isNot(equals(boost2)));
      });
    });
  });
}

