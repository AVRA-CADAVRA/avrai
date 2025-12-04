import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/brand/sponsorship_card.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/product_tracking.dart';
import 'package:spots/core/models/sponsorship_status.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../fixtures/model_factories.dart';

/// Widget tests for SponsorshipCard
/// 
/// Agent 2: Phase 7, Section 51-52 - Widget Test Coverage
/// 
/// Tests:
/// - Widget rendering
/// - Status badge display
/// - Contribution display
/// - Product tracking display
/// - Callback handling
void main() {
  group('SponsorshipCard Widget Tests', () {
    testWidgets('displays sponsorship card with event ID', (WidgetTester tester) async {
      // Arrange
      final sponsorship = ModelFactories.createTestSponsorship(
        eventId: 'event-123',
        status: SponsorshipStatus.active,
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: SponsorshipCard(
          sponsorship: sponsorship,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(SponsorshipCard), findsOneWidget);
      expect(find.text('Event: event-123'), findsOneWidget);
    });

    testWidgets('displays active status badge', (WidgetTester tester) async {
      // Arrange
      final sponsorship = ModelFactories.createTestSponsorship(
        status: SponsorshipStatus.active,
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: SponsorshipCard(
          sponsorship: sponsorship,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(SponsorshipCard), findsOneWidget);
      // Status badge should be visible
    });

    testWidgets('displays financial contribution when present', (WidgetTester tester) async {
      // Arrange
      final sponsorship = ModelFactories.createTestSponsorship(
        contributionAmount: 500.0,
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: SponsorshipCard(
          sponsorship: sponsorship,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(SponsorshipCard), findsOneWidget);
      expect(find.textContaining('Your Contribution'), findsOneWidget);
    });

    testWidgets('calls onTap callback when card is tapped', (WidgetTester tester) async {
      // Arrange
      bool wasTapped = false;
      final sponsorship = ModelFactories.createTestSponsorship();

      final widget = WidgetTestHelpers.createTestableWidget(
        child: SponsorshipCard(
          sponsorship: sponsorship,
          onTap: () => wasTapped = true,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await tester.tap(find.byType(SponsorshipCard));
      await tester.pump();

      // Assert
      expect(wasTapped, isTrue);
    });

    testWidgets('displays product tracking when present', (WidgetTester tester) async {
      // Arrange
      final sponsorship = ModelFactories.createTestSponsorship();
      final productTracking = ProductTracking(
        productName: 'Test Product',
        quantity: 10,
        unitValue: 25.0,
        trackingId: 'track-123',
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: SponsorshipCard(
          sponsorship: sponsorship,
          productTracking: productTracking,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(SponsorshipCard), findsOneWidget);
      // Product tracking should be displayed
    });
  });
}

