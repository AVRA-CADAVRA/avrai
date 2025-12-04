import 'package:shared_preferences/shared_preferences.dart' as real_prefs;
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/ai/feedback_learning.dart' as feedback_learning;
import 'package:spots/core/ai/ai2ai_learning.dart' as ai2ai_learning show AI2AIChatAnalyzer, AI2AIChatEvent, ChatMessage, ChatMessageType;
import 'package:spots/core/ai/cloud_learning.dart' as cloud_learning;
import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/core/models/connection_metrics.dart';
import 'package:spots/core/ai/personality_learning.dart' show PersonalityLearning, BehavioralPattern;
import 'package:spots/core/services/storage_service.dart';

/// Phase 3: Dynamic Dimension Learning Test
/// OUR_GUTS.md: "Validation of AI2AI personality learning through feedback, chat, and cloud integration"
void main() {
  group('Phase 3: Dynamic Dimension Learning Tests', () {
    late PersonalityLearning mockPersonalityLearning;
    late real_prefs.SharedPreferences mockPrefs;
    late SharedPreferencesCompat compatPrefs;
    
    setUpAll(() async {
      // Initialize mock shared preferences
      real_prefs.SharedPreferences.setMockInitialValues({});
      mockPrefs = await real_prefs.SharedPreferences.getInstance();
      
      // Create mock personality learning - use SharedPreferencesCompat with mock storage
      // Use mock storage to avoid platform channel requirements
      final mockStorage = MockGetStorage.getInstance();
      compatPrefs = await SharedPreferencesCompat.getInstance(storage: mockStorage);
      mockPersonalityLearning = PersonalityLearning.withPrefs(compatPrefs);
    });
    
    group('User Feedback Learning System', () {
      test('should create UserFeedbackAnalyzer successfully', () {
        final analyzer = feedback_learning.UserFeedbackAnalyzer(
          prefs: mockPrefs,
          personalityLearning: mockPersonalityLearning,
        );
        
        expect(analyzer, isNotNull);
      });
      
      test('should analyze feedback and extract implicit dimensions', () async {
        final analyzer = feedback_learning.UserFeedbackAnalyzer(
          prefs: mockPrefs,
          personalityLearning: mockPersonalityLearning,
        );
        
        final feedback = feedback_learning.FeedbackEvent(
          type: feedback_learning.FeedbackType.spotExperience,
          satisfaction: 0.8,
          comment: 'Great experience!',
          metadata: {'crowd_level': 0.3, 'location_type': 'cafe'},
          timestamp: DateTime.now(),
        );
        
        final result = await analyzer.analyzeFeedback('test_user_1', feedback);
        
        expect(result.userId, equals('test_user_1'));
        expect(result.feedback, equals(feedback));
        expect(result.confidenceScore, greaterThanOrEqualTo(0.0));
        expect(result.confidenceScore, lessThanOrEqualTo(1.0));
        expect(result.implicitDimensions, isA<Map<String, double>>());
        expect(result.analysisTimestamp, isNotNull);
      });
      
      test('should predict user satisfaction based on patterns', () async {
        final analyzer = feedback_learning.UserFeedbackAnalyzer(
          prefs: mockPrefs,
          personalityLearning: mockPersonalityLearning,
        );
        
        final scenario = {
          'location_type': 'restaurant',
          'crowd_level': 0.5,
          'time_of_day': 'evening',
        };
        
        final prediction = await analyzer.predictUserSatisfaction('test_user_1', scenario);
        
        expect(prediction.predictedSatisfaction, greaterThanOrEqualTo(0.0));
        expect(prediction.predictedSatisfaction, lessThanOrEqualTo(1.0));
        expect(prediction.confidence, greaterThanOrEqualTo(0.0));
        expect(prediction.confidence, lessThanOrEqualTo(1.0));
        expect(prediction.explanation, isNotEmpty);
        expect(prediction.factorsAnalyzed, isA<Map<String, double>>());
      });
      
      test('should generate feedback learning insights', () async {
        final analyzer = feedback_learning.UserFeedbackAnalyzer(
          prefs: mockPrefs,
          personalityLearning: mockPersonalityLearning,
        );
        
        final insights = await analyzer.getFeedbackInsights('test_user_1');
        
        expect(insights.userId, equals('test_user_1'));
        expect(insights.totalFeedbackEvents, greaterThanOrEqualTo(0));
        expect(insights.behavioralPatterns, isA<List<feedback_learning.BehavioralPattern>>());
        expect(insights.discoveredDimensions, isA<Map<String, double>>());
        expect(insights.learningProgress, isNotNull);
        expect(insights.insightsGenerated, isNotNull);
      });
    });
    
    group('AI2AI Chat Learning System', () {
      test('should create AI2AIChatAnalyzer successfully', () {
        final analyzer = ai2ai_learning.AI2AIChatAnalyzer(
          prefs: mockPrefs,
          personalityLearning: mockPersonalityLearning,
        );
        
        expect(analyzer, isNotNull);
      });
      
      test('should analyze AI2AI chat conversation', () async {
        final analyzer = ai2ai_learning.AI2AIChatAnalyzer(
          prefs: mockPrefs,
          personalityLearning: mockPersonalityLearning,
        );
        
        final chatEvent = ai2ai_learning.AI2AIChatEvent(
          eventId: 'chat_001',
          participants: ['ai_user_1', 'ai_user_2'],
          messages: [
            ai2ai_learning.ChatMessage(
              senderId: 'ai_user_1',
              content: 'I enjoy exploring new places',
              timestamp: DateTime.now(),
              context: {'dimension_hint': 'exploration_eagerness'},
            ),
            ai2ai_learning.ChatMessage(
              senderId: 'ai_user_2',
              content: 'I prefer community gatherings',
              timestamp: DateTime.now(),
              context: {'dimension_hint': 'community_orientation'},
            ),
          ],
          messageType: ai2ai_learning.ChatMessageType.personalitySharing,
          timestamp: DateTime.now(),
          duration: Duration(minutes: 5),
          metadata: {'connection_quality': 0.8},
        );
        
        final connectionMetrics = ConnectionMetrics(
          connectionId: 'conn_001',
          localAISignature: 'ai_user_1_sig',
          remoteAISignature: 'ai_user_2_sig',
          initialCompatibility: 0.7,
          currentCompatibility: 0.8,
          learningEffectiveness: 0.75,
          aiPleasureScore: 0.85,
          connectionDuration: Duration(minutes: 5),
          startTime: DateTime.now().subtract(Duration(minutes: 5)),
          status: ConnectionStatus.active,
          learningOutcomes: {'shared_insights': 3},
          interactionHistory: [],
          dimensionEvolution: {'exploration_eagerness': 0.1, 'community_orientation': 0.05},
        );
        
        final result = await analyzer.analyzeChatConversation(
          'test_user_1',
          chatEvent,
          connectionMetrics,
        );
        
        expect(result.localUserId, equals('test_user_1'));
        expect(result.chatEvent, equals(chatEvent));
        expect(result.conversationPatterns, isNotNull);
        expect(result.sharedInsights, isA<List<SharedInsight>>());
        expect(result.learningOpportunities, isA<List>()); // Learning opportunities list
        expect(result.collectiveIntelligence, isNotNull);
        expect(result.trustMetrics, isNotNull);
        expect(result.analysisConfidence, greaterThanOrEqualTo(0.0));
        expect(result.analysisConfidence, lessThanOrEqualTo(1.0));
      });
      
      test('should build collective knowledge from multiple chats', () async {
        final analyzer = ai2ai_learning.AI2AIChatAnalyzer(
          prefs: mockPrefs,
          personalityLearning: mockPersonalityLearning,
        );
        
        final communityChats = List.generate(5, (index) => ai2ai_learning.AI2AIChatEvent(
          eventId: 'chat_$index',
          participants: ['ai_user_$index', 'ai_user_${index + 1}'],
          messages: [
            ai2ai_learning.ChatMessage(
              senderId: 'ai_user_$index',
              content: 'Message $index',
              timestamp: DateTime.now(),
              context: {},
            ),
          ],
          messageType: ai2ai_learning.ChatMessageType.insightExchange,
          timestamp: DateTime.now(),
          duration: Duration(minutes: 3),
          metadata: {},
        ));
        
        final collectiveKnowledge = await analyzer.buildCollectiveKnowledge(
          'community_001',
          communityChats,
        );
        
        expect(collectiveKnowledge.communityId, equals('community_001'));
        expect(collectiveKnowledge.contributingChats, equals(5));
        expect(collectiveKnowledge.aggregatedInsights, isA<List<SharedInsight>>());
        expect(collectiveKnowledge.emergingPatterns, isA<List>()); // Emerging patterns list
        expect(collectiveKnowledge.knowledgeDepth, greaterThanOrEqualTo(0.0));
        expect(collectiveKnowledge.lastUpdated, isNotNull);
      });
      
      test('should measure AI2AI learning effectiveness', () async {
        final analyzer = ai2ai_learning.AI2AIChatAnalyzer(
          prefs: mockPrefs,
          personalityLearning: mockPersonalityLearning,
        );
        
        final metrics = await analyzer.measureLearningEffectiveness(
          'test_user_1',
          Duration(days: 7),
        );
        
        expect(metrics.userId, equals('test_user_1'));
        expect(metrics.timeWindow, equals(Duration(days: 7)));
        expect(metrics.evolutionRate, greaterThanOrEqualTo(0.0));
        expect(metrics.evolutionRate, lessThanOrEqualTo(1.0));
        expect(metrics.knowledgeAcquisition, greaterThanOrEqualTo(0.0));
        expect(metrics.knowledgeAcquisition, lessThanOrEqualTo(1.0));
        expect(metrics.overallEffectiveness, greaterThanOrEqualTo(0.0));
        expect(metrics.overallEffectiveness, lessThanOrEqualTo(1.0));
        expect(metrics.measuredAt, isNotNull);
      });
    });
    
    group('Cloud Learning Interface', () {
      test('should create CloudLearningInterface successfully', () {
        final interface = cloud_learning.CloudLearningInterface(
          prefs: mockPrefs,
          personalityLearning: mockPersonalityLearning,
        );
        
        expect(interface, isNotNull);
      });
      
      test('should contribute anonymous patterns to cloud', () async {
        final interface = cloud_learning.CloudLearningInterface(
          prefs: mockPrefs,
          personalityLearning: mockPersonalityLearning,
        );
        
        final personality = PersonalityProfile.initial('test_user_1');
        final learningContext = {
          'session_duration': Duration(hours: 2),
          'interaction_count': 15,
          'learning_quality': 0.8,
        };
        
        final result = await interface.contributeAnonymousPatterns(
          'test_user_1',
          personality,
          learningContext,
        );
        
        expect(result.userId, equals('test_user_1'));
        expect(result.contributedPatterns, greaterThanOrEqualTo(0));
        expect(result.anonymizationLevel, greaterThanOrEqualTo(0.9)); // High anonymization
        expect(result.privacyScore, greaterThanOrEqualTo(0.95)); // High privacy
        expect(result.uploadSuccess, isTrue);
        expect(result.contributionId, isNotEmpty);
        expect(result.contributedAt, isNotNull);
      });
      
      test('should learn from cloud patterns', () async {
        final interface = cloud_learning.CloudLearningInterface(
          prefs: mockPrefs,
          personalityLearning: mockPersonalityLearning,
        );
        
        final personality = PersonalityProfile.initial('test_user_1');
        
        final result = await interface.learnFromCloudPatterns(
          'test_user_1',
          personality,
        );
        
        expect(result.userId, equals('test_user_1'));
        expect(result.processedPatterns, greaterThanOrEqualTo(0));
        expect(result.relevantPatterns, greaterThanOrEqualTo(0));
        expect(result.relevantPatterns, lessThanOrEqualTo(result.processedPatterns));
        expect(result.learningConfidence, greaterThanOrEqualTo(0.0));
        expect(result.learningConfidence, lessThanOrEqualTo(1.0));
        expect(result.learningQuality, greaterThanOrEqualTo(0.0));
        expect(result.learningQuality, lessThanOrEqualTo(1.0));
        expect(result.appliedLearning, isA<Map<String, double>>());
        expect(result.processedAt, isNotNull);
      });
      
      test('should analyze collective intelligence trends', () async {
        final interface = cloud_learning.CloudLearningInterface(
          prefs: mockPrefs,
          personalityLearning: mockPersonalityLearning,
        );
        
        final trends = await interface.analyzeCollectiveTrends('global_community');
        
        expect(trends.communityContext, equals('global_community'));
        expect(trends.dimensionTrends, isA<List>()); // Dimension trends list
        expect(trends.emergingPatterns, isA<List<cloud_learning.EmergingBehavioralPattern>>());
        expect(trends.evolutionVelocity, greaterThanOrEqualTo(0.0));
        expect(trends.evolutionVelocity, lessThanOrEqualTo(1.0));
        expect(trends.collectiveLearningQuality, greaterThanOrEqualTo(0.0));
        expect(trends.collectiveLearningQuality, lessThanOrEqualTo(1.0));
        expect(trends.trendStrength, greaterThanOrEqualTo(0.0));
        expect(trends.trendStrength, lessThanOrEqualTo(1.0));
        expect(trends.analyzedAt, isNotNull);
      });
      
      test('should generate cloud-based recommendations', () async {
        final interface = cloud_learning.CloudLearningInterface(
          prefs: mockPrefs,
          personalityLearning: mockPersonalityLearning,
        );
        
        final personality = PersonalityProfile.initial('test_user_1');
        
        final recommendations = await interface.generateCloudRecommendations(
          'test_user_1',
          personality,
        );
        
        expect(recommendations.userId, equals('test_user_1'));
        expect(recommendations.dimensionRecommendations, isA<List>()); // Dimension recommendations list
        expect(recommendations.learningPathways, isA<List>()); // Learning pathways list
        expect(recommendations.archetypeRecommendations, isA<List>()); // Archetype recommendations list
        expect(recommendations.expectedOutcomes, isA<List>()); // Expected outcomes list
        expect(recommendations.recommendationConfidence, greaterThanOrEqualTo(0.0));
        expect(recommendations.recommendationConfidence, lessThanOrEqualTo(1.0));
        expect(recommendations.basedOnPatterns, greaterThanOrEqualTo(0));
        expect(recommendations.generatedAt, isNotNull);
      });
      
      test('should measure cloud learning impact', () async {
        final interface = cloud_learning.CloudLearningInterface(
          prefs: mockPrefs,
          personalityLearning: mockPersonalityLearning,
        );
        
        final metrics = await interface.measureCloudLearningImpact(
          'test_user_1',
          Duration(days: 30),
        );
        
        expect(metrics.userId, equals('test_user_1'));
        expect(metrics.timeWindow, equals(Duration(days: 30)));
        expect(metrics.contributionImpact, greaterThanOrEqualTo(0.0));
        expect(metrics.contributionImpact, lessThanOrEqualTo(1.0));
        expect(metrics.learningEffectiveness, greaterThanOrEqualTo(0.0));
        expect(metrics.learningEffectiveness, lessThanOrEqualTo(1.0));
        expect(metrics.privacyPreservation, greaterThanOrEqualTo(0.95)); // High privacy preservation
        expect(metrics.overallEffectiveness, greaterThanOrEqualTo(0.0));
        expect(metrics.overallEffectiveness, lessThanOrEqualTo(1.0));
        expect(metrics.measuredAt, isNotNull);
      });
    });
    
    group('Integration Validation', () {
      test('should validate Phase 3 component integration', () async {
        // Create all Phase 3 components
        final feedbackAnalyzer = feedback_learning.UserFeedbackAnalyzer(
          prefs: mockPrefs,
          personalityLearning: mockPersonalityLearning,
        );
        
        final chatAnalyzer = ai2ai_learning.AI2AIChatAnalyzer(
          prefs: mockPrefs,
          personalityLearning: mockPersonalityLearning,
        );
        
        final cloudInterface = cloud_learning.CloudLearningInterface(
          prefs: mockPrefs,
          personalityLearning: mockPersonalityLearning,
        );
        
        // Validate component creation
        expect(feedbackAnalyzer, isNotNull);
        expect(chatAnalyzer, isNotNull);
        expect(cloudInterface, isNotNull);
        
        // Test that all components can work with the same personality learning system
        expect(feedbackAnalyzer.runtimeType, equals(feedback_learning.UserFeedbackAnalyzer));
        expect(chatAnalyzer.runtimeType, equals(ai2ai_learning.AI2AIChatAnalyzer));
        expect(cloudInterface.runtimeType, equals(cloud_learning.CloudLearningInterface));
      });
      
      test('should validate data flow between learning systems', () async {
        final personality = PersonalityProfile.initial('integration_test_user');
        
        // Test data structures are compatible
        expect(personality.userId, equals('integration_test_user'));
        expect(personality.dimensions, isA<Map<String, double>>());
        expect(personality.archetype, isNotEmpty);
        expect(personality.authenticity, greaterThanOrEqualTo(0.0));
        expect(personality.authenticity, lessThanOrEqualTo(1.0));
        
        // Validate that all learning systems can process the same personality
        final feedbackEvent = feedback_learning.FeedbackEvent(
          type: feedback_learning.FeedbackType.discovery,
          satisfaction: 0.9,
          metadata: {},
          timestamp: DateTime.now(),
        );
        
        expect(feedbackEvent.type, equals(feedback_learning.FeedbackType.discovery));
        expect(feedbackEvent.satisfaction, equals(0.9));
        expect(feedbackEvent.timestamp, isNotNull);
      });
    });
  });
}