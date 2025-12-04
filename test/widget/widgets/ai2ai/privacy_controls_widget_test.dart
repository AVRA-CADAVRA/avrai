import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/ai2ai/privacy_controls_widget.dart';
import "../../helpers/widget_test_helpers.dart';

/// Widget tests for PrivacyControlsWidget
/// Tests privacy controls for AI2AI participation
void main() {
  group('PrivacyControlsWidget Widget Tests', () {
    testWidgets('displays all privacy controls', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const PrivacyControlsWidget(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(PrivacyControlsWidget), findsOneWidget);
      expect(find.text('Privacy Controls'), findsOneWidget);
      expect(find.text('AI2AI Participation'), findsOneWidget);
      expect(find.text('Privacy Level'), findsOneWidget);
      expect(find.text('Share Learning Insights'), findsOneWidget);
    });

    testWidgets('toggles AI2AI participation switch', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const PrivacyControlsWidget(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      
      // Find the switch (should be enabled by default)
      final switchFinder = find.byType(SwitchListTile).first;
      expect(switchFinder, findsOneWidget);
      
      // Tap the switch
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Assert - Switch state should have changed
      final switchWidget = tester.widget<SwitchListTile>(switchFinder);
      expect(switchWidget.value, isFalse);
    });

    testWidgets('displays privacy level dropdown', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const PrivacyControlsWidget(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Maximum'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);
    });

    testWidgets('displays privacy information message', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const PrivacyControlsWidget(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.textContaining('All data is anonymized and privacy-preserving'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('toggles share learning insights switch', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const PrivacyControlsWidget(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      
      // Find the second switch (Share Learning Insights)
      final switches = find.byType(SwitchListTile);
      expect(switches, findsNWidgets(2));
      
      final shareInsightsSwitch = switches.at(1);
      await tester.tap(shareInsightsSwitch);
      await tester.pumpAndSettle();

      // Assert - Switch state should have changed
      final switchWidget = tester.widget<SwitchListTile>(shareInsightsSwitch);
      expect(switchWidget.value, isFalse);
    });
  });
}

