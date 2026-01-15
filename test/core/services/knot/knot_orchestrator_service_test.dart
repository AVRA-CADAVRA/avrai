/// SPOTS KnotOrchestratorService Unit Tests
/// Date: January 6, 2026
/// Purpose: Test KnotOrchestratorService functionality for Phase 9 (AVRAI Core System Services)
///
/// Test Coverage:
/// - Individual Knot Operations: Generate, save, get or generate, handle evolution
/// - String Operations: Create user string, get knot at time
/// - Group/Fabric Operations: Create fabric, get or create fabric, create snapshot
/// - Worldsheet Operations: Create worldsheet for group
/// - Error Handling: Missing data, invalid inputs, service failures
///
/// Dependencies:
/// - PersonalityKnotService: Generate knots
/// - KnotStorageService: Store/load knots, fabrics, snapshots
/// - KnotEvolutionCoordinatorService: Handle profile evolution
/// - KnotEvolutionStringService: Create strings
/// - KnotFabricService: Generate fabrics
/// - KnotWorldsheetService: Create worldsheets
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
import 'package:avrai_knot/services/knot/knot_orchestrator_service.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_coordinator_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';
import 'package:avrai_knot/models/knot/fabric_snapshot.dart';
import 'package:avrai_knot/models/knot/knot_worldsheet.dart';
import 'package:avrai_knot/models/knot/fabric_invariants.dart';

class MockPersonalityKnotService extends Mock implements PersonalityKnotService {}
class MockKnotStorageService extends Mock implements KnotStorageService {}
class MockKnotEvolutionCoordinatorService extends Mock implements KnotEvolutionCoordinatorService {}
class MockKnotEvolutionStringService extends Mock implements KnotEvolutionStringService {}
class MockKnotFabricService extends Mock implements KnotFabricService {}
class MockKnotWorldsheetService extends Mock implements KnotWorldsheetService {}

void main() {
  group('KnotOrchestratorService', () {
    late KnotOrchestratorService service;
    late MockPersonalityKnotService mockKnotService;
    late MockKnotStorageService mockStorageService;
    late MockKnotEvolutionCoordinatorService mockCoordinator;
    late MockKnotEvolutionStringService mockStringService;
    late MockKnotFabricService mockFabricService;
    late MockKnotWorldsheetService mockWorldsheetService;

    setUp(() {
      mockKnotService = MockPersonalityKnotService();
      mockStorageService = MockKnotStorageService();
      mockCoordinator = MockKnotEvolutionCoordinatorService();
      mockStringService = MockKnotEvolutionStringService();
      mockFabricService = MockKnotFabricService();
      mockWorldsheetService = MockKnotWorldsheetService();
      
      service = KnotOrchestratorService(
        knotService: mockKnotService,
        storageService: mockStorageService,
        coordinator: mockCoordinator,
        stringService: mockStringService,
        fabricService: mockFabricService,
        worldsheetService: mockWorldsheetService,
      );
    });

    // Helper to create test profile
    PersonalityProfile createTestProfile(String agentId) {
      return PersonalityProfile.initial(agentId);
    }

    // Helper to create test knot
    PersonalityKnot createTestKnot(String agentId) {
      return PersonalityKnot(
        agentId: agentId,
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

    group('Individual Knot Operations', () {
      test('should generate and save knot, get or generate knot (load from storage or generate if missing), and handle profile evolution', () async {
        // Test business logic: knot generation and storage
        
        final profile = createTestProfile('agent-1');
        final testKnot = createTestKnot('agent-1');

        // Test: Generate and save knot
        when(() => mockKnotService.generateKnot(profile))
            .thenAnswer((_) async => testKnot);
        when(() => mockStorageService.saveKnot('agent-1', testKnot))
            .thenAnswer((_) async => Future.value());

        final generatedKnot = await service.generateAndSaveKnot(profile);

        expect(generatedKnot, equals(testKnot));
        verify(() => mockStorageService.saveKnot('agent-1', testKnot)).called(1);

        // Test: Get or generate knot - load from storage
        when(() => mockStorageService.loadKnot('agent-1'))
            .thenAnswer((_) async => testKnot);

        final loadedKnot = await service.getOrGenerateKnot(profile);

        expect(loadedKnot, equals(testKnot));
        verifyNever(() => mockKnotService.generateKnot(any()));

        // Test: Get or generate knot - generate if missing
        when(() => mockStorageService.loadKnot('agent-2'))
            .thenAnswer((_) async => null);
        when(() => mockKnotService.generateKnot(any()))
            .thenAnswer((_) async => testKnot);
        when(() => mockStorageService.saveKnot('agent-2', testKnot))
            .thenAnswer((_) async => Future.value());

        final profile2 = createTestProfile('agent-2');
        final generatedKnot2 = await service.getOrGenerateKnot(profile2);

        expect(generatedKnot2, equals(testKnot));
        verify(() => mockKnotService.generateKnot(any())).called(1);

        // Test: Handle profile evolution
        final evolvedProfile = createTestProfile('agent-1');
        when(() => mockCoordinator.handleProfileEvolution('user-1', evolvedProfile))
            .thenAnswer((_) async => Future.value());

        await service.handleProfileEvolution('user-1', evolvedProfile);

        verify(() => mockCoordinator.handleProfileEvolution('user-1', evolvedProfile)).called(1);
      });
    });

    group('String Operations', () {
      test('should create user string and get knot at specific time from string', () async {
        // Test business logic: string creation and temporal retrieval
        
        final testKnot = createTestKnot('agent-1');
        final testString = KnotString(
          initialKnot: testKnot,
          snapshots: <KnotSnapshot>[],
        );

        when(() => mockStringService.createStringFromHistory('agent-1'))
            .thenAnswer((_) async => testString);

        final string = await service.createUserString('agent-1');

        expect(string, isNotNull);
        expect(string!.initialKnot.agentId, equals('agent-1'));

        // Test: Get knot at time
        final knotAtTime = await service.getUserKnotAtTime('agent-1', DateTime(2025, 1, 1, 12));

        expect(knotAtTime, isNotNull);
        expect(knotAtTime!.agentId, equals('agent-1'));
      });

      test('should return null when string cannot be created', () async {
        // Test business logic: error handling
        
        when(() => mockStringService.createStringFromHistory('agent-1'))
            .thenAnswer((_) async => null);

        final string = await service.createUserString('agent-1');
        final knotAtTime = await service.getUserKnotAtTime('agent-1', DateTime(2025, 1, 1));

        expect(string, isNull);
        expect(knotAtTime, isNull);
      });
    });

    group('Group/Fabric Operations', () {
      test('should create fabric for group, get or create fabric (load from storage or create if missing), and create fabric snapshot', () async {
        // Test business logic: fabric creation and management
        
        final testKnot1 = createTestKnot('agent-1');
        final testKnot2 = createTestKnot('agent-2');
        final testFabric = createTestFabric([testKnot1, testKnot2]);

        // Test: Create fabric for group
        when(() => mockStorageService.loadKnot('agent-1'))
            .thenAnswer((_) async => testKnot1);
        when(() => mockStorageService.loadKnot('agent-2'))
            .thenAnswer((_) async => testKnot2);
        when(() => mockFabricService.generateMultiStrandBraidFabric(
              userKnots: any(named: 'userKnots'),
              compatibilityScores: any(named: 'compatibilityScores'),
              relationships: any(named: 'relationships'),
            )).thenAnswer((_) async => testFabric);
        when(() => mockStorageService.saveFabric('group-1', testFabric))
            .thenAnswer((_) async => Future.value());

        final fabric = await service.createFabricForGroup(
          groupId: 'group-1',
          userIds: ['agent-1', 'agent-2'],
        );

        expect(fabric, equals(testFabric));
        verify(() => mockStorageService.saveFabric('group-1', testFabric)).called(1);

        // Test: Get or create fabric - load from storage
        when(() => mockStorageService.loadFabric('group-1'))
            .thenAnswer((_) async => testFabric);

        final loadedFabric = await service.getOrCreateFabricForGroup(
          groupId: 'group-1',
          userIds: ['agent-1', 'agent-2'],
        );

        expect(loadedFabric, equals(testFabric));
        verifyNever(() => mockFabricService.generateMultiStrandBraidFabric(
              userKnots: any(named: 'userKnots'),
            ));

        // Test: Get or create fabric - create if missing
        when(() => mockStorageService.loadFabric('group-2'))
            .thenAnswer((_) async => null);
        when(() => mockStorageService.loadKnot('agent-1'))
            .thenAnswer((_) async => testKnot1);
        when(() => mockStorageService.loadKnot('agent-2'))
            .thenAnswer((_) async => testKnot2);
        when(() => mockFabricService.generateMultiStrandBraidFabric(
              userKnots: any(named: 'userKnots'),
            )).thenAnswer((_) async => testFabric);
        when(() => mockStorageService.saveFabric('group-2', testFabric))
            .thenAnswer((_) async => Future.value());

        final createdFabric = await service.getOrCreateFabricForGroup(
          groupId: 'group-2',
          userIds: ['agent-1', 'agent-2'],
        );

        expect(createdFabric, equals(testFabric));
        verify(() => mockFabricService.generateMultiStrandBraidFabric(
              userKnots: any(named: 'userKnots'),
            )).called(1);

        // Test: Create fabric snapshot
        when(() => mockStorageService.loadFabric('group-1'))
            .thenAnswer((_) async => testFabric);
        when(() => mockStorageService.saveFabricSnapshot('group-1', any()))
            .thenAnswer((_) async => Future.value());

        await service.createFabricSnapshot(
          groupId: 'group-1',
          reason: 'Test snapshot',
        );

        verify(() => mockStorageService.saveFabricSnapshot('group-1', any())).called(1);
      });

      test('should throw error when creating fabric with no knots found', () async {
        // Test business logic: error handling
        
        when(() => mockStorageService.loadKnot('agent-1'))
            .thenAnswer((_) async => null);
        when(() => mockStorageService.loadKnot('agent-2'))
            .thenAnswer((_) async => null);

        expect(
          () => service.createFabricForGroup(
            groupId: 'group-1',
            userIds: ['agent-1', 'agent-2'],
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Worldsheet Operations', () {
      test('should create worldsheet for group', () async {
        // Test business logic: worldsheet creation
        
        final testWorldsheet = KnotWorldsheet(
          groupId: 'group-1',
          initialFabric: createTestFabric([createTestKnot('agent-1')]),
          snapshots: <FabricSnapshot>[],
          userStrings: {},
          createdAt: DateTime(2025, 1, 1),
          lastUpdated: DateTime(2025, 1, 1),
        );

        when(() => mockWorldsheetService.createWorldsheet(
              groupId: 'group-1',
              userIds: ['agent-1'],
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime'),
            )).thenAnswer((_) async => testWorldsheet);

        final worldsheet = await service.createWorldsheetForGroup(
          groupId: 'group-1',
          userIds: ['agent-1'],
        );

        expect(worldsheet, equals(testWorldsheet));
        verify(() => mockWorldsheetService.createWorldsheet(
              groupId: 'group-1',
              userIds: ['agent-1'],
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime'),
            )).called(1);
      });
    });
  });
}
