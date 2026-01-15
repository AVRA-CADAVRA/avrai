/// SPOTS KnotEvolutionStringService Unit Tests
/// Date: January 6, 2026
/// Purpose: Test KnotEvolutionStringService functionality for Phase 9 (AVRAI Core System Services)
///
/// Test Coverage:
/// - String Creation: Create string from evolution history, handle empty history, handle missing knot
/// - Temporal Interpolation: Get knot at any time (interpolation between snapshots)
/// - Evolution Trajectory: Generate smooth curve through time
/// - Error Handling: Missing data, invalid inputs, storage errors
///
/// Dependencies:
/// - KnotStorageService: Load knots and evolution history
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
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_core/models/personality_knot.dart';

class MockKnotStorageService extends Mock implements KnotStorageService {}

void main() {
  group('KnotEvolutionStringService', () {
    late KnotEvolutionStringService service;
    late MockKnotStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockKnotStorageService();
      service = KnotEvolutionStringService(
        storageService: mockStorageService,
      );
    });

    group('createStringFromHistory', () {
      test('should create string from evolution history, return string with current knot when history is empty, and return null when no knot found', () async {
        // Test business logic: string creation with various data scenarios
        
        // Arrange - Create test knot and snapshots
        final testKnot = PersonalityKnot(
          agentId: 'agent-1',
          invariants: KnotInvariants(
            jonesPolynomial: [1.0, 2.0],
            alexanderPolynomial: [1.0],
            crossingNumber: 3,
            writhe: 1,
            signature: 0,
            bridgeNumber: 1,
            braidIndex: 1,
            determinant: 1,
          ),
          braidData: [8.0, 0.0, 1.0],
          createdAt: DateTime(2025, 1, 1),
          lastUpdated: DateTime(2025, 1, 1),
        );

        final snapshot1 = KnotSnapshot(
          timestamp: DateTime(2025, 1, 2),
          knot: testKnot,
          reason: 'Evolution milestone',
        );

        final snapshot2 = KnotSnapshot(
          timestamp: DateTime(2025, 1, 3),
          knot: testKnot,
          reason: 'Evolution milestone',
        );

        // Test: Create string from history
        when(() => mockStorageService.loadEvolutionHistory('agent-1'))
            .thenAnswer((_) async => [snapshot1, snapshot2]);

        final string1 = await service.createStringFromHistory('agent-1');

        expect(string1, isNotNull);
        expect(string1!.initialKnot.agentId, equals('agent-1'));
        expect(string1.snapshots.length, equals(2));
        expect(string1.snapshots.first.timestamp, equals(DateTime(2025, 1, 2)));

        // Test: Empty history - return string with current knot
        when(() => mockStorageService.loadEvolutionHistory('agent-2'))
            .thenAnswer((_) async => []);
        when(() => mockStorageService.loadKnot('agent-2'))
            .thenAnswer((_) async => testKnot);

        final string2 = await service.createStringFromHistory('agent-2');

        expect(string2, isNotNull);
        expect(string2!.initialKnot.agentId, equals('agent-2'));
        expect(string2.snapshots, isEmpty);

        // Test: No knot found - return null
        when(() => mockStorageService.loadEvolutionHistory('agent-3'))
            .thenAnswer((_) async => []);
        when(() => mockStorageService.loadKnot('agent-3'))
            .thenAnswer((_) async => null);

        final string3 = await service.createStringFromHistory('agent-3');

        expect(string3, isNull);
      });

      test('should sort snapshots by timestamp and use first snapshot as initial knot', () async {
        // Test business logic: snapshot sorting and initial knot selection
        
        final testKnot1 = PersonalityKnot(
          agentId: 'agent-1',
          invariants: KnotInvariants(
            jonesPolynomial: [1.0],
            alexanderPolynomial: [1.0],
            crossingNumber: 1,
            writhe: 0,
            signature: 0,
            bridgeNumber: 1,
            braidIndex: 1,
            determinant: 1,
          ),
          braidData: [8.0],
          createdAt: DateTime(2025, 1, 1),
          lastUpdated: DateTime(2025, 1, 1),
        );

        final testKnot2 = PersonalityKnot(
          agentId: 'agent-1',
          invariants: KnotInvariants(
            jonesPolynomial: [2.0],
            alexanderPolynomial: [2.0],
            crossingNumber: 2,
            writhe: 1,
            signature: 0,
            bridgeNumber: 1,
            braidIndex: 1,
            determinant: 2,
          ),
          braidData: [8.0, 1.0],
          createdAt: DateTime(2025, 1, 2),
          lastUpdated: DateTime(2025, 1, 2),
        );

        // Snapshots in reverse order
        final snapshot1 = KnotSnapshot(
          timestamp: DateTime(2025, 1, 3),
          knot: testKnot2,
          reason: 'Later snapshot',
        );

        final snapshot2 = KnotSnapshot(
          timestamp: DateTime(2025, 1, 2),
          knot: testKnot1,
          reason: 'Earlier snapshot',
        );

        when(() => mockStorageService.loadEvolutionHistory('agent-1'))
            .thenAnswer((_) async => [snapshot1, snapshot2]);

        final string = await service.createStringFromHistory('agent-1');

        expect(string, isNotNull);
        // First snapshot should be used as initial knot
        expect(string!.initialKnot.invariants.crossingNumber, equals(1));
        // Snapshots should be sorted
        expect(string.snapshots.length, equals(2));
        expect(string.snapshots.first.timestamp, equals(DateTime(2025, 1, 2)));
        expect(string.snapshots.last.timestamp, equals(DateTime(2025, 1, 3)));
      });
    });

    group('getKnotAtTime', () {
      test('should return knot at specific time using string interpolation', () async {
        // Test business logic: temporal retrieval via string
        
        final testKnot = PersonalityKnot(
          agentId: 'agent-1',
          invariants: KnotInvariants(
            jonesPolynomial: [1.0],
            alexanderPolynomial: [1.0],
            crossingNumber: 1,
            writhe: 0,
            signature: 0,
            bridgeNumber: 1,
            braidIndex: 1,
            determinant: 1,
          ),
          braidData: [8.0],
          createdAt: DateTime(2025, 1, 1),
          lastUpdated: DateTime(2025, 1, 1),
        );

        // Test: Empty history - uses current knot
        when(() => mockStorageService.loadEvolutionHistory('agent-1'))
            .thenAnswer((_) async => []);
        when(() => mockStorageService.loadKnot('agent-1'))
            .thenAnswer((_) async => testKnot);

        final knot = await service.getKnotAtTime('agent-1', DateTime(2025, 1, 1, 12));

        expect(knot, isNotNull);
        expect(knot!.agentId, equals('agent-1'));
        expect(knot.invariants.crossingNumber, equals(1));
      });

      test('should return null when string cannot be created', () async {
        // Test business logic: error handling
        
        when(() => mockStorageService.loadEvolutionHistory('agent-1'))
            .thenAnswer((_) async => []);
        when(() => mockStorageService.loadKnot('agent-1'))
            .thenAnswer((_) async => null);

        final knot = await service.getKnotAtTime('agent-1', DateTime(2025, 1, 1));

        expect(knot, isNull);
      });
    });

    group('getEvolutionTrajectory', () {
      test('should generate sequence of knots at regular intervals when history is empty', () async {
        // Test business logic: trajectory generation with empty history
        
        final testKnot = PersonalityKnot(
          agentId: 'agent-1',
          invariants: KnotInvariants(
            jonesPolynomial: [1.0],
            alexanderPolynomial: [1.0],
            crossingNumber: 1,
            writhe: 0,
            signature: 0,
            bridgeNumber: 1,
            braidIndex: 1,
            determinant: 1,
          ),
          braidData: [8.0],
          createdAt: DateTime(2025, 1, 1),
          lastUpdated: DateTime(2025, 1, 1),
        );

        // Test: Empty history - uses current knot for all times
        when(() => mockStorageService.loadEvolutionHistory('agent-1'))
            .thenAnswer((_) async => []);
        when(() => mockStorageService.loadKnot('agent-1'))
            .thenAnswer((_) async => testKnot);

        final trajectory = await service.getEvolutionTrajectory(
          agentId: 'agent-1',
          start: DateTime(2025, 1, 1),
          end: DateTime(2025, 1, 2),
          step: const Duration(hours: 1),
        );

        expect(trajectory, isNotEmpty);
        // Should return same knot for all times when no history (uses current knot as initial)
        expect(trajectory.every((k) => k.agentId == 'agent-1'), isTrue);
        expect(trajectory.length, greaterThan(1));
      });
    });
  });
}
