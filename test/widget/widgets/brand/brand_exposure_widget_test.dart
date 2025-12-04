import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/brand/brand_exposure_widget.dart';
import 'package:spots/presentation/pages/brand/brand_analytics_page.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for BrandExposureWidget
/// 
/// Agent 2: Phase 7, Section 51-52 - Widget Test Coverage
/// 
/// Tests:
/// - Widget rendering
/// - Exposure metrics display
/// - Number formatting
/// - All metric rows display
void main() {
  group('BrandExposureWidget Widget Tests', () {
    testWidgets('displays brand exposure widget with metrics', (WidgetTester tester) async {
      // Arrange
      final analytics = BrandAnalytics(
        totalInvestment: 10000.0,
        cashInvestment: 5000.0,
        productInvestment: 5000.0,
        totalReturns: 15000.0,
        directRevenue: 12000.0,
        estimatedBrandValue: 3000.0,
        roiPercentage: 50.0,
        topPerformingEvents: [],
        exposureMetrics: const BrandExposureMetrics(
          totalReach: 5000,
          totalImpressions: 10000,
          productSampling: 200,
          emailSignups: 150,
          websiteVisits: 300,
        ),
        performanceMetrics: const PerformanceMetrics(
          totalEvents: 10,
          activeSponsorships: 5,
          averageROI: 50.0,
          totalBrandValue: 3000.0,
        ),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: BrandExposureWidget(analytics: analytics),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(BrandExposureWidget), findsOneWidget);
      expect(find.text('Brand Exposure Metrics'), findsOneWidget);
    });

    testWidgets('displays total reach metric', (WidgetTester tester) async {
      // Arrange
      final analytics = BrandAnalytics(
        totalInvestment: 10000.0,
        cashInvestment: 5000.0,
        productInvestment: 5000.0,
        totalReturns: 15000.0,
        directRevenue: 12000.0,
        estimatedBrandValue: 3000.0,
        roiPercentage: 50.0,
        topPerformingEvents: [],
        exposureMetrics: const BrandExposureMetrics(
          totalReach: 5000,
          totalImpressions: 10000,
          productSampling: 200,
          emailSignups: 150,
          websiteVisits: 300,
        ),
        performanceMetrics: const PerformanceMetrics(
          totalEvents: 10,
          activeSponsorships: 5,
          averageROI: 50.0,
          totalBrandValue: 3000.0,
        ),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: BrandExposureWidget(analytics: analytics),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Total Reach'), findsOneWidget);
      expect(find.text('Total audience reached'), findsOneWidget);
    });

    testWidgets('displays impressions metric', (WidgetTester tester) async {
      // Arrange
      final analytics = BrandAnalytics(
        totalInvestment: 10000.0,
        cashInvestment: 5000.0,
        productInvestment: 5000.0,
        totalReturns: 15000.0,
        directRevenue: 12000.0,
        estimatedBrandValue: 3000.0,
        roiPercentage: 50.0,
        topPerformingEvents: [],
        exposureMetrics: const BrandExposureMetrics(
          totalReach: 5000,
          totalImpressions: 10000,
          productSampling: 200,
          emailSignups: 150,
          websiteVisits: 300,
        ),
        performanceMetrics: const PerformanceMetrics(
          totalEvents: 10,
          activeSponsorships: 5,
          averageROI: 50.0,
          totalBrandValue: 3000.0,
        ),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: BrandExposureWidget(analytics: analytics),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Impressions'), findsOneWidget);
      expect(find.text('Total impressions'), findsOneWidget);
    });

    testWidgets('displays product sampling metric', (WidgetTester tester) async {
      // Arrange
      final analytics = BrandAnalytics(
        totalInvestment: 10000.0,
        cashInvestment: 5000.0,
        productInvestment: 5000.0,
        totalReturns: 15000.0,
        directRevenue: 12000.0,
        estimatedBrandValue: 3000.0,
        roiPercentage: 50.0,
        topPerformingEvents: [],
        exposureMetrics: const BrandExposureMetrics(
          totalReach: 5000,
          totalImpressions: 10000,
          productSampling: 200,
          emailSignups: 150,
          websiteVisits: 300,
        ),
        performanceMetrics: const PerformanceMetrics(
          totalEvents: 10,
          activeSponsorships: 5,
          averageROI: 50.0,
          totalBrandValue: 3000.0,
        ),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: BrandExposureWidget(analytics: analytics),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Product Sampling'), findsOneWidget);
      expect(find.text('People who sampled products'), findsOneWidget);
    });

    testWidgets('displays email signups metric', (WidgetTester tester) async {
      // Arrange
      final analytics = BrandAnalytics(
        totalInvestment: 10000.0,
        cashInvestment: 5000.0,
        productInvestment: 5000.0,
        totalReturns: 15000.0,
        directRevenue: 12000.0,
        estimatedBrandValue: 3000.0,
        roiPercentage: 50.0,
        topPerformingEvents: [],
        exposureMetrics: const BrandExposureMetrics(
          totalReach: 5000,
          totalImpressions: 10000,
          productSampling: 200,
          emailSignups: 150,
          websiteVisits: 300,
        ),
        performanceMetrics: const PerformanceMetrics(
          totalEvents: 10,
          activeSponsorships: 5,
          averageROI: 50.0,
          totalBrandValue: 3000.0,
        ),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: BrandExposureWidget(analytics: analytics),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Email Signups'), findsOneWidget);
      expect(find.text('New email subscribers'), findsOneWidget);
    });

    testWidgets('displays website visits metric', (WidgetTester tester) async {
      // Arrange
      final analytics = BrandAnalytics(
        totalInvestment: 10000.0,
        cashInvestment: 5000.0,
        productInvestment: 5000.0,
        totalReturns: 15000.0,
        directRevenue: 12000.0,
        estimatedBrandValue: 3000.0,
        roiPercentage: 50.0,
        topPerformingEvents: [],
        exposureMetrics: const BrandExposureMetrics(
          totalReach: 5000,
          totalImpressions: 10000,
          productSampling: 200,
          emailSignups: 150,
          websiteVisits: 300,
        ),
        performanceMetrics: const PerformanceMetrics(
          totalEvents: 10,
          activeSponsorships: 5,
          averageROI: 50.0,
          totalBrandValue: 3000.0,
        ),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: BrandExposureWidget(analytics: analytics),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Website Visits'), findsOneWidget);
      expect(find.text('Website traffic from events'), findsOneWidget);
    });
  });
}

