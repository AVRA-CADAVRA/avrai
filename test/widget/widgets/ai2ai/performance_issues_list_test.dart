import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:spots/presentation/widgets/ai2ai/performance_issues_list.dart';
import 'package:spots/core/monitoring/network_analytics.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for PerformanceIssuesList
/// Tests performance issues and recommendations display
void main() {
  group('PerformanceIssuesList Widget Tests', () {
    testWidgets('displays empty state when no issues or recommendations', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const PerformanceIssuesList(
          issues: [],
          recommendations: [],
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(PerformanceIssuesList), findsOneWidget);
      expect(find.text('Performance & Optimization'), findsOneWidget);
      expect(find.text('No issues detected. Network operating optimally.'), findsOneWidget);
    });

    testWidgets('displays performance issues', (WidgetTester tester) async {
      // Arrange
      final issues = [
        PerformanceIssue(
          type: IssueType.highUtilization,
          severity: IssueSeverity.high,
          description: 'High latency detected',
          impact: 'May cause connection delays',
          recommendedAction: 'Consider load balancing optimization',
        ),
        PerformanceIssue(
          type: IssueType.lowConnectionSuccess,
          severity: IssueSeverity.critical,
          description: 'Low throughput',
          impact: 'Reduced AI2AI personality matching',
          recommendedAction: 'Review compatibility algorithms',
        ),
      ];

      final widget = WidgetTestHelpers.createTestableWidget(
        child: PerformanceIssuesList(
          issues: issues,
          recommendations: [],
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Issues (2)'), findsOneWidget);
      expect(find.text('High latency detected'), findsOneWidget);
      expect(find.text('Low throughput'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsWidgets);
      expect(find.byIcon(Icons.error), findsWidgets);
    });

    testWidgets('displays optimization recommendations', (WidgetTester tester) async {
      // Arrange
      final recommendations = [
        OptimizationRecommendation(
          category: 'Connection Quality',
          recommendation: 'Consider reducing connection pool size',
          expectedImpact: 'Increase average compatibility by 10-15%',
          priority: Priority.high,
          estimatedEffort: 'Medium',
        ),
        OptimizationRecommendation(
          category: 'Learning Effectiveness',
          recommendation: 'Enable connection caching',
          expectedImpact: 'Accelerate personality evolution by 20%',
          priority: Priority.medium,
          estimatedEffort: 'Low',
        ),
      ];

      final widget = WidgetTestHelpers.createTestableWidget(
        child: PerformanceIssuesList(
          issues: [],
          recommendations: recommendations,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Recommendations (2)'), findsOneWidget);
      expect(find.text('Consider reducing connection pool size'), findsOneWidget);
      expect(find.text('Enable connection caching'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsWidgets);
    });

    testWidgets('displays both issues and recommendations', (WidgetTester tester) async {
      // Arrange
      final issues = [
        PerformanceIssue(
          type: IssueType.highUtilization,
          severity: IssueSeverity.high,
          description: 'Test issue',
          impact: 'May cause connection delays',
          recommendedAction: 'Consider load balancing optimization',
        ),
      ];

      final recommendations = [
        OptimizationRecommendation(
          category: 'Connection Quality',
          recommendation: 'Test recommendation',
          expectedImpact: 'Increase average compatibility by 10-15%',
          priority: Priority.high,
          estimatedEffort: 'Medium',
        ),
      ];

      final widget = WidgetTestHelpers.createTestableWidget(
        child: PerformanceIssuesList(
          issues: issues,
          recommendations: recommendations,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Issues (1)'), findsOneWidget);
      expect(find.text('Recommendations (1)'), findsOneWidget);
    });
  });
}

