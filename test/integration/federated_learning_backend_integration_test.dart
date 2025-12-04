/// SPOTS Federated Learning Backend Integration Tests
/// Date: November 26, 2025
/// Purpose: Test backend integration for Federated Learning UI widgets
/// 
/// Test Coverage:
/// - FederatedLearningSystem integration (active rounds, participation history)
/// - NetworkAnalytics integration (privacy metrics)
/// - Error handling
/// - Loading states
/// - Offline handling
/// 
/// Dependencies:
/// - FederatedLearningSystem: For learning rounds
/// - NetworkAnalytics: For privacy metrics
/// - Widgets: FederatedLearningStatusWidget, FederatedParticipationHistoryWidget, PrivacyMetricsWidget

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spots/core/p2p/federated_learning.dart';
import 'package:spots/core/monitoring/network_analytics.dart' as analytics;
import 'package:spots/presentation/widgets/settings/federated_learning_status_widget.dart';
import 'package:spots/presentation/widgets/settings/federated_participation_history_widget.dart' as history_widget;
import 'package:spots/presentation/widgets/settings/privacy_metrics_widget.dart';
import '../widget/helpers/widget_test_helpers.dart';

/// Integration tests for Federated Learning backend services
void main() {
  group('Federated Learning Backend Integration Tests', () {
    late FederatedLearningSystem federatedLearningSystem;
    late analytics.NetworkAnalytics networkAnalytics;
    late SharedPreferences prefs;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    setUp(() {
      federatedLearningSystem = FederatedLearningSystem();
      networkAnalytics = analytics.NetworkAnalytics(prefs: prefs);
    });

    group('FederatedLearningSystem Integration', () {
      test('should initialize learning system', () {
        expect(federatedLearningSystem, isNotNull);
      });

      test('should create learning round with valid parameters', () async {
        // Arrange
        final objective = LearningObjective(
          name: 'Test Recommendation',
          description: 'Test objective',
          type: LearningType.recommendation,
          parameters: {},
        );
        final participants = ['node_1', 'node_2', 'node_3'];

        // Act
        final round = await federatedLearningSystem.initializeLearningRound(
          'test_org',
          objective,
          participants,
        );

        // Assert
        expect(round, isNotNull);
        expect(round.roundId, isNotEmpty);
        expect(round.participantNodeIds, hasLength(3));
        expect(round.status, RoundStatus.training);
        expect(round.objective.name, 'Test Recommendation');
      });

      test('should throw exception with insufficient participants', () async {
        // Arrange
        final objective = LearningObjective(
          name: 'Test',
          description: 'Test',
          type: LearningType.recommendation,
          parameters: {},
        );
        final participants = ['node_1']; // Less than minimum (3)

        // Act & Assert
        expect(
          () => federatedLearningSystem.initializeLearningRound(
            'test_org',
            objective,
            participants,
          ),
          throwsA(isA<FederatedLearningException>()),
        );
      });

      test('should train local model with privacy preservation', () async {
        // Arrange
        final objective = LearningObjective(
          name: 'Test',
          description: 'Test',
          type: LearningType.recommendation,
          parameters: {},
        );
        final round = await federatedLearningSystem.initializeLearningRound(
          'test_org',
          objective,
          ['node_1', 'node_2', 'node_3'],
        );
        final trainingData = LocalTrainingData(
          sampleCount: 100,
          features: {'feature1': 1.0, 'feature2': 2.0},
          containsPersonalIdentifiers: false,
        );

        // Act
        final update = await federatedLearningSystem.trainLocalModel(
          'node_1',
          round,
          trainingData,
        );

        // Assert
        expect(update, isNotNull);
        expect(update.nodeId, 'node_1');
        expect(update.roundId, round.roundId);
        expect(update.privacyCompliant, isTrue);
        expect(update.trainingMetrics.privacyBudgetUsed, greaterThan(0.0));
      });

      test('should aggregate model updates', () async {
        // Arrange
        final objective = LearningObjective(
          name: 'Test',
          description: 'Test',
          type: LearningType.recommendation,
          parameters: {},
        );
        final round = await federatedLearningSystem.initializeLearningRound(
          'test_org',
          objective,
          ['node_1', 'node_2', 'node_3'],
        );
        final trainingData = LocalTrainingData(
          sampleCount: 100,
          features: {'feature1': 1.0},
          containsPersonalIdentifiers: false,
        );
        final updates = [
          await federatedLearningSystem.trainLocalModel(
            'node_1',
            round,
            trainingData,
          ),
          await federatedLearningSystem.trainLocalModel(
            'node_2',
            round,
            trainingData,
          ),
        ];

        // Act
        final globalUpdate = await federatedLearningSystem.aggregateModelUpdates(
          round,
          updates,
        );

        // Assert
        expect(globalUpdate, isNotNull);
        expect(globalUpdate.roundId, round.roundId);
        expect(globalUpdate.participantCount, 2);
        expect(globalUpdate.privacyPreserved, isTrue);
        expect(globalUpdate.convergenceMetrics, isNotNull);
      });
    });

    group('NetworkAnalytics Integration', () {
      test('should initialize network analytics', () {
        expect(networkAnalytics, isNotNull);
      });

      test('should collect real-time metrics', () async {
        // Act
        final metrics = await networkAnalytics.collectRealTimeMetrics();

        // Assert
        expect(metrics, isNotNull);
        expect(metrics.connectionThroughput, greaterThanOrEqualTo(0.0));
        expect(metrics.matchingSuccessRate, greaterThanOrEqualTo(0.0));
        expect(metrics.matchingSuccessRate, lessThanOrEqualTo(1.0));
      });

      test('should generate analytics dashboard', () async {
        // Act
        final dashboard = await networkAnalytics.generateAnalyticsDashboard(
          const Duration(days: 7),
        );

        // Assert
        expect(dashboard, isNotNull);
        expect(dashboard.timeWindow, const Duration(days: 7));
        expect(dashboard.generatedAt, isNotNull);
        expect(dashboard.privacyPreservationStats, isNotNull);
      });

      test('should analyze network health', () async {
        // Act
        final healthReport = await networkAnalytics.analyzeNetworkHealth();

        // Assert
        expect(healthReport, isNotNull);
        expect(healthReport.overallHealthScore, greaterThanOrEqualTo(0.0));
        expect(healthReport.overallHealthScore, lessThanOrEqualTo(1.0));
        expect(healthReport.privacyMetrics, isNotNull);
      });
    });

    group('Widget Backend Integration', () {
      testWidgets('FederatedLearningStatusWidget should display active rounds', (WidgetTester tester) async {
        // Arrange
        final objective = LearningObjective(
          name: 'Recommendation',
          description: 'Test',
          type: LearningType.recommendation,
          parameters: {},
        );
        final round = await federatedLearningSystem.initializeLearningRound(
          'test_org',
          objective,
          ['node_1', 'node_2', 'node_3'],
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
        expect(find.byType(FederatedLearningStatusWidget), findsOneWidget);
        expect(find.textContaining('Round'), findsWidgets);
        expect(find.textContaining('Training'), findsOneWidget);
      });

      testWidgets('FederatedParticipationHistoryWidget should display history', (WidgetTester tester) async {
        // Arrange
        final history = history_widget.ParticipationHistory(
          totalRoundsParticipated: 10,
          completedRounds: 8,
          totalContributions: 40,
          benefitsEarned: ['Improved Recommendations'],
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
        expect(find.byType(history_widget.FederatedParticipationHistoryWidget), findsOneWidget);
        expect(find.textContaining('10'), findsOneWidget);
        expect(find.textContaining('Total Rounds'), findsOneWidget);
      });

      testWidgets('PrivacyMetricsWidget should display metrics', (WidgetTester tester) async {
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
        expect(find.byType(PrivacyMetricsWidget), findsOneWidget);
        expect(find.textContaining('Privacy'), findsWidgets);
        expect(find.textContaining('98'), findsWidgets);
      });
    });

    group('Error Handling', () {
      test('should handle training data with personal identifiers', () async {
        // Arrange
        final objective = LearningObjective(
          name: 'Test',
          description: 'Test',
          type: LearningType.recommendation,
          parameters: {},
        );
        final round = await federatedLearningSystem.initializeLearningRound(
          'test_org',
          objective,
          ['node_1', 'node_2', 'node_3'],
        );
        final trainingData = LocalTrainingData(
          sampleCount: 100,
          features: {'name': 'John Doe'}, // Personal identifier
          containsPersonalIdentifiers: true,
        );

        // Act & Assert
        expect(
          () => federatedLearningSystem.trainLocalModel(
            'node_1',
            round,
            trainingData,
          ),
          throwsA(isA<FederatedLearningException>()),
        );
      });

      test('should handle non-privacy-compliant updates', () async {
        // Arrange
        final objective = LearningObjective(
          name: 'Test',
          description: 'Test',
          type: LearningType.recommendation,
          parameters: {},
        );
        final round = await federatedLearningSystem.initializeLearningRound(
          'test_org',
          objective,
          ['node_1', 'node_2', 'node_3'],
        );
        final nonCompliantUpdate = LocalModelUpdate(
          nodeId: 'node_1',
          roundId: round.roundId,
          gradients: {},
          trainingMetrics: TrainingMetrics(
            samplesUsed: 100,
            trainingLoss: 0.5,
            accuracy: 0.75,
            privacyBudgetUsed: 0.1,
          ),
          timestamp: DateTime.now(),
          privacyCompliant: false, // Non-compliant
        );

        // Act & Assert
        expect(
          () => federatedLearningSystem.aggregateModelUpdates(
            round,
            [nonCompliantUpdate],
          ),
          throwsA(isA<FederatedLearningException>()),
        );
      });
    });

    group('Loading States', () {
      testWidgets('FederatedLearningStatusWidget should handle empty rounds', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const FederatedLearningStatusWidget(
            activeRounds: [],
          ),
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert
        expect(find.byType(FederatedLearningStatusWidget), findsOneWidget);
        expect(find.textContaining('No active'), findsOneWidget);
      });

      testWidgets('FederatedParticipationHistoryWidget should handle null history', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const history_widget.FederatedParticipationHistoryWidget(
            participationHistory: null,
          ),
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert
        expect(find.byType(history_widget.FederatedParticipationHistoryWidget), findsOneWidget);
        expect(find.textContaining('No participation'), findsOneWidget);
      });
    });
  });
}

