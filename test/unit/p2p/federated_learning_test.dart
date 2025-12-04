import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/p2p/federated_learning.dart';
import '../../helpers/platform_channel_helper.dart';
import '../../mocks/mock_storage_service.dart';

void main() {
  group('FederatedLearningSystem', () {
    late FederatedLearningSystem system;

    setUp(() {
      // Use mock storage for testing
      final mockStorage = MockGetStorage.getInstance();
      if (mockStorage != null) {
        system = FederatedLearningSystem(storage: mockStorage);
      } else {
        // Fallback if mock storage fails (shouldn't happen)
        system = FederatedLearningSystem();
      }
    });

    test('initializeLearningRound creates privacy-preserving round', () async {
      // OUR_GUTS.md: "Local model training with global model aggregation"
      final objective = LearningObjective(
        name: 'spot_recommendation',
        description: 'Learn community spot preferences',
        type: LearningType.recommendation,
        parameters: {'learning_rate': 0.01, 'epochs': 10},
      );

      final participants = ['node1', 'node2', 'node3', 'node4'];

      final round = await system.initializeLearningRound(
        'test-org',
        objective,
        participants,
      );

      expect(round.organizationId, equals('test-org'));
      expect(round.participantNodeIds.length, equals(4));
      expect(round.status, equals(RoundStatus.training));
      expect(round.privacyMetrics.differentialPrivacyEnabled, isTrue);
    });

    test('trainLocalModel preserves privacy', () async {
      // OUR_GUTS.md: "Local model training without exposing user data"
      final objective = LearningObjective(
        name: 'preference_learning',
        description: 'Learn user preferences privately',
        type: LearningType.classification,
        parameters: {'privacy_budget': 1.0},
      );

      final round = await system.initializeLearningRound(
        'privacy-org',
        objective,
        ['node1', 'node2', 'node3'],
      );

      final trainingData = LocalTrainingData(
        sampleCount: 100,
        features: {
          'category_scores': [0.8, 0.6, 0.4],
          'time_preferences': [0.2, 0.7, 0.9]
        },
        containsPersonalIdentifiers: false,
      );

      final modelUpdate =
          await system.trainLocalModel('node1', round, trainingData);

      expect(modelUpdate.privacyCompliant, isTrue);
      expect(modelUpdate.trainingMetrics.privacyBudgetUsed, greaterThan(0.0));
      expect(modelUpdate.gradients, isNotEmpty);
    });

    test('rejects training data with personal identifiers', () async {
      // OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
      final objective = LearningObjective(
        name: 'test_learning',
        description: 'Test learning objective',
        type: LearningType.classification,
        parameters: {},
      );

      final round = await system.initializeLearningRound(
        'test-org',
        objective,
        ['node1', 'node2', 'node3'],
      );

      final badTrainingData = LocalTrainingData(
        sampleCount: 50,
        features: {
          'user_id': 'user123',
          'preferences': [0.5, 0.8]
        },
        containsPersonalIdentifiers: true, // This should trigger rejection
      );

      expect(
        () => system.trainLocalModel('node1', round, badTrainingData),
        throwsA(isA<FederatedLearningException>()),
      );
    });

    test('aggregateModelUpdates maintains privacy', () async {
      // OUR_GUTS.md: "Global model aggregation with privacy protection"
      final objective = LearningObjective(
        name: 'aggregation_test',
        description: 'Test aggregation',
        type: LearningType.recommendation,
        parameters: {},
      );

      final round = await system.initializeLearningRound(
        'agg-org',
        objective,
        ['node1', 'node2', 'node3'],
      );

      final localUpdates = [
        LocalModelUpdate(
          nodeId: 'node1',
          roundId: round.roundId,
          gradients: {
            'weights': [0.1, 0.2, 0.3]
          },
          trainingMetrics: TrainingMetrics(
            samplesUsed: 100,
            trainingLoss: 0.5,
            accuracy: 0.8,
            privacyBudgetUsed: 0.5,
          ),
          timestamp: DateTime.now(),
          privacyCompliant: true,
        ),
        LocalModelUpdate(
          nodeId: 'node2',
          roundId: round.roundId,
          gradients: {
            'weights': [0.2, 0.1, 0.4]
          },
          trainingMetrics: TrainingMetrics(
            samplesUsed: 80,
            trainingLoss: 0.6,
            accuracy: 0.7,
            privacyBudgetUsed: 0.6,
          ),
          timestamp: DateTime.now(),
          privacyCompliant: true,
        ),
      ];

      final globalUpdate =
          await system.aggregateModelUpdates(round, localUpdates);

      expect(globalUpdate.privacyPreserved, isTrue);
      expect(globalUpdate.participantCount, equals(2));
      expect(globalUpdate.convergenceMetrics.convergenceScore,
          greaterThanOrEqualTo(0.0));
    });
  });
}
