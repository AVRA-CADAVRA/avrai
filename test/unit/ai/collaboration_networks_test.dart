import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/ai/collaboration_networks.dart';
import 'package:spots/core/models/personality_profile.dart';

/// Collaboration Networks Tests
/// Tests AI agent collaboration and trust network building
/// OUR_GUTS.md: "Privacy-preserving AI collaboration networks"
void main() {
  group('CollaborationNetworks', () {
    late CollaborationNetworks networks;

    setUp(() {
      networks = CollaborationNetworks();
    });

    group('AI Agent Clustering', () {
      test('should cluster similar AIs without errors', () async {
        final profile = PersonalityProfile.initial('test-user');
        final personality = UserPersonality(
          userId: 'test-user',
          profile: profile,
        );
        
        final agents = await networks.clusterSimilarAIs(personality);
        
        expect(agents, isA<List<AIAgent>>());
      });

      test('should handle initial personality profile', () async {
        final profile = PersonalityProfile.initial('test-user');
        final personality = UserPersonality(
          userId: 'test-user',
          profile: profile,
        );
        
        final agents = await networks.clusterSimilarAIs(personality);
        expect(agents, isA<List<AIAgent>>());
      });
    });

    group('Trust Network Building', () {
      test('should build trust-based networks without errors', () async {
        final trustNetwork = await networks.buildTrustBasedNetworks();
        
        expect(trustNetwork, isA<TrustNetwork>());
        expect(trustNetwork.totalAgents, greaterThanOrEqualTo(0));
        expect(trustNetwork.averageTrustLevel, greaterThanOrEqualTo(0.0));
        expect(trustNetwork.averageTrustLevel, lessThanOrEqualTo(1.0));
      });
    });

    group('AI Reputation', () {
      test('should calculate AI reputation without errors', () async {
        const aiAgentId = 'test-agent-123';
        
        final reputation = await networks.calculateAIReputation(aiAgentId);
        
        expect(reputation, isA<ReputationSystem>());
        expect(reputation.agentId, equals(aiAgentId));
      });

      test('should handle unknown agent ID', () async {
        const aiAgentId = 'unknown-agent';
        
        final reputation = await networks.calculateAIReputation(aiAgentId);
        
        expect(reputation, isA<ReputationSystem>());
      });
    });
  });
}

