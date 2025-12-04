import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/multi_party_sponsorship.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for MultiPartySponsorship model
void main() {
  group('MultiPartySponsorship Model Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    test('should create multi-party sponsorship with required fields', () {
      final multiParty = MultiPartySponsorship(
        id: 'multi-sponsor-123',
        eventId: 'event-456',
        brandIds: ['brand-1', 'brand-2', 'brand-3'],
        agreementStatus: MultiPartyAgreementStatus.pending,
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(multiParty.id, equals('multi-sponsor-123'));
      expect(multiParty.brandCount, equals(3));
      expect(multiParty.isApproved, isFalse);
      expect(multiParty.canBeModified, isTrue);
    });

    test('should validate revenue split configuration', () {
      final multiParty = MultiPartySponsorship(
        id: 'multi-sponsor-123',
        eventId: 'event-456',
        brandIds: ['brand-1', 'brand-2'],
        revenueSplitConfiguration: {
          'brand-1': 60.0,
          'brand-2': 40.0,
        },
        agreementStatus: MultiPartyAgreementStatus.pending,
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(multiParty.isRevenueSplitValid, isTrue);
    });

    test('should detect invalid revenue split configuration', () {
      final multiParty = MultiPartySponsorship(
        id: 'multi-sponsor-123',
        eventId: 'event-456',
        brandIds: ['brand-1', 'brand-2'],
        revenueSplitConfiguration: {
          'brand-1': 60.0,
          'brand-2': 50.0, // Total > 100%
        },
        agreementStatus: MultiPartyAgreementStatus.pending,
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(multiParty.isRevenueSplitValid, isFalse);
    });

    test('should serialize and deserialize correctly', () {
      final multiParty = MultiPartySponsorship(
        id: 'multi-sponsor-123',
        eventId: 'event-456',
        brandIds: ['brand-1', 'brand-2'],
        revenueSplitConfiguration: {
          'brand-1': 60.0,
          'brand-2': 40.0,
        },
        totalContributionValue: 1000.00,
        agreementStatus: MultiPartyAgreementStatus.approved,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final json = multiParty.toJson();
      final restored = MultiPartySponsorship.fromJson(json);

      expect(restored.id, equals(multiParty.id));
      expect(restored.brandCount, equals(2));
      expect(restored.totalContributionValue, equals(1000.00));
    });
  });
}

