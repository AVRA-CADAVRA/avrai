import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:spots/core/services/performance_monitor.dart';
import 'package:shared_preferences/shared_preferences.dart' as real_prefs;
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/mock_dependencies.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

void main() {
  group('PerformanceMonitor Tests', () {
    late PerformanceMonitor monitor;
    late MockStorageService mockStorageService;
    late SharedPreferences prefs;

    setUpAll(() async {
      await setupTestStorage();
      real_prefs.SharedPreferences.setMockInitialValues({});
    });

    setUp(() async {
      mockStorageService = MockStorageService();
      prefs = await real_prefs.SharedPreferences.getInstance();
      
      monitor = PerformanceMonitor(
        storageService: mockStorageService,
        prefs: prefs,
      );
    });

    tearDown(() async {
      await monitor.stopMonitoring();
      await prefs.clear();
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    group('trackMetric', () {
      test('tracks metric successfully', () async {
        // Arrange
        when(mockStorageService.setObject(
          any,
          any,
          box: anyNamed('box'),
        )).thenAnswer((_) async => true);

        // Act
        await monitor.trackMetric('test_metric', 42.0);

        // Assert
        verify(mockStorageService.setObject(
          any,
          any,
          box: anyNamed('box'),
        )).called(greaterThan(0));
      });

      test('tracks multiple metrics', () async {
        // Arrange
        when(mockStorageService.setObject(
          any,
          any,
          box: anyNamed('box'),
        )).thenAnswer((_) async => true);

        // Act
        await monitor.trackMetric('metric1', 10.0);
        await monitor.trackMetric('metric2', 20.0);
        await monitor.trackMetric('metric3', 30.0);

        // Assert - metrics should be tracked
        verify(mockStorageService.setObject(
          any,
          any,
          box: anyNamed('box'),
        )).called(greaterThan(0));
      });
    });

    group('generateReport', () {
      test('generates report with tracked metrics', () async {
        // Arrange
        when(mockStorageService.setObject(
          any,
          any,
          box: anyNamed('box'),
        )).thenAnswer((_) async => true);

        await monitor.trackMetric('memory_usage', 150.0);
        await monitor.trackMetric('response_time', 500.0);

        // Act
        final report = await monitor.generateReport(const Duration(hours: 1));

        // Assert
        expect(report, isNotNull);
        expect(report.timeWindow, equals(const Duration(hours: 1)));
        expect(report.totalMetrics, greaterThan(0));
      });

      test('generates empty report when no metrics', () async {
        // Act
        final report = await monitor.generateReport(const Duration(hours: 1));

        // Assert
        expect(report, isNotNull);
        expect(report.totalMetrics, equals(0));
      });
    });

    group('monitoring lifecycle', () {
      test('starts and stops monitoring', () async {
        // Act
        await monitor.startMonitoring();
        await monitor.stopMonitoring();

        // Assert - no exceptions thrown
        expect(monitor, isNotNull);
      });
    });
  });
}

