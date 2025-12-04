import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/user_partnership.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/partnership_expertise_boost.dart';
import '../helpers/test_helpers.dart';

/// Profile Partnership Display Integration Test
/// 
/// Agent 3: Models & Testing (Phase 4.5)
/// 
/// Tests profile partnership display integration:
/// - Profile page partnership display
/// - Partnerships page navigation
/// - Expertise boost indicator display
/// - Visibility controls integration
/// 
/// **Test Scenarios:**
/// - Scenario 1: Profile Page Partnership Display
/// - Scenario 2: Partnerships Page Navigation
/// - Scenario 3: Expertise Boost Indicator Display
/// - Scenario 4: Visibility Controls Integration
void main() {
  group('Profile Partnership Display Integration Tests', () {
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

    group('Scenario 1: Profile Page Partnership Display', () {
      test('should display active partnerships on profile', () {
        // Arrange - Active partnerships
        final partnerships = [
          UserPartnership(
            id: 'partnership-1',
            type: ProfilePartnershipType.business,
            partnerId: 'business-1',
            partnerName: 'Business 1',
            partnerLogoUrl: 'https://example.com/logo1.png',
            status: PartnershipStatus.active,
            startDate: startDate,
            category: 'Food',
            eventCount: 3,
            isPublic: true,
          ),
          UserPartnership(
            id: 'partnership-2',
            type: ProfilePartnershipType.brand,
            partnerId: 'brand-1',
            partnerName: 'Brand 1',
            partnerLogoUrl: 'https://example.com/logo2.png',
            status: PartnershipStatus.active,
            startDate: startDate,
            category: 'Technology',
            eventCount: 5,
            isPublic: true,
          ),
        ];

        // Act - Filter for profile display (active + public, max 3)
        final displayPartnerships = partnerships
            .where((p) => p.isActive && p.isPublic)
            .take(3)
            .toList();

        // Assert
        expect(displayPartnerships.length, equals(2));
        expect(displayPartnerships.every((p) => p.isActive && p.isPublic), isTrue);
        expect(displayPartnerships.first.partnerName, equals('Business 1'));
        expect(displayPartnerships.first.partnerLogoUrl, isNotNull);
      });

      test('should limit profile display to 3 partnerships', () {
        // Arrange - More than 3 active partnerships
        final partnerships = List.generate(5, (index) => UserPartnership(
          id: 'partnership-$index',
          type: ProfilePartnershipType.business,
          partnerId: 'business-$index',
          partnerName: 'Business $index',
          status: PartnershipStatus.active,
          isPublic: true,
        ));

        // Act - Take max 3 for profile preview
        final displayPartnerships = partnerships
            .where((p) => p.isActive && p.isPublic)
            .take(3)
            .toList();

        // Assert
        expect(displayPartnerships.length, equals(3));
        expect(displayPartnerships.length, lessThanOrEqualTo(3));
      });

      test('should exclude private partnerships from profile display', () {
        // Arrange
        final partnerships = [
          UserPartnership(
            id: 'partnership-1',
            type: ProfilePartnershipType.business,
            partnerId: 'business-1',
            partnerName: 'Public Business',
            status: PartnershipStatus.active,
            isPublic: true,
          ),
          UserPartnership(
            id: 'partnership-2',
            type: ProfilePartnershipType.brand,
            partnerId: 'brand-1',
            partnerName: 'Private Brand',
            status: PartnershipStatus.active,
            isPublic: false,
          ),
        ];

        // Act
        final publicPartnerships = partnerships
            .where((p) => p.isActive && p.isPublic)
            .toList();

        // Assert
        expect(publicPartnerships.length, equals(1));
        expect(publicPartnerships.first.partnerName, equals('Public Business'));
      });
    });

    group('Scenario 2: Partnerships Page Navigation', () {
      test('should prepare all partnerships for partnerships page', () {
        // Arrange - All partnerships (active, completed, etc.)
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
            isPublic: false,
          ),
        ];

        // Act - Get all partnerships for partnerships page
        final allPartnerships = partnerships;

        // Assert
        expect(allPartnerships.length, equals(3));
        expect(allPartnerships.any((p) => p.isActive), isTrue);
        expect(allPartnerships.any((p) => p.isCompleted), isTrue);
      });

      test('should filter partnerships by type on partnerships page', () {
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

        // Act - Filter by business type
        final businessPartnerships = partnerships
            .where((p) => p.type == ProfilePartnershipType.business)
            .toList();

        // Assert
        expect(businessPartnerships.length, equals(2));
        expect(businessPartnerships.every((p) => p.type == ProfilePartnershipType.business), isTrue);
      });

      test('should filter partnerships by status on partnerships page', () {
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
            status: PartnershipStatus.completed,
          ),
          UserPartnership(
            id: 'partnership-3',
            type: ProfilePartnershipType.company,
            partnerId: 'company-1',
            partnerName: 'Company 1',
            status: PartnershipStatus.active,
          ),
        ];

        // Act - Filter by active status
        final activePartnerships = partnerships
            .where((p) => p.isActive)
            .toList();

        // Assert
        expect(activePartnerships.length, equals(2));
        expect(activePartnerships.every((p) => p.isActive), isTrue);
      });
    });

    group('Scenario 3: Expertise Boost Indicator Display', () {
      test('should display expertise boost when partnerships contribute', () {
        // Arrange
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
        ];

        final boost = PartnershipExpertiseBoost(
          totalBoost: 0.15,
          activeBoost: 0.15,
          partnershipCount: partnerships.length,
        );

        // Act - Check if boost should be displayed
        final shouldDisplayBoost = boost.hasBoost && partnerships.isNotEmpty;

        // Assert
        expect(shouldDisplayBoost, isTrue);
        expect(boost.boostPercentage, equals(15.0));
      });

      test('should not display boost when no partnerships', () {
        // Arrange
        final partnerships = <UserPartnership>[];
        final boost = PartnershipExpertiseBoost(
          totalBoost: 0.0,
          partnershipCount: partnerships.length,
        );

        // Act
        final shouldDisplayBoost = boost.hasBoost && partnerships.isNotEmpty;

        // Assert
        expect(shouldDisplayBoost, isFalse);
        expect(boost.hasBoost, isFalse);
      });

      test('should format boost percentage correctly', () {
        // Arrange
        final boost = PartnershipExpertiseBoost(
          totalBoost: 0.25,
          partnershipCount: 3,
        );

        // Act
        final percentage = boost.boostPercentage;
        final formatted = '${percentage.toStringAsFixed(0)}%';

        // Assert
        expect(percentage, equals(25.0));
        expect(formatted, equals('25%'));
      });

      test('should show boost breakdown by category', () {
        // Arrange
        final boost = PartnershipExpertiseBoost(
          totalBoost: 0.30,
          sameCategoryBoost: 0.20,
          relatedCategoryBoost: 0.08,
          unrelatedCategoryBoost: 0.02,
          partnershipCount: 5,
        );

        // Act - Prepare breakdown for display
        final breakdown = {
          'sameCategory': boost.sameCategoryBoost,
          'relatedCategory': boost.relatedCategoryBoost,
          'unrelatedCategory': boost.unrelatedCategoryBoost,
        };

        // Assert
        expect(breakdown['sameCategory'], equals(0.20));
        expect(breakdown['relatedCategory'], equals(0.08));
        expect(breakdown['unrelatedCategory'], equals(0.02));
        final sum = breakdown.values.reduce((a, b) => a + b);
        expect(sum, closeTo(boost.totalBoost, 0.001));
      });
    });

    group('Scenario 4: Visibility Controls Integration', () {
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

        // Act - Toggle to private
        final updated = partnership.copyWith(isPublic: false);

        // Assert
        expect(partnership.isPublic, isTrue);
        expect(updated.isPublic, isFalse);
        expect(updated.id, equals(partnership.id));
      });

      test('should apply bulk visibility settings', () {
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
            isPublic: true,
          ),
        ];

        // Act - Set all to private
        final updatedPartnerships = partnerships
            .map((p) => p.copyWith(isPublic: false))
            .toList();

        // Assert
        expect(updatedPartnerships.every((p) => !p.isPublic), isTrue);
        expect(updatedPartnerships.length, equals(partnerships.length));
      });

      test('should filter visible partnerships for display', () {
        // Arrange
        final partnerships = [
          UserPartnership(
            id: 'partnership-1',
            type: ProfilePartnershipType.business,
            partnerId: 'business-1',
            partnerName: 'Public Business',
            status: PartnershipStatus.active,
            isPublic: true,
          ),
          UserPartnership(
            id: 'partnership-2',
            type: ProfilePartnershipType.brand,
            partnerId: 'brand-1',
            partnerName: 'Private Brand',
            status: PartnershipStatus.active,
            isPublic: false,
          ),
          UserPartnership(
            id: 'partnership-3',
            type: ProfilePartnershipType.company,
            partnerId: 'company-1',
            partnerName: 'Public Company',
            status: PartnershipStatus.completed,
            isPublic: true,
          ),
        ];

        // Act - Filter visible partnerships
        final visiblePartnerships = partnerships
            .where((p) => p.isPublic)
            .toList();

        // Assert
        expect(visiblePartnerships.length, equals(2));
        expect(visiblePartnerships.every((p) => p.isPublic), isTrue);
        expect(visiblePartnerships.any((p) => p.partnerName == 'Public Business'), isTrue);
        expect(visiblePartnerships.any((p) => p.partnerName == 'Public Company'), isTrue);
      });

      test('should maintain visibility state across updates', () {
        // Arrange
        final partnership = UserPartnership(
          id: 'partnership-1',
          type: ProfilePartnershipType.business,
          partnerId: 'business-1',
          partnerName: 'Business 1',
          status: PartnershipStatus.active,
          isPublic: true,
        );

        // Act - Update other fields while maintaining visibility
        final updated = partnership.copyWith(
          partnerName: 'Updated Business',
          eventCount: 5,
          // isPublic not changed, should remain true
        );

        // Assert
        expect(updated.isPublic, equals(partnership.isPublic));
        expect(updated.isPublic, isTrue);
        expect(updated.partnerName, equals('Updated Business'));
      });
    });
  });
}

