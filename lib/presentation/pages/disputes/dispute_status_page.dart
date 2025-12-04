import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/core/models/dispute.dart';
import 'package:spots/core/models/dispute_status.dart';
import 'package:spots/core/services/dispute_resolution_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';

/// Dispute Status Page
/// 
/// Agent 2: Phase 5, Week 16-17 - Dispute UI
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - Dispute status display
/// - Timeline of dispute progress
/// - Messages/communication thread
/// - Resolution details (if resolved)
class DisputeStatusPage extends StatefulWidget {
  final String disputeId;

  const DisputeStatusPage({
    super.key,
    required this.disputeId,
  });

  @override
  State<DisputeStatusPage> createState() => _DisputeStatusPageState();
}

class _DisputeStatusPageState extends State<DisputeStatusPage> {
  final DisputeResolutionService _disputeService = DisputeResolutionService(
    eventService: GetIt.instance<ExpertiseEventService>(),
  );

  Dispute? _dispute;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDispute();
  }

  Future<void> _loadDispute() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dispute = await _disputeService.getDispute(widget.disputeId);
      setState(() {
        _dispute = dispute;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Dispute Status',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDispute,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_dispute == null) {
      return const Center(
        child: Text('Dispute not found'),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            _buildStatusHeader(),
            const SizedBox(height: 24),

            // Dispute Details
            _buildDisputeDetails(),
            const SizedBox(height: 24),

            // Timeline
            _buildTimeline(),
            const SizedBox(height: 24),

            // Messages (if any)
            if (_dispute!.messages.isNotEmpty) ...[
              _buildMessages(),
              const SizedBox(height: 24),
            ],

            // Resolution (if resolved)
            if (_dispute!.isResolved) ...[
              _buildResolution(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final status = _dispute!.status;
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case DisputeStatus.pending:
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.pending;
        break;
      case DisputeStatus.inReview:
        statusColor = AppTheme.primaryColor;
        statusIcon = Icons.visibility;
        break;
      case DisputeStatus.waitingResponse:
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.hourglass_empty;
        break;
      case DisputeStatus.resolved:
        statusColor = AppColors.electricGreen;
        statusIcon = Icons.check_circle;
        break;
      case DisputeStatus.closed:
        statusColor = AppColors.grey400;
        statusIcon = Icons.close;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: ${status.displayName}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDescription(status),
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
    );
  }

  Widget _buildDisputeDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dispute Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Type', _dispute!.type.displayName),
          _buildDetailRow('Event ID', _dispute!.eventId),
          _buildDetailRow('Created', _formatDateTime(_dispute!.createdAt)),
          if (_dispute!.assignedAdminId != null)
            _buildDetailRow('Assigned Admin', _dispute!.assignedAdminId!),
          const SizedBox(height: 16),
          Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _dispute!.description,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          if (_dispute!.evidenceUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Evidence',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _dispute!.evidenceUrls.map((url) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.grey300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.grey200,
                          child: Icon(Icons.image, color: AppColors.textSecondary),
                        );
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildTimelineItem(
            'Dispute Submitted',
            _formatDateTime(_dispute!.createdAt),
            true,
          ),
          if (_dispute!.assignedAt != null)
            _buildTimelineItem(
              'Assigned to Admin',
              _formatDateTime(_dispute!.assignedAt!),
              true,
            ),
          if (_dispute!.resolvedAt != null)
            _buildTimelineItem(
              'Resolved',
              _formatDateTime(_dispute!.resolvedAt!),
              true,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String date, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isComplete ? AppColors.electricGreen : AppColors.grey400,
            ),
            child: isComplete
                ? const Icon(Icons.check, size: 16, color: AppColors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Messages',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ..._dispute!.messages.map((message) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: message.isAdminMessage
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (message.isAdminMessage)
                          Icon(Icons.admin_panel_settings,
                              size: 16, color: AppTheme.primaryColor),
                        if (message.isAdminMessage) const SizedBox(width: 4),
                        Text(
                          message.isAdminMessage ? 'Admin' : 'You',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDateTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildResolution() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.electricGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.electricGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.electricGreen),
              const SizedBox(width: 8),
              Text(
                'Resolution',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.electricGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_dispute!.resolution != null) ...[
            Text(
              _dispute!.resolution!,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_dispute!.refundAmount != null) ...[
            Text(
              'Refund Amount: \$${_dispute!.refundAmount!.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDescription(DisputeStatus status) {
    switch (status) {
      case DisputeStatus.pending:
        return 'Your dispute has been submitted and is waiting to be reviewed';
      case DisputeStatus.inReview:
        return 'An admin is currently reviewing your dispute';
      case DisputeStatus.waitingResponse:
        return 'We are waiting for additional information';
      case DisputeStatus.resolved:
        return 'Your dispute has been resolved';
      case DisputeStatus.closed:
        return 'This dispute has been closed';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }
}

