import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/user_partnership.dart';
import 'package:spots/core/models/event_partnership.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for UserPartnership model
/// Tests partnership creation, JSON serialization, and business logic
void main() {
  group('UserPartnership Model Tests', () {
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

    group('ProfilePartnershipType Enum', () {
      test('should have correct display names', () {
        expect(ProfilePartnershipType.business.displayName, equals('Business Partnership'));
        expect(ProfilePartnershipType.brand.displayName, equals('Brand Partnership'));
        expect(ProfilePartnershipType.company.displayName, equals('Company Partnership'));
      });

      test('should parse from string correctly', () {
        expect(ProfilePartnershipTypeExtension.fromString('business'), equals(ProfilePartnershipType.business));
        expect(ProfilePartnershipTypeExtension.fromString('brand'), equals(ProfilePartnershipType.brand));
        expect(ProfilePartnershipTypeExtension.fromString('company'), equals(ProfilePartnershipType.company));
        expect(ProfilePartnershipTypeExtension.fromString('unknown'), equals(ProfilePartnershipType.business));
        expect(ProfilePartnershipTypeExtension.fromString(null), equals(ProfilePartnershipType.business));
      });
    });

    group('Constructor and Properties', () {
      test('should create user partnership with required fields', () {
        final partnership = UserPartnership(
          id: 'partnership-123',
          type: ProfilePartnershipType.business,
          partnerId: 'business-123',
          partnerName: 'Test Business',
          status: PartnershipStatus.active,
        );

        expect(partnership.id, equals('partnership-123'));
        expect(partnership.type, equals(ProfilePartnershipType.business));
        expect(partnership.partnerId, equals('business-123'));
        expect(partnership.partnerName, equals('Test Business'));
        expect(partnership.status, equals(PartnershipStatus.active));
        
        // Test default values
        expect(partnership.partnerLogoUrl, isNull);
        expect(partnership.startDate, isNull);
        expect(partnership.endDate, isNull);
        expect(partnership.category, isNull);
        expect(partnership.vibeCompatibility, isNull);
        expect(partnership.eventCount, equals(0));
        expect(partnership.isPublic, isTrue);
      });

      test('should create user partnership with all optional fields', () {
        final partnership = UserPartnership(
          id: 'partnership-123',
          type: ProfilePartnershipType.brand,
          partnerId: 'brand-123',
          partnerName: 'Test Brand',
          partnerLogoUrl: 'https://example.com/logo.png',
          status: PartnershipStatus.completed,
          startDate: startDate,
          endDate: endDate,
          category: 'Food',
          vibeCompatibility: 0.85,
          eventCount: 5,
          isPublic: false,
        );

        expect(partnership.partnerLogoUrl, equals('https://example.com/logo.png'));
        expect(partnership.startDate, equals(startDate));
        expect(partnership.endDate, equals(endDate));
        expect(partnership.category, equals('Food'));
        expect(partnership.vibeCompatibility, equals(0.85));
        expect(partnership.eventCount, equals(5));
        expect(partnership.isPublic, isFalse);
      });
    });

    group('Business Logic', () {
      test('should identify active partnership correctly', () {
        final partnership = UserPartnership(
          id: 'partnership-123',
          type: ProfilePartnershipType.business,
          partnerId: 'business-123',
          partnerName: 'Test Business',
          status: PartnershipStatus.active,
        );

        expect(partnership.isActive, isTrue);
        expect(partnership.isCompleted, isFalse);
        expect(partnership.isOngoing, isFalse);
      });

      test('should identify completed partnership correctly', () {
        final partnership = UserPartnership(
          id: 'partnership-123',
          type: ProfilePartnershipType.business,
          partnerId: 'business-123',
          partnerName: 'Test Business',
          status: PartnershipStatus.completed,
        );

        expect(partnership.isActive, isFalse);
        expect(partnership.isCompleted, isTrue);
        expect(partnership.isOngoing, isFalse);
      });

      test('should identify ongoing partnership correctly', () {
        final partnership = UserPartnership(
          id: 'partnership-123',
          type: ProfilePartnershipType.business,
          partnerId: 'business-123',
          partnerName: 'Test Business',
          status: PartnershipStatus.active,
          startDate: startDate,
          // endDate is null, so it's ongoing
        );

        expect(partnership.isActive, isTrue);
        expect(partnership.isCompleted, isFalse);
        expect(partnership.isOngoing, isTrue);
      });

      test('should identify ongoing partnership by date range', () {
        final partnership = UserPartnership(
          id: 'partnership-123',
          type: ProfilePartnershipType.business,
          partnerId: 'business-123',
          partnerName: 'Test Business',
          status: PartnershipStatus.active,
          startDate: startDate,
          // endDate is null, so it's ongoing
        );

        expect(partnership.isOngoing, isTrue);
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final partnership = UserPartnership(
          id: 'partnership-123',
          type: ProfilePartnershipType.business,
          partnerId: 'business-123',
          partnerName: 'Test Business',
          partnerLogoUrl: 'https://example.com/logo.png',
          status: PartnershipStatus.active,
          startDate: startDate,
          endDate: endDate,
          category: 'Food',
          vibeCompatibility: 0.85,
          eventCount: 5,
          isPublic: true,
        );

        final json = partnership.toJson();

        expect(json['id'], equals('partnership-123'));
        expect(json['type'], equals('business'));
        expect(json['partnerId'], equals('business-123'));
        expect(json['partnerName'], equals('Test Business'));
        expect(json['partnerLogoUrl'], equals('https://example.com/logo.png'));
        expect(json['status'], equals('active'));
        expect(json['startDate'], equals(startDate.toIso8601String()));
        expect(json['endDate'], equals(endDate.toIso8601String()));
        expect(json['category'], equals('Food'));
        expect(json['vibeCompatibility'], equals(0.85));
        expect(json['eventCount'], equals(5));
        expect(json['isPublic'], isTrue);
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'partnership-456',
          'type': 'brand',
          'partnerId': 'brand-456',
          'partnerName': 'Test Brand',
          'partnerLogoUrl': 'https://example.com/brand-logo.png',
          'status': 'completed',
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'category': 'Technology',
          'vibeCompatibility': 0.92,
          'eventCount': 10,
          'isPublic': false,
        };

        final partnership = UserPartnership.fromJson(json);

        expect(partnership.id, equals('partnership-456'));
        expect(partnership.type, equals(ProfilePartnershipType.brand));
        expect(partnership.partnerId, equals('brand-456'));
        expect(partnership.partnerName, equals('Test Brand'));
        expect(partnership.partnerLogoUrl, equals('https://example.com/brand-logo.png'));
        expect(partnership.status, equals(PartnershipStatus.completed));
        expect(partnership.startDate, equals(startDate));
        expect(partnership.endDate, equals(endDate));
        expect(partnership.category, equals('Technology'));
        expect(partnership.vibeCompatibility, equals(0.92));
        expect(partnership.eventCount, equals(10));
        expect(partnership.isPublic, isFalse);
      });

      test('should handle missing optional fields in JSON', () {
        final minimalJson = {
          'id': 'partnership-minimal',
          'type': 'company',
          'partnerId': 'company-123',
          'partnerName': 'Test Company',
          'status': 'active',
        };

        final partnership = UserPartnership.fromJson(minimalJson);

        expect(partnership.id, equals('partnership-minimal'));
        expect(partnership.type, equals(ProfilePartnershipType.company));
        expect(partnership.partnerId, equals('company-123'));
        expect(partnership.partnerName, equals('Test Company'));
        expect(partnership.status, equals(PartnershipStatus.active));
        expect(partnership.partnerLogoUrl, isNull);
        expect(partnership.startDate, isNull);
        expect(partnership.endDate, isNull);
        expect(partnership.category, isNull);
        expect(partnership.vibeCompatibility, isNull);
        expect(partnership.eventCount, equals(0));
        expect(partnership.isPublic, isTrue);
      });

      test('should handle null values in JSON gracefully', () {
        final jsonWithNulls = {
          'id': 'partnership-nulls',
          'type': 'business',
          'partnerId': 'business-123',
          'partnerName': 'Test Business',
          'status': 'active',
          'partnerLogoUrl': null,
          'startDate': null,
          'endDate': null,
          'category': null,
          'vibeCompatibility': null,
        };

        final partnership = UserPartnership.fromJson(jsonWithNulls);

        expect(partnership.partnerLogoUrl, isNull);
        expect(partnership.startDate, isNull);
        expect(partnership.endDate, isNull);
        expect(partnership.category, isNull);
        expect(partnership.vibeCompatibility, isNull);
      });

      test('should handle JSON roundtrip correctly', () {
        final originalPartnership = UserPartnership(
          id: 'partnership-roundtrip',
          type: ProfilePartnershipType.business,
          partnerId: 'business-123',
          partnerName: 'Test Business',
          partnerLogoUrl: 'https://example.com/logo.png',
          status: PartnershipStatus.active,
          startDate: startDate,
          endDate: endDate,
          category: 'Food',
          vibeCompatibility: 0.85,
          eventCount: 5,
          isPublic: true,
        );

        final json = originalPartnership.toJson();
        final reconstructed = UserPartnership.fromJson(json);

        expect(reconstructed, equals(originalPartnership));
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final original = UserPartnership(
          id: 'partnership-123',
          type: ProfilePartnershipType.business,
          partnerId: 'business-123',
          partnerName: 'Test Business',
          status: PartnershipStatus.active,
        );

        final updated = original.copyWith(
          partnerName: 'Updated Business',
          status: PartnershipStatus.completed,
          isPublic: false,
        );

        expect(updated.id, equals(original.id));
        expect(updated.type, equals(original.type));
        expect(updated.partnerId, equals(original.partnerId));
        expect(updated.partnerName, equals('Updated Business'));
        expect(updated.status, equals(PartnershipStatus.completed));
        expect(updated.isPublic, isFalse);
      });

      test('should create copy without changing original', () {
        final original = UserPartnership(
          id: 'partnership-123',
          type: ProfilePartnershipType.business,
          partnerId: 'business-123',
          partnerName: 'Test Business',
          status: PartnershipStatus.active,
        );

        final copy = original.copyWith(partnerName: 'New Name');

        expect(original.partnerName, equals('Test Business'));
        expect(copy.partnerName, equals('New Name'));
      });
    });

    group('Equatable', () {
      test('should be equal when all properties match', () {
        final partnership1 = UserPartnership(
          id: 'partnership-123',
          type: ProfilePartnershipType.business,
          partnerId: 'business-123',
          partnerName: 'Test Business',
          status: PartnershipStatus.active,
        );

        final partnership2 = UserPartnership(
          id: 'partnership-123',
          type: ProfilePartnershipType.business,
          partnerId: 'business-123',
          partnerName: 'Test Business',
          status: PartnershipStatus.active,
        );

        expect(partnership1, equals(partnership2));
      });

      test('should not be equal when properties differ', () {
        final partnership1 = UserPartnership(
          id: 'partnership-123',
          type: ProfilePartnershipType.business,
          partnerId: 'business-123',
          partnerName: 'Test Business',
          status: PartnershipStatus.active,
        );

        final partnership2 = UserPartnership(
          id: 'partnership-123',
          type: ProfilePartnershipType.business,
          partnerId: 'business-123',
          partnerName: 'Different Business',
          status: PartnershipStatus.active,
        );

        expect(partnership1, isNot(equals(partnership2)));
      });
    });
  });
}

