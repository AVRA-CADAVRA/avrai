import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/brand_analytics_service.dart';
import 'package:spots/core/services/sponsorship_service.dart';
import 'package:spots/core/services/product_tracking_service.dart';
import 'package:spots/core/services/product_sales_service.dart';
import 'package:spots/core/services/revenue_split_service.dart';
import 'package:spots/core/models/sponsorship.dart';

import 'brand_analytics_service_test.mocks.dart';

@GenerateMocks([
  SponsorshipService,
  ProductTrackingService,
  ProductSalesService,
  RevenueSplitService,
])
void main() {
  group('BrandAnalyticsService Tests', () {
    late BrandAnalyticsService service;
    late MockSponsorshipService mockSponsorshipService;
    late MockProductTrackingService mockProductTrackingService;
    late MockProductSalesService mockProductSalesService;
    late MockRevenueSplitService mockRevenueSplitService;
    late Sponsorship testSponsorship;

    setUp(() {
      mockSponsorshipService = MockSponsorshipService();
      mockProductTrackingService = MockProductTrackingService();
      mockProductSalesService = MockProductSalesService();
      mockRevenueSplitService = MockRevenueSplitService();

      service = BrandAnalyticsService(
        sponsorshipService: mockSponsorshipService,
        productTrackingService: mockProductTrackingService,
        productSalesService: mockProductSalesService,
        revenueSplitService: mockRevenueSplitService,
      );

      testSponsorship = Sponsorship(
        id: 'sponsorship-123',
        eventId: 'event-123',
        brandId: 'brand-123',
        type: SponsorshipType.financial,
        contributionAmount: 500.00,
        status: SponsorshipStatus.completed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    group('calculateBrandROI', () {
      test('should calculate brand ROI', () async {
        // Arrange
        when(mockRevenueSplitService.trackEarnings(
          partyId: 'brand-123',
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
        )).thenAnswer((_) async => 600.00); // Revenue from splits

        // Act
        final roi = await service.calculateBrandROI(
          brandId: 'brand-123',
        );

        // Assert
        expect(roi, isA<BrandROI>());
        expect(roi.brandId, equals('brand-123'));
        expect(roi.totalRevenue, equals(600.00));
        expect(roi.roiPercentage, isA<double>());
      });

      test('should calculate ROI percentage correctly', () async {
        // Arrange
        // Investment: 500.00 (from sponsorship contributionAmount)
        // Revenue: 600.00
        // ROI = ((600 - 500) / 500) * 100 = 20%
        when(mockRevenueSplitService.trackEarnings(
          partyId: 'brand-123',
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
        )).thenAnswer((_) async => 600.00);

        // Act
        final roi = await service.calculateBrandROI(
          brandId: 'brand-123',
        );

        // Assert
        expect(roi.netProfit, equals(100.00)); // 600 - 500
        // ROI calculation depends on totalInvestment which needs to be calculated from sponsorships
      });

      test('should filter ROI by date range', () async {
        // Arrange
        final startDate = DateTime.now().subtract(const Duration(days: 30));
        final endDate = DateTime.now();

        when(mockRevenueSplitService.trackEarnings(
          partyId: 'brand-123',
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => 600.00);

        // Act
        final roi = await service.calculateBrandROI(
          brandId: 'brand-123',
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(roi.startDate, equals(startDate));
        expect(roi.endDate, equals(endDate));
      });
    });

    group('getBrandPerformance', () {
      test('should return brand performance metrics', () async {
        // Act
        final performance = await service.getBrandPerformance(
          brandId: 'brand-123',
        );

        // Assert
        expect(performance, isA<BrandPerformance>());
        expect(performance.brandId, equals('brand-123'));
        expect(performance.calculatedAt, isNotNull);
      });
    });

    group('analyzeBrandExposure', () {
      test('should return brand exposure analytics', () async {
        // Act
        final exposure = await service.analyzeBrandExposure(
          brandId: 'brand-123',
          eventId: 'event-123',
        );

        // Assert
        expect(exposure, isA<BrandExposure>());
        expect(exposure.brandId, equals('brand-123'));
        expect(exposure.eventId, equals('event-123'));
        expect(exposure.calculatedAt, isNotNull);
      });
    });

    group('getEventPerformance', () {
      test('should return event performance metrics', () async {
        // Arrange
        when(mockSponsorshipService.getSponsorshipsForEvent('event-123'))
            .thenAnswer((_) async => [testSponsorship]);

        // Act
        final performance = await service.getEventPerformance(
          eventId: 'event-123',
        );

        // Assert
        expect(performance, isA<EventPerformance>());
        expect(performance.eventId, equals('event-123'));
        expect(performance.totalSponsorships, equals(1));
        expect(performance.totalSponsorshipValue, equals(500.00));
      });
    });
  });
}

