import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/product_tracking.dart';
import 'package:spots/core/models/payment_status.dart';
import 'package:spots/core/models/sponsorship_integration.dart';
import '../helpers/test_helpers.dart';

/// Product Tracking Flow Integration Tests
/// 
/// Agent 3: Models & Testing (Week 12)
/// 
/// Tests the complete product tracking flow:
/// - Product provided by sponsor
/// - Product sales tracking
/// - Revenue attribution
/// - Inventory management
/// - Sales reporting
/// 
/// **Test Scenarios:**
/// - Scenario 1: Product Provision and Tracking
/// - Scenario 2: Product Sales Tracking
/// - Scenario 3: Revenue Attribution
/// - Scenario 4: Inventory Management
/// - Scenario 5: Sales Reporting
void main() {
  group('Product Tracking Flow Integration Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Scenario 1: Product Provision and Tracking', () {
      test('should track products provided by sponsor', () {
        // Arrange
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.product,
          productValue: 500.00,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final productTracking = ProductTracking(
          id: 'product-track-123',
          sponsorshipId: 'sponsor-123',
          productName: 'Premium Olive Oil',
          quantityProvided: 20,
          unitPrice: 25.00,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act & Assert
        expect(productTracking.sponsorshipId, equals(sponsorship.id));
        expect(productTracking.quantityProvided, equals(20));
        expect(productTracking.quantityRemaining, equals(20));
        expect(productTracking.isSoldOut, isFalse);
      });

      test('should track multiple products from same sponsor', () {
        // Arrange
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.product,
          productValue: 900.00,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final productTracking1 = ProductTracking(
          id: 'product-track-1',
          sponsorshipId: 'sponsor-123',
          productName: 'Premium Olive Oil',
          quantityProvided: 20,
          unitPrice: 25.00,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final productTracking2 = ProductTracking(
          id: 'product-track-2',
          sponsorshipId: 'sponsor-123',
          productName: 'Premium Balsamic',
          quantityProvided: 15,
          unitPrice: 20.00,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act
        final allTracking = [productTracking1, productTracking2];
        final totalProducts = allTracking
            .where((pt) => pt.sponsorshipId == sponsorship.id)
            .fold<int>(0, (sum, pt) => sum + pt.quantityProvided);

        // Assert
        expect(allTracking.length, equals(2));
        expect(totalProducts, equals(35));
      });
    });

    group('Scenario 2: Product Sales Tracking', () {
      test('should track product sales and update inventory', () {
        // Arrange
        var productTracking = ProductTracking(
          id: 'product-track-123',
          sponsorshipId: 'sponsor-123',
          productName: 'Premium Olive Oil',
          quantityProvided: 20,
          unitPrice: 25.00,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act - Record sales
        productTracking = productTracking.copyWith(
          quantitySold: 15,
          totalSales: 375.00,
          platformFee: 37.50,
        );

        // Assert
        expect(productTracking.quantitySold, equals(15));
        expect(productTracking.totalSales, equals(375.00));
        expect(productTracking.quantityRemaining, equals(5));
        expect(productTracking.hasSales, isTrue);
      });

      test('should track individual product sales', () {
        // Arrange
        final sale1 = ProductSale(
          id: 'sale-1',
          productTrackingId: 'product-track-123',
          buyerId: 'buyer-1',
          quantity: 2,
          unitPrice: 25.00,
          totalAmount: 50.00,
          soldAt: testDate,
          paymentStatus: PaymentStatus.completed,
        );

        final sale2 = ProductSale(
          id: 'sale-2',
          productTrackingId: 'product-track-123',
          buyerId: 'buyer-2',
          quantity: 1,
          unitPrice: 25.00,
          totalAmount: 25.00,
          soldAt: testDate,
          paymentStatus: PaymentStatus.completed,
        );

        final productTracking = ProductTracking(
          id: 'product-track-123',
          sponsorshipId: 'sponsor-123',
          productName: 'Premium Olive Oil',
          quantityProvided: 20,
          quantitySold: 3,
          unitPrice: 25.00,
          totalSales: 75.00,
          platformFee: 7.50,
          sales: [sale1, sale2],
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act & Assert
        expect(productTracking.sales.length, equals(2));
        expect(productTracking.totalSales, equals(75.00));
        expect(productTracking.quantitySold, equals(3));
      });
    });

    group('Scenario 3: Revenue Attribution', () {
      test('should attribute product sales revenue correctly', () {
        // Arrange
        final productTracking = ProductTracking(
          id: 'product-track-123',
          sponsorshipId: 'sponsor-123',
          productName: 'Premium Olive Oil',
          quantityProvided: 20,
          quantitySold: 15,
          unitPrice: 25.00,
          totalSales: 375.00,
          platformFee: 37.50,
          revenueDistribution: {
            'brand-123': 202.50, // 60% of net
            'user-123': 84.38,   // 25% of net
            'business-123': 50.62, // 15% of net
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act
        final netRevenue = productTracking.netRevenue;
        final brandShare = productTracking.revenueDistribution['brand-123'] ?? 0.0;
        final totalDistributed = productTracking.revenueDistribution.values
            .fold<double>(0.0, (sum, amount) => sum + amount);

        // Assert
        expect(netRevenue, equals(337.50));
        expect(brandShare, equals(202.50));
        expect(totalDistributed, closeTo(netRevenue, 0.01));
      });

      test('should calculate revenue for multiple products', () {
        // Arrange
        final productTracking1 = ProductTracking(
          id: 'product-track-1',
          sponsorshipId: 'sponsor-1',
          productName: 'Premium Olive Oil',
          quantityProvided: 20,
          quantitySold: 15,
          unitPrice: 25.00,
          totalSales: 375.00,
          platformFee: 37.50,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final productTracking2 = ProductTracking(
          id: 'product-track-2',
          sponsorshipId: 'sponsor-2',
          productName: 'Premium Wine',
          quantityProvided: 10,
          quantitySold: 10,
          unitPrice: 35.00,
          totalSales: 350.00,
          platformFee: 35.00,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act
        final totalSales = productTracking1.totalSales + productTracking2.totalSales;
        final totalPlatformFee = productTracking1.platformFee + productTracking2.platformFee;
        final totalNetRevenue = productTracking1.netRevenue + productTracking2.netRevenue;

        // Assert
        expect(totalSales, equals(725.00));
        expect(totalPlatformFee, equals(72.50));
        expect(totalNetRevenue, equals(652.50));
      });
    });

    group('Scenario 4: Inventory Management', () {
      test('should track product inventory correctly', () {
        // Arrange
        final productTracking = ProductTracking(
          id: 'product-track-123',
          sponsorshipId: 'sponsor-123',
          productName: 'Premium Olive Oil',
          quantityProvided: 20,
          quantitySold: 15,
          quantityGivenAway: 2,
          quantityUsedInEvent: 1,
          unitPrice: 25.00,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act
        final remaining = productTracking.quantityRemaining;

        // Assert
        expect(remaining, equals(2)); // 20 - 15 - 2 - 1
        expect(productTracking.quantitySold, equals(15));
        expect(productTracking.quantityGivenAway, equals(2));
        expect(productTracking.quantityUsedInEvent, equals(1));
      });

      test('should detect sold out products', () {
        // Arrange
        final productTracking = ProductTracking(
          id: 'product-track-123',
          sponsorshipId: 'sponsor-123',
          productName: 'Premium Olive Oil',
          quantityProvided: 20,
          quantitySold: 20,
          unitPrice: 25.00,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act & Assert
        expect(productTracking.isSoldOut, isTrue);
        expect(productTracking.quantityRemaining, equals(0));
      });
    });

    group('Scenario 5: Sales Reporting', () {
      test('should calculate profit margin for products', () {
        // Arrange
        final productTracking = ProductTracking(
          id: 'product-track-123',
          sponsorshipId: 'sponsor-123',
          productName: 'Premium Olive Oil',
          quantityProvided: 20,
          quantitySold: 15,
          unitPrice: 25.00,
          unitCostPrice: 15.00,
          totalSales: 375.00,
          platformFee: 37.50,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act
        final profitMargin = productTracking.profitMargin;

        // Assert
        expect(profitMargin, equals(40.0)); // (25-15)/25 * 100
      });

      test('should get product tracking for sponsorship', () {
        // Arrange
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.product,
          status: SponsorshipStatus.active,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final productTracking = ProductTracking(
          id: 'product-track-123',
          sponsorshipId: 'sponsor-123',
          productName: 'Premium Olive Oil',
          quantityProvided: 20,
          quantitySold: 15,
          unitPrice: 25.00,
          totalSales: 375.00,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final allTracking = [productTracking];

        // Act
        final trackingForSponsor = SponsorshipIntegration.getProductTrackingForSponsorship(
          sponsorship,
          allTracking,
        );
        final totalSales = SponsorshipIntegration.getTotalProductSalesForSponsorship(
          sponsorship,
          allTracking,
        );

        // Assert
        expect(trackingForSponsor.length, equals(1));
        expect(totalSales, equals(375.00));
      });
    });
  });
}

