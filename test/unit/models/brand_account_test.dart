import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/brand_account.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for BrandAccount model
void main() {
  group('BrandAccount Model Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    test('should create brand account with required fields', () {
      final brand = BrandAccount(
        id: 'brand-123',
        name: 'Premium Oil Co.',
        brandType: 'Food & Beverage',
        contactEmail: 'partnerships@premiumoil.com',
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(brand.id, equals('brand-123'));
      expect(brand.name, equals('Premium Oil Co.'));
      expect(brand.brandType, equals('Food & Beverage'));
      expect(brand.verificationStatus, equals(BrandVerificationStatus.pending));
      expect(brand.isVerified, isFalse);
      expect(brand.canSponsor, isFalse);
    });

    test('should create verified brand account', () {
      final brand = BrandAccount(
        id: 'brand-123',
        name: 'Premium Oil Co.',
        brandType: 'Food & Beverage',
        contactEmail: 'partnerships@premiumoil.com',
        verificationStatus: BrandVerificationStatus.verified,
        stripeConnectAccountId: 'acct_1234567890',
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(brand.isVerified, isTrue);
      expect(brand.canSponsor, isTrue);
    });

    test('should serialize and deserialize correctly', () {
      final brand = BrandAccount(
        id: 'brand-123',
        name: 'Premium Oil Co.',
        brandType: 'Food & Beverage',
        categories: ['Gourmet', 'Premium'],
        contactEmail: 'partnerships@premiumoil.com',
        contactPhone: '+1-555-0123',
        verificationStatus: BrandVerificationStatus.verified,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final json = brand.toJson();
      final restored = BrandAccount.fromJson(json);

      expect(restored.id, equals(brand.id));
      expect(restored.name, equals(brand.name));
      expect(restored.categories, equals(brand.categories));
      expect(restored.isVerified, isTrue);
    });
  });
}

