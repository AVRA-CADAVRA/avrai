/// SPOTS KnotWorldsheetService Unit Tests
/// Date: January 6, 2026
/// Purpose: Test KnotWorldsheetService functionality for Phase 9 (AVRAI Core System Services)
///
/// Test Coverage:
/// - Worldsheet Creation: Create 2D worldsheet from group strings and fabric snapshots
/// - Temporal Interpolation: Get fabric at any time point (interpolation between snapshots)
/// - Fabric Integration: Load or generate fabric on-the-fly if missing
/// - String Integration: Load user strings for group members
/// - Cross-Section: Get all users at specific time
/// - Error Handling: Missing strings, missing fabrics, invalid inputs
///
/// Dependencies:
/// - KnotStorageService: Load knots, fabrics, fabric snapshots
/// - KnotEvolutionStringService: Create strings from history
/// - KnotFabricService: Generate fabrics on-the-fly
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
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';
import 'package:avrai_knot/models/knot/fabric_snapshot.dart';
import 'package:avrai_knot/models/knot/fabric_invariants.dart';

class MockKnotStorageService extends Mock implements KnotStorageService {}
class MockKnotEvolutionStringService extends Mock implements KnotEvolutionStringService {}
class MockKnotFabricService extends Mock implements KnotFabricService {}

void main() {
  group('KnotWorldsheetService', () {
    late KnotWorldsheetService service;
    late MockKnotStorageService mockStorageService;
    late MockKnotEvolutionStringService mockStringService;
    late MockKnotFabricService mockFabricService;

    setUp(() {
      mockStorageService = MockKnotStorageService();
      mockStringService = MockKnotEvolutionStringService();
      mockFabricService = MockKnotFabricService();
      
      service = KnotWorldsheetService(
        storageService: mockStorageService,
        stringService: mockStringService,
        fabricService: mockFabricService,
      );
    });

    // Helper to create test knots
    PersonalityKnot createTestKnot(String agentId, int crossingNumber) {
      return PersonalityKnot(
        agentId: agentId,
        invariants: KnotInvariants(
          jonesPolynomial: [crossingNumber.toDouble()],
          alexanderPolynomial: [crossingNumber.toDouble()],
          crossingNumber: crossingNumber,
          writhe: 0,
          signature: 0,
          bridgeNumber: 1,
          braidIndex: 1,
          determinant: crossingNumber,
        ),
        braidData: [8.0],
        createdAt: DateTime(2025, 1, 1),
        lastUpdated: DateTime(2025, 1, 1),
      );
    }

    // Helper to create test string
    KnotString createTestString(PersonalityKnot initialKnot) {
      return KnotString(
        initialKnot: initialKnot,
        snapshots: <KnotSnapshot>[],
      );
    }

    // Helper to create test fabric
    KnotFabric createTestFabric(List<PersonalityKnot> userKnots) {
      return KnotFabric(
        fabricId: 'fabric-1',
        userKnots: userKnots,
        braid: MultiStrandBraid(
          strandCount: userKnots.length,
          braidData: [userKnots.length.toDouble()],
          userToStrandIndex: Map.fromEntries(
            userKnots.asMap().entries.map((e) => MapEntry(e.value.agentId, e.key)),
          ),
        ),
        invariants: FabricInvariants(
          jonesPolynomial: Polynomial([1.0]),
          alexanderPolynomial: Polynomial([1.0]),
          crossingNumber: userKnots.length,
          density: 1.0,
          stability: 0.7,
        ),
        createdAt: DateTime(2025, 1, 1),
      );
    }

    group('createWorldsheet', () {
      test('should create worldsheet from group strings and fabric snapshots, return null when no strings found, and generate fabric on-the-fly if missing', () async {
        // Test business logic: worldsheet creation with string and fabric integration
        
        final testKnot1 = createTestKnot('agent-1', 1);
        final testKnot2 = createTestKnot('agent-2', 2);
        final testString1 = createTestString(testKnot1);
        final testString2 = createTestString(testKnot2);
        final testFabric = createTestFabric([testKnot1, testKnot2]);

        // Mock: Load strings for users
        when(() => mockStringService.createStringFromHistory('agent-1'))
            .thenAnswer((_) async => testString1);
        when(() => mockStringService.createStringFromHistory('agent-2'))
            .thenAnswer((_) async => testString2);

        // Mock: Load fabric (exists)
        when(() => mockStorageService.loadFabric('group-1'))
            .thenAnswer((_) async => testFabric);

        // Mock: Load fabric snapshots
        when(() => mockStorageService.loadFabricSnapshots(
              'group-1',
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime'),
            )).thenAnswer((_) async => <FabricSnapshot>[]);

        // Act
        final worldsheet = await service.createWorldsheet(
          groupId: 'group-1',
          userIds: ['agent-1', 'agent-2'],
        );

        // Assert - Worldsheet created successfully
        expect(worldsheet, isNotNull);
        expect(worldsheet!.groupId, equals('group-1'));
        expect(worldsheet.userStrings.length, equals(2));
        expect(worldsheet.userStrings.containsKey('agent-1'), isTrue);
        expect(worldsheet.userStrings.containsKey('agent-2'), isTrue);
        expect(worldsheet.initialFabric.fabricId, equals('fabric-1'));

        // Test: No strings found
        when(() => mockStringService.createStringFromHistory('agent-1'))
            .thenAnswer((_) async => null);
        when(() => mockStringService.createStringFromHistory('agent-2'))
            .thenAnswer((_) async => null);

        final worldsheetNoStrings = await service.createWorldsheet(
          groupId: 'group-1',
          userIds: ['agent-1', 'agent-2'],
        );

        expect(worldsheetNoStrings, isNull);

        // Test: Generate fabric on-the-fly if missing
        when(() => mockStringService.createStringFromHistory('agent-1'))
            .thenAnswer((_) async => testString1);
        when(() => mockStringService.createStringFromHistory('agent-2'))
            .thenAnswer((_) async => testString2);
        when(() => mockStorageService.loadFabric('group-2'))
            .thenAnswer((_) async => null);
        when(() => mockStorageService.loadKnot('agent-1'))
            .thenAnswer((_) async => testKnot1);
        when(() => mockStorageService.loadKnot('agent-2'))
            .thenAnswer((_) async => testKnot2);
        when(() => mockFabricService.generateMultiStrandBraidFabric(
              userKnots: any(named: 'userKnots'),
              compatibilityScores: any(named: 'compatibilityScores'),
              relationships: any(named: 'relationships'),
            )).thenAnswer((_) async => testFabric);

        final worldsheetGenerated = await service.createWorldsheet(
          groupId: 'group-2',
          userIds: ['agent-1', 'agent-2'],
        );

        expect(worldsheetGenerated, isNotNull);
        verify(() => mockFabricService.generateMultiStrandBraidFabric(
              userKnots: any(named: 'userKnots'),
            )).called(1);
      });

      test('should handle time filtering and return null when no knots found for fabric generation', () async {
        // Test business logic: time filtering and error handling
        
        final testKnot = createTestKnot('agent-1', 1);
        final testString = createTestString(testKnot);
        final testFabric = createTestFabric([testKnot]);

        final snapshot1 = FabricSnapshot(
          fabric: testFabric,
          timestamp: DateTime(2025, 1, 2),
        );

        final snapshot2 = FabricSnapshot(
          fabric: testFabric,
          timestamp: DateTime(2025, 1, 3),
        );

        when(() => mockStringService.createStringFromHistory('agent-1'))
            .thenAnswer((_) async => testString);
        when(() => mockStorageService.loadFabric('group-1'))
            .thenAnswer((_) async => testFabric);
        when(() => mockStorageService.loadFabricSnapshots(
              'group-1',
              startTime: DateTime(2025, 1, 2),
              endTime: DateTime(2025, 1, 3),
            )).thenAnswer((_) async => [snapshot1, snapshot2]);

        final worldsheet = await service.createWorldsheet(
          groupId: 'group-1',
          userIds: ['agent-1'],
          startTime: DateTime(2025, 1, 2),
          endTime: DateTime(2025, 1, 3),
        );

        expect(worldsheet, isNotNull);
        expect(worldsheet!.snapshots.length, equals(2));

        // Test: No knots found for fabric generation
        when(() => mockStorageService.loadFabric('group-3'))
            .thenAnswer((_) async => null);
        when(() => mockStorageService.loadKnot('agent-1'))
            .thenAnswer((_) async => null);

        final worldsheetNoKnots = await service.createWorldsheet(
          groupId: 'group-3',
          userIds: ['agent-1'],
        );

        expect(worldsheetNoKnots, isNull);
      });
    });

    group('getFabricAtTime', () {
      test('should return fabric at specific time using worldsheet interpolation', () async {
        // Test business logic: temporal fabric retrieval
        
        final testKnot = createTestKnot('agent-1', 1);
        final testString = createTestString(testKnot);
        final testFabric = createTestFabric([testKnot]);

        when(() => mockStringService.createStringFromHistory('agent-1'))
            .thenAnswer((_) async => testString);
        when(() => mockStorageService.loadFabric('group-1'))
            .thenAnswer((_) async => testFabric);
        when(() => mockStorageService.loadFabricSnapshots(
              'group-1',
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime'),
            )).thenAnswer((_) async => <FabricSnapshot>[]);

        final fabric = await service.getFabricAtTime(
          groupId: 'group-1',
          time: DateTime(2025, 1, 1, 12),
        );

        expect(fabric, isNotNull);
        expect(fabric!.fabricId, equals('fabric-1'));
      });
    });

    group('getCrossSectionAtTime', () {
      test('should return all user knots at specific time', () async {
        // Test business logic: cross-section retrieval
        
        final testKnot1 = createTestKnot('agent-1', 1);
        final testKnot2 = createTestKnot('agent-2', 2);
        final testString1 = createTestString(testKnot1);
        final testString2 = createTestString(testKnot2);
        final testFabric = createTestFabric([testKnot1, testKnot2]);

        when(() => mockStringService.createStringFromHistory('agent-1'))
            .thenAnswer((_) async => testString1);
        when(() => mockStringService.createStringFromHistory('agent-2'))
            .thenAnswer((_) async => testString2);
        when(() => mockStorageService.loadFabric('group-1'))
            .thenAnswer((_) async => testFabric);
        when(() => mockStorageService.loadFabricSnapshots(
              'group-1',
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime'),
            )).thenAnswer((_) async => <FabricSnapshot>[]);

        final crossSection = await service.getCrossSectionAtTime(
          groupId: 'group-1',
          time: DateTime(2025, 1, 1, 12),
        );

        expect(crossSection, isNotEmpty);
        expect(crossSection.length, equals(2));
        expect(crossSection.any((k) => k.agentId == 'agent-1'), isTrue);
        expect(crossSection.any((k) => k.agentId == 'agent-2'), isTrue);
      });
    });

    group('getUserString', () {
      test('should return user string from worldsheet', () async {
        // Test business logic: user string retrieval
        
        final testKnot = createTestKnot('agent-1', 1);
        final testString = createTestString(testKnot);
        final testFabric = createTestFabric([testKnot]);

        when(() => mockStringService.createStringFromHistory('agent-1'))
            .thenAnswer((_) async => testString);
        when(() => mockStorageService.loadFabric('group-1'))
            .thenAnswer((_) async => testFabric);
        when(() => mockStorageService.loadFabricSnapshots(
              'group-1',
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime'),
            )).thenAnswer((_) async => <FabricSnapshot>[]);

        final userString = await service.getUserString(
          groupId: 'group-1',
          userId: 'agent-1',
        );

        expect(userString, isNotNull);
        expect(userString!.initialKnot.agentId, equals('agent-1'));
      });
    });
  });
}
