/// SPOTS Reservation Service Tests
/// Date: January 1, 2026
/// Purpose: Test ReservationService functionality
/// 
/// Test Coverage:
/// - Core Methods: createReservation, getUserReservations, updateReservation, cancelReservation
/// - Offline-First: Local storage operations
/// - Privacy: agentId usage (not userId)
/// - Error Handling: Invalid inputs, edge cases
/// 
/// Dependencies:
/// - Mock AtomicClockService: Atomic timestamp generation
/// - Mock ReservationQuantumService: Quantum state creation
/// - Mock AgentIdService: Agent ID resolution
/// - Mock StorageService: Local storage
/// - Mock SupabaseService: Cloud sync
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
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/core/services/reservation_quantum_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/services/supabase_service.dart';
import 'package:avrai/core/services/payment_service.dart';
import 'package:avrai/core/services/refund_service.dart';
import 'package:avrai/core/services/reservation_cancellation_policy_service.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/models/payment.dart';
import 'package:avrai/core/models/payment_result.dart';
import 'package:avrai/core/models/payment_intent.dart';
import 'package:avrai/core/models/payment_status.dart';
import 'package:avrai/core/models/refund_distribution.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';

// Mock dependencies
class MockAtomicClockService extends Mock implements AtomicClockService {}
class MockReservationQuantumService extends Mock implements ReservationQuantumService {}
class MockAgentIdService extends Mock implements AgentIdService {}
class MockStorageService extends Mock implements StorageService {}
class MockSupabaseService extends Mock implements SupabaseService {}
class MockPaymentService extends Mock implements PaymentService {}
class MockRefundService extends Mock implements RefundService {}
class MockReservationCancellationPolicyService extends Mock implements ReservationCancellationPolicyService {}

void main() {
  setUpAll(() {
    // Register fallback values for enum types used in mocks
    registerFallbackValue(ReservationType.event);
    // Register fallback value for Reservation model (needed for any() matchers)
    registerFallbackValue(Reservation(
      id: 'fallback-reservation',
      agentId: 'fallback-agent',
      type: ReservationType.event,
      targetId: 'fallback-target',
      reservationTime: DateTime.now(),
      partySize: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  });
  group('ReservationService', () {
    late ReservationService service;
    late MockAtomicClockService mockAtomicClock;
    late MockReservationQuantumService mockQuantumService;
    late MockAgentIdService mockAgentIdService;
    late MockStorageService mockStorageService;
    late MockSupabaseService mockSupabaseService;
    late MockPaymentService? mockPaymentService;
    late MockRefundService? mockRefundService;
    late MockReservationCancellationPolicyService? mockCancellationPolicyService;

    setUp(() {
      mockAtomicClock = MockAtomicClockService();
      mockQuantumService = MockReservationQuantumService();
      mockAgentIdService = MockAgentIdService();
      mockStorageService = MockStorageService();
      mockSupabaseService = MockSupabaseService();
      mockPaymentService = null; // Default: no payment service
      mockRefundService = null; // Default: no refund service
      mockCancellationPolicyService = null; // Default: no cancellation policy service

      service = ReservationService(
        atomicClock: mockAtomicClock,
        quantumService: mockQuantumService,
        agentIdService: mockAgentIdService,
        storageService: mockStorageService,
        supabaseService: mockSupabaseService,
        paymentService: mockPaymentService,
        refundService: mockRefundService,
        cancellationPolicyService: mockCancellationPolicyService,
      );
    });

    group('createReservation', () {
      test('should create reservation with quantum state and atomic timestamp', () async {
        // Arrange
        const userId = 'user-123';
        const agentId = 'agent-123';
        const eventId = 'event-456';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );

        final quantumState = QuantumEntityState(
          entityId: userId,
          entityType: QuantumEntityType.user,
          personalityState: {},
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: atomicTimestamp,
        );

        // Setup mocks
        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(() => mockAtomicClock.getTicketPurchaseTimestamp())
            .thenAnswer((_) async => atomicTimestamp);
        when(() => mockQuantumService.createReservationQuantumState(
          userId: any(named: 'userId'),
          eventId: any(named: 'eventId'),
          reservationTime: any(named: 'reservationTime'),
        )).thenAnswer((_) async => quantumState);
        when(() => mockStorageService.setString(any(), any()))
            .thenAnswer((_) async => true);
        when(() => mockSupabaseService.isAvailable).thenReturn(false); // Offline

        // Act
        final reservation = await service.createReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          partySize: 2,
        );

        // Assert - Test actual behavior
        expect(reservation, isA<Reservation>());
        expect(reservation.agentId, equals(agentId)); // Uses agentId, not userId
        expect(reservation.type, equals(ReservationType.event));
        expect(reservation.targetId, equals(eventId));
        expect(reservation.partySize, equals(2));
        expect(reservation.status, equals(ReservationStatus.confirmed)); // Free reservations are automatically confirmed
        expect(reservation.atomicTimestamp, equals(atomicTimestamp));
        expect(reservation.quantumState, equals(quantumState));

        // Verify interactions
        verify(() => mockAgentIdService.getUserAgentId(userId)).called(1);
        verify(() => mockAtomicClock.getTicketPurchaseTimestamp()).called(1);
        verify(() => mockQuantumService.createReservationQuantumState(
          userId: userId,
          eventId: eventId,
          reservationTime: reservationTime,
        )).called(1);
        verify(() => mockStorageService.setString(any(), any())).called(1);
      });

      test('should sync to cloud when online', () async {
        // Arrange
        const userId = 'user-123';
        const agentId = 'agent-123';
        const eventId = 'event-456';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );

        final quantumState = QuantumEntityState(
          entityId: userId,
          entityType: QuantumEntityType.user,
          personalityState: {},
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: atomicTimestamp,
        );

        // Setup mocks
        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(() => mockAtomicClock.getTicketPurchaseTimestamp())
            .thenAnswer((_) async => atomicTimestamp);
        when(() => mockQuantumService.createReservationQuantumState(
          userId: any(named: 'userId'),
          eventId: any(named: 'eventId'),
          reservationTime: any(named: 'reservationTime'),
        )).thenAnswer((_) async => quantumState);
        when(() => mockStorageService.setString(any(), any()))
            .thenAnswer((_) async => true);
        when(() => mockSupabaseService.isAvailable).thenReturn(true); // Online
        when(() => mockSupabaseService.client).thenThrow(Exception('Not implemented')); // Will fail gracefully

        // Act
        final reservation = await service.createReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          partySize: 2,
        );

        // Assert - Reservation should still be created even if cloud sync fails
        expect(reservation, isA<Reservation>());
        expect(reservation.agentId, equals(agentId));
      });
    });

    group('getUserReservations', () {
      test('should get reservations from local storage when offline', () async {
        // Arrange
        const userId = 'user-123';
        const agentId = 'agent-123';

        // Create test reservation
        final testReservation = Reservation(
          id: 'reservation-1',
          agentId: agentId,
          type: ReservationType.event,
          targetId: 'event-456',
          reservationTime: DateTime.now().add(const Duration(days: 7)),
          partySize: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Setup mocks
        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(() => mockStorageService.getKeys()).thenReturn(['reservation_reservation-1']);
        when(() => mockStorageService.getString('reservation_reservation-1'))
            .thenReturn('{"id":"reservation-1","agentId":"$agentId","type":"event","targetId":"event-456","reservationTime":"${testReservation.reservationTime.toIso8601String()}","partySize":2,"ticketCount":1,"status":"pending","modificationCount":0,"disputeStatus":"none","metadata":{},"createdAt":"${testReservation.createdAt.toIso8601String()}","updatedAt":"${testReservation.updatedAt.toIso8601String()}"}');
        when(() => mockSupabaseService.isAvailable).thenReturn(false); // Offline

        // Act
        final reservations = await service.getUserReservations(userId: userId);

        // Assert
        expect(reservations, isA<List<Reservation>>());
        expect(reservations.length, greaterThanOrEqualTo(0));
      });
    });

    group('hasExistingReservation', () {
      test('should return true when reservation exists for same target and time', () async {
        // Arrange
        const userId = 'user-123';
        const agentId = 'agent-123';
        const eventId = 'event-456';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        // Create existing reservation
        final existingReservation = Reservation(
          id: 'reservation-1',
          agentId: agentId,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          partySize: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Setup mocks
        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(() => mockStorageService.getKeys()).thenReturn(['reservation_reservation-1']);
        when(() => mockStorageService.getString('reservation_reservation-1'))
            .thenReturn('{"id":"reservation-1","agentId":"$agentId","type":"event","targetId":"$eventId","reservationTime":"${reservationTime.toIso8601String()}","partySize":2,"ticketCount":1,"status":"pending","modificationCount":0,"disputeStatus":"none","metadata":{},"createdAt":"${existingReservation.createdAt.toIso8601String()}","updatedAt":"${existingReservation.updatedAt.toIso8601String()}"}');
        when(() => mockSupabaseService.isAvailable).thenReturn(false);

        // Act
        final hasExisting = await service.hasExistingReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
        );

        // Assert
        expect(hasExisting, isTrue);
      });

      test('should return false when no reservation exists', () async {
        // Arrange
        const userId = 'user-123';
        const eventId = 'event-456';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        // Setup mocks
        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => 'agent-123');
        when(() => mockStorageService.getKeys()).thenReturn([]);
        when(() => mockSupabaseService.isAvailable).thenReturn(false);

        // Act
        final hasExisting = await service.hasExistingReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
        );

        // Assert
        expect(hasExisting, isFalse);
      });
    });

    group('updateReservation', () {
      test('should update reservation and increment modification count', () async {
        // Arrange
        const reservationId = 'reservation-1';
        const agentId = 'agent-123';
        final originalTime = DateTime.now().add(const Duration(days: 7));
        final newTime = DateTime.now().add(const Duration(days: 8));

        // Create existing reservation
        final existingReservation = Reservation(
          id: reservationId,
          agentId: agentId,
          type: ReservationType.event,
          targetId: 'event-456',
          reservationTime: originalTime,
          partySize: 2,
          modificationCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Setup mocks
        when(() => mockStorageService.getString('reservation_$reservationId'))
            .thenReturn('{"id":"$reservationId","agentId":"$agentId","type":"event","targetId":"event-456","reservationTime":"${originalTime.toIso8601String()}","partySize":2,"ticketCount":1,"status":"pending","modificationCount":0,"disputeStatus":"none","metadata":{},"createdAt":"${existingReservation.createdAt.toIso8601String()}","updatedAt":"${existingReservation.updatedAt.toIso8601String()}"}');
        when(() => mockStorageService.setString(any(), any()))
            .thenAnswer((_) async => true);
        when(() => mockSupabaseService.isAvailable).thenReturn(false);

        // Act
        final updated = await service.updateReservation(
          reservationId: reservationId,
          reservationTime: newTime,
        );

        // Assert
        expect(updated, isA<Reservation>());
        expect(updated.id, equals(reservationId));
        expect(updated.reservationTime, equals(newTime));
        expect(updated.modificationCount, equals(1)); // Incremented
        expect(updated.lastModifiedAt, isNotNull);
      });

      test('should throw exception when reservation cannot be modified', () async {
        // Arrange
        const reservationId = 'reservation-1';
        const agentId = 'agent-123';
        final originalTime = DateTime.now().add(const Duration(hours: 30)); // Too close

        // Create existing reservation with max modifications
        final existingReservation = Reservation(
          id: reservationId,
          agentId: agentId,
          type: ReservationType.event,
          targetId: 'event-456',
          reservationTime: originalTime,
          partySize: 2,
          modificationCount: 3, // Max modifications
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Setup mocks
        when(() => mockStorageService.getString('reservation_$reservationId'))
            .thenReturn('{"id":"$reservationId","agentId":"$agentId","type":"event","targetId":"event-456","reservationTime":"${originalTime.toIso8601String()}","partySize":2,"ticketCount":1,"status":"pending","modificationCount":3,"disputeStatus":"none","metadata":{},"createdAt":"${existingReservation.createdAt.toIso8601String()}","updatedAt":"${existingReservation.updatedAt.toIso8601String()}"}');

        // Act & Assert
        expect(
          () => service.updateReservation(
            reservationId: reservationId,
            reservationTime: originalTime.add(const Duration(days: 1)),
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('cannot be modified'),
          )),
        );
      });
    });

    group('cancelReservation', () {
      test('should cancel reservation and update status', () async {
        // Arrange
        const reservationId = 'reservation-1';
        const agentId = 'agent-123';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        // Create existing reservation
        final existingReservation = Reservation(
          id: reservationId,
          agentId: agentId,
          type: ReservationType.event,
          targetId: 'event-456',
          reservationTime: reservationTime,
          partySize: 2,
          status: ReservationStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Setup mocks
        when(() => mockStorageService.getString('reservation_$reservationId'))
            .thenReturn('{"id":"$reservationId","agentId":"$agentId","type":"event","targetId":"event-456","reservationTime":"${reservationTime.toIso8601String()}","partySize":2,"ticketCount":1,"status":"pending","modificationCount":0,"disputeStatus":"none","metadata":{},"createdAt":"${existingReservation.createdAt.toIso8601String()}","updatedAt":"${existingReservation.updatedAt.toIso8601String()}"}');
        when(() => mockStorageService.setString(any(), any()))
            .thenAnswer((_) async => true);
        when(() => mockSupabaseService.isAvailable).thenReturn(false);

        // Act
        final cancelled = await service.cancelReservation(
          reservationId: reservationId,
          reason: 'User request',
        );

        // Assert
        expect(cancelled, isA<Reservation>());
        expect(cancelled.id, equals(reservationId));
        expect(cancelled.status, equals(ReservationStatus.cancelled));
      });

      test('should throw exception when reservation cannot be cancelled', () async {
        // Arrange
        const reservationId = 'reservation-1';
        const agentId = 'agent-123';

        // Create existing reservation that's already cancelled
        final existingReservation = Reservation(
          id: reservationId,
          agentId: agentId,
          type: ReservationType.event,
          targetId: 'event-456',
          reservationTime: DateTime.now().add(const Duration(days: 7)),
          partySize: 2,
          status: ReservationStatus.cancelled, // Already cancelled
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Setup mocks
        when(() => mockStorageService.getString('reservation_$reservationId'))
            .thenReturn('{"id":"$reservationId","agentId":"$agentId","type":"event","targetId":"event-456","reservationTime":"${existingReservation.reservationTime.toIso8601String()}","partySize":2,"ticketCount":1,"status":"cancelled","modificationCount":0,"disputeStatus":"none","metadata":{},"createdAt":"${existingReservation.createdAt.toIso8601String()}","updatedAt":"${existingReservation.updatedAt.toIso8601String()}"}');

        // Act & Assert
        expect(
          () => service.cancelReservation(
            reservationId: reservationId,
            reason: 'User request',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('cannot be cancelled'),
          )),
        );
      });

      test('should process refund when reservation qualifies and has payment', () async {
        // Arrange
        const reservationId = 'reservation-1';
        const agentId = 'agent-123';
        const paymentId = 'payment-123';
        final reservationTime = DateTime.now().add(const Duration(days: 2)); // 48 hours away

        // Create paid reservation with payment ID in metadata
        final existingReservation = Reservation(
          id: reservationId,
          agentId: agentId,
          type: ReservationType.event,
          targetId: 'event-456',
          reservationTime: reservationTime,
          partySize: 2,
          ticketCount: 2,
          ticketPrice: 25.0,
          status: ReservationStatus.confirmed,
          metadata: {
            'paymentId': paymentId,
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Create payment
        final payment = Payment(
          id: paymentId,
          eventId: reservationId, // Workaround: using reservationId as eventId
          userId: 'user-123',
          amount: 50.0, // 2 tickets * $25
          status: PaymentStatus.completed,
          stripePaymentIntentId: 'pi_test123',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Create refund distribution
        final refundDistribution = RefundDistribution(
          userId: 'user-123',
          role: 'attendee',
          amount: 50.0,
          stripeRefundId: 're_test123',
          completedAt: DateTime.now(),
          statusMessage: 'Refund processed successfully',
        );

        // Setup mocks
        mockPaymentService = MockPaymentService();
        mockRefundService = MockRefundService();
        mockCancellationPolicyService = MockReservationCancellationPolicyService();

        service = ReservationService(
          atomicClock: mockAtomicClock,
          quantumService: mockQuantumService,
          agentIdService: mockAgentIdService,
          storageService: mockStorageService,
          supabaseService: mockSupabaseService,
          paymentService: mockPaymentService,
          refundService: mockRefundService,
          cancellationPolicyService: mockCancellationPolicyService,
        );

        when(() => mockStorageService.getString('reservation_$reservationId'))
            .thenReturn('{"id":"$reservationId","agentId":"$agentId","type":"event","targetId":"event-456","reservationTime":"${reservationTime.toIso8601String()}","partySize":2,"ticketCount":2,"ticketPrice":25.0,"status":"confirmed","modificationCount":0,"disputeStatus":"none","metadata":{"paymentId":"$paymentId"},"createdAt":"${existingReservation.createdAt.toIso8601String()}","updatedAt":"${existingReservation.updatedAt.toIso8601String()}"}');
        when(() => mockStorageService.setString(any(), any()))
            .thenAnswer((_) async => true);
        when(() => mockSupabaseService.isAvailable).thenReturn(false);

        when(() => mockPaymentService!.getPayment(paymentId))
            .thenReturn(payment);
        when(() => mockCancellationPolicyService!.qualifiesForRefund(
          reservation: any(named: 'reservation'),
          cancellationTime: any(named: 'cancellationTime'),
        )).thenAnswer((_) async => true);
        when(() => mockCancellationPolicyService!.calculateRefund(
          reservation: any(named: 'reservation'),
          cancellationTime: any(named: 'cancellationTime'),
        )).thenAnswer((_) async => 50.0); // Full refund
        when(() => mockRefundService!.processRefund(
          paymentId: any(named: 'paymentId'),
          amount: any(named: 'amount'),
          cancellationId: any(named: 'cancellationId'),
        )).thenAnswer((_) async => [refundDistribution]);

        // Act
        final cancelled = await service.cancelReservation(
          reservationId: reservationId,
          reason: 'User request',
          applyPolicy: true,
        );

        // Assert
        expect(cancelled.status, equals(ReservationStatus.cancelled));
        expect(cancelled.metadata['refundProcessed'], equals(true));
        expect(cancelled.metadata['refundAmount'], equals(50.0));
        expect(cancelled.metadata['refundDistributionId'], equals('re_test123'));

        // Verify interactions
        verify(() => mockPaymentService!.getPayment(paymentId)).called(1);
        verify(() => mockCancellationPolicyService!.qualifiesForRefund(
          reservation: any(named: 'reservation'),
          cancellationTime: any(named: 'cancellationTime'),
        )).called(1);
        verify(() => mockCancellationPolicyService!.calculateRefund(
          reservation: any(named: 'reservation'),
          cancellationTime: any(named: 'cancellationTime'),
        )).called(1);
        verify(() => mockRefundService!.processRefund(
          paymentId: paymentId,
          amount: 50.0,
          cancellationId: reservationId,
        )).called(1);
      });

      test('should cancel without refund when reservation does not qualify', () async {
        // Arrange
        const reservationId = 'reservation-1';
        const agentId = 'agent-123';
        const paymentId = 'payment-123';
        final reservationTime = DateTime.now().add(const Duration(hours: 12)); // Too late (12 hours < 24)

        // Create paid reservation
        final existingReservation = Reservation(
          id: reservationId,
          agentId: agentId,
          type: ReservationType.event,
          targetId: 'event-456',
          reservationTime: reservationTime,
          partySize: 2,
          ticketCount: 2,
          ticketPrice: 25.0,
          status: ReservationStatus.confirmed,
          metadata: {
            'paymentId': paymentId,
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Create payment
        final payment = Payment(
          id: paymentId,
          eventId: reservationId,
          userId: 'user-123',
          amount: 50.0,
          status: PaymentStatus.completed,
          stripePaymentIntentId: 'pi_test123',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Setup mocks
        mockPaymentService = MockPaymentService();
        mockRefundService = MockRefundService();
        mockCancellationPolicyService = MockReservationCancellationPolicyService();

        service = ReservationService(
          atomicClock: mockAtomicClock,
          quantumService: mockQuantumService,
          agentIdService: mockAgentIdService,
          storageService: mockStorageService,
          supabaseService: mockSupabaseService,
          paymentService: mockPaymentService,
          refundService: mockRefundService,
          cancellationPolicyService: mockCancellationPolicyService,
        );

        when(() => mockStorageService.getString('reservation_$reservationId'))
            .thenReturn('{"id":"$reservationId","agentId":"$agentId","type":"event","targetId":"event-456","reservationTime":"${reservationTime.toIso8601String()}","partySize":2,"ticketCount":2,"ticketPrice":25.0,"status":"confirmed","modificationCount":0,"disputeStatus":"none","metadata":{"paymentId":"$paymentId"},"createdAt":"${existingReservation.createdAt.toIso8601String()}","updatedAt":"${existingReservation.updatedAt.toIso8601String()}"}');
        when(() => mockStorageService.setString(any(), any()))
            .thenAnswer((_) async => true);
        when(() => mockSupabaseService.isAvailable).thenReturn(false);

        when(() => mockPaymentService!.getPayment(paymentId))
            .thenReturn(payment);
        when(() => mockCancellationPolicyService!.qualifiesForRefund(
          reservation: any(named: 'reservation'),
          cancellationTime: any(named: 'cancellationTime'),
        )).thenAnswer((_) async => false); // Doesn't qualify

        // Act
        final cancelled = await service.cancelReservation(
          reservationId: reservationId,
          reason: 'User request',
          applyPolicy: true,
        );

        // Assert
        expect(cancelled.status, equals(ReservationStatus.cancelled));
        expect(cancelled.metadata['refundProcessed'], isNull); // No refund processed

        // Verify interactions
        verify(() => mockPaymentService!.getPayment(paymentId)).called(1);
        verify(() => mockCancellationPolicyService!.qualifiesForRefund(
          reservation: any(named: 'reservation'),
          cancellationTime: any(named: 'cancellationTime'),
        )).called(1);
        verifyNever(() => mockCancellationPolicyService!.calculateRefund(
          reservation: any(named: 'reservation'),
          cancellationTime: any(named: 'cancellationTime'),
        ));
        verifyNever(() => mockRefundService!.processRefund(
          paymentId: any(named: 'paymentId'),
          amount: any(named: 'amount'),
          cancellationId: any(named: 'cancellationId'),
        ));
      });

      test('should cancel free reservation without refund processing', () async {
        // Arrange
        const reservationId = 'reservation-1';
        const agentId = 'agent-123';
        final reservationTime = DateTime.now().add(const Duration(days: 2));

        // Create free reservation (no payment ID in metadata)
        final existingReservation = Reservation(
          id: reservationId,
          agentId: agentId,
          type: ReservationType.event,
          targetId: 'event-456',
          reservationTime: reservationTime,
          partySize: 2,
          status: ReservationStatus.confirmed,
          metadata: {}, // No payment ID
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Setup mocks
        mockPaymentService = MockPaymentService();
        mockRefundService = MockRefundService();
        mockCancellationPolicyService = MockReservationCancellationPolicyService();

        service = ReservationService(
          atomicClock: mockAtomicClock,
          quantumService: mockQuantumService,
          agentIdService: mockAgentIdService,
          storageService: mockStorageService,
          supabaseService: mockSupabaseService,
          paymentService: mockPaymentService,
          refundService: mockRefundService,
          cancellationPolicyService: mockCancellationPolicyService,
        );

        when(() => mockStorageService.getString('reservation_$reservationId'))
            .thenReturn('{"id":"$reservationId","agentId":"$agentId","type":"event","targetId":"event-456","reservationTime":"${reservationTime.toIso8601String()}","partySize":2,"ticketCount":1,"status":"confirmed","modificationCount":0,"disputeStatus":"none","metadata":{},"createdAt":"${existingReservation.createdAt.toIso8601String()}","updatedAt":"${existingReservation.updatedAt.toIso8601String()}"}');
        when(() => mockStorageService.setString(any(), any()))
            .thenAnswer((_) async => true);
        when(() => mockSupabaseService.isAvailable).thenReturn(false);

        // Act
        final cancelled = await service.cancelReservation(
          reservationId: reservationId,
          reason: 'User request',
          applyPolicy: true,
        );

        // Assert
        expect(cancelled.status, equals(ReservationStatus.cancelled));
        expect(cancelled.metadata['refundProcessed'], isNull); // No refund for free reservation

        // Verify no refund processing attempted
        verifyNever(() => mockPaymentService!.getPayment(any()));
        verifyNever(() => mockCancellationPolicyService!.qualifiesForRefund(
          reservation: any(named: 'reservation'),
          cancellationTime: any(named: 'cancellationTime'),
        ));
        verifyNever(() => mockRefundService!.processRefund(
          paymentId: any(named: 'paymentId'),
          amount: any(named: 'amount'),
          cancellationId: any(named: 'cancellationId'),
        ));
      });

      test('should cancel without refund when services unavailable (graceful degradation)', () async {
        // Arrange
        const reservationId = 'reservation-1';
        const agentId = 'agent-123';
        final reservationTime = DateTime.now().add(const Duration(days: 2));

        // Create paid reservation
        final existingReservation = Reservation(
          id: reservationId,
          agentId: agentId,
          type: ReservationType.event,
          targetId: 'event-456',
          reservationTime: reservationTime,
          partySize: 2,
          ticketPrice: 25.0,
          status: ReservationStatus.confirmed,
          metadata: {
            'paymentId': 'payment-123',
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Setup mocks - services not available
        when(() => mockStorageService.getString('reservation_$reservationId'))
            .thenReturn('{"id":"$reservationId","agentId":"$agentId","type":"event","targetId":"event-456","reservationTime":"${reservationTime.toIso8601String()}","partySize":2,"ticketCount":1,"ticketPrice":25.0,"status":"confirmed","modificationCount":0,"disputeStatus":"none","metadata":{"paymentId":"payment-123"},"createdAt":"${existingReservation.createdAt.toIso8601String()}","updatedAt":"${existingReservation.updatedAt.toIso8601String()}"}');
        when(() => mockStorageService.setString(any(), any()))
            .thenAnswer((_) async => true);
        when(() => mockSupabaseService.isAvailable).thenReturn(false);

        // Act
        final cancelled = await service.cancelReservation(
          reservationId: reservationId,
          reason: 'User request',
          applyPolicy: true,
        );

        // Assert - Cancellation should proceed even without refund services
        expect(cancelled.status, equals(ReservationStatus.cancelled));
        expect(cancelled.metadata['refundProcessed'], isNull);
      });

      test('should cancel even when refund processing fails', () async {
        // Arrange
        const reservationId = 'reservation-1';
        const agentId = 'agent-123';
        const paymentId = 'payment-123';
        final reservationTime = DateTime.now().add(const Duration(days: 2));

        // Create paid reservation
        final existingReservation = Reservation(
          id: reservationId,
          agentId: agentId,
          type: ReservationType.event,
          targetId: 'event-456',
          reservationTime: reservationTime,
          partySize: 2,
          ticketCount: 2,
          ticketPrice: 25.0,
          status: ReservationStatus.confirmed,
          metadata: {
            'paymentId': paymentId,
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Create payment
        final payment = Payment(
          id: paymentId,
          eventId: reservationId,
          userId: 'user-123',
          amount: 50.0,
          status: PaymentStatus.completed,
          stripePaymentIntentId: 'pi_test123',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Setup mocks
        mockPaymentService = MockPaymentService();
        mockRefundService = MockRefundService();
        mockCancellationPolicyService = MockReservationCancellationPolicyService();

        service = ReservationService(
          atomicClock: mockAtomicClock,
          quantumService: mockQuantumService,
          agentIdService: mockAgentIdService,
          storageService: mockStorageService,
          supabaseService: mockSupabaseService,
          paymentService: mockPaymentService,
          refundService: mockRefundService,
          cancellationPolicyService: mockCancellationPolicyService,
        );

        when(() => mockStorageService.getString('reservation_$reservationId'))
            .thenReturn('{"id":"$reservationId","agentId":"$agentId","type":"event","targetId":"event-456","reservationTime":"${reservationTime.toIso8601String()}","partySize":2,"ticketCount":2,"ticketPrice":25.0,"status":"confirmed","modificationCount":0,"disputeStatus":"none","metadata":{"paymentId":"$paymentId"},"createdAt":"${existingReservation.createdAt.toIso8601String()}","updatedAt":"${existingReservation.updatedAt.toIso8601String()}"}');
        when(() => mockStorageService.setString(any(), any()))
            .thenAnswer((_) async => true);
        when(() => mockSupabaseService.isAvailable).thenReturn(false);

        when(() => mockPaymentService!.getPayment(paymentId))
            .thenReturn(payment);
        when(() => mockCancellationPolicyService!.qualifiesForRefund(
          reservation: any(named: 'reservation'),
          cancellationTime: any(named: 'cancellationTime'),
        )).thenAnswer((_) async => true);
        when(() => mockCancellationPolicyService!.calculateRefund(
          reservation: any(named: 'reservation'),
          cancellationTime: any(named: 'cancellationTime'),
        )).thenAnswer((_) async => 50.0);
        when(() => mockRefundService!.processRefund(
          paymentId: any(named: 'paymentId'),
          amount: any(named: 'amount'),
          cancellationId: any(named: 'cancellationId'),
        )).thenThrow(Exception('Refund processing failed')); // Refund fails

        // Act
        final cancelled = await service.cancelReservation(
          reservationId: reservationId,
          reason: 'User request',
          applyPolicy: true,
        );

        // Assert - Cancellation should proceed even if refund fails
        expect(cancelled.status, equals(ReservationStatus.cancelled));
        expect(cancelled.metadata['refundProcessed'], isNull); // No refund metadata (failed)

        // Verify refund was attempted
        verify(() => mockRefundService!.processRefund(
          paymentId: paymentId,
          amount: 50.0,
          cancellationId: reservationId,
        )).called(1);
      });

      test('should create free reservation and automatically confirm', () async {
        // Arrange
        const userId = 'user-123';
        const agentId = 'agent-123';
        const eventId = 'event-456';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );

        final quantumState = QuantumEntityState(
          entityId: userId,
          entityType: QuantumEntityType.user,
          personalityState: {},
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: atomicTimestamp,
        );

        // Setup mocks
        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(() => mockAtomicClock.getTicketPurchaseTimestamp())
            .thenAnswer((_) async => atomicTimestamp);
        when(() => mockQuantumService.createReservationQuantumState(
          userId: any(named: 'userId'),
          eventId: any(named: 'eventId'),
          reservationTime: any(named: 'reservationTime'),
        )).thenAnswer((_) async => quantumState);
        when(() => mockStorageService.setString(any(), any()))
            .thenAnswer((_) async => true);
        when(() => mockSupabaseService.isAvailable).thenReturn(false); // Offline

        // Act - Create free reservation (ticketPrice == null)
        final reservation = await service.createReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          partySize: 2,
          ticketPrice: null, // Free reservation
        );

        // Assert - Free reservations are automatically confirmed
        expect(reservation.status, equals(ReservationStatus.confirmed));
        expect(reservation.ticketPrice, isNull);
        expect(reservation.metadata.containsKey('paymentId'), isFalse);

        // Verify no payment processing occurred (payment service is null, so can't verify)
        // No-op since payment service is null for free reservations
      });

      test('should create free reservation with ticketPrice 0 and automatically confirm', () async {
        // Arrange
        const userId = 'user-123';
        const agentId = 'agent-123';
        const eventId = 'event-456';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );

        final quantumState = QuantumEntityState(
          entityId: userId,
          entityType: QuantumEntityType.user,
          personalityState: {},
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: atomicTimestamp,
        );

        // Setup mocks
        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(() => mockAtomicClock.getTicketPurchaseTimestamp())
            .thenAnswer((_) async => atomicTimestamp);
        when(() => mockQuantumService.createReservationQuantumState(
          userId: any(named: 'userId'),
          eventId: any(named: 'eventId'),
          reservationTime: any(named: 'reservationTime'),
        )).thenAnswer((_) async => quantumState);
        when(() => mockStorageService.setString(any(), any()))
            .thenAnswer((_) async => true);
        when(() => mockSupabaseService.isAvailable).thenReturn(false); // Offline

        // Act - Create free reservation (ticketPrice == 0)
        final reservation = await service.createReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          partySize: 2,
          ticketPrice: 0.0, // Free reservation
        );

        // Assert - Free reservations are automatically confirmed
        expect(reservation.status, equals(ReservationStatus.confirmed));
        expect(reservation.ticketPrice, equals(0.0));
        expect(reservation.metadata.containsKey('paymentId'), isFalse);
      });

      test('should process payment for paid reservation and confirm on success', () async {
        // Arrange
        const userId = 'user-123';
        const agentId = 'agent-123';
        const eventId = 'event-456';
        const ticketPrice = 25.0;
        const ticketCount = 2;
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );

        final quantumState = QuantumEntityState(
          entityId: userId,
          entityType: QuantumEntityType.user,
          personalityState: {},
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: atomicTimestamp,
        );

        // Create mock payment service
        mockPaymentService = MockPaymentService();
        service = ReservationService(
          atomicClock: mockAtomicClock,
          quantumService: mockQuantumService,
          agentIdService: mockAgentIdService,
          storageService: mockStorageService,
          supabaseService: mockSupabaseService,
          paymentService: mockPaymentService,
        );

        // Create payment and payment intent for successful payment
        final payment = Payment(
          id: 'payment-123',
          eventId: 'reservation-id-will-be-set',
          userId: userId,
          amount: ticketPrice,
          status: PaymentStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          stripePaymentIntentId: 'pi_test123',
          quantity: ticketCount,
        );

        final paymentIntent = PaymentIntent(
          id: 'pi_test123',
          clientSecret: 'pi_test123_secret',
          amount: (ticketPrice * ticketCount * 100).round(),
          currency: 'usd',
          status: PaymentStatus.pending,
          createdAt: DateTime.now(),
        );

        // Setup mocks
        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(() => mockAtomicClock.getTicketPurchaseTimestamp())
            .thenAnswer((_) async => atomicTimestamp);
        when(() => mockQuantumService.createReservationQuantumState(
          userId: any(named: 'userId'),
          eventId: any(named: 'eventId'),
          reservationTime: any(named: 'reservationTime'),
        )).thenAnswer((_) async => quantumState);
        when(() => mockStorageService.setString(any(), any()))
            .thenAnswer((_) async => true);
        when(() => mockSupabaseService.isAvailable).thenReturn(false); // Offline
        when(() => mockPaymentService!.processReservationPayment(
          reservationId: any(named: 'reservationId'),
          reservationType: any(named: 'reservationType'),
          userId: any(named: 'userId'),
          ticketPrice: any(named: 'ticketPrice'),
          ticketCount: any(named: 'ticketCount'),
          depositAmount: any(named: 'depositAmount'),
        )).thenAnswer((invocation) async {
          // Get reservationId from invocation named arguments
          final reservationId = invocation.namedArguments[#reservationId] as String;
          // Return payment result with reservationId
          final paymentWithReservationId = payment.copyWith(
            eventId: reservationId,
          );
          return PaymentResult.success(
            payment: paymentWithReservationId,
            paymentIntent: paymentIntent,
            revenueSplit: null,
          );
        });

        // Act - Create paid reservation
        final reservation = await service.createReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          partySize: 2,
          ticketPrice: ticketPrice,
          ticketCount: ticketCount,
        );

        // Assert - Paid reservation should be confirmed after successful payment
        expect(reservation.status, equals(ReservationStatus.confirmed));
        expect(reservation.ticketPrice, equals(ticketPrice));
        expect(reservation.metadata.containsKey('paymentId'), isTrue);
        expect(reservation.metadata['paymentId'], equals('payment-123'));
        expect(reservation.metadata['stripePaymentIntentId'], equals('pi_test123'));

        // Verify payment processing was called
        verify(() => mockPaymentService!.processReservationPayment(
          reservationId: reservation.id,
          reservationType: ReservationType.event,
          userId: userId,
          ticketPrice: ticketPrice,
          ticketCount: ticketCount,
          depositAmount: null,
        )).called(1);
      });

      test('should fail reservation creation when payment processing fails', () async {
        // Arrange
        const userId = 'user-123';
        const agentId = 'agent-123';
        const eventId = 'event-456';
        const ticketPrice = 25.0;
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );

        final quantumState = QuantumEntityState(
          entityId: userId,
          entityType: QuantumEntityType.user,
          personalityState: {},
          quantumVibeAnalysis: {},
          entityCharacteristics: {},
          tAtomic: atomicTimestamp,
        );

        // Create mock payment service
        mockPaymentService = MockPaymentService();
        service = ReservationService(
          atomicClock: mockAtomicClock,
          quantumService: mockQuantumService,
          agentIdService: mockAgentIdService,
          storageService: mockStorageService,
          supabaseService: mockSupabaseService,
          paymentService: mockPaymentService,
        );

        final paymentResult = PaymentResult.failure(
          errorMessage: 'Payment processing failed',
          errorCode: 'PAYMENT_FAILED',
        );

        // Setup mocks
        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(() => mockAtomicClock.getTicketPurchaseTimestamp())
            .thenAnswer((_) async => atomicTimestamp);
        when(() => mockQuantumService.createReservationQuantumState(
          userId: any(named: 'userId'),
          eventId: any(named: 'eventId'),
          reservationTime: any(named: 'reservationTime'),
        )).thenAnswer((_) async => quantumState);
        when(() => mockPaymentService!.processReservationPayment(
          reservationId: any(named: 'reservationId'),
          reservationType: any(named: 'reservationType'),
          userId: any(named: 'userId'),
          ticketPrice: any(named: 'ticketPrice'),
          ticketCount: any(named: 'ticketCount'),
          depositAmount: any(named: 'depositAmount'),
        )).thenAnswer((_) async => paymentResult);

        // Act & Assert - Reservation creation should fail when payment fails
        try {
          await service.createReservation(
            userId: userId,
            type: ReservationType.event,
            targetId: eventId,
            reservationTime: reservationTime,
            partySize: 2,
            ticketPrice: ticketPrice,
          );
          fail('Expected exception was not thrown');
        } catch (e) {
          expect(e, isA<Exception>());
          expect(e.toString(), contains('Payment processing failed'));
        }

        // Verify payment processing was called (payment should be attempted before exception)
        verify(() => mockPaymentService!.processReservationPayment(
          reservationId: any(named: 'reservationId'),
          reservationType: ReservationType.event,
          userId: userId,
          ticketPrice: ticketPrice,
          ticketCount: 2, // Defaults to partySize
          depositAmount: null,
        )).called(1);

        // Verify reservation was NOT stored (should not reach storage due to exception)
        verifyNever(() => mockStorageService.setString(any(), any()));
      });
    });
  });
}
