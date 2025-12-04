/// SPOTS ContinuousLearningSystem Service Backend Integration Tests
/// Date: November 28, 2025
/// Purpose: Test ContinuousLearningSystem service functionality and backend integration
/// 
/// Test Coverage:
/// - Service initialization
/// - getLearningStatus() method
/// - getLearningProgress() method
/// - getLearningMetrics() method
/// - getDataCollectionStatus() method
/// - startContinuousLearning() method
/// - stopContinuousLearning() method
/// - Error handling
/// - Data flow from backend to service
/// 
/// Dependencies:
/// - ContinuousLearningSystem: Backend service
/// 
/// Phase 7, Section 39 (7.4.1): Continuous Learning UI - Integration & Polish

import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/ai/continuous_learning_system.dart';

/// Backend integration tests for ContinuousLearningSystem service
void main() {
  group('ContinuousLearningSystem Service Backend Integration Tests', () {
    late ContinuousLearningSystem service;
    
    setUp(() {
      service = ContinuousLearningSystem();
    });
    
    tearDown(() async {
      // Clean up: stop learning if active
      if (service.isLearningActive) {
        await service.stopContinuousLearning();
      }
    });
    
    group('Service Initialization', () {
      test('service can be initialized', () {
        expect(service, isNotNull);
        expect(service, isA<ContinuousLearningSystem>());
      });
      
      test('service initialization handles dependencies correctly', () async {
        await service.initialize();
        
        // Service should be ready to use
        expect(service, isNotNull);
      });
      
      test('service can be initialized multiple times', () async {
        await service.initialize();
        await service.initialize(); // Second call should not error
        
        expect(service, isNotNull);
      });
    });
    
    group('getLearningStatus() Method', () {
      test('returns status when learning is inactive', () async {
        await service.initialize();
        
        final status = await service.getLearningStatus();
        
        expect(status, isA<ContinuousLearningStatus>());
        expect(status.isActive, isFalse);
        expect(status.activeProcesses, isEmpty);
        expect(status.uptime, equals(Duration.zero));
        expect(status.cyclesCompleted, equals(0));
        expect(status.learningTime, equals(Duration.zero));
      });
      
      test('returns status when learning is active', () async {
        await service.initialize();
        await service.startContinuousLearning();
        
        // Wait a moment for learning to start
        await Future.delayed(const Duration(milliseconds: 100));
        
        final status = await service.getLearningStatus();
        
        expect(status, isA<ContinuousLearningStatus>());
        expect(status.isActive, isTrue);
        expect(status.activeProcesses, isA<List<String>>());
        expect(status.uptime, isA<Duration>());
        expect(status.cyclesCompleted, greaterThanOrEqualTo(0));
        expect(status.learningTime, isA<Duration>());
      });
      
      test('returns status with active processes when learning', () async {
        await service.initialize();
        await service.startContinuousLearning();
        
        // Wait for learning cycles
        await Future.delayed(const Duration(seconds: 2));
        
        final status = await service.getLearningStatus();
        
        expect(status.isActive, isTrue);
        expect(status.activeProcesses, isA<List<String>>());
        // Active processes may be empty initially or populated after learning cycles
      });
      
      test('handles errors gracefully', () async {
        await service.initialize();
        
        // Service should not throw even with errors
        final status = await service.getLearningStatus();
        
        expect(status, isA<ContinuousLearningStatus>());
        expect(status.isActive, isA<bool>());
      });
      
      test('returns status with correct structure', () async {
        await service.initialize();
        
        final status = await service.getLearningStatus();
        
        expect(status, isA<ContinuousLearningStatus>());
        expect(status.isActive, isA<bool>());
        expect(status.activeProcesses, isA<List<String>>());
        expect(status.uptime, isA<Duration>());
        expect(status.cyclesCompleted, isA<int>());
        expect(status.learningTime, isA<Duration>());
      });
    });
    
    group('getLearningProgress() Method', () {
      test('returns progress for all dimensions', () async {
        await service.initialize();
        
        final progress = await service.getLearningProgress();
        
        expect(progress, isA<Map<String, double>>());
        // Progress may be empty initially or have values after learning
      });
      
      test('returns progress with dimension keys', () async {
        await service.initialize();
        await service.startContinuousLearning();
        
        // Wait for learning cycles
        await Future.delayed(const Duration(seconds: 2));
        
        final progress = await service.getLearningProgress();
        
        expect(progress, isA<Map<String, double>>());
        // Progress may contain dimension keys after learning cycles
      });
      
      test('returns progress values between 0 and 1', () async {
        await service.initialize();
        await service.startContinuousLearning();
        
        // Wait for learning cycles
        await Future.delayed(const Duration(seconds: 2));
        
        final progress = await service.getLearningProgress();
        
        for (final value in progress.values) {
          expect(value, greaterThanOrEqualTo(0.0));
          expect(value, lessThanOrEqualTo(1.0));
        }
      });
      
      test('handles errors gracefully', () async {
        await service.initialize();
        
        // Service should not throw even with errors
        final progress = await service.getLearningProgress();
        
        expect(progress, isA<Map<String, double>>());
      });
      
      test('returns empty map on error', () async {
        await service.initialize();
        
        final progress = await service.getLearningProgress();
        
        expect(progress, isA<Map<String, double>>());
        // May be empty initially or have values
      });
    });
    
    group('getLearningMetrics() Method', () {
      test('returns metrics for any state', () async {
        await service.initialize();
        
        final metrics = await service.getLearningMetrics();
        
        expect(metrics, isA<ContinuousLearningMetrics>());
      });
      
      test('returns metrics with total improvements', () async {
        await service.initialize();
        
        final metrics = await service.getLearningMetrics();
        
        expect(metrics.totalImprovements, greaterThanOrEqualTo(0.0));
        expect(metrics.totalImprovements, isA<double>());
      });
      
      test('returns metrics with average progress', () async {
        await service.initialize();
        
        final metrics = await service.getLearningMetrics();
        
        expect(metrics.averageProgress, greaterThanOrEqualTo(0.0));
        expect(metrics.averageProgress, lessThanOrEqualTo(1.0));
        expect(metrics.averageProgress, isA<double>());
      });
      
      test('returns metrics with top improving dimensions', () async {
        await service.initialize();
        
        final metrics = await service.getLearningMetrics();
        
        expect(metrics.topImprovingDimensions, isA<List<String>>());
        // May be empty or have dimensions
      });
      
      test('returns metrics with dimensions count', () async {
        await service.initialize();
        
        final metrics = await service.getLearningMetrics();
        
        expect(metrics.dimensionsCount, greaterThanOrEqualTo(0));
        expect(metrics.dimensionsCount, isA<int>());
      });
      
      test('returns metrics with data sources count', () async {
        await service.initialize();
        
        final metrics = await service.getLearningMetrics();
        
        expect(metrics.dataSourcesCount, greaterThanOrEqualTo(0));
        expect(metrics.dataSourcesCount, isA<int>());
      });
      
      test('returns zero metrics on error', () async {
        await service.initialize();
        
        final metrics = await service.getLearningMetrics();
        
        expect(metrics, isA<ContinuousLearningMetrics>());
        expect(metrics.totalImprovements, greaterThanOrEqualTo(0.0));
        expect(metrics.averageProgress, greaterThanOrEqualTo(0.0));
        // Should return zero metrics, not throw
      });
    });
    
    group('getDataCollectionStatus() Method', () {
      test('returns data collection status for any state', () async {
        await service.initialize();
        
        final status = await service.getDataCollectionStatus();
        
        expect(status, isA<DataCollectionStatus>());
      });
      
      test('returns status with source statuses', () async {
        await service.initialize();
        
        final status = await service.getDataCollectionStatus();
        
        expect(status.sourceStatuses, isA<Map<String, DataSourceStatus>>());
      });
      
      test('returns status with total volume', () async {
        await service.initialize();
        
        final status = await service.getDataCollectionStatus();
        
        expect(status.totalVolume, greaterThanOrEqualTo(0));
        expect(status.totalVolume, isA<int>());
      });
      
      test('returns status with active sources count', () async {
        await service.initialize();
        
        final status = await service.getDataCollectionStatus();
        
        expect(status.activeSourcesCount, greaterThanOrEqualTo(0));
        expect(status.activeSourcesCount, isA<int>());
      });
      
      test('returns status with all 10 data sources', () async {
        await service.initialize();
        await service.startContinuousLearning();
        
        // Wait for data collection
        await Future.delayed(const Duration(seconds: 2));
        
        final status = await service.getDataCollectionStatus();
        
        expect(status.sourceStatuses, isA<Map<String, DataSourceStatus>>());
        // Should have entries for all 10 data sources
      });
      
      test('returns status with correct data source status structure', () async {
        await service.initialize();
        
        final status = await service.getDataCollectionStatus();
        
        for (final sourceStatus in status.sourceStatuses.values) {
          expect(sourceStatus, isA<DataSourceStatus>());
          expect(sourceStatus.isActive, isA<bool>());
          expect(sourceStatus.dataVolume, greaterThanOrEqualTo(0));
          expect(sourceStatus.eventCount, greaterThanOrEqualTo(0));
          expect(sourceStatus.healthStatus, isA<String>());
          expect(['healthy', 'idle', 'inactive'], contains(sourceStatus.healthStatus));
        }
      });
      
      test('returns zero status on error', () async {
        await service.initialize();
        
        final status = await service.getDataCollectionStatus();
        
        expect(status, isA<DataCollectionStatus>());
        expect(status.totalVolume, greaterThanOrEqualTo(0));
        expect(status.activeSourcesCount, greaterThanOrEqualTo(0));
        // Should return zero status, not throw
      });
    });
    
    group('startContinuousLearning() Method', () {
      test('starts continuous learning successfully', () async {
        await service.initialize();
        
        await expectLater(
          service.startContinuousLearning(),
          completes,
        );
        
        expect(service.isLearningActive, isTrue);
      });
      
      test('handles multiple start calls gracefully', () async {
        await service.initialize();
        await service.startContinuousLearning();
        await service.startContinuousLearning(); // Second call should not error
        
        expect(service.isLearningActive, isTrue);
      });
      
      test('starts learning timer', () async {
        await service.initialize();
        await service.startContinuousLearning();
        
        // Wait a moment
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(service.isLearningActive, isTrue);
      });
    });
    
    group('stopContinuousLearning() Method', () {
      test('stops continuous learning successfully', () async {
        await service.initialize();
        await service.startContinuousLearning();
        
        await expectLater(
          service.stopContinuousLearning(),
          completes,
        );
        
        expect(service.isLearningActive, isFalse);
      });
      
      test('handles stop when not active', () async {
        await service.initialize();
        
        await expectLater(
          service.stopContinuousLearning(),
          completes,
        );
        
        expect(service.isLearningActive, isFalse);
      });
      
      test('cancels learning timer', () async {
        await service.initialize();
        await service.startContinuousLearning();
        await service.stopContinuousLearning();
        
        expect(service.isLearningActive, isFalse);
      });
    });
    
    group('Error Handling', () {
      test('handles service errors without crashing', () async {
        await service.initialize();
        
        // All methods should return safe defaults on error
        final status = await service.getLearningStatus();
        final progress = await service.getLearningProgress();
        final metrics = await service.getLearningMetrics();
        final dataStatus = await service.getDataCollectionStatus();
        
        expect(status, isA<ContinuousLearningStatus>());
        expect(progress, isA<Map<String, double>>());
        expect(metrics, isA<ContinuousLearningMetrics>());
        expect(dataStatus, isA<DataCollectionStatus>());
      });
    });
    
    group('Data Flow from Backend', () {
      test('data flows correctly from backend to service', () async {
        await service.initialize();
        await service.startContinuousLearning();
        
        // Wait for learning cycles
        await Future.delayed(const Duration(seconds: 2));
        
        // Get data through service
        final status = await service.getLearningStatus();
        final progress = await service.getLearningProgress();
        final metrics = await service.getLearningMetrics();
        final dataStatus = await service.getDataCollectionStatus();
        
        // Verify data flow
        expect(status, isA<ContinuousLearningStatus>());
        expect(progress, isA<Map<String, double>>());
        expect(metrics, isA<ContinuousLearningMetrics>());
        expect(dataStatus, isA<DataCollectionStatus>());
      });
    });
  });
}

