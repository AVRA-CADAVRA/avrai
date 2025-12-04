import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/product_tracking_service.dart';
import 'package:spots/core/services/sponsorship_service.dart';
import 'package:spots/core/services/revenue_split_service.dart';
import 'package:spots/core/models/product_tracking.dart';
import 'package:spots/core/models/sponsorship.dart';

import 'product_tracking_service_test.mocks.dart';

@GenerateMocks([SponsorshipService, RevenueSplitService])
void main() {
  group('ProductTrackingService Tests', () {
    late ProductTrackingService service;
    late MockSponsorshipService mockSponsorshipService;
    late MockRevenueSplitService mockRevenueSplitService;
    late Sponsorship testSponsorship;

    setUp(() {
      mockSponsorshipService = MockSponsorshipService();
      mockRevenueSplitService = MockRevenueSplitService();

      service = ProductTrackingService(
        sponsorshipService: mockSponsorshipService,
        revenueSplitService: mockRevenueSplitService,
      );

      testSponsorship = Sponsorship(
        id: 'sponsorship-123',
        eventId: 'event-123',
        brandId: 'brand-123',
        type: SponsorshipType.product,
        productValue: 300.00,
        status: SponsorshipStatus.approved,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    group('recordProductContribution', () {
      test('should record product contribution for product sponsorship', () async {
        // Arrange
        when(mockSponsorshipService.getSponsorshipById('sponsorship-123'))
            .thenAnswer((_) async => testSponsorship);

        // Act
        final tracking = await service.recordProductContribution(
          sponsorshipId: 'sponsorship-123',
          productName: 'Coffee Beans',
          quantityProvided: 100,
          unitPrice: 15.00,
          description: 'Premium coffee beans',
        );

        // Assert
        expect(tracking, isA<ProductTracking>());
        expect(tracking.sponsorshipId, equals('sponsorship-123'));
        expect(tracking.productName, equals('Coffee Beans'));
        expect(tracking.quantityProvided, equals(100));
        expect(tracking.unitPrice, equals(15.00));
        expect(tracking.quantityRemaining, equals(100));
      });

      test('should throw exception if sponsorship not found', () async {
        // Arrange
        when(mockSponsorshipService.getSponsorshipById('sponsorship-123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.recordProductContribution(
            sponsorshipId: 'sponsorship-123',
            productName: 'Coffee Beans',
            quantityProvided: 100,
            unitPrice: 15.00,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Sponsorship not found'),
          )),
        );
      });

      test('should throw exception if sponsorship type does not support products', () async {
        // Arrange
        final financialSponsorship = testSponsorship.copyWith(
          type: SponsorshipType.financial,
          productValue: null,
        );
        when(mockSponsorshipService.getSponsorshipById('sponsorship-123'))
            .thenAnswer((_) async => financialSponsorship);

        // Act & Assert
        expect(
          () => service.recordProductContribution(
            sponsorshipId: 'sponsorship-123',
            productName: 'Coffee Beans',
            quantityProvided: 100,
            unitPrice: 15.00,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('does not support products'),
          )),
        );
      });
    });

    group('recordProductSale', () {
      test('should record product sale and update quantity', () async {
        // Arrange
        when(mockSponsorshipService.getSponsorshipById('sponsorship-123'))
            .thenAnswer((_) async => testSponsorship);

        final tracking = await service.recordProductContribution(
          sponsorshipId: 'sponsorship-123',
          productName: 'Coffee Beans',
          quantityProvided: 100,
          unitPrice: 15.00,
        );

        // Act
        final updated = await service.recordProductSale(
          productTrackingId: tracking.id,
          quantity: 10,
          buyerId: 'user-456',
          salePrice: 15.00,
        );

        // Assert
        expect(updated.quantitySold, equals(10));
        expect(updated.quantityRemaining, equals(90));
        expect(updated.sales, hasLength(1));
        expect(updated.sales[0].quantity, equals(10));
        expect(updated.sales[0].buyerId, equals('user-456'));
      });

      test('should throw exception if insufficient quantity available', () async {
        // Arrange
        when(mockSponsorshipService.getSponsorshipById('sponsorship-123'))
            .thenAnswer((_) async => testSponsorship);

        final tracking = await service.recordProductContribution(
          sponsorshipId: 'sponsorship-123',
          productName: 'Coffee Beans',
          quantityProvided: 10,
          unitPrice: 15.00,
        );

        // Act & Assert
        expect(
          () => service.recordProductSale(
            productTrackingId: tracking.id,
            quantity: 20, // More than available
            buyerId: 'user-456',
            salePrice: 15.00,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Insufficient quantity'),
          )),
        );
      });
    });

    group('calculateRevenueAttribution', () {
      test('should calculate revenue attribution for product sales', () async {
        // Arrange
        when(mockSponsorshipService.getSponsorshipById('sponsorship-123'))
            .thenAnswer((_) async => testSponsorship);

        final tracking = await service.recordProductContribution(
          sponsorshipId: 'sponsorship-123',
          productName: 'Coffee Beans',
          quantityProvided: 100,
          unitPrice: 15.00,
        );

        await service.recordProductSale(
          productTrackingId: tracking.id,
          quantity: 10,
          buyerId: 'user-456',
          salePrice: 15.00,
        );

        // Act
        final updated = await service.calculateRevenueAttribution(
          productTrackingId: tracking.id,
        );

        // Assert
        expect(updated.totalRevenue, equals(150.00)); // 10 * 15.00
        expect(updated.revenueAttributed, isNotNull);
      });
    });

    group('generateSalesReport', () {
      test('should generate sales report for product tracking', () async {
        // Arrange
        when(mockSponsorshipService.getSponsorshipById('sponsorship-123'))
            .thenAnswer((_) async => testSponsorship);

        final tracking = await service.recordProductContribution(
          sponsorshipId: 'sponsorship-123',
          productName: 'Coffee Beans',
          quantityProvided: 100,
          unitPrice: 15.00,
        );

        await service.recordProductSale(
          productTrackingId: tracking.id,
          quantity: 10,
          buyerId: 'user-456',
          salePrice: 15.00,
        );

        // Act
        final report = await service.generateSalesReport(
          sponsorshipId: 'sponsorship-123',
        );

        // Assert
        expect(report, isA<ProductSalesReport>());
        expect(report.sponsorshipId, equals('sponsorship-123'));
        expect(report.totalQuantitySold, greaterThanOrEqualTo(10));
        expect(report.totalSales, greaterThanOrEqualTo(150.00));
      });
    });

    group('getProductTrackingById', () {
      test('should return product tracking by ID', () async {
        // Arrange
        when(mockSponsorshipService.getSponsorshipById('sponsorship-123'))
            .thenAnswer((_) async => testSponsorship);

        final created = await service.recordProductContribution(
          sponsorshipId: 'sponsorship-123',
          productName: 'Coffee Beans',
          quantityProvided: 100,
          unitPrice: 15.00,
        );

        // Act
        final tracking = await service.getProductTrackingById(created.id);

        // Assert
        expect(tracking, isNotNull);
        expect(tracking?.id, equals(created.id));
      });

      test('should return null if product tracking not found', () async {
        // Act
        final tracking = await service.getProductTrackingById('nonexistent-id');

        // Assert
        expect(tracking, isNull);
      });
    });
  });
}

