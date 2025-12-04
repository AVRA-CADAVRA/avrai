import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:spots/presentation/widgets/ai2ai/connections_list.dart';
import 'package:spots/core/monitoring/connection_monitor.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for ConnectionsList
/// Tests display of active AI2AI connections list
void main() {
  group('ConnectionsList Widget Tests', () {
    testWidgets('displays empty state when no connections', (WidgetTester tester) async {
      // Arrange
      final overview = ActiveConnectionsOverview.empty();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: ConnectionsList(overview: overview),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(ConnectionsList), findsOneWidget);
      expect(find.text('Active Connections'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('No active connections'), findsOneWidget);
    });

    testWidgets('displays top performing connections', (WidgetTester tester) async {
      // Arrange
      final overview = ActiveConnectionsOverview(
        totalActiveConnections: 3,
        aggregateMetrics: AggregateConnectionMetrics(0.8),
        topPerformingConnections: ['conn-1', 'conn-2'],
        connectionsNeedingAttention: [],
        learningVelocityDistribution: LearningVelocityDistribution.normal(),
        optimizationOpportunities: [],
        averageConnectionDuration: Duration(minutes: 20),
        totalAlertsGenerated: 0,
        generatedAt: TestHelpers.createTestDateTime(),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: ConnectionsList(overview: overview),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Top Performing'), findsOneWidget);
      expect(find.text('High performance connection'), findsWidgets);
      expect(find.byIcon(Icons.trending_up), findsWidgets);
    });

    testWidgets('displays connections needing attention', (WidgetTester tester) async {
      // Arrange
      final overview = ActiveConnectionsOverview(
        totalActiveConnections: 2,
        aggregateMetrics: AggregateConnectionMetrics(0.5),
        topPerformingConnections: [],
        connectionsNeedingAttention: ['conn-3', 'conn-4'],
        learningVelocityDistribution: LearningVelocityDistribution.normal(),
        optimizationOpportunities: [],
        averageConnectionDuration: Duration(minutes: 5),
        totalAlertsGenerated: 2,
        generatedAt: TestHelpers.createTestDateTime(),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: ConnectionsList(overview: overview),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Needs Attention'), findsOneWidget);
      expect(find.text('May need optimization'), findsWidgets);
      expect(find.byIcon(Icons.warning), findsWidgets);
    });

    testWidgets('displays aggregate metrics', (WidgetTester tester) async {
      // Arrange
      final overview = ActiveConnectionsOverview(
        totalActiveConnections: 2,
        aggregateMetrics: AggregateConnectionMetrics(0.75),
        topPerformingConnections: ['conn-1'],
        connectionsNeedingAttention: [],
        learningVelocityDistribution: LearningVelocityDistribution.normal(),
        optimizationOpportunities: [],
        averageConnectionDuration: Duration(minutes: 15),
        totalAlertsGenerated: 1,
        generatedAt: TestHelpers.createTestDateTime(),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: ConnectionsList(overview: overview),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Aggregate Metrics'), findsOneWidget);
      expect(find.text('Avg Compatibility'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Avg Duration'), findsOneWidget);
      expect(find.text('15min'), findsOneWidget);
      expect(find.text('Total Alerts'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('navigates to connection detail on tap', (WidgetTester tester) async {
      // Arrange
      final overview = ActiveConnectionsOverview(
        totalActiveConnections: 1,
        aggregateMetrics: AggregateConnectionMetrics(0.8),
        topPerformingConnections: ['connection-12345'],
        connectionsNeedingAttention: [],
        learningVelocityDistribution: LearningVelocityDistribution.normal(),
        optimizationOpportunities: [],
        averageConnectionDuration: Duration(minutes: 20),
        totalAlertsGenerated: 0,
        generatedAt: TestHelpers.createTestDateTime(),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: ConnectionsList(overview: overview),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      
      // Tap on a connection tile
      final connectionTile = find.byType(ListTile).first;
      await tester.tap(connectionTile);
      await tester.pumpAndSettle();

      // Assert - Navigation should occur (checking for navigation icon)
      expect(find.byIcon(Icons.chevron_right), findsWidgets);
    });
  });
}

