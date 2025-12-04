import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/expertise/expertise_progress_widget.dart';
import 'package:spots/core/models/expertise_progress.dart';
import 'package:spots/core/models/expertise_level.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for ExpertiseProgressWidget
/// Tests expertise progress display
void main() {
  group('ExpertiseProgressWidget Widget Tests', () {
    testWidgets('displays current level and category', (WidgetTester tester) async {
      // Arrange
      final progress = ExpertiseProgress(
        category: 'Coffee',
        currentLevel: ExpertiseLevel.local,
        progressPercentage: 50.0,
        nextLevel: ExpertiseLevel.city,
        location: 'Brooklyn',
        contributionBreakdown: {
          'spots': 5,
          'lists': 2,
          'reviews': 10,
        },
        totalContributions: 17,
        requiredContributions: 30,
        nextSteps: ['Create 3 more spots', 'Write 5 more reviews'],
        lastUpdated: DateTime.now(),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseProgressWidget(progress: progress),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(ExpertiseProgressWidget), findsOneWidget);
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('Local Level'), findsOneWidget);
      expect(find.text('• Brooklyn'), findsOneWidget);
    });

    testWidgets('displays progress bar when next level exists', (WidgetTester tester) async {
      // Arrange
      final progress = ExpertiseProgress(
        category: 'Restaurants',
        currentLevel: ExpertiseLevel.local,
        progressPercentage: 75.0,
        nextLevel: ExpertiseLevel.city,
        location: 'Manhattan',
        contributionBreakdown: {},
        totalContributions: 0,
        requiredContributions: 0,
        nextSteps: [],
        lastUpdated: DateTime.now(),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseProgressWidget(progress: progress),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.textContaining('75'), findsOneWidget);
    });

    testWidgets('displays highest level message when at max level', (WidgetTester tester) async {
      // Arrange
      final progress = ExpertiseProgress(
        category: 'Coffee',
        currentLevel: ExpertiseLevel.global,
        progressPercentage: 100.0,
        nextLevel: null,
        location: 'Global',
        contributionBreakdown: {
          'spots': 100,
          'lists': 50,
          'reviews': 200,
        },
        totalContributions: 350,
        requiredContributions: 0,
        nextSteps: [],
        lastUpdated: DateTime.now(),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseProgressWidget(progress: progress),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Highest level achieved!'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('displays contribution summary when showDetails is true', (WidgetTester tester) async {
      // Arrange
      final progress = ExpertiseProgress(
        category: 'Coffee',
        currentLevel: ExpertiseLevel.local,
        progressPercentage: 50.0,
        nextLevel: ExpertiseLevel.city,
        location: 'Brooklyn',
        contributionBreakdown: {
          'spots': 5,
          'lists': 2,
          'reviews': 10,
        },
        totalContributions: 17,
        requiredContributions: 30,
        nextSteps: ['Create 3 more spots'],
        lastUpdated: DateTime.now(),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseProgressWidget(progress: progress, showDetails: true),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Your Contributions'), findsOneWidget);
      expect(find.text('Next Steps'), findsOneWidget);
      expect(find.text('Create 3 more spots'), findsOneWidget);
    });

    testWidgets('hides details when showDetails is false', (WidgetTester tester) async {
      // Arrange
      final progress = ExpertiseProgress(
        category: 'Coffee',
        currentLevel: ExpertiseLevel.local,
        progressPercentage: 50.0,
        nextLevel: ExpertiseLevel.city,
        location: 'Brooklyn',
        contributionBreakdown: {
          'spots': 5,
        },
        totalContributions: 5,
        requiredContributions: 30,
        nextSteps: ['Create 3 more spots'],
        lastUpdated: DateTime.now(),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseProgressWidget(progress: progress, showDetails: false),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Your Contributions'), findsNothing);
      expect(find.text('Next Steps'), findsNothing);
    });

    testWidgets('calls onTap callback when tapped', (WidgetTester tester) async {
      // Arrange
      bool tapped = false;
      final progress = ExpertiseProgress(
        category: 'Coffee',
        currentLevel: ExpertiseLevel.local,
        progressPercentage: 50.0,
        nextLevel: ExpertiseLevel.city,
        location: 'Brooklyn',
        contributionBreakdown: {},
        totalContributions: 0,
        requiredContributions: 0,
        nextSteps: [],
        lastUpdated: DateTime.now(),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseProgressWidget(
          progress: progress,
          onTap: () {
            tapped = true;
          },
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await tester.tap(find.byType(ExpertiseProgressWidget));
      await tester.pumpAndSettle();

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('displays compact version correctly', (WidgetTester tester) async {
      // Arrange
      final progress = ExpertiseProgress(
        category: 'Coffee',
        currentLevel: ExpertiseLevel.local,
        progressPercentage: 50.0,
        nextLevel: ExpertiseLevel.city,
        location: 'Brooklyn',
        contributionBreakdown: {},
        totalContributions: 0,
        requiredContributions: 0,
        nextSteps: [],
        lastUpdated: DateTime.now(),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: CompactExpertiseProgressWidget(progress: progress),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(CompactExpertiseProgressWidget), findsOneWidget);
      expect(find.text('Local'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}

