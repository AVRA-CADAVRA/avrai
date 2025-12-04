import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/ai2ai/evolution_timeline_widget.dart';
import 'package:spots/core/models/personality_profile.dart';
import "../../helpers/widget_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for EvolutionTimelineWidget
/// Tests personality evolution timeline display
void main() {
  group('EvolutionTimelineWidget Widget Tests', () {
    testWidgets('displays evolution timeline with statistics', (WidgetTester tester) async {
      // Arrange
      final profile = PersonalityProfile(
        userId: 'test-user-id',
        dimensions: {},
        dimensionConfidence: {},
        archetype: 'explorer',
        authenticity: 0.75,
        createdAt: TestHelpers.createTestDateTime(),
        lastUpdated: TestHelpers.createTestDateTime(),
        evolutionGeneration: 5,
        learningHistory: {
          'total_interactions': 100,
          'successful_ai2ai_connections': 25,
          'evolution_milestones': [],
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: EvolutionTimelineWidget(profile: profile),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(EvolutionTimelineWidget), findsOneWidget);
      expect(find.text('Evolution Timeline'), findsOneWidget);
      expect(find.text('Generation'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Interactions'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('Connections'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
    });

    testWidgets('displays empty state when no milestones', (WidgetTester tester) async {
      // Arrange
      final profile = PersonalityProfile(
        userId: 'test-user-id',
        dimensions: {},
        dimensionConfidence: {},
        archetype: 'developing',
        authenticity: 0.5,
        createdAt: TestHelpers.createTestDateTime(),
        lastUpdated: TestHelpers.createTestDateTime(),
        evolutionGeneration: 1,
        learningHistory: {
          'total_interactions': 0,
          'successful_ai2ai_connections': 0,
          'evolution_milestones': [],
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: EvolutionTimelineWidget(profile: profile),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('No evolution milestones yet'), findsOneWidget);
      expect(find.text('Milestones will appear as your personality evolves'), findsOneWidget);
      expect(find.byIcon(Icons.timeline), findsOneWidget);
    });

    testWidgets('displays evolution milestones', (WidgetTester tester) async {
      // Arrange
      final milestones = [
        TestHelpers.createTestDateTime().subtract(const Duration(days: 10)),
        TestHelpers.createTestDateTime().subtract(const Duration(days: 5)),
        TestHelpers.createTestDateTime().subtract(const Duration(days: 1)),
      ];

      final profile = PersonalityProfile(
        userId: 'test-user-id',
        dimensions: {},
        dimensionConfidence: {},
        archetype: 'explorer',
        authenticity: 0.8,
        createdAt: TestHelpers.createTestDateTime().subtract(const Duration(days: 30)),
        lastUpdated: TestHelpers.createTestDateTime(),
        evolutionGeneration: 3,
        learningHistory: {
          'total_interactions': 50,
          'successful_ai2ai_connections': 10,
          'evolution_milestones': milestones,
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: EvolutionTimelineWidget(profile: profile),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Evolution Milestone'), findsWidgets);
      expect(find.textContaining('Created:'), findsOneWidget);
      expect(find.textContaining('Last Updated:'), findsOneWidget);
    });

    testWidgets('limits displayed milestones to 10', (WidgetTester tester) async {
      // Arrange
      final milestones = List.generate(15, (index) => 
        TestHelpers.createTestDateTime().subtract(Duration(days: 15 - index))
      );

      final profile = PersonalityProfile(
        userId: 'test-user-id',
        dimensions: {},
        dimensionConfidence: {},
        archetype: 'explorer',
        authenticity: 0.8,
        createdAt: TestHelpers.createTestDateTime().subtract(const Duration(days: 30)),
        lastUpdated: TestHelpers.createTestDateTime(),
        evolutionGeneration: 15,
        learningHistory: {
          'total_interactions': 200,
          'successful_ai2ai_connections': 50,
          'evolution_milestones': milestones,
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: EvolutionTimelineWidget(profile: profile),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Should only show 10 milestones
      expect(find.text('Evolution Milestone'), findsNWidgets(10));
    });

    testWidgets('displays created and updated dates', (WidgetTester tester) async {
      // Arrange
      final createdAt = TestHelpers.createTestDateTime(2025, 1, 1);
      final updatedAt = TestHelpers.createTestDateTime(2025, 1, 15);

      final profile = PersonalityProfile(
        userId: 'test-user-id',
        dimensions: {},
        dimensionConfidence: {},
        archetype: 'explorer',
        authenticity: 0.7,
        createdAt: createdAt,
        lastUpdated: updatedAt,
        evolutionGeneration: 2,
        learningHistory: {
          'total_interactions': 20,
          'successful_ai2ai_connections': 5,
          'evolution_milestones': [],
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: EvolutionTimelineWidget(profile: profile),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.textContaining('Created:'), findsOneWidget);
      expect(find.textContaining('Last Updated:'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.update), findsOneWidget);
    });
  });
}

