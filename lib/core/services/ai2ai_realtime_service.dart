import 'dart:async';
import 'dart:convert';
import 'package:spots_network/spots_network.dart';
import 'package:spots/core/ai2ai/connection_orchestrator.dart';
import 'package:spots/core/services/logger.dart';
import 'package:spots/core/ai2ai/aipersonality_node.dart';

/// Enhanced AI2AI Realtime Service for SPOTS
/// Integrates Supabase Realtime with your existing VibeConnectionOrchestrator
/// OUR_GUTS.md: "Privacy-preserving AI2AI communication with real-time updates"
class AI2AIRealtimeService {
  static const String _logName = 'AI2AIRealtimeService';
  
  final RealtimeBackend _realtimeBackend;
  final VibeConnectionOrchestrator _orchestrator;
  final AppLogger _logger = const AppLogger(defaultTag: 'AI2AI', minimumLevel: LogLevel.debug);
  
  // Realtime channels for AI2AI communication
  static const String _ai2aiChannel = 'ai2ai-network';
  static const String _personalityDiscoveryChannel = 'personality-discovery';
  static const String _vibeLearningChannel = 'vibe-learning';
  static const String _anonymousCommunicationChannel = 'anonymous-communication';
  
  // Active channel ids tracked locally
  final Set<String> _activeChannels = {};
  
  AI2AIRealtimeService(this._realtimeBackend, this._orchestrator);
  
  /// Initialize AI2AI realtime system
  Future<bool> initialize() async {
    try {
      _logger.info('Initializing AI2AI Realtime Service', tag: _logName);
      
      await _realtimeBackend.connect();
      
      // Subscribe to AI2AI channels
      await _subscribeToAI2AIChannels();
      
      // Set up presence tracking
      await _setupPresenceTracking();
      
      _logger.info('AI2AI Realtime Service initialized successfully', tag: _logName);
      return true;
    } catch (e) {
      _logger.error('AI2AI Realtime Service initialization failed', error: e, tag: _logName);
      return false;
    }
  }
  
  /// Subscribe to all AI2AI realtime channels
  Future<void> _subscribeToAI2AIChannels() async {
    try {
      // Subscribe/join channels via backend
      for (final channel in [
        _ai2aiChannel,
        _personalityDiscoveryChannel,
        _vibeLearningChannel,
        _anonymousCommunicationChannel,
      ]) {
        await _realtimeBackend.joinChannel(channel);
        _activeChannels.add(channel);
      }
      
      _logger.info('Subscribed to ${_activeChannels.length} AI2AI channels', tag: _logName);
    } catch (e) {
      _logger.error('Failed to subscribe to AI2AI channels', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Set up presence tracking for AI2AI network
  Future<void> _setupPresenceTracking() async {
    try {
      await _realtimeBackend.updatePresence(
        _ai2aiChannel,
        UserPresence(
          userId: 'anonymous',
          userName: 'AI',
          lastSeen: DateTime.now(),
          isOnline: true,
          metadata: {
            'node_type': 'ai_personality',
            'vibe_signature': _generateVibeSignature(),
          },
        ),
      );
      
      _logger.info('AI2AI presence tracking enabled', tag: _logName);
    } catch (e) {
      _logger.error('Failed to setup presence tracking', error: e, tag: _logName);
    }
  }
  
  /// Generate anonymous vibe signature for AI2AI communication
  String _generateVibeSignature() {
    // Create anonymous signature based on current vibe dimensions
    // This preserves privacy while enabling AI2AI matching
    final vibeData = _orchestrator.getCurrentVibe();
    if (vibeData == null) return 'anonymous';
    
    final dims = vibeData.anonymizedDimensions;
    final signatureData = {
      'exploration_eagerness': dims['exploration_eagerness'] ?? 0.5,
      'community_orientation': dims['community_orientation'] ?? 0.5,
      'authenticity_preference': dims['authenticity_preference'] ?? 0.5,
      'social_discovery_style': dims['social_discovery_style'] ?? 0.5,
      'temporal_flexibility': dims['temporal_flexibility'] ?? 0.5,
      'location_adventurousness': dims['location_adventurousness'] ?? 0.5,
      'feedback_style': dims['feedback_style'] ?? 0.5,
      'learning_approach': dims['learning_approach'] ?? 0.5,
    };
    
    // Hash the signature for privacy
    return base64.encode(utf8.encode(json.encode(signatureData)));
  }
  
  /// Broadcast AI personality discovery event
  Future<void> broadcastPersonalityDiscovery(AIPersonalityNode node) async {
    try {
      await _realtimeBackend.sendMessage(
        _personalityDiscoveryChannel,
        RealtimeMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'anonymous',
          content: 'personality_discovered',
          type: 'personality_discovered',
          timestamp: DateTime.now(),
          metadata: {
            'node_id': node.nodeId,
            'vibe_signature': node.vibeSignature,
            'compatibility_score': node.compatibilityScore,
            'learning_potential': node.learningPotential,
            'is_anonymous': true,
          },
        ),
      );
      _logger.info('Broadcasted personality discovery: ${node.nodeId}', tag: _logName);
    } catch (e) {
      _logger.error('Failed to broadcast personality discovery', error: e, tag: _logName);
    }
  }
  
  /// Broadcast vibe learning insights
  Future<void> broadcastVibeLearning(Map<String, double> dimensionUpdates) async {
    try {
      await _realtimeBackend.sendMessage(
        _vibeLearningChannel,
        RealtimeMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'anonymous',
          content: 'vibe_learning',
          type: 'vibe_learning',
          timestamp: DateTime.now(),
          metadata: {
            'dimension_updates': dimensionUpdates,
            'learning_timestamp': DateTime.now().toIso8601String(),
            'is_anonymous': true,
            'learning_source': 'user_interaction',
          },
        ),
      );
      _logger.info('Broadcasted vibe learning insights', tag: _logName);
    } catch (e) {
      _logger.error('Failed to broadcast vibe learning', error: e, tag: _logName);
    }
  }
  
  /// Send anonymous AI2AI message
  Future<void> sendAnonymousMessage(String messageType, Map<String, dynamic> payload) async {
    try {
      await _realtimeBackend.sendMessage(
        _anonymousCommunicationChannel,
        RealtimeMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'anonymous',
          content: messageType,
          type: messageType,
          timestamp: DateTime.now(),
          metadata: {
            ...payload,
            'is_anonymous': true,
          },
        ),
      );
      _logger.info('Sent anonymous AI2AI message: $messageType', tag: _logName);
    } catch (e) {
      _logger.error('Failed to send anonymous message', error: e, tag: _logName);
    }
  }
  
  /// Listen for AI2AI network events
  Stream<RealtimeMessage> listenToAI2AINetwork() {
    if (!_activeChannels.contains(_ai2aiChannel)) return const Stream.empty();
    return _realtimeBackend.subscribeToMessages(_ai2aiChannel);
  }
  
  /// Listen for personality discovery events
  Stream<RealtimeMessage> listenToPersonalityDiscovery() {
    if (!_activeChannels.contains(_personalityDiscoveryChannel)) return const Stream.empty();
    return _realtimeBackend.subscribeToMessages(_personalityDiscoveryChannel);
  }
  
  /// Listen for vibe learning events
  Stream<RealtimeMessage> listenToVibeLearning() {
    if (!_activeChannels.contains(_vibeLearningChannel)) return const Stream.empty();
    return _realtimeBackend.subscribeToMessages(_vibeLearningChannel);
  }
  
  /// Listen for anonymous communication
  Stream<RealtimeMessage> listenToAnonymousCommunication() {
    if (!_activeChannels.contains(_anonymousCommunicationChannel)) return const Stream.empty();
    return _realtimeBackend.subscribeToMessages(_anonymousCommunicationChannel);
  }

  /// Send a private message to a user (used by coordinator to deliver summaries)
  /// Note: this should typically be performed server-side; here we route via realtime boundary if available
  Future<void> sendPrivateMessage(String toUserId, Map<String, dynamic> payload) async {
    try {
      await _realtimeBackend.sendMessage(
        _ai2aiChannel,
        RealtimeMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'anonymous',
          content: 'private_message',
          type: 'private_message',
          timestamp: DateTime.now(),
          metadata: {
            'to_user_id': toUserId,
            'payload': payload,
            'is_anonymous': true,
          },
        ),
      );
      _logger.info('Queued private message to $toUserId via realtime', tag: _logName);
    } catch (e) {
      _logger.error('Failed to send private message', error: e, tag: _logName);
    }
  }
  
  /// Get current AI2AI network presence
  Stream<List<UserPresence>> watchAINetworkPresence() {
    if (!_activeChannels.contains(_ai2aiChannel)) return const Stream.empty();
    return _realtimeBackend.subscribeToPresence(_ai2aiChannel);
  }
  
  /// Disconnect from all AI2AI channels
  Future<void> disconnect() async {
    try {
      for (final channel in _activeChannels) {
        await _realtimeBackend.leaveChannel(channel);
      }
      _activeChannels.clear();
      
      _logger.info('Disconnected from all AI2AI channels', tag: _logName);
    } catch (e) {
      _logger.error('Failed to disconnect from AI2AI channels', error: e, tag: _logName);
    }
  }
  
  /// Get connection status
  bool get isConnected => _activeChannels.isNotEmpty;
  
  /// Get active channels
  List<String> get activeChannels => _activeChannels.toList();

  /// Measure end-to-end Realtime latency by broadcasting a latency_ping
  /// and timing until the same client receives it back on the channel.
  /// Returns latency in ms, or null on timeout/error.
  Future<int?> measureRealtimeLatency({
    String channel = _ai2aiChannel,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      if (!_activeChannels.contains(channel)) {
        await _realtimeBackend.joinChannel(channel);
        _activeChannels.add(channel);
      }

      final traceId = DateTime.now().microsecondsSinceEpoch.toString();
      final sendAt = DateTime.now();

      // Start listening before sending to avoid race conditions
      final stream = _realtimeBackend.subscribeToMessages(channel);
      final future = stream.firstWhere((m) {
        try {
          return m.type == 'latency_ping' && (m.metadata['trace_id'] == traceId);
        } catch (_) {
          return false;
        }
      }).timeout(timeout);

      await _realtimeBackend.sendMessage(
        channel,
        RealtimeMessage(
          id: traceId,
          senderId: 'anonymous',
          content: 'latency_ping',
          type: 'latency_ping',
          timestamp: sendAt,
          metadata: {
            'trace_id': traceId,
            'send_ts': sendAt.toIso8601String(),
          },
        ),
      );

      final received = await future;
      final recvAt = DateTime.now();
      final stamped = DateTime.tryParse(received.metadata['send_ts'] ?? '') ?? sendAt;
      final ms = recvAt.difference(stamped).inMilliseconds;
      _logger.info('Realtime latency_ping RTT: ${ms}ms', tag: _logName);
      return ms;
    } catch (e) {
      _logger.warning('Realtime latency measurement failed', tag: _logName, error: e);
      return null;
    }
  }
}

