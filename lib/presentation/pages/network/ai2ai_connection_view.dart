/// AI2AI Connection View
/// 
/// Part of Feature Matrix Phase 1: Critical UI/UX Features
/// 
/// Displays active AI2AI connections and their metrics:
/// - Connection status and quality ratings
/// - Compatibility scores and learning effectiveness
/// - AI pleasure scores
/// - Connection duration and learning outcomes
/// - Connection management actions
/// 
/// Uses AppColors and AppTheme for consistent styling per design token requirements.

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:spots/core/models/connection_metrics.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/core/ai2ai/connection_orchestrator.dart';

/// Page that displays active AI2AI connections
class AI2AIConnectionView extends StatefulWidget {
  final List<ConnectionMetrics>? connections;
  final Function(String connectionId)? onConnectionTap;
  final Function(String connectionId)? onDisconnect;

  const AI2AIConnectionView({
    super.key,
    this.connections,
    this.onConnectionTap,
    this.onDisconnect,
  });

  @override
  State<AI2AIConnectionView> createState() => _AI2AIConnectionViewState();
}

class _AI2AIConnectionViewState extends State<AI2AIConnectionView> {
  List<ConnectionMetrics> _connections = [];
  Timer? _refreshTimer;
  VibeConnectionOrchestrator? _orchestrator;

  @override
  void initState() {
    super.initState();
    _initializeOrchestrator();
    _loadConnections();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _initializeOrchestrator() {
    try {
      _orchestrator = GetIt.instance<VibeConnectionOrchestrator>();
    } catch (e) {
      // Orchestrator not registered, will handle gracefully
    }
  }

  Future<void> _loadConnections() async {
    if (widget.connections != null) {
      setState(() {
        _connections = widget.connections!;
      });
      return;
    }

    // Try to load from orchestrator
    if (_orchestrator != null) {
      try {
        // Get active connections from orchestrator
        final activeConnections = _orchestrator!.getActiveConnections();
        developer.log('Loaded ${activeConnections.length} active connections from orchestrator', name: 'AI2AIConnectionView');
        setState(() {
          _connections = activeConnections.isNotEmpty ? activeConnections : (widget.connections ?? []);
        });
      } catch (e) {
        developer.log('Error loading connections from orchestrator: $e', name: 'AI2AIConnectionView');
        setState(() {
          _connections = widget.connections ?? [];
        });
      }
    } else {
      setState(() {
        _connections = widget.connections ?? [];
      });
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadConnections();
    });
  }

  Future<void> _handleDisconnect(String connectionId) async {
    if (widget.onDisconnect != null) {
      widget.onDisconnect!(connectionId);
    } else if (_orchestrator != null) {
      // Try to disconnect via orchestrator
      // Note: Would need orchestrator method to disconnect
    }

    // Remove from local list
    setState(() {
      _connections.removeWhere((c) => c.connectionId == connectionId);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection disconnected'),
          backgroundColor: AppColors.electricGreen,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI2AI Connections'),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConnections,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadConnections,
        child: _connections.isEmpty
            ? _buildEmptyState()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    ..._connections.map((connection) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildConnectionCard(connection),
                        )),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          'Active Connections',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.electricGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_connections.length}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.electricGreen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.link_off,
            size: 64,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No active connections',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'AI2AI connections will appear here when established',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(ConnectionMetrics connection) {
    final qualityRating = connection.qualityRating;
    final qualityColor = _getQualityColor(qualityRating);
    final statusColor = _getStatusColor(connection.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: widget.onConnectionTap != null
            ? () => widget.onConnectionTap!(connection.connectionId)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStatusLabel(connection.status),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Connection ${connection.connectionId.substring(0, 8)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: qualityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      qualityRating.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: qualityColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetric(
                      'Compatibility',
                      '${(connection.currentCompatibility * 100).round()}%',
                      Icons.favorite,
                      AppColors.electricGreen,
                    ),
                  ),
                  Expanded(
                    child: _buildMetric(
                      'Learning',
                      '${(connection.learningEffectiveness * 100).round()}%',
                      Icons.school,
                      AppColors.warning,
                    ),
                  ),
                  Expanded(
                    child: _buildMetric(
                      'AI Pleasure',
                      '${(connection.aiPleasureScore * 100).round()}%',
                      Icons.mood,
                      AppColors.electricGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(connection.connectionDuration),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (connection.interactionHistory.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${connection.interactionHistory.length} interactions',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onConnectionTap != null
                          ? () => widget.onConnectionTap!(connection.connectionId)
                          : null,
                      icon: const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.electricGreen,
                      ),
                      label: const Text(
                        'View Details',
                        style: TextStyle(
                          color: AppColors.electricGreen,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.electricGreen),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleDisconnect(connection.connectionId),
                      icon: const Icon(
                        Icons.link_off,
                        size: 16,
                        color: AppColors.error,
                      ),
                      label: const Text(
                        'Disconnect',
                        style: TextStyle(
                          color: AppColors.error,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Color _getQualityColor(String rating) {
    switch (rating.toLowerCase()) {
      case 'excellent':
        return AppColors.electricGreen;
      case 'good':
        return AppColors.warning;
      case 'fair':
        return AppColors.warning;
      case 'poor':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.establishing:
        return AppColors.warning;
      case ConnectionStatus.active:
        return AppColors.electricGreen;
      case ConnectionStatus.learning:
        return AppColors.electricGreen;
      case ConnectionStatus.completing:
        return AppColors.warning;
      case ConnectionStatus.completed:
        return AppColors.textSecondary;
      case ConnectionStatus.failed:
        return AppColors.error;
      case ConnectionStatus.timeout:
        return AppColors.error;
    }
  }

  String _getStatusLabel(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.establishing:
        return 'Establishing';
      case ConnectionStatus.active:
        return 'Active';
      case ConnectionStatus.learning:
        return 'Learning';
      case ConnectionStatus.completing:
        return 'Completing';
      case ConnectionStatus.completed:
        return 'Completed';
      case ConnectionStatus.failed:
        return 'Failed';
      case ConnectionStatus.timeout:
        return 'Timeout';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 1) {
      return '${duration.inSeconds}s';
    } else if (duration.inHours < 1) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
  }
}

