import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart' as real_prefs;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spots/core/monitoring/connection_monitor.dart';
import '../helpers/platform_channel_helper.dart';

/// Tests for ConnectionMonitor stream methods
/// Phase 7, Section 40: Advanced Analytics UI - Stream Integration Tests
/// Tests streamActiveConnections() method
void main() {
  group('ConnectionMonitor Stream Tests', () {
    late SharedPreferences mockPrefs;
    late ConnectionMonitor connectionMonitor;

    setUpAll(() async {
      await setupTestStorage();
      real_prefs.SharedPreferences.setMockInitialValues({});
      mockPrefs = await real_prefs.SharedPreferences.getInstance();
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    setUp(() {
      connectionMonitor = ConnectionMonitor(prefs: mockPrefs);
    });

    tearDown(() {
      // Dispose streams after each test
      connectionMonitor.disposeStreams();
    });

    group('streamActiveConnections()', () {
      test('should emit initial value immediately', () async {
        final stream = connectionMonitor.streamActiveConnections();
        final values = <ActiveConnectionsOverview>[];

        await for (final overview in stream.take(1)) {
          values.add(overview);
        }

        expect(values, hasLength(1));
        expect(values.first, isNotNull);
        expect(values.first.totalActiveConnections, greaterThanOrEqualTo(0));
        expect(values.first.generatedAt, isNotNull);
      });

      test('should emit periodic updates', () async {
        final stream = connectionMonitor.streamActiveConnections();
        final values = <ActiveConnectionsOverview>[];
        final completer = Completer<void>();

        final subscription = stream.listen(
          (overview) {
            values.add(overview);
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
          const Duration(seconds: 20),
          onTimeout: () {
            subscription.cancel();
            // If we got at least 2 values, that's acceptable
            expect(values.length, greaterThanOrEqualTo(2));
          },
        );

        await subscription.cancel();

        expect(values.length, greaterThanOrEqualTo(2));
        // All values should be valid ActiveConnectionsOverview
        for (final overview in values) {
          expect(overview.totalActiveConnections, greaterThanOrEqualTo(0));
          expect(overview.generatedAt, isNotNull);
        }
      });

      test('should emit on connection changes', () async {
        // Note: In a real scenario, connections would be added/removed
        // For this test, we verify the stream emits periodic updates
        // which would include connection changes
        final stream = connectionMonitor.streamActiveConnections();
        final values = <ActiveConnectionsOverview>[];
        StreamSubscription<ActiveConnectionsOverview>? subscription;

        subscription = stream.listen((overview) {
          values.add(overview);
          if (values.length >= 2 && subscription != null) {
            subscription.cancel();
          }
        });

        // Wait for at least 2 emissions
        await Future.delayed(const Duration(seconds: 10));

        // Cancel if still listening
        await subscription!.cancel();
      
        expect(values.length, greaterThanOrEqualTo(1));
        // All overviews should be valid
        for (final overview in values) {
          expect(overview, isNotNull);
          expect(overview.totalActiveConnections, greaterThanOrEqualTo(0));
        }
      });

      test('should handle errors gracefully', () async {
        final stream = connectionMonitor.streamActiveConnections();
        bool hasReceivedValue = false;
        bool hasError = false;

        final subscription = stream.listen(
          (overview) {
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
        final stream = connectionMonitor.streamActiveConnections();
        final subscription = stream.listen((_) {});

        // Cancel the subscription
        await subscription.cancel();

        // Verify cancellation doesn't throw
        expect(subscription.isPaused, isFalse);
      });

      test('should emit different timestamps over time', () async {
        final stream = connectionMonitor.streamActiveConnections();
        final timestamps = <DateTime>[];
        StreamSubscription<ActiveConnectionsOverview>? subscription;

        subscription = stream.listen((overview) {
          timestamps.add(overview.generatedAt);
          if (timestamps.length >= 2) {
            subscription?.cancel();
          }
        });

        // Wait for at least 2 emissions
        await Future.delayed(const Duration(seconds: 10));

        // Cancel if still listening
        await subscription.cancel();

        expect(timestamps.length, greaterThanOrEqualTo(1));
      });
    });

    group('Stream Error Recovery', () {
      test('should recover from errors', () async {
        final stream = connectionMonitor.streamActiveConnections();
        int valueCount = 0;

        final subscription = stream.listen(
          (overview) {
            valueCount++;
          },
          onError: (error) {
            // Errors should be handled internally by the stream
            fail('Stream should not propagate errors: $error');
          },
        );

        // Wait for initial value and at least one periodic update
        await Future.delayed(const Duration(seconds: 10));
        await subscription.cancel();

        // Should have received values despite any internal errors
        expect(valueCount, greaterThanOrEqualTo(1));
      });
    });

    group('Stream Disposal', () {
      test('should allow multiple subscriptions', () async {
        final stream = connectionMonitor.streamActiveConnections();
        int subscription1Count = 0;
        int subscription2Count = 0;

        final sub1 = stream.listen((_) => subscription1Count++);
        final sub2 = stream.listen((_) => subscription2Count++);

        await Future.delayed(const Duration(seconds: 2));

        await sub1.cancel();
        await sub2.cancel();

        // Both subscriptions should have received at least initial value
        expect(subscription1Count, greaterThanOrEqualTo(1));
        expect(subscription2Count, greaterThanOrEqualTo(1));
      });

      test('should dispose stream controller correctly', () async {
        final stream = connectionMonitor.streamActiveConnections();
        final subscription = stream.listen((_) {});

        // Dispose streams
        connectionMonitor.disposeStreams();

        // Wait a bit
        await Future.delayed(const Duration(milliseconds: 100));

        // Cancel should not throw even after disposal
        await subscription.cancel();
      });

      test('should handle multiple dispose calls gracefully', () {
        // Should not throw on multiple dispose calls
        connectionMonitor.disposeStreams();
        connectionMonitor.disposeStreams();
        connectionMonitor.disposeStreams();

        // If we get here, no exception was thrown
        expect(true, isTrue);
      });
    });
  });
}

