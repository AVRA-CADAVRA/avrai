/// SPOTS InteractionEvent Phase 11 Enhancement Tests
/// Date: January 2026
/// Purpose: Test atomic timestamp field support in InteractionEvent
///
/// Test Coverage:
/// - Atomic timestamp field creation and serialization
/// - Atomic timestamp deserialization from JSON
/// - Backward compatibility with DateTime timestamp
/// - Atomic timestamp conversion from DateTime
///
/// Phase 11 Enhancement Testing
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/interaction_events.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';

void main() {
  group('InteractionEvent Atomic Timestamp Support', () {
    group('Atomic Timestamp Field Tests', () {
      test('should create InteractionEvent with atomicTimestamp', () {
        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: DateTime.now(),
          localTime: DateTime.now().toLocal(),
          timezoneId: 'UTC',
          offset: Duration.zero,
          isSynchronized: false,
        );
        
        final event = InteractionEvent(
          eventType: 'spot_visited',
          parameters: {'spot_id': 'spot-123'},
          context: InteractionContext.empty(),
          atomicTimestamp: atomicTimestamp,
        );
        
        expect(event.atomicTimestamp, isNotNull);
        expect(event.atomicTimestamp, equals(atomicTimestamp));
        expect(event.timestamp, isA<DateTime>());
      });

      test('should create InteractionEvent without atomicTimestamp (defaults to null)', () {
        final event = InteractionEvent(
          eventType: 'respect_tap',
          parameters: {'target_id': 'list-456'},
          context: InteractionContext.empty(),
        );
        
        expect(event.atomicTimestamp, isNull);
        expect(event.timestamp, isA<DateTime>());
      });

      test('should serialize atomicTimestamp in toJson()', () {
        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: DateTime(2025, 1, 15, 12, 30, 0),
          localTime: DateTime(2025, 1, 15, 12, 30, 0).toLocal(),
          timezoneId: 'UTC',
          offset: Duration.zero,
          isSynchronized: false,
        );
        
        final event = InteractionEvent(
          eventType: 'list_view_started',
          parameters: {},
          context: InteractionContext.empty(),
          atomicTimestamp: atomicTimestamp,
        );
        
        final json = event.toJson();
        
        expect(json, containsPair('atomic_timestamp', isA<Map<String, dynamic>>()));
        expect(json['timestamp'], isA<String>());
      });

      test('should deserialize atomicTimestamp from fromJson() with Map format', () {
        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: DateTime(2025, 1, 15, 12, 30, 0),
          localTime: DateTime(2025, 1, 15, 12, 30, 0).toLocal(),
          timezoneId: 'UTC',
          offset: Duration.zero,
          isSynchronized: false,
        );
        
        final json = {
          'event_type': 'spot_visited',
          'parameters': {'spot_id': 'spot-789'},
          'context': InteractionContext.empty().toJson(),
          'timestamp': DateTime.now().toIso8601String(),
          'atomic_timestamp': atomicTimestamp.toJson(),
        };
        
        final event = InteractionEvent.fromJson(json);
        
        expect(event.atomicTimestamp, isNotNull);
        expect(event.atomicTimestamp?.serverTime, isA<DateTime>());
        expect(event.timestamp, isA<DateTime>());
      });

      test('should deserialize atomicTimestamp from fromJson() with String format', () {
        final json = {
          'event_type': 'respect_tap',
          'parameters': {'target_id': 'list-123'},
          'context': InteractionContext.empty().toJson(),
          'timestamp': DateTime.now().toIso8601String(),
          'atomic_timestamp': DateTime(2025, 1, 15, 12, 30, 0).toIso8601String(),
        };
        
        final event = InteractionEvent.fromJson(json);
        
        // Should create AtomicTimestamp from string
        expect(event.atomicTimestamp, isNotNull);
        expect(event.atomicTimestamp?.serverTime, isA<DateTime>());
      });

      test('should be backward compatible with DateTime timestamp only', () {
        final json = {
          'event_type': 'scroll_depth',
          'parameters': {'depth': 0.75},
          'context': InteractionContext.empty().toJson(),
          'timestamp': DateTime.now().toIso8601String(),
          // No atomic_timestamp field
        };
        
        final event = InteractionEvent.fromJson(json);
        
        // Should work without atomicTimestamp
        expect(event.atomicTimestamp, isNull);
        expect(event.timestamp, isA<DateTime>());
        expect(event.eventType, equals('scroll_depth'));
      });
    });

    group('Atomic Timestamp Conversion Tests', () {
      test('should preserve atomic timestamp precision in serialization', () {
        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: DateTime(2025, 1, 15, 12, 30, 0, 500),
          localTime: DateTime(2025, 1, 15, 12, 30, 0, 500).toLocal(),
          timezoneId: 'America/New_York',
          offset: const Duration(hours: -5),
          isSynchronized: true,
        );
        
        final event = InteractionEvent(
          eventType: 'test_event',
          parameters: {},
          context: InteractionContext.empty(),
          atomicTimestamp: atomicTimestamp,
        );
        
        final json = event.toJson();
        final restored = InteractionEvent.fromJson(json);
        
        expect(restored.atomicTimestamp, isNotNull);
        expect(restored.atomicTimestamp?.precision, equals(TimePrecision.millisecond));
        expect(restored.atomicTimestamp?.isSynchronized, equals(true));
      });

      test('should handle timezone correctly', () {
        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: DateTime.utc(2025, 1, 15, 17, 30, 0),
          localTime: DateTime(2025, 1, 15, 12, 30, 0), // EST (UTC-5)
          timezoneId: 'America/New_York',
          offset: const Duration(hours: -5),
          isSynchronized: true,
        );
        
        final event = InteractionEvent(
          eventType: 'test_event',
          parameters: {},
          context: InteractionContext.empty(),
          atomicTimestamp: atomicTimestamp,
        );
        
        final json = event.toJson();
        final restored = InteractionEvent.fromJson(json);
        
        expect(restored.atomicTimestamp?.timezoneId, equals('America/New_York'));
        expect(restored.atomicTimestamp?.offset, equals(const Duration(hours: -5)));
      });
    });

    group('copyWith Tests', () {
      test('should copy InteractionEvent with modified atomicTimestamp', () {
        final originalAtomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: DateTime(2025, 1, 15, 12, 0, 0),
          localTime: DateTime(2025, 1, 15, 12, 0, 0).toLocal(),
          timezoneId: 'UTC',
          offset: Duration.zero,
          isSynchronized: false,
        );
        
        final newAtomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: DateTime(2025, 1, 15, 13, 0, 0),
          localTime: DateTime(2025, 1, 15, 13, 0, 0).toLocal(),
          timezoneId: 'UTC',
          offset: Duration.zero,
          isSynchronized: false,
        );
        
        final original = InteractionEvent(
          eventType: 'test_event',
          parameters: {},
          context: InteractionContext.empty(),
          atomicTimestamp: originalAtomicTimestamp,
        );
        
        final copied = original.copyWith(
          atomicTimestamp: newAtomicTimestamp,
        );
        
        expect(copied.atomicTimestamp, equals(newAtomicTimestamp));
        expect(copied.atomicTimestamp, isNot(equals(originalAtomicTimestamp)));
        expect(copied.eventType, equals(original.eventType));
      });
    });
  });
}
