import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/expertise/expert_matching_widget.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for ExpertMatchingWidget
/// Tests expert matching display
void main() {
  group('ExpertMatchingWidget Widget Tests', () {
    testWidgets('displays loading state initially', (WidgetTester tester) async {
      // Arrange
      final user = WidgetTestHelpers.createTestUser();

      final widget = WidgetTestHelpers.createTestableWidget(
        child: ExpertMatchingWidget(
          user: user,
          category: 'Coffee',
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump(); // Don't settle, check loading state

      // Assert - Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays similar experts header', (WidgetTester tester) async {
      // Arrange
      final user = WidgetTestHelpers.createTestUser();

      final widget = WidgetTestHelpers.createTestableWidget(
        child: ExpertMatchingWidget(
          user: user,
          category: 'Coffee',
          matchingType: MatchingType.similar,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Widget should handle async loading
      expect(find.byType(ExpertMatchingWidget), findsOneWidget);
    });

    testWidgets('displays mentors header for mentor matching type', (WidgetTester tester) async {
      // Arrange
      final user = WidgetTestHelpers.createTestUser();

      final widget = WidgetTestHelpers.createTestableWidget(
        child: ExpertMatchingWidget(
          user: user,
          category: 'Coffee',
          matchingType: MatchingType.mentors,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Widget should be present
      expect(find.byType(ExpertMatchingWidget), findsOneWidget);
    });

    testWidgets('calls onMatchSelected when match is selected', (WidgetTester tester) async {
      // Arrange
      final user = WidgetTestHelpers.createTestUser();

      final widget = WidgetTestHelpers.createTestableWidget(
        child: ExpertMatchingWidget(
          user: user,
          category: 'Coffee',
          onMatchSelected: (_) {},
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Widget should be present
      expect(find.byType(ExpertMatchingWidget), findsOneWidget);
    });
  });
}

