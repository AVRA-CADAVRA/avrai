import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/monitoring/network_analytics.dart' as analytics;
import 'package:spots/core/monitoring/connection_monitor.dart';
import 'package:spots/core/models/connection_metrics.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase 4: Network Monitoring Test
/// OUR_GUTS.md: "Validation of AI2AI personality network monitoring and analytics systems"
void main() {
  group('Phase 4: Network Monitoring Tests', () {
    late SharedPreferences mockPrefs;
    
    setUpAll(() async {
      // Initialize mock shared preferences
      SharedPreferences.setMockInitialValues({});
      mockPrefs = await SharedPreferences.getInstance();
    });
    
    group('Network Analytics System', () {
      test('should create NetworkAnalytics successfully', () {
        final analyticsSystem = analytics.NetworkAnalytics(prefs: mockPrefs);
        
        expect(analyticsSystem, isNotNull);
      });
      
      test('should analyze network health and generate report', () async {
        final analyticsSystem = analytics.NetworkAnalytics(prefs: mockPrefs);
        
        final healthReport = await analyticsSystem.analyzeNetworkHealth();
        
        expect(healthReport.overallHealthScore, greaterThanOrEqualTo(0.0));
        expect(healthReport.overallHealthScore, lessThanOrEqualTo(1.0));
        expect(healthReport.connectionQuality, isNotNull);
        expect(healthReport.learningEffectiveness, isNotNull);
        expect(healthReport.privacyMetrics, isNotNull);
        expect(healthReport.stabilityMetrics, isNotNull);
        expect(healthReport.performanceIssues, isA<List>());
        expect(healthReport.optimizationRecommendations, isA<List>());
        expect(healthReport.totalActiveConnections, greaterThanOrEqualTo(0));
        expect(healthReport.networkUtilization, greaterThanOrEqualTo(0.0));
        expect(healthReport.networkUtilization, lessThanOrEqualTo(1.0));
        expect(healthReport.analysisTimestamp, isNotNull);
      });
      
      test('should collect real-time network metrics', () async {
        final analyticsSystem = analytics.NetworkAnalytics(prefs: mockPrefs);
        
        final realTimeMetrics = await analyticsSystem.collectRealTimeMetrics();
        
        expect(realTimeMetrics.connectionThroughput, greaterThanOrEqualTo(0.0));
        expect(realTimeMetrics.matchingSuccessRate, greaterThanOrEqualTo(0.0));
        expect(realTimeMetrics.matchingSuccessRate, lessThanOrEqualTo(1.0));
        expect(realTimeMetrics.learningConvergenceSpeed, greaterThanOrEqualTo(0.0));
        expect(realTimeMetrics.learningConvergenceSpeed, lessThanOrEqualTo(1.0));
        expect(realTimeMetrics.vibeSynchronizationQuality, greaterThanOrEqualTo(0.0));
        expect(realTimeMetrics.vibeSynchronizationQuality, lessThanOrEqualTo(1.0));
        expect(realTimeMetrics.networkResponsiveness, greaterThanOrEqualTo(0.0));
        expect(realTimeMetrics.networkResponsiveness, lessThanOrEqualTo(1.0));
        expect(realTimeMetrics.resourceUtilization, isNotNull);
        expect(realTimeMetrics.timestamp, isNotNull);
      });
      
      test('should generate comprehensive analytics dashboard', () async {
        final analyticsSystem = analytics.NetworkAnalytics(prefs: mockPrefs);
        
        final dashboard = await analyticsSystem.generateAnalyticsDashboard(Duration(days: 7));
        
        expect(dashboard.timeWindow, equals(Duration(days: 7)));
        expect(dashboard.performanceTrends, isA<List>());
        expect(dashboard.evolutionStatistics, isNotNull);
        expect(dashboard.connectionPatterns, isA<List>());
        expect(dashboard.learningDistribution, isNotNull);
        expect(dashboard.privacyPreservationStats, isNotNull);
        expect(dashboard.usageAnalytics, isNotNull);
        expect(dashboard.networkGrowthMetrics, isNotNull);
        expect(dashboard.topPerformingArchetypes, isA<List<String>>());
        expect(dashboard.generatedAt, isNotNull);
      });
      
      test('should detect network anomalies', () async {
        final analyticsSystem = analytics.NetworkAnalytics(prefs: mockPrefs);
        
        final anomalies = await analyticsSystem.detectNetworkAnomalies();
        
        expect(anomalies, isA<List<analytics.NetworkAnomaly>>());
        // Anomalies list can be empty if no anomalies are detected
        for (final anomaly in anomalies) {
          expect(anomaly.type, isA<analytics.AnomalyType>());
          expect(anomaly.severity, isA<analytics.IssueSeverity>());
          expect(anomaly.description, isNotEmpty);
          expect(anomaly.detectedAt, isNotNull);
          expect(anomaly.metadata, isA<Map<String, dynamic>>());
        }
      });
      
      test('should analyze network optimization opportunities', () async {
        final analyticsSystem = analytics.NetworkAnalytics(prefs: mockPrefs);
        
        final optimizationReport = await analyticsSystem.analyzeNetworkOptimization();
        
        expect(optimizationReport.connectionEfficiency, isNotNull);
        expect(optimizationReport.learningBottlenecks, isA<List>());
        expect(optimizationReport.resourceOptimization, isNotNull);
        expect(optimizationReport.performanceImprovements, isNotNull);
        expect(optimizationReport.optimizationActions, isA<List>());
        expect(optimizationReport.impactEstimates, isNotNull);
        expect(optimizationReport.currentEfficiencyScore, greaterThanOrEqualTo(0.0));
        expect(optimizationReport.currentEfficiencyScore, lessThanOrEqualTo(1.0));
        expect(optimizationReport.potentialEfficiencyScore, greaterThanOrEqualTo(0.0));
        expect(optimizationReport.potentialEfficiencyScore, lessThanOrEqualTo(1.0));
        expect(optimizationReport.analyzedAt, isNotNull);
      });
    });
    
    group('Connection Monitor System', () {
      test('should create ConnectionMonitor successfully', () {
        final connectionMonitor = ConnectionMonitor(prefs: mockPrefs);
        
        expect(connectionMonitor, isNotNull);
      });
      
      test('should start monitoring a connection', () async {
        final connectionMonitor = ConnectionMonitor(prefs: mockPrefs);
        
        final testMetrics = ConnectionMetrics(
          connectionId: 'test_connection_001',
          localAISignature: 'local_ai_signature',
          remoteAISignature: 'remote_ai_signature',
          initialCompatibility: 0.75,
          currentCompatibility: 0.80,
          learningEffectiveness: 0.70,
          aiPleasureScore: 0.85,
          connectionDuration: Duration(minutes: 10),
          startTime: DateTime.now().subtract(Duration(minutes: 10)),
          status: ConnectionStatus.active,
          learningOutcomes: {'insights_shared': 5},
          interactionHistory: [],
          dimensionEvolution: {'exploration_eagerness': 0.05, 'community_orientation': 0.03},
        );
        
                 final session = await connectionMonitor.startMonitoring('test_connection_001', testMetrics);
         
         expect(session.connectionId, equals('test_connection_001'));
         expect(session.localAISignature, equals('local_ai_signature'));
         expect(session.remoteAISignature, equals('remote_ai_signature'));
         expect(session.initialMetrics, equals(testMetrics));
         expect(session.currentMetrics, equals(testMetrics));
         expect(session.qualityHistory, hasLength(1));
         expect(session.learningProgressHistory, hasLength(1));
         expect(session.alertsGenerated, isEmpty);
         expect(session.monitoringStatus, equals(MonitoringStatus.active));
        expect(session.startTime, isNotNull);
      });
      
      test('should update connection metrics during monitoring', () async {
        final monitor = ConnectionMonitor(prefs: mockPrefs);
        
        final initialMetrics = ConnectionMetrics(
          connectionId: 'test_connection_002',
          localAISignature: 'local_ai_signature_2',
          remoteAISignature: 'remote_ai_signature_2',
          initialCompatibility: 0.70,
          currentCompatibility: 0.70,
          learningEffectiveness: 0.65,
          aiPleasureScore: 0.80,
          connectionDuration: Duration(minutes: 5),
          startTime: DateTime.now().subtract(Duration(minutes: 5)),
          status: ConnectionStatus.active,
          learningOutcomes: {'insights_shared': 2},
          interactionHistory: [],
          dimensionEvolution: {'exploration_eagerness': 0.02},
        );
        
        // Start monitoring
        await monitor.startMonitoring('test_connection_002', initialMetrics);
        
        // Update metrics
        final updatedMetrics = ConnectionMetrics(
          connectionId: 'test_connection_002',
          localAISignature: 'local_ai_signature_2',
          remoteAISignature: 'remote_ai_signature_2',
          initialCompatibility: 0.70,
          currentCompatibility: 0.85,
          learningEffectiveness: 0.75,
          aiPleasureScore: 0.90,
          connectionDuration: Duration(minutes: 10),
          startTime: DateTime.now().subtract(Duration(minutes: 10)),
          status: ConnectionStatus.active,
          learningOutcomes: {'insights_shared': 8},
          interactionHistory: [],
          dimensionEvolution: {'exploration_eagerness': 0.08, 'community_orientation': 0.04},
        );
        
        final updatedSession = await monitor.updateConnectionMetrics('test_connection_002', updatedMetrics);
        
        expect(updatedSession.currentMetrics, equals(updatedMetrics));
        expect(updatedSession.qualityHistory, hasLength(2));
        expect(updatedSession.learningProgressHistory, hasLength(2));
        expect(updatedSession.lastUpdated, isNotNull);
      });
      
      test('should get real-time connection status', () async {
        final monitor = ConnectionMonitor(prefs: mockPrefs);
        
        final testMetrics = ConnectionMetrics(
          connectionId: 'test_connection_003',
          localAISignature: 'local_ai_signature_3',
          remoteAISignature: 'remote_ai_signature_3',
          initialCompatibility: 0.80,
          currentCompatibility: 0.82,
          learningEffectiveness: 0.78,
          aiPleasureScore: 0.88,
          connectionDuration: Duration(minutes: 15),
          startTime: DateTime.now().subtract(Duration(minutes: 15)),
          status: ConnectionStatus.active,
          learningOutcomes: {'insights_shared': 10},
          interactionHistory: [],
          dimensionEvolution: {'exploration_eagerness': 0.06},
        );
        
        // Start monitoring
        await monitor.startMonitoring('test_connection_003', testMetrics);
        
        final connectionStatus = await monitor.getConnectionStatus('test_connection_003');
        
        expect(connectionStatus.connectionId, equals('test_connection_003'));
        expect(connectionStatus.currentPerformance, isNotNull);
        expect(connectionStatus.healthScore, greaterThanOrEqualTo(0.0));
        expect(connectionStatus.healthScore, lessThanOrEqualTo(1.0));
        expect(connectionStatus.recentAlerts, isA<List<ConnectionAlert>>());
        expect(connectionStatus.trajectory, isNotNull);
        expect(connectionStatus.monitoringDuration, greaterThan(Duration.zero));
        expect(connectionStatus.lastUpdated, isNotNull);
      });
      
      test('should handle connection not found gracefully', () async {
        final monitor = ConnectionMonitor(prefs: mockPrefs);
        
        final connectionStatus = await monitor.getConnectionStatus('non_existent_connection');
        
        expect(connectionStatus.connectionId, equals('non_existent_connection'));
        expect(connectionStatus.healthScore, equals(0.0));
        expect(connectionStatus.monitoringDuration, equals(Duration.zero));
      });
      
      test('should analyze connection performance trends', () async {
        final monitor = ConnectionMonitor(prefs: mockPrefs);
        
        final testMetrics = ConnectionMetrics(
          connectionId: 'test_connection_004',
          localAISignature: 'local_ai_signature_4',
          remoteAISignature: 'remote_ai_signature_4',
          initialCompatibility: 0.75,
          currentCompatibility: 0.78,
          learningEffectiveness: 0.72,
          aiPleasureScore: 0.85,
          connectionDuration: Duration(minutes: 20),
          startTime: DateTime.now().subtract(Duration(minutes: 20)),
          status: ConnectionStatus.active,
          learningOutcomes: {'insights_shared': 12},
          interactionHistory: [],
          dimensionEvolution: {'exploration_eagerness': 0.07, 'authenticity_preference': 0.03},
        );
        
        // Start monitoring
        await monitor.startMonitoring('test_connection_004', testMetrics);
        
        final performanceAnalysis = await monitor.analyzeConnectionPerformance(
          'test_connection_004',
          Duration(minutes: 30),
        );
        
        expect(performanceAnalysis.connectionId, equals('test_connection_004'));
        expect(performanceAnalysis.analysisWindow, equals(Duration(minutes: 30)));
        expect(performanceAnalysis.qualityTrends, isNotNull);
        expect(performanceAnalysis.learningTrends, isNotNull);
        expect(performanceAnalysis.stabilityMetrics, isNotNull);
        expect(performanceAnalysis.performancePatterns, isA<List>());
        expect(performanceAnalysis.recommendations, isA<List>());
        expect(performanceAnalysis.overallPerformanceScore, greaterThanOrEqualTo(0.0));
        expect(performanceAnalysis.overallPerformanceScore, lessThanOrEqualTo(1.0));
        expect(performanceAnalysis.analyzedAt, isNotNull);
      });
      
      test('should generate active connections overview when no connections exist', () async {
        final monitor = ConnectionMonitor(prefs: mockPrefs);
        
        final overview = await monitor.getActiveConnectionsOverview();
        
        expect(overview.totalActiveConnections, equals(0));
        expect(overview.aggregateMetrics, isNotNull);
        expect(overview.topPerformingConnections, isEmpty);
        expect(overview.connectionsNeedingAttention, isEmpty);
        expect(overview.learningVelocityDistribution, isNotNull);
        expect(overview.optimizationOpportunities, isA<List>());
        expect(overview.averageConnectionDuration, equals(Duration.zero));
        expect(overview.totalAlertsGenerated, equals(0));
        expect(overview.generatedAt, isNotNull);
      });
      
      test('should detect connection anomalies', () async {
        final monitor = ConnectionMonitor(prefs: mockPrefs);
        
        final anomalies = await monitor.detectConnectionAnomalies();
        
        expect(anomalies, isA<List<ConnectionAnomaly>>());
        // Anomalies list can be empty if no connections are being monitored
        for (final anomaly in anomalies) {
          expect(anomaly.connectionId, isNotEmpty);
          expect(anomaly.type, isA<AnomalyType>());
          expect(anomaly.severity, isA<AlertSeverity>());
          expect(anomaly.description, isNotEmpty);
          expect(anomaly.detectedAt, isNotNull);
          expect(anomaly.metadata, isA<Map<String, dynamic>>());
        }
      });
      
      test('should stop monitoring and generate report', () async {
        final monitor = ConnectionMonitor(prefs: mockPrefs);
        
        final testMetrics = ConnectionMetrics(
          connectionId: 'test_connection_005',
          localAISignature: 'local_ai_signature_5',
          remoteAISignature: 'remote_ai_signature_5',
          initialCompatibility: 0.72,
          currentCompatibility: 0.85,
          learningEffectiveness: 0.80,
          aiPleasureScore: 0.90,
          connectionDuration: Duration(minutes: 25),
          startTime: DateTime.now().subtract(Duration(minutes: 25)),
          status: ConnectionStatus.completing,
          learningOutcomes: {'insights_shared': 15, 'dimensions_evolved': 3},
          interactionHistory: [],
          dimensionEvolution: {'exploration_eagerness': 0.10, 'community_orientation': 0.05},
        );
        
        // Start monitoring
        await monitor.startMonitoring('test_connection_005', testMetrics);
        
        // Stop monitoring
        final report = await monitor.stopMonitoring('test_connection_005');
        
        expect(report.connectionId, equals('test_connection_005'));
        expect(report.localAISignature, equals('local_ai_signature_5'));
        expect(report.remoteAISignature, equals('remote_ai_signature_5'));
        expect(report.connectionDuration, greaterThan(Duration.zero));
        expect(report.initialMetrics, isNotNull);
        expect(report.finalMetrics, equals(testMetrics));
        expect(report.performanceSummary, isNotNull);
        expect(report.learningOutcomes, isNotNull);
        expect(report.qualityAnalysis, isNotNull);
        expect(report.alertsGenerated, isA<List<ConnectionAlert>>());
        expect(report.overallRating, greaterThanOrEqualTo(0.0));
        expect(report.overallRating, lessThanOrEqualTo(1.0));
        expect(report.generatedAt, isNotNull);
        
        // Verify connection is no longer being monitored
        final statusAfterStop = await monitor.getConnectionStatus('test_connection_005');
        expect(statusAfterStop.healthScore, equals(0.0)); // Should return not found status
      });
    });
    
    group('Integration Validation', () {
      test('should validate Phase 4 component integration', () async {
        // Create both Phase 4 components
        final analyticsSystem = analytics.NetworkAnalytics(prefs: mockPrefs);
        final monitor = ConnectionMonitor(prefs: mockPrefs);
        
        // Validate component creation
        expect(analyticsSystem, isNotNull);
        expect(monitor, isNotNull);
        
        // Test that both components work independently
        expect(analyticsSystem.runtimeType, equals(analytics.NetworkAnalytics));
        expect(monitor.runtimeType, equals(ConnectionMonitor));
        
        // Test basic functionality
        final healthReport = await analyticsSystem.analyzeNetworkHealth();
        expect(healthReport.overallHealthScore, greaterThanOrEqualTo(0.0));
        
        final overview = await monitor.getActiveConnectionsOverview();
        expect(overview.totalActiveConnections, equals(0));
      });
      
      test('should validate monitoring data structures compatibility', () async {
        // Test that monitoring data structures are compatible with connection metrics
        final testMetrics = ConnectionMetrics(
          connectionId: 'integration_test_connection',
          localAISignature: 'local_signature',
          remoteAISignature: 'remote_signature',
          initialCompatibility: 0.75,
          currentCompatibility: 0.80,
          learningEffectiveness: 0.70,
          aiPleasureScore: 0.85,
          connectionDuration: Duration(minutes: 10),
          startTime: DateTime.now().subtract(Duration(minutes: 10)),
          status: ConnectionStatus.active,
          learningOutcomes: {'test': 1},
          interactionHistory: [],
          dimensionEvolution: {'test_dimension': 0.05},
        );
        
        // Validate that connection metrics work with monitoring components
        expect(testMetrics.connectionId, isNotEmpty);
        expect(testMetrics.currentCompatibility, greaterThanOrEqualTo(0.0));
        expect(testMetrics.currentCompatibility, lessThanOrEqualTo(1.0));
        expect(testMetrics.learningEffectiveness, greaterThanOrEqualTo(0.0));
        expect(testMetrics.learningEffectiveness, lessThanOrEqualTo(1.0));
        expect(testMetrics.status, isA<ConnectionStatus>());
        expect(testMetrics.dimensionEvolution, isA<Map<String, double>>());
      });
      
      test('should validate Phase 4 monitoring capabilities', () async {
        final monitor = ConnectionMonitor(prefs: mockPrefs);
        final analyticsSystem = analytics.NetworkAnalytics(prefs: mockPrefs);
        
        // Test monitoring lifecycle
        final testMetrics = ConnectionMetrics(
          connectionId: 'lifecycle_test',
          localAISignature: 'local_test',
          remoteAISignature: 'remote_test',
          initialCompatibility: 0.70,
          currentCompatibility: 0.75,
          learningEffectiveness: 0.65,
          aiPleasureScore: 0.80,
          connectionDuration: Duration(minutes: 5),
          startTime: DateTime.now().subtract(Duration(minutes: 5)),
          status: ConnectionStatus.active,
          learningOutcomes: {},
          interactionHistory: [],
          dimensionEvolution: {},
        );
        
        // Start monitoring
        final session = await monitor.startMonitoring('lifecycle_test', testMetrics);
        expect(session.monitoringStatus, equals(MonitoringStatus.active));
        
        // Check network analytics can run while monitoring is active
        final healthReport = await analyticsSystem.analyzeNetworkHealth();
        expect(healthReport, isNotNull);
        
        // Get connection status
        final status = await monitor.getConnectionStatus('lifecycle_test');
        expect(status.connectionId, equals('lifecycle_test'));
        
        // Stop monitoring
        final report = await monitor.stopMonitoring('lifecycle_test');
        expect(report.connectionId, equals('lifecycle_test'));
        
        // Verify monitoring system handles the full lifecycle correctly
        expect(session.connectionId, equals('lifecycle_test'));
        expect(report.connectionDuration, greaterThan(Duration.zero));
      });
    });
  });
}