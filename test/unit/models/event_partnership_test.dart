import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/business_account.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for EventPartnership model
/// Tests partnership creation, JSON serialization, status workflow, and agreement locking
void main() {
  group('EventPartnership Model Tests', () {
    late DateTime testDate;
    late UnifiedUser testUser;
    late BusinessAccount testBusiness;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Expert User',
      );
      testBusiness = BusinessAccount(
        id: 'business-123',
        name: 'Test Restaurant',
        email: 'test@restaurant.com',
        businessType: 'Restaurant',
        createdAt: testDate,
        updatedAt: testDate,
        createdBy: 'user-123',
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Constructor and Properties', () {
      test('should create partnership with required fields', () {
        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(partnership.id, equals('partnership-123'));
        expect(partnership.eventId, equals('event-123'));
        expect(partnership.userId, equals('user-123'));
        expect(partnership.businessId, equals('business-123'));
        expect(partnership.status, equals(PartnershipStatus.pending));
        expect(partnership.type, equals(PartnershipType.eventBased));
        expect(partnership.userApproved, isFalse);
        expect(partnership.businessApproved, isFalse);
        expect(partnership.isApproved, isFalse);
        expect(partnership.isLocked, isFalse);
        expect(partnership.canBeModified, isTrue);
      });

      test('should create partnership with all optional fields', () {
        final agreement = PartnershipAgreement(
          id: 'agreement-123',
          partnershipId: 'partnership-123',
          terms: {'revenueSplit': '50/50'},
          agreedAt: testDate,
          agreedBy: 'user-123',
        );

        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          user: testUser,
          business: testBusiness,
          status: PartnershipStatus.proposed,
          agreement: agreement,
          type: PartnershipType.ongoing,
          sharedResponsibilities: ['venue', 'marketing'],
          venueLocation: '123 Main St',
          expectedEventCount: 5,
          eventIds: ['event-1', 'event-2'],
          termsAgreedAt: testDate,
          termsVersion: '1.0',
          userApproved: true,
          businessApproved: true,
          vibeCompatibilityScore: 0.85,
          createdAt: testDate,
          updatedAt: testDate,
          startDate: testDate,
          endDate: testDate.add(Duration(days: 30)),
        );

        expect(partnership.user, equals(testUser));
        expect(partnership.business, equals(testBusiness));
        expect(partnership.status, equals(PartnershipStatus.proposed));
        expect(partnership.agreement, equals(agreement));
        expect(partnership.type, equals(PartnershipType.ongoing));
        expect(partnership.sharedResponsibilities, hasLength(2));
        expect(partnership.venueLocation, equals('123 Main St'));
        expect(partnership.expectedEventCount, equals(5));
        expect(partnership.eventIds, hasLength(2));
        expect(partnership.isApproved, isTrue);
        expect(partnership.vibeCompatibilityScore, equals(0.85));
      });
    });

    group('Status Workflow', () {
      test('should track pending status correctly', () {
        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.pending,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(partnership.status, equals(PartnershipStatus.pending));
        expect(partnership.canBeModified, isTrue);
        expect(partnership.isLocked, isFalse);
      });

      test('should track proposed status correctly', () {
        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.proposed,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(partnership.status, equals(PartnershipStatus.proposed));
        expect(partnership.canBeModified, isTrue);
      });

      test('should track locked status correctly', () {
        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.locked,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(partnership.status, equals(PartnershipStatus.locked));
        expect(partnership.isLocked, isTrue);
        expect(partnership.canBeModified, isFalse);
      });

      test('should track active status correctly', () {
        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.active,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(partnership.status, equals(PartnershipStatus.active));
        expect(partnership.isActive, isTrue);
        expect(partnership.isLocked, isTrue);
      });

      test('should track completed status correctly', () {
        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.completed,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(partnership.status, equals(PartnershipStatus.completed));
        expect(partnership.isCompleted, isTrue);
      });

      test('should track cancelled status correctly', () {
        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.cancelled,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(partnership.status, equals(PartnershipStatus.cancelled));
        expect(partnership.isCancelled, isTrue);
      });

      test('should track disputed status correctly', () {
        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.disputed,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(partnership.status, equals(PartnershipStatus.disputed));
        expect(partnership.isDisputed, isTrue);
      });
    });

    group('Approval Logic', () {
      test('should require both parties to approve', () {
        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          userApproved: true,
          businessApproved: false,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(partnership.userApproved, isTrue);
        expect(partnership.businessApproved, isFalse);
        expect(partnership.isApproved, isFalse);
      });

      test('should be approved when both parties approve', () {
        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          userApproved: true,
          businessApproved: true,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(partnership.isApproved, isTrue);
      });
    });

    group('Vibe Compatibility', () {
      test('should store vibe compatibility score', () {
        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          vibeCompatibilityScore: 0.75,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(partnership.vibeCompatibilityScore, equals(0.75));
      });

      test('should handle null vibe compatibility score', () {
        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(partnership.vibeCompatibilityScore, isNull);
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final agreement = PartnershipAgreement(
          id: 'agreement-123',
          partnershipId: 'partnership-123',
          terms: {'revenueSplit': '50/50'},
          agreedAt: testDate,
          agreedBy: 'user-123',
        );

        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.proposed,
          agreement: agreement,
          type: PartnershipType.eventBased,
          sharedResponsibilities: ['venue'],
          venueLocation: '123 Main St',
          eventIds: ['event-1'],
          termsAgreedAt: testDate,
          termsVersion: '1.0',
          userApproved: true,
          businessApproved: true,
          vibeCompatibilityScore: 0.85,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = partnership.toJson();

        expect(json['id'], equals('partnership-123'));
        expect(json['eventId'], equals('event-123'));
        expect(json['userId'], equals('user-123'));
        expect(json['businessId'], equals('business-123'));
        expect(json['status'], equals('proposed'));
        expect(json['type'], equals('eventBased'));
        expect(json['userApproved'], isTrue);
        expect(json['businessApproved'], isTrue);
        expect(json['vibeCompatibilityScore'], equals(0.85));
        expect(json['agreement'], isNotNull);
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'partnership-123',
          'eventId': 'event-123',
          'userId': 'user-123',
          'businessId': 'business-123',
          'status': 'proposed',
          'type': 'eventBased',
          'sharedResponsibilities': ['venue'],
          'venueLocation': '123 Main St',
          'eventIds': ['event-1'],
          'termsAgreedAt': testDate.toIso8601String(),
          'termsVersion': '1.0',
          'userApproved': true,
          'businessApproved': true,
          'vibeCompatibilityScore': 0.85,
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
          'agreement': {
            'id': 'agreement-123',
            'partnershipId': 'partnership-123',
            'terms': {'revenueSplit': '50/50'},
            'agreedAt': testDate.toIso8601String(),
            'agreedBy': 'user-123',
            'version': '1.0',
          },
        };

        final partnership = EventPartnership.fromJson(json);

        expect(partnership.id, equals('partnership-123'));
        expect(partnership.eventId, equals('event-123'));
        expect(partnership.userId, equals('user-123'));
        expect(partnership.businessId, equals('business-123'));
        expect(partnership.status, equals(PartnershipStatus.proposed));
        expect(partnership.type, equals(PartnershipType.eventBased));
        expect(partnership.userApproved, isTrue);
        expect(partnership.businessApproved, isTrue);
        expect(partnership.vibeCompatibilityScore, equals(0.85));
        expect(partnership.agreement, isNotNull);
      });
    });

    group('Copy With', () {
      test('should create copy with updated fields', () {
        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = partnership.copyWith(
          status: PartnershipStatus.approved,
          userApproved: true,
          businessApproved: true,
        );

        expect(updated.id, equals(partnership.id));
        expect(updated.status, equals(PartnershipStatus.approved));
        expect(updated.userApproved, isTrue);
        expect(updated.businessApproved, isTrue);
        expect(updated.isApproved, isTrue);
      });
    });

    group('Partnership Agreement', () {
      test('should create agreement with required fields', () {
        final agreement = PartnershipAgreement(
          id: 'agreement-123',
          partnershipId: 'partnership-123',
          terms: {'revenueSplit': '50/50'},
          agreedAt: testDate,
          agreedBy: 'user-123',
        );

        expect(agreement.id, equals('agreement-123'));
        expect(agreement.partnershipId, equals('partnership-123'));
        expect(agreement.terms, equals({'revenueSplit': '50/50'}));
        expect(agreement.agreedAt, equals(testDate));
        expect(agreement.agreedBy, equals('user-123'));
        expect(agreement.version, equals('1.0'));
      });

      test('should serialize agreement to JSON', () {
        final agreement = PartnershipAgreement(
          id: 'agreement-123',
          partnershipId: 'partnership-123',
          terms: {'revenueSplit': '50/50'},
          customArrangementDetails: 'Custom terms',
          agreedAt: testDate,
          agreedBy: 'user-123',
          version: '1.0',
        );

        final json = agreement.toJson();

        expect(json['id'], equals('agreement-123'));
        expect(json['partnershipId'], equals('partnership-123'));
        expect(json['terms'], equals({'revenueSplit': '50/50'}));
        expect(json['customArrangementDetails'], equals('Custom terms'));
        expect(json['agreedBy'], equals('user-123'));
        expect(json['version'], equals('1.0'));
      });

      test('should deserialize agreement from JSON', () {
        final json = {
          'id': 'agreement-123',
          'partnershipId': 'partnership-123',
          'terms': {'revenueSplit': '50/50'},
          'customArrangementDetails': 'Custom terms',
          'agreedAt': testDate.toIso8601String(),
          'agreedBy': 'user-123',
          'version': '1.0',
        };

        final agreement = PartnershipAgreement.fromJson(json);

        expect(agreement.id, equals('agreement-123'));
        expect(agreement.partnershipId, equals('partnership-123'));
        expect(agreement.terms, equals({'revenueSplit': '50/50'}));
        expect(agreement.customArrangementDetails, equals('Custom terms'));
        expect(agreement.agreedBy, equals('user-123'));
        expect(agreement.version, equals('1.0'));
      });
    });

    group('Partnership Status Extension', () {
      test('should convert status to display name', () {
        expect(PartnershipStatus.pending.displayName, equals('Pending'));
        expect(PartnershipStatus.proposed.displayName, equals('Proposed'));
        expect(PartnershipStatus.negotiating.displayName, equals('Negotiating'));
        expect(PartnershipStatus.approved.displayName, equals('Approved'));
        expect(PartnershipStatus.locked.displayName, equals('Locked'));
        expect(PartnershipStatus.active.displayName, equals('Active'));
        expect(PartnershipStatus.completed.displayName, equals('Completed'));
        expect(PartnershipStatus.cancelled.displayName, equals('Cancelled'));
        expect(PartnershipStatus.disputed.displayName, equals('Disputed'));
      });

      test('should parse status from string', () {
        expect(
          PartnershipStatusExtension.fromString('pending'),
          equals(PartnershipStatus.pending),
        );
        expect(
          PartnershipStatusExtension.fromString('proposed'),
          equals(PartnershipStatus.proposed),
        );
        expect(
          PartnershipStatusExtension.fromString('locked'),
          equals(PartnershipStatus.locked),
        );
        expect(
          PartnershipStatusExtension.fromString('unknown'),
          equals(PartnershipStatus.pending), // Default
        );
      });
    });

    group('Partnership Type Extension', () {
      test('should convert type to display name', () {
        expect(PartnershipType.eventBased.displayName, equals('Event-Based'));
        expect(PartnershipType.ongoing.displayName, equals('Ongoing'));
        expect(PartnershipType.exclusive.displayName, equals('Exclusive'));
      });

      test('should parse type from string', () {
        expect(
          PartnershipTypeExtension.fromString('eventBased'),
          equals(PartnershipType.eventBased),
        );
        expect(
          PartnershipTypeExtension.fromString('ongoing'),
          equals(PartnershipType.ongoing),
        );
        expect(
          PartnershipTypeExtension.fromString('exclusive'),
          equals(PartnershipType.exclusive),
        );
        expect(
          PartnershipTypeExtension.fromString('unknown'),
          equals(PartnershipType.eventBased), // Default
        );
      });
    });
  });
}

