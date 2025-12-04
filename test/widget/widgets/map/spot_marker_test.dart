import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/map/spot_marker.dart';
import 'package:spots/core/theme/colors.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../fixtures/model_factories.dart';

/// Widget tests for SpotMarker
/// Tests map marker display and interactions
void main() {
  group('SpotMarker Widget Tests', () {
    testWidgets('displays marker with correct color', (WidgetTester tester) async {
      // Arrange
      final testSpot = ModelFactories.createTestSpot(
        id: 'spot-123',
        category: 'Coffee',
      );
      final widget = WidgetTestHelpers.createTestableWidget(
        child: SpotMarker(
          spot: testSpot,
          color: AppColors.electricGreen,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Should show marker
      expect(find.byType(SpotMarker), findsOneWidget);
    });

    testWidgets('displays category icon', (WidgetTester tester) async {
      // Arrange
      final testSpot = ModelFactories.createTestSpot(
        id: 'spot-123',
        category: 'Coffee',
      );
      final widget = WidgetTestHelpers.createTestableWidget(
        child: SpotMarker(
          spot: testSpot,
          color: AppColors.electricGreen,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Should show category icon
      expect(find.byIcon(Icons.coffee), findsOneWidget);
    });

    testWidgets('calls onTap callback when tapped', (WidgetTester tester) async {
      // Arrange
      bool wasTapped = false;
      final testSpot = ModelFactories.createTestSpot(id: 'spot-123');
      final widget = WidgetTestHelpers.createTestableWidget(
        child: SpotMarker(
          spot: testSpot,
          color: AppColors.electricGreen,
          onTap: () => wasTapped = true,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await tester.tap(find.byType(SpotMarker));
      await tester.pump();

      // Assert - Callback should be called
      expect(wasTapped, isTrue);
    });
  });
}

