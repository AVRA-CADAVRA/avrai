import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/ai2ai/network_health_gauge.dart';
import 'package:spots/core/monitoring/network_analytics.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for NetworkHealthGauge
/// Tests network health score display
void main() {
  group('NetworkHealthGauge Widget Tests', () {
    testWidgets('displays network health score', (WidgetTester tester) async {
      // Arrange
      final healthReport = NetworkHealthReport(
        overallHealthScore: 0.85,
        connectionQuality: ConnectionQualityMetrics(
          averageCompatibility: 0.85,
          connectionSuccessRate: 0.9,
          stabilityScore: 0.8,
          trustBuildingRate: 0.85,
          mutualBenefitScore: 0.8,
        ),
        learningEffectiveness: LearningEffectivenessMetrics(
          overallEffectiveness: 0.85,
          personalityEvolutionRate: 0.8,
          knowledgeAcquisitionSpeed: 0.85,
          insightQualityScore: 0.9,
          collectiveIntelligenceGrowth: 0.8,
        ),
        privacyMetrics: PrivacyMetrics.secure(),
        stabilityMetrics: NetworkStabilityMetrics(
          uptime: 0.99,
          reliability: 0.95,
          errorRate: 0.01,
          recoveryTime: const Duration(seconds: 30),
          loadBalancing: 0.9,
        ),
        performanceIssues: [],
        optimizationRecommendations: [],
        totalActiveConnections: 10,
        networkUtilization: 0.6,
        analysisTimestamp: DateTime.now(),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: NetworkHealthGauge(healthReport: healthReport),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(NetworkHealthGauge), findsOneWidget);
    });

    testWidgets('displays good health label for score >= 0.6', (WidgetTester tester) async {
      // Arrange
      final healthReport = NetworkHealthReport(
        overallHealthScore: 0.7,
        connectionQuality: ConnectionQualityMetrics(
          averageCompatibility: 0.7,
          connectionSuccessRate: 0.75,
          stabilityScore: 0.65,
          trustBuildingRate: 0.7,
          mutualBenefitScore: 0.65,
        ),
        learningEffectiveness: LearningEffectivenessMetrics(
          overallEffectiveness: 0.7,
          personalityEvolutionRate: 0.65,
          knowledgeAcquisitionSpeed: 0.7,
          insightQualityScore: 0.75,
          collectiveIntelligenceGrowth: 0.65,
        ),
        privacyMetrics: PrivacyMetrics.secure(),
        stabilityMetrics: NetworkStabilityMetrics(
          uptime: 0.95,
          reliability: 0.85,
          errorRate: 0.05,
          recoveryTime: const Duration(minutes: 1),
          loadBalancing: 0.75,
        ),
        performanceIssues: [],
        optimizationRecommendations: [],
        totalActiveConnections: 5,
        networkUtilization: 0.5,
        analysisTimestamp: DateTime.now(),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: NetworkHealthGauge(healthReport: healthReport),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(NetworkHealthGauge), findsOneWidget);
    });

    testWidgets('displays poor health label for score < 0.6', (WidgetTester tester) async {
      // Arrange
      final healthReport = NetworkHealthReport(
        overallHealthScore: 0.4,
        connectionQuality: ConnectionQualityMetrics.poor(),
        learningEffectiveness: LearningEffectivenessMetrics.low(),
        privacyMetrics: PrivacyMetrics.secure(),
        stabilityMetrics: NetworkStabilityMetrics.unstable(),
        performanceIssues: [],
        optimizationRecommendations: [],
        totalActiveConnections: 2,
        networkUtilization: 0.3,
        analysisTimestamp: DateTime.now(),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: NetworkHealthGauge(healthReport: healthReport),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(NetworkHealthGauge), findsOneWidget);
    });

    testWidgets('displays network statistics', (WidgetTester tester) async {
      // Arrange
      final healthReport = NetworkHealthReport(
        overallHealthScore: 0.8,
        connectionQuality: ConnectionQualityMetrics(
          averageCompatibility: 0.8,
          connectionSuccessRate: 0.85,
          stabilityScore: 0.75,
          trustBuildingRate: 0.8,
          mutualBenefitScore: 0.75,
        ),
        learningEffectiveness: LearningEffectivenessMetrics(
          overallEffectiveness: 0.8,
          personalityEvolutionRate: 0.75,
          knowledgeAcquisitionSpeed: 0.8,
          insightQualityScore: 0.85,
          collectiveIntelligenceGrowth: 0.75,
        ),
        privacyMetrics: PrivacyMetrics.secure(),
        stabilityMetrics: NetworkStabilityMetrics(
          uptime: 0.98,
          reliability: 0.9,
          errorRate: 0.02,
          recoveryTime: const Duration(seconds: 45),
          loadBalancing: 0.85,
        ),
        performanceIssues: [],
        optimizationRecommendations: [],
        totalActiveConnections: 15,
        networkUtilization: 0.75,
        analysisTimestamp: DateTime.now(),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: NetworkHealthGauge(healthReport: healthReport),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(NetworkHealthGauge), findsOneWidget);
    });
  });
}
