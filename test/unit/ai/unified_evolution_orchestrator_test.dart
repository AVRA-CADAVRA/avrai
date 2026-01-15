import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/unified_evolution_orchestrator.dart';
import 'package:avrai/core/ai/personality_learning.dart'
    show PersonalityLearning, UserAction, UserActionType;
import 'package:avrai/core/services/agent_id_service.dart';

/// Unified Evolution Orchestrator Tests
/// Tests the unified orchestrator that coordinates all evolution-related activities
void main() {
  group('UnifiedEvolutionOrchestrator', () {
    late UnifiedEvolutionOrchestrator orchestrator;
    late PersonalityLearning personalityLearning;
    late AgentIdService agentIdService;

    setUp(() {
      personalityLearning = PersonalityLearning();
      agentIdService = AgentIdService();
      orchestrator = UnifiedEvolutionOrchestrator(
        personalityLearning: personalityLearning,
        agentIdService: agentIdService,
        knotEvolutionCoordinator: null,
        quantumMatchingLearning: null,
        continuousLearningOrchestrator: null,
        ai2aiLearning: null,
      );
    });

    tearDown(() async {
      // Clean up: stop orchestration if it's running
      try {
        await orchestrator.stopEvolutionOrchestration();
      } catch (e) {
        // Ignore errors during cleanup
      }
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        await orchestrator.initialize();
        expect(orchestrator.isInitialized, isTrue);
      });

      test('should not be initialized before initialize()', () {
        expect(orchestrator.isInitialized, isFalse);
      });

      test('should be initialized after initialize()', () async {
        await orchestrator.initialize();
        expect(orchestrator.isInitialized, isTrue);
      });

      test('should handle multiple initialize() calls gracefully', () async {
        await orchestrator.initialize();
        expect(orchestrator.isInitialized, isTrue);
        await orchestrator.initialize(); // Should not throw
        expect(orchestrator.isInitialized, isTrue);
      });
    });

    group('Evolution Orchestration', () {
      test('should start evolution orchestration after initialization',
          () async {
        await orchestrator.initialize();
        await orchestrator.startEvolutionOrchestration();
        expect(orchestrator.isOrchestrating, isTrue);
      });

      test('should not be orchestrating before start', () async {
        await orchestrator.initialize();
        expect(orchestrator.isOrchestrating, isFalse);
      });

      test(
          'should handle multiple startEvolutionOrchestration() calls gracefully',
          () async {
        await orchestrator.initialize();
        await orchestrator.startEvolutionOrchestration();
        expect(orchestrator.isOrchestrating, isTrue);
        await orchestrator.startEvolutionOrchestration(); // Should not throw
        expect(orchestrator.isOrchestrating, isTrue);
      });

      test('should stop evolution orchestration', () async {
        await orchestrator.initialize();
        await orchestrator.startEvolutionOrchestration();
        expect(orchestrator.isOrchestrating, isTrue);
        await orchestrator.stopEvolutionOrchestration();
        expect(orchestrator.isOrchestrating, isFalse);
      });

      test('should handle stopEvolutionOrchestration() when not running',
          () async {
        await orchestrator.initialize();
        await expectLater(
          orchestrator.stopEvolutionOrchestration(),
          completes,
        );
      });
    });

    group('Evolution Metrics', () {
      test('should return null for non-existent agent metrics', () {
        final metrics = orchestrator.getEvolutionMetrics('non-existent-agent');
        expect(metrics, isNull);
      });

      test('should return empty evolution history initially', () {
        final history = orchestrator.getEvolutionHistory();
        expect(history, isEmpty);
      });

      test('should return limited evolution history when limit specified', () {
        final history = orchestrator.getEvolutionHistory(limit: 10);
        expect(history, isEmpty);
      });
    });

    group('Personality Evolution Handling', () {
      test('should handle personality evolution without errors', () async {
        await orchestrator.initialize();

        // Trigger evolution (this will call the callback)
        await personalityLearning.evolveFromUserAction(
          'test-user',
          UserAction(
            type: UserActionType.spotVisit,
            timestamp: DateTime.now(),
            metadata: {},
          ),
        );

        // Should complete without errors
        expect(orchestrator.isInitialized, isTrue);
      });
    });
  });
}
