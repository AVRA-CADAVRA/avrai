/// SPOTS Reservation Analytics Service Tests
/// Date: January 6, 2026
/// Purpose: Test ReservationAnalyticsService functionality
/// 
/// Test Coverage:
/// - Core Methods: getUserAnalytics, trackReservationEvent
/// - Analytics Calculations: Patterns, favorite spots, waitlist history, modification patterns
/// - Knot/Quantum/AI2AI Integration: String evolution, fabric stability, worldsheet evolution, quantum compatibility, AI2AI insights
/// - Error Handling: Invalid inputs, edge cases, service unavailability
/// 
/// Dependencies:
/// - Mock ReservationService: Reservation data retrieval
/// - Mock AgentIdService: Agent ID resolution
/// - Mock EventLogger: Event tracking
/// - Mock PaymentService: Payment data retrieval
/// - Mock KnotEvolutionStringService: String evolution patterns (optional)
/// - Mock KnotFabricService: Fabric stability calculations (optional)
/// - Mock KnotWorldsheetService: Worldsheet evolution tracking (optional)
/// - Mock AtomicClockService: Timestamp generation (optional)
/// - Mock QuantumMatchingAILearningService: Quantum compatibility (optional)
/// - Mock ReservationQuantumService: Quantum state operations (optional)
/// - Mock PersonalityLearning: Personality profile retrieval (optional)
/// 
/// ⚠️  TEST QUALITY GUIDELINES:
/// ✅ DO: Test business logic, error handling, async operations, side effects
/// ✅ DO: Test service behavior and interactions with dependencies
/// ✅ DO: Consolidate related checks into comprehensive test blocks
/// 
/// See: docs/plans/test_refactoring/TEST_WRITING_GUIDE.md
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai/core/services/reservation_analytics_service.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/ai/event_logger.dart';
import 'package:avrai/core/services/payment_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/core/services/quantum/quantum_matching_ai_learning_service.dart';
import 'package:avrai/core/services/reservation_quantum_service.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/models/reservation.dart';

// Mock dependencies
class MockReservationService extends Mock implements ReservationService {}
class MockAgentIdService extends Mock implements AgentIdService {}
class MockEventLogger extends Mock implements EventLogger {}
class MockPaymentService extends Mock implements PaymentService {}
class MockKnotEvolutionStringService extends Mock implements KnotEvolutionStringService {}
class MockKnotFabricService extends Mock implements KnotFabricService {}
class MockKnotWorldsheetService extends Mock implements KnotWorldsheetService {}
class MockAtomicClockService extends Mock implements AtomicClockService {}
class MockQuantumMatchingAILearningService extends Mock implements QuantumMatchingAILearningService {}
class MockReservationQuantumService extends Mock implements ReservationQuantumService {}
class MockPersonalityLearning extends Mock implements PersonalityLearning {}

void main() {
  setUpAll(() {
    // Register fallback values for enum types
    registerFallbackValue(ReservationType.event);
    registerFallbackValue(ReservationType.spot);
    registerFallbackValue(ReservationType.business);
    registerFallbackValue(ReservationStatus.completed);
  });

  group('ReservationAnalyticsService', () {
    late ReservationAnalyticsService service;
    late MockReservationService mockReservationService;
    late MockAgentIdService mockAgentIdService;
    late MockEventLogger? mockEventLogger;
    late MockPaymentService? mockPaymentService;
    late MockKnotEvolutionStringService? mockStringService;
    late MockKnotFabricService? mockFabricService;
    late MockKnotWorldsheetService? mockWorldsheetService;
    late MockAtomicClockService? mockAtomicClock;
    late MockQuantumMatchingAILearningService? mockAILearningService;
    late MockReservationQuantumService? mockQuantumService;
    late MockPersonalityLearning? mockPersonalityLearning;

    setUp(() {
      mockReservationService = MockReservationService();
      mockAgentIdService = MockAgentIdService();
      mockEventLogger = null;
      mockPaymentService = null;
      mockStringService = null;
      mockFabricService = null;
      mockWorldsheetService = null;
      mockAtomicClock = null;
      mockAILearningService = null;
      mockQuantumService = null;
      mockPersonalityLearning = null;

      service = ReservationAnalyticsService(
        reservationService: mockReservationService,
        agentIdService: mockAgentIdService,
        eventLogger: mockEventLogger,
        paymentService: mockPaymentService,
        stringService: mockStringService,
        fabricService: mockFabricService,
        worldsheetService: mockWorldsheetService,
        atomicClock: mockAtomicClock,
        aiLearningService: mockAILearningService,
        quantumService: mockQuantumService,
        personalityLearning: mockPersonalityLearning,
      );
    });

    group('getUserAnalytics', () {
      test('should calculate analytics correctly with basic reservation data', () async {
        // Test business logic: analytics calculation with real reservation data
        const userId = 'user-1';
        const agentId = 'agent-1';
        final now = DateTime.now();
        final reservations = [
          Reservation(
            id: 'res-1',
            agentId: agentId,
            type: ReservationType.spot,
            targetId: 'spot-1',
            reservationTime: now.add(const Duration(days: 7)),
            partySize: 2,
            status: ReservationStatus.completed,
            createdAt: now.subtract(const Duration(days: 30)),
            updatedAt: now.subtract(const Duration(days: 30)),
          ),
          Reservation(
            id: 'res-2',
            agentId: agentId,
            type: ReservationType.spot,
            targetId: 'spot-2',
            reservationTime: now.add(const Duration(days: 14)),
            partySize: 1,
            status: ReservationStatus.pending,
            createdAt: now.subtract(const Duration(days: 20)),
            updatedAt: now.subtract(const Duration(days: 20)),
          ),
          Reservation(
            id: 'res-3',
            agentId: agentId,
            type: ReservationType.event,
            targetId: 'event-1',
            reservationTime: now.add(const Duration(days: 21)),
            partySize: 4,
            status: ReservationStatus.cancelled,
            createdAt: now.subtract(const Duration(days: 10)),
            updatedAt: now.subtract(const Duration(days: 5)),
          ),
        ];

        when(() => mockReservationService.getUserReservations(
          userId: userId,
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => reservations);

        final analytics = await service.getUserAnalytics(userId: userId);

        expect(analytics.totalReservations, equals(3));
        expect(analytics.completedReservations, equals(1));
        expect(analytics.cancelledReservations, equals(1));
        expect(analytics.pendingReservations, equals(1));
        expect(analytics.completionRate, closeTo(1.0 / 3.0, 0.001));
        expect(analytics.cancellationRate, closeTo(1.0 / 3.0, 0.001));
        expect(analytics.favoriteSpots.length, greaterThan(0));
      });

      test('should handle empty reservation list gracefully', () async {
        // Test error handling: empty data edge case
        const userId = 'user-1';
        when(() => mockReservationService.getUserReservations(
          userId: userId,
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => <Reservation>[]);

        final analytics = await service.getUserAnalytics(userId: userId);

        expect(analytics.totalReservations, equals(0));
        expect(analytics.completedReservations, equals(0));
        expect(analytics.cancelledReservations, equals(0));
        expect(analytics.pendingReservations, equals(0));
        expect(analytics.completionRate, equals(0.0));
        expect(analytics.cancellationRate, equals(0.0));
        expect(analytics.favoriteSpots, isEmpty);
      });

      test('should calculate favorite spots correctly based on reservation count', () async {
        // Test business logic: favorite spots calculation
        const userId = 'user-1';
        const agentId = 'agent-1';
        final now = DateTime.now();
        final reservations = List.generate(5, (i) => Reservation(
          id: 'res-$i',
          agentId: agentId,
          type: ReservationType.spot,
          targetId: 'spot-1', // Same spot for multiple reservations
          reservationTime: now.add(Duration(days: 7 + i)),
          partySize: 2,
          status: ReservationStatus.completed,
          createdAt: now.subtract(const Duration(days: 30)),
          updatedAt: now.subtract(const Duration(days: 30)),
        ))..addAll(List.generate(2, (i) => Reservation(
          id: 'res-${5 + i}',
          agentId: agentId,
          type: ReservationType.spot,
          targetId: 'spot-2',
          reservationTime: now.add(Duration(days: 14 + i)),
          partySize: 1,
          status: ReservationStatus.completed,
          createdAt: now.subtract(const Duration(days: 30)),
          updatedAt: now.subtract(const Duration(days: 30)),
        )));

        when(() => mockReservationService.getUserReservations(
          userId: userId,
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => reservations);

        final analytics = await service.getUserAnalytics(userId: userId);

        expect(analytics.favoriteSpots.length, equals(2));
        expect(analytics.favoriteSpots.first.spotId, equals('spot-1'));
        expect(analytics.favoriteSpots.first.reservationCount, equals(5));
        expect(analytics.favoriteSpots.last.spotId, equals('spot-2'));
        expect(analytics.favoriteSpots.last.reservationCount, equals(2));
      });

      test('should calculate reservation patterns correctly by time and day', () async {
        // Test business logic: pattern calculation
        const userId = 'user-1';
        const agentId = 'agent-1';
        final now = DateTime.now();
        // Create reservations on same day of week and hour
        // Calculate next Tuesday at 6pm
        final daysUntilTuesday = (DateTime.tuesday - now.weekday) % 7;
        final tuesdayAt6pm = now.add(Duration(days: daysUntilTuesday)).copyWith(
          hour: 18,
          minute: 0,
          second: 0,
          millisecond: 0,
        );
        final reservations = List.generate(3, (i) => Reservation(
          id: 'res-$i',
          agentId: agentId,
          type: ReservationType.spot,
          targetId: 'spot-1',
          reservationTime: tuesdayAt6pm.add(Duration(days: i * 7)),
          partySize: 2,
          status: ReservationStatus.completed,
          createdAt: now.subtract(const Duration(days: 30)),
          updatedAt: now.subtract(const Duration(days: 30)),
        ));

        when(() => mockReservationService.getUserReservations(
          userId: userId,
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => reservations);

        final analytics = await service.getUserAnalytics(userId: userId);

        expect(analytics.patterns.preferredHour, equals(18));
        expect(analytics.patterns.preferredDayOfWeek, equals(DateTime.tuesday));
      });

      test('should return null for advanced analytics when optional services unavailable', () async {
        // Test error handling: graceful degradation when optional services null
        const userId = 'user-1';
        const agentId = 'agent-1';
        final now = DateTime.now();
        final reservations = [
          Reservation(
            id: 'res-1',
            agentId: agentId,
            type: ReservationType.spot,
            targetId: 'spot-1',
            reservationTime: now.add(const Duration(days: 7)),
            partySize: 2,
            status: ReservationStatus.completed,
            createdAt: now.subtract(const Duration(days: 30)),
            updatedAt: now.subtract(const Duration(days: 30)),
          ),
        ];

        when(() => mockReservationService.getUserReservations(
          userId: userId,
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => reservations);

        final analytics = await service.getUserAnalytics(userId: userId);

        // Advanced analytics should be null when services unavailable
        expect(analytics.stringEvolutionPatterns, isNull);
        expect(analytics.fabricStabilityAnalytics, isNull);
        expect(analytics.worldsheetEvolutionAnalytics, isNull);
        expect(analytics.quantumCompatibilityHistory, isNull);
        expect(analytics.ai2aiLearningInsights, isNull);
      });

      test('should integrate with optional string service when available', () async {
        // Test integration: optional service integration
        const userId = 'user-1';
        const agentId = 'agent-1';
        final now = DateTime.now();
        final reservations = [
          Reservation(
            id: 'res-1',
            agentId: agentId,
            type: ReservationType.spot,
            targetId: 'spot-1',
            reservationTime: now.add(const Duration(days: 7)),
            partySize: 2,
            status: ReservationStatus.completed,
            createdAt: now.subtract(const Duration(days: 30)),
            updatedAt: now.subtract(const Duration(days: 30)),
          ),
        ];

        mockStringService = MockKnotEvolutionStringService();
        service = ReservationAnalyticsService(
          reservationService: mockReservationService,
          agentIdService: mockAgentIdService,
          eventLogger: mockEventLogger,
          paymentService: mockPaymentService,
          stringService: mockStringService,
          fabricService: mockFabricService,
          worldsheetService: mockWorldsheetService,
          atomicClock: mockAtomicClock,
          aiLearningService: mockAILearningService,
          quantumService: mockQuantumService,
          personalityLearning: mockPersonalityLearning,
        );

        when(() => mockReservationService.getUserReservations(
          userId: userId,
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => reservations);
        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);

        // Mock string service to return analysis
        final evolutionAnalysis = EvolutionAnalysis(
          hasPatterns: true,
          cycles: [],
          trends: [],
          milestones: [],
        );
        when(() => mockStringService!.analyzeEvolutionPatterns(agentId))
            .thenAnswer((_) async => evolutionAnalysis);

        final analytics = await service.getUserAnalytics(userId: userId);

        // Should have string evolution patterns when service available
        expect(analytics.stringEvolutionPatterns, isNotNull);
      });

      test('should handle service errors gracefully without crashing', () async {
        // Test error handling: service failure recovery
        const userId = 'user-1';
        when(() => mockReservationService.getUserReservations(
          userId: userId,
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenThrow(Exception('Service error'));

        expect(
          () => service.getUserAnalytics(userId: userId),
          throwsException,
        );
      });

      test('should calculate modification patterns correctly', () async {
        // Test business logic: modification pattern tracking
        const userId = 'user-1';
        const agentId = 'agent-1';
        final now = DateTime.now();
        final reservations = [
          Reservation(
            id: 'res-1',
            agentId: agentId,
            type: ReservationType.spot,
            targetId: 'spot-1',
            reservationTime: now.add(const Duration(days: 7)),
            partySize: 2,
            status: ReservationStatus.pending,
            createdAt: now.subtract(const Duration(days: 30)),
            updatedAt: now.subtract(const Duration(days: 5)), // Modified 5 days after creation
            metadata: {'modificationCount': 2},
          ),
        ];

        when(() => mockReservationService.getUserReservations(
          userId: userId,
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => reservations);

        final analytics = await service.getUserAnalytics(userId: userId);

        expect(analytics.modificationPatterns.totalModifications, greaterThan(0));
      });

      test('should calculate waitlist history correctly', () async {
        // Test business logic: waitlist history tracking
        const userId = 'user-1';
        const agentId = 'agent-1';
        final now = DateTime.now();
        final reservations = [
          Reservation(
            id: 'res-1',
            agentId: agentId,
            type: ReservationType.spot,
            targetId: 'spot-1',
            reservationTime: now.add(const Duration(days: 7)),
            partySize: 2,
            status: ReservationStatus.completed,
            createdAt: now.subtract(const Duration(days: 30)),
            updatedAt: now.subtract(const Duration(days: 25)),
            metadata: {'wasWaitlist': true},
          ),
        ];

        when(() => mockReservationService.getUserReservations(
          userId: userId,
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => reservations);

        final analytics = await service.getUserAnalytics(userId: userId);

        expect(analytics.waitlistHistory.totalWaitlistJoins, equals(1));
        expect(analytics.waitlistHistory.totalWaitlistConversions, equals(1));
      });
    });

    group('trackReservationEvent', () {
      test('should track events when event logger available', () async {
        // Test integration: event tracking when service available
        mockEventLogger = MockEventLogger();
        service = ReservationAnalyticsService(
          reservationService: mockReservationService,
          agentIdService: mockAgentIdService,
          eventLogger: mockEventLogger,
          paymentService: mockPaymentService,
          stringService: mockStringService,
          fabricService: mockFabricService,
          worldsheetService: mockWorldsheetService,
          atomicClock: mockAtomicClock,
          aiLearningService: mockAILearningService,
          quantumService: mockQuantumService,
          personalityLearning: mockPersonalityLearning,
        );

        when(() => mockEventLogger!.logEvent(
          eventType: any(named: 'eventType'),
          parameters: any(named: 'parameters'),
          context: any(named: 'context'),
          agentId: any(named: 'agentId'),
        )).thenAnswer((_) async => {});

        await service.trackReservationEvent(
          userId: 'user-1',
          eventType: 'reservation_created',
          parameters: {'reservationId': 'res-1'},
        );

        verify(() => mockEventLogger!.logEvent(
          eventType: 'reservation_created',
          parameters: any(named: 'parameters'),
          context: any(named: 'context'),
          agentId: any(named: 'agentId'),
        )).called(1);
      });

      test('should handle missing event logger gracefully', () async {
        // Test error handling: missing optional service
        // Service should not throw when event logger is null
        await expectLater(
          service.trackReservationEvent(
            userId: 'user-1',
            eventType: 'reservation_created',
            parameters: {'reservationId': 'res-1'},
          ),
          completes,
        );
      });
    });
  });
}
