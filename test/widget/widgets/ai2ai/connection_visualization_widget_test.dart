import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/ai2ai/connection_visualization_widget.dart';
import 'package:spots/core/monitoring/connection_monitor.dart';
import "../../helpers/widget_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for ConnectionVisualizationWidget
/// Tests network visualization display
void main() {
  group('ConnectionVisualizationWidget Widget Tests', () {
    testWidgets('displays empty state when no connections', (WidgetTester tester) async {
      // Arrange
      final overview = ActiveConnectionsOverview.empty();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: ConnectionVisualizationWidget(overview: overview),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(ConnectionVisualizationWidget), findsOneWidget);
      expect(find.text('Network Visualization'), findsOneWidget);
      expect(find.text('No connections to visualize'), findsOneWidget);
      expect(find.byIcon(Icons.account_tree), findsOneWidget);
    });

    testWidgets('displays network graph when connections exist', (WidgetTester tester) async {
      // Arrange
      final overview = ActiveConnectionsOverview(
        totalActiveConnections: 3,
        aggregateMetrics: AggregateConnectionMetrics(
          averageCompatibility: 0.8,
          averageLatency: Duration(milliseconds: 50),
          averageThroughput: 2000.0,
          totalMessagesExchanged: 200,
          averageQualityScore: 0.9,
          totalLearningEvents: 30,
        ),
        topPerformingConnections: ['conn-1', 'conn-2'],
        connectionsNeedingAttention: ['conn-3'],
        learningVelocityDistribution: LearningVelocityDistribution.normal(),
        optimizationOpportunities: [],
        averageConnectionDuration: Duration(minutes: 20),
        totalAlertsGenerated: 0,
        generatedAt: TestHelpers.createTestDateTime(),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: ConnectionVisualizationWidget(overview: overview),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(ConnectionVisualizationWidget), findsOneWidget);
      expect(find.text('Network Visualization'), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
    });

    testWidgets('displays legend', (WidgetTester tester) async {
      // Arrange
      final overview = ActiveConnectionsOverview(
        totalActiveConnections: 2,
        aggregateMetrics: AggregateConnectionMetrics(
          averageCompatibility: 0.75,
          averageLatency: Duration(milliseconds: 100),
          averageThroughput: 1000.0,
          totalMessagesExchanged: 150,
          averageQualityScore: 0.8,
          totalLearningEvents: 25,
        ),
        topPerformingConnections: ['conn-1'],
        connectionsNeedingAttention: [],
        learningVelocityDistribution: LearningVelocityDistribution.normal(),
        optimizationOpportunities: [],
        averageConnectionDuration: Duration(minutes: 15),
        totalAlertsGenerated: 0,
        generatedAt: TestHelpers.createTestDateTime(),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: ConnectionVisualizationWidget(overview: overview),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(ConnectionVisualizationWidget), findsOneWidget);
    });
  });
}

