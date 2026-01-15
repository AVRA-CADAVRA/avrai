// Cancellation Policy Settings Widget Test
//
// Phase 15: Reservation System Implementation
// Section 15.3.2: Business Reservation Settings
//
// Widget tests for CancellationPolicySettingsWidget

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai/presentation/widgets/business/reservations/cancellation_policy_settings_widget.dart';
import 'package:avrai/core/services/reservation_cancellation_policy_service.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/services/supabase_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/core/services/reservation_quantum_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/services/secure_mapping_encryption_service.dart';
import 'package:avrai/core/services/quantum/location_timing_quantum_state_service.dart';
import 'package:avrai/core/ai/quantum/quantum_vibe_engine.dart';
import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import '../../../../helpers/platform_channel_helper.dart';
import '../../../../helpers/getit_test_harness.dart';

// Mock dependencies for ReservationService
class MockQuantumVibeEngine extends Mock implements QuantumVibeEngine {}

class MockUserVibeAnalyzer extends Mock implements UserVibeAnalyzer {}

class MockPersonalityLearning extends Mock implements PersonalityLearning {}

void main() {
  group('CancellationPolicySettingsWidget', () {
    late GetItTestHarness getIt;
    late StorageService storageService;
    late SupabaseService supabaseService;
    late ReservationService reservationService;

    setUpAll(() async {
      await setupTestStorage();
      getIt = GetItTestHarness(sl: GetIt.instance);

      // Initialize storage service
      storageService = StorageService.instance;
      if (!GetIt.instance.isRegistered<StorageService>()) {
        getIt.registerSingletonReplace<StorageService>(storageService);
      }

      // Initialize supabase service
      supabaseService = SupabaseService();
      if (!GetIt.instance.isRegistered<SupabaseService>()) {
        getIt.registerSingletonReplace<SupabaseService>(supabaseService);
      }

      // Create minimal ReservationService (required by cancellation policy service)
      // Even though it's marked unused_field, the constructor tries to get it from GetIt
      final atomicClock = AtomicClockService();
      final encryptionService = SecureMappingEncryptionService();
      final agentIdService =
          AgentIdService(encryptionService: encryptionService);
      final locationTimingService = LocationTimingQuantumStateService();

      final mockQuantumVibeEngine = MockQuantumVibeEngine();
      final mockVibeAnalyzer = MockUserVibeAnalyzer();
      final mockPersonalityLearning = MockPersonalityLearning();

      final quantumService = ReservationQuantumService(
        atomicClock: atomicClock,
        quantumVibeEngine: mockQuantumVibeEngine,
        vibeAnalyzer: mockVibeAnalyzer,
        personalityLearning: mockPersonalityLearning,
        locationTimingService: locationTimingService,
      );

      reservationService = ReservationService(
        atomicClock: atomicClock,
        quantumService: quantumService,
        agentIdService: agentIdService,
        storageService: storageService,
        supabaseService: supabaseService,
      );

      if (!GetIt.instance.isRegistered<ReservationService>()) {
        getIt.registerSingletonReplace<ReservationService>(reservationService);
      }

      // Register cancellation policy service
      if (!GetIt.instance
          .isRegistered<ReservationCancellationPolicyService>()) {
        getIt
            .registerLazySingletonReplace<ReservationCancellationPolicyService>(
          () => ReservationCancellationPolicyService(
            storageService: storageService,
            supabaseService: supabaseService,
            reservationService: reservationService,
          ),
        );
      }
    });

    tearDownAll(() async {
      getIt.unregisterIfRegistered<ReservationCancellationPolicyService>();
      getIt.unregisterIfRegistered<ReservationService>();
      getIt.unregisterIfRegistered<SupabaseService>();
      getIt.unregisterIfRegistered<StorageService>();
      await cleanupTestStorage();
    });

    setUp(() async {
      // Clear storage before each test
      await StorageService.instance.clear();
    });

    testWidgets('should render widget with baseline policy',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child:
                  CancellationPolicySettingsWidget(businessId: 'test_business'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that widget renders
      expect(find.text('Use Baseline Policy'), findsOneWidget);
    });

    testWidgets('should toggle to custom policy', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child:
                  CancellationPolicySettingsWidget(businessId: 'test_business'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Tap to disable baseline (enable custom)
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Should show custom policy inputs
      expect(find.text('Hours Before Cancellation'), findsOneWidget);
    });
  });
}
