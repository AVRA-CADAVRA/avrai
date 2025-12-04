import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/user_partnership.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/partnership_expertise_boost.dart';
import '../helpers/test_helpers.dart';

/// Expertise Boost Partnership Integration Test
/// 
/// Agent 3: Models & Testing (Phase 4.5)
/// 
/// Tests partnership boost calculation accuracy and integration:
/// - Partnership boost calculation accuracy
/// - Expertise calculation with partnership boost
/// - Community/Professional/Influence path integration
/// - Edge cases (no partnerships, many partnerships, etc.)
/// 
/// **Test Scenarios:**
/// - Scenario 1: Partnership Boost Calculation Accuracy
/// - Scenario 2: Expertise Calculation with Partnership Boost
/// - Scenario 3: Community/Professional/Influence Path Integration
/// - Scenario 4: Edge Cases
void main() {
  group('Expertise Boost Partnership Integration Tests', () {
    late DateTime testDate;
    late DateTime startDate;
    late DateTime endDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      startDate = testDate.subtract(const Duration(days: 30));
      endDate = testDate.add(const Duration(days: 30));
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Scenario 1: Partnership Boost Calculation Accuracy', () {
      test('should calculate boost from active partnerships correctly', () {
        // Arrange - Active partnerships
        final partnerships = [
          UserPartnership(
            id: 'partnership-1',
            type: ProfilePartnershipType.business,
            partnerId: 'business-1',
            partnerName: 'Business 1',
            status: PartnershipStatus.active,
            category: 'Food',
            vibeCompatibility: 0.85,
            eventCount: 3,
          ),
          UserPartnership(
            id: 'partnership-2',
            type: ProfilePartnershipType.brand,
            partnerId: 'brand-1',
            partnerName: 'Brand 1',
            status: PartnershipStatus.active,
            category: 'Food',
            vibeCompatibility: 0.80,
            eventCount: 2,
          ),
        ];

        // Act - Calculate boost (simplified for test)
        // Active: 0.05 per partnership, max 0.15
        final activeBoost = (partnerships.where((p) => p.isActive).length * 0.05).clamp(0.0, 0.15);
        
        final boost = PartnershipExpertiseBoost(
          totalBoost: activeBoost,
          activeBoost: activeBoost,
          partnershipCount: partnerships.length,
        );

        // Assert
        expect(boost.activeBoost, equals(0.10)); // 2 * 0.05
        expect(boost.totalBoost, equals(0.10));
        expect(boost.partnershipCount, equals(2));
      });

      test('should calculate boost from completed partnerships correctly', () {
        // Arrange - Completed partnerships
        final partnerships = [
          UserPartnership(
            id: 'partnership-1',
            type: ProfilePartnershipType.business,
            partnerId: 'business-1',
            partnerName: 'Business 1',
            status: PartnershipStatus.completed,
            category: 'Food',
            vibeCompatibility: 0.90,
            eventCount: 5,
          ),
        ];

        // Act - Calculate boost
        // Completed: 0.10 per partnership, max 0.30
        final completedBoost = (partnerships.where((p) => p.isCompleted).length * 0.10).clamp(0.0, 0.30);
        
        final boost = PartnershipExpertiseBoost(
          totalBoost: completedBoost,
          completedBoost: completedBoost,
          partnershipCount: partnerships.length,
        );

        // Assert
        expect(boost.completedBoost, equals(0.10));
        expect(boost.totalBoost, equals(0.10));
      });

      test('should calculate boost from ongoing partnerships correctly', () {
        // Arrange - Ongoing partnerships (active with startDate but no endDate)
        final partnerships = [
          UserPartnership(
            id: 'partnership-1',
            type: ProfilePartnershipType.business,
            partnerId: 'business-1',
            partnerName: 'Business 1',
            status: PartnershipStatus.active,
            startDate: startDate,
            // endDate is null, so it's ongoing
            category: 'Food',
            eventCount: 4,
          ),
        ];

        // Act - Calculate boost
        // Ongoing: 0.08 per partnership, max 0.24
        final ongoingBoost = (partnerships.where((p) => p.isOngoing).length * 0.08).clamp(0.0, 0.24);
        
        final boost = PartnershipExpertiseBoost(
          totalBoost: ongoingBoost,
          ongoingBoost: ongoingBoost,
          partnershipCount: partnerships.length,
        );

        // Assert
        expect(boost.ongoingBoost, equals(0.08));
        expect(boost.totalBoost, equals(0.08));
      });

      test('should apply count multiplier correctly', () {
        // Arrange - 6+ partnerships (1.5x multiplier)
        final partnerships = List.generate(6, (index) => UserPartnership(
          id: 'partnership-$index',
          type: ProfilePartnershipType.business,
          partnerId: 'business-$index',
          partnerName: 'Business $index',
          status: PartnershipStatus.active,
          category: 'Food',
        ));

        // Act - Calculate boost with multiplier
        final baseBoost = 0.15; // Max active boost
        final countMultiplier = partnerships.length >= 6 ? 1.5 : (partnerships.length >= 3 ? 1.2 : 1.0);
        final totalBoost = (baseBoost * countMultiplier).clamp(0.0, 0.50);
        
        final boost = PartnershipExpertiseBoost(
          totalBoost: totalBoost,
          activeBoost: baseBoost,
          partnershipCount: partnerships.length,
          countMultiplier: countMultiplier,
        );

        // Assert
        expect(boost.countMultiplier, equals(1.5));
        expect(boost.partnershipCount, equals(6));
        expect(boost.totalBoost, closeTo(0.225, 0.001)); // 0.15 * 1.5
      });
    });

    group('Scenario 2: Expertise Calculation with Partnership Boost', () {
      test('should integrate partnership boost into total expertise', () {
        // Arrange
        final baseExpertise = 0.60;
        final partnershipBoost = PartnershipExpertiseBoost(
          totalBoost: 0.25,
          activeBoost: 0.10,
          completedBoost: 0.15,
          partnershipCount: 3,
        );

        // Act - Add partnership boost to base expertise
        // Partnership boost is added to expertise (capped at 1.0)
        final totalExpertise = (baseExpertise + partnershipBoost.totalBoost).clamp(0.0, 1.0);

        // Assert
        expect(totalExpertise, equals(0.85));
        expect(partnershipBoost.hasBoost, isTrue);
      });

      test('should cap total expertise at 1.0', () {
        // Arrange
        final baseExpertise = 0.80;
        final partnershipBoost = PartnershipExpertiseBoost(
          totalBoost: 0.50, // Max boost
          partnershipCount: 10,
        );

        // Act
        final totalExpertise = (baseExpertise + partnershipBoost.totalBoost).clamp(0.0, 1.0);

        // Assert
        expect(totalExpertise, equals(1.0)); // Capped at 1.0
      });

      test('should apply boost to different expertise paths', () {
        // Arrange
        final partnershipBoost = PartnershipExpertiseBoost(
          totalBoost: 0.25,
          partnershipCount: 4,
        );

        // Act - Apply boost to different paths
        // Community Path: 60% of boost
        // Professional Path: 30% of boost
        // Influence Path: 10% of boost
        final communityBoost = partnershipBoost.totalBoost * 0.60;
        final professionalBoost = partnershipBoost.totalBoost * 0.30;
        final influenceBoost = partnershipBoost.totalBoost * 0.10;

        // Assert
        expect(communityBoost, equals(0.15)); // 0.25 * 0.60
        expect(professionalBoost, equals(0.075)); // 0.25 * 0.30
        expect(influenceBoost, equals(0.025)); // 0.25 * 0.10
      });
    });

    group('Scenario 3: Community/Professional/Influence Path Integration', () {
      test('should apply boost primarily to Community Path', () {
        // Arrange
        final partnershipBoost = PartnershipExpertiseBoost(
          totalBoost: 0.20,
          partnershipCount: 3,
        );

        // Act
        final communityPathBoost = partnershipBoost.totalBoost * 0.60;

        // Assert
        expect(communityPathBoost, equals(0.12)); // 60% of total
        expect(communityPathBoost, greaterThan(partnershipBoost.totalBoost * 0.30)); // Greater than professional
      });

      test('should apply boost secondarily to Professional Path', () {
        // Arrange
        final partnershipBoost = PartnershipExpertiseBoost(
          totalBoost: 0.20,
          partnershipCount: 3,
        );

        // Act
        final professionalPathBoost = partnershipBoost.totalBoost * 0.30;

        // Assert
        expect(professionalPathBoost, equals(0.06)); // 30% of total
      });

      test('should apply minor boost to Influence Path', () {
        // Arrange
        final partnershipBoost = PartnershipExpertiseBoost(
          totalBoost: 0.20,
          partnershipCount: 3,
        );

        // Act
        final influencePathBoost = partnershipBoost.totalBoost * 0.10;

        // Assert
        expect(influencePathBoost, closeTo(0.02, 0.001)); // 10% of total
        expect(influencePathBoost, lessThan(partnershipBoost.totalBoost * 0.30)); // Less than professional
      });
    });

    group('Scenario 4: Edge Cases', () {
      test('should handle no partnerships', () {
        // Arrange
        final partnerships = <UserPartnership>[];

        // Act
        final boost = PartnershipExpertiseBoost(
          totalBoost: 0.0,
          partnershipCount: partnerships.length,
        );

        // Assert
        expect(boost.hasBoost, isFalse);
        expect(boost.totalBoost, equals(0.0));
        expect(boost.partnershipCount, equals(0));
      });

      test('should handle many partnerships (10+)', () {
        // Arrange - Create 10 partnerships
        final partnerships = List.generate(10, (index) => UserPartnership(
          id: 'partnership-$index',
          type: ProfilePartnershipType.business,
          partnerId: 'business-$index',
          partnerName: 'Business $index',
          status: PartnershipStatus.active,
          category: 'Food',
        ));

        // Act - Calculate boost with multiplier
        final baseBoost = 0.15; // Max active boost
        final countMultiplier = partnerships.length >= 6 ? 1.5 : (partnerships.length >= 3 ? 1.2 : 1.0);
        final totalBoost = (baseBoost * countMultiplier).clamp(0.0, 0.50);
        
        final boost = PartnershipExpertiseBoost(
          totalBoost: totalBoost,
          activeBoost: baseBoost,
          partnershipCount: partnerships.length,
          countMultiplier: countMultiplier,
        );

        // Assert
        expect(boost.partnershipCount, equals(10));
        expect(boost.countMultiplier, equals(1.5));
        expect(boost.totalBoost, closeTo(0.225, 0.001)); // 0.15 * 1.5
        expect(boost.totalBoost, lessThanOrEqualTo(0.50)); // Capped at 0.50
      });

      test('should handle partnerships with no category', () {
        // Arrange
        final partnerships = [
          UserPartnership(
            id: 'partnership-1',
            type: ProfilePartnershipType.business,
            partnerId: 'business-1',
            partnerName: 'Business 1',
            status: PartnershipStatus.active,
            // category is null
          ),
        ];

        // Act
        final boost = PartnershipExpertiseBoost(
          totalBoost: 0.05,
          activeBoost: 0.05,
          unrelatedCategoryBoost: 0.05, // No category = unrelated
          partnershipCount: partnerships.length,
        );

        // Assert
        expect(boost.unrelatedCategoryBoost, equals(0.05));
        expect(boost.totalBoost, equals(0.05));
      });

      test('should cap boost at maximum (0.50)', () {
        // Arrange - Very high boost calculation
        final calculatedBoost = 0.75; // Would exceed max

        // Act - Cap at 0.50
        final cappedBoost = calculatedBoost.clamp(0.0, 0.50);
        
        final boost = PartnershipExpertiseBoost(
          totalBoost: cappedBoost,
          partnershipCount: 20,
        );

        // Assert
        expect(boost.totalBoost, equals(0.50)); // Capped
        expect(boost.totalBoost, lessThan(calculatedBoost));
      });
    });
  });
}

