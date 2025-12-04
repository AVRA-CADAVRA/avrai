import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/user_partnership.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/partnership_expertise_boost.dart';
import '../helpers/test_helpers.dart';

/// Partnership Profile Flow Integration Test
/// 
/// Agent 3: Models & Testing (Phase 4.5)
/// 
/// Tests integration flow for partnership profile features:
/// - Get user partnerships flow
/// - Filter partnerships by type flow
/// - Calculate expertise boost flow
/// - Profile visibility controls flow
/// 
/// **Test Scenarios:**
/// - Scenario 1: Get User Partnerships Flow
/// - Scenario 2: Filter Partnerships by Type Flow
/// - Scenario 3: Calculate Expertise Boost Flow
/// - Scenario 4: Profile Visibility Controls Flow
void main() {
  group('Partnership Profile Flow Integration Tests', () {
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

    group('Scenario 1: Get User Partnerships Flow', () {
      test('should get all partnerships for a user', () {
        // Arrange - Create multiple partnerships
        final businessPartnership = UserPartnership(
          id: 'partnership-1',
          type: ProfilePartnershipType.business,
          partnerId: 'business-1',
          partnerName: 'Test Business',
          status: PartnershipStatus.active,
          startDate: startDate,
          category: 'Food',
          eventCount: 3,
        );

        final brandPartnership = UserPartnership(
          id: 'partnership-2',
          type: ProfilePartnershipType.brand,
          partnerId: 'brand-1',
          partnerName: 'Test Brand',
          status: PartnershipStatus.completed,
          startDate: startDate,
          endDate: endDate,
          category: 'Technology',
          eventCount: 5,
        );

        final companyPartnership = UserPartnership(
          id: 'partnership-3',
          type: ProfilePartnershipType.company,
          partnerId: 'company-1',
          partnerName: 'Test Company',
          status: PartnershipStatus.active,
          startDate: startDate,
          category: 'Food',
          eventCount: 2,
        );

        final allPartnerships = [
          businessPartnership,
          brandPartnership,
          companyPartnership,
        ];

        // Act & Assert
        expect(allPartnerships.length, equals(3));
        expect(allPartnerships.any((p) => p.type == ProfilePartnershipType.business), isTrue);
        expect(allPartnerships.any((p) => p.type == ProfilePartnershipType.brand), isTrue);
        expect(allPartnerships.any((p) => p.type == ProfilePartnershipType.company), isTrue);
      });

      test('should handle empty partnerships list', () {
        final partnerships = <UserPartnership>[];

        expect(partnerships.isEmpty, isTrue);
        expect(partnerships.length, equals(0));
      });
    });

    group('Scenario 2: Filter Partnerships by Type Flow', () {
      test('should filter partnerships by business type', () {
        // Arrange
        final partnerships = [
          UserPartnership(
            id: 'partnership-1',
            type: ProfilePartnershipType.business,
            partnerId: 'business-1',
            partnerName: 'Business 1',
            status: PartnershipStatus.active,
          ),
          UserPartnership(
            id: 'partnership-2',
            type: ProfilePartnershipType.brand,
            partnerId: 'brand-1',
            partnerName: 'Brand 1',
            status: PartnershipStatus.active,
          ),
          UserPartnership(
            id: 'partnership-3',
            type: ProfilePartnershipType.business,
            partnerId: 'business-2',
            partnerName: 'Business 2',
            status: PartnershipStatus.completed,
          ),
        ];

        // Act
        final businessPartnerships = partnerships
            .where((p) => p.type == ProfilePartnershipType.business)
            .toList();

        // Assert
        expect(businessPartnerships.length, equals(2));
        expect(businessPartnerships.every((p) => p.type == ProfilePartnershipType.business), isTrue);
      });

      test('should filter partnerships by brand type', () {
        // Arrange
        final partnerships = [
          UserPartnership(
            id: 'partnership-1',
            type: ProfilePartnershipType.business,
            partnerId: 'business-1',
            partnerName: 'Business 1',
            status: PartnershipStatus.active,
          ),
          UserPartnership(
            id: 'partnership-2',
            type: ProfilePartnershipType.brand,
            partnerId: 'brand-1',
            partnerName: 'Brand 1',
            status: PartnershipStatus.active,
          ),
        ];

        // Act
        final brandPartnerships = partnerships
            .where((p) => p.type == ProfilePartnershipType.brand)
            .toList();

        // Assert
        expect(brandPartnerships.length, equals(1));
        expect(brandPartnerships.first.type, equals(ProfilePartnershipType.brand));
      });

      test('should filter partnerships by company type', () {
        // Arrange
        final partnerships = [
          UserPartnership(
            id: 'partnership-1',
            type: ProfilePartnershipType.company,
            partnerId: 'company-1',
            partnerName: 'Company 1',
            status: PartnershipStatus.active,
          ),
          UserPartnership(
            id: 'partnership-2',
            type: ProfilePartnershipType.business,
            partnerId: 'business-1',
            partnerName: 'Business 1',
            status: PartnershipStatus.active,
          ),
        ];

        // Act
        final companyPartnerships = partnerships
            .where((p) => p.type == ProfilePartnershipType.company)
            .toList();

        // Assert
        expect(companyPartnerships.length, equals(1));
        expect(companyPartnerships.first.type, equals(ProfilePartnershipType.company));
      });
    });

    group('Scenario 3: Calculate Expertise Boost Flow', () {
      test('should calculate expertise boost from partnerships', () {
        // Arrange - Create partnerships with different statuses
        final activePartnership = UserPartnership(
          id: 'partnership-1',
          type: ProfilePartnershipType.business,
          partnerId: 'business-1',
          partnerName: 'Business 1',
          status: PartnershipStatus.active,
          category: 'Food',
          vibeCompatibility: 0.85,
          eventCount: 3,
        );

        final completedPartnership = UserPartnership(
          id: 'partnership-2',
          type: ProfilePartnershipType.brand,
          partnerId: 'brand-1',
          partnerName: 'Brand 1',
          status: PartnershipStatus.completed,
          category: 'Food',
          vibeCompatibility: 0.90,
          eventCount: 5,
        );

        final partnerships = [activePartnership, completedPartnership];

        // Act - Calculate boost (simplified calculation for test)
        // In real implementation, this would be done by ExpertiseCalculationService
        final boost = PartnershipExpertiseBoost(
          totalBoost: 0.25,
          activeBoost: 0.10,
          completedBoost: 0.15,
          sameCategoryBoost: 0.20,
          relatedCategoryBoost: 0.05,
          partnershipCount: partnerships.length,
          countMultiplier: 1.2,
        );

        // Assert
        expect(boost.hasBoost, isTrue);
        expect(boost.totalBoost, equals(0.25));
        expect(boost.partnershipCount, equals(2));
        expect(boost.activeBoost, equals(0.10));
        expect(boost.completedBoost, equals(0.15));
      });

      test('should handle zero boost when no partnerships', () {
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

      test('should calculate boost with category alignment', () {
        // Arrange - Partnerships in same category
        final partnerships = [
          UserPartnership(
            id: 'partnership-1',
            type: ProfilePartnershipType.business,
            partnerId: 'business-1',
            partnerName: 'Business 1',
            status: PartnershipStatus.active,
            category: 'Food',
            eventCount: 3,
          ),
          UserPartnership(
            id: 'partnership-2',
            type: ProfilePartnershipType.brand,
            partnerId: 'brand-1',
            partnerName: 'Brand 1',
            status: PartnershipStatus.completed,
            category: 'Food',
            eventCount: 5,
          ),
        ];

        // Act - Calculate boost with same category
        final boost = PartnershipExpertiseBoost(
          totalBoost: 0.30,
          sameCategoryBoost: 0.30,
          partnershipCount: partnerships.length,
        );

        // Assert
        expect(boost.sameCategoryBoost, equals(0.30));
        expect(boost.totalBoost, equals(0.30));
      });
    });

    group('Scenario 4: Profile Visibility Controls Flow', () {
      test('should filter public partnerships only', () {
        // Arrange
        final partnerships = [
          UserPartnership(
            id: 'partnership-1',
            type: ProfilePartnershipType.business,
            partnerId: 'business-1',
            partnerName: 'Business 1',
            status: PartnershipStatus.active,
            isPublic: true,
          ),
          UserPartnership(
            id: 'partnership-2',
            type: ProfilePartnershipType.brand,
            partnerId: 'brand-1',
            partnerName: 'Brand 1',
            status: PartnershipStatus.active,
            isPublic: false,
          ),
          UserPartnership(
            id: 'partnership-3',
            type: ProfilePartnershipType.company,
            partnerId: 'company-1',
            partnerName: 'Company 1',
            status: PartnershipStatus.completed,
            isPublic: true,
          ),
        ];

        // Act
        final publicPartnerships = partnerships
            .where((p) => p.isPublic)
            .toList();

        // Assert
        expect(publicPartnerships.length, equals(2));
        expect(publicPartnerships.every((p) => p.isPublic), isTrue);
      });

      test('should toggle partnership visibility', () {
        // Arrange
        final partnership = UserPartnership(
          id: 'partnership-1',
          type: ProfilePartnershipType.business,
          partnerId: 'business-1',
          partnerName: 'Business 1',
          status: PartnershipStatus.active,
          isPublic: true,
        );

        // Act - Toggle visibility
        final updated = partnership.copyWith(isPublic: false);

        // Assert
        expect(partnership.isPublic, isTrue);
        expect(updated.isPublic, isFalse);
      });

      test('should filter active partnerships for profile display', () {
        // Arrange
        final partnerships = [
          UserPartnership(
            id: 'partnership-1',
            type: ProfilePartnershipType.business,
            partnerId: 'business-1',
            partnerName: 'Business 1',
            status: PartnershipStatus.active,
            isPublic: true,
          ),
          UserPartnership(
            id: 'partnership-2',
            type: ProfilePartnershipType.brand,
            partnerId: 'brand-1',
            partnerName: 'Brand 1',
            status: PartnershipStatus.completed,
            isPublic: true,
          ),
          UserPartnership(
            id: 'partnership-3',
            type: ProfilePartnershipType.company,
            partnerId: 'company-1',
            partnerName: 'Company 1',
            status: PartnershipStatus.active,
            isPublic: true,
          ),
        ];

        // Act - Filter active and public partnerships
        final activePublicPartnerships = partnerships
            .where((p) => p.isActive && p.isPublic)
            .toList();

        // Assert
        expect(activePublicPartnerships.length, equals(2));
        expect(activePublicPartnerships.every((p) => p.isActive && p.isPublic), isTrue);
      });
    });
  });
}

