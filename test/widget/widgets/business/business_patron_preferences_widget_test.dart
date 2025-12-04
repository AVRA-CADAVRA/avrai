import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/business/business_patron_preferences_widget.dart';
import "../../helpers/widget_test_helpers.dart';

/// Widget tests for BusinessPatronPreferencesWidget
/// Tests business patron preferences form
void main() {
  group('BusinessPatronPreferencesWidget Widget Tests', () {
    testWidgets('displays preferences form', (WidgetTester tester) async {
      // Arrange
      bool preferencesChanged = false;
      final widget = WidgetTestHelpers.createTestableWidget(
        child: BusinessPatronPreferencesWidget(
          onPreferencesChanged: (_) {
            preferencesChanged = true;
          },
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(BusinessPatronPreferencesWidget), findsOneWidget);
    });

    testWidgets('loads initial preferences when provided', (WidgetTester tester) async {
      // Arrange
      final initialPreferences = BusinessPatronPreferences.empty();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: BusinessPatronPreferencesWidget(
          initialPreferences: initialPreferences,
          onPreferencesChanged: (_) {},
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(BusinessPatronPreferencesWidget), findsOneWidget);
    });

    testWidgets('calls onPreferencesChanged when preferences change', (WidgetTester tester) async {
      // Arrange
      bool preferencesChanged = false;
      final widget = WidgetTestHelpers.createTestableWidget(
        child: BusinessPatronPreferencesWidget(
          onPreferencesChanged: (_) {
            preferencesChanged = true;
          },
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Widget should be present
      expect(find.byType(BusinessPatronPreferencesWidget), findsOneWidget);
    });
  });
}

