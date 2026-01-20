/// SPOTS Atomic Time Integration Tests
/// Date: January 2026
/// Purpose: Test atomic time integration throughout Phase 11 enhancements
///
/// Test Coverage:
/// - Throttling checks use atomic time
/// - InteractionEvent atomic timestamps
/// - Quantum formula compatibility
/// - Fallback behavior when atomic time unavailable
///
/// Phase 11 Enhancement Testing
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/core/ai/interaction_events.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/services/supabase_service.dart';
import 'dart:math' as math;
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import '../../helpers/getit_test_harness.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([
  AtomicClockService,
  AgentIdService,
  SupabaseService,
])
import 'atomic_time_integration_test.mocks.dart';

void main() {
  group('Atomic Time Integration', () {
    late MockAtomicClockService mockAtomicClock;
    late GetItTestHarness getIt;

    setUpAll(() async {
      await setupTestStorage();
    });

    setUp(() {
      getIt = GetItTestHarness(sl: GetIt.instance);
      
      mockAtomicClock = MockAtomicClockService();
      
      // Setup atomic clock mock
      when(mockAtomicClock.getAtomicTimestamp())
          .thenAnswer((_) async => AtomicTimestamp.now(
                precision: TimePrecision.millisecond,
                serverTime: DateTime.now(),
                localTime: DateTime.now().toLocal(),
                timezoneId: 'UTC',
                offset: Duration.zero,
                isSynchronized: true,
              ));
      
      // Register AtomicClockService in GetIt
      getIt.unregisterIfRegistered<AtomicClockService>();
      getIt.registerLazySingletonReplace<AtomicClockService>(
        () => mockAtomicClock,
      );
    });

    tearDown(() {
      getIt.unregisterIfRegistered<AtomicClockService>();
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    group('Throttling Checks Use Atomic Time', () {
      test('should use atomic time for AI2AI learning throttling', () async {
        final learningSystem = ContinuousLearningSystem(
          agentIdService: AgentIdService(),
          supabase: null,
        );
        
        await learningSystem.initialize();
        
        final insight1 = AI2AILearningInsight(
          type: AI2AIInsightType.compatibilityLearning,
          dimensionInsights: {'exploration_eagerness': 0.05},
          learningQuality: 0.75,
          timestamp: DateTime.now(),
        );
        
        // First learning - should succeed
        await learningSystem.processAI2AILearningInsight(
          userId: 'test-user',
          insight: insight1,
          peerId: 'peer-throttle',
        );
        
        // Verify atomic clock was called
        verify(mockAtomicClock.getAtomicTimestamp())
            .called(greaterThanOrEqualTo(1));
      });

      test('should calculate time differences correctly using atomic time', () async {
        final now = DateTime.now();
        final pastTime = now.subtract(const Duration(minutes: 10));
        
        final atomicNow = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: now,
          localTime: now.toLocal(),
          timezoneId: 'UTC',
          offset: Duration.zero,
          isSynchronized: true,
        );
        
        final atomicPast = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: pastTime,
          localTime: pastTime.toLocal(),
          timezoneId: 'UTC',
          offset: Duration.zero,
          isSynchronized: true,
        );
        
        final diff = atomicNow.difference(atomicPast);
        
        expect(diff.inMinutes, equals(10));
        expect(diff, equals(const Duration(minutes: 10)));
      });

      test('should fall back gracefully when atomic time unavailable', () async {
        // Unregister AtomicClockService
        getIt.unregisterIfRegistered<AtomicClockService>();
        
        final learningSystem = ContinuousLearningSystem(
          agentIdService: AgentIdService(),
          supabase: null,
        );
        
        await learningSystem.initialize();
        
        final insight = AI2AILearningInsight(
          type: AI2AIInsightType.dimensionDiscovery,
          dimensionInsights: {'novelty_seeking': 0.06},
          learningQuality: 0.80,
          timestamp: DateTime.now(),
        );
        
        // Should complete with DateTime fallback
        await expectLater(
          learningSystem.processAI2AILearningInsight(
            userId: 'test-user',
            insight: insight,
            peerId: 'peer-fallback',
          ),
          completes,
        );
      });
    });

    group('InteractionEvent Atomic Timestamps', () {
      test('should include atomicTimestamp in InteractionEvent', () {
        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: DateTime.now(),
          localTime: DateTime.now().toLocal(),
          timezoneId: 'America/New_York',
          offset: const Duration(hours: -5),
          isSynchronized: true,
        );
        
        final event = InteractionEvent(
          eventType: 'spot_visited',
          parameters: {'spot_id': 'spot-123'},
          context: InteractionContext.empty(),
          atomicTimestamp: atomicTimestamp,
        );
        
        expect(event.atomicTimestamp, isNotNull);
        expect(event.atomicTimestamp, equals(atomicTimestamp));
      });

      test('should serialize atomicTimestamp correctly', () {
        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: DateTime(2025, 1, 15, 12, 30, 0),
          localTime: DateTime(2025, 1, 15, 12, 30, 0).toLocal(),
          timezoneId: 'UTC',
          offset: Duration.zero,
          isSynchronized: true,
        );
        
        final event = InteractionEvent(
          eventType: 'respect_tap',
          parameters: {},
          context: InteractionContext.empty(),
          atomicTimestamp: atomicTimestamp,
        );
        
        final json = event.toJson();
        
        expect(json, containsPair('atomic_timestamp', isA<Map<String, dynamic>>()));
        expect(json['atomic_timestamp'], isNotNull);
      });

      test('should deserialize atomicTimestamp correctly', () {
        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: DateTime(2025, 1, 15, 12, 30, 0),
          localTime: DateTime(2025, 1, 15, 12, 30, 0).toLocal(),
          timezoneId: 'UTC',
          offset: Duration.zero,
          isSynchronized: true,
        );
        
        final json = {
          'event_type': 'scroll_depth',
          'parameters': {'depth': 0.75},
          'context': InteractionContext.empty().toJson(),
          'timestamp': DateTime.now().toIso8601String(),
          'atomic_timestamp': atomicTimestamp.toJson(),
        };
        
        final event = InteractionEvent.fromJson(json);
        
        expect(event.atomicTimestamp, isNotNull);
        expect(event.atomicTimestamp?.serverTime, isA<DateTime>());
        expect(event.atomicTimestamp?.isSynchronized, equals(true));
      });
    });

    group('Quantum Formula Compatibility', () {
      test('should use AtomicTimestamp for quantum temporal calculations', () {
        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: DateTime.now(),
          localTime: DateTime.now().toLocal(),
          timezoneId: 'UTC',
          offset: Duration.zero,
          isSynchronized: true,
        );
        
        // Verify atomic timestamp has required properties for quantum formulas
        expect(atomicTimestamp.serverTime, isA<DateTime>());
        expect(atomicTimestamp.deviceTime, isA<DateTime>());
        expect(atomicTimestamp.localTime, isA<DateTime>());
        expect(atomicTimestamp.precision, isA<TimePrecision>());
        expect(atomicTimestamp.isSynchronized, isA<bool>());
      });

      test('should enable temporal decay calculations with atomic time', () {
        final t1 = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: DateTime(2025, 1, 15, 12, 0, 0),
          localTime: DateTime(2025, 1, 15, 12, 0, 0).toLocal(),
          timezoneId: 'UTC',
          offset: Duration.zero,
          isSynchronized: true,
        );
        
        final t2 = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: DateTime(2025, 1, 15, 14, 0, 0), // 2 hours later
          localTime: DateTime(2025, 1, 15, 14, 0, 0).toLocal(),
          timezoneId: 'UTC',
          offset: Duration.zero,
          isSynchronized: true,
        );
        
        final timeDiff = t2.difference(t1);
        
        // Verify time difference can be used for temporal decay: e^(-γ * (t2 - t1))
        expect(timeDiff.inHours, equals(2));
        expect(timeDiff.inSeconds, equals(7200));
        
        // Can now use in quantum formulas: decay = exp(-gamma * timeDiff.inSeconds / 3600.0)
        final gamma = 0.1;
        final decay = math.pow(math.e, -gamma * timeDiff.inHours).toDouble(); // Simplified decay calculation
        expect(decay, lessThan(1.0));
        expect(decay, greaterThan(0.0));
      });
    });
  });
}
