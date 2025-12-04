import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/ai/ai2ai_learning.dart';
import 'package:spots/core/ai/personality_learning.dart';
import 'package:shared_preferences/shared_preferences.dart' as sp;
import 'package:spots/core/services/storage_service.dart';

void main() {
  group('AI2AI Learning Methods Tests', () {
    late AI2AIChatAnalyzer analyzer;
    late PersonalityLearning personalityLearning;
    
    setUp(() async {
      sp.SharedPreferences.setMockInitialValues({});
      final sharedPrefs = await sp.SharedPreferences.getInstance();
      // PersonalityLearning uses SharedPreferences from storage_service (typedef to SharedPreferencesCompat)
      // AI2AIChatAnalyzer uses SharedPreferences from shared_preferences package
      // Use the compat version for PersonalityLearning
      final compatPrefs = await SharedPreferencesCompat.getInstance();
      personalityLearning = PersonalityLearning.withPrefs(compatPrefs);
      analyzer = AI2AIChatAnalyzer(
        prefs: sharedPrefs,
        personalityLearning: personalityLearning,
      );
    });
    
    group('Data Model Tests', () {
      test('AI2AIChatEvent can be created', () {
        final event = AI2AIChatEvent(
          eventId: 'test_event_1',
          participants: ['user_1', 'user_2'],
          messages: [
            ChatMessage(
              senderId: 'user_1',
              content: 'Hello, let\'s explore adventure spots!',
              timestamp: DateTime.now(),
              context: {},
            ),
          ],
          messageType: ChatMessageType.personalitySharing,
          timestamp: DateTime.now(),
          duration: const Duration(minutes: 5),
          metadata: {},
        );
        
        expect(event.eventId, 'test_event_1');
        expect(event.participants.length, 2);
        expect(event.messages.length, 1);
      });
      
      test('SharedInsight can be created', () {
        final insight = SharedInsight(
          category: 'dimension_evolution',
          dimension: 'adventure',
          value: 0.8,
          description: 'High adventure preference',
          reliability: 0.9,
          timestamp: DateTime.now(),
        );
        
        expect(insight.dimension, 'adventure');
        expect(insight.value, 0.8);
        expect(insight.reliability, 0.9);
      });
      
      test('EmergingPattern can be created', () {
        final pattern = EmergingPattern('rapid_exchange', 0.75);
        
        expect(pattern.pattern, 'rapid_exchange');
        expect(pattern.strength, 0.75);
      });
      
      test('CommunityTrend can be created', () {
        final trend = CommunityTrend('increasing_conversation_depth', 1.0);
        
        expect(trend.trend, 'increasing_conversation_depth');
        expect(trend.direction, 1.0);
      });
      
      test('CollectiveKnowledge can be created', () {
        final knowledge = CollectiveKnowledge(
          communityId: 'test_community',
          aggregatedInsights: [],
          emergingPatterns: [],
          consensusKnowledge: {},
          communityTrends: [],
          reliabilityScores: {},
          contributingChats: 5,
          knowledgeDepth: 0.8,
          lastUpdated: DateTime.now(),
        );
        
        expect(knowledge.contributingChats, 5);
        expect(knowledge.aggregatedInsights, isEmpty);
      });
      
      test('CrossPersonalityLearningPattern can be created', () {
        final pattern = CrossPersonalityLearningPattern(
          patternType: 'interaction_frequency',
          characteristics: {
            'frequency_score': 0.85,
            'total_interactions': 10,
          },
          strength: 0.85,
          confidence: 0.8,
          identified: DateTime.now(),
        );
        
        expect(pattern.patternType, 'interaction_frequency');
        expect(pattern.strength, 0.85);
        expect(pattern.confidence, 0.8);
        expect(pattern.characteristics['frequency_score'], 0.85);
      });
      
      test('AI2AILearningRecommendations can be created', () {
        final recommendations = AI2AILearningRecommendations(
          userId: 'test_user',
          optimalPartners: [],
          learningTopics: [],
          developmentAreas: [],
          interactionStrategy: InteractionStrategy.balanced(),
          expectedOutcomes: [],
          confidenceScore: 0.85,
          generatedAt: DateTime.now(),
        );
        
        expect(recommendations.userId, 'test_user');
        expect(recommendations.confidenceScore, 0.85);
      });
      
      test('LearningEffectivenessMetrics can be created', () {
        final metrics = LearningEffectivenessMetrics(
          userId: 'test_user',
          timeWindow: const Duration(days: 30),
          evolutionRate: 0.15,
          knowledgeAcquisition: 0.8,
          insightQuality: 0.9,
          trustNetworkGrowth: 0.7,
          collectiveContribution: 0.6,
          totalInteractions: 10,
          overallEffectiveness: 0.75,
          measuredAt: DateTime.now(),
        );
        
        expect(metrics.userId, 'test_user');
        expect(metrics.overallEffectiveness, 0.75);
        expect(metrics.evolutionRate, 0.15);
      });
    });
    
    group('Chat Event Processing', () {
      test('Multiple chat events with different patterns', () {
        // Create events representing different conversation styles
        final rapidExchange = AI2AIChatEvent(
          eventId: 'rapid_1',
          participants: ['user_1', 'user_2'],
          messages: List.generate(8, (i) => ChatMessage(
            senderId: i % 2 == 0 ? 'user_1' : 'user_2',
            content: 'Quick message $i',
            timestamp: DateTime.now().subtract(Duration(minutes: 10 - i)),
            context: {},
          )),
          messageType: ChatMessageType.personalitySharing,
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          duration: const Duration(minutes: 8),
          metadata: {},
        );
        
        final deepConversation = AI2AIChatEvent(
          eventId: 'deep_1',
          participants: ['user_1', 'user_3'],
          messages: List.generate(15, (i) => ChatMessage(
            senderId: i % 2 == 0 ? 'user_1' : 'user_3',
            content: 'Deep thought about adventure and exploration $i',
            timestamp: DateTime.now().subtract(Duration(minutes: 30 - i * 2)),
            context: {},
          )),
          messageType: ChatMessageType.experienceSharing,
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          duration: const Duration(minutes: 30),
          metadata: {},
        );
        
        final groupInteraction = AI2AIChatEvent(
          eventId: 'group_1',
          participants: ['user_1', 'user_2', 'user_3', 'user_4'],
          messages: List.generate(12, (i) => ChatMessage(
            senderId: 'user_${(i % 4) + 1}',
            content: 'Group discussion message $i',
            timestamp: DateTime.now().subtract(Duration(minutes: 20 - i)),
            context: {},
          )),
          messageType: ChatMessageType.insightExchange,
          timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
          duration: const Duration(minutes: 20),
          metadata: {},
        );
        
        expect(rapidExchange.messages.length, 8);
        expect(rapidExchange.duration.inMinutes, 8);
        
        expect(deepConversation.messages.length, 15);
        expect(deepConversation.participants.length, 2);
        
        expect(groupInteraction.participants.length, 4);
        expect(groupInteraction.messages.length, 12);
      });
      
      test('Chat events with keyword-based insights', () {
        final adventureChat = AI2AIChatEvent(
          eventId: 'adventure_1',
          participants: ['user_1', 'user_2'],
          messages: [
            ChatMessage(
              senderId: 'user_1',
              content: 'I love adventure and exploring new places!',
              timestamp: DateTime.now(),
              context: {},
            ),
            ChatMessage(
              senderId: 'user_2',
              content: 'Me too! Let\'s go on an adventure together.',
              timestamp: DateTime.now(),
              context: {},
            ),
          ],
          messageType: ChatMessageType.personalitySharing,
          timestamp: DateTime.now(),
          duration: const Duration(minutes: 5),
          metadata: {},
        );
        
        final socialChat = AI2AIChatEvent(
          eventId: 'social_1',
          participants: ['user_1', 'user_3'],
          messages: [
            ChatMessage(
              senderId: 'user_1',
              content: 'I enjoy social gatherings and meeting new people.',
              timestamp: DateTime.now(),
              context: {},
            ),
            ChatMessage(
              senderId: 'user_3',
              content: 'Social events are great for networking!',
              timestamp: DateTime.now(),
              context: {},
            ),
          ],
          messageType: ChatMessageType.experienceSharing,
          timestamp: DateTime.now(),
          duration: const Duration(minutes: 5),
          metadata: {},
        );
        
        // Verify keyword presence
        expect(adventureChat.messages[0].content.toLowerCase(), contains('adventure'));
        expect(socialChat.messages[0].content.toLowerCase(), contains('social'));
      });
    });
    
    group('Pattern Detection Logic', () {
      test('Interaction frequency pattern detection', () {
        final chats = List.generate(5, (i) => AI2AIChatEvent(
          eventId: 'chat_$i',
          participants: ['user_1', 'user_2'],
          messages: [
            ChatMessage(
              senderId: 'user_1',
              content: 'Message $i',
              timestamp: DateTime.now().subtract(Duration(days: i)),
              context: {},
            ),
          ],
          messageType: ChatMessageType.personalitySharing,
          timestamp: DateTime.now().subtract(Duration(days: i)),
          duration: const Duration(minutes: 5),
          metadata: {},
        ));
        
        // Verify chat intervals
        expect(chats.length, 5);
        expect(chats.first.timestamp.isAfter(chats.last.timestamp), true);
      });
      
      test('Trust building pattern - repeated interactions', () {
        final participantCounts = <String, int>{};
        
        // Simulate repeated interactions
        final interactions = [
          ['user_1', 'user_2'],
          ['user_1', 'user_2'],
          ['user_1', 'user_3'],
          ['user_1', 'user_2'],
          ['user_1', 'user_4'],
        ];
        
        for (final participants in interactions) {
          for (final participant in participants) {
            if (participant != 'user_1') {
              participantCounts[participant] = (participantCounts[participant] ?? 0) + 1;
            }
          }
        }
        
        final repeatedConnections = participantCounts.values.where((c) => c >= 2).length;
        final trustScore = repeatedConnections / participantCounts.length;
        
        expect(participantCounts['user_2'], 3); // Repeated 3 times
        expect(participantCounts['user_3'], 1);
        expect(participantCounts['user_4'], 1);
        expect(repeatedConnections, 1); // Only user_2 has >= 2 interactions
        expect(trustScore, greaterThan(0.0));
      });
      
      test('Learning acceleration pattern detection', () {
        // Early period learning
        final earlyLearning = 50;
        final earlyTime = 10; // days
        final earlyRate = earlyLearning / earlyTime;
        
        // Late period learning (accelerated)
        final lateLearning = 100;
        final lateTime = 10; // days
        final lateRate = lateLearning / lateTime;
        
        final acceleration = (lateRate / earlyRate - 1.0) / 2.0;
        
        expect(lateRate, greaterThan(earlyRate));
        expect(acceleration, greaterThan(0.0));
      });
    });
    
    group('Collective Knowledge Logic', () {
      test('Consensus building from multiple insights', () {
        final insights = [
          SharedInsight(
            category: 'dimension_evolution',
            dimension: 'adventure',
            value: 0.7,
            description: 'Adventure insight 1',
            reliability: 0.8,
            timestamp: DateTime.now(),
          ),
          SharedInsight(
            category: 'dimension_evolution',
            dimension: 'adventure',
            value: 0.9,
            description: 'Adventure insight 2',
            reliability: 0.9,
            timestamp: DateTime.now(),
          ),
          SharedInsight(
            category: 'dimension_evolution',
            dimension: 'social',
            value: 0.6,
            description: 'Social insight',
            reliability: 0.7,
            timestamp: DateTime.now(),
          ),
        ];
        
        // Group by dimension
        final dimensionGroups = <String, List<SharedInsight>>{};
        for (final insight in insights) {
          dimensionGroups.putIfAbsent(insight.dimension, () => []).add(insight);
        }
        
        expect(dimensionGroups['adventure']?.length, 2);
        expect(dimensionGroups['social']?.length, 1);
        
        // Calculate consensus for adventure dimension
        final adventureInsights = dimensionGroups['adventure'];
        if (adventureInsights != null && adventureInsights.isNotEmpty) {
          final avgValue = adventureInsights.map((i) => i.value).reduce((a, b) => a + b) / 
                          adventureInsights.length;
          final avgReliability = adventureInsights.map((i) => i.reliability).reduce((a, b) => a + b) / 
                                adventureInsights.length;
          
          expect(avgValue, closeTo(0.8, 0.1));
          expect(avgReliability, closeTo(0.85, 0.05));
        } else {
          fail('Adventure insights should not be null or empty');
        }
      });
      
      test('Knowledge reliability scoring', () {
        final insights = List.generate(5, (i) => SharedInsight(
          category: 'dimension_evolution',
          dimension: 'adventure',
          value: 0.8,
          reliability: 0.85,
          description: 'Insight $i',
          timestamp: DateTime.now(),
        ));
        
        final avgReliability = insights.map((i) => i.reliability).reduce((a, b) => a + b) / 
                              insights.length;
        final supportFactor = (insights.length / 5.0).clamp(0.0, 1.0);
        final reliabilityScore = (avgReliability * 0.7 + supportFactor * 0.3).clamp(0.0, 1.0);
        
        expect(avgReliability, 0.85);
        expect(supportFactor, 1.0); // 5/5 = 1.0
        expect(reliabilityScore, closeTo(0.895, 0.01)); // 0.85*0.7 + 1.0*0.3
      });
    });
    
    group('Integration Smoke Tests', () {
      test('AI2AIChatAnalyzer can be instantiated', () {
        expect(analyzer, isNotNull);
        expect(analyzer, isA<AI2AIChatAnalyzer>());
      });
      
      test('All data models are valid types', () {
        expect(AI2AIChatEvent, isA<Type>());
        expect(SharedInsight, isA<Type>());
        expect(EmergingPattern, isA<Type>());
        expect(CommunityTrend, isA<Type>());
        expect(CollectiveKnowledge, isA<Type>());
        expect(CrossPersonalityLearningPattern, isA<Type>());
        expect(AI2AILearningRecommendations, isA<Type>());
        expect(LearningEffectivenessMetrics, isA<Type>());
      });
    });
  });
}

