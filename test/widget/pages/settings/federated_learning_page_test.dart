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
    setUp(() async {
      await WidgetTestHelpers.initializeTestEnvironment();
    });

    testWidgets('Page renders correctly', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.wrapWithMaterialApp(
          const FederatedLearningPage(),
        ),
      );

      // Verify app bar
      expect(find.text('Federated Learning'), findsOneWidget);
      
      // Verify header
      expect(find.text('Privacy-Preserving AI Training'), findsOneWidget);
      expect(find.text('Help improve AI without sharing your data'), findsOneWidget);
      
      // Verify section headers
      expect(find.text('Settings & Participation'), findsOneWidget);
      expect(find.text('Active Learning Rounds'), findsOneWidget);
      expect(find.text('Your Privacy Metrics'), findsOneWidget);
      expect(find.text('Participation History'), findsOneWidget);
    });

    testWidgets('All 4 widgets are present', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.wrapWithMaterialApp(
          const FederatedLearningPage(),
        ),
      );

      // Verify all 4 widgets are rendered
      expect(find.byType(FederatedLearningSettingsSection), findsOneWidget);
      expect(find.byType(FederatedLearningStatusWidget), findsOneWidget);
      expect(find.byType(PrivacyMetricsWidget), findsOneWidget);
      expect(find.byType(FederatedParticipationHistoryWidget), findsOneWidget);
    });

    testWidgets('Page is scrollable', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.wrapWithMaterialApp(
          const FederatedLearningPage(),
        ),
      );

      // Verify ListView is present
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('Footer information is displayed', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.wrapWithMaterialApp(
          const FederatedLearningPage(),
        ),
      );

      // Scroll to bottom to see footer
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pumpAndSettle();

      // Verify footer content
      expect(find.text('Learn More'), findsOneWidget);
      expect(find.text('Your data never leaves your device'), findsOneWidget);
    });

    test('Page can be instantiated', () {
      const page = FederatedLearningPage();
      expect(page, isA<StatelessWidget>());
    });
  });
}

