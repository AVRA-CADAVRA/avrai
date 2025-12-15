import 'package:flutter/material.dart';
import 'package:spots/core/services/admin_communication_service.dart';
import 'package:spots/core/monitoring/connection_monitor.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/ai/ai2ai_learning.dart';
import 'package:spots/core/models/connection_metrics.dart' hide ChatMessage;
import 'package:spots/core/services/storage_service.dart' show SharedPreferencesCompat;
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

/// Admin page showing detailed communication log between two AIs
class ConnectionCommunicationDetailPage extends StatefulWidget {
  final String connectionId;
  
  const ConnectionCommunicationDetailPage({
    super.key,
    required this.connectionId,
  });

  @override
  State<ConnectionCommunicationDetailPage> createState() => _ConnectionCommunicationDetailPageState();
}

class _ConnectionCommunicationDetailPageState extends State<ConnectionCommunicationDetailPage> {
  AdminCommunicationService? _communicationService;
  ConnectionCommunicationLog? _log;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadCommunicationLog();
  }

  Future<void> _initializeService() async {
    try {
      final prefs = GetIt.instance<SharedPreferencesCompat>();
      final connectionMonitor = ConnectionMonitor(prefs: prefs);
      // Try to get AI2AIChatAnalyzer from GetIt if available
      AI2AIChatAnalyzer? chatAnalyzer;
      try {
        // Note: This assumes AI2AIChatAnalyzer is registered in GetIt
        // If not, it will be null and chat history won't be available
        chatAnalyzer = GetIt.instance<AI2AIChatAnalyzer>();
      } catch (e) {
        // Not registered, continue without chat analyzer
        chatAnalyzer = null;
      }
      
      _communicationService = AdminCommunicationService(
        connectionMonitor: connectionMonitor,
        chatAnalyzer: chatAnalyzer,
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize service: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCommunicationLog() async {
    if (_communicationService == null) {
      await _initializeService();
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final log = await _communicationService!.getConnectionLog(widget.connectionId);
      setState(() {
        _log = log;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load communication log: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connection: ${widget.connectionId.length > 12 ? widget.connectionId.substring(0, 12) : widget.connectionId}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCommunicationLog,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.error,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCommunicationLog,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _log == null
                  ? const Center(child: Text('No communication log found'))
                  : RefreshIndicator(
                      onRefresh: _loadCommunicationLog,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildConnectionHeader(context),
                            const SizedBox(height: 24),
                            _buildMetricsSection(context),
                            const SizedBox(height: 24),
                            _buildChatHistorySection(context),
                            const SizedBox(height: 24),
                            _buildInteractionHistorySection(context),
                            const SizedBox(height: 24),
                            _buildAlertsSection(context),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildConnectionHeader(BuildContext context) {
    if (_log == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Local AI', _log!.localAISignature),
            _buildInfoRow('Remote AI', _log!.remoteAISignature),
            _buildInfoRow('Started', DateFormat('MMM d, y HH:mm:ss').format(_log!.startTime)),
            _buildInfoRow('Duration', _formatDuration(_log!.duration)),
            _buildInfoRow('Health Score', '${(_log!.healthScore * 100).toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection(BuildContext context) {
    if (_log == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Communication Metrics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCard('Messages', '${_log!.totalMessages}', Icons.message),
                _buildMetricCard('Interactions', '${_log!.interactionHistory.length}', Icons.swap_horiz),
                _buildMetricCard('Chat Events', '${_log!.chatEvents.length}', Icons.chat_bubble_outline),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppTheme.primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildChatHistorySection(BuildContext context) {
    if (_log == null || _log!.chatEvents.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 8),
              Text(
                'No chat history available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Chat conversations will appear here when AIs communicate',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chat History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Chip(
                  label: Text('${_log!.chatEvents.length} events'),
                  backgroundColor: AppColors.grey100,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._log!.chatEvents.map((event) => _buildChatEventCard(context, event)),
          ],
        ),
      ),
    );
  }

  Widget _buildChatEventCard(BuildContext context, AI2AIChatEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.grey50,
      child: ExpansionTile(
        title: Text(
          'Chat Event: ${event.messageType.name}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${event.messages.length} messages • ${DateFormat('MMM d, HH:mm').format(event.timestamp)}',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Event ID', event.eventId),
                _buildInfoRow('Participants', event.participants.join(', ')),
                _buildInfoRow('Duration', _formatDuration(event.duration)),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Messages',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...event.messages.map((message) => _buildMessageBubble(context, message)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final isLocal = message.senderId == _log!.localAISignature;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLocal ? AppTheme.primaryColor.withValues(alpha: 0.1) : AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isLocal ? 'Local AI' : 'Remote AI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isLocal ? AppTheme.primaryColor : AppColors.textSecondary,
                ),
              ),
              Text(
                DateFormat('HH:mm:ss').format(message.timestamp),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message.content,
            style: const TextStyle(fontSize: 14),
          ),
          if (message.context.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Context: ${message.context.toString()}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInteractionHistorySection(BuildContext context) {
    if (_log == null || _log!.interactionHistory.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.swap_horiz, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 8),
              Text(
                'No interaction history',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interaction History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ..._log!.interactionHistory.map((interaction) => _buildInteractionTile(context, interaction)),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionTile(BuildContext context, InteractionEvent interaction) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(
        _getInteractionIcon(interaction.type),
        color: AppTheme.primaryColor,
      ),
      title: Text(interaction.type.name),
      subtitle: Text(
        DateFormat('MMM d, HH:mm:ss').format(interaction.timestamp),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: interaction.successful
          ? const Icon(Icons.check_circle, color: AppColors.success, size: 20)
          : const Icon(Icons.error, color: AppColors.error, size: 20),
    );
  }

  Widget _buildAlertsSection(BuildContext context) {
    if (_log == null || _log!.recentAlerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      color: AppColors.warning.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(
                  'Recent Alerts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._log!.recentAlerts.map((alert) => _buildAlertTile(context, alert)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTile(BuildContext context, ConnectionAlert alert) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(
        _getAlertIcon(alert.severity),
        color: _getAlertColor(alert.severity),
      ),
      title: Text(alert.message),
      subtitle: Text(
        '${alert.type.name} • ${DateFormat('MMM d, HH:mm').format(alert.timestamp)}',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  IconData _getInteractionIcon(InteractionType type) {
    switch (type) {
      case InteractionType.vibeExchange:
        return Icons.swap_horiz;
      case InteractionType.personalitySharing:
        return Icons.person;
      case InteractionType.learningInsight:
        return Icons.lightbulb;
      case InteractionType.dimensionEvolution:
        return Icons.trending_up;
      case InteractionType.patternDiscovery:
        return Icons.auto_awesome;
      case InteractionType.trustBuilding:
        return Icons.handshake;
      case InteractionType.feedbackSharing:
        return Icons.feedback;
      default:
        return Icons.info;
    }
  }

  IconData _getAlertIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Icons.error;
      case AlertSeverity.high:
        return Icons.warning;
      case AlertSeverity.medium:
        return Icons.info;
      case AlertSeverity.low:
        return Icons.info_outline;
    }
  }

  Color _getAlertColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return AppColors.error;
      case AlertSeverity.high:
        return AppColors.warning;
      case AlertSeverity.medium:
        return AppColors.grey600;
      case AlertSeverity.low:
        return AppColors.textSecondary;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

