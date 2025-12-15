import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/pages/settings/federated_learning_page.dart';
import 'package:spots/presentation/widgets/settings/federated_learning_settings_section.dart';
import 'package:spots/presentation/widgets/settings/federated_learning_status_widget.dart';
import 'package:spots/presentation/widgets/settings/privacy_metrics_widget.dart';
import 'package:spots/presentation/widgets/settings/federated_participation_history_widget.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  group('FederatedLearningPage Tests', () {
    testWidgets('Page renders correctly', (tester) async {
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const FederatedLearningPage(),
      );
      await tester.pumpWidget(widget);
      await tester.pump();

      // Verify app bar (AppBar title is more specific)
      expect(find.byType(AppBar), findsOneWidget);
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect((appBar.title as Text).data, equals('Federated Learning'));
      
      // Verify header (should be visible immediately)
      expect(find.text('Privacy-Preserving AI Training'), findsOneWidget);
      expect(find.text('Help improve AI without sharing your data'), findsOneWidget);
      
      // Verify first section header (should be visible)
      expect(find.text('Settings & Participation'), findsOneWidget);
      
      // Scroll to bring other sections into view (ListView builds lazily)
      final listView = find.byType(ListView);
      final activeRoundsText = find.text('Active Learning Rounds');
      for (var i = 0; i < 10 && activeRoundsText.evaluate().isEmpty; i++) {
        await tester.drag(listView, const Offset(0, -200));
        await tester.pump();
      }
      expect(activeRoundsText, findsOneWidget);
      
      final privacyMetricsText = find.text('Your Privacy Metrics');
      for (var i = 0; i < 5 && privacyMetricsText.evaluate().isEmpty; i++) {
        await tester.drag(listView, const Offset(0, -200));
        await tester.pump();
      }
      expect(privacyMetricsText, findsOneWidget);
      
      final historyText = find.text('Participation History');
      for (var i = 0; i < 5 && historyText.evaluate().isEmpty; i++) {
        await tester.drag(listView, const Offset(0, -200));
        await tester.pump();
      }
      // Text may appear multiple times (section header + widget title), so just verify it exists
      expect(historyText, findsWidgets);
    });

    testWidgets('All 4 widgets are present', (tester) async {
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const FederatedLearningPage(),
      );
      await tester.pumpWidget(widget);
      await tester.pump();

      // Verify first widget is rendered (should be visible immediately)
      expect(find.byType(FederatedLearningSettingsSection), findsOneWidget);
      
      // Scroll to bring other widgets into view (ListView builds lazily)
      final listView = find.byType(ListView);
      final statusWidget = find.byType(FederatedLearningStatusWidget);
      for (var i = 0; i < 10 && statusWidget.evaluate().isEmpty; i++) {
        await tester.drag(listView, const Offset(0, -200));
        await tester.pump();
      }
      expect(statusWidget, findsOneWidget);
      
      final privacyWidget = find.byType(PrivacyMetricsWidget);
      for (var i = 0; i < 5 && privacyWidget.evaluate().isEmpty; i++) {
        await tester.drag(listView, const Offset(0, -200));
        await tester.pump();
      }
      expect(privacyWidget, findsOneWidget);
      
      final historyWidget = find.byType(FederatedParticipationHistoryWidget);
      for (var i = 0; i < 5 && historyWidget.evaluate().isEmpty; i++) {
        await tester.drag(listView, const Offset(0, -200));
        await tester.pump();
      }
      expect(historyWidget, findsOneWidget);
    });

    testWidgets('Page is scrollable', (tester) async {
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const FederatedLearningPage(),
      );
      await tester.pumpWidget(widget);

      // Verify ListView is present
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('Footer information is displayed', (tester) async {
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const FederatedLearningPage(),
      );
      await tester.pumpWidget(widget);
      await tester.pump();

      // Scroll to footer (ListView builds lazily)
      final listView = find.byType(ListView);
      final learnMoreFinder = find.text('Learn More');
      for (var i = 0; i < 15 && learnMoreFinder.evaluate().isEmpty; i++) {
        await tester.drag(listView, const Offset(0, -200));
        await tester.pump();
      }

      // Verify footer content
      expect(learnMoreFinder, findsOneWidget);
      expect(find.text('Your data never leaves your device'), findsOneWidget);
    });

    test('Page can be instantiated', () {
      const page = FederatedLearningPage();
      expect(page, isA<StatelessWidget>());
    });
  });
}

