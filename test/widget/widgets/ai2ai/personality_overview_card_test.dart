import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/ai2ai/personality_overview_card.dart';
import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/core/constants/vibe_constants.dart';
import "../../helpers/widget_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for PersonalityOverviewCard
/// Tests personality overview display with dimensions, confidence, and archetype
void main() {
  group('PersonalityOverviewCard Widget Tests', () {
    testWidgets('displays personality overview with all dimensions', (WidgetTester tester) async {
      // Arrange
      final profile = PersonalityProfile(
        userId: 'test-user-id',
        dimensions: {
          'adventure': 0.7,
          'social': 0.8,
          'culture': 0.6,
        },
        dimensionConfidence: {
          'adventure': 0.9,
          'social': 0.85,
          'culture': 0.7,
        },
        archetype: 'explorer',
        authenticity: 0.75,
        createdAt: TestHelpers.createTestDateTime(),
        lastUpdated: TestHelpers.createTestDateTime(),
        evolutionGeneration: 3,
        learningHistory: {},
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: PersonalityOverviewCard(profile: profile),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(PersonalityOverviewCard), findsOneWidget);
      expect(find.text('Personality Overview'), findsOneWidget);
      expect(find.text('EXPLORER'), findsOneWidget);
      expect(find.text('Authenticity'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Core Dimensions'), findsOneWidget);
      expect(find.text('Evolution Generation'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('displays dimension bars with correct values', (WidgetTester tester) async {
      // Arrange
      final profile = PersonalityProfile(
        userId: 'test-user-id',
        dimensions: {
          'adventure': 0.7,
          'social': 0.8,
        },
        dimensionConfidence: {
          'adventure': 0.9,
          'social': 0.85,
        },
        archetype: 'explorer',
        authenticity: 0.75,
        createdAt: TestHelpers.createTestDateTime(),
        lastUpdated: TestHelpers.createTestDateTime(),
        evolutionGeneration: 1,
        learningHistory: {},
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: PersonalityOverviewCard(profile: profile),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Check dimension values are displayed
      expect(find.text('70%'), findsWidgets); // adventure dimension
      expect(find.text('80%'), findsWidgets); // social dimension
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('displays authenticity progress bar', (WidgetTester tester) async {
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
        learningHistory: {},
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: PersonalityOverviewCard(profile: profile),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('50%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('handles empty dimensions gracefully', (WidgetTester tester) async {
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
        learningHistory: {},
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: PersonalityOverviewCard(profile: profile),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Widget should still render without errors
      expect(find.byType(PersonalityOverviewCard), findsOneWidget);
      expect(find.text('Personality Overview'), findsOneWidget);
    });
  });
}

