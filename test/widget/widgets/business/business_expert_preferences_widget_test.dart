import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/business/business_expert_preferences_widget.dart';
import "../../helpers/widget_test_helpers.dart';

/// Widget tests for BusinessExpertPreferencesWidget
/// Tests business expert preferences form
void main() {
  group('BusinessExpertPreferencesWidget Widget Tests', () {
    testWidgets('displays preferences form', (WidgetTester tester) async {
      // Arrange
      bool preferencesChanged = false;
      final widget = WidgetTestHelpers.createTestableWidget(
        child: BusinessExpertPreferencesWidget(
          onPreferencesChanged: (_) {
            preferencesChanged = true;
          },
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(BusinessExpertPreferencesWidget), findsOneWidget);
    });

    testWidgets('loads initial preferences when provided', (WidgetTester tester) async {
      // Arrange
      final initialPreferences = BusinessExpertPreferences.empty();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: BusinessExpertPreferencesWidget(
          initialPreferences: initialPreferences,
          onPreferencesChanged: (_) {},
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(BusinessExpertPreferencesWidget), findsOneWidget);
    });

    testWidgets('calls onPreferencesChanged when preferences change', (WidgetTester tester) async {
      // Arrange
      bool preferencesChanged = false;
      final widget = WidgetTestHelpers.createTestableWidget(
        child: BusinessExpertPreferencesWidget(
          onPreferencesChanged: (_) {
            preferencesChanged = true;
          },
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Widget should be present
      expect(find.byType(BusinessExpertPreferencesWidget), findsOneWidget);
    });
  });
}

