import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/ai2ai/learning_insights_widget.dart';
import 'package:spots/core/ai/ai2ai_learning.dart';
import "../../helpers/widget_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for LearningInsightsWidget
/// Tests display of learning insights from AI2AI interactions
void main() {
  group('LearningInsightsWidget Widget Tests', () {
    testWidgets('displays empty state when no insights', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const LearningInsightsWidget(insights: []),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(LearningInsightsWidget), findsOneWidget);
      expect(find.text('Learning Insights'), findsOneWidget);
      expect(find.text('No insights yet'), findsOneWidget);
      expect(find.text('Insights will appear as your AI learns from interactions'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('displays insights list when insights exist', (WidgetTester tester) async {
      // Arrange
      final insights = [
        SharedInsight(
          category: 'Preference Learning',
          dimension: 'adventure',
          value: 0.75,
          description: 'User shows strong preference for adventure activities',
          reliability: 0.9,
          timestamp: TestHelpers.createTestDateTime(),
        ),
        SharedInsight(
          category: 'Social Patterns',
          dimension: 'social',
          value: 0.6,
          description: 'Moderate social interaction patterns detected',
          reliability: 0.7,
          timestamp: TestHelpers.createTestDateTime().subtract(const Duration(hours: 2)),
        ),
      ];

      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningInsightsWidget(insights: insights),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(LearningInsightsWidget), findsOneWidget);
      expect(find.text('Learning Insights'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Preference Learning'), findsOneWidget);
      expect(find.text('Social Patterns'), findsOneWidget);
      expect(find.text('User shows strong preference for adventure activities'), findsOneWidget);
    });

    testWidgets('displays insight details correctly', (WidgetTester tester) async {
      // Arrange
      final insights = [
        SharedInsight(
          category: 'Test Category',
          dimension: 'adventure',
          value: 0.8,
          description: 'Test description',
          reliability: 0.85,
          timestamp: TestHelpers.createTestDateTime(),
        ),
      ];

      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningInsightsWidget(insights: insights),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Test Category'), findsOneWidget);
      expect(find.text('Test description'), findsOneWidget);
      expect(find.textContaining('adventure: 80%'), findsOneWidget);
      expect(find.textContaining('Reliability: 85%'), findsOneWidget);
    });

    testWidgets('limits displayed insights to 5', (WidgetTester tester) async {
      // Arrange
      final insights = List.generate(10, (index) => SharedInsight(
        category: 'Category $index',
        dimension: 'test',
        value: 0.5,
        description: 'Description $index',
        reliability: 0.7,
        timestamp: TestHelpers.createTestDateTime(),
      ));

      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningInsightsWidget(insights: insights),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Should show count of 10 but only display 5
      expect(find.text('10'), findsOneWidget);
      expect(find.text('Category 0'), findsOneWidget);
      expect(find.text('Category 4'), findsOneWidget);
      expect(find.text('Category 5'), findsNothing); // Should not show 6th item
    });

    testWidgets('displays correct icon based on reliability', (WidgetTester tester) async {
      // Arrange
      final highReliabilityInsight = SharedInsight(
        category: 'High Reliability',
        dimension: 'test',
        value: 0.8,
        description: 'High reliability insight',
        reliability: 0.9,
        timestamp: TestHelpers.createTestDateTime(),
      );

      final mediumReliabilityInsight = SharedInsight(
        category: 'Medium Reliability',
        dimension: 'test',
        value: 0.6,
        description: 'Medium reliability insight',
        reliability: 0.6,
        timestamp: TestHelpers.createTestDateTime(),
      );

      final lowReliabilityInsight = SharedInsight(
        category: 'Low Reliability',
        dimension: 'test',
        value: 0.4,
        description: 'Low reliability insight',
        reliability: 0.3,
        timestamp: TestHelpers.createTestDateTime(),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningInsightsWidget(insights: [
          highReliabilityInsight,
          mediumReliabilityInsight,
          lowReliabilityInsight,
        ]),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Icons should be present (exact icon type depends on reliability)
      expect(find.byIcon(Icons.trending_up), findsWidgets);
      expect(find.byIcon(Icons.info), findsWidgets);
      expect(find.byIcon(Icons.help_outline), findsWidgets);
    });
  });
}

