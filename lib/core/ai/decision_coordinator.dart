// Decision Coordinator for Phase 11: User-AI Interaction Update
// Section 6: Decision Fabric
// Chooses optimal inference pathway in real-time based on context

import 'dart:async';
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avrai/core/ml/inference_orchestrator.dart';
import 'package:avrai/core/services/config_service.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/ai2ai/connection_orchestrator.dart';

/// Decision Coordinator
/// 
/// Chooses optimal inference pathway based on:
/// - Connectivity status (offline/online)
/// - Latency requirements (critical/normal)
/// - Context needs (narrative, social insights, etc.)
/// 
/// Phase 11 Section 6: Decision Fabric
class DecisionCoordinator {
  static const String _logName = 'DecisionCoordinator';
  
  final InferenceOrchestrator orchestrator;
  final Connectivity connectivity;
  final ConfigService config;
  
  DecisionCoordinator({
    required this.orchestrator,
    Connectivity? connectivity,
    required this.config,
  }) : connectivity = connectivity ?? Connectivity();
  
  /// Chooses optimal inference pathway based on context
  /// 
  /// [input] - Input data for inference
  /// [context] - Inference context (needs, requirements)
  /// 
  /// Returns InferenceResult from the chosen pathway
  Future<InferenceResult> coordinate({
    required Map<String, dynamic> input,
    required InferenceContext context,
  }) async {
    InferenceStrategy chosenStrategy = InferenceStrategy.deviceFirst;
    String decisionReason = '';
    
    try {
      developer.log('Coordinating inference pathway', name: _logName);
      
      // Check connectivity status
      final connectivityResults = await connectivity.checkConnectivity();
      final isOffline = connectivityResults.contains(ConnectivityResult.none);
      
      // Decision logic:
      // 1. Offline? → ONNX + Rules
      // 2. Online but latency critical? → Local scores + Cached recommendations
      // 3. Need rich narrative? → Gemini through LLM service (edge-prefetch)
      // 4. Need social/community insights? → Edge functions (edge-prefetch)
      // 5. Default: Device-first with Gemini fallback
      
      InferenceResult result;
      if (isOffline) {
        chosenStrategy = InferenceStrategy.deviceFirst;
        decisionReason = 'Offline: Using device-first strategy (ONNX + rules + AI2AI mesh)';
        developer.log(decisionReason, name: _logName);
        
        // Phase 11 Enhancement: Get offline mesh learning insights (works offline via Bluetooth)
        final meshInsights = await _getOfflineMeshInsights(input);
        if (meshInsights.isNotEmpty) {
          // Enhance input with mesh learning context
          input = {
            ...input,
            'ai2ai_mesh_insights': meshInsights,
            'source': 'offline_mesh',
          };
          
          developer.log(
            'Enhanced input with ${meshInsights.length} offline mesh insights',
            name: _logName,
          );
        }
        
        // Offline: Stick to ONNX + rules + mesh insights (no cloud access)
        result = await orchestrator.infer(
          input: input,
          strategy: chosenStrategy,
        );
      } else if (context.latencyCritical) {
        chosenStrategy = InferenceStrategy.deviceFirst; // Cached uses device-first
        decisionReason = 'Latency critical: Using cached recommendations';
        developer.log(decisionReason, name: _logName);
        // Latency critical: Local scores + cached
        result = await _getCachedRecommendations(input);
      } else if (context.needsNarrative || context.needsSocialInsights) {
        chosenStrategy = InferenceStrategy.edgePrefetch;
        decisionReason = 'Rich context needed: Using edge-prefetch strategy';
        developer.log(decisionReason, name: _logName);
        // Rich narrative or social insights: Gemini/Edge
        result = await orchestrator.infer(
          input: input,
          strategy: chosenStrategy,
        );
      } else {
        chosenStrategy = InferenceStrategy.deviceFirst;
        decisionReason = 'Default: Using device-first strategy with Gemini fallback';
        developer.log(decisionReason, name: _logName);
        // Default: Device-first with Gemini fallback
        result = await orchestrator.infer(
          input: input,
          strategy: chosenStrategy,
        );
      }
      
      // Log decision for tracking/analytics
      _logDecision(
        strategy: chosenStrategy,
        reason: decisionReason,
        context: context,
        resultSource: result.source,
        isOffline: isOffline,
      );
      
      return result;
    } catch (e, stackTrace) {
      developer.log(
        'Error in decision coordination: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Fallback to device-first on error
      final result = await orchestrator.infer(
        input: input,
        strategy: InferenceStrategy.deviceFirst,
      );
      
      // Log fallback decision
      _logDecision(
        strategy: InferenceStrategy.deviceFirst,
        reason: 'Error fallback: Using device-first strategy',
        context: context,
        resultSource: result.source,
        isOffline: false,
        error: e.toString(),
      );
      
      return result;
    }
  }
  
  /// Get offline mesh learning insights from AI2AI connections
  /// 
  /// Phase 11 Enhancement: Offline Mesh Learning
  /// This works offline because AI2AI mesh uses Bluetooth
  /// 
  /// Returns list of mesh insights (simplified format) to enhance input context
  Future<List<Map<String, dynamic>>> _getOfflineMeshInsights(
    Map<String, dynamic> input,
  ) async {
    try {
      // Try to get recent passive learning insights from ConnectionOrchestrator
      // Note: ConnectionOrchestrator may not expose this API yet - gracefully degrade
      if (GetIt.instance.isRegistered<VibeConnectionOrchestrator>()) {
        try {
          // TODO(Phase 11.8.4): Implement ConnectionOrchestrator.getRecentMeshInsights()
          // For now, return empty list - this can be enhanced when API is available
          // The orchestrator processes mesh insights internally, so we could expose them
          // through a getter method that returns recent insights without device IDs (privacy)
        } catch (e) {
          developer.log(
            'Error getting offline mesh insights: $e',
            name: _logName,
          );
        }
      }
      
      return [];
    } catch (e) {
      developer.log('Error getting offline mesh insights: $e', name: _logName);
      return [];
    }
  }

  /// Log decision for tracking and analytics
  /// 
  /// Phase 11 Section 6: Decision logging
  void _logDecision({
    required InferenceStrategy strategy,
    required String reason,
    required InferenceContext context,
    required InferenceSource resultSource,
    required bool isOffline,
    String? error,
  }) {
    developer.log(
      'Decision logged: strategy=${strategy.name}, reason=$reason, '
      'source=${resultSource.name}, offline=$isOffline, '
      'needsNarrative=${context.needsNarrative}, '
      'latencyCritical=${context.latencyCritical}, '
      'needsSocialInsights=${context.needsSocialInsights}'
      '${error != null ? ", error=$error" : ""}',
      name: _logName,
    );
    
    // TODO(Phase 11.6): Store decision logs in Supabase for analytics
    // This could be used for:
    // - Optimizing decision logic based on actual outcomes
    // - Understanding which strategies work best for different contexts
    // - Detecting patterns in decision-making
  }
  
  /// Get cached recommendations for low-latency responses
  /// 
  /// Returns inference result with cached data
  /// TODO(Phase 11.6): Implement caching strategy for recommendations
  Future<InferenceResult> _getCachedRecommendations(Map<String, dynamic> input) async {
    developer.log('Getting cached recommendations for low latency', name: _logName);
    
    // For now, return device-first result (fast, local)
    // Future: Implement actual caching strategy
    return await orchestrator.infer(
      input: input,
      strategy: InferenceStrategy.deviceFirst,
    );
  }
}

/// Inference Context
/// 
/// Context information that influences pathway selection
class InferenceContext {
  /// Whether a rich narrative response is needed (requires LLM)
  final bool needsNarrative;
  
  /// Whether latency is critical (requires fast, cached responses)
  final bool latencyCritical;
  
  /// Whether social/community insights are needed (requires edge functions)
  final bool needsSocialInsights;
  
  /// Additional user context data
  final Map<String, dynamic>? userContext;
  
  InferenceContext({
    this.needsNarrative = false,
    this.latencyCritical = false,
    this.needsSocialInsights = false,
    this.userContext,
  });
  
  /// Create context for narrative requests (chat, explanations)
  factory InferenceContext.narrative() {
    return InferenceContext(
      needsNarrative: true,
      latencyCritical: false,
      needsSocialInsights: false,
    );
  }
  
  /// Create context for low-latency requests (quick recommendations)
  factory InferenceContext.lowLatency() {
    return InferenceContext(
      needsNarrative: false,
      latencyCritical: true,
      needsSocialInsights: false,
    );
  }
  
  /// Create context for social/community requests (friend discovery, community insights)
  factory InferenceContext.social() {
    return InferenceContext(
      needsNarrative: false,
      latencyCritical: false,
      needsSocialInsights: true,
    );
  }
  
  /// Create context for comprehensive requests (narrative + social)
  factory InferenceContext.comprehensive() {
    return InferenceContext(
      needsNarrative: true,
      latencyCritical: false,
      needsSocialInsights: true,
    );
  }
}
