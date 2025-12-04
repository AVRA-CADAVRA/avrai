import 'package:flutter/material.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/services/expertise_recognition_service.dart';
import 'package:spots/core/theme/colors.dart';

/// Expertise Recognition Widget
/// Displays community recognition and appreciation
class ExpertiseRecognitionWidget extends StatelessWidget {
  final UnifiedUser expert;
  final Function(UnifiedUser)? onRecognize;

  const ExpertiseRecognitionWidget({
    super.key,
    required this.expert,
    this.onRecognize,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ExpertRecognition>>(
      future: ExpertiseRecognitionService().getRecognitionsForExpert(expert),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final recognitions = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(recognitions.length),
            const SizedBox(height: 8),
            if (recognitions.isEmpty)
              _buildEmptyState()
            else
              _buildRecognitionsList(recognitions),
            if (onRecognize != null) ...[
              const SizedBox(height: 16),
              _buildRecognizeButton(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHeader(int count) {
    return Row(
      children: [
        const Text(
          'Community Recognition',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.favorite_border, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No recognition yet',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to recognize this expert!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecognitionsList(List<ExpertRecognition> recognitions) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recognitions.length,
      itemBuilder: (context, index) {
        return _buildRecognitionCard(recognitions[index]);
      },
    );
  }

  Widget _buildRecognitionCard(ExpertRecognition recognition) {
    IconData icon;
    Color color;

    switch (recognition.type) {
      case RecognitionType.helpful:
        icon = Icons.help_outline;
        color = AppColors.electricGreen;
        break;
      case RecognitionType.inspiring:
        icon = Icons.lightbulb_outline;
        color = AppColors.warning;
        break;
      case RecognitionType.exceptional:
        icon = Icons.star;
        color = AppColors.electricGreen;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          recognition.recognizer.displayName ?? recognition.recognizer.email,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(recognition.reason),
            const SizedBox(height: 4),
            Text(
              _formatDate(recognition.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(
            recognition.type.name.toUpperCase(),
            style: const TextStyle(fontSize: 10),
          ),
          backgroundColor: color.withValues(alpha: 0.1),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  Widget _buildRecognizeButton() {
    return ElevatedButton.icon(
      onPressed: () => onRecognize?.call(expert),
      icon: const Icon(Icons.favorite),
      label: const Text('Recognize Expert'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.electricGreen,
        foregroundColor: AppColors.white,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

/// Featured Expert Widget
class FeaturedExpertWidget extends StatelessWidget {
  final FeaturedExpert featuredExpert;

  const FeaturedExpertWidget({
    super.key,
    required this.featuredExpert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.electricGreen.withValues(alpha: 0.1),
            AppColors.electricGreen.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.electricGreen.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.star,
                color: AppColors.electricGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Featured Expert',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Expert Info
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.grey200,
                child: featuredExpert.expert.photoUrl != null
                    ? Image.network(featuredExpert.expert.photoUrl!)
                    : Text(
                        (featuredExpert.expert.displayName ?? featuredExpert.expert.email)[0].toUpperCase(),
                        style: const TextStyle(fontSize: 20),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      featuredExpert.expert.displayName ?? featuredExpert.expert.email,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${featuredExpert.recognitionCount} recognitions',
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
        ],
      ),
    );
  }
}

