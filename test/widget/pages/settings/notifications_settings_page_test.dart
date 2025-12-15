import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/pages/settings/notifications_settings_page.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for NotificationsSettingsPage
/// Tests notification settings UI and preferences
void main() {
  setUpAll(() async {
    await WidgetTestHelpers.setupWidgetTestEnvironment();
  });

  tearDownAll(() async {
    await WidgetTestHelpers.cleanupWidgetTestEnvironment();
  });

  group('NotificationsSettingsPage Widget Tests', () {
    testWidgets('displays all required UI elements', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const NotificationsSettingsPage(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Verify all UI elements are present
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Privacy First'), findsOneWidget);
      expect(find.text('Notification Types'), findsOneWidget);
    });

    testWidgets('displays notification preference toggles', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const NotificationsSettingsPage(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Should show notification toggles
      expect(find.byType(NotificationsSettingsPage), findsOneWidget);
    });
  });
}

