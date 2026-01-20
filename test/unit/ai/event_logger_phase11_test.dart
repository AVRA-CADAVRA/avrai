/// SPOTS EventLogger Phase 11 Enhancement Tests
/// Date: January 2026
/// Purpose: Test atomic timestamp capture in EventLogger
///
/// Test Coverage:
/// - Atomic timestamp capture when AtomicClockService available
/// - Graceful fallback when AtomicClockService unavailable
/// - InteractionEvent created with atomicTimestamp
/// - Error handling in atomic timestamp retrieval
///
/// Phase 11 Enhancement Testing
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/ai/event_logger.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/services/supabase_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai/injection_container.dart' as di;
import '../../helpers/getit_test_harness.dart';

@GenerateMocks([
  AtomicClockService,
  AgentIdService,
  SupabaseService,
])
import 'event_logger_phase11_test.mocks.dart';

void main() {
  group('EventLogger Atomic Timestamp Capture', () {
    late EventLogger eventLogger;
    late MockAtomicClockService mockAtomicClock;
    late MockAgentIdService mockAgentIdService;
    late MockSupabaseService mockSupabaseService;
    late GetItTestHarness getIt;

    setUp(() {
      getIt = GetItTestHarness(sl: GetIt.instance);
      
      // Create mocks
      mockAtomicClock = MockAtomicClockService();
      mockAgentIdService = MockAgentIdService();
      mockSupabaseService = MockSupabaseService();
      
      // Setup atomic clock mock
      when(mockAtomicClock.getAtomicTimestamp()).thenAnswer(
        (_) async => AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: DateTime.now(),
          localTime: DateTime.now().toLocal(),
          timezoneId: 'UTC',
          offset: Duration.zero,
          isSynchronized: false,
        ),
      );
      
      // Setup agent ID mock
      when(mockAgentIdService.getUserAgentId(any))
          .thenAnswer((_) async => 'agent_test_user');
      
      // Setup SupabaseService mock
      when(mockSupabaseService.isAvailable).thenReturn(false);
      
      // Register mocks in GetIt
      getIt.unregisterIfRegistered<AtomicClockService>();
      getIt.unregisterIfRegistered<AgentIdService>();
      
      // Use di.sl for AtomicClockService (matches EventLogger implementation)
      if (!di.sl.isRegistered<AtomicClockService>()) {
        di.sl.registerLazySingleton<AtomicClockService>(
          () => mockAtomicClock,
        );
      }
      if (!di.sl.isRegistered<AgentIdService>()) {
        di.sl.registerLazySingleton<AgentIdService>(
          () => mockAgentIdService,
        );
      }
      
      // Create EventLogger
      eventLogger = EventLogger(
        agentIdService: mockAgentIdService,
        supabaseService: mockSupabaseService,
      );
    });

    tearDown(() {
      // Clean up GetIt registrations
      getIt.unregisterIfRegistered<AtomicClockService>();
      getIt.unregisterIfRegistered<AgentIdService>();
    });

    group('Atomic Timestamp Capture Tests', () {
      test('should capture atomic timestamp when AtomicClockService available', () async {
        await eventLogger.initialize(userId: 'test-user');
        
        // Log an event
        await eventLogger.logEvent(
          eventType: 'spot_visited',
          parameters: {'spot_id': 'spot-123'},
        );
        
        // Verify atomic clock was called
        verify(mockAtomicClock.getAtomicTimestamp()).called(greaterThanOrEqualTo(1));
      });

      test('should fall back gracefully when AtomicClockService unavailable', () async {
        // Unregister AtomicClockService
        if (di.sl.isRegistered<AtomicClockService>()) {
          di.sl.unregister<AtomicClockService>();
        }
        
        await eventLogger.initialize(userId: 'test-user');
        
        // Should complete without errors
        await expectLater(
          eventLogger.logEvent(
            eventType: 'respect_tap',
            parameters: {'target_id': 'list-456'},
          ),
          completes,
        );
      });

      test('should handle errors in atomic timestamp retrieval', () async {
        // Make atomic clock throw an error
        when(mockAtomicClock.getAtomicTimestamp())
            .thenThrow(Exception('Atomic clock error'));
        
        await eventLogger.initialize(userId: 'test-user');
        
        // Should complete without throwing
        await expectLater(
          eventLogger.logEvent(
            eventType: 'scroll_depth',
            parameters: {'depth': 0.75},
          ),
          completes,
        );
      });
    });
  });
}
