import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/brand/sponsorship_revenue_split_display.dart';
import 'package:spots/core/models/revenue_split.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for SponsorshipRevenueSplitDisplay
/// 
/// Agent 2: Phase 7, Section 51-52 - Widget Test Coverage
void main() {
  group('SponsorshipRevenueSplitDisplay Widget Tests', () {
    testWidgets('displays revenue split with sponsorship', (WidgetTester tester) async {
      // Arrange
      final revenueSplit = RevenueSplit(
        id: 'split-123',
        eventId: 'event-456',
        totalAmount: 1000.0,
        platformFee: 100.0,
        processingFee: 30.0,
        hostPayout: 870.0,
        parties: [],
        isLocked: false,
        calculatedAt: DateTime.now(),
        ticketsSold: 20,
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: SponsorshipRevenueSplitDisplay(
          split: revenueSplit,
          sponsorshipContribution: 200.0,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(SponsorshipRevenueSplitDisplay), findsOneWidget);
      expect(find.text('Revenue Breakdown (with Sponsorship)'), findsOneWidget);
    });

    testWidgets('displays total revenue', (WidgetTester tester) async {
      // Arrange
      final revenueSplit = RevenueSplit(
        id: 'split-123',
        eventId: 'event-456',
        totalAmount: 1000.0,
        platformFee: 100.0,
        processingFee: 30.0,
        hostPayout: 870.0,
        parties: [],
        isLocked: false,
        calculatedAt: DateTime.now(),
        ticketsSold: 20,
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: SponsorshipRevenueSplitDisplay(
          split: revenueSplit,
          sponsorshipContribution: 200.0,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Total Revenue'), findsOneWidget);
    });

    testWidgets('displays sponsorship contribution', (WidgetTester tester) async {
      // Arrange
      final revenueSplit = RevenueSplit(
        id: 'split-123',
        eventId: 'event-456',
        totalAmount: 1000.0,
        platformFee: 100.0,
        processingFee: 30.0,
        hostPayout: 870.0,
        parties: [],
        isLocked: false,
        calculatedAt: DateTime.now(),
        ticketsSold: 20,
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: SponsorshipRevenueSplitDisplay(
          split: revenueSplit,
          sponsorshipContribution: 200.0,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(SponsorshipRevenueSplitDisplay), findsOneWidget);
    });
  });
}

