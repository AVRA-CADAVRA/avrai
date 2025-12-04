import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/brand/brand_stats_card.dart';
import 'package:spots/core/theme/colors.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for BrandStatsCard
/// 
/// Agent 2: Phase 7, Section 51-52 - Widget Test Coverage
/// 
/// Tests:
/// - Widget rendering
/// - Label and value display
/// - Icon display
/// - Color customization
void main() {
  group('BrandStatsCard Widget Tests', () {
    testWidgets('displays brand stats card with label and value', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const BrandStatsCard(
          label: 'Total Investment',
          value: '\$10,000',
          icon: Icons.attach_money,
          color: AppColors.electricGreen,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(BrandStatsCard), findsOneWidget);
      expect(find.text('Total Investment'), findsOneWidget);
      expect(find.text('\$10,000'), findsOneWidget);
    });

    testWidgets('displays icon correctly', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const BrandStatsCard(
          label: 'ROI',
          value: '50%',
          icon: Icons.trending_up,
          color: AppColors.electricGreen,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('displays with custom color', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const BrandStatsCard(
          label: 'Revenue',
          value: '\$15,000',
          icon: Icons.monetization_on,
          color: AppColors.electricGreen,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(BrandStatsCard), findsOneWidget);
      expect(find.text('Revenue'), findsOneWidget);
      expect(find.text('\$15,000'), findsOneWidget);
    });

    testWidgets('displays different metrics correctly', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const BrandStatsCard(
          label: 'Active Sponsorships',
          value: '5',
          icon: Icons.event,
          color: AppColors.grey600,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Active Sponsorships'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });
  });
}

