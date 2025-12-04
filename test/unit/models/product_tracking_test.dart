import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/product_tracking.dart';
import 'package:spots/core/models/payment_status.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for ProductTracking model
void main() {
  group('ProductTracking Model Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    test('should create product tracking with required fields', () {
      final tracking = ProductTracking(
        id: 'product-track-123',
        sponsorshipId: 'sponsor-456',
        productName: 'Premium Olive Oil',
        quantityProvided: 20,
        unitPrice: 25.00,
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(tracking.id, equals('product-track-123'));
      expect(tracking.productName, equals('Premium Olive Oil'));
      expect(tracking.quantityProvided, equals(20));
      expect(tracking.quantityRemaining, equals(20));
      expect(tracking.isSoldOut, isFalse);
    });

    test('should calculate remaining quantity correctly', () {
      final tracking = ProductTracking(
        id: 'product-track-123',
        sponsorshipId: 'sponsor-456',
        productName: 'Premium Olive Oil',
        quantityProvided: 20,
        quantitySold: 15,
        quantityGivenAway: 2,
        quantityUsedInEvent: 1,
        unitPrice: 25.00,
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(tracking.quantityRemaining, equals(2));
    });

    test('should calculate profit margin correctly', () {
      final tracking = ProductTracking(
        id: 'product-track-123',
        sponsorshipId: 'sponsor-456',
        productName: 'Premium Olive Oil',
        quantityProvided: 20,
        unitPrice: 25.00,
        unitCostPrice: 15.00,
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(tracking.profitMargin, equals(40.0)); // (25-15)/25 * 100
    });

    test('should serialize and deserialize correctly', () {
      final sale = ProductSale(
        id: 'sale-123',
        productTrackingId: 'product-track-123',
        buyerId: 'buyer-456',
        quantity: 2,
        unitPrice: 25.00,
        totalAmount: 50.00,
        soldAt: testDate,
        paymentStatus: PaymentStatus.completed,
      );

      final tracking = ProductTracking(
        id: 'product-track-123',
        sponsorshipId: 'sponsor-456',
        productName: 'Premium Olive Oil',
        quantityProvided: 20,
        quantitySold: 2,
        unitPrice: 25.00,
        totalSales: 50.00,
        platformFee: 5.00,
        sales: [sale],
        createdAt: testDate,
        updatedAt: testDate,
      );

      final json = tracking.toJson();
      final restored = ProductTracking.fromJson(json);

      expect(restored.id, equals(tracking.id));
      expect(restored.totalSales, equals(50.00));
      expect(restored.sales.length, equals(1));
    });
  });
}

