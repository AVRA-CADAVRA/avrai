import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/ai2ai/learning_metrics_chart.dart';
import 'package:spots/core/monitoring/network_analytics.dart';
import "../../helpers/widget_test_helpers.dart';

/// Widget tests for LearningMetricsChart
/// Tests learning metrics chart display
void main() {
  group('LearningMetricsChart Widget Tests', () {
    testWidgets('displays learning metrics chart', (WidgetTester tester) async {
      // Arrange
      final metrics = RealTimeMetrics(
        connectionThroughput: 10.5,
        matchingSuccessRate: 0.85,
        learningConvergenceSpeed: 0.7,
        vibeSynchronizationQuality: 0.9,
        networkResponsiveness: 0.8,
        resourceUtilization: ResourceUtilization(
          cpuUsage: 0.5,
          memoryUsage: 0.6,
          networkBandwidth: 0.4,
          storageUsage: 0.3,
        ),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningMetricsChart(metrics: metrics),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(LearningMetricsChart), findsOneWidget);
      expect(find.text('Learning Metrics'), findsOneWidget);
      expect(find.text('Connection Throughput'), findsOneWidget);
      expect(find.text('Matching Success Rate'), findsOneWidget);
      expect(find.text('Learning Convergence Speed'), findsOneWidget);
    });

    testWidgets('displays all metric bars', (WidgetTester tester) async {
      // Arrange
      final metrics = RealTimeMetrics(
        connectionThroughput: 15.0,
        matchingSuccessRate: 0.9,
        learningConvergenceSpeed: 0.8,
        vibeSynchronizationQuality: 0.95,
        networkResponsiveness: 0.85,
        resourceUtilization: ResourceUtilization(
          cpuUsage: 0.4,
          memoryUsage: 0.5,
          networkBandwidth: 0.3,
          storageUsage: 0.2,
        ),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningMetricsChart(metrics: metrics),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Vibe Synchronization Quality'), findsOneWidget);
      expect(find.text('Network Responsiveness'), findsOneWidget);
      expect(find.text('Resource Utilization'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });
  });
}

