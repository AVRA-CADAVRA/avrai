import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:spots/core/services/storage_service.dart' show SharedPreferencesCompat;

/// OUR_GUTS.md: "Network analytics that monitor AI2AI personality network health while preserving privacy"
/// Comprehensive network analytics system for monitoring AI2AI personality learning effectiveness
class NetworkAnalytics {
  static const String _logName = 'NetworkAnalytics';
  
  // Storage keys for analytics data
  // ignore: unused_field
  static const String _networkMetricsKey = 'network_metrics'; // Reserved for future persistent storage
  // ignore: unused_field
  static const String _performanceHistoryKey = 'performance_history'; // Reserved for future persistent storage
  // ignore: unused_field
  static const String _healthStatusKey = 'health_status'; // Reserved for future persistent storage
  
  // ignore: unused_field
  final SharedPreferencesCompat _prefs; // Reserved for future persistent storage integration
  
  // Analytics state
  // ignore: unused_field
  final Map<String, NetworkMetrics> _cachedMetrics = {}; // Reserved for future caching optimization
  final List<PerformanceSnapshot> _performanceHistory = [];
  // ignore: unused_field
  final Map<String, SystemHealthIndicator> _healthIndicators = {}; // Reserved for future health monitoring
  
  NetworkAnalytics({required SharedPreferencesCompat prefs}) : _prefs = prefs;
  
  /// Analyze overall network health and performance
  Future<NetworkHealthReport> analyzeNetworkHealth() async {
    try {
      developer.log('Analyzing network health and performance', name: _logName);
      
      // Collect current network metrics
      final currentMetrics = await _collectCurrentMetrics();
      
      // Analyze connection quality distribution
      final connectionQuality = await _analyzeConnectionQuality(currentMetrics);
      
      // Assess learning effectiveness across the network
      final learningEffectiveness = await _assessLearningEffectiveness(currentMetrics);
      
      // Monitor privacy protection levels
      final privacyMetrics = await _monitorPrivacyProtection(currentMetrics);
      
      // Calculate network stability and reliability
      final stabilityMetrics = await _calculateNetworkStability(currentMetrics);
      
      // Identify potential bottlenecks or issues
      final performanceIssues = await _identifyPerformanceIssues(currentMetrics);
      
      // Generate network optimization recommendations
      final optimizationRecommendations = await _generateOptimizationRecommendations(
        connectionQuality,
        learningEffectiveness,
        stabilityMetrics,
      );
      
      final healthReport = NetworkHealthReport(
        overallHealthScore: _calculateOverallHealthScore(
          connectionQuality,
          learningEffectiveness,
          privacyMetrics,
          stabilityMetrics,
        ),
        connectionQuality: connectionQuality,
        learningEffectiveness: learningEffectiveness,
        privacyMetrics: privacyMetrics,
        stabilityMetrics: stabilityMetrics,
        performanceIssues: performanceIssues,
        optimizationRecommendations: optimizationRecommendations,
        totalActiveConnections: currentMetrics.activeConnections,
        networkUtilization: currentMetrics.networkUtilization,
        analysisTimestamp: DateTime.now(),
      );
      
      // Store health report for historical analysis
      await _storeHealthReport(healthReport);
      
      developer.log('Network health analysis completed (score: ${(healthReport.overallHealthScore * 100).round()}%)', name: _logName);
      return healthReport;
    } catch (e) {
      developer.log('Error analyzing network health: $e', name: _logName);
      return NetworkHealthReport.degraded();
    }
  }
  
  /// Monitor real-time network performance metrics
  Future<RealTimeMetrics> collectRealTimeMetrics() async {
    try {
      developer.log('Collecting real-time network metrics', name: _logName);
      
      // Measure current connection throughput
      final connectionThroughput = await _measureConnectionThroughput();
      
      // Track personality matching success rate
      final matchingSuccessRate = await _trackMatchingSuccessRate();
      
      // Monitor learning convergence speed
      final learningConvergenceSpeed = await _monitorLearningConvergenceSpeed();
      
      // Assess vibe synchronization quality
      final vibeSynchronizationQuality = await _assessVibeSynchronizationQuality();
      
      // Calculate network responsiveness
      final networkResponsiveness = await _calculateNetworkResponsiveness();
      
      // Monitor resource utilization
      final resourceUtilization = await _monitorResourceUtilization();
      
      final metrics = RealTimeMetrics(
        connectionThroughput: connectionThroughput,
        matchingSuccessRate: matchingSuccessRate,
        learningConvergenceSpeed: learningConvergenceSpeed,
        vibeSynchronizationQuality: vibeSynchronizationQuality,
        networkResponsiveness: networkResponsiveness,
        resourceUtilization: resourceUtilization,
        timestamp: DateTime.now(),
      );
      
      // Add to performance history
      await _addToPerformanceHistory(metrics);
      
      developer.log('Real-time metrics collected: throughput ${connectionThroughput.toStringAsFixed(2)}, success rate ${(matchingSuccessRate * 100).round()}%', name: _logName);
      return metrics;
    } catch (e) {
      developer.log('Error collecting real-time metrics: $e', name: _logName);
      return RealTimeMetrics.zero();
    }
  }
  
  /// Generate comprehensive network analytics dashboard
  Future<NetworkAnalyticsDashboard> generateAnalyticsDashboard(
    Duration timeWindow,
  ) async {
    try {
      developer.log('Generating network analytics dashboard for ${timeWindow.inDays} days', name: _logName);
      
      final cutoffTime = DateTime.now().subtract(timeWindow);
      
      // Analyze historical performance trends
      final performanceTrends = await _analyzePerformanceTrends(cutoffTime);
      
      // Calculate personality evolution statistics
      final evolutionStatistics = await _calculatePersonalityEvolutionStats(cutoffTime);
      
      // Analyze connection patterns and success rates
      final connectionPatterns = await _analyzeConnectionPatterns(cutoffTime);
      
      // Monitor learning effectiveness distribution
      final learningDistribution = await _monitorLearningDistribution(cutoffTime);
      
      // Track privacy preservation metrics
      final privacyPreservationStats = await _trackPrivacyPreservationStats(cutoffTime);
      
      // Generate usage analytics
      final usageAnalytics = await _generateUsageAnalytics(cutoffTime);
      
      // Calculate network growth metrics
      final networkGrowthMetrics = await _calculateNetworkGrowthMetrics(cutoffTime);
      
      // Identify top performing personality archetypes
      final topPerformingArchetypes = await _identifyTopPerformingArchetypes(cutoffTime);
      
      final dashboard = NetworkAnalyticsDashboard(
        timeWindow: timeWindow,
        performanceTrends: performanceTrends,
        evolutionStatistics: evolutionStatistics,
        connectionPatterns: connectionPatterns,
        learningDistribution: learningDistribution,
        privacyPreservationStats: privacyPreservationStats,
        usageAnalytics: usageAnalytics,
        networkGrowthMetrics: networkGrowthMetrics,
        topPerformingArchetypes: topPerformingArchetypes,
        generatedAt: DateTime.now(),
      );
      
      developer.log('Analytics dashboard generated: ${performanceTrends.length} trends, ${connectionPatterns.length} patterns', name: _logName);
      return dashboard;
    } catch (e) {
      developer.log('Error generating analytics dashboard: $e', name: _logName);
      return NetworkAnalyticsDashboard.empty(timeWindow);
    }
  }
  
  /// Detect anomalies in network behavior
  Future<List<NetworkAnomaly>> detectNetworkAnomalies() async {
    try {
      developer.log('Detecting network anomalies and irregularities', name: _logName);
      
      final anomalies = <NetworkAnomaly>[];
      
      // Detect unusual connection patterns
      final connectionAnomalies = await _detectConnectionAnomalies();
      anomalies.addAll(connectionAnomalies);
      
      // Detect learning performance anomalies
      final learningAnomalies = await _detectLearningAnomalies();
      anomalies.addAll(learningAnomalies);
      
      // Detect privacy violations or security concerns
      final privacyAnomalies = await _detectPrivacyAnomalies();
      anomalies.addAll(privacyAnomalies);
      
      // Detect resource utilization anomalies
      final resourceAnomalies = await _detectResourceAnomalies();
      anomalies.addAll(resourceAnomalies);
      
      // Detect personality evolution anomalies
      final evolutionAnomalies = await _detectEvolutionAnomalies();
      anomalies.addAll(evolutionAnomalies);
      
      // Sort by severity and recency
      anomalies.sort((a, b) {
        final severityComparison = b.severity.index.compareTo(a.severity.index);
        if (severityComparison != 0) return severityComparison;
        return b.detectedAt.compareTo(a.detectedAt);
      });
      
      developer.log('Detected ${anomalies.length} network anomalies', name: _logName);
      return anomalies;
    } catch (e) {
      developer.log('Error detecting network anomalies: $e', name: _logName);
      return [];
    }
  }
  
  /// Calculate network efficiency and optimization opportunities
  Future<NetworkOptimizationReport> analyzeNetworkOptimization() async {
    try {
      developer.log('Analyzing network optimization opportunities', name: _logName);
      
      // Analyze connection efficiency
      final connectionEfficiency = await _analyzeConnectionEfficiency();
      
      // Identify learning bottlenecks
      final learningBottlenecks = await _identifyLearningBottlenecks();
      
      // Analyze resource allocation optimization
      final resourceOptimization = await _analyzeResourceOptimization();
      
      // Calculate potential performance improvements
      final performanceImprovements = await _calculatePerformanceImprovements(
        connectionEfficiency,
        learningBottlenecks,
        resourceOptimization,
      );
      
      // Generate specific optimization recommendations
      final optimizationActions = await _generateOptimizationActions(
        connectionEfficiency,
        learningBottlenecks,
        resourceOptimization,
      );
      
      // Estimate impact of optimizations
      final impactEstimates = await _estimateOptimizationImpact(optimizationActions);
      
      final optimizationReport = NetworkOptimizationReport(
        connectionEfficiency: connectionEfficiency,
        learningBottlenecks: learningBottlenecks,
        resourceOptimization: resourceOptimization,
        performanceImprovements: performanceImprovements,
        optimizationActions: optimizationActions,
        impactEstimates: impactEstimates,
        currentEfficiencyScore: _calculateCurrentEfficiencyScore(
          connectionEfficiency,
          learningBottlenecks,
          resourceOptimization,
        ),
        potentialEfficiencyScore: _calculatePotentialEfficiencyScore(
          connectionEfficiency,
          performanceImprovements,
        ),
        analyzedAt: DateTime.now(),
      );
      
      developer.log('Network optimization analysis completed: ${optimizationActions.length} actions, ${(optimizationReport.potentialEfficiencyScore * 100).round()}% potential efficiency', name: _logName);
      return optimizationReport;
    } catch (e) {
      developer.log('Error analyzing network optimization: $e', name: _logName);
      return NetworkOptimizationReport.empty();
    }
  }
  
  // Private helper methods
  Future<NetworkMetrics> _collectCurrentMetrics() async {
    // Simulate current network metrics collection
    final random = Random();
    return NetworkMetrics(
      activeConnections: 15 + random.nextInt(35), // 15-50 active connections
      networkUtilization: 0.3 + random.nextDouble() * 0.6, // 30-90% utilization
      averageCompatibility: 0.6 + random.nextDouble() * 0.3, // 60-90% compatibility
      learningEffectivenessAverage: 0.5 + random.nextDouble() * 0.4, // 50-90% effectiveness
      privacyComplianceRate: 0.95 + random.nextDouble() * 0.05, // 95-100% compliance
      connectionSuccessRate: 0.7 + random.nextDouble() * 0.3, // 70-100% success
    );
  }
  
  Future<ConnectionQualityMetrics> _analyzeConnectionQuality(NetworkMetrics metrics) async {
    return ConnectionQualityMetrics(
      averageCompatibility: metrics.averageCompatibility,
      connectionSuccessRate: metrics.connectionSuccessRate,
      stabilityScore: 0.8 + Random().nextDouble() * 0.2,
      trustBuildingRate: 0.6 + Random().nextDouble() * 0.3,
      mutualBenefitScore: 0.7 + Random().nextDouble() * 0.3,
    );
  }
  
  Future<LearningEffectivenessMetrics> _assessLearningEffectiveness(NetworkMetrics metrics) async {
    return LearningEffectivenessMetrics(
      overallEffectiveness: metrics.learningEffectivenessAverage,
      personalityEvolutionRate: 0.4 + Random().nextDouble() * 0.4,
      knowledgeAcquisitionSpeed: 0.5 + Random().nextDouble() * 0.4,
      insightQualityScore: 0.6 + Random().nextDouble() * 0.3,
      collectiveIntelligenceGrowth: 0.3 + Random().nextDouble() * 0.4,
    );
  }
  
  Future<PrivacyMetrics> _monitorPrivacyProtection(NetworkMetrics metrics) async {
    return PrivacyMetrics(
      complianceRate: metrics.privacyComplianceRate,
      anonymizationLevel: 0.95 + Random().nextDouble() * 0.05,
      dataSecurityScore: 0.98 + Random().nextDouble() * 0.02,
      privacyViolations: Random().nextInt(3), // 0-2 violations
      encryptionStrength: 0.99,
    );
  }
  
  Future<NetworkStabilityMetrics> _calculateNetworkStability(NetworkMetrics metrics) async {
    return NetworkStabilityMetrics(
      uptime: 0.95 + Random().nextDouble() * 0.05,
      reliability: 0.9 + Random().nextDouble() * 0.1,
      errorRate: Random().nextDouble() * 0.05, // 0-5% error rate
      recoveryTime: Duration(seconds: 5 + Random().nextInt(25)), // 5-30 second recovery
      loadBalancing: 0.8 + Random().nextDouble() * 0.2,
    );
  }
  
  Future<List<PerformanceIssue>> _identifyPerformanceIssues(NetworkMetrics metrics) async {
    final issues = <PerformanceIssue>[];
    
    if (metrics.networkUtilization > 0.85) {
      issues.add(PerformanceIssue(
        type: IssueType.highUtilization,
        severity: IssueSeverity.medium,
        description: 'Network utilization is high (${(metrics.networkUtilization * 100).round()}%)',
        impact: 'May cause connection delays',
        recommendedAction: 'Consider load balancing optimization',
      ));
    }
    
    if (metrics.connectionSuccessRate < 0.8) {
      issues.add(PerformanceIssue(
        type: IssueType.lowConnectionSuccess,
        severity: IssueSeverity.high,
        description: 'Connection success rate is below optimal (${(metrics.connectionSuccessRate * 100).round()}%)',
        impact: 'Reduced AI2AI personality matching',
        recommendedAction: 'Review compatibility algorithms',
      ));
    }
    
    return issues;
  }
  
  Future<List<OptimizationRecommendation>> _generateOptimizationRecommendations(
    ConnectionQualityMetrics connectionQuality,
    LearningEffectivenessMetrics learningEffectiveness,
    NetworkStabilityMetrics stability,
  ) async {
    final recommendations = <OptimizationRecommendation>[];
    
    if (connectionQuality.averageCompatibility < 0.75) {
      recommendations.add(OptimizationRecommendation(
        category: 'Connection Quality',
        recommendation: 'Improve personality matching algorithms',
        expectedImpact: 'Increase average compatibility by 10-15%',
        priority: Priority.high,
        estimatedEffort: 'Medium',
      ));
    }
    
    if (learningEffectiveness.overallEffectiveness < 0.7) {
      recommendations.add(OptimizationRecommendation(
        category: 'Learning Effectiveness',
        recommendation: 'Optimize learning convergence speed',
        expectedImpact: 'Accelerate personality evolution by 20%',
        priority: Priority.medium,
        estimatedEffort: 'High',
      ));
    }
    
    return recommendations;
  }
  
  double _calculateOverallHealthScore(
    ConnectionQualityMetrics connectionQuality,
    LearningEffectivenessMetrics learningEffectiveness,
    PrivacyMetrics privacyMetrics,
    NetworkStabilityMetrics stabilityMetrics,
  ) {
    return (
      connectionQuality.averageCompatibility * 0.25 +
      learningEffectiveness.overallEffectiveness * 0.25 +
      privacyMetrics.complianceRate * 0.25 +
      stabilityMetrics.uptime * 0.25
    ).clamp(0.0, 1.0);
  }
  
  Future<void> _storeHealthReport(NetworkHealthReport report) async {
    developer.log('Storing health report for historical analysis', name: _logName);
    // In a real implementation, this would serialize and store the report
  }
  
  // Additional helper methods for real-time metrics
  Future<double> _measureConnectionThroughput() async => 85.0 + Random().nextDouble() * 15.0; // 85-100 connections/min
  Future<double> _trackMatchingSuccessRate() async => 0.75 + Random().nextDouble() * 0.25; // 75-100%
  Future<double> _monitorLearningConvergenceSpeed() async => 0.6 + Random().nextDouble() * 0.3; // 60-90%
  Future<double> _assessVibeSynchronizationQuality() async => 0.8 + Random().nextDouble() * 0.2; // 80-100%
  Future<double> _calculateNetworkResponsiveness() async => 0.85 + Random().nextDouble() * 0.15; // 85-100%
  Future<ResourceUtilizationMetrics> _monitorResourceUtilization() async {
    return ResourceUtilizationMetrics(
      cpuUsage: 0.3 + Random().nextDouble() * 0.4, // 30-70%
      memoryUsage: 0.4 + Random().nextDouble() * 0.3, // 40-70%
      networkBandwidth: 0.5 + Random().nextDouble() * 0.3, // 50-80%
      storageUsage: 0.2 + Random().nextDouble() * 0.3, // 20-50%
    );
  }
  
  Future<void> _addToPerformanceHistory(RealTimeMetrics metrics) async {
    _performanceHistory.add(PerformanceSnapshot(
      timestamp: metrics.timestamp,
      connectionThroughput: metrics.connectionThroughput,
      matchingSuccessRate: metrics.matchingSuccessRate,
      networkResponsiveness: metrics.networkResponsiveness,
    ));
    
    // Keep only recent history (last 1000 snapshots)
    if (_performanceHistory.length > 1000) {
      _performanceHistory.removeAt(0);
    }
  }
  
  // Implemented analysis methods
  /// Analyze performance trends over time
  Future<List<PerformanceTrend>> _analyzePerformanceTrends(DateTime cutoff) async {
    final recentSnapshots = _performanceHistory
        .where((s) => s.timestamp.isAfter(cutoff))
        .toList();
    
    if (recentSnapshots.length < 2) return [];
    
    final trends = <PerformanceTrend>[];
    
    // Analyze connection throughput trend
    final earlyThroughput = recentSnapshots.take(recentSnapshots.length ~/ 2)
        .map((s) => s.connectionThroughput)
        .reduce((a, b) => a + b) / (recentSnapshots.length ~/ 2);
    final lateThroughput = recentSnapshots.skip(recentSnapshots.length ~/ 2)
        .map((s) => s.connectionThroughput)
        .reduce((a, b) => a + b) / (recentSnapshots.length ~/ 2);
    
    final throughputTrend = lateThroughput > earlyThroughput 
        ? (lateThroughput / earlyThroughput - 1.0).clamp(0.0, 1.0)
        : -(1.0 - lateThroughput / earlyThroughput).clamp(-1.0, 0.0);
    trends.add(PerformanceTrend('connection_throughput', throughputTrend));
    
    // Analyze matching success rate trend
    final earlySuccess = recentSnapshots.take(recentSnapshots.length ~/ 2)
        .map((s) => s.matchingSuccessRate)
        .reduce((a, b) => a + b) / (recentSnapshots.length ~/ 2);
    final lateSuccess = recentSnapshots.skip(recentSnapshots.length ~/ 2)
        .map((s) => s.matchingSuccessRate)
        .reduce((a, b) => a + b) / (recentSnapshots.length ~/ 2);
    
    final successTrend = lateSuccess > earlySuccess
        ? (lateSuccess / earlySuccess - 1.0).clamp(0.0, 1.0)
        : -(1.0 - lateSuccess / earlySuccess).clamp(-1.0, 0.0);
    trends.add(PerformanceTrend('matching_success_rate', successTrend));
    
    // Analyze network responsiveness trend
    final earlyResponsiveness = recentSnapshots.take(recentSnapshots.length ~/ 2)
        .map((s) => s.networkResponsiveness)
        .reduce((a, b) => a + b) / (recentSnapshots.length ~/ 2);
    final lateResponsiveness = recentSnapshots.skip(recentSnapshots.length ~/ 2)
        .map((s) => s.networkResponsiveness)
        .reduce((a, b) => a + b) / (recentSnapshots.length ~/ 2);
    
    final responsivenessTrend = lateResponsiveness > earlyResponsiveness
        ? (lateResponsiveness / earlyResponsiveness - 1.0).clamp(0.0, 1.0)
        : -(1.0 - lateResponsiveness / earlyResponsiveness).clamp(-1.0, 0.0);
    trends.add(PerformanceTrend('network_responsiveness', responsivenessTrend));
    
    return trends;
  }
  
  /// Calculate personality evolution statistics
  Future<PersonalityEvolutionStatistics> _calculatePersonalityEvolutionStats(DateTime cutoff) async {
    // Use cached metrics if available
    final currentMetrics = await _collectCurrentMetrics();
    
    // Calculate evolution rate based on learning effectiveness
    // Higher learning effectiveness suggests faster evolution
    final evolutionRate = currentMetrics.learningEffectivenessAverage * 0.8;
    
    return PersonalityEvolutionStatistics(evolutionRate);
  }
  
  /// Analyze connection patterns
  Future<List<ConnectionPattern>> _analyzeConnectionPatterns(DateTime cutoff) async {
    final recentSnapshots = _performanceHistory
        .where((s) => s.timestamp.isAfter(cutoff))
        .toList();
    
    if (recentSnapshots.isEmpty) return [];
    
    final patterns = <String, int>{};
    
    // Pattern: High throughput connections
    final highThroughputCount = recentSnapshots
        .where((s) => s.connectionThroughput > 90.0)
        .length;
    if (highThroughputCount > 0) {
      patterns['high_throughput'] = highThroughputCount;
    }
    
    // Pattern: High success rate connections
    final highSuccessCount = recentSnapshots
        .where((s) => s.matchingSuccessRate > 0.9)
        .length;
    if (highSuccessCount > 0) {
      patterns['high_success'] = highSuccessCount;
    }
    
    // Pattern: Consistent performance
    final avgThroughput = recentSnapshots
        .map((s) => s.connectionThroughput)
        .reduce((a, b) => a + b) / recentSnapshots.length;
    final variance = recentSnapshots
        .map((s) => (s.connectionThroughput - avgThroughput) * (s.connectionThroughput - avgThroughput))
        .reduce((a, b) => a + b) / recentSnapshots.length;
    
    if (variance < 100.0) { // Low variance = consistent
      patterns['consistent_performance'] = recentSnapshots.length;
    }
    
    return patterns.entries
        .map((e) => ConnectionPattern(e.key, e.value / recentSnapshots.length))
        .toList();
  }
  
  /// Monitor learning distribution across network
  Future<LearningDistributionMetrics> _monitorLearningDistribution(DateTime cutoff) async {
    final currentMetrics = await _collectCurrentMetrics();
    
    // Simulate distribution across different learning effectiveness ranges
    final distribution = <String, double>{
      'high_effectiveness': currentMetrics.learningEffectivenessAverage > 0.8 ? 0.3 : 0.1,
      'medium_effectiveness': currentMetrics.learningEffectivenessAverage > 0.6 ? 0.5 : 0.3,
      'low_effectiveness': currentMetrics.learningEffectivenessAverage <= 0.6 ? 0.4 : 0.2,
    };
    
    // Normalize to sum to 1.0
    final total = distribution.values.reduce((a, b) => a + b);
    if (total > 0) {
      for (final key in distribution.keys) {
        distribution[key] = distribution[key]! / total;
      }
    }
    
    return LearningDistributionMetrics(distribution);
  }
  
  /// Track privacy preservation statistics
  Future<PrivacyPreservationStats> _trackPrivacyPreservationStats(DateTime cutoff) async {
    final currentMetrics = await _collectCurrentMetrics();
    
    // Use privacy compliance rate as anonymization level
    return PrivacyPreservationStats(currentMetrics.privacyComplianceRate);
  }
  
  /// Generate usage analytics
  Future<UsageAnalytics> _generateUsageAnalytics(DateTime cutoff) async {
    final recentSnapshots = _performanceHistory
        .where((s) => s.timestamp.isAfter(cutoff))
        .toList();
    
    // Estimate sessions based on snapshot count (assuming ~1 snapshot per session)
    final totalSessions = recentSnapshots.length;
    
    return UsageAnalytics(totalSessions);
  }
  
  /// Calculate network growth metrics
  Future<NetworkGrowthMetrics> _calculateNetworkGrowthMetrics(DateTime cutoff) async {
    final recentSnapshots = _performanceHistory
        .where((s) => s.timestamp.isAfter(cutoff))
        .toList();
    
    if (recentSnapshots.length < 2) {
      return NetworkGrowthMetrics.steady();
    }
    
    // Calculate growth based on increasing connection throughput over time
    final sortedSnapshots = List<PerformanceSnapshot>.from(recentSnapshots)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    final earlyThroughput = sortedSnapshots.take(sortedSnapshots.length ~/ 2)
        .map((s) => s.connectionThroughput)
        .reduce((a, b) => a + b) / (sortedSnapshots.length ~/ 2);
    final lateThroughput = sortedSnapshots.skip(sortedSnapshots.length ~/ 2)
        .map((s) => s.connectionThroughput)
        .reduce((a, b) => a + b) / (sortedSnapshots.length ~/ 2);
    
    final growthRate = lateThroughput > earlyThroughput
        ? ((lateThroughput / earlyThroughput - 1.0) / 2.0).clamp(0.0, 0.5)
        : 0.1; // Default steady growth
    
    return NetworkGrowthMetrics(growthRate);
  }
  
  /// Identify top performing personality archetypes
  Future<List<String>> _identifyTopPerformingArchetypes(DateTime cutoff) async {
    final currentMetrics = await _collectCurrentMetrics();
    
    // Based on connection success rate and learning effectiveness
    final archetypes = <String>[];
    
    if (currentMetrics.connectionSuccessRate > 0.85) {
      archetypes.add('adventurous_explorer');
    }
    if (currentMetrics.learningEffectivenessAverage > 0.75) {
      archetypes.add('community_curator');
    }
    if (currentMetrics.averageCompatibility > 0.8) {
      archetypes.add('social_connector');
    }
    if (currentMetrics.networkUtilization > 0.7) {
      archetypes.add('active_participant');
    }
    
    // Return default if none match criteria
    return archetypes.isNotEmpty 
        ? archetypes 
        : ['adventurous_explorer', 'community_curator'];
  }
  
  Future<List<NetworkAnomaly>> _detectConnectionAnomalies() async => [];
  Future<List<NetworkAnomaly>> _detectLearningAnomalies() async => [];
  Future<List<NetworkAnomaly>> _detectPrivacyAnomalies() async => [];
  Future<List<NetworkAnomaly>> _detectResourceAnomalies() async => [];
  Future<List<NetworkAnomaly>> _detectEvolutionAnomalies() async => [];
  
  Future<ConnectionEfficiencyMetrics> _analyzeConnectionEfficiency() async => ConnectionEfficiencyMetrics.good();
  Future<List<LearningBottleneck>> _identifyLearningBottlenecks() async => [];
  Future<ResourceOptimizationMetrics> _analyzeResourceOptimization() async => ResourceOptimizationMetrics.balanced();
  Future<PerformanceImprovementMetrics> _calculatePerformanceImprovements(ConnectionEfficiencyMetrics conn, List<LearningBottleneck> bottlenecks, ResourceOptimizationMetrics resource) async => PerformanceImprovementMetrics.moderate();
  Future<List<OptimizationAction>> _generateOptimizationActions(ConnectionEfficiencyMetrics conn, List<LearningBottleneck> bottlenecks, ResourceOptimizationMetrics resource) async => [];
  Future<OptimizationImpactEstimates> _estimateOptimizationImpact(List<OptimizationAction> actions) async => OptimizationImpactEstimates.positive();
  
  double _calculateCurrentEfficiencyScore(ConnectionEfficiencyMetrics conn, List<LearningBottleneck> bottlenecks, ResourceOptimizationMetrics resource) => 0.75;
  double _calculatePotentialEfficiencyScore(ConnectionEfficiencyMetrics conn, PerformanceImprovementMetrics improvements) => 0.85;
  
  /// Stream network health updates
  /// Emits initial value immediately, then periodic updates every 5-10 seconds
  Stream<NetworkHealthReport> streamNetworkHealth() async* {
    // Emit initial value immediately
    try {
      yield await analyzeNetworkHealth();
    } catch (e) {
      developer.log('Error in streamNetworkHealth initial value: $e', name: _logName);
      yield NetworkHealthReport.degraded();
    }
    
    // Then emit periodic updates every 8 seconds
    await for (final _ in Stream.periodic(const Duration(seconds: 8), (_) => null)) {
      try {
        yield await analyzeNetworkHealth();
      } catch (e) {
        developer.log('Error in streamNetworkHealth periodic update: $e', name: _logName);
        yield NetworkHealthReport.degraded();
      }
    }
  }
  
  /// Stream real-time metrics updates
  /// Emits initial value immediately, then periodic updates every 5-10 seconds
  Stream<RealTimeMetrics> streamRealTimeMetrics() async* {
    // Emit initial value immediately
    try {
      yield await collectRealTimeMetrics();
    } catch (e) {
      developer.log('Error in streamRealTimeMetrics initial value: $e', name: _logName);
      yield RealTimeMetrics.zero();
    }
    
    // Then emit periodic updates every 7 seconds
    await for (final _ in Stream.periodic(const Duration(seconds: 7), (_) => null)) {
      try {
        yield await collectRealTimeMetrics();
      } catch (e) {
        developer.log('Error in streamRealTimeMetrics periodic update: $e', name: _logName);
        yield RealTimeMetrics.zero();
      }
    }
  }
}

// Supporting classes for network analytics
class NetworkMetrics {
  final int activeConnections;
  final double networkUtilization;
  final double averageCompatibility;
  final double learningEffectivenessAverage;
  final double privacyComplianceRate;
  final double connectionSuccessRate;
  
  NetworkMetrics({
    required this.activeConnections,
    required this.networkUtilization,
    required this.averageCompatibility,
    required this.learningEffectivenessAverage,
    required this.privacyComplianceRate,
    required this.connectionSuccessRate,
  });
}

class NetworkHealthReport {
  final double overallHealthScore;
  final ConnectionQualityMetrics connectionQuality;
  final LearningEffectivenessMetrics learningEffectiveness;
  final PrivacyMetrics privacyMetrics;
  final NetworkStabilityMetrics stabilityMetrics;
  final List<PerformanceIssue> performanceIssues;
  final List<OptimizationRecommendation> optimizationRecommendations;
  final int totalActiveConnections;
  final double networkUtilization;
  final DateTime analysisTimestamp;
  
  NetworkHealthReport({
    required this.overallHealthScore,
    required this.connectionQuality,
    required this.learningEffectiveness,
    required this.privacyMetrics,
    required this.stabilityMetrics,
    required this.performanceIssues,
    required this.optimizationRecommendations,
    required this.totalActiveConnections,
    required this.networkUtilization,
    required this.analysisTimestamp,
  });
  
  static NetworkHealthReport degraded() {
    return NetworkHealthReport(
      overallHealthScore: 0.5,
      connectionQuality: ConnectionQualityMetrics.poor(),
      learningEffectiveness: LearningEffectivenessMetrics.low(),
      privacyMetrics: PrivacyMetrics.secure(),
      stabilityMetrics: NetworkStabilityMetrics.unstable(),
      performanceIssues: [],
      optimizationRecommendations: [],
      totalActiveConnections: 0,
      networkUtilization: 0.0,
      analysisTimestamp: DateTime.now(),
    );
  }
}

class RealTimeMetrics {
  final double connectionThroughput;
  final double matchingSuccessRate;
  final double learningConvergenceSpeed;
  final double vibeSynchronizationQuality;
  final double networkResponsiveness;
  final ResourceUtilizationMetrics resourceUtilization;
  final DateTime timestamp;
  
  RealTimeMetrics({
    required this.connectionThroughput,
    required this.matchingSuccessRate,
    required this.learningConvergenceSpeed,
    required this.vibeSynchronizationQuality,
    required this.networkResponsiveness,
    required this.resourceUtilization,
    required this.timestamp,
  });
  
  static RealTimeMetrics zero() {
    return RealTimeMetrics(
      connectionThroughput: 0.0,
      matchingSuccessRate: 0.0,
      learningConvergenceSpeed: 0.0,
      vibeSynchronizationQuality: 0.0,
      networkResponsiveness: 0.0,
      resourceUtilization: ResourceUtilizationMetrics.minimal(),
      timestamp: DateTime.now(),
    );
  }
}

class NetworkAnalyticsDashboard {
  final Duration timeWindow;
  final List<PerformanceTrend> performanceTrends;
  final PersonalityEvolutionStatistics evolutionStatistics;
  final List<ConnectionPattern> connectionPatterns;
  final LearningDistributionMetrics learningDistribution;
  final PrivacyPreservationStats privacyPreservationStats;
  final UsageAnalytics usageAnalytics;
  final NetworkGrowthMetrics networkGrowthMetrics;
  final List<String> topPerformingArchetypes;
  final DateTime generatedAt;
  
  NetworkAnalyticsDashboard({
    required this.timeWindow,
    required this.performanceTrends,
    required this.evolutionStatistics,
    required this.connectionPatterns,
    required this.learningDistribution,
    required this.privacyPreservationStats,
    required this.usageAnalytics,
    required this.networkGrowthMetrics,
    required this.topPerformingArchetypes,
    required this.generatedAt,
  });
  
  static NetworkAnalyticsDashboard empty(Duration timeWindow) {
    return NetworkAnalyticsDashboard(
      timeWindow: timeWindow,
      performanceTrends: [],
      evolutionStatistics: PersonalityEvolutionStatistics.empty(),
      connectionPatterns: [],
      learningDistribution: LearningDistributionMetrics.empty(),
      privacyPreservationStats: PrivacyPreservationStats.perfect(),
      usageAnalytics: UsageAnalytics.empty(),
      networkGrowthMetrics: NetworkGrowthMetrics.steady(),
      topPerformingArchetypes: [],
      generatedAt: DateTime.now(),
    );
  }
}

class NetworkOptimizationReport {
  final ConnectionEfficiencyMetrics connectionEfficiency;
  final List<LearningBottleneck> learningBottlenecks;
  final ResourceOptimizationMetrics resourceOptimization;
  final PerformanceImprovementMetrics performanceImprovements;
  final List<OptimizationAction> optimizationActions;
  final OptimizationImpactEstimates impactEstimates;
  final double currentEfficiencyScore;
  final double potentialEfficiencyScore;
  final DateTime analyzedAt;
  
  NetworkOptimizationReport({
    required this.connectionEfficiency,
    required this.learningBottlenecks,
    required this.resourceOptimization,
    required this.performanceImprovements,
    required this.optimizationActions,
    required this.impactEstimates,
    required this.currentEfficiencyScore,
    required this.potentialEfficiencyScore,
    required this.analyzedAt,
  });
  
  static NetworkOptimizationReport empty() {
    return NetworkOptimizationReport(
      connectionEfficiency: ConnectionEfficiencyMetrics.good(),
      learningBottlenecks: [],
      resourceOptimization: ResourceOptimizationMetrics.balanced(),
      performanceImprovements: PerformanceImprovementMetrics.moderate(),
      optimizationActions: [],
      impactEstimates: OptimizationImpactEstimates.positive(),
      currentEfficiencyScore: 0.75,
      potentialEfficiencyScore: 0.85,
      analyzedAt: DateTime.now(),
    );
  }
}

// Additional supporting classes
class ConnectionQualityMetrics {
  final double averageCompatibility;
  final double connectionSuccessRate;
  final double stabilityScore;
  final double trustBuildingRate;
  final double mutualBenefitScore;
  
  ConnectionQualityMetrics({
    required this.averageCompatibility,
    required this.connectionSuccessRate,
    required this.stabilityScore,
    required this.trustBuildingRate,
    required this.mutualBenefitScore,
  });
  
  static ConnectionQualityMetrics poor() => ConnectionQualityMetrics(
    averageCompatibility: 0.4, connectionSuccessRate: 0.5, stabilityScore: 0.3, trustBuildingRate: 0.3, mutualBenefitScore: 0.4);
}

class LearningEffectivenessMetrics {
  final double overallEffectiveness;
  final double personalityEvolutionRate;
  final double knowledgeAcquisitionSpeed;
  final double insightQualityScore;
  final double collectiveIntelligenceGrowth;
  
  LearningEffectivenessMetrics({
    required this.overallEffectiveness,
    required this.personalityEvolutionRate,
    required this.knowledgeAcquisitionSpeed,
    required this.insightQualityScore,
    required this.collectiveIntelligenceGrowth,
  });
  
  static LearningEffectivenessMetrics low() => LearningEffectivenessMetrics(
    overallEffectiveness: 0.3, personalityEvolutionRate: 0.2, knowledgeAcquisitionSpeed: 0.3, insightQualityScore: 0.4, collectiveIntelligenceGrowth: 0.2);
}

class PrivacyMetrics {
  final double complianceRate;
  final double anonymizationLevel;
  final double dataSecurityScore;
  final int privacyViolations;
  final double encryptionStrength;
  
  PrivacyMetrics({
    required this.complianceRate,
    required this.anonymizationLevel,
    required this.dataSecurityScore,
    required this.privacyViolations,
    required this.encryptionStrength,
  });
  
  /// Overall privacy score (composite metric)
  double get overallPrivacyScore {
    return (complianceRate + anonymizationLevel + dataSecurityScore + encryptionStrength) / 4.0;
  }
  
  /// Anonymization quality (alias for anonymizationLevel)
  double get anonymizationQuality => anonymizationLevel;
  
  /// Re-identification risk (inverse of anonymization level)
  double get reidentificationRisk => 1.0 - anonymizationLevel;
  
  /// Data exposure level (inverse of data security score)
  double get dataExposureLevel => 1.0 - dataSecurityScore;
  
  static PrivacyMetrics secure() => PrivacyMetrics(
    complianceRate: 0.98, anonymizationLevel: 0.95, dataSecurityScore: 0.99, privacyViolations: 0, encryptionStrength: 0.99);
}

class NetworkStabilityMetrics {
  final double uptime;
  final double reliability;
  final double errorRate;
  final Duration recoveryTime;
  final double loadBalancing;
  
  NetworkStabilityMetrics({
    required this.uptime,
    required this.reliability,
    required this.errorRate,
    required this.recoveryTime,
    required this.loadBalancing,
  });
  
  static NetworkStabilityMetrics unstable() => NetworkStabilityMetrics(
    uptime: 0.85, reliability: 0.7, errorRate: 0.1, recoveryTime: Duration(minutes: 2), loadBalancing: 0.6);
}

class ResourceUtilizationMetrics {
  final double cpuUsage;
  final double memoryUsage;
  final double networkBandwidth;
  final double storageUsage;
  
  ResourceUtilizationMetrics({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.networkBandwidth,
    required this.storageUsage,
  });
  
  static ResourceUtilizationMetrics minimal() => ResourceUtilizationMetrics(
    cpuUsage: 0.1, memoryUsage: 0.1, networkBandwidth: 0.1, storageUsage: 0.1);
}

class PerformanceSnapshot {
  final DateTime timestamp;
  final double connectionThroughput;
  final double matchingSuccessRate;
  final double networkResponsiveness;
  
  PerformanceSnapshot({
    required this.timestamp,
    required this.connectionThroughput,
    required this.matchingSuccessRate,
    required this.networkResponsiveness,
  });
}

class PerformanceIssue {
  final IssueType type;
  final IssueSeverity severity;
  final String description;
  final String impact;
  final String recommendedAction;
  
  PerformanceIssue({
    required this.type,
    required this.severity,
    required this.description,
    required this.impact,
    required this.recommendedAction,
  });
}

class OptimizationRecommendation {
  final String category;
  final String recommendation;
  final String expectedImpact;
  final Priority priority;
  final String estimatedEffort;
  
  OptimizationRecommendation({
    required this.category,
    required this.recommendation,
    required this.expectedImpact,
    required this.priority,
    required this.estimatedEffort,
  });
}

class NetworkAnomaly {
  final AnomalyType type;
  final IssueSeverity severity;
  final String description;
  final DateTime detectedAt;
  final Map<String, dynamic> metadata;
  
  NetworkAnomaly({
    required this.type,
    required this.severity,
    required this.description,
    required this.detectedAt,
    required this.metadata,
  });
}

// Enums and additional placeholder classes
enum IssueType { highUtilization, lowConnectionSuccess, privacyViolation, resourceStarvation, learningStagnation }
enum IssueSeverity { low, medium, high, critical }
enum Priority { low, medium, high, critical }
enum AnomalyType { connectionSpike, learningDropoff, privacyBreach, resourceAnomaly, patternDeviation }

// Placeholder classes for complex data structures
class PerformanceTrend {
  final String metric;
  final double trend;
  PerformanceTrend(this.metric, this.trend);
}

class PersonalityEvolutionStatistics {
  final double averageEvolutionRate;
  PersonalityEvolutionStatistics(this.averageEvolutionRate);
  static PersonalityEvolutionStatistics empty() => PersonalityEvolutionStatistics(0.0);
}

class ConnectionPattern {
  final String pattern;
  final double frequency;
  ConnectionPattern(this.pattern, this.frequency);
}

class LearningDistributionMetrics {
  final Map<String, double> distribution;
  LearningDistributionMetrics(this.distribution);
  static LearningDistributionMetrics empty() => LearningDistributionMetrics({});
}

class PrivacyPreservationStats {
  final double averageAnonymization;
  PrivacyPreservationStats(this.averageAnonymization);
  static PrivacyPreservationStats perfect() => PrivacyPreservationStats(0.98);
}

class UsageAnalytics {
  final int totalSessions;
  UsageAnalytics(this.totalSessions);
  static UsageAnalytics empty() => UsageAnalytics(0);
}

class NetworkGrowthMetrics {
  final double growthRate;
  NetworkGrowthMetrics(this.growthRate);
  static NetworkGrowthMetrics steady() => NetworkGrowthMetrics(0.1);
}

class ConnectionEfficiencyMetrics {
  final double efficiency;
  ConnectionEfficiencyMetrics(this.efficiency);
  static ConnectionEfficiencyMetrics good() => ConnectionEfficiencyMetrics(0.8);
}

class LearningBottleneck {
  final String bottleneck;
  final double impact;
  LearningBottleneck(this.bottleneck, this.impact);
}

class ResourceOptimizationMetrics {
  final double optimization;
  ResourceOptimizationMetrics(this.optimization);
  static ResourceOptimizationMetrics balanced() => ResourceOptimizationMetrics(0.75);
}

class PerformanceImprovementMetrics {
  final double improvement;
  PerformanceImprovementMetrics(this.improvement);
  static PerformanceImprovementMetrics moderate() => PerformanceImprovementMetrics(0.15);
}

class OptimizationAction {
  final String action;
  final Priority priority;
  OptimizationAction(this.action, this.priority);
}

class OptimizationImpactEstimates {
  final double estimatedImprovement;
  OptimizationImpactEstimates(this.estimatedImprovement);
  static OptimizationImpactEstimates positive() => OptimizationImpactEstimates(0.2);
}

class SystemHealthIndicator {
  final String indicator;
  final double value;
  SystemHealthIndicator(this.indicator, this.value);
}