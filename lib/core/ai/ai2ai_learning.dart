import 'dart:developer' as developer;
import 'dart:math';
import 'package:spots/core/constants/vibe_constants.dart';
import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/core/models/connection_metrics.dart';
import 'package:spots/core/models/collaborative_activity_metrics.dart';
import 'package:spots/core/ai/personality_learning.dart';
import 'package:spots/core/services/storage_service.dart' show SharedPreferencesCompat;

class ExpectedOutcome {
  final String id;
  final String description;
  final double probability;
  
  ExpectedOutcome({
    required this.id,
    required this.description,
    required this.probability,
  });
}

/// OUR_GUTS.md: "AI2AI chat learning that builds collective intelligence through cross-personality interactions"
/// Advanced AI2AI chat analysis system that extracts learning insights from personality conversations
class AI2AIChatAnalyzer {
  static const String _logName = 'AI2AIChatAnalyzer';
  
  // Storage keys for AI2AI learning data
  // ignore: unused_field
  static const String _chatHistoryKey = 'ai2ai_chat_history';
  // ignore: unused_field
  static const String _learningInsightsKey = 'ai2ai_learning_insights';
  // ignore: unused_field
  static const String _collectiveKnowledgeKey = 'collective_knowledge';
  
  // ignore: unused_field
  final SharedPreferencesCompat _prefs;
  final PersonalityLearning _personalityLearning;
  
  // AI2AI learning state
  final Map<String, List<AI2AIChatEvent>> _chatHistory = {};
  final Map<String, CollectiveKnowledge> _sharedKnowledge = {};
  final Map<String, List<CrossPersonalityInsight>> _learningInsights = {};
  
  AI2AIChatAnalyzer({
    required SharedPreferencesCompat prefs,
    required PersonalityLearning personalityLearning,
  }) : _prefs = prefs,
       _personalityLearning = personalityLearning;
  
  /// Analyze AI2AI chat conversation for learning insights
  Future<AI2AIChatAnalysisResult> analyzeChatConversation(
    String localUserId,
    AI2AIChatEvent chatEvent,
    ConnectionMetrics connectionContext,
  ) async {
    try {
      developer.log('Analyzing AI2AI chat for user: $localUserId', name: _logName);
      developer.log('Chat type: ${chatEvent.messageType}, participants: ${chatEvent.participants.length}', name: _logName);
      
      // Store chat event in history
      await _storeChatEvent(localUserId, chatEvent);
      
      // Extract conversation patterns
      final conversationPatterns = await _analyzeConversationPatterns(localUserId, chatEvent);
      
      // Identify shared insights between AI personalities
      final sharedInsights = await _extractSharedInsights(chatEvent, connectionContext);
      
      // Discover cross-personality learning opportunities
      final learningOpportunities = await _discoverLearningOpportunities(
        localUserId,
        chatEvent,
        connectionContext,
      );
      
      // Analyze collective intelligence emergence
      final collectiveIntelligence = await _analyzeCollectiveIntelligence(
        localUserId,
        chatEvent,
        sharedInsights,
      );
      
      // Generate personality evolution recommendations
      final evolutionRecommendations = await _generateEvolutionRecommendations(
        localUserId,
        sharedInsights,
        learningOpportunities,
      );
      
      // Calculate cross-personality trust building
      final trustMetrics = await _calculateTrustMetrics(chatEvent, connectionContext);
      
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
        analysisConfidence: _calculateAnalysisConfidence(chatEvent, connectionContext),
      );
      
      // Apply learning if confidence is sufficient
      if (result.analysisConfidence >= 0.6) {
        await _applyAI2AILearning(localUserId, result);
      }
      
      developer.log('AI2AI chat analysis completed (confidence: ${(result.analysisConfidence * 100).round()}%)', name: _logName);
      return result;
    } catch (e) {
      developer.log('Error analyzing AI2AI chat: $e', name: _logName);
      return AI2AIChatAnalysisResult.fallback(localUserId, chatEvent);
    }
  }
  
  /// Build collective knowledge from multiple AI2AI interactions
  Future<CollectiveKnowledge> buildCollectiveKnowledge(
    String communityId,
    List<AI2AIChatEvent> communityChats,
  ) async {
    try {
      developer.log('Building collective knowledge for community: $communityId', name: _logName);
      
      if (communityChats.length < 3) {
        developer.log('Insufficient chat data for collective knowledge building', name: _logName);
        return CollectiveKnowledge.insufficient();
      }
      
      // Aggregate insights from all AI2AI conversations
      final aggregatedInsights = await _aggregateConversationInsights(communityChats);
      
      // Identify emerging patterns across personalities
      final emergingPatterns = await _identifyEmergingPatterns(communityChats);
      
      // Build consensus knowledge from repeated insights
      final consensusKnowledge = await _buildConsensusKnowledge(aggregatedInsights);
      
      // Discover community-level personality trends
      final communityTrends = await _analyzeCommunityTrends(communityChats);
      
      // Calculate knowledge reliability scores
      final reliabilityScores = await _calculateKnowledgeReliability(
        aggregatedInsights,
        emergingPatterns,
      );
      
      final collectiveKnowledge = CollectiveKnowledge(
        communityId: communityId,
        aggregatedInsights: aggregatedInsights,
        emergingPatterns: emergingPatterns,
        consensusKnowledge: consensusKnowledge,
        communityTrends: communityTrends,
        reliabilityScores: reliabilityScores,
        contributingChats: communityChats.length,
        knowledgeDepth: _calculateKnowledgeDepth(aggregatedInsights),
        lastUpdated: DateTime.now(),
      );
      
      // Store collective knowledge
      _sharedKnowledge[communityId] = collectiveKnowledge;
      
      developer.log('Collective knowledge built: ${aggregatedInsights.length} insights, ${emergingPatterns.length} patterns', name: _logName);
      return collectiveKnowledge;
    } catch (e) {
      developer.log('Error building collective knowledge: $e', name: _logName);
      return CollectiveKnowledge.insufficient();
    }
  }
  
  /// Extract cross-personality learning patterns
  Future<List<CrossPersonalityLearningPattern>> extractLearningPatterns(
    String userId,
    List<AI2AIChatEvent> recentChats,
  ) async {
    try {
      developer.log('Extracting cross-personality learning patterns for: $userId', name: _logName);
      
      final patterns = <CrossPersonalityLearningPattern>[];
      
      // Analyze interaction frequency patterns
      final frequencyPattern = await _analyzeInteractionFrequency(userId, recentChats);
      if (frequencyPattern != null) patterns.add(frequencyPattern);
      
      // Analyze compatibility evolution patterns
      final compatibilityPattern = await _analyzeCompatibilityEvolution(userId, recentChats);
      if (compatibilityPattern != null) patterns.add(compatibilityPattern);
      
      // Analyze knowledge sharing patterns
      final sharingPattern = await _analyzeKnowledgeSharing(userId, recentChats);
      if (sharingPattern != null) patterns.add(sharingPattern);
      
      // Analyze trust building patterns
      final trustPattern = await _analyzeTrustBuilding(userId, recentChats);
      if (trustPattern != null) patterns.add(trustPattern);
      
      // Analyze learning acceleration patterns
      final accelerationPattern = await _analyzeLearningAcceleration(userId, recentChats);
      if (accelerationPattern != null) patterns.add(accelerationPattern);
      
      developer.log('Extracted ${patterns.length} cross-personality learning patterns', name: _logName);
      return patterns;
    } catch (e) {
      developer.log('Error extracting learning patterns: $e', name: _logName);
      return [];
    }
  }
  
  /// Generate AI2AI learning recommendations
  Future<AI2AILearningRecommendations> generateLearningRecommendations(
    String userId,
    PersonalityProfile currentPersonality,
  ) async {
    try {
      developer.log('Generating AI2AI learning recommendations for: $userId', name: _logName);
      
      final chatHistory = await _getChatHistory(userId);
      final learningPatterns = await extractLearningPatterns(userId, chatHistory);
      
      // Identify optimal personality types for learning
      final optimalPartners = await _identifyOptimalLearningPartners(
        currentPersonality,
        learningPatterns,
      );
      
      // Generate conversation topics for maximum learning
      final learningTopics = await _generateLearningTopics(
        currentPersonality,
        learningPatterns,
      );
      
      // Recommend personality development areas
      final developmentAreas = await _recommendDevelopmentAreas(
        currentPersonality,
        learningPatterns,
      );
      
      // Suggest optimal interaction timing and frequency
      final interactionStrategy = await _suggestInteractionStrategy(
        userId,
        learningPatterns,
      );
      
      // Calculate expected learning outcomes
      final expectedOutcomes = await _calculateExpectedOutcomes(
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
        confidenceScore: _calculateRecommendationConfidence(learningPatterns),
        generatedAt: DateTime.now(),
      );
      
      developer.log('Generated AI2AI learning recommendations: ${optimalPartners.length} partners, ${learningTopics.length} topics', name: _logName);
      return recommendations;
    } catch (e) {
      developer.log('Error generating learning recommendations: $e', name: _logName);
      return AI2AILearningRecommendations.empty(userId);
    }
  }
  
  /// Measure AI2AI learning effectiveness
  Future<LearningEffectivenessMetrics> measureLearningEffectiveness(
    String userId,
    Duration timeWindow,
  ) async {
    try {
      developer.log('Measuring AI2AI learning effectiveness for: $userId', name: _logName);
      
      final cutoffTime = DateTime.now().subtract(timeWindow);
      final recentChats = await _getRecentChats(userId, cutoffTime);
      final learningInsights = await _getLearningInsights(userId);
      
      // Calculate personality evolution rate
      final evolutionRate = await _calculatePersonalityEvolutionRate(userId, cutoffTime);
      
      // Measure knowledge acquisition speed
      final knowledgeAcquisition = await _measureKnowledgeAcquisition(
        userId,
        recentChats,
        learningInsights,
      );
      
      // Assess insight quality improvement
      final insightQuality = await _assessInsightQuality(learningInsights);
      
      // Calculate trust network growth
      final trustNetworkGrowth = await _calculateTrustNetworkGrowth(userId, recentChats);
      
      // Measure collective contribution
      final collectiveContribution = await _measureCollectiveContribution(
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
        overallEffectiveness: _calculateOverallEffectiveness(
          evolutionRate,
          knowledgeAcquisition,
          insightQuality,
          trustNetworkGrowth,
        ),
        measuredAt: DateTime.now(),
      );
      
      developer.log('Learning effectiveness measured: ${(metrics.overallEffectiveness * 100).round()}% effective', name: _logName);
      return metrics;
    } catch (e) {
      developer.log('Error measuring learning effectiveness: $e', name: _logName);
      return LearningEffectivenessMetrics.zero(userId, timeWindow);
    }
  }
  
  // Private helper methods
  Future<void> _storeChatEvent(String userId, AI2AIChatEvent chatEvent) async {
    final userHistory = _chatHistory[userId] ?? <AI2AIChatEvent>[];
    userHistory.add(chatEvent);
    _chatHistory[userId] = userHistory;
    
    // Keep only recent chats (last 200 events)
    if (userHistory.length > 200) {
      _chatHistory[userId] = userHistory.sublist(userHistory.length - 200);
    }
    
    // Persist to storage
    await _saveChatHistory(userId);
  }
  
  Future<ConversationPatterns> _analyzeConversationPatterns(
    String userId,
    AI2AIChatEvent chatEvent,
  ) async {
    final history = await _getChatHistory(userId);
    
    // Analyze message exchange patterns
    final exchangeFrequency = _analyzeExchangeFrequency(history);
    final responseLatency = _analyzeResponseLatency(history);
    final conversationDepth = _analyzeConversationDepth(chatEvent);
    final topicConsistency = _analyzeTopicConsistency(history);
    
    return ConversationPatterns(
      exchangeFrequency: exchangeFrequency,
      responseLatency: responseLatency,
      conversationDepth: conversationDepth,
      topicConsistency: topicConsistency,
      patternStrength: _calculatePatternStrength(exchangeFrequency, topicConsistency),
    );
  }
  
  Future<List<SharedInsight>> _extractSharedInsights(
    AI2AIChatEvent chatEvent,
    ConnectionMetrics connectionContext,
  ) async {
    final insights = <SharedInsight>[];
    
    // Extract insights from message content and context
    for (final message in chatEvent.messages) {
      // Analyze dimension-related insights
      final dimensionInsights = await _extractDimensionInsights(message);
      insights.addAll(dimensionInsights);
      
      // Analyze preference sharing insights
      final preferenceInsights = await _extractPreferenceInsights(message);
      insights.addAll(preferenceInsights);
      
      // Analyze experience sharing insights
      final experienceInsights = await _extractExperienceInsights(message);
      insights.addAll(experienceInsights);
    }
    
    // Validate insights against connection context
    final validatedInsights = await _validateInsights(insights, connectionContext);
    
    return validatedInsights;
  }
  
  Future<List<AI2AILearningOpportunity>> _discoverLearningOpportunities(
    String userId,
    AI2AIChatEvent chatEvent,
    ConnectionMetrics connectionContext,
  ) async {
    final opportunities = <AI2AILearningOpportunity>[];
    
    // Identify dimension evolution opportunities
    if (connectionContext.currentCompatibility >= VibeConstants.mediumCompatibilityThreshold) {
      for (final dimensionChange in connectionContext.dimensionEvolution.entries) {
        if (dimensionChange.value.abs() >= 0.05) {
          opportunities.add(AI2AILearningOpportunity(
            area: dimensionChange.key,
            description: 'Potential for ${dimensionChange.value > 0 ? 'growth' : 'refinement'} in ${dimensionChange.key}',
            potential: dimensionChange.value.abs(),
          ));
        }
      }
    }
    
    // Identify trust building opportunities
    if (connectionContext.learningEffectiveness >= VibeConstants.minLearningEffectiveness) {
      opportunities.add(AI2AILearningOpportunity(
        area: 'trust_building',
        description: 'High potential for building cross-personality trust',
        potential: connectionContext.learningEffectiveness,
      ));
    }
    
    return opportunities;
  }
  
  Future<CollectiveIntelligence> _analyzeCollectiveIntelligence(
    String userId,
    AI2AIChatEvent chatEvent,
    List<SharedInsight> insights,
  ) async {
    // Analyze how individual insights contribute to collective understanding
    final individualContribution = insights.length / max(1, chatEvent.messages.length);
    final insightQuality = insights.isNotEmpty 
        ? insights.fold(0.0, (sum, insight) => sum + insight.reliability) / insights.length
        : 0.0;
    
    final networkEffect = _calculateNetworkEffect(chatEvent.participants.length);
    final knowledgeSynergy = _calculateKnowledgeSynergy(insights);
    
    return CollectiveIntelligence(
      individualContribution: individualContribution,
      insightQuality: insightQuality,
      networkEffect: networkEffect,
      knowledgeSynergy: knowledgeSynergy,
      emergenceScore: (individualContribution + insightQuality + networkEffect + knowledgeSynergy) / 4.0,
    );
  }
  
  Future<List<PersonalityEvolutionRecommendation>> _generateEvolutionRecommendations(
    String userId,
    List<SharedInsight> insights,
    List<AI2AILearningOpportunity> opportunities,
  ) async {
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
  
  Future<TrustMetrics> _calculateTrustMetrics(
    AI2AIChatEvent chatEvent,
    ConnectionMetrics connectionContext,
  ) async {
    final trustBuilding = connectionContext.currentCompatibility * 
                         connectionContext.learningEffectiveness;
    
    final trustEvolution = connectionContext.compatibilityEvolution.clamp(-1.0, 1.0);
    
    final communicationQuality = _assessCommunicationQuality(chatEvent.messages);
    
    final mutualBenefit = connectionContext.aiPleasureScore;
    
    return TrustMetrics(
      trustBuilding: trustBuilding,
      trustEvolution: trustEvolution,
      communicationQuality: communicationQuality,
      mutualBenefit: mutualBenefit,
      overallTrust: (trustBuilding + communicationQuality + mutualBenefit) / 3.0,
    );
  }
  
  double _calculateAnalysisConfidence(AI2AIChatEvent chatEvent, ConnectionMetrics connectionContext) {
    var confidence = 0.5; // Base confidence
    
    // Increase confidence based on conversation depth
    confidence += min(0.2, chatEvent.messages.length / 10.0);
    
    // Increase confidence based on connection quality
    confidence += connectionContext.learningEffectiveness * 0.2;
    
    // Increase confidence based on compatibility
    confidence += connectionContext.currentCompatibility * 0.1;
    
    return confidence.clamp(0.0, 1.0);
  }
  
  Future<void> _applyAI2AILearning(String userId, AI2AIChatAnalysisResult result) async {
    // Apply evolution recommendations if they exist
    if (result.evolutionRecommendations.isNotEmpty) {
      final dimensionAdjustments = <String, double>{};
      
      for (final recommendation in result.evolutionRecommendations) {
        if (recommendation.confidence >= 0.7) {
          final adjustment = recommendation.magnitude * VibeConstants.ai2aiLearningRate;
          final directionMultiplier = recommendation.direction == 'increase' ? 1.0 : -1.0;
          dimensionAdjustments[recommendation.dimension] = adjustment * directionMultiplier;
        }
      }
      
      if (dimensionAdjustments.isNotEmpty) {
        final ai2aiInsight = AI2AILearningInsight(
          type: AI2AIInsightType.communityInsight,
          dimensionInsights: dimensionAdjustments,
          learningQuality: result.analysisConfidence,
          timestamp: DateTime.now(),
        );
        
        await _personalityLearning.evolveFromAI2AILearning(userId, ai2aiInsight);
        
        developer.log('Applied AI2AI chat learning with ${dimensionAdjustments.length} adjustments', name: _logName);
      }
    }
  }
  
  // Additional helper methods (placeholder implementations)
  Future<List<AI2AIChatEvent>> _getChatHistory(String userId) async => _chatHistory[userId] ?? [];
  Future<void> _saveChatHistory(String userId) async => developer.log('Saved chat history for: $userId', name: _logName);
  Future<List<CrossPersonalityInsight>> _getLearningInsights(String userId) async => _learningInsights[userId] ?? [];
  
  /// Get chat history for admin access
  /// Returns all chat events for a given user ID
  Future<List<AI2AIChatEvent>> getChatHistoryForAdmin(String userId) async {
    return _chatHistory[userId] ?? [];
  }
  
  /// Get all chat history across all users (admin access)
  /// Returns a map of userId -> chat events
  Map<String, List<AI2AIChatEvent>> getAllChatHistoryForAdmin() {
    return Map<String, List<AI2AIChatEvent>>.from(_chatHistory);
  }
  
  // Analysis helper methods
  double _analyzeExchangeFrequency(List<AI2AIChatEvent> history) => min(1.0, history.length / 10.0);
  
  /// Analyze response latency from chat history
  /// Returns a score (0.0-1.0) where higher = faster/more responsive
  double _analyzeResponseLatency(List<AI2AIChatEvent> history) {
    if (history.isEmpty) return 0.5; // Default for no history
    
    final latencies = <Duration>[];
    
    for (final event in history) {
      if (event.messages.length < 2) continue;
      
      // Sort messages by timestamp
      final sortedMessages = List<ChatMessage>.from(event.messages)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // Calculate time between consecutive messages
      for (int i = 1; i < sortedMessages.length; i++) {
        final latency = sortedMessages[i].timestamp.difference(sortedMessages[i - 1].timestamp);
        if (latency.inSeconds > 0 && latency.inHours < 24) {
          // Only count reasonable latencies (not same sender, not too long)
          if (sortedMessages[i].senderId != sortedMessages[i - 1].senderId) {
            latencies.add(latency);
          }
        }
      }
    }
    
    if (latencies.isEmpty) return 0.5; // Default if no valid latencies
    
    // Calculate average latency in seconds
    final avgLatencySeconds = latencies
        .map((d) => d.inSeconds)
        .reduce((a, b) => a + b) / latencies.length;
    
    // Normalize: faster responses = higher score
    // Target: < 60 seconds = excellent (1.0), > 300 seconds = poor (0.0)
    final normalizedScore = 1.0 - min(1.0, avgLatencySeconds / 300.0);
    return normalizedScore.clamp(0.0, 1.0);
  }
  
  double _analyzeConversationDepth(AI2AIChatEvent event) => min(1.0, event.messages.length / 5.0);
  
  /// Analyze topic consistency across conversation history
  /// Returns a score (0.0-1.0) where higher = more consistent topics
  double _analyzeTopicConsistency(List<AI2AIChatEvent> history) {
    if (history.isEmpty) return 0.5; // Default for no history
    
    // Extract topics from message content
    final allTopics = <String>[];
    for (final event in history) {
      for (final message in event.messages) {
        // Simple keyword extraction (in production, could use NLP)
        final content = message.content.toLowerCase();
        final words = content.split(RegExp(r'\s+'));
        
        // Extract meaningful words (length > 3, not common stop words)
        final stopWords = {'the', 'and', 'for', 'are', 'but', 'not', 'you', 'all', 'can', 'her', 'was', 'one', 'our', 'out', 'day', 'get', 'has', 'him', 'his', 'how', 'its', 'may', 'new', 'now', 'old', 'see', 'two', 'who', 'way', 'use', 'she', 'man', 'boy', 'did', 'let', 'put', 'say', 'too'};
        
        for (final word in words) {
          final cleaned = word.replaceAll(RegExp(r'[^\w]'), '');
          if (cleaned.length > 3 && !stopWords.contains(cleaned)) {
            allTopics.add(cleaned);
          }
        }
      }
    }
    
    if (allTopics.isEmpty) return 0.5; // Default if no topics extracted
    
    // Count topic frequencies
    final topicFreq = <String, int>{};
    for (final topic in allTopics) {
      topicFreq[topic] = (topicFreq[topic] ?? 0) + 1;
    }
    
    // Calculate consistency: higher frequency topics = more consistent
    final totalTopics = allTopics.length;
    final uniqueTopics = topicFreq.length;
    
    if (uniqueTopics == 0) return 0.5;
    
    // Consistency score: fewer unique topics relative to total = more consistent
    // But also reward repeated topics
    final repetitionRatio = (totalTopics - uniqueTopics) / totalTopics;
    final diversityPenalty = min(1.0, uniqueTopics / 20.0); // Penalize too many unique topics
    
    final consistencyScore = (repetitionRatio * 0.7 + (1.0 - diversityPenalty) * 0.3).clamp(0.0, 1.0);
    return consistencyScore;
  }
  
  double _calculatePatternStrength(double frequency, double consistency) => (frequency + consistency) / 2.0;
  
  double _calculateNetworkEffect(int participantCount) => min(1.0, participantCount / 5.0);
  double _calculateKnowledgeSynergy(List<SharedInsight> insights) => min(1.0, insights.length / 10.0);
  double _assessCommunicationQuality(List<ChatMessage> messages) => min(1.0, messages.length / 3.0);
  
  double _calculateKnowledgeDepth(List<SharedInsight> insights) => min(1.0, insights.length / 20.0);
  
  // Complex analysis methods (implemented)
  /// Aggregate insights from multiple conversations
  Future<List<SharedInsight>> _aggregateConversationInsights(List<AI2AIChatEvent> chats) async {
    if (chats.isEmpty) return [];
    
    final aggregated = <String, SharedInsight>{};
    
    for (final chat in chats) {
      // Extract insights from messages
      for (final message in chat.messages) {
        // Simple keyword-based insight extraction
        final content = message.content.toLowerCase();
        
        // Look for dimension-related keywords
        final dimensionKeywords = {
          'adventure': 'adventure',
          'social': 'social',
          'relax': 'relaxation',
          'explore': 'exploration',
          'creative': 'creativity',
          'active': 'activity',
        };
        
        for (final entry in dimensionKeywords.entries) {
          if (content.contains(entry.key)) {
            final insightId = '${entry.value}_${chat.eventId}';
            if (!aggregated.containsKey(insightId)) {
              aggregated[insightId] = SharedInsight(
                category: 'dimension_evolution',
                dimension: entry.value,
                value: 0.6,
                description: 'Insight about ${entry.value} from conversation',
                reliability: 0.7,
                timestamp: message.timestamp,
              );
            }
          }
        }
      }
    }
    
    return aggregated.values.toList();
  }
  
  /// Identify emerging patterns across conversations
  Future<List<EmergingPattern>> _identifyEmergingPatterns(List<AI2AIChatEvent> chats) async {
    if (chats.length < 3) return [];
    
    final patterns = <String, int>{};
    
    // Count pattern occurrences
    for (final chat in chats) {
      // Pattern: frequent short messages
      if (chat.messages.length >= 5 && chat.duration.inMinutes < 10) {
        patterns['rapid_exchange'] = (patterns['rapid_exchange'] ?? 0) + 1;
      }
      
      // Pattern: deep conversations
      if (chat.messages.length >= 10) {
        patterns['deep_conversation'] = (patterns['deep_conversation'] ?? 0) + 1;
      }
      
      // Pattern: multi-participant
      if (chat.participants.length >= 3) {
        patterns['group_interaction'] = (patterns['group_interaction'] ?? 0) + 1;
      }
    }
    
    // Return patterns that appear in at least 30% of chats
    final threshold = (chats.length * 0.3).ceil();
    return patterns.entries
        .where((e) => e.value >= threshold)
        .map((e) => EmergingPattern(e.key, e.value / chats.length))
        .toList();
  }
  
  /// Build consensus knowledge from aggregated insights
  Future<Map<String, dynamic>> _buildConsensusKnowledge(List<SharedInsight> insights) async {
    if (insights.isEmpty) return {};
    
    final consensus = <String, dynamic>{};
    
    // Group insights by dimension
    final dimensionGroups = <String, List<SharedInsight>>{};
    for (final insight in insights) {
      final dim = insight.dimension;
      dimensionGroups.putIfAbsent(dim, () => []).add(insight);
    }
    
    // Calculate consensus values for each dimension
    for (final entry in dimensionGroups.entries) {
      final dimInsights = entry.value;
      if (dimInsights.length >= 2) {
        final avgValue = dimInsights.map((i) => i.value).reduce((a, b) => a + b) / dimInsights.length;
        final avgReliability = dimInsights.map((i) => i.reliability).reduce((a, b) => a + b) / dimInsights.length;
        
        consensus[entry.key] = {
          'value': avgValue,
          'reliability': avgReliability,
          'supporting_insights': dimInsights.length,
        };
      }
    }
    
    return consensus;
  }
  
  /// Analyze community-level trends
  Future<List<CommunityTrend>> _analyzeCommunityTrends(List<AI2AIChatEvent> chats) async {
    if (chats.length < 5) return [];
    
    final trends = <CommunityTrend>[];
    
    // Analyze temporal trends
    final sortedChats = List<AI2AIChatEvent>.from(chats)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // Trend: Increasing conversation depth over time
    if (sortedChats.length >= 3) {
      final earlyDepth = sortedChats.take(sortedChats.length ~/ 3)
          .map((c) => c.messages.length)
          .reduce((a, b) => a + b) / (sortedChats.length ~/ 3);
      final lateDepth = sortedChats.skip(sortedChats.length * 2 ~/ 3)
          .map((c) => c.messages.length)
          .reduce((a, b) => a + b) / (sortedChats.length ~/ 3);
      
      if (lateDepth > earlyDepth * 1.2) {
        trends.add(CommunityTrend('increasing_conversation_depth', 1.0));
      } else if (lateDepth < earlyDepth * 0.8) {
        trends.add(CommunityTrend('decreasing_conversation_depth', -1.0));
      }
    }
    
    // Trend: Growing network size
    final avgParticipants = chats.map((c) => c.participants.length).reduce((a, b) => a + b) / chats.length;
    if (avgParticipants >= 2.5) {
      trends.add(CommunityTrend('growing_network', 1.0));
    }
    
    return trends;
  }
  
  /// Calculate reliability scores for knowledge
  Future<Map<String, double>> _calculateKnowledgeReliability(
    List<SharedInsight> insights,
    List<EmergingPattern> patterns,
  ) async {
    final reliability = <String, double>{};
    
    // Calculate reliability based on insight count and quality
    final dimensionGroups = <String, List<SharedInsight>>{};
    for (final insight in insights) {
      dimensionGroups.putIfAbsent(insight.dimension, () => []).add(insight);
    }
    
    for (final entry in dimensionGroups.entries) {
      final dimInsights = entry.value;
      final avgReliability = dimInsights.map((i) => i.reliability).reduce((a, b) => a + b) / dimInsights.length;
      final supportFactor = min(1.0, dimInsights.length / 5.0); // More insights = more reliable
      reliability[entry.key] = (avgReliability * 0.7 + supportFactor * 0.3).clamp(0.0, 1.0);
    }
    
    // Add pattern-based reliability
    for (final pattern in patterns) {
      reliability['pattern_${pattern.pattern}'] = pattern.strength;
    }
    
    return reliability;
  }
  
  /// Analyze interaction frequency patterns
  Future<CrossPersonalityLearningPattern?> _analyzeInteractionFrequency(
    String userId,
    List<AI2AIChatEvent> chats,
  ) async {
    if (chats.length < 3) return null;
    
    // Calculate average time between interactions
    final sortedChats = List<AI2AIChatEvent>.from(chats)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    final intervals = <Duration>[];
    for (int i = 1; i < sortedChats.length; i++) {
      intervals.add(sortedChats[i].timestamp.difference(sortedChats[i - 1].timestamp));
    }
    
    if (intervals.isEmpty) return null;
    
    // Calculate average interval: sum all durations, then divide by count
    final totalDuration = intervals.fold<Duration>(
      Duration.zero,
      (sum, duration) => sum + duration,
    );
    final avgInterval = Duration(
      microseconds: totalDuration.inMicroseconds ~/ intervals.length,
    );
    final frequencyScore = 1.0 - min(1.0, avgInterval.inHours / 168.0); // Normalize to weekly
    
    return CrossPersonalityLearningPattern(
      patternType: 'interaction_frequency',
      characteristics: {
        'avg_interval_hours': avgInterval.inHours,
        'total_interactions': chats.length,
        'frequency_score': frequencyScore,
      },
      strength: frequencyScore,
      confidence: min(1.0, chats.length / 10.0),
      identified: DateTime.now(),
    );
  }
  
  /// Analyze compatibility evolution patterns
  Future<CrossPersonalityLearningPattern?> _analyzeCompatibilityEvolution(
    String userId,
    List<AI2AIChatEvent> chats,
  ) async {
    if (chats.length < 3) return null;
    
    // Analyze if conversations are getting longer/deeper over time
    final sortedChats = List<AI2AIChatEvent>.from(chats)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    final earlyDepth = sortedChats.take(sortedChats.length ~/ 2)
        .map((c) => c.messages.length)
        .reduce((a, b) => a + b) / (sortedChats.length ~/ 2);
    final lateDepth = sortedChats.skip(sortedChats.length ~/ 2)
        .map((c) => c.messages.length)
        .reduce((a, b) => a + b) / (sortedChats.length ~/ 2);
    
    final evolutionScore = lateDepth > earlyDepth ? (lateDepth / earlyDepth - 1.0).clamp(0.0, 1.0) : 0.0;
    
    if (evolutionScore < 0.1) return null; // No significant evolution
    
    return CrossPersonalityLearningPattern(
      patternType: 'compatibility_evolution',
      characteristics: {
        'early_depth': earlyDepth,
        'late_depth': lateDepth,
        'evolution_rate': evolutionScore,
      },
      strength: evolutionScore,
      confidence: min(1.0, chats.length / 10.0),
      identified: DateTime.now(),
    );
  }
  
  /// Analyze knowledge sharing patterns
  Future<CrossPersonalityLearningPattern?> _analyzeKnowledgeSharing(
    String userId,
    List<AI2AIChatEvent> chats,
  ) async {
    if (chats.isEmpty) return null;
    
    // Count insights and learning opportunities
    int totalInsights = 0;
    for (final chat in chats) {
      // Estimate insights from message count and depth
      totalInsights += (chat.messages.length / 2).round();
    }
    
    final sharingScore = min(1.0, totalInsights / (chats.length * 3.0));
    
    if (sharingScore < 0.2) return null;
    
    return CrossPersonalityLearningPattern(
      patternType: 'knowledge_sharing',
      characteristics: {
        'total_insights': totalInsights,
        'avg_insights_per_chat': totalInsights / chats.length,
        'sharing_score': sharingScore,
      },
      strength: sharingScore,
      confidence: min(1.0, chats.length / 5.0),
      identified: DateTime.now(),
    );
  }
  
  /// Analyze trust building patterns
  Future<CrossPersonalityLearningPattern?> _analyzeTrustBuilding(
    String userId,
    List<AI2AIChatEvent> chats,
  ) async {
    if (chats.length < 3) return null;
    
    // Trust building indicators: repeated interactions with same participants
    final participantCounts = <String, int>{};
    for (final chat in chats) {
      for (final participant in chat.participants) {
        if (participant != userId) {
          participantCounts[participant] = (participantCounts[participant] ?? 0) + 1;
        }
      }
    }
    
    final repeatedConnections = participantCounts.values.where((c) => c >= 2).length;
    final trustScore = min(1.0, repeatedConnections / max(1, participantCounts.length));
    
    if (trustScore < 0.3) return null;
    
    return CrossPersonalityLearningPattern(
      patternType: 'trust_building',
      characteristics: {
        'unique_participants': participantCounts.length,
        'repeated_connections': repeatedConnections,
        'trust_score': trustScore,
      },
      strength: trustScore,
      confidence: min(1.0, chats.length / 5.0),
      identified: DateTime.now(),
    );
  }
  
  /// Analyze learning acceleration patterns
  Future<CrossPersonalityLearningPattern?> _analyzeLearningAcceleration(
    String userId,
    List<AI2AIChatEvent> chats,
  ) async {
    if (chats.length < 5) return null;
    
    // Check if learning rate is increasing over time
    final sortedChats = List<AI2AIChatEvent>.from(chats)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // Calculate learning indicators per time period
    final earlyPeriod = sortedChats.take(sortedChats.length ~/ 2);
    final latePeriod = sortedChats.skip(sortedChats.length ~/ 2);
    
    final earlyLearning = earlyPeriod.map((c) => c.messages.length * c.participants.length).reduce((a, b) => a + b);
    final lateLearning = latePeriod.map((c) => c.messages.length * c.participants.length).reduce((a, b) => a + b);
    
    final earlyTime = earlyPeriod.last.timestamp.difference(earlyPeriod.first.timestamp).inDays;
    final lateTime = latePeriod.last.timestamp.difference(latePeriod.first.timestamp).inDays;
    
    if (earlyTime == 0 || lateTime == 0) return null;
    
    final earlyRate = earlyLearning / earlyTime;
    final lateRate = lateLearning / lateTime;
    
    final acceleration = lateRate > earlyRate ? ((lateRate / earlyRate - 1.0) / 2.0).clamp(0.0, 1.0) : 0.0;
    
    if (acceleration < 0.1) return null;
    
    return CrossPersonalityLearningPattern(
      patternType: 'learning_acceleration',
      characteristics: {
        'early_rate': earlyRate,
        'late_rate': lateRate,
        'acceleration_factor': acceleration,
      },
      strength: acceleration,
      confidence: min(1.0, chats.length / 10.0),
      identified: DateTime.now(),
    );
  }
  
  /// Extract dimension-related insights from chat message
  /// Analyzes message content for personality dimension indicators
  Future<List<SharedInsight>> _extractDimensionInsights(ChatMessage message) async {
    final insights = <SharedInsight>[];
    final content = message.content.toLowerCase();
    
    // Map keywords to dimensions
    final dimensionKeywords = {
      'exploration_eagerness': ['explore', 'adventure', 'new', 'discover', 'try', 'visit', 'check out'],
      'community_orientation': ['together', 'group', 'friends', 'community', 'share', 'we', 'us'],
      'authenticity_preference': ['authentic', 'local', 'hidden', 'gem', 'secret', 'real', 'genuine'],
      'social_discovery_style': ['social', 'meet', 'hangout', 'connect', 'network'],
      'temporal_flexibility': ['spontaneous', 'spur', 'moment', 'now', 'flexible', 'anytime'],
      'location_adventurousness': ['far', 'travel', 'distant', 'road trip', 'journey', 'explore'],
      'curation_tendency': ['curate', 'list', 'recommend', 'suggest', 'favorite', 'best'],
      'trust_network_reliance': ['trust', 'friend', 'recommended', 'suggested', 'heard'],
    };
    
    // Check for dimension keywords in message
    for (final entry in dimensionKeywords.entries) {
      final dimension = entry.key;
      final keywords = entry.value;
      
      int matches = 0;
      for (final keyword in keywords) {
        if (content.contains(keyword)) {
          matches++;
        }
      }
      
      if (matches > 0) {
        // Calculate value based on keyword frequency
        final value = min(1.0, matches / keywords.length * 0.8 + 0.2);
        final reliability = min(1.0, matches / 3.0); // More matches = more reliable
        
        insights.add(SharedInsight(
          category: 'dimension_evolution',
          dimension: dimension,
          value: value,
          description: 'Dimension insight from message: ${message.content.substring(0, min(50, message.content.length))}...',
          reliability: reliability,
          timestamp: message.timestamp,
        ));
      }
    }
    
    return insights;
  }
  
  /// Extract preference-related insights from chat message
  /// Identifies user preferences mentioned in conversation
  Future<List<SharedInsight>> _extractPreferenceInsights(ChatMessage message) async {
    final insights = <SharedInsight>[];
    final content = message.content.toLowerCase();
    
    // Look for preference indicators
    final preferencePatterns = {
      'like': ['like', 'love', 'enjoy', 'prefer', 'favorite'],
      'dislike': ['dislike', 'hate', 'avoid', 'not my thing', "don't like"],
      'want': ['want', 'wish', 'hope', 'looking for', 'seeking'],
      'need': ['need', 'require', 'must have', 'essential'],
    };
    
    for (final entry in preferencePatterns.entries) {
      final preferenceType = entry.key;
      final keywords = entry.value;
      
      bool found = false;
      for (final keyword in keywords) {
        if (content.contains(keyword)) {
          found = true;
          break;
        }
      }
      
      if (found) {
        // Extract what they're referring to (simplified - in production would use NLP)
        final value = preferenceType == 'like' || preferenceType == 'want' ? 0.8 : 0.2;
        
        insights.add(SharedInsight(
          category: 'preference_discovery',
          dimension: preferenceType,
          value: value,
          description: 'Preference insight: ${preferenceType} mentioned in conversation',
          reliability: 0.6,
          timestamp: message.timestamp,
        ));
      }
    }
    
    return insights;
  }
  
  /// Extract experience-related insights from chat message
  /// Identifies shared experiences and learnings
  Future<List<SharedInsight>> _extractExperienceInsights(ChatMessage message) async {
    final insights = <SharedInsight>[];
    final content = message.content.toLowerCase();
    
    // Look for experience indicators
    final experienceKeywords = [
      'went', 'visited', 'tried', 'experienced', 'saw', 'did',
      'learned', 'discovered', 'found', 'realized', 'noticed',
    ];
    
    bool hasExperience = false;
    for (final keyword in experienceKeywords) {
      if (content.contains(keyword)) {
        hasExperience = true;
        break;
      }
    }
    
    if (hasExperience) {
      // Extract experience type (simplified)
      String experienceType = 'general';
      if (content.contains('spot') || content.contains('place') || content.contains('location')) {
        experienceType = 'location_experience';
      } else if (content.contains('food') || content.contains('eat') || content.contains('drink')) {
        experienceType = 'food_experience';
      } else if (content.contains('activity') || content.contains('event')) {
        experienceType = 'activity_experience';
      }
      
      insights.add(SharedInsight(
        category: 'experience_sharing',
        dimension: experienceType,
        value: 0.7,
        description: 'Experience shared: ${message.content.substring(0, min(60, message.content.length))}...',
        reliability: 0.7,
        timestamp: message.timestamp,
      ));
    }
    
    return insights;
  }
  
  Future<List<SharedInsight>> _validateInsights(List<SharedInsight> insights, ConnectionMetrics context) async {
    // Filter insights based on connection context
    final validated = <SharedInsight>[];
    
    for (final insight in insights) {
      // Only include insights with sufficient reliability
      if (insight.reliability >= 0.5) {
        // Boost reliability if connection context supports it
        double adjustedReliability = insight.reliability;
        
        // If connection has high compatibility, insights are more reliable
        if (context.currentCompatibility >= 0.7) {
          adjustedReliability = min(1.0, adjustedReliability + 0.1);
        }
        
        // If learning effectiveness is high, insights are more reliable
        if (context.learningEffectiveness >= 0.7) {
          adjustedReliability = min(1.0, adjustedReliability + 0.1);
        }
        
        validated.add(SharedInsight(
          category: insight.category,
          dimension: insight.dimension,
          value: insight.value,
          description: insight.description,
          reliability: adjustedReliability,
          timestamp: insight.timestamp,
        ));
      }
    }
    
    return validated;
  }
  
  /// Identify optimal learning partners based on personality and patterns
  /// Finds personalities that would provide the best learning opportunities
  Future<List<OptimalPartner>> _identifyOptimalLearningPartners(
    PersonalityProfile personality,
    List<CrossPersonalityLearningPattern> patterns,
  ) async {
    final partners = <OptimalPartner>[];
    
    // Analyze patterns to identify partner characteristics
    final trustPattern = patterns.firstWhere(
      (p) => p.patternType == 'trust_building',
      orElse: () => CrossPersonalityLearningPattern(
        patternType: 'none',
        characteristics: {},
        strength: 0.0,
        confidence: 0.0,
        identified: DateTime.now(),
      ),
    );
    
    final compatibilityPattern = patterns.firstWhere(
      (p) => p.patternType == 'compatibility_evolution',
      orElse: () => CrossPersonalityLearningPattern(
        patternType: 'none',
        characteristics: {},
        strength: 0.0,
        confidence: 0.0,
        identified: DateTime.now(),
      ),
    );
    
    // Identify complementary archetypes for learning
    // Partners with different but compatible dimensions provide learning opportunities
    final currentArchetype = personality.archetype;
    
    // Map of archetypes and their learning compatibility
    final archetypeCompatibility = {
      'adventurous_explorer': ['community_curator', 'social_connector', 'balanced'],
      'community_curator': ['adventurous_explorer', 'authentic_seeker', 'balanced'],
      'authentic_seeker': ['community_curator', 'social_connector', 'balanced'],
      'social_connector': ['adventurous_explorer', 'community_curator', 'balanced'],
      'balanced': ['adventurous_explorer', 'community_curator', 'authentic_seeker'],
    };
    
    final compatibleArchetypes = archetypeCompatibility[currentArchetype] ?? 
        ['balanced', 'adventurous_explorer', 'community_curator'];
    
    // Calculate compatibility scores based on patterns
    for (final archetype in compatibleArchetypes) {
      double compatibility = 0.6; // Base compatibility
      
      // Boost if trust pattern exists
      if (trustPattern.patternType == 'trust_building' && trustPattern.strength > 0.5) {
        compatibility += 0.2;
      }
      
      // Boost if compatibility evolution is positive
      if (compatibilityPattern.patternType == 'compatibility_evolution' && 
          compatibilityPattern.strength > 0.5) {
        compatibility += 0.2;
      }
      
      partners.add(OptimalPartner(
        archetype,
        compatibility.clamp(0.0, 1.0),
      ));
    }
    
    // Sort by compatibility (highest first)
    partners.sort((a, b) => b.compatibility.compareTo(a.compatibility));
    
    // Return top 3 partners
    return partners.take(3).toList();
  }
  
  /// Generate learning topics based on personality and patterns
  /// Creates topics that would maximize learning potential
  Future<List<LearningTopic>> _generateLearningTopics(
    PersonalityProfile personality,
    List<CrossPersonalityLearningPattern> patterns,
  ) async {
    final topics = <LearningTopic>[];
    
    // Identify weak dimensions (low confidence or extreme values)
    final weakDimensions = <String>[];
    for (final entry in personality.dimensions.entries) {
      final confidence = personality.dimensionConfidence[entry.key] ?? 0.0;
      final value = entry.value;
      
      // Weak if low confidence or extreme value (needs balancing)
      if (confidence < 0.5 || value < 0.2 || value > 0.8) {
        weakDimensions.add(entry.key);
      }
    }
    
    // Generate topics based on weak dimensions
    final topicMap = {
      'exploration_eagerness': 'Exploring new places and experiences',
      'community_orientation': 'Building community connections',
      'authenticity_preference': 'Discovering authentic local spots',
      'social_discovery_style': 'Social discovery patterns',
      'temporal_flexibility': 'Spontaneous vs planned activities',
      'location_adventurousness': 'Travel and location exploration',
      'curation_tendency': 'Curating and sharing recommendations',
      'trust_network_reliance': 'Building trust networks',
    };
    
    for (final dimension in weakDimensions) {
      final topicName = topicMap[dimension] ?? 'General learning about $dimension';
      final potential = 0.8; // High potential for weak dimensions
      
      topics.add(LearningTopic(
        topicName,
        potential,
      ));
    }
    
    // Add topics based on patterns
    for (final pattern in patterns) {
      if (pattern.patternType == 'knowledge_sharing' && pattern.strength > 0.6) {
        topics.add(LearningTopic(
          'Knowledge sharing and collective learning',
          pattern.strength,
        ));
      }
      
      if (pattern.patternType == 'learning_acceleration' && pattern.strength > 0.5) {
        topics.add(LearningTopic(
          'Accelerated learning techniques',
          pattern.strength,
        ));
      }
    }
    
    // If no specific topics, add general ones
    if (topics.isEmpty) {
      topics.addAll([
        LearningTopic('Cross-personality learning', 0.7),
        LearningTopic('Personality evolution', 0.6),
        LearningTopic('Trust building', 0.6),
      ]);
    }
    
    // Sort by potential (highest first) and return top 5
    topics.sort((a, b) => b.potential.compareTo(a.potential));
    return topics.take(5).toList();
  }
  
  /// Recommend development areas based on personality and patterns
  /// Identifies areas where personality could grow
  Future<List<DevelopmentArea>> _recommendDevelopmentAreas(
    PersonalityProfile personality,
    List<CrossPersonalityLearningPattern> patterns,
  ) async {
    final areas = <DevelopmentArea>[];
    
    // Identify dimensions that need development
    for (final entry in personality.dimensions.entries) {
      final dimension = entry.key;
      final value = entry.value;
      final confidence = personality.dimensionConfidence[dimension] ?? 0.0;
      
      // Low priority if already well-developed (high confidence and balanced value)
      if (confidence >= 0.7 && value >= 0.3 && value <= 0.7) {
        continue;
      }
      
      // High priority if extreme value or low confidence
      double priority = 0.5;
      if (confidence < 0.5) {
        priority = 0.9; // High priority for low confidence
      } else if (value < 0.2 || value > 0.8) {
        priority = 0.8; // High priority for extreme values
      }
      
      areas.add(DevelopmentArea(
        dimension,
        priority,
      ));
    }
    
    // Add areas based on patterns
    for (final pattern in patterns) {
      if (pattern.patternType == 'compatibility_evolution') {
        areas.add(DevelopmentArea(
          'compatibility_improvement',
          pattern.strength,
        ));
      }
      
      if (pattern.patternType == 'trust_building') {
        areas.add(DevelopmentArea(
          'trust_development',
          pattern.strength,
        ));
      }
    }
    
    // Sort by priority (highest first) and return top 5
    areas.sort((a, b) => b.priority.compareTo(a.priority));
    return areas.take(5).toList();
  }
  
  Future<InteractionStrategy> _suggestInteractionStrategy(String userId, List<CrossPersonalityLearningPattern> patterns) async => InteractionStrategy.balanced();
  
  /// Calculate expected outcomes from learning recommendations
  Future<List<ExpectedOutcome>> _calculateExpectedOutcomes(
    PersonalityProfile personality,
    List<OptimalPartner> partners,
    List<LearningTopic> topics,
  ) async {
    final outcomes = <ExpectedOutcome>[];
    
    // Calculate expected outcomes based on partners and topics
    if (partners.isNotEmpty && topics.isNotEmpty) {
      final avgCompatibility = partners
          .map((p) => p.compatibility)
          .reduce((a, b) => a + b) / partners.length;
      
      final avgTopicPotential = topics
          .map((t) => t.potential)
          .reduce((a, b) => a + b) / topics.length;
      
      // Expected personality evolution
      final evolutionProbability = (avgCompatibility * 0.6 + avgTopicPotential * 0.4).clamp(0.0, 1.0);
      outcomes.add(ExpectedOutcome(
        id: 'personality_evolution',
        description: 'Personality evolution through AI2AI learning',
        probability: evolutionProbability,
      ));
      
      // Expected dimension development
      outcomes.add(ExpectedOutcome(
        id: 'dimension_development',
        description: 'Development of personality dimensions',
        probability: avgTopicPotential,
      ));
      
      // Expected trust building
      outcomes.add(ExpectedOutcome(
        id: 'trust_building',
        description: 'Building trust with AI2AI partners',
        probability: avgCompatibility * 0.8,
      ));
    }
    
    return outcomes;
  }
  
  double _calculateRecommendationConfidence(List<CrossPersonalityLearningPattern> patterns) => min(1.0, patterns.length / 5.0);
  
  Future<List<AI2AIChatEvent>> _getRecentChats(String userId, DateTime cutoff) async {
    final allChats = await _getChatHistory(userId);
    return allChats.where((chat) => chat.timestamp.isAfter(cutoff)).toList();
  }
  
  /// Calculate personality evolution rate based on chat activity and learning insights
  /// Returns a score (0.0-1.0) representing how fast personality is evolving
  Future<double> _calculatePersonalityEvolutionRate(String userId, DateTime cutoff) async {
    try {
      // Get recent chats since cutoff
      final recentChats = await _getRecentChats(userId, cutoff);
      final learningInsights = await _getLearningInsights(userId);
      
      if (recentChats.isEmpty && learningInsights.isEmpty) {
        return 0.0; // No activity = no evolution
      }
      
      // Calculate time window in days
      final timeWindow = DateTime.now().difference(cutoff).inDays;
      if (timeWindow <= 0) return 0.0;
      
      // Count evolution indicators
      int evolutionIndicators = 0;
      
      // 1. Chat frequency (more chats = more learning opportunities)
      evolutionIndicators += min(10, recentChats.length);
      
      // 2. Learning insights count
      evolutionIndicators += min(10, learningInsights.length);
      
      // 3. Conversation depth (deeper conversations = more learning)
      final avgDepth = recentChats.isEmpty 
          ? 0.0 
          : recentChats.map((c) => c.messages.length).reduce((a, b) => a + b) / recentChats.length;
      evolutionIndicators += (avgDepth / 5.0 * 5).round(); // Normalize to 0-5
      
      // 4. Insight quality (higher quality insights = better evolution)
      final avgInsightQuality = learningInsights.isEmpty
          ? 0.0
          : learningInsights.map((i) => i.reliability).reduce((a, b) => a + b) / learningInsights.length;
      evolutionIndicators += (avgInsightQuality * 5).round(); // Normalize to 0-5
      
      // Normalize to 0.0-1.0 based on time window
      // Target: 20+ indicators in 7 days = high evolution rate (1.0)
      final maxExpectedIndicators = timeWindow * 3; // ~3 indicators per day for high activity
      final normalizedRate = min(1.0, evolutionIndicators / maxExpectedIndicators);
      
      return normalizedRate.clamp(0.0, 1.0);
    } catch (e) {
      developer.log('Error calculating evolution rate: $e', name: _logName);
      return 0.0;
    }
  }
  
  /// Measure knowledge acquisition from chats and insights
  /// Returns a score (0.0-1.0) representing how much knowledge is being acquired
  Future<double> _measureKnowledgeAcquisition(
    String userId,
    List<AI2AIChatEvent> chats,
    List<CrossPersonalityInsight> insights,
  ) async {
    if (chats.isEmpty && insights.isEmpty) return 0.0;
    
    double knowledgeScore = 0.0;
    int factors = 0;
    
    // Factor 1: Number of insights (more insights = more knowledge)
    if (insights.isNotEmpty) {
      final insightCountScore = min(1.0, insights.length / 10.0);
      knowledgeScore += insightCountScore * 0.3;
      factors++;
    }
    
    // Factor 2: Quality of insights (higher reliability = better knowledge)
    if (insights.isNotEmpty) {
      final avgReliability = insights
          .map((i) => i.reliability)
          .reduce((a, b) => a + b) / insights.length;
      knowledgeScore += avgReliability * 0.3;
      factors++;
    }
    
    // Factor 3: Conversation depth (deeper = more knowledge exchange)
    if (chats.isNotEmpty) {
      final avgMessagesPerChat = chats
          .map((c) => c.messages.length)
          .reduce((a, b) => a + b) / chats.length;
      final depthScore = min(1.0, avgMessagesPerChat / 10.0);
      knowledgeScore += depthScore * 0.2;
      factors++;
    }
    
    // Factor 4: Diversity of insights (more diverse = broader knowledge)
    if (insights.isNotEmpty) {
      final uniqueTypes = insights.map((i) => i.type).toSet().length;
      final diversityScore = min(1.0, uniqueTypes / 5.0);
      knowledgeScore += diversityScore * 0.2;
      factors++;
    }
    
    // Normalize by number of factors considered
    return factors > 0 ? (knowledgeScore / factors).clamp(0.0, 1.0) : 0.0;
  }
  
  /// Assess the quality of learning insights
  /// Returns a score (0.0-1.0) representing overall insight quality
  Future<double> _assessInsightQuality(List<CrossPersonalityInsight> insights) async {
    if (insights.isEmpty) return 0.0;
    
    // Calculate average reliability
    final avgReliability = insights
        .map((i) => i.reliability)
        .reduce((a, b) => a + b) / insights.length;
    
    // Factor in consistency (how many insights have high reliability)
    final highQualityCount = insights.where((i) => i.reliability >= 0.7).length;
    final consistencyScore = highQualityCount / insights.length;
    
    // Factor in diversity (variety of insight types)
    final uniqueTypes = insights.map((i) => i.type).toSet().length;
    final diversityScore = min(1.0, uniqueTypes / insights.length);
    
    // Weighted combination: reliability (50%), consistency (30%), diversity (20%)
    final qualityScore = (
      avgReliability * 0.5 +
      consistencyScore * 0.3 +
      diversityScore * 0.2
    ).clamp(0.0, 1.0);
    
    return qualityScore;
  }
  Future<double> _calculateTrustNetworkGrowth(String userId, List<AI2AIChatEvent> chats) async => 0.6;
  Future<double> _measureCollectiveContribution(String userId, List<AI2AIChatEvent> chats) async => 0.5;
  
  double _calculateOverallEffectiveness(double evolution, double knowledge, double quality, double trust) {
    return (evolution + knowledge + quality + trust) / 4.0;
  }
  
  /// Analyze collaborative activity patterns from AI2AI conversations
  /// Phase 7 Week 40: Track list creation during AI2AI conversations
  /// Privacy-safe: Returns aggregate metrics only, no user data
  // ignore: unused_element
  Future<CollaborativeActivityMetrics> _analyzeCollaborativeActivity(
    String userId,
    List<AI2AIChatEvent> chats,
  ) async {
    try {
      if (chats.isEmpty) {
        return CollaborativeActivityMetrics.empty();
      }
      
      developer.log('Analyzing collaborative activity for user: $userId (${chats.length} chats)', name: _logName);
      
      // Track collaborative list creation
      int totalCollaborativeLists = 0;
      int groupChatLists = 0;
      int dmLists = 0;
      final groupSizes = <int, int>{};
      final activityByHour = <int, int>{};
      int totalPlanningSessions = 0;
      double totalSessionDuration = 0.0;
      int listsWithSpots = 0;
      final timeDeltas = <Duration>[];
      
      // Get action history service (if available)
      // Note: This is a simplified implementation - in production would inject service
      // For now, we'll analyze based on chat patterns and metadata
      
      for (final chat in chats) {
        // Check if this chat led to list creation
        // Look for planning keywords in messages
        bool hasPlanningKeywords = false;
        for (final message in chat.messages) {
          final content = message.content.toLowerCase();
          if (content.contains('list') || 
              content.contains('plan') || 
              content.contains('create') ||
              content.contains('collaborate') ||
              content.contains('together')) {
            hasPlanningKeywords = true;
            break;
          }
        }
        
        if (hasPlanningKeywords) {
          totalPlanningSessions++;
          totalSessionDuration += chat.duration.inMinutes.toDouble();
        }
        
        // Detect list creation (simplified - would check action history in production)
        // For now, estimate based on chat characteristics
        final groupSize = chat.participants.length;
        final isGroupChat = groupSize >= 3;
        
        // Estimate list creation probability based on chat depth and planning keywords
        final listCreationProbability = hasPlanningKeywords && chat.messages.length >= 3 ? 0.3 : 0.0;
        
        if (listCreationProbability > 0.1) {
          totalCollaborativeLists++;
          
          // Categorize by group size
          groupSizes[groupSize] = (groupSizes[groupSize] ?? 0) + 1;
          
          if (isGroupChat) {
            groupChatLists++;
          } else {
            dmLists++;
          }
          
          // Track activity by hour
          final hour = chat.timestamp.hour;
          activityByHour[hour] = (activityByHour[hour] ?? 0) + 1;
          
          // Estimate follow-through (lists with spots added)
          if (chat.messages.length >= 5) {
            listsWithSpots++;
          }
          
          // Estimate time delta (simplified)
          timeDeltas.add(Duration(minutes: 5)); // Placeholder
        }
      }
      
      if (totalCollaborativeLists == 0) {
        return CollaborativeActivityMetrics.empty();
      }
      
      // Calculate metrics
      final collaborationRate = totalCollaborativeLists / chats.length;
      final avgSessionDuration = totalPlanningSessions > 0 
          ? totalSessionDuration / totalPlanningSessions 
          : 0.0;
      final followThroughRate = totalCollaborativeLists > 0
          ? listsWithSpots / totalCollaborativeLists
          : 0.0;
      
      // Estimate average list size and collaborator count (simplified)
      final avgListSize = 8.3; // Placeholder - would calculate from actual lists
      final avgCollaboratorCount = groupSizes.entries
          .map((e) => e.key * e.value)
          .fold(0, (sum, val) => sum + val) / 
          totalCollaborativeLists;
      
      return CollaborativeActivityMetrics(
        totalCollaborativeLists: totalCollaborativeLists,
        groupChatLists: groupChatLists,
        dmLists: dmLists,
        avgListSize: avgListSize,
        avgCollaboratorCount: avgCollaboratorCount,
        groupSizeDistribution: groupSizes,
        collaborationRate: collaborationRate,
        totalPlanningSessions: totalPlanningSessions,
        avgSessionDuration: avgSessionDuration,
        followThroughRate: followThroughRate,
        activityByHour: activityByHour,
        collectionStart: chats.isNotEmpty 
            ? chats.map((c) => c.timestamp).reduce((a, b) => a.isBefore(b) ? a : b)
            : DateTime.now(),
        lastUpdated: DateTime.now(),
        measurementWindow: chats.isNotEmpty
            ? chats.map((c) => c.timestamp).reduce((a, b) => a.isAfter(b) ? a : b)
                .difference(chats.map((c) => c.timestamp).reduce((a, b) => a.isBefore(b) ? a : b))
            : Duration.zero,
        totalUsersContributing: 1, // Count only, no IDs
        containsUserData: false,
        isAnonymized: true,
      );
    } catch (e) {
      developer.log('Error analyzing collaborative activity: $e', name: _logName);
      return CollaborativeActivityMetrics.empty();
    }
  }
}

// Supporting classes for AI2AI chat learning
class AI2AIChatEvent {
  final String eventId;
  final List<String> participants;
  final List<ChatMessage> messages;
  final ChatMessageType messageType;
  final DateTime timestamp;
  final Duration duration;
  final Map<String, dynamic> metadata;
  
  AI2AIChatEvent({
    required this.eventId,
    required this.participants,
    required this.messages,
    required this.messageType,
    required this.timestamp,
    required this.duration,
    required this.metadata,
  });
}

class ChatMessage {
  final String senderId;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic> context;
  
  ChatMessage({
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.context,
  });
}

enum ChatMessageType { personalitySharing, experienceSharing, insightExchange, trustBuilding }

class AI2AIChatAnalysisResult {
  final String localUserId;
  final AI2AIChatEvent chatEvent;
  final ConversationPatterns conversationPatterns;
  final List<SharedInsight> sharedInsights;
  final List<AI2AILearningOpportunity> learningOpportunities;
  final CollectiveIntelligence collectiveIntelligence;
  final List<PersonalityEvolutionRecommendation> evolutionRecommendations;
  final TrustMetrics trustMetrics;
  final DateTime analysisTimestamp;
  final double analysisConfidence;
  
  AI2AIChatAnalysisResult({
    required this.localUserId,
    required this.chatEvent,
    required this.conversationPatterns,
    required this.sharedInsights,
    required this.learningOpportunities,
    required this.collectiveIntelligence,
    required this.evolutionRecommendations,
    required this.trustMetrics,
    required this.analysisTimestamp,
    required this.analysisConfidence,
  });
  
  static AI2AIChatAnalysisResult fallback(String userId, AI2AIChatEvent chatEvent) {
    return AI2AIChatAnalysisResult(
      localUserId: userId,
      chatEvent: chatEvent,
      conversationPatterns: ConversationPatterns.empty(),
      sharedInsights: [],
      learningOpportunities: [],
      collectiveIntelligence: CollectiveIntelligence.empty(),
      evolutionRecommendations: [],
      trustMetrics: TrustMetrics.empty(),
      analysisTimestamp: DateTime.now(),
      analysisConfidence: 0.0,
    );
  }
}

// Additional supporting classes
class ConversationPatterns {
  final double exchangeFrequency;
  final double responseLatency;
  final double conversationDepth;
  final double topicConsistency;
  final double patternStrength;
  
  ConversationPatterns({
    required this.exchangeFrequency,
    required this.responseLatency,
    required this.conversationDepth,
    required this.topicConsistency,
    required this.patternStrength,
  });
  
  static ConversationPatterns empty() {
    return ConversationPatterns(
      exchangeFrequency: 0.0,
      responseLatency: 0.0,
      conversationDepth: 0.0,
      topicConsistency: 0.0,
      patternStrength: 0.0,
    );
  }
}

class SharedInsight {
  final String category;
  final String dimension;
  final double value;
  final String description;
  final double reliability;
  final DateTime timestamp;
  
  SharedInsight({
    required this.category,
    required this.dimension,
    required this.value,
    required this.description,
    required this.reliability,
    required this.timestamp,
  });
}

class CollectiveIntelligence {
  final double individualContribution;
  final double insightQuality;
  final double networkEffect;
  final double knowledgeSynergy;
  final double emergenceScore;
  
  CollectiveIntelligence({
    required this.individualContribution,
    required this.insightQuality,
    required this.networkEffect,
    required this.knowledgeSynergy,
    required this.emergenceScore,
  });
  
  static CollectiveIntelligence empty() {
    return CollectiveIntelligence(
      individualContribution: 0.0,
      insightQuality: 0.0,
      networkEffect: 0.0,
      knowledgeSynergy: 0.0,
      emergenceScore: 0.0,
    );
  }
}

class PersonalityEvolutionRecommendation {
  final String dimension;
  final String direction;
  final double magnitude;
  final double confidence;
  final String reasoning;
  
  PersonalityEvolutionRecommendation({
    required this.dimension,
    required this.direction,
    required this.magnitude,
    required this.confidence,
    required this.reasoning,
  });
}

class TrustMetrics {
  final double trustBuilding;
  final double trustEvolution;
  final double communicationQuality;
  final double mutualBenefit;
  final double overallTrust;
  
  TrustMetrics({
    required this.trustBuilding,
    required this.trustEvolution,
    required this.communicationQuality,
    required this.mutualBenefit,
    required this.overallTrust,
  });
  
  static TrustMetrics empty() {
    return TrustMetrics(
      trustBuilding: 0.0,
      trustEvolution: 0.0,
      communicationQuality: 0.0,
      mutualBenefit: 0.0,
      overallTrust: 0.0,
    );
  }
}

class CollectiveKnowledge {
  final String communityId;
  final List<SharedInsight> aggregatedInsights;
  final List<EmergingPattern> emergingPatterns;
  final Map<String, dynamic> consensusKnowledge;
  final List<CommunityTrend> communityTrends;
  final Map<String, double> reliabilityScores;
  final int contributingChats;
  final double knowledgeDepth;
  final DateTime lastUpdated;
  
  CollectiveKnowledge({
    required this.communityId,
    required this.aggregatedInsights,
    required this.emergingPatterns,
    required this.consensusKnowledge,
    required this.communityTrends,
    required this.reliabilityScores,
    required this.contributingChats,
    required this.knowledgeDepth,
    required this.lastUpdated,
  });
  
  static CollectiveKnowledge insufficient() {
    return CollectiveKnowledge(
      communityId: '',
      aggregatedInsights: [],
      emergingPatterns: [],
      consensusKnowledge: {},
      communityTrends: [],
      reliabilityScores: {},
      contributingChats: 0,
      knowledgeDepth: 0.0,
      lastUpdated: DateTime.now(),
    );
  }
}

class CrossPersonalityLearningPattern {
  final String patternType;
  final Map<String, dynamic> characteristics;
  final double strength;
  final double confidence;
  final DateTime identified;
  
  CrossPersonalityLearningPattern({
    required this.patternType,
    required this.characteristics,
    required this.strength,
    required this.confidence,
    required this.identified,
  });
}

class AI2AILearningRecommendations {
  final String userId;
  final List<OptimalPartner> optimalPartners;
  final List<LearningTopic> learningTopics;
  final List<DevelopmentArea> developmentAreas;
  final InteractionStrategy interactionStrategy;
  final List<ExpectedOutcome> expectedOutcomes;
  final double confidenceScore;
  final DateTime generatedAt;
  
  AI2AILearningRecommendations({
    required this.userId,
    required this.optimalPartners,
    required this.learningTopics,
    required this.developmentAreas,
    required this.interactionStrategy,
    required this.expectedOutcomes,
    required this.confidenceScore,
    required this.generatedAt,
  });
  
  static AI2AILearningRecommendations empty(String userId) {
    return AI2AILearningRecommendations(
      userId: userId,
      optimalPartners: [],
      learningTopics: [],
      developmentAreas: [],
      interactionStrategy: InteractionStrategy.balanced(),
      expectedOutcomes: [],
      confidenceScore: 0.0,
      generatedAt: DateTime.now(),
    );
  }
}

class LearningEffectivenessMetrics {
  final String userId;
  final Duration timeWindow;
  final double evolutionRate;
  final double knowledgeAcquisition;
  final double insightQuality;
  final double trustNetworkGrowth;
  final double collectiveContribution;
  final int totalInteractions;
  final double overallEffectiveness;
  final DateTime measuredAt;
  
  LearningEffectivenessMetrics({
    required this.userId,
    required this.timeWindow,
    required this.evolutionRate,
    required this.knowledgeAcquisition,
    required this.insightQuality,
    required this.trustNetworkGrowth,
    required this.collectiveContribution,
    required this.totalInteractions,
    required this.overallEffectiveness,
    required this.measuredAt,
  });
  
  static LearningEffectivenessMetrics zero(String userId, Duration timeWindow) {
    return LearningEffectivenessMetrics(
      userId: userId,
      timeWindow: timeWindow,
      evolutionRate: 0.0,
      knowledgeAcquisition: 0.0,
      insightQuality: 0.0,
      trustNetworkGrowth: 0.0,
      collectiveContribution: 0.0,
      totalInteractions: 0,
      overallEffectiveness: 0.0,
      measuredAt: DateTime.now(),
    );
  }
}

// Placeholder classes for complex data structures
class EmergingPattern {
  final String pattern;
  final double strength;
  EmergingPattern(this.pattern, this.strength);
}

class CommunityTrend {
  final String trend;
  final double direction;
  CommunityTrend(this.trend, this.direction);
}

class CrossPersonalityInsight {
  final String insight;
  final double value;
  final double reliability;
  final String type;
  final DateTime timestamp;
  
  CrossPersonalityInsight({
    required this.insight,
    required this.value,
    required this.reliability,
    required this.type,
    required this.timestamp,
  });
}

class OptimalPartner {
  final String archetype;
  final double compatibility;
  OptimalPartner(this.archetype, this.compatibility);
}

class LearningTopic {
  final String topic;
  final double potential;
  LearningTopic(this.topic, this.potential);
}

class DevelopmentArea {
  final String area;
  final double priority;
  DevelopmentArea(this.area, this.priority);
}

class InteractionStrategy {
  final String strategy;
  final Map<String, dynamic> parameters;
  InteractionStrategy(this.strategy, this.parameters);
  
  static InteractionStrategy balanced() => InteractionStrategy('balanced', {});
}

class AI2AILearningOpportunity {
  final String area;
  final String description;
  final double potential;
  
  AI2AILearningOpportunity({
    required this.area,
    required this.description,
    required this.potential,
  });
}

