import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:avrai/core/constants/vibe_constants.dart';
import 'package:avrai/core/models/connection_metrics.dart' hide SharedInsight;
import 'package:avrai/core/ai/ai2ai_learning.dart';
import 'package:avrai/core/ai/ai2ai_learning/extractors/conversation_insights_extractor.dart';
import 'package:avrai/core/ai/ai2ai_learning/detectors/emerging_patterns_detector.dart';
import 'package:avrai/core/ai/ai2ai_learning/builders/consensus_knowledge_builder.dart';
import 'package:avrai/core/ai/ai2ai_learning/analyzers/community_trends_analyzer.dart';
import 'package:avrai/core/ai/ai2ai_learning/analyzers/learning_effectiveness_analyzer.dart';
import 'package:avrai/core/ai/ai2ai_learning/recommendations/learning_recommendations_generator.dart';
import 'package:avrai/core/ai/ai2ai_learning/utils/ai2ai_learning_utils.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/ai/continuous_learning_system.dart';

/// Orchestrates the AI2AI learning system
///
/// Coordinates data extraction, pattern detection, knowledge building, and trend analysis.
class AI2AILearningOrchestrator {
  static const String _logName = 'AI2AILearningOrchestrator';

  // AI2AI learning state
  final Map<String, List<AI2AIChatEvent>> _chatHistory = {};
  final Map<String, CollectiveKnowledge> _sharedKnowledge = {};
  final Map<String, List<CrossPersonalityInsight>> _learningInsights = {};

  // Core modules
  final ConversationInsightsExtractor _insightsExtractor;
  final EmergingPatternsDetector _patternsDetector;
  final ConsensusKnowledgeBuilder _knowledgeBuilder;
  final CommunityTrendsAnalyzer _trendsAnalyzer;
  final LearningRecommendationsGenerator _recommendationsGenerator;
  final LearningEffectivenessAnalyzer _effectivenessAnalyzer;

  AI2AILearningOrchestrator({
    ConversationInsightsExtractor? insightsExtractor,
    EmergingPatternsDetector? patternsDetector,
    ConsensusKnowledgeBuilder? knowledgeBuilder,
    CommunityTrendsAnalyzer? trendsAnalyzer,
    LearningRecommendationsGenerator? recommendationsGenerator,
    LearningEffectivenessAnalyzer? effectivenessAnalyzer,
  })  : _insightsExtractor =
            insightsExtractor ?? ConversationInsightsExtractor(),
        _patternsDetector = patternsDetector ?? EmergingPatternsDetector(),
        _knowledgeBuilder = knowledgeBuilder ?? ConsensusKnowledgeBuilder(),
        _trendsAnalyzer = trendsAnalyzer ?? CommunityTrendsAnalyzer(),
        _recommendationsGenerator =
            recommendationsGenerator ?? LearningRecommendationsGenerator(),
        _effectivenessAnalyzer =
            effectivenessAnalyzer ?? LearningEffectivenessAnalyzer();

  /// Get chat history for a user
  Future<List<AI2AIChatEvent>> getChatHistory(String userId) async =>
      _chatHistory[userId] ?? [];

  /// Get all chat history (for admin access)
  Map<String, List<AI2AIChatEvent>> getAllChatHistory() =>
      Map<String, List<AI2AIChatEvent>>.from(_chatHistory);

  /// Get learning insights for a user
  Future<List<CrossPersonalityInsight>> getLearningInsights(
          String userId) async =>
      _learningInsights[userId] ?? [];

  /// Get shared knowledge (for admin access)
  Map<String, CollectiveKnowledge> getSharedKnowledge() =>
      Map<String, CollectiveKnowledge>.from(_sharedKnowledge);

  /// Store chat event in history
  Future<void> storeChatEvent(String userId, AI2AIChatEvent chatEvent) async {
    final userHistory = _chatHistory[userId] ?? <AI2AIChatEvent>[];
    userHistory.add(chatEvent);
    _chatHistory[userId] = userHistory;

    // Keep only recent chats (last 200 events)
    if (userHistory.length > 200) {
      _chatHistory[userId] = userHistory.sublist(userHistory.length - 200);
    }

    developer.log('Stored chat event for user: $userId', name: _logName);
  }

  /// Get recent chats since cutoff
  Future<List<AI2AIChatEvent>> getRecentChats(
      String userId, DateTime cutoff) async {
    final history = await getChatHistory(userId);
    return history.where((chat) => chat.timestamp.isAfter(cutoff)).toList();
  }

  /// Analyze AI2AI chat conversation for learning insights
  Future<AI2AIChatAnalysisResult> analyzeChatConversation(
    String localUserId,
    AI2AIChatEvent chatEvent,
    ConnectionMetrics connectionContext,
  ) async {
    try {
      developer.log('Analyzing AI2AI chat for user: $localUserId',
          name: _logName);
      developer.log(
          'Chat type: ${chatEvent.messageType}, participants: ${chatEvent.participants.length}',
          name: _logName);

      // Store chat event in history
      await storeChatEvent(localUserId, chatEvent);

      // Get chat history
      final chatHistory = await getChatHistory(localUserId);

      // Extract conversation patterns
      final conversationPatterns =
          await _insightsExtractor.analyzeConversationPatterns(
        localUserId,
        chatEvent,
        chatHistory,
      );

      // Extract shared insights
      final sharedInsights = await _insightsExtractor.extractSharedInsights(
        chatEvent,
        connectionContext,
      );

      // Discover learning opportunities (simplified - can be enhanced)
      final learningOpportunities = _discoverLearningOpportunities(
        chatEvent,
        connectionContext,
      );

      // Analyze collective intelligence
      final collectiveIntelligence = _analyzeCollectiveIntelligence(
        chatEvent,
        sharedInsights,
      );

      // Generate evolution recommendations (simplified - can be enhanced)
      final evolutionRecommendations = _generateEvolutionRecommendations(
        sharedInsights,
        learningOpportunities,
      );

      // Calculate trust metrics
      final trustMetrics = _calculateTrustMetrics(
        chatEvent,
        connectionContext,
      );

      final result = AI2AIChatAnalysisResult(
        localUserId: localUserId,
        chatEvent: chatEvent,
        conversationPatterns: conversationPatterns,
        sharedInsights: sharedInsights,
        learningOpportunities: learningOpportunities,
        collectiveIntelligence: collectiveIntelligence,
        evolutionRecommendations: evolutionRecommendations,
        trustMetrics: trustMetrics,
        analysisTimestamp: DateTime.now(),
        analysisConfidence: AI2AILearningUtils.calculateAnalysisConfidence(
          chatEvent,
          connectionContext,
        ),
      );

      developer.log(
          'AI2AI chat analysis completed (confidence: ${(result.analysisConfidence * 100).round()}%)',
          name: _logName);

      // Phase 11 Enhancement: Integrate with ContinuousLearningSystem
      // If confidence >= 0.6, process through continuous learning pipeline
      if (result.analysisConfidence >= 0.6) {
        if (GetIt.instance.isRegistered<ContinuousLearningSystem>()) {
          try {
            final continuousLearningSystem =
                GetIt.instance<ContinuousLearningSystem>();
            unawaited(continuousLearningSystem.processAI2AIChatConversation(
              userId: localUserId,
              chatAnalysis: result,
            ));
          } catch (e) {
            developer.log(
              'Failed to process AI2AI chat conversation in ContinuousLearningSystem: $e',
              name: _logName,
            );
            // Non-blocking - don't break existing flow
          }
        }
      }

      return result;
    } catch (e, stackTrace) {
      developer.log('Error analyzing AI2AI chat: $e',
          name: _logName, error: e, stackTrace: stackTrace);
      return AI2AIChatAnalysisResult.fallback(localUserId, chatEvent);
    }
  }

  /// Build collective knowledge from multiple AI2AI interactions
  Future<CollectiveKnowledge> buildCollectiveKnowledge(
    String communityId,
    List<AI2AIChatEvent> communityChats,
  ) async {
    try {
      developer.log('Building collective knowledge for community: $communityId',
          name: _logName);

      if (communityChats.length < 3) {
        developer.log(
            'Insufficient chat data for collective knowledge building',
            name: _logName);
        return CollectiveKnowledge.insufficient();
      }

      // Aggregate insights from all AI2AI conversations
      final aggregatedInsights =
          await _knowledgeBuilder.aggregateConversationInsights(communityChats);

      // Identify emerging patterns across personalities
      final emergingPatterns =
          await _trendsAnalyzer.identifyEmergingPatterns(communityChats);

      // Build consensus knowledge from repeated insights
      final consensusKnowledge =
          await _knowledgeBuilder.buildConsensusKnowledge(aggregatedInsights);

      // Discover community-level personality trends
      final communityTrends =
          await _trendsAnalyzer.analyzeCommunityTrends(communityChats);

      // Calculate knowledge reliability scores
      final reliabilityScores = await _knowledgeBuilder
          .calculateKnowledgeReliability(aggregatedInsights, emergingPatterns);

      final collectiveKnowledge = CollectiveKnowledge(
        communityId: communityId,
        aggregatedInsights: aggregatedInsights,
        emergingPatterns: emergingPatterns,
        consensusKnowledge: consensusKnowledge,
        communityTrends: communityTrends,
        reliabilityScores: reliabilityScores,
        contributingChats: communityChats.length,
        knowledgeDepth:
            AI2AILearningUtils.calculateKnowledgeDepth(aggregatedInsights),
        lastUpdated: DateTime.now(),
      );

      // Store collective knowledge
      _sharedKnowledge[communityId] = collectiveKnowledge;

      developer.log(
          'Collective knowledge built: ${aggregatedInsights.length} insights, ${emergingPatterns.length} patterns',
          name: _logName);
      return collectiveKnowledge;
    } catch (e, stackTrace) {
      developer.log('Error building collective knowledge: $e',
          name: _logName, error: e, stackTrace: stackTrace);
      return CollectiveKnowledge.insufficient();
    }
  }

  /// Extract cross-personality learning patterns
  Future<List<CrossPersonalityLearningPattern>> extractLearningPatterns(
    String userId,
    List<AI2AIChatEvent> recentChats,
  ) async {
    return await _patternsDetector.extractLearningPatterns(
      userId,
      recentChats,
    );
  }

  // Helper methods (simplified versions - full implementations in main class)

  /// Discover learning opportunities
  List<AI2AILearningOpportunity> _discoverLearningOpportunities(
    AI2AIChatEvent chatEvent,
    ConnectionMetrics connectionContext,
  ) {
    final opportunities = <AI2AILearningOpportunity>[];

    // Identify dimension evolution opportunities
    if (connectionContext.currentCompatibility >=
        VibeConstants.mediumCompatibilityThreshold) {
      for (final dimensionChange
          in connectionContext.dimensionEvolution.entries) {
        if (dimensionChange.value.abs() >= 0.05) {
          opportunities.add(AI2AILearningOpportunity(
            area: dimensionChange.key,
            description:
                'Potential for ${dimensionChange.value > 0 ? 'growth' : 'refinement'} in ${dimensionChange.key}',
            potential: dimensionChange.value.abs(),
          ));
        }
      }
    }

    // Identify trust building opportunities
    if (connectionContext.learningEffectiveness >=
        VibeConstants.minLearningEffectiveness) {
      opportunities.add(AI2AILearningOpportunity(
        area: 'trust_building',
        description: 'High potential for building cross-personality trust',
        potential: connectionContext.learningEffectiveness,
      ));
    }

    return opportunities;
  }

  /// Analyze collective intelligence
  CollectiveIntelligence _analyzeCollectiveIntelligence(
    AI2AIChatEvent chatEvent,
    List<SharedInsight> insights,
  ) {
    final individualContribution =
        insights.length / max(1, chatEvent.messages.length);
    final insightQuality = insights.isNotEmpty
        ? insights.map((i) => i.reliability).reduce((a, b) => a + b) /
            insights.length
        : 0.0;

    final networkEffect = AI2AILearningUtils.calculateNetworkEffect(
        chatEvent.participants.length);
    final knowledgeSynergy =
        AI2AILearningUtils.calculateKnowledgeSynergy(insights);

    return CollectiveIntelligence(
      individualContribution: individualContribution,
      insightQuality: insightQuality,
      networkEffect: networkEffect,
      knowledgeSynergy: knowledgeSynergy,
      emergenceScore: (individualContribution +
              insightQuality +
              networkEffect +
              knowledgeSynergy) /
          4.0,
    );
  }

  /// Generate evolution recommendations
  List<PersonalityEvolutionRecommendation> _generateEvolutionRecommendations(
    List<SharedInsight> insights,
    List<AI2AILearningOpportunity> opportunities,
  ) {
    final recommendations = <PersonalityEvolutionRecommendation>[];

    // Generate recommendations based on shared insights
    for (final insight in insights.where((i) => i.reliability >= 0.7)) {
      if (insight.category == 'dimension_evolution') {
        recommendations.add(PersonalityEvolutionRecommendation(
          dimension: insight.dimension,
          direction: insight.value > 0.5 ? 'increase' : 'decrease',
          magnitude: (insight.value - 0.5).abs() * 2.0,
          confidence: insight.reliability,
          reasoning: 'Based on shared AI2AI insights: ${insight.description}',
        ));
      }
    }

    // Generate recommendations based on learning opportunities
    for (final opportunity in opportunities.where((o) => o.potential >= 0.3)) {
      recommendations.add(PersonalityEvolutionRecommendation(
        dimension: opportunity.area,
        direction: 'develop',
        magnitude: opportunity.potential,
        confidence: 0.8,
        reasoning: opportunity.description,
      ));
    }

    return recommendations;
  }

  /// Calculate trust metrics
  TrustMetrics _calculateTrustMetrics(
    AI2AIChatEvent chatEvent,
    ConnectionMetrics connectionContext,
  ) {
    final trustBuilding = connectionContext.currentCompatibility *
        connectionContext.learningEffectiveness;

    final trustEvolution =
        connectionContext.compatibilityEvolution.clamp(-1.0, 1.0);

    final communicationQuality =
        AI2AILearningUtils.assessCommunicationQuality(chatEvent.messages);

    final mutualBenefit = connectionContext.aiPleasureScore;

    return TrustMetrics(
      trustBuilding: trustBuilding,
      trustEvolution: trustEvolution,
      communicationQuality: communicationQuality,
      mutualBenefit: mutualBenefit,
      overallTrust:
          (trustBuilding + communicationQuality + mutualBenefit) / 3.0,
    );
  }

  /// Generate AI2AI learning recommendations
  Future<AI2AILearningRecommendations> generateLearningRecommendations(
    String userId,
    PersonalityProfile currentPersonality,
  ) async {
    try {
      developer.log('Generating AI2AI learning recommendations for: $userId',
          name: _logName);

      final chatHistory = await getChatHistory(userId);
      final learningPatterns =
          await extractLearningPatterns(userId, chatHistory);

      // Identify optimal personality types for learning
      final optimalPartners =
          await _recommendationsGenerator.identifyOptimalLearningPartners(
              currentPersonality, learningPatterns);

      // Generate conversation topics for maximum learning
      final learningTopics = await _recommendationsGenerator
          .generateLearningTopics(currentPersonality, learningPatterns);

      // Recommend personality development areas
      final developmentAreas = await _recommendationsGenerator
          .recommendDevelopmentAreas(currentPersonality, learningPatterns);

      // Suggest optimal interaction timing and frequency
      final interactionStrategy = await _recommendationsGenerator
          .suggestInteractionStrategy(userId, learningPatterns);

      // Calculate expected learning outcomes
      final expectedOutcomes =
          await _recommendationsGenerator.calculateExpectedOutcomes(
        currentPersonality,
        optimalPartners,
        learningTopics,
      );

      final recommendations = AI2AILearningRecommendations(
        userId: userId,
        optimalPartners: optimalPartners,
        learningTopics: learningTopics,
        developmentAreas: developmentAreas,
        interactionStrategy: interactionStrategy,
        expectedOutcomes: expectedOutcomes,
        confidenceScore: _recommendationsGenerator
            .calculateRecommendationConfidence(learningPatterns),
        generatedAt: DateTime.now(),
      );

      developer.log(
          'Generated AI2AI learning recommendations: ${optimalPartners.length} partners, ${learningTopics.length} topics',
          name: _logName);
      return recommendations;
    } catch (e, stackTrace) {
      developer.log('Error generating learning recommendations: $e',
          name: _logName, error: e, stackTrace: stackTrace);
      return AI2AILearningRecommendations.empty(userId);
    }
  }

  /// Measure AI2AI learning effectiveness
  Future<LearningEffectivenessMetrics> measureLearningEffectiveness(
    String userId,
    Duration timeWindow,
  ) async {
    try {
      developer.log('Measuring AI2AI learning effectiveness for: $userId',
          name: _logName);

      final cutoffTime = DateTime.now().subtract(timeWindow);
      final recentChats = await getRecentChats(userId, cutoffTime);
      final learningInsights = await getLearningInsights(userId);

      // Calculate personality evolution rate
      final evolutionRate =
          await _effectivenessAnalyzer.calculatePersonalityEvolutionRate(
        userId,
        cutoffTime,
        getRecentChats,
        getLearningInsights,
      );

      // Measure knowledge acquisition speed
      final knowledgeAcquisition =
          await _effectivenessAnalyzer.measureKnowledgeAcquisition(
        userId,
        recentChats,
        learningInsights,
      );

      // Assess insight quality improvement
      final insightQuality =
          await _effectivenessAnalyzer.assessInsightQuality(learningInsights);

      // Calculate trust network growth
      final trustNetworkGrowth =
          await _effectivenessAnalyzer.calculateTrustNetworkGrowth(
        userId,
        recentChats,
      );

      // Measure collective contribution
      final collectiveContribution =
          await _effectivenessAnalyzer.measureCollectiveContribution(
        userId,
        recentChats,
      );

      final metrics = LearningEffectivenessMetrics(
        userId: userId,
        timeWindow: timeWindow,
        evolutionRate: evolutionRate,
        knowledgeAcquisition: knowledgeAcquisition,
        insightQuality: insightQuality,
        trustNetworkGrowth: trustNetworkGrowth,
        collectiveContribution: collectiveContribution,
        totalInteractions: recentChats.length,
        overallEffectiveness:
            _effectivenessAnalyzer.calculateOverallEffectiveness(
          evolutionRate,
          knowledgeAcquisition,
          insightQuality,
          trustNetworkGrowth,
        ),
        measuredAt: DateTime.now(),
      );

      developer.log(
          'Learning effectiveness measured: ${(metrics.overallEffectiveness * 100).round()}% effective',
          name: _logName);
      return metrics;
    } catch (e, stackTrace) {
      developer.log('Error measuring learning effectiveness: $e',
          name: _logName, error: e, stackTrace: stackTrace);
      return LearningEffectivenessMetrics.zero(userId, timeWindow);
    }
  }
}
