/// Federated Learning Status Widget
/// 
/// Part of Feature Matrix Phase 2: Medium Priority UI/UX
/// 
/// Widget showing active learning rounds, participation status, and progress:
/// - Active learning rounds display
/// - Participation status (whether user is participating)
/// - Round progress indicators
/// - Round status (initializing, training, aggregating, completed, failed)
/// 
/// Location: Settings/Account page (within Federated Learning section)
/// Uses AppColors for consistent styling per design token requirements.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/p2p/federated_learning.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/presentation/widgets/common/standard_error_widget.dart';
import 'package:spots/presentation/widgets/common/standard_loading_widget.dart';
import 'package:get_it/get_it.dart';

/// Widget displaying federated learning round status and participation
class FederatedLearningStatusWidget extends StatefulWidget {
  const FederatedLearningStatusWidget({super.key});

  @override
  State<FederatedLearningStatusWidget> createState() => _FederatedLearningStatusWidgetState();
}

class _FederatedLearningStatusWidgetState extends State<FederatedLearningStatusWidget> {
  late final FederatedLearningSystem _federatedLearningSystem;
  List<FederatedLearningRound> _activeRounds = [];
  String? _currentNodeId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Use dependency injection to get FederatedLearningSystem
    try {
      _federatedLearningSystem = GetIt.instance<FederatedLearningSystem>();
    } catch (e) {
      // Fallback if not registered in DI (shouldn't happen in production)
      _federatedLearningSystem = FederatedLearningSystem();
    }
    _loadActiveRounds();
  }

  Future<void> _loadActiveRounds() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user ID as node ID
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        _currentNodeId = authState.user.id;
      }

      // Fetch active rounds from backend
      final activeRounds = await _federatedLearningSystem.getActiveRounds(_currentNodeId);
      
      if (mounted) {
        setState(() {
          _activeRounds = activeRounds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load active rounds: ${e.toString()}';
          _isLoading = false;
          _activeRounds = [];
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.electricGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.sync,
                    color: AppColors.electricGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Learning Round Status',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.info_outline,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => _showLearningRoundInfoDialog(context),
                  tooltip: 'What is a learning round?',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              _buildLoadingState()
            else if (_errorMessage != null)
              _buildErrorState()
            else if (_activeRounds.isEmpty)
              _buildNoActiveRoundsMessage()
            else
              ..._activeRounds.map((round) => _buildRoundCard(round)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return StandardLoadingWidget.container(
      message: 'Loading active rounds...',
    );
  }

  Widget _buildErrorState() {
    return StandardErrorWidget(
      message: _errorMessage ?? 'An error occurred',
      onRetry: _loadActiveRounds,
    );
  }

  Widget _buildNoActiveRoundsMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No active learning rounds at the moment. Rounds start when enough participants join.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundCard(FederatedLearningRound round) {
    final isParticipating = _currentNodeId != null &&
        round.participantNodeIds.contains(_currentNodeId);
    final progress = _calculateProgress(round);
    final statusColor = _getStatusColor(round.status);
    final statusText = _getStatusText(round.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Round ${round.roundNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildParticipationBadge(isParticipating),
            ],
          ),
          const SizedBox(height: 8),
          // Learning objective/topic
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.electricGreen.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.electricGreen.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getObjectiveIcon(round.objective.type),
                  size: 16,
                  color: AppColors.electricGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Learning: ${round.objective.name}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (round.objective.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          round.objective.description,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${round.participantNodeIds.length} participant${round.participantNodeIds.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.grey200,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticipationBadge(bool isParticipating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isParticipating
            ? AppColors.electricGreen.withValues(alpha: 0.1)
            : AppColors.grey200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isParticipating ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: isParticipating
                ? AppColors.electricGreen
                : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            isParticipating ? 'Participating' : 'Not participating',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isParticipating
                  ? AppColors.electricGreen
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateProgress(FederatedLearningRound round) {
    // Calculate progress based on status and participant updates
    switch (round.status) {
      case RoundStatus.initializing:
        return 0.1;
      case RoundStatus.training:
        // Progress based on how many participants have submitted updates
        final updateCount = round.participantUpdates.length;
        final participantCount = round.participantNodeIds.length;
        if (participantCount == 0) return 0.2;
        return 0.2 + (updateCount / participantCount) * 0.6;
      case RoundStatus.aggregating:
        return 0.9;
      case RoundStatus.completed:
        return 1.0;
      case RoundStatus.failed:
        return 0.0;
    }
  }

  Color _getStatusColor(RoundStatus status) {
    switch (status) {
      case RoundStatus.initializing:
        return AppColors.textSecondary;
      case RoundStatus.training:
        return AppColors.electricGreen;
      case RoundStatus.aggregating:
        return AppColors.primary;
      case RoundStatus.completed:
        return AppColors.electricGreen;
      case RoundStatus.failed:
        return AppColors.error;
    }
  }

  String _getStatusText(RoundStatus status) {
    switch (status) {
      case RoundStatus.initializing:
        return 'Initializing';
      case RoundStatus.training:
        return 'Training';
      case RoundStatus.aggregating:
        return 'Aggregating';
      case RoundStatus.completed:
        return 'Completed';
      case RoundStatus.failed:
        return 'Failed';
    }
  }

  IconData _getObjectiveIcon(LearningType type) {
    switch (type) {
      case LearningType.recommendation:
        return Icons.recommend;
      case LearningType.classification:
        return Icons.category;
      case LearningType.clustering:
        return Icons.group_work;
      case LearningType.prediction:
        return Icons.trending_up;
    }
  }

  void _showLearningRoundInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.sync,
              color: AppColors.electricGreen,
            ),
            SizedBox(width: 8),
            Text(
              'What is a Learning Round?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A learning round is a cycle in federated learning where the AI improves through collaborative training.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'How it works:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoItem('1. Initialization', 'A global AI model is created and distributed to participants'),
              _buildInfoItem('2. Local Training', 'Each device trains the model on local data (data never leaves your device)'),
              _buildInfoItem('3. Update Sharing', 'Only model updates (patterns), not raw data, are sent'),
              _buildInfoItem('4. Aggregation', 'Updates from all participants are combined to improve the global model'),
              _buildInfoItem('5. Distribution', 'The improved model is sent back to your device'),
              _buildInfoItem('6. Repeat', 'Process repeats until model converges (stops improving)'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.electricGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: AppColors.electricGreen,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Think of it like: A group of chefs sharing recipe improvements without sharing their secret ingredients.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Got it',
              style: TextStyle(
                color: AppColors.electricGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.electricGreen,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
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
}
