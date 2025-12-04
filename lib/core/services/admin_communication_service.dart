import 'package:spots/core/monitoring/connection_monitor.dart';
import 'package:spots/core/ai/ai2ai_learning.dart';
import 'package:spots/core/models/connection_metrics.dart';
import 'package:spots/core/services/logger.dart';

/// Service for admin access to AI2AI communication logs
/// Provides aggregated view of all AI-to-AI interactions
class AdminCommunicationService {
  static const String _logName = 'AdminCommunicationService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );
  
  final ConnectionMonitor _connectionMonitor;
  final AI2AIChatAnalyzer? _chatAnalyzer;
  
  AdminCommunicationService({
    required ConnectionMonitor connectionMonitor,
    AI2AIChatAnalyzer? chatAnalyzer,
  })  : _connectionMonitor = connectionMonitor,
        _chatAnalyzer = chatAnalyzer;
  
  /// Get all communication logs for a specific connection
  Future<ConnectionCommunicationLog> getConnectionLog(String connectionId) async {
    try {
      _logger.info('Fetching communication log for connection: $connectionId', tag: _logName);
      
      // Get connection status and metrics
      final status = await _connectionMonitor.getConnectionStatus(connectionId);
      
      // Get monitoring session for full details
      final session = _connectionMonitor.getMonitoringSession(connectionId);
      
      // Extract AI signatures from session
      String localSig = session?.localAISignature ?? 'local_${connectionId.substring(0, 8)}';
      String remoteSig = session?.remoteAISignature ?? 'remote_${connectionId.substring(0, 8)}';
      
      // Get interaction history from session
      List<InteractionEvent> interactionHistory = session?.interactionHistory ?? [];
      
      // Get chat history if available
      List<AI2AIChatEvent> chatEvents = [];
      if (_chatAnalyzer != null) {
        // Get all chat history and filter by connection participants
        final allChatHistory = _chatAnalyzer!.getAllChatHistoryForAdmin();
        for (final userChats in allChatHistory.values) {
          // Filter to events that involve this connection
          final relevantChats = userChats.where((event) {
            // Check if connection ID appears in participants or event metadata
            return event.participants.any((p) => 
              p.contains(connectionId.substring(0, 8)) || 
              connectionId.contains(p.substring(0, 8)) ||
              p == localSig || p == remoteSig
            ) || event.metadata.containsKey('connection_id') &&
                event.metadata['connection_id'] == connectionId;
          }).toList();
          chatEvents.addAll(relevantChats);
        }
        // Sort by timestamp
        chatEvents.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      
      return ConnectionCommunicationLog(
        connectionId: connectionId,
        localAISignature: localSig,
        remoteAISignature: remoteSig,
        startTime: status.monitoringDuration.inSeconds > 0 
            ? DateTime.now().subtract(status.monitoringDuration)
            : DateTime.now(),
        chatEvents: chatEvents,
        interactionHistory: interactionHistory,
        metrics: status.currentPerformance.performance,
        healthScore: status.healthScore,
        recentAlerts: status.recentAlerts,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error fetching connection log: $connectionId',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return ConnectionCommunicationLog.empty(connectionId);
    }
  }
  
  /// Get all active connections with their communication summaries
  Future<List<ConnectionCommunicationSummary>> getAllConnectionSummaries() async {
    try {
      _logger.info('Fetching all connection summaries', tag: _logName);
      
      final overview = await _connectionMonitor.getActiveConnectionsOverview();
      final summaries = <ConnectionCommunicationSummary>[];
      
      // Get summaries for all active connections
      for (final connectionId in overview.topPerformingConnections) {
        final log = await getConnectionLog(connectionId);
        summaries.add(ConnectionCommunicationSummary.fromLog(log));
      }
      
      for (final connectionId in overview.connectionsNeedingAttention) {
        final log = await getConnectionLog(connectionId);
        summaries.add(ConnectionCommunicationSummary.fromLog(log));
      }
      
      return summaries;
    } catch (e, stackTrace) {
      _logger.error(
        'Error fetching connection summaries',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return [];
    }
  }
  
  /// Search communication logs by connection ID, AI signature, or time range
  Future<List<ConnectionCommunicationLog>> searchLogs({
    String? connectionId,
    String? aiSignature,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final summaries = await getAllConnectionSummaries();
      final matchingLogs = <ConnectionCommunicationLog>[];
      
      for (final summary in summaries) {
        // Filter by connection ID
        if (connectionId != null && !summary.connectionId.contains(connectionId)) {
          continue;
        }
        
        // Filter by AI signature
        if (aiSignature != null && 
            !summary.localAISignature.contains(aiSignature) &&
            !summary.remoteAISignature.contains(aiSignature)) {
          continue;
        }
        
        // Filter by time range
        if (startTime != null && summary.startTime.isBefore(startTime)) {
          continue;
        }
        if (endTime != null && summary.startTime.isAfter(endTime)) {
          continue;
        }
        
        final log = await getConnectionLog(summary.connectionId);
        matchingLogs.add(log);
      }
      
      return matchingLogs;
    } catch (e, stackTrace) {
      _logger.error(
        'Error searching logs',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return [];
    }
  }
}

/// Communication log for a single connection
class ConnectionCommunicationLog {
  final String connectionId;
  final String localAISignature;
  final String remoteAISignature;
  final DateTime startTime;
  final List<AI2AIChatEvent> chatEvents;
  final List<InteractionEvent> interactionHistory;
  final double metrics;
  final double healthScore;
  final List<ConnectionAlert> recentAlerts;
  
  ConnectionCommunicationLog({
    required this.connectionId,
    required this.localAISignature,
    required this.remoteAISignature,
    required this.startTime,
    required this.chatEvents,
    required this.interactionHistory,
    required this.metrics,
    required this.healthScore,
    required this.recentAlerts,
  });
  
  factory ConnectionCommunicationLog.empty(String connectionId) {
    return ConnectionCommunicationLog(
      connectionId: connectionId,
      localAISignature: 'unknown',
      remoteAISignature: 'unknown',
      startTime: DateTime.now(),
      chatEvents: [],
      interactionHistory: [],
      metrics: 0.0,
      healthScore: 0.0,
      recentAlerts: [],
    );
  }
  
  int get totalMessages => chatEvents.fold(0, (sum, event) => sum + event.messages.length);
  
  Duration get duration => DateTime.now().difference(startTime);
  
  bool get hasChatHistory => chatEvents.isNotEmpty;
  
  bool get hasInteractions => interactionHistory.isNotEmpty;
}

/// Summary of communication for quick viewing
class ConnectionCommunicationSummary {
  final String connectionId;
  final String localAISignature;
  final String remoteAISignature;
  final DateTime startTime;
  final int messageCount;
  final int interactionCount;
  final double healthScore;
  final String qualityRating;
  
  ConnectionCommunicationSummary({
    required this.connectionId,
    required this.localAISignature,
    required this.remoteAISignature,
    required this.startTime,
    required this.messageCount,
    required this.interactionCount,
    required this.healthScore,
    required this.qualityRating,
  });
  
  factory ConnectionCommunicationSummary.fromLog(ConnectionCommunicationLog log) {
    String qualityRating = 'unknown';
    if (log.healthScore >= 0.8) {
      qualityRating = 'excellent';
    } else if (log.healthScore >= 0.6) {
      qualityRating = 'good';
    } else if (log.healthScore >= 0.4) {
      qualityRating = 'fair';
    } else {
      qualityRating = 'poor';
    }
    
    return ConnectionCommunicationSummary(
      connectionId: log.connectionId,
      localAISignature: log.localAISignature.length > 12 
          ? log.localAISignature.substring(0, 12) 
          : log.localAISignature,
      remoteAISignature: log.remoteAISignature.length > 12
          ? log.remoteAISignature.substring(0, 12)
          : log.remoteAISignature,
      startTime: log.startTime,
      messageCount: log.totalMessages,
      interactionCount: log.interactionHistory.length,
      healthScore: log.healthScore,
      qualityRating: qualityRating,
    );
  }
}

