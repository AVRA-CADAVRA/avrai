import 'dart:developer' as developer;
import 'dart:async';
import 'dart:io';
import 'package:spots/core/services/storage_service.dart' show SharedPreferencesCompat, StorageService;
import 'package:spots/core/services/logger.dart';

/// OUR_GUTS.md: "Effortless, Seamless Discovery" - Performance monitoring for seamless UX
/// Service for monitoring application performance metrics
class PerformanceMonitor {
  static const String _logName = 'PerformanceMonitor';
  final AppLogger _logger = const AppLogger(defaultTag: 'Performance', minimumLevel: LogLevel.debug);
  
  // Storage keys
  static const String _metricsKey = 'performance_metrics';
  static const String _alertsKey = 'performance_alerts';
  
  final StorageService _storageService;
  final SharedPreferencesCompat _prefs;
  
  // Monitoring state
  bool _isMonitoring = false;
  Timer? _monitoringTimer;
  
  // Performance metrics
  final List<PerformanceMetric> _metrics = [];
  final List<PerformanceAlert> _alerts = [];
  
  // Thresholds
  static const int _memoryWarningThresholdMB = 200;
  static const int _memoryCriticalThresholdMB = 300;
  static const Duration _responseTimeWarningThreshold = Duration(milliseconds: 1000);
  static const Duration _responseTimeCriticalThreshold = Duration(milliseconds: 2000);
  
  PerformanceMonitor({
    required StorageService storageService,
    required SharedPreferencesCompat prefs,
  }) : _storageService = storageService,
       _prefs = prefs;
  
  /// Start performance monitoring
  Future<void> startMonitoring() async {
    if (_isMonitoring) {
      developer.log('Performance monitoring already active', name: _logName);
      return;
    }
    
    try {
      _isMonitoring = true;
      _logger.info('Starting performance monitoring', tag: _logName);
      
      // Start periodic monitoring
      _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _collectMetrics();
      });
      
      // Initial metric collection
      await _collectMetrics();
      
      _logger.info('Performance monitoring started', tag: _logName);
    } catch (e) {
      _logger.error('Error starting performance monitoring', error: e, tag: _logName);
      _isMonitoring = false;
    }
  }
  
  /// Stop performance monitoring
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) {
      return;
    }
    
    try {
      _isMonitoring = false;
      _monitoringTimer?.cancel();
      _monitoringTimer = null;
      
      _logger.info('Performance monitoring stopped', tag: _logName);
    } catch (e) {
      _logger.error('Error stopping performance monitoring', error: e, tag: _logName);
    }
  }
  
  /// Get current memory usage in bytes
  Future<int> getCurrentMemoryUsage() async {
    try {
      // On mobile platforms, we can't directly get memory usage
      // This is a placeholder that would integrate with platform-specific APIs
      // For now, return estimated usage based on app state
      
      if (Platform.isAndroid || Platform.isIOS) {
        // Platform-specific memory tracking would go here
        // For now, return a reasonable estimate
        return 100 * 1024 * 1024; // 100MB estimate
      }
      
      // For web/desktop, could use ProcessInfo if available
      return 100 * 1024 * 1024; // Default estimate
    } catch (e) {
      _logger.error('Error getting memory usage', error: e, tag: _logName);
      return 0;
    }
  }
  
  /// Track a performance metric
  Future<void> trackMetric(String metricName, double value) async {
    try {
      final metric = PerformanceMetric(
        name: metricName,
        value: value,
        timestamp: DateTime.now(),
      );
      
      _metrics.add(metric);
      
      // Keep only recent metrics (last 1000)
      if (_metrics.length > 1000) {
        _metrics.removeRange(0, _metrics.length - 1000);
      }
      
      // Check thresholds and generate alerts
      await _checkThresholds(metric);
      
      // Persist metrics periodically
      if (_metrics.length % 10 == 0) {
        await _persistMetrics();
      }
    } catch (e) {
      _logger.error('Error tracking metric', error: e, tag: _logName);
    }
  }
  
  /// Generate performance report
  Future<PerformanceReport> generateReport(Duration timeWindow) async {
    try {
      final cutoff = DateTime.now().subtract(timeWindow);
      final recentMetrics = _metrics
          .where((m) => m.timestamp.isAfter(cutoff))
          .toList();
      
      // Calculate averages
      final avgMemory = recentMetrics
          .where((m) => m.name == 'memory_usage')
          .map((m) => m.value)
          .fold(0.0, (a, b) => a + b) / 
          (recentMetrics.where((m) => m.name == 'memory_usage').length);
      
      final avgResponseTime = recentMetrics
          .where((m) => m.name == 'response_time')
          .map((m) => m.value)
          .fold(0.0, (a, b) => a + b) / 
          (recentMetrics.where((m) => m.name == 'response_time').length);
      
      // Get recent alerts
      final recentAlerts = _alerts
          .where((a) => a.timestamp.isAfter(cutoff))
          .toList();
      
      return PerformanceReport(
        timeWindow: timeWindow,
        averageMemoryUsageMB: avgMemory.isNaN ? 0.0 : avgMemory,
        averageResponseTimeMs: avgResponseTime.isNaN ? 0.0 : avgResponseTime,
        totalMetrics: recentMetrics.length,
        alerts: recentAlerts,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.error('Error generating performance report', error: e, tag: _logName);
      return PerformanceReport.empty();
    }
  }
  
  /// Alert on threshold breach
  void alertOnThreshold(String metric, double threshold) {
    // This would set up automatic alerting
    // Implementation would depend on alerting system
    developer.log('Alert threshold set for $metric: $threshold', name: _logName);
  }
  
  // Private helper methods
  
  /// Collect current performance metrics
  Future<void> _collectMetrics() async {
    try {
      // Memory usage
      final memoryUsage = await getCurrentMemoryUsage();
      await trackMetric('memory_usage', memoryUsage / (1024 * 1024)); // Convert to MB
      
      // Response time (would be tracked from actual operations)
      // This is a placeholder - in real implementation, would track actual API calls
      
    } catch (e) {
      _logger.error('Error collecting metrics', error: e, tag: _logName);
    }
  }
  
  /// Check metric thresholds and generate alerts
  Future<void> _checkThresholds(PerformanceMetric metric) async {
    try {
      if (metric.name == 'memory_usage') {
        if (metric.value >= _memoryCriticalThresholdMB) {
          await _createAlert(
            metric.name,
            'Critical',
            'Memory usage is critically high: ${metric.value.toStringAsFixed(1)}MB',
          );
        } else if (metric.value >= _memoryWarningThresholdMB) {
          await _createAlert(
            metric.name,
            'Warning',
            'Memory usage is high: ${metric.value.toStringAsFixed(1)}MB',
          );
        }
      } else if (metric.name == 'response_time') {
        final responseTime = Duration(milliseconds: metric.value.round());
        if (responseTime >= _responseTimeCriticalThreshold) {
          await _createAlert(
            metric.name,
            'Critical',
            'Response time is critically slow: ${responseTime.inMilliseconds}ms',
          );
        } else if (responseTime >= _responseTimeWarningThreshold) {
          await _createAlert(
            metric.name,
            'Warning',
            'Response time is slow: ${responseTime.inMilliseconds}ms',
          );
        }
      }
    } catch (e) {
      _logger.error('Error checking thresholds', error: e, tag: _logName);
    }
  }
  
  /// Create performance alert
  Future<void> _createAlert(String metric, String severity, String message) async {
    try {
      final alert = PerformanceAlert(
        metric: metric,
        severity: severity,
        message: message,
        timestamp: DateTime.now(),
      );
      
      _alerts.add(alert);
      
      // Keep only recent alerts (last 100)
      if (_alerts.length > 100) {
        _alerts.removeRange(0, _alerts.length - 100);
      }
      
      _logger.warn('Performance alert: $severity - $message', tag: _logName);
      
      // Persist alerts
      await _persistAlerts();
    } catch (e) {
      _logger.error('Error creating alert', error: e, tag: _logName);
    }
  }
  
  /// Persist metrics to storage
  Future<void> _persistMetrics() async {
    try {
      final metricsJson = _metrics
          .map((m) => {
                'name': m.name,
                'value': m.value,
                'timestamp': m.timestamp.toIso8601String(),
              })
          .toList();
      
      await _storageService.setObject(
        _metricsKey,
        metricsJson,
        box: 'spots_analytics',
      );
    } catch (e) {
      _logger.error('Error persisting metrics', error: e, tag: _logName);
    }
  }
  
  /// Persist alerts to storage
  Future<void> _persistAlerts() async {
    try {
      final alertsJson = _alerts
          .map((a) => {
                'metric': a.metric,
                'severity': a.severity,
                'message': a.message,
                'timestamp': a.timestamp.toIso8601String(),
              })
          .toList();
      
      await _storageService.setObject(
        _alertsKey,
        alertsJson,
        box: 'spots_analytics',
      );
    } catch (e) {
      _logger.error('Error persisting alerts', error: e, tag: _logName);
    }
  }
}

/// Performance metric data
class PerformanceMetric {
  final String name;
  final double value;
  final DateTime timestamp;
  
  PerformanceMetric({
    required this.name,
    required this.value,
    required this.timestamp,
  });
}

/// Performance alert
class PerformanceAlert {
  final String metric;
  final String severity;
  final String message;
  final DateTime timestamp;
  
  PerformanceAlert({
    required this.metric,
    required this.severity,
    required this.message,
    required this.timestamp,
  });
}

/// Performance report
class PerformanceReport {
  final Duration timeWindow;
  final double averageMemoryUsageMB;
  final double averageResponseTimeMs;
  final int totalMetrics;
  final List<PerformanceAlert> alerts;
  final DateTime generatedAt;
  
  PerformanceReport({
    required this.timeWindow,
    required this.averageMemoryUsageMB,
    required this.averageResponseTimeMs,
    required this.totalMetrics,
    required this.alerts,
    required this.generatedAt,
  });
  
  factory PerformanceReport.empty() {
    return PerformanceReport(
      timeWindow: const Duration(hours: 1),
      averageMemoryUsageMB: 0.0,
      averageResponseTimeMs: 0.0,
      totalMetrics: 0,
      alerts: [],
      generatedAt: DateTime.now(),
    );
  }
}


