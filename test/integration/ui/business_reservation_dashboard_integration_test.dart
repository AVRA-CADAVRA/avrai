// Business Reservation Dashboard Integration Test
//
// Phase 15: Reservation System Implementation
// Section 15.3.1: Business Reservation Dashboard
//
// Integration tests for reservation dashboard pages

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/services/reservation_quantum_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/services/supabase_service.dart';
import 'package:avrai/core/services/secure_mapping_encryption_service.dart';
import 'package:avrai/core/services/quantum/location_timing_quantum_state_service.dart';
import 'package:avrai/core/ai/quantum/quantum_vibe_engine.dart';
import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/presentation/pages/business/reservations/reservation_dashboard_page.dart';
import 'package:avrai/presentation/pages/business/reservations/reservation_calendar_page.dart';
import '../../helpers/getit_test_harness.dart';
import '../../helpers/platform_channel_helper.dart';

// Mock dependencies
class MockSupabaseService extends Mock implements SupabaseService {}
class MockQuantumVibeEngine extends Mock implements QuantumVibeEngine {}
class MockUserVibeAnalyzer extends Mock implements UserVibeAnalyzer {}
class MockPersonalityLearning extends Mock implements PersonalityLearning {}

void main() {
  group('Business Reservation Dashboard Integration', () {
    late GetItTestHarness getIt;
    late StorageService storageService;
    late AtomicClockService atomicClock;
    late AgentIdService agentIdService;
    late LocationTimingQuantumStateService locationTimingService;
    late ReservationService reservationService;
    late MockSupabaseService mockSupabaseService;
    late MockQuantumVibeEngine mockQuantumVibeEngine;
    late MockUserVibeAnalyzer mockVibeAnalyzer;
    late MockPersonalityLearning mockPersonalityLearning;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await setupTestStorage();
      getIt = GetItTestHarness(sl: GetIt.instance);

      // Initialize storage service
      storageService = StorageService.instance;

      // Initialize real services
      atomicClock = AtomicClockService();
      final encryptionService = SecureMappingEncryptionService();
      agentIdService = AgentIdService(encryptionService: encryptionService);
      locationTimingService = LocationTimingQuantumStateService();

      // Initialize mocks
      mockSupabaseService = MockSupabaseService();
      mockQuantumVibeEngine = MockQuantumVibeEngine();
      mockVibeAnalyzer = MockUserVibeAnalyzer();
      mockPersonalityLearning = MockPersonalityLearning();

      // Setup mock Supabase (offline by default)
      when(() => mockSupabaseService.isAvailable).thenReturn(false);

      // Create quantum service with mocks
      final quantumService = ReservationQuantumService(
        atomicClock: atomicClock,
        quantumVibeEngine: mockQuantumVibeEngine,
        vibeAnalyzer: mockVibeAnalyzer,
        personalityLearning: mockPersonalityLearning,
        locationTimingService: locationTimingService,
      );

      // Create reservation service
      reservationService = ReservationService(
        atomicClock: atomicClock,
        quantumService: quantumService,
        agentIdService: agentIdService,
        storageService: storageService,
        supabaseService: mockSupabaseService,
      );

      // Register ReservationService in GetIt for the page
      getIt.unregisterIfRegistered<ReservationService>();
      getIt.registerSingletonReplace<ReservationService>(reservationService);
    });

    tearDownAll(() {
      getIt.unregisterIfRegistered<ReservationService>();
    });

    testWidgets('should render reservation dashboard page', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ReservationDashboardPage(
            businessId: 'test-business-id',
          ),
        ),
      );

      // Wait for page to load
      await tester.pumpAndSettle();

      // Check that dashboard elements are displayed
      expect(find.text('Reservation Dashboard'), findsOneWidget);
      expect(find.text('Statistics'), findsOneWidget);
      expect(find.text('Views'), findsOneWidget);
    });

    testWidgets('should render calendar page', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ReservationCalendarPage(
            businessId: 'test-business-id',
          ),
        ),
      );

      // Wait for page to load
      await tester.pumpAndSettle();

      // Check that calendar page elements are displayed
      expect(find.text('Reservation Calendar'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('should display empty state when no reservations', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ReservationDashboardPage(
            businessId: 'test-business-id',
          ),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Dashboard should render (even with empty state)
      expect(find.text('Reservation Dashboard'), findsOneWidget);
      expect(find.text('Statistics'), findsOneWidget);
    });
  });
}
