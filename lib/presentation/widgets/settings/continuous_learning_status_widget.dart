import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/ai/continuous_learning_system.dart';
import 'dart:async';

/// Continuous Learning Status Widget
/// 
/// Phase 7, Section 39 (7.4.1): Continuous Learning UI - Integration & Polish
/// 
/// Displays current learning status including:
/// - Active/paused/stopped status
/// - Active learning processes list
/// - System metrics (uptime, cycles, learning time)
class ContinuousLearningStatusWidget extends StatefulWidget {
  final String userId;
  final ContinuousLearningSystem learningSystem;
  
  const ContinuousLearningStatusWidget({
    super.key,
    required this.userId,
    required this.learningSystem,
  });
  
  @override
  State<ContinuousLearningStatusWidget> createState() => _ContinuousLearningStatusWidgetState();
}

class _ContinuousLearningStatusWidgetState extends State<ContinuousLearningStatusWidget> {
  ContinuousLearningStatus? _status;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _loadStatus();
    
    // Refresh status periodically
    _refreshTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) _loadStatus();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final status = await widget.learningSystem.getLearningStatus();
      
      if (mounted) {
        setState(() {
          _status = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load status: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Semantics(
        label: 'Loading continuous learning status',
        child: const Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
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
        label: 'Error loading continuous learning status',
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                  label: 'Retry loading status',
                  button: true,
                  child: TextButton(
                    onPressed: _loadStatus,
                    child: const Text('Retry'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    if (_status == null) {
      return Semantics(
        label: 'No learning status available',
        child: const Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'No learning status available',
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
      label: 'Continuous learning status: ${_status!.isActive ? 'Active' : 'Inactive'}',
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
              // Status Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _status!.isActive
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.grey300.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _status!.isActive ? Icons.check_circle : Icons.pause_circle,
                      color: _status!.isActive ? AppColors.success : AppColors.grey600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _status!.isActive ? 'Active' : 'Inactive',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _status!.isActive
                              ? 'Learning is in progress'
                              : 'Learning is paused',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // System Metrics
              Semantics(
                label: 'Uptime: ${_formatDuration(_status!.uptime)}',
                child: _buildMetricRow(
                  'Uptime',
                  _formatDuration(_status!.uptime),
                  Icons.access_time,
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Cycles completed: ${_status!.cyclesCompleted}',
                child: _buildMetricRow(
                  'Cycles Completed',
                  _status!.cyclesCompleted.toString(),
                  Icons.refresh,
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Learning time: ${_formatDuration(_status!.learningTime)}',
                child: _buildMetricRow(
                  'Learning Time',
                  _formatDuration(_status!.learningTime),
                  Icons.school,
                ),
              ),
              
              // Active Processes
              if (_status!.activeProcesses.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Active Learning Processes (${_status!.activeProcesses.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  label: 'Active learning processes list',
                  child: Column(
                    children: _status!.activeProcesses.map((process) => Semantics(
                      label: 'Active process: ${_formatDimensionName(process)}',
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatDimensionName(process),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
  
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
  
  String _formatDimensionName(String dimension) {
    return dimension
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

