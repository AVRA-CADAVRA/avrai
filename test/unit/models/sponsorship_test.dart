import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/sponsorship.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for Sponsorship model
/// Tests sponsorship creation, JSON serialization, status workflow, and types
void main() {
  group('Sponsorship Model Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Constructor and Properties', () {
      test('should create sponsorship with required fields', () {
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-789',
          type: SponsorshipType.financial,
          status: SponsorshipStatus.pending,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(sponsorship.id, equals('sponsor-123'));
        expect(sponsorship.eventId, equals('event-456'));
        expect(sponsorship.brandId, equals('brand-789'));
        expect(sponsorship.type, equals(SponsorshipType.financial));
        expect(sponsorship.status, equals(SponsorshipStatus.pending));
        expect(sponsorship.isApproved, isFalse);
        expect(sponsorship.isActive, isFalse);
        expect(sponsorship.isLocked, isFalse);
        expect(sponsorship.canBeModified, isTrue);
      });

      test('should create financial sponsorship with amount', () {
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-789',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          status: SponsorshipStatus.pending,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(sponsorship.contributionAmount, equals(500.00));
        expect(sponsorship.totalContributionValue, equals(500.00));
      });

      test('should create product sponsorship with value', () {
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-789',
          type: SponsorshipType.product,
          productValue: 400.00,
          status: SponsorshipStatus.pending,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(sponsorship.productValue, equals(400.00));
        expect(sponsorship.totalContributionValue, equals(400.00));
      });

      test('should create hybrid sponsorship with both amounts', () {
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-789',
          type: SponsorshipType.hybrid,
          contributionAmount: 300.00,
          productValue: 400.00,
          status: SponsorshipStatus.pending,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(sponsorship.totalContributionValue, equals(700.00));
      });
    });

    group('Status Workflow', () {
      test('should track pending status correctly', () {
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-789',
          type: SponsorshipType.financial,
          status: SponsorshipStatus.pending,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(sponsorship.status, equals(SponsorshipStatus.pending));
        expect(sponsorship.canBeModified, isTrue);
        expect(sponsorship.isLocked, isFalse);
      });

      test('should track approved status correctly', () {
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-789',
          type: SponsorshipType.financial,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(sponsorship.isApproved, isTrue);
        expect(sponsorship.isActive, isFalse);
      });

      test('should track locked status correctly', () {
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-789',
          type: SponsorshipType.financial,
          status: SponsorshipStatus.locked,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(sponsorship.isLocked, isTrue);
        expect(sponsorship.canBeModified, isFalse);
      });

      test('should track active status correctly', () {
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-789',
          type: SponsorshipType.financial,
          status: SponsorshipStatus.active,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(sponsorship.isActive, isTrue);
        expect(sponsorship.isApproved, isTrue);
        expect(sponsorship.isLocked, isTrue);
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-789',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          status: SponsorshipStatus.pending,
          agreementTerms: {'terms': 'test'},
          agreementVersion: '1.0',
          agreementSignedAt: testDate,
          agreementSignedBy: 'brand-rep-123',
          revenueSharePercentage: 20.0,
          metadata: {'key': 'value'},
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = sponsorship.toJson();

        expect(json['id'], equals('sponsor-123'));
        expect(json['eventId'], equals('event-456'));
        expect(json['brandId'], equals('brand-789'));
        expect(json['type'], equals('financial'));
        expect(json['contributionAmount'], equals(500.00));
        expect(json['status'], equals('pending'));
        expect(json['revenueSharePercentage'], equals(20.0));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'sponsor-123',
          'eventId': 'event-456',
          'brandId': 'brand-789',
          'type': 'financial',
          'contributionAmount': 500.00,
          'status': 'pending',
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
        };

        final sponsorship = Sponsorship.fromJson(json);

        expect(sponsorship.id, equals('sponsor-123'));
        expect(sponsorship.eventId, equals('event-456'));
        expect(sponsorship.brandId, equals('brand-789'));
        expect(sponsorship.type, equals(SponsorshipType.financial));
        expect(sponsorship.contributionAmount, equals(500.00));
        expect(sponsorship.status, equals(SponsorshipStatus.pending));
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final original = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-789',
          type: SponsorshipType.financial,
          status: SponsorshipStatus.pending,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          status: SponsorshipStatus.approved,
          contributionAmount: 600.00,
        );

        expect(updated.id, equals(original.id));
        expect(updated.status, equals(SponsorshipStatus.approved));
        expect(updated.contributionAmount, equals(600.00));
        expect(updated.type, equals(original.type));
      });
    });

    group('SponsorshipType Extension', () {
      test('should have correct display names', () {
        expect(SponsorshipType.financial.displayName, equals('Financial'));
        expect(SponsorshipType.product.displayName, equals('Product'));
        expect(SponsorshipType.hybrid.displayName, equals('Hybrid'));
      });

      test('should parse from string correctly', () {
        expect(
          SponsorshipTypeExtension.fromString('financial'),
          equals(SponsorshipType.financial),
        );
        expect(
          SponsorshipTypeExtension.fromString('product'),
          equals(SponsorshipType.product),
        );
        expect(
          SponsorshipTypeExtension.fromString('hybrid'),
          equals(SponsorshipType.hybrid),
        );
        expect(
          SponsorshipTypeExtension.fromString('unknown'),
          equals(SponsorshipType.financial), // Default
        );
      });
    });

    group('SponsorshipStatus Extension', () {
      test('should have correct display names', () {
        expect(SponsorshipStatus.pending.displayName, equals('Pending'));
        expect(SponsorshipStatus.approved.displayName, equals('Approved'));
        expect(SponsorshipStatus.active.displayName, equals('Active'));
        expect(SponsorshipStatus.locked.displayName, equals('Locked'));
      });

      test('should parse from string correctly', () {
        expect(
          SponsorshipStatusExtension.fromString('pending'),
          equals(SponsorshipStatus.pending),
        );
        expect(
          SponsorshipStatusExtension.fromString('approved'),
          equals(SponsorshipStatus.approved),
        );
        expect(
          SponsorshipStatusExtension.fromString('active'),
          equals(SponsorshipStatus.active),
        );
      });
    });
  });
}

