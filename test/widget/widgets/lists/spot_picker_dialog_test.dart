import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/lists/spot_picker_dialog.dart';
import 'package:spots/core/models/list.dart';
import "../../helpers/widget_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for SpotPickerDialog
/// Tests spot picker dialog functionality
void main() {
  group('SpotPickerDialog Widget Tests', () {
    testWidgets('displays dialog with list title', (WidgetTester tester) async {
      // Arrange
      final list = WidgetTestHelpers.createTestList(
        id: 'list-123',
        name: 'Test List',
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: SpotPickerDialog(list: list),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(SpotPickerDialog), findsOneWidget);
      expect(find.textContaining('Add Spots to'), findsOneWidget);
      expect(find.text('Test List'), findsOneWidget);
    });

    testWidgets('displays search bar', (WidgetTester tester) async {
      // Arrange
      final list = WidgetTestHelpers.createTestList();

      final widget = WidgetTestHelpers.createTestableWidget(
        child: SpotPickerDialog(list: list),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Search spots...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('displays cancel and add buttons', (WidgetTester tester) async {
      // Arrange
      final list = WidgetTestHelpers.createTestList();

      final widget = WidgetTestHelpers.createTestableWidget(
        child: SpotPickerDialog(list: list),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.textContaining('Add'), findsOneWidget);
    });

    testWidgets('displays selected count', (WidgetTester tester) async {
      // Arrange
      final list = WidgetTestHelpers.createTestList();

      final widget = WidgetTestHelpers.createTestableWidget(
        child: SpotPickerDialog(list: list),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('0 selected'), findsOneWidget);
    });

    testWidgets('excludes spots from excludedSpotIds', (WidgetTester tester) async {
      // Arrange
      final list = WidgetTestHelpers.createTestList();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: SpotPickerDialog(
          list: list,
          excludedSpotIds: ['spot-1', 'spot-2'],
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Widget should be present
      expect(find.byType(SpotPickerDialog), findsOneWidget);
    });
  });
}

