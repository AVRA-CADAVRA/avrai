import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/brand_account.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/multi_party_sponsorship.dart';
import 'package:spots/core/models/sponsorship_integration.dart';
import '../helpers/test_helpers.dart';
import '../fixtures/model_factories.dart';

/// Sponsorship Creation Flow Integration Tests
/// 
/// Agent 3: Models & Testing (Week 12)
/// 
/// Tests the complete sponsorship creation flow:
/// - Brand proposes sponsorship
/// - Host reviews proposal
/// - Agreement negotiation
/// - Sponsorship approval
/// - Multi-party sponsorship creation
/// 
/// **Test Scenarios:**
/// - Scenario 1: Financial Sponsorship Creation
/// - Scenario 2: Product Sponsorship Creation
/// - Scenario 3: Hybrid Sponsorship Creation
/// - Scenario 4: Multi-Party Sponsorship Creation
/// - Scenario 5: Sponsorship Approval Workflow
void main() {
  group('Sponsorship Creation Flow Integration Tests', () {
    late DateTime testDate;
    late UnifiedUser testUser;
    late BusinessAccount testBusiness;
    late BrandAccount testBrand;

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
      testBrand = BrandAccount(
        id: 'brand-123',
        name: 'Premium Oil Co.',
        brandType: 'Food & Beverage',
        contactEmail: 'partnerships@premiumoil.com',
        verificationStatus: BrandVerificationStatus.verified,
        createdAt: testDate,
        updatedAt: testDate,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Scenario 1: Financial Sponsorship Creation', () {
      test('should create financial sponsorship proposal', () {
        // Arrange
        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-456',
          userId: 'user-123',
          businessId: 'business-123',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          revenueSharePercentage: 20.0,
          status: SponsorshipStatus.proposed,
          agreementTerms: {
            'branding': 'Logo on event page',
            'socialMedia': 'Mention in promotion',
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act & Assert
        expect(sponsorship.eventId, equals(partnership.eventId));
        expect(sponsorship.type, equals(SponsorshipType.financial));
        expect(sponsorship.contributionAmount, equals(500.00));
        expect(sponsorship.status, equals(SponsorshipStatus.proposed));
        expect(sponsorship.canBeModified, isTrue);
      });

      test('should transition sponsorship from proposed to approved', () {
        // Arrange
        var sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          status: SponsorshipStatus.proposed,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act - Approve sponsorship
        sponsorship = sponsorship.copyWith(
          status: SponsorshipStatus.approved,
          agreementSignedAt: testDate,
          agreementSignedBy: 'user-123',
        );

        // Assert
        expect(sponsorship.status, equals(SponsorshipStatus.approved));
        expect(sponsorship.isApproved, isTrue);
        expect(sponsorship.agreementSignedAt, isNotNull);
      });
    });

    group('Scenario 2: Product Sponsorship Creation', () {
      test('should create product sponsorship with product value', () {
        // Arrange
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.product,
          productValue: 400.00,
          status: SponsorshipStatus.proposed,
          agreementTerms: {
            'products': [
              {
                'name': 'Premium Olive Oil',
                'quantity': 20,
                'unitPrice': 20.00,
              },
            ],
            'forSale': true,
            'forSample': true,
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act & Assert
        expect(sponsorship.type, equals(SponsorshipType.product));
        expect(sponsorship.productValue, equals(400.00));
        expect(sponsorship.totalContributionValue, equals(400.00));
      });
    });

    group('Scenario 3: Hybrid Sponsorship Creation', () {
      test('should create hybrid sponsorship with cash and product', () {
        // Arrange
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.hybrid,
          contributionAmount: 300.00,
          productValue: 400.00,
          revenueSharePercentage: 20.0,
          status: SponsorshipStatus.proposed,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act & Assert
        expect(sponsorship.type, equals(SponsorshipType.hybrid));
        expect(sponsorship.totalContributionValue, equals(700.00));
        expect(sponsorship.contributionAmount, equals(300.00));
        expect(sponsorship.productValue, equals(400.00));
      });
    });

    group('Scenario 4: Multi-Party Sponsorship Creation', () {
      test('should create multi-party sponsorship with multiple brands', () {
        // Arrange
        final brand1 = BrandAccount(
          id: 'brand-1',
          name: 'Oil Company',
          brandType: 'Food & Beverage',
          contactEmail: 'oil@company.com',
          verificationStatus: BrandVerificationStatus.verified,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final brand2 = BrandAccount(
          id: 'brand-2',
          name: 'Wine Company',
          brandType: 'Food & Beverage',
          contactEmail: 'wine@company.com',
          verificationStatus: BrandVerificationStatus.verified,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final multiParty = MultiPartySponsorship(
          id: 'multi-sponsor-123',
          eventId: 'event-456',
          brandIds: ['brand-1', 'brand-2'],
          revenueSplitConfiguration: {
            'brand-1': 60.0,
            'brand-2': 40.0,
          },
          totalContributionValue: 1000.00,
          agreementStatus: MultiPartyAgreementStatus.proposed,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act
        final brandIds = SponsorshipIntegration.getBrandIdsFromMultiParty(multiParty);
        final isValid = multiParty.isRevenueSplitValid;

        // Assert
        expect(multiParty.brandCount, equals(2));
        expect(brandIds, containsAll(['brand-1', 'brand-2']));
        expect(isValid, isTrue);
        expect(multiParty.canBeModified, isTrue);
      });

      test('should approve multi-party sponsorship', () {
        // Arrange
        var multiParty = MultiPartySponsorship(
          id: 'multi-sponsor-123',
          eventId: 'event-456',
          brandIds: ['brand-1', 'brand-2'],
          revenueSplitConfiguration: {
            'brand-1': 60.0,
            'brand-2': 40.0,
          },
          agreementStatus: MultiPartyAgreementStatus.proposed,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act - Approve multi-party sponsorship
        multiParty = multiParty.copyWith(
          agreementStatus: MultiPartyAgreementStatus.approved,
          agreementSignedAt: testDate,
          agreementSignedBy: ['brand-rep-1', 'brand-rep-2'],
        );

        // Assert
        expect(multiParty.agreementStatus, equals(MultiPartyAgreementStatus.approved));
        expect(multiParty.isApproved, isTrue);
        expect(multiParty.agreementSignedBy.length, equals(2));
      });
    });

    group('Scenario 5: Sponsorship Approval Workflow', () {
      test('should complete full sponsorship approval workflow', () {
        // Arrange
        var sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          status: SponsorshipStatus.pending,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Step 1: Propose
        sponsorship = sponsorship.copyWith(
          status: SponsorshipStatus.proposed,
        );
        expect(sponsorship.status, equals(SponsorshipStatus.proposed));

        // Step 2: Negotiate
        sponsorship = sponsorship.copyWith(
          status: SponsorshipStatus.negotiating,
          agreementTerms: {
            'revenueShare': 20.0,
            'branding': 'Logo on event page',
          },
        );
        expect(sponsorship.status, equals(SponsorshipStatus.negotiating));

        // Step 3: Approve
        sponsorship = sponsorship.copyWith(
          status: SponsorshipStatus.approved,
          agreementSignedAt: testDate,
          agreementSignedBy: 'brand-rep-123',
        );
        expect(sponsorship.isApproved, isTrue);

        // Step 4: Lock (before event)
        sponsorship = sponsorship.copyWith(
          status: SponsorshipStatus.locked,
        );
        expect(sponsorship.isLocked, isTrue);
        expect(sponsorship.canBeModified, isFalse);

        // Step 5: Activate (event starts)
        sponsorship = sponsorship.copyWith(
          status: SponsorshipStatus.active,
        );
        expect(sponsorship.isActive, isTrue);
      });

      test('should handle sponsorship cancellation', () {
        // Arrange
        var sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          status: SponsorshipStatus.proposed,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act - Cancel
        sponsorship = sponsorship.copyWith(
          status: SponsorshipStatus.cancelled,
        );

        // Assert
        expect(sponsorship.status, equals(SponsorshipStatus.cancelled));
        expect(sponsorship.isCancelled, isTrue);
      });
    });
  });
}

