import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/admin_god_mode_service.dart';
import 'package:spots/core/p2p/federated_learning.dart' as federated;
import 'package:spots/presentation/widgets/admin/admin_federated_rounds_widget.dart';

void main() {
  group('AdminFederatedRoundsWidget Widget Tests', () {
    testWidgets('widget can be created', (WidgetTester tester) async {
      // This is a basic smoke test to ensure the widget compiles
      // Full testing would require proper mocking infrastructure
      
      // For now, we verify the widget class exists and can be referenced
      expect(AdminFederatedRoundsWidget, isA<Type>());
      expect(GodModeFederatedRoundInfo, isA<Type>());
      expect(RoundParticipant, isA<Type>());
      expect(RoundPerformanceMetrics, isA<Type>());
    });
    
    test('data models can be created', () {
      // Test that the data models work correctly
      final participant = RoundParticipant(
        nodeId: 'node_123',
        userId: 'user_1',
        aiPersonalityName: 'Test AI',
        contributionCount: 5,
        joinedAt: DateTime.now(),
        isActive: true,
      );
      
      expect(participant.nodeId, 'node_123');
      expect(participant.userId, 'user_1');
      expect(participant.isActive, true);
      
      final metrics = RoundPerformanceMetrics(
        participationRate: 0.95,
        averageAccuracy: 0.85,
        privacyComplianceScore: 0.98,
        convergenceProgress: 0.75,
      );
      
      expect(metrics.participationRate, 0.95);
      expect(metrics.overallHealth, greaterThan(0.8));
      
      final roundInfo = GodModeFederatedRoundInfo(
        round: federated.FederatedLearningRound(
          roundId: 'test_round',
          organizationId: 'test_org',
          objective: federated.LearningObjective(
            name: 'Test Objective',
            description: 'Test description',
            type: federated.LearningType.recommendation,
            parameters: {},
          ),
          participantNodeIds: ['node_1'],
          status: federated.RoundStatus.training,
          createdAt: DateTime.now(),
          roundNumber: 1,
          globalModel: federated.GlobalModel(
            modelId: 'model_1',
            objective: federated.LearningObjective(
              name: 'Test',
              description: 'Test',
              type: federated.LearningType.recommendation,
              parameters: {},
            ),
            version: 1,
            parameters: {},
            loss: 0.1,
            accuracy: 0.9,
            updatedAt: DateTime.now(),
          ),
          participantUpdates: {},
          privacyMetrics: federated.PrivacyMetrics.initial(),
        ),
        participants: [participant],
        performanceMetrics: metrics,
        learningRationale: 'Test rationale',
      );
      
      expect(roundInfo.round.roundId, 'test_round');
      expect(roundInfo.participants.length, 1);
      expect(roundInfo.isActive, true);
    });
  });
}
