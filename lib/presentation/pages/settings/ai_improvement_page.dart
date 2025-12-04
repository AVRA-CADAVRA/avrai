import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/presentation/widgets/settings/ai_improvement_section.dart';
import 'package:spots/presentation/widgets/settings/ai_improvement_progress_widget.dart';
import 'package:spots/presentation/widgets/settings/ai_improvement_timeline_widget.dart';
import 'package:spots/presentation/widgets/settings/ai_improvement_impact_widget.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/services/ai_improvement_tracking_service.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';

/// AI Improvement Page
/// 
/// Phase 7, Week 37: AI Self-Improvement Visibility - Integration & Polish
/// 
/// Combines all 4 AI improvement widgets into a single comprehensive page:
/// 1. AIImprovementSection (main metrics)
/// 2. AIImprovementProgressWidget (progress charts)
/// 3. AIImprovementTimelineWidget (history timeline)
/// 4. AIImprovementImpactWidget (impact explanation)
class AIImprovementPage extends StatefulWidget {
  const AIImprovementPage({super.key});

  @override
  State<AIImprovementPage> createState() => _AIImprovementPageState();
}

class _AIImprovementPageState extends State<AIImprovementPage> {
  AIImprovementTrackingService? _trackingService;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });

      // Use dependency injection instead of direct instantiation
      final service = GetIt.instance<AIImprovementTrackingService>();
      await service.initialize();

      if (mounted) {
        setState(() {
          _trackingService = service;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize AI improvement tracking: $e';
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _trackingService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Improvement'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! Authenticated) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final userId = authState.user.id;

          if (_isInitializing) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (_errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _initializeService,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_trackingService == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              _buildHeader(context),
              const SizedBox(height: 24),
              
              // Section 1: Main Metrics
              _buildSectionHeader(context, 'AI Improvement Metrics'),
              const SizedBox(height: 8),
              Text(
                'See how your AI is improving over time',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              AIImprovementSection(
                userId: userId,
                trackingService: _trackingService!,
              ),
              const SizedBox(height: 32),
              
              // Section 2: Progress Charts
              _buildSectionHeader(context, 'Improvement Progress'),
              const SizedBox(height: 8),
              Text(
                'Track improvement trends over time',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              AIImprovementProgressWidget(
                userId: userId,
                trackingService: _trackingService!,
              ),
              const SizedBox(height: 32),
              
              // Section 3: Timeline
              _buildSectionHeader(context, 'Improvement History'),
              const SizedBox(height: 8),
              Text(
                'Timeline of AI improvements and milestones',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              AIImprovementTimelineWidget(
                userId: userId,
                trackingService: _trackingService!,
              ),
              const SizedBox(height: 32),
              
              // Section 4: Impact
              _buildSectionHeader(context, 'Impact & Benefits'),
              const SizedBox(height: 8),
              Text(
                'How AI improvements benefit your experience',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              AIImprovementImpactWidget(
                userId: userId,
                trackingService: _trackingService!,
              ),
              const SizedBox(height: 24),
              
              // Footer
              _buildFooter(context),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.trending_up,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Self-Improvement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Watch your AI learn and improve over time',
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
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
  
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Learn More',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your AI continuously learns and improves from your interactions. '
            'This page shows you how your AI is evolving, including improvements '
            'in recommendation accuracy, understanding your preferences, and '
            'adapting to your unique style. All learning happens on your device '
            'to protect your privacy.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.shield,
                color: AppColors.success,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Your data stays on your device',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

