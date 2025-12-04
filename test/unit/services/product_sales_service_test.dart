import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/product_sales_service.dart';
import 'package:spots/core/services/product_tracking_service.dart';
import 'package:spots/core/services/revenue_split_service.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/models/product_tracking.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/models/payment_status.dart';

import 'product_sales_service_test.mocks.dart';

@GenerateMocks([
  ProductTrackingService,
  RevenueSplitService,
  PaymentService,
])
void main() {
  group('ProductSalesService Tests', () {
    late ProductSalesService service;
    late MockProductTrackingService mockProductTrackingService;
    late MockRevenueSplitService mockRevenueSplitService;
    late MockPaymentService mockPaymentService;
    late ProductTracking testProductTracking;

    setUp(() {
      mockProductTrackingService = MockProductTrackingService();
      mockRevenueSplitService = MockRevenueSplitService();
      mockPaymentService = MockPaymentService();

      service = ProductSalesService(
        productTrackingService: mockProductTrackingService,
        revenueSplitService: mockRevenueSplitService,
        paymentService: mockPaymentService,
      );

      testProductTracking = ProductTracking(
        id: 'tracking-123',
        sponsorshipId: 'sponsorship-123',
        productName: 'Coffee Beans',
        quantityProvided: 100,
        quantitySold: 0,
        unitPrice: 15.00,
        totalSales: 0.0,
        platformFee: 0.0,
        sales: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    group('processProductSale', () {
      test('should process product sale successfully', () async {
        // Arrange
        when(mockProductTrackingService.getProductTrackingById('tracking-123'))
            .thenAnswer((_) async => testProductTracking);
        when(mockProductTrackingService.recordProductSale(
          productTrackingId: 'tracking-123',
          quantity: 10,
          buyerId: 'user-456',
          salePrice: 15.00,
          paymentMethod: anyNamed('paymentMethod'),
        )).thenAnswer((_) async => testProductTracking.copyWith(
          quantitySold: 10,
          totalSales: 150.00,
          sales: [
            ProductSale(
              id: 'sale-1',
              productTrackingId: 'tracking-123',
              buyerId: 'user-456',
              quantity: 10,
              unitPrice: 15.00,
              totalAmount: 150.00,
              soldAt: DateTime.now(),
              paymentStatus: PaymentStatus.completed,
            ),
          ],
        ));
        when(mockProductTrackingService.calculateRevenueAttribution(
          productTrackingId: 'tracking-123',
        )).thenAnswer((_) async => {'brand-123': 135.00});

        // Act
        final sale = await service.processProductSale(
          productTrackingId: 'tracking-123',
          quantity: 10,
          buyerId: 'user-456',
          salePrice: 15.00,
        );

        // Assert
        expect(sale, isA<ProductSale>());
        expect(sale.quantity, equals(10));
        expect(sale.buyerId, equals('user-456'));
        expect(sale.totalAmount, equals(150.00));
      });

      test('should throw exception if product tracking not found', () async {
        // Arrange
        when(mockProductTrackingService.getProductTrackingById('tracking-123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.processProductSale(
            productTrackingId: 'tracking-123',
            quantity: 10,
            buyerId: 'user-456',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Product tracking not found'),
          )),
        );
      });

      test('should throw exception if insufficient quantity available', () async {
        // Arrange
        final lowStockTracking = testProductTracking.copyWith(
          quantityProvided: 5,
        );
        when(mockProductTrackingService.getProductTrackingById('tracking-123'))
            .thenAnswer((_) async => lowStockTracking);

        // Act & Assert
        expect(
          () => service.processProductSale(
            productTrackingId: 'tracking-123',
            quantity: 10, // More than available
            buyerId: 'user-456',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Insufficient quantity available'),
          )),
        );
      });

      test('should use unitPrice if salePrice not provided', () async {
        // Arrange
        when(mockProductTrackingService.getProductTrackingById('tracking-123'))
            .thenAnswer((_) async => testProductTracking);
        when(mockProductTrackingService.recordProductSale(
          productTrackingId: 'tracking-123',
          quantity: 10,
          buyerId: 'user-456',
          salePrice: 15.00, // Uses unitPrice
          paymentMethod: anyNamed('paymentMethod'),
        )).thenAnswer((_) async => testProductTracking.copyWith(
          quantitySold: 10,
          totalSales: 150.00,
          sales: [
            ProductSale(
              id: 'sale-1',
              productTrackingId: 'tracking-123',
              buyerId: 'user-456',
              quantity: 10,
              unitPrice: 15.00,
              totalAmount: 150.00,
              soldAt: DateTime.now(),
              paymentStatus: PaymentStatus.completed,
            ),
          ],
        ));
        when(mockProductTrackingService.calculateRevenueAttribution(
          productTrackingId: 'tracking-123',
        )).thenAnswer((_) async => {'brand-123': 135.00});

        // Act
        final sale = await service.processProductSale(
          productTrackingId: 'tracking-123',
          quantity: 10,
          buyerId: 'user-456',
          // salePrice not provided, should use unitPrice
        );

        // Assert
        expect(sale.unitPrice, equals(15.00));
      });
    });

    group('calculateProductRevenue', () {
      test('should calculate total product revenue for sponsorship', () async {
        // Arrange
        final tracking1 = testProductTracking.copyWith(
          id: 'tracking-1',
          totalSales: 150.00,
        );
        final tracking2 = testProductTracking.copyWith(
          id: 'tracking-2',
          totalSales: 200.00,
        );

        when(mockProductTrackingService.getProductTrackingForSponsorship('sponsorship-123'))
            .thenAnswer((_) async => [tracking1, tracking2]);

        // Act
        final revenue = await service.calculateProductRevenue(
          sponsorshipId: 'sponsorship-123',
        );

        // Assert
        expect(revenue, equals(350.00)); // 150.00 + 200.00
      });

      test('should filter revenue by date range', () async {
        // Arrange
        final tracking1 = testProductTracking.copyWith(
          id: 'tracking-1',
          totalSales: 150.00,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        );
        final tracking2 = testProductTracking.copyWith(
          id: 'tracking-2',
          totalSales: 200.00,
          createdAt: DateTime.now().add(const Duration(days: 5)),
        );

        when(mockProductTrackingService.getProductTrackingForSponsorship('sponsorship-123'))
            .thenAnswer((_) async => [tracking1, tracking2]);

        final startDate = DateTime.now().subtract(const Duration(days: 10));
        final endDate = DateTime.now();

        // Act
        final revenue = await service.calculateProductRevenue(
          sponsorshipId: 'sponsorship-123',
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        // Should only include tracking1 (within date range)
        expect(revenue, equals(150.00));
      });
    });

    group('calculateProductRevenueSplit', () {
      test('should calculate product revenue split', () async {
        // Arrange
        final tracking = testProductTracking.copyWith(
          totalSales: 150.00,
        );
        final revenueSplit = RevenueSplit.nWay(
          id: 'split-123',
          eventId: 'event-123',
          totalAmount: 150.00,
          ticketsSold: 10,
          parties: [
            SplitParty(
              partyId: 'brand-123',
              type: SplitPartyType.sponsor,
              percentage: 100.0,
              amount: 135.00,
              name: 'Brand',
            ),
          ],
        );

        when(mockProductTrackingService.getProductTrackingById('tracking-123'))
            .thenAnswer((_) async => tracking);
        when(mockRevenueSplitService.calculateProductSalesSplit(
          productTrackingId: 'tracking-123',
          totalSales: 150.00,
        )).thenAnswer((_) async => revenueSplit);

        // Act
        final split = await service.calculateProductRevenueSplit(
          productTrackingId: 'tracking-123',
        );

        // Assert
        expect(split, isA<RevenueSplit>());
        expect(split.totalAmount, equals(150.00));
        expect(split.parties, hasLength(1));
        expect(split.parties[0].partyId, equals('brand-123'));
      });
    });

    group('generateEventSalesReport', () {
      test('should generate event sales report', () async {
        // Act
        final report = await service.generateEventSalesReport(
          eventId: 'event-123',
        );

        // Assert
        expect(report, isA<EventProductSalesReport>());
        expect(report.eventId, equals('event-123'));
      });
    });
  });
}

