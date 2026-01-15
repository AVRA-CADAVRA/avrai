/// SPOTS Business Reservation Analytics Service Tests
/// Date: January 6, 2026
/// Purpose: Test BusinessReservationAnalyticsService functionality
///
/// Test Coverage:
/// - Core Methods: getBusinessAnalytics
/// - Business Metrics: Volume, peak times, revenue, rates, retention
/// - Advanced Metrics: Rate limit usage, waitlist, capacity utilization
/// - Knot/Quantum/AI2AI Integration: String evolution, fabric stability, worldsheet evolution, quantum compatibility, AI2AI insights
/// - Error Handling: Invalid inputs, edge cases, service unavailability
///
/// Dependencies:
/// - Mock ReservationService: Reservation data retrieval
/// - Mock PaymentService: Revenue data retrieval
/// - Mock ReservationRateLimitService: Rate limit metrics (optional)
/// - Mock ReservationWaitlistService: Waitlist metrics (optional)
/// - Mock ReservationAvailabilityService: Capacity utilization (optional)
/// - Mock AgentIdService: Agent ID resolution
/// - Mock EventLogger: Event tracking
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
import 'package:avrai/core/services/business_reservation_analytics_service.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/services/payment_service.dart';
import 'package:avrai/core/services/reservation_rate_limit_service.dart';
import 'package:avrai/core/services/reservation_waitlist_service.dart';
import 'package:avrai/core/services/reservation_availability_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/ai/event_logger.dart';
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

class MockPaymentService extends Mock implements PaymentService {}

class MockReservationRateLimitService extends Mock
    implements ReservationRateLimitService {}

class MockReservationWaitlistService extends Mock
    implements ReservationWaitlistService {}

class MockReservationAvailabilityService extends Mock
    implements ReservationAvailabilityService {}

class MockAgentIdService extends Mock implements AgentIdService {}

class MockEventLogger extends Mock implements EventLogger {}

class MockKnotEvolutionStringService extends Mock
    implements KnotEvolutionStringService {}

class MockKnotFabricService extends Mock implements KnotFabricService {}

class MockKnotWorldsheetService extends Mock implements KnotWorldsheetService {}

class MockAtomicClockService extends Mock implements AtomicClockService {}

class MockQuantumMatchingAILearningService extends Mock
    implements QuantumMatchingAILearningService {}

class MockReservationQuantumService extends Mock
    implements ReservationQuantumService {}

class MockPersonalityLearning extends Mock implements PersonalityLearning {}

void main() {
  setUpAll(() {
    // Register fallback values for enum types
    registerFallbackValue(ReservationType.event);
    registerFallbackValue(ReservationType.spot);
    registerFallbackValue(ReservationType.business);
    registerFallbackValue(ReservationStatus.completed);
    registerFallbackValue(ReservationStatus.confirmed);
    registerFallbackValue(ReservationStatus.cancelled);
    registerFallbackValue(ReservationStatus.noShow);
  });

  group('BusinessReservationAnalyticsService', () {
    late BusinessReservationAnalyticsService service;
    late MockReservationService mockReservationService;
    late MockPaymentService? mockPaymentService;
    late MockReservationRateLimitService? mockRateLimitService;
    late MockReservationWaitlistService? mockWaitlistService;
    late MockReservationAvailabilityService? mockAvailabilityService;
    late MockAgentIdService mockAgentIdService;
    late MockEventLogger? mockEventLogger;
    late MockKnotEvolutionStringService? mockStringService;
    late MockKnotFabricService? mockFabricService;
    late MockKnotWorldsheetService? mockWorldsheetService;
    late MockAtomicClockService? mockAtomicClock;
    late MockQuantumMatchingAILearningService? mockAILearningService;
    late MockReservationQuantumService? mockQuantumService;
    late MockPersonalityLearning? mockPersonalityLearning;

    setUp(() {
      mockReservationService = MockReservationService();
      mockPaymentService = null;
      mockRateLimitService = null;
      mockWaitlistService = null;
      mockAvailabilityService = null;
      mockAgentIdService = MockAgentIdService();
      mockEventLogger = null;
      mockStringService = null;
      mockFabricService = null;
      mockWorldsheetService = null;
      mockAtomicClock = null;
      mockAILearningService = null;
      mockQuantumService = null;
      mockPersonalityLearning = null;

      service = BusinessReservationAnalyticsService(
        reservationService: mockReservationService,
        paymentService: mockPaymentService,
        rateLimitService: mockRateLimitService,
        waitlistService: mockWaitlistService,
        availabilityService: mockAvailabilityService,
        agentIdService: mockAgentIdService,
        eventLogger: mockEventLogger,
        stringService: mockStringService,
        fabricService: mockFabricService,
        worldsheetService: mockWorldsheetService,
        atomicClock: mockAtomicClock,
        aiLearningService: mockAILearningService,
        quantumService: mockQuantumService,
        personalityLearning: mockPersonalityLearning,
      );
    });

    group('getBusinessAnalytics', () {
      test('should calculate analytics correctly with basic reservation data',
          () async {
        // Test business logic: analytics calculation with real reservation data
        const businessId = 'business-1';
        final now = DateTime.now();
        final reservations = [
          Reservation(
            id: 'res-1',
            agentId: 'agent-1',
            type: ReservationType.business,
            targetId: businessId,
            reservationTime: now.add(const Duration(days: 7)),
            partySize: 2,
            ticketCount: 2,
            ticketPrice: 50.0,
            status: ReservationStatus.completed,
            createdAt: now.subtract(const Duration(days: 30)),
            updatedAt: now.subtract(const Duration(days: 30)),
          ),
          Reservation(
            id: 'res-2',
            agentId: 'agent-2',
            type: ReservationType.business,
            targetId: businessId,
            reservationTime: now.add(const Duration(days: 14)),
            partySize: 1,
            ticketCount: 1,
            ticketPrice: 30.0,
            status: ReservationStatus.confirmed,
            createdAt: now.subtract(const Duration(days: 20)),
            updatedAt: now.subtract(const Duration(days: 20)),
          ),
          Reservation(
            id: 'res-3',
            agentId: 'agent-3',
            type: ReservationType.business,
            targetId: businessId,
            reservationTime: now.add(const Duration(days: 21)),
            partySize: 4,
            ticketCount: 4,
            ticketPrice: 40.0,
            status: ReservationStatus.cancelled,
            createdAt: now.subtract(const Duration(days: 10)),
            updatedAt: now.subtract(const Duration(days: 5)),
          ),
        ];

        when(() => mockReservationService.getReservationsForTarget(
              type: ReservationType.business,
              targetId: businessId,
              status: any(named: 'status'),
            )).thenAnswer((_) async => reservations);

        final analytics = await service.getBusinessAnalytics(
          businessId: businessId,
          type: ReservationType.business,
        );

        expect(analytics.totalReservations, equals(3));
        expect(analytics.completedReservations, equals(1));
        expect(analytics.confirmedReservations, equals(1));
        expect(analytics.cancelledReservations, equals(1));
        expect(analytics.completionRate, closeTo(1.0 / 3.0, 0.001));
        expect(analytics.cancellationRate, closeTo(1.0 / 3.0, 0.001));
      });

      test('should handle empty reservation list gracefully', () async {
        // Test error handling: empty data edge case
        const businessId = 'business-1';
        when(() => mockReservationService.getReservationsForTarget(
              type: ReservationType.business,
              targetId: businessId,
              status: any(named: 'status'),
            )).thenAnswer((_) async => <Reservation>[]);

        final analytics = await service.getBusinessAnalytics(
          businessId: businessId,
          type: ReservationType.business,
        );

        expect(analytics.totalReservations, equals(0));
        expect(analytics.completedReservations, equals(0));
        expect(analytics.confirmedReservations, equals(0));
        expect(analytics.cancelledReservations, equals(0));
        expect(analytics.completionRate, equals(0.0));
        expect(analytics.cancellationRate, equals(0.0));
        expect(analytics.totalRevenue, equals(0.0));
      });

      test('should calculate revenue metrics correctly', () async {
        // Test business logic: revenue calculation
        const businessId = 'business-1';
        final now = DateTime.now();
        final reservations = [
          Reservation(
            id: 'res-1',
            agentId: 'agent-1',
            type: ReservationType.business,
            targetId: businessId,
            reservationTime: now.add(const Duration(days: 7)),
            partySize: 2,
            ticketCount: 2,
            ticketPrice: 50.0,
            status: ReservationStatus.completed,
            createdAt: now.subtract(const Duration(days: 30)),
            updatedAt: now.subtract(const Duration(days: 30)),
          ),
          Reservation(
            id: 'res-2',
            agentId: 'agent-2',
            type: ReservationType.business,
            targetId: businessId,
            reservationTime: now.add(const Duration(days: 14)),
            partySize: 1,
            ticketCount: 1,
            ticketPrice: 30.0,
            status: ReservationStatus.completed,
            createdAt: now.subtract(const Duration(days: 20)),
            updatedAt: now.subtract(const Duration(days: 20)),
          ),
        ];

        when(() => mockReservationService.getReservationsForTarget(
              type: ReservationType.business,
              targetId: businessId,
              status: any(named: 'status'),
            )).thenAnswer((_) async => reservations);

        final analytics = await service.getBusinessAnalytics(
          businessId: businessId,
          type: ReservationType.business,
        );

        expect(analytics.totalRevenue, equals(130.0)); // 100 + 30
        expect(analytics.averageRevenuePerReservation, equals(65.0)); // 130 / 2
      });

      test('should calculate volume by hour and day correctly', () async {
        // Test business logic: volume pattern calculation
        const businessId = 'business-1';
        final now = DateTime.now();
        // Create reservations at same hour
        final hour18 = now.copyWith(hour: 18, minute: 0);
        final reservations = List.generate(
            3,
            (i) => Reservation(
                  id: 'res-$i',
                  agentId: 'agent-${i + 1}',
                  type: ReservationType.business,
                  targetId: businessId,
                  reservationTime: hour18.add(Duration(days: i)),
                  partySize: 2,
                  ticketCount: 2,
                  ticketPrice: 50.0,
                  status: ReservationStatus.completed,
                  createdAt: now.subtract(const Duration(days: 30)),
                  updatedAt: now.subtract(const Duration(days: 30)),
                ));

        when(() => mockReservationService.getReservationsForTarget(
              type: ReservationType.business,
              targetId: businessId,
              status: any(named: 'status'),
            )).thenAnswer((_) async => reservations);

        final analytics = await service.getBusinessAnalytics(
          businessId: businessId,
          type: ReservationType.business,
        );

        expect(analytics.volumeByHour[18], equals(3));
        expect(analytics.peakHours.contains(18), isTrue);
      });

      test('should calculate customer retention correctly', () async {
        // Test business logic: retention rate calculation
        const businessId = 'business-1';
        final now = DateTime.now();
        // Same agent with multiple reservations
        final reservations = [
          Reservation(
            id: 'res-1',
            agentId: 'agent-1',
            type: ReservationType.business,
            targetId: businessId,
            reservationTime: now.add(const Duration(days: 7)),
            partySize: 2,
            ticketCount: 2,
            ticketPrice: 50.0,
            status: ReservationStatus.completed,
            createdAt: now.subtract(const Duration(days: 30)),
            updatedAt: now.subtract(const Duration(days: 30)),
          ),
          Reservation(
            id: 'res-2',
            agentId: 'agent-1', // Same agent
            type: ReservationType.business,
            targetId: businessId,
            reservationTime: now.add(const Duration(days: 14)),
            partySize: 1,
            ticketCount: 1,
            ticketPrice: 30.0,
            status: ReservationStatus.completed,
            createdAt: now.subtract(const Duration(days: 20)),
            updatedAt: now.subtract(const Duration(days: 20)),
          ),
          Reservation(
            id: 'res-3',
            agentId: 'agent-2', // Different agent
            type: ReservationType.business,
            targetId: businessId,
            reservationTime: now.add(const Duration(days: 21)),
            partySize: 4,
            ticketCount: 4,
            ticketPrice: 40.0,
            status: ReservationStatus.completed,
            createdAt: now.subtract(const Duration(days: 10)),
            updatedAt: now.subtract(const Duration(days: 10)),
          ),
        ];

        when(() => mockReservationService.getReservationsForTarget(
              type: ReservationType.business,
              targetId: businessId,
              status: any(named: 'status'),
            )).thenAnswer((_) async => reservations);

        final analytics = await service.getBusinessAnalytics(
          businessId: businessId,
          type: ReservationType.business,
        );

        // 2 unique customers, 1 repeat customer (agent-1 has 2 reservations)
        expect(analytics.customerRetentionRate, greaterThan(0.0));
      });

      test('should filter reservations by date range correctly', () async {
        // Test business logic: date range filtering
        const businessId = 'business-1';
        final now = DateTime.now();
        final startDate = now.subtract(const Duration(days: 15));
        final endDate = now.add(const Duration(days: 15));

        final reservations = [
          Reservation(
            id: 'res-1',
            agentId: 'agent-1',
            type: ReservationType.business,
            targetId: businessId,
            reservationTime: now.add(const Duration(days: 7)), // Within range
            partySize: 2,
            ticketCount: 2,
            ticketPrice: 50.0,
            status: ReservationStatus.completed,
            createdAt: now.subtract(const Duration(days: 30)),
            updatedAt: now.subtract(const Duration(days: 30)),
          ),
          Reservation(
            id: 'res-2',
            agentId: 'agent-2',
            type: ReservationType.business,
            targetId: businessId,
            reservationTime: now.add(const Duration(days: 30)), // Outside range
            partySize: 1,
            ticketCount: 1,
            ticketPrice: 30.0,
            status: ReservationStatus.completed,
            createdAt: now.subtract(const Duration(days: 20)),
            updatedAt: now.subtract(const Duration(days: 20)),
          ),
        ];

        when(() => mockReservationService.getReservationsForTarget(
              type: ReservationType.business,
              targetId: businessId,
              status: any(named: 'status'),
            )).thenAnswer((_) async => reservations);

        final analytics = await service.getBusinessAnalytics(
          businessId: businessId,
          type: ReservationType.business,
          startDate: startDate,
          endDate: endDate,
        );

        // Should only count reservation within date range
        expect(analytics.totalReservations, equals(1));
      });

      test(
          'should return null for advanced analytics when optional services unavailable',
          () async {
        // Test error handling: graceful degradation when optional services null
        const businessId = 'business-1';
        final now = DateTime.now();
        final reservations = [
          Reservation(
            id: 'res-1',
            agentId: 'agent-1',
            type: ReservationType.business,
            targetId: businessId,
            reservationTime: now.add(const Duration(days: 7)),
            partySize: 2,
            ticketCount: 2,
            ticketPrice: 50.0,
            status: ReservationStatus.completed,
            createdAt: now.subtract(const Duration(days: 30)),
            updatedAt: now.subtract(const Duration(days: 30)),
          ),
        ];

        when(() => mockReservationService.getReservationsForTarget(
              type: ReservationType.business,
              targetId: businessId,
              status: any(named: 'status'),
            )).thenAnswer((_) async => reservations);

        final analytics = await service.getBusinessAnalytics(
          businessId: businessId,
          type: ReservationType.business,
        );

        // Advanced analytics should be null when services unavailable
        // Note: AI2AI learning insights returns placeholder data even when service unavailable
        expect(analytics.rateLimitMetrics, isNull);
        expect(analytics.waitlistMetrics, isNull);
        expect(analytics.capacityMetrics, isNull);
        expect(analytics.stringEvolutionPatterns, isNull);
        expect(analytics.fabricStabilityAnalytics, isNull);
        expect(analytics.worldsheetEvolutionAnalytics, isNull);
        expect(analytics.quantumCompatibilityTrends, isNull);
        // AI2AI learning insights returns placeholder data (not null) even when service unavailable
        expect(analytics.ai2aiLearningInsights, isNotNull);
        expect(analytics.ai2aiLearningInsights!.totalInsights, equals(0));
      });

      test('should handle service errors gracefully without crashing',
          () async {
        // Test error handling: service failure recovery
        const businessId = 'business-1';
        when(() => mockReservationService.getReservationsForTarget(
              type: ReservationType.business,
              targetId: businessId,
              status: any(named: 'status'),
            )).thenThrow(Exception('Service error'));

        expect(
          () => service.getBusinessAnalytics(
            businessId: businessId,
            type: ReservationType.business,
          ),
          throwsException,
        );
      });

      test('should calculate no-show rate correctly', () async {
        // Test business logic: no-show rate calculation
        const businessId = 'business-1';
        final now = DateTime.now();
        final reservations = [
          Reservation(
            id: 'res-1',
            agentId: 'agent-1',
            type: ReservationType.business,
            targetId: businessId,
            reservationTime: now.add(const Duration(days: 7)),
            partySize: 2,
            ticketCount: 2,
            ticketPrice: 50.0,
            status: ReservationStatus.completed,
            createdAt: now.subtract(const Duration(days: 30)),
            updatedAt: now.subtract(const Duration(days: 30)),
          ),
          Reservation(
            id: 'res-2',
            agentId: 'agent-2',
            type: ReservationType.business,
            targetId: businessId,
            reservationTime: now.add(const Duration(days: 14)),
            partySize: 1,
            ticketCount: 1,
            ticketPrice: 30.0,
            status: ReservationStatus.noShow,
            createdAt: now.subtract(const Duration(days: 20)),
            updatedAt: now.subtract(const Duration(days: 20)),
          ),
        ];

        when(() => mockReservationService.getReservationsForTarget(
              type: ReservationType.business,
              targetId: businessId,
              status: any(named: 'status'),
            )).thenAnswer((_) async => reservations);

        final analytics = await service.getBusinessAnalytics(
          businessId: businessId,
          type: ReservationType.business,
        );

        expect(analytics.noShowReservations, equals(1));
        expect(analytics.noShowRate, closeTo(1.0 / 2.0, 0.001));
      });
    });
  });
}
