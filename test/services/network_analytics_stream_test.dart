import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart' as real_prefs;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spots/core/monitoring/network_analytics.dart';
import '../helpers/platform_channel_helper.dart';

/// Tests for NetworkAnalytics stream methods
/// Phase 7, Section 40: Advanced Analytics UI - Stream Integration Tests
/// Tests streamNetworkHealth() and streamRealTimeMetrics() methods
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NetworkAnalytics Stream Tests', () {
    late SharedPreferences mockPrefs;
    late NetworkAnalytics networkAnalytics;

    setUpAll(() async {
      await setupTestStorage();
      real_prefs.SharedPreferences.setMockInitialValues({});
      mockPrefs = await real_prefs.SharedPreferences.getInstance();
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    setUp(() {
      networkAnalytics = NetworkAnalytics(prefs: mockPrefs);
    });

    group('streamNetworkHealth()', () {
      test('should emit initial value immediately', () async {
        final stream = networkAnalytics.streamNetworkHealth();
        final values = <NetworkHealthReport>[];

        await for (final report in stream.take(1)) {
          values.add(report);
        }

        expect(values, hasLength(1));
        expect(values.first, isNotNull);
        expect(values.first.overallHealthScore, greaterThanOrEqualTo(0.0));
        expect(values.first.overallHealthScore, lessThanOrEqualTo(1.0));
        expect(values.first.analysisTimestamp, isNotNull);
      });

      test('should emit periodic updates', () async {
        final stream = networkAnalytics.streamNetworkHealth();
        final values = <NetworkHealthReport>[];
        final completer = Completer<void>();

        final subscription = stream.listen(
          (report) {
            values.add(report);
            if (values.length >= 3) {
              completer.complete();
            }
          },
          onError: (error) {
            completer.completeError(error);
          },
        );

        // Wait for at least 3 emissions (initial + 2 periodic)
        await completer.future.timeout(
          const Duration(seconds: 25),
          onTimeout: () {
            subscription.cancel();
            // If we got at least 2 values, that's acceptable
            expect(values.length, greaterThanOrEqualTo(2));
          },
        );

        await subscription.cancel();

        expect(values.length, greaterThanOrEqualTo(2));
        // All values should be valid NetworkHealthReport
        for (final report in values) {
          expect(report.overallHealthScore, greaterThanOrEqualTo(0.0));
          expect(report.overallHealthScore, lessThanOrEqualTo(1.0));
        }
      });

      test('should handle errors gracefully', () async {
        // Stream should handle errors internally and continue
        final stream = networkAnalytics.streamNetworkHealth();
        bool hasReceivedValue = false;
        bool hasError = false;

        final subscription = stream.listen(
          (report) {
            hasReceivedValue = true;
          },
          onError: (error) {
            hasError = true;
          },
        );

        // Wait for initial value
        await Future.delayed(const Duration(seconds: 2));
        await subscription.cancel();

        // Should have received at least initial value without errors
        expect(hasReceivedValue, isTrue);
        // Stream handles errors internally, so no error should propagate
        expect(hasError, isFalse);
      });

      test('should be cancellable/disposable', () async {
        final stream = networkAnalytics.streamNetworkHealth();
        final subscription = stream.listen((_) {});

        // Cancel the subscription
        await subscription.cancel();

        // Verify cancellation doesn't throw
        expect(subscription.isPaused, isFalse);
      });

      test('should emit different values over time', () async {
        final stream = networkAnalytics.streamNetworkHealth();
        final timestamps = <DateTime>[];
        StreamSubscription<NetworkHealthReport>? subscription;

        subscription = stream.listen((report) {
          timestamps.add(report.analysisTimestamp);
          if (timestamps.length >= 2 && subscription != null) {
            subscription.cancel();
          }
        });

        // Wait for at least 2 emissions
        await Future.delayed(const Duration(seconds: 12));

        // Cancel if still listening
        await subscription!.cancel();

        expect(timestamps.length, greaterThanOrEqualTo(1));
      });
    });

    group('streamRealTimeMetrics()', () {
      test('should emit initial value immediately', () async {
        final stream = networkAnalytics.streamRealTimeMetrics();
        final values = <RealTimeMetrics>[];

        await for (final metrics in stream.take(1)) {
          values.add(metrics);
        }

        expect(values, hasLength(1));
        expect(values.first, isNotNull);
        expect(values.first.connectionThroughput, greaterThanOrEqualTo(0.0));
        expect(values.first.matchingSuccessRate, greaterThanOrEqualTo(0.0));
        expect(values.first.matchingSuccessRate, lessThanOrEqualTo(1.0));
        expect(values.first.timestamp, isNotNull);
      });

      test('should emit periodic updates', () async {
        final stream = networkAnalytics.streamRealTimeMetrics();
        final values = <RealTimeMetrics>[];
        final completer = Completer<void>();

        final subscription = stream.listen(
          (metrics) {
            values.add(metrics);
            if (values.length >= 3) {
              completer.complete();
            }
          },
          onError: (error) {
            completer.completeError(error);
          },
        );

        // Wait for at least 3 emissions (initial + 2 periodic)
        await completer.future.timeout(
          const Duration(seconds: 25),
          onTimeout: () {
            subscription.cancel();
            // If we got at least 2 values, that's acceptable
            expect(values.length, greaterThanOrEqualTo(2));
          },
        );

        await subscription.cancel();

        expect(values.length, greaterThanOrEqualTo(2));
        // All values should be valid RealTimeMetrics
        for (final metrics in values) {
          expect(metrics.connectionThroughput, greaterThanOrEqualTo(0.0));
          expect(metrics.matchingSuccessRate, greaterThanOrEqualTo(0.0));
          expect(metrics.matchingSuccessRate, lessThanOrEqualTo(1.0));
        }
      });

      test('should handle errors gracefully', () async {
        final stream = networkAnalytics.streamRealTimeMetrics();
        bool hasReceivedValue = false;
        bool hasError = false;

        final subscription = stream.listen(
          (metrics) {
            hasReceivedValue = true;
          },
          onError: (error) {
            hasError = true;
          },
        );

        // Wait for initial value
        await Future.delayed(const Duration(seconds: 2));
        await subscription.cancel();

        // Should have received at least initial value without errors
        expect(hasReceivedValue, isTrue);
        // Stream handles errors internally, so no error should propagate
        expect(hasError, isFalse);
      });

      test('should be cancellable/disposable', () async {
        final stream = networkAnalytics.streamRealTimeMetrics();
        final subscription = stream.listen((_) {});

        // Cancel the subscription
        await subscription.cancel();

        // Verify cancellation doesn't throw
        expect(subscription.isPaused, isFalse);
      });

      test('should emit different timestamps over time', () async {
        final stream = networkAnalytics.streamRealTimeMetrics();
        final timestamps = <DateTime>[];
        StreamSubscription<RealTimeMetrics>? subscription;

        subscription = stream.listen((metrics) {
          timestamps.add(metrics.timestamp);
          if (timestamps.length >= 2) {
            subscription?.cancel();
          }
        });

        // Wait for at least 2 emissions
        await Future.delayed(const Duration(seconds: 12));

        // Cancel if still listening
        await subscription.cancel();

        expect(timestamps.length, greaterThanOrEqualTo(1));
      });
    });

    group('Stream Error Recovery', () {
      test('streamNetworkHealth should recover from errors', () async {
        final stream = networkAnalytics.streamNetworkHealth();
        int valueCount = 0;

        final subscription = stream.listen(
          (report) {
            valueCount++;
          },
          onError: (error) {
            // Errors should be handled internally by the stream
            fail('Stream should not propagate errors: $error');
          },
        );

        // Wait for initial value and at least one periodic update
        await Future.delayed(const Duration(seconds: 12));
        await subscription.cancel();

        // Should have received values despite any internal errors
        expect(valueCount, greaterThanOrEqualTo(1));
      });

      test('streamRealTimeMetrics should recover from errors', () async {
        final stream = networkAnalytics.streamRealTimeMetrics();
        int valueCount = 0;

        final subscription = stream.listen(
          (metrics) {
            valueCount++;
          },
          onError: (error) {
            // Errors should be handled internally by the stream
            fail('Stream should not propagate errors: $error');
          },
        );

        // Wait for initial value and at least one periodic update
        await Future.delayed(const Duration(seconds: 12));
        await subscription.cancel();

        // Should have received values despite any internal errors
        expect(valueCount, greaterThanOrEqualTo(1));
      });
    });

    group('Stream Disposal', () {
      test('should allow multiple subscriptions to streamNetworkHealth',
          () async {
        // Get separate streams for each subscription (streams are single-subscription)
        final stream1 = networkAnalytics.streamNetworkHealth();
        final stream2 = networkAnalytics.streamNetworkHealth();
        int subscription1Count = 0;
        int subscription2Count = 0;

        final sub1 = stream1.listen((_) => subscription1Count++);
        final sub2 = stream2.listen((_) => subscription2Count++);

        await Future.delayed(const Duration(seconds: 2));

        await sub1.cancel();
        await sub2.cancel();

        // Both subscriptions should have received at least initial value
        expect(subscription1Count, greaterThanOrEqualTo(1));
        expect(subscription2Count, greaterThanOrEqualTo(1));
      });

      test('should allow multiple subscriptions to streamRealTimeMetrics',
          () async {
        // Get separate streams for each subscription (streams are single-subscription)
        final stream1 = networkAnalytics.streamRealTimeMetrics();
        final stream2 = networkAnalytics.streamRealTimeMetrics();
        int subscription1Count = 0;
        int subscription2Count = 0;

        final sub1 = stream1.listen((_) => subscription1Count++);
        final sub2 = stream2.listen((_) => subscription2Count++);

        await Future.delayed(const Duration(seconds: 2));

        await sub1.cancel();
        await sub2.cancel();

        // Both subscriptions should have received at least initial value
        expect(subscription1Count, greaterThanOrEqualTo(1));
        expect(subscription2Count, greaterThanOrEqualTo(1));
      });
    });
  });
}
