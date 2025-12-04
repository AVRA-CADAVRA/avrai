import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/brand/sponsorable_event_card.dart';
import 'package:spots/core/models/brand_discovery.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for SponsorableEventCard
/// 
/// Agent 2: Phase 7, Section 51-52 - Widget Test Coverage
void main() {
  group('SponsorableEventCard Widget Tests', () {
    testWidgets('displays sponsorable event card', (WidgetTester tester) async {
      // Arrange
      final brandMatch = BrandMatch(
        brandId: 'brand-123',
        brandName: 'Test Brand',
        compatibilityScore: 85.0,
        vibeCompatibility: VibeCompatibility(
          overallScore: 85,
          valueAlignment: 85.0,
          styleCompatibility: 85.0,
          qualityFocus: 85.0,
          audienceAlignment: 85.0,
        ),
        matchReasons: ['High compatibility'],
        metadata: {
          'eventTitle': 'Community Coffee Meetup',
          'eventDate': '2025-12-15',
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: SponsorableEventCard(brandMatch: brandMatch),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(SponsorableEventCard), findsOneWidget);
    });

    testWidgets('displays recommended badge when meets threshold', (WidgetTester tester) async {
      // Arrange
      final brandMatch = BrandMatch(
        brandId: 'brand-123',
        brandName: 'Test Brand',
        compatibilityScore: 85.0,
        vibeCompatibility: VibeCompatibility(
          overallScore: 85,
          valueAlignment: 85.0,
          styleCompatibility: 85.0,
          qualityFocus: 85.0,
          audienceAlignment: 85.0,
        ),
        matchReasons: ['High compatibility'],
        metadata: {
          'eventTitle': 'Community Coffee Meetup',
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: SponsorableEventCard(brandMatch: brandMatch),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Recommended'), findsOneWidget);
    });

    testWidgets('calls onTap callback when card is tapped', (WidgetTester tester) async {
      // Arrange
      bool wasTapped = false;
      final brandMatch = BrandMatch(
        brandId: 'brand-123',
        brandName: 'Test Brand',
        compatibilityScore: 85.0,
        vibeCompatibility: VibeCompatibility(
          overallScore: 85,
          valueAlignment: 85.0,
          styleCompatibility: 85.0,
          qualityFocus: 85.0,
          audienceAlignment: 85.0,
        ),
        matchReasons: ['High compatibility'],
        metadata: {
          'eventTitle': 'Community Coffee Meetup',
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: SponsorableEventCard(
          brandMatch: brandMatch,
          onTap: () => wasTapped = true,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await tester.tap(find.byType(SponsorableEventCard));
      await tester.pump();

      // Assert
      expect(wasTapped, isTrue);
    });
  });
}

