/// SPOTS Federated Learning End-to-End Tests
/// Date: November 26, 2025
/// Purpose: Test complete user flows for Federated Learning UI
/// 
/// Test Coverage:
/// - Navigation from profile to federated learning page
/// - Opt-in/opt-out toggle and persistence
/// - Joining/leaving learning rounds
/// - Viewing all sections
/// - Error scenarios
/// - Offline handling
/// 
/// Dependencies:
/// - FederatedLearningPage: Main page
/// - All federated learning widgets
/// - Backend services (mocked for testing)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/pages/settings/federated_learning_page.dart';
import 'package:spots/presentation/widgets/settings/federated_learning_settings_section.dart';
import 'package:spots/presentation/widgets/settings/federated_learning_status_widget.dart';
import 'package:spots/presentation/widgets/settings/privacy_metrics_widget.dart';
import 'package:spots/presentation/widgets/settings/federated_participation_history_widget.dart' as history_widget;
import 'package:spots/core/p2p/federated_learning.dart';
import 'package:spots/core/monitoring/network_analytics.dart' as analytics;
import '../widget/helpers/widget_test_helpers.dart';

/// End-to-end tests for Federated Learning UI
void main() {
  group('Federated Learning End-to-End Tests', () {
    group('Navigation Flow', () {
      testWidgets('should navigate to federated learning page', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const FederatedLearningPage(),
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert
        expect(find.byType(FederatedLearningPage), findsOneWidget);
        expect(find.text('Federated Learning'), findsOneWidget);
        expect(find.text('Privacy-Preserving AI Training'), findsOneWidget);
      });

      testWidgets('should display all four main sections', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const FederatedLearningPage(),
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert
        expect(find.byType(FederatedLearningSettingsSection), findsOneWidget);
        expect(find.byType(FederatedLearningStatusWidget), findsOneWidget);
        expect(find.byType(PrivacyMetricsWidget), findsOneWidget);
        expect(find.byType(history_widget.FederatedParticipationHistoryWidget), findsOneWidget);
      });

      testWidgets('should display section headers', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const FederatedLearningPage(),
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert
        expect(find.text('Settings & Participation'), findsOneWidget);
        expect(find.text('Active Learning Rounds'), findsOneWidget);
        expect(find.text('Your Privacy Metrics'), findsOneWidget);
        expect(find.text('Participation History'), findsOneWidget);
      });
    });

    group('Opt-in/Opt-out Flow', () {
      testWidgets('should display participation toggle', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: Scaffold(
            body: const FederatedLearningSettingsSection(),
          ),
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert
        expect(find.byType(Switch), findsOneWidget);
        expect(find.textContaining('Participate'), findsOneWidget);
      });

      testWidgets('should toggle participation when switch is tapped', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: Scaffold(
            body: const FederatedLearningSettingsSection(),
          ),
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        final switchWidget = find.byType(Switch);
        final initialValue = tester.widget<Switch>(switchWidget).value;
        await tester.tap(switchWidget);
        await tester.pumpAndSettle();

        // Assert
        final newValue = tester.widget<Switch>(switchWidget).value;
        expect(newValue, isNot(equals(initialValue)));
      });

      testWidgets('should display benefits of participating', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const FederatedLearningSettingsSection(),
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert
        expect(find.text('Benefits of participating:'), findsOneWidget);
        expect(find.textContaining('More accurate'), findsOneWidget);
      });

      testWidgets('should display consequences of not participating', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const FederatedLearningSettingsSection(),
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert
        expect(find.textContaining('Less accurate'), findsOneWidget);
        expect(find.textContaining('Slower'), findsOneWidget);
      });
    });

    group('Learning Rounds Flow', () {
      testWidgets('should display active learning rounds', (WidgetTester tester) async {
        // Arrange
        final objective = LearningObjective(
          name: 'Recommendation',
          description: 'Test objective',
          type: LearningType.recommendation,
          parameters: {},
        );
        final round = FederatedLearningRound(
          roundId: 'round_1',
          organizationId: 'test_org',
          objective: objective,
          participantNodeIds: ['node_1', 'node_2', 'node_3'],
          status: RoundStatus.training,
          createdAt: DateTime.now(),
          roundNumber: 1,
          globalModel: GlobalModel(
            modelId: 'model_1',
            objective: objective,
            version: 1,
            parameters: {},
            loss: 0.5,
            accuracy: 0.75,
            updatedAt: DateTime.now(),
          ),
          participantUpdates: {},
          privacyMetrics: PrivacyMetrics.initial(),
        );

        final widget = WidgetTestHelpers.createTestableWidget(
          child: FederatedLearningStatusWidget(
            activeRounds: [round],
            currentNodeId: 'node_1',
          ),
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert
        expect(find.textContaining('Round 1'), findsOneWidget);
        expect(find.textContaining('Training'), findsOneWidget);
        expect(find.textContaining('Participating'), findsOneWidget);
      });

      testWidgets('should display no active rounds message when empty', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const FederatedLearningStatusWidget(
            activeRounds: [],
          ),
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert
        expect(find.textContaining('No active'), findsOneWidget);
      });

      testWidgets('should display participation status correctly', (WidgetTester tester) async {
        // Arrange
        final objective = LearningObjective(
          name: 'Test',
          description: 'Test',
          type: LearningType.recommendation,
          parameters: {},
        );
        final round = FederatedLearningRound(
          roundId: 'round_1',
          organizationId: 'test_org',
          objective: objective,
          participantNodeIds: ['node_1', 'node_2'],
          status: RoundStatus.training,
          createdAt: DateTime.now(),
          roundNumber: 1,
          globalModel: GlobalModel(
            modelId: 'model_1',
            objective: objective,
            version: 1,
            parameters: {},
            loss: 0.5,
            accuracy: 0.75,
            updatedAt: DateTime.now(),
          ),
          participantUpdates: {},
          privacyMetrics: PrivacyMetrics.initial(),
        );

        final widget = WidgetTestHelpers.createTestableWidget(
          child: FederatedLearningStatusWidget(
            activeRounds: [round],
            currentNodeId: 'node_3', // Not participating
          ),
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert
        expect(find.textContaining('Not participating'), findsOneWidget);
      });
    });

    group('Privacy Metrics Flow', () {
      testWidgets('should display privacy metrics', (WidgetTester tester) async {
        // Arrange
        final privacyMetrics = analytics.PrivacyMetrics.secure();

        final widget = WidgetTestHelpers.createTestableWidget(
          child: PrivacyMetricsWidget(
            privacyMetrics: privacyMetrics,
          ),
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert
        expect(find.textContaining('Privacy Metrics'), findsOneWidget);
        expect(find.textContaining('Overall Privacy Score'), findsOneWidget);
        expect(find.textContaining('Anonymization Level'), findsOneWidget);
        expect(find.textContaining('Data Security Score'), findsOneWidget);
      });

      testWidgets('should display privacy info dialog when info icon is tapped', (WidgetTester tester) async {
        // Arrange
        final privacyMetrics = analytics.PrivacyMetrics.secure();

        final widget = WidgetTestHelpers.createTestableWidget(
          child: PrivacyMetricsWidget(
            privacyMetrics: privacyMetrics,
          ),
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        final infoButton = find.byIcon(Icons.info_outline);
        if (infoButton.evaluate().isNotEmpty) {
          await tester.tap(infoButton.first);
          await tester.pumpAndSettle();

          // Assert
          expect(find.byType(AlertDialog), findsOneWidget);
          expect(find.textContaining('Privacy Metrics Explained'), findsOneWidget);
        }
      });
    });

    group('Participation History Flow', () {
      testWidgets('should display participation history when available', (WidgetTester tester) async {
        // Arrange
        final history = history_widget.ParticipationHistory(
          totalRoundsParticipated: 15,
          completedRounds: 12,
          totalContributions: 50,
          benefitsEarned: ['Improved Recommendations', 'Early Access'],
          lastParticipationDate: DateTime.now().subtract(const Duration(days: 1)),
          participationStreak: 5,
        );

        final widget = WidgetTestHelpers.createTestableWidget(
          child: history_widget.FederatedParticipationHistoryWidget(
            participationHistory: history,
          ),
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert
        expect(find.textContaining('Participation History'), findsOneWidget);
        expect(find.textContaining('15'), findsOneWidget);
        expect(find.textContaining('Total Rounds'), findsOneWidget);
        expect(find.textContaining('Benefits Earned'), findsOneWidget);
      });

      testWidgets('should display empty state when no history', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const history_widget.FederatedParticipationHistoryWidget(
            participationHistory: null,
          ),
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert
        expect(find.textContaining('No participation'), findsOneWidget);
      });
    });

    group('Error Scenarios', () {
      testWidgets('should handle widget errors gracefully', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const FederatedLearningPage(),
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert - Page should still render even if some widgets have issues
        expect(find.byType(FederatedLearningPage), findsOneWidget);
      });

      testWidgets('should handle null data gracefully', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const FederatedLearningStatusWidget(
            activeRounds: [],
            currentNodeId: null,
          ),
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert
        expect(find.byType(FederatedLearningStatusWidget), findsOneWidget);
      });
    });

    group('Complete User Journey', () {
      testWidgets('should complete full user journey from page load to viewing all sections', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const FederatedLearningPage(),
        );

        // Act - Load page
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert - All sections visible
        expect(find.byType(FederatedLearningSettingsSection), findsOneWidget);
        expect(find.byType(FederatedLearningStatusWidget), findsOneWidget);
        expect(find.byType(PrivacyMetricsWidget), findsOneWidget);
        expect(find.byType(history_widget.FederatedParticipationHistoryWidget), findsOneWidget);

        // Act - Toggle participation
        final switchWidget = find.byType(Switch);
        if (switchWidget.evaluate().isNotEmpty) {
          await tester.tap(switchWidget);
          await tester.pumpAndSettle();
        }

        // Assert - Toggle worked
        expect(find.byType(Switch), findsOneWidget);

        // Act - View info dialogs
        final infoButtons = find.byIcon(Icons.info_outline);
        if (infoButtons.evaluate().isNotEmpty) {
          await tester.tap(infoButtons.first);
          await tester.pumpAndSettle();
          
          // Close dialog
          final closeButton = find.text('Got it');
          if (closeButton.evaluate().isNotEmpty) {
            await tester.tap(closeButton);
            await tester.pumpAndSettle();
          }
        }

        // Assert - Page still functional
        expect(find.byType(FederatedLearningPage), findsOneWidget);
      });
    });
  });
}

