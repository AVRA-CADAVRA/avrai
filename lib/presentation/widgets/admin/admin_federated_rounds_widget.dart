import 'dart:async';
import 'package:flutter/material.dart';
import 'package:avrai/core/services/admin_god_mode_service.dart';
import 'package:avrai/core/p2p/federated_learning.dart' as federated;
import 'package:avrai/core/theme/colors.dart';

/// Admin widget displaying all federated learning rounds
/// Shows active and completed rounds with participant details
/// Updates automatically every 10 seconds
class AdminFederatedRoundsWidget extends StatefulWidget {
  final AdminGodModeService godModeService;
  final Duration refreshInterval;
  
  const AdminFederatedRoundsWidget({
    super.key,
    required this.godModeService,
    this.refreshInterval = const Duration(seconds: 10),
  });
  
  @override
  State<AdminFederatedRoundsWidget> createState() => _AdminFederatedRoundsWidgetState();
}

class _AdminFederatedRoundsWidgetState extends State<AdminFederatedRoundsWidget> {
  bool _showCompleted = true;
  List<GodModeFederatedRoundInfo>? _rounds;
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  DateTime? _lastUpdated;
  
  @override
  void initState() {
    super.initState();
    _loadRounds();
    _startAutoRefresh();
  }
  
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(widget.refreshInterval, (timer) {
      if (mounted) {
        _loadRounds(showLoading: false);
      }
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadRounds({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    
    try {
      final rounds = await widget.godModeService.getAllFederatedLearningRounds(
        includeCompleted: _showCompleted,
      );
      
      if (mounted) {
        setState(() {
          _rounds = rounds;
          _isLoading = false;
          _lastUpdated = DateTime.now();
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _buildError()
            else if (_rounds == null || _rounds!.isEmpty)
              _buildEmptyState()
            else
              _buildRoundsList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.electricGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.school,
            color: AppColors.electricGreen,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Federated Learning Rounds',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_lastUpdated != null)
                Text(
                  'Auto-refresh: ${_formatTimeAgo(_lastUpdated!)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            const Text(
              'Show Completed',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: _showCompleted,
              onChanged: (value) {
                setState(() {
                  _showCompleted = value;
                });
                _loadRounds();
              },
              activeThumbColor: AppColors.electricGreen,
            ),
          ],
        ),
        IconButton(
          icon: const Icon(
            Icons.refresh,
            color: AppColors.textSecondary,
          ),
          onPressed: () => _loadRounds(),
          tooltip: 'Refresh now',
        ),
      ],
    );
  }
  
  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inSeconds < 10) {
      return 'just now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
  
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error loading rounds',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.inbox,
              color: AppColors.textSecondary,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'No Learning Rounds',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'No federated learning rounds are currently active',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRoundsList() {
    return Column(
      children: _rounds!.map((roundInfo) => _buildRoundCard(roundInfo)).toList(),
    );
  }
  
  Widget _buildRoundCard(GodModeFederatedRoundInfo roundInfo) {
    final round = roundInfo.round;
    final statusColor = _getStatusColor(round.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        backgroundColor: AppColors.surface,
        collapsedBackgroundColor: AppColors.surface,
        title: Row(
          children: [
            _buildStatusBadge(round.status, statusColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    round.objective.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Round ${round.roundNumber} • ${roundInfo.durationString}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _buildLearningTypeIcon(round.objective.type),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              const Icon(
                Icons.people,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${roundInfo.participants.length} participants',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.trending_up,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${(round.globalModel.accuracy * 100).toStringAsFixed(1)}% accuracy',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        children: [
          _buildRoundDetails(roundInfo),
        ],
      ),
    );
  }
  
  Widget _buildRoundDetails(GodModeFederatedRoundInfo roundInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        
        // Learning Objective Section
        _buildDetailSection(
          'Learning Objective',
          Icons.lightbulb_outline,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                roundInfo.round.objective.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.electricGreen.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.electricGreen.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppColors.electricGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        roundInfo.learningRationale,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Performance Metrics Section
        _buildDetailSection(
          'Performance Metrics',
          Icons.analytics,
          Column(
            children: [
              _buildMetricRow(
                'Participation Rate',
                roundInfo.performanceMetrics.participationRate,
                false,
              ),
              _buildMetricRow(
                'Average Accuracy',
                roundInfo.performanceMetrics.averageAccuracy,
                false,
              ),
              _buildMetricRow(
                'Privacy Compliance',
                roundInfo.performanceMetrics.privacyComplianceScore,
                false,
              ),
              _buildMetricRow(
                'Convergence Progress',
                roundInfo.performanceMetrics.convergenceProgress,
                false,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Participants Section
        _buildDetailSection(
          'AI Participants (${roundInfo.participants.length})',
          Icons.people,
          Column(
            children: roundInfo.participants.map((participant) {
              return _buildParticipantRow(participant);
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailSection(String title, IconData icon, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: AppColors.electricGreen,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }
  
  Widget _buildMetricRow(String label, double value, bool isRisk) {
    final color = _getMetricColor(value, isRisk);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: AppColors.grey200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(value * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildParticipantRow(RoundParticipant participant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: participant.isActive 
                  ? AppColors.electricGreen.withValues(alpha: 0.1)
                  : AppColors.grey200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.android,
              color: participant.isActive 
                  ? AppColors.electricGreen
                  : AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.aiPersonalityName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'User: ${participant.userId}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${participant.contributionCount} contributions',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                participant.joinedTimeAgo,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: participant.isActive 
                  ? AppColors.electricGreen
                  : AppColors.grey300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusBadge(federated.RoundStatus status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
  
  Widget _buildLearningTypeIcon(federated.LearningType type) {
    IconData icon;
    switch (type) {
      case federated.LearningType.recommendation:
        icon = Icons.recommend;
        break;
      case federated.LearningType.classification:
        icon = Icons.category;
        break;
      case federated.LearningType.clustering:
        icon = Icons.group_work;
        break;
      case federated.LearningType.prediction:
        icon = Icons.trending_up;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.electricGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: AppColors.electricGreen,
        size: 20,
      ),
    );
  }
  
  Color _getStatusColor(federated.RoundStatus status) {
    switch (status) {
      case federated.RoundStatus.initializing:
        return AppColors.warning;
      case federated.RoundStatus.training:
        return AppColors.electricGreen;
      case federated.RoundStatus.aggregating:
        return AppColors.primaryLight;
      case federated.RoundStatus.completed:
        return AppColors.success;
      case federated.RoundStatus.failed:
        return AppColors.error;
    }
  }
  
  String _getStatusText(federated.RoundStatus status) {
    switch (status) {
      case federated.RoundStatus.initializing:
        return 'Initializing';
      case federated.RoundStatus.training:
        return 'Training';
      case federated.RoundStatus.aggregating:
        return 'Aggregating';
      case federated.RoundStatus.completed:
        return 'Completed';
      case federated.RoundStatus.failed:
        return 'Failed';
    }
  }
  
  Color _getMetricColor(double value, bool isRisk) {
    if (isRisk) value = 1.0 - value; // Invert for risk metrics
    
    if (value >= 0.9) return AppColors.success;
    if (value >= 0.7) return AppColors.electricGreen;
    if (value >= 0.5) return AppColors.warning;
    return AppColors.error;
  }
}

