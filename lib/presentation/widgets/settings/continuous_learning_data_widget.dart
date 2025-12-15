import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/ai/continuous_learning_system.dart';
import 'dart:async';

/// Continuous Learning Data Collection Widget
/// 
/// Phase 7, Section 39 (7.4.1): Continuous Learning UI - Integration & Polish
/// 
/// Displays data collection status for all 10 data sources:
/// - user_actions
/// - location_data
/// - weather_conditions
/// - time_patterns
/// - social_connections
/// - age_demographics
/// - app_usage_patterns
/// - community_interactions
/// - ai2ai_communications
/// - external_context
/// 
/// Shows data collection activity indicators, data volume/statistics, and health status.
/// Uses AppColors/AppTheme for 100% design token compliance.
class ContinuousLearningDataWidget extends StatefulWidget {
  final String userId;
  final ContinuousLearningSystem learningSystem;
  
  const ContinuousLearningDataWidget({
    super.key,
    required this.userId,
    required this.learningSystem,
  });
  
  @override
  State<ContinuousLearningDataWidget> createState() => _ContinuousLearningDataWidgetState();
}

class _ContinuousLearningDataWidgetState extends State<ContinuousLearningDataWidget> {
  DataCollectionStatus? _dataStatus;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _loadDataStatus();
    
    // Refresh data status periodically
    _refreshTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) _loadDataStatus();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadDataStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final status = await widget.learningSystem.getDataCollectionStatus();
      
      if (mounted) {
        setState(() {
          _dataStatus = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data collection status: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Semantics(
        label: 'Loading data collection status',
        child: const Card(
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Semantics(
        label: 'Error loading data collection status',
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: 'Retry loading data collection status',
                  button: true,
                  child: TextButton(
                    onPressed: _loadDataStatus,
                    child: const Text('Retry'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    if (_dataStatus == null || _dataStatus!.sourceStatuses.isEmpty) {
      return Semantics(
        label: 'No data collection status available',
        child: const Card(
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'No data collection status available',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return Semantics(
      label: 'Data collection status for ${_dataStatus!.sourceStatuses.length} sources',
      child: Card(
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
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.data_usage,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Data Collection Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Summary Metrics
              _buildSummaryMetrics(),
              const SizedBox(height: 24),
              
              // Data Sources List
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Data Sources (${_dataStatus!.sourceStatuses.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ..._dataStatus!.sourceStatuses.entries.map((entry) => _buildDataSourceCard(
                entry.key,
                entry.value,
              )),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSummaryMetrics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryMetricItem(
              'Active Sources',
              _dataStatus!.activeSourcesCount.toString(),
              Icons.check_circle,
              AppColors.success,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.grey300,
          ),
          Expanded(
            child: _buildSummaryMetricItem(
              'Total Volume',
              _formatDataVolume(_dataStatus!.totalVolume),
              Icons.storage,
              AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryMetricItem(String label, String value, IconData icon, Color color) {
    return Semantics(
      label: '$label: $value',
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDataSourceCard(String sourceName, DataSourceStatus status) {
    final healthColor = _getHealthColor(status.healthStatus);
    final healthIcon = _getHealthIcon(status.healthStatus);
    
    return Semantics(
      label: '${_formatSourceName(sourceName)}: ${status.healthStatus}, ${_formatDataVolume(status.dataVolume)}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: healthColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: healthColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    healthIcon,
                    color: healthColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatSourceName(sourceName),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: healthColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatHealthStatus(status.healthStatus),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: healthColor,
                              ),
                            ),
                          ),
                          if (status.isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.fiber_manual_record,
                                    size: 8,
                                    color: AppColors.success,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDataMetricItem(
                    'Volume',
                    _formatDataVolume(status.dataVolume),
                    Icons.storage,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDataMetricItem(
                    'Events',
                    status.eventCount.toString(),
                    Icons.event,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDataMetricItem(String label, String value, IconData icon) {
    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getHealthColor(String healthStatus) {
    switch (healthStatus.toLowerCase()) {
      case 'healthy':
        return AppColors.success;
      case 'idle':
        return AppColors.warning;
      case 'inactive':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
  
  IconData _getHealthIcon(String healthStatus) {
    switch (healthStatus.toLowerCase()) {
      case 'healthy':
        return Icons.check_circle;
      case 'idle':
        return Icons.pause_circle;
      case 'inactive':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
  
  String _formatHealthStatus(String healthStatus) {
    return healthStatus[0].toUpperCase() + healthStatus.substring(1);
  }
  
  String _formatSourceName(String source) {
    return source
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
  
  String _formatDataVolume(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
