import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/map/map_view.dart';
import "../../helpers/widget_test_helpers.dart';

/// Widget tests for MapView
/// Tests map view display
void main() {
  group('MapView Widget Tests', () {
    testWidgets('displays map view', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const MapView(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(MapView), findsOneWidget);
    });

    testWidgets('displays map view with app bar when showAppBar is true', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const MapView(
          showAppBar: true,
          appBarTitle: 'Map',
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(MapView), findsOneWidget);
    });

    testWidgets('displays map view without app bar when showAppBar is false', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const MapView(showAppBar: false),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(MapView), findsOneWidget);
    });

    testWidgets('handles initial selected list', (WidgetTester tester) async {
      // Arrange
      final list = WidgetTestHelpers.createTestList();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: MapView(initialSelectedList: list),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(MapView), findsOneWidget);
    });
  });
}

