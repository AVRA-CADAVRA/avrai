import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/brand/performance_metrics_widget.dart';
import 'package:spots/presentation/pages/brand/brand_analytics_page.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for PerformanceMetricsWidget
/// 
/// Agent 2: Phase 7, Section 51-52 - Widget Test Coverage
void main() {
  group('PerformanceMetricsWidget Widget Tests', () {
    testWidgets('displays performance metrics widget', (WidgetTester tester) async {
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
        child: PerformanceMetricsWidget(analytics: analytics),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(PerformanceMetricsWidget), findsOneWidget);
      expect(find.text('Performance Metrics'), findsOneWidget);
    });

    testWidgets('displays total events metric', (WidgetTester tester) async {
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
        child: PerformanceMetricsWidget(analytics: analytics),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Total Events'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('displays active sponsorships metric', (WidgetTester tester) async {
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
        child: PerformanceMetricsWidget(analytics: analytics),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Active Sponsorships'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });
  });
}

