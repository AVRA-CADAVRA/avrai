import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/presentation/widgets/settings/ai2ai_learning_methods_widget.dart';
import 'package:spots/presentation/widgets/settings/ai2ai_learning_effectiveness_widget.dart';
import 'package:spots/presentation/widgets/settings/ai2ai_learning_insights_widget.dart';
import 'package:spots/presentation/widgets/settings/ai2ai_learning_recommendations_widget.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/services/ai2ai_learning_service.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/injection_container.dart' as di;

/// AI2AI Learning Methods Page
/// 
/// Phase 7, Week 38: AI2AI Learning Methods UI - Integration & Polish
/// 
/// Combines all 4 AI2AI learning widgets into a single comprehensive page:
/// 1. Learning Methods Overview (active methods, status, effectiveness)
/// 2. Learning Effectiveness Metrics (metrics, insights count, acquisition rate)
/// 3. Active Learning Insights (recent insights, cross-personality, patterns)
/// 4. Learning Recommendations (optimal partners, topics, development areas)
class AI2AILearningMethodsPage extends StatefulWidget {
  const AI2AILearningMethodsPage({super.key});

  @override
  State<AI2AILearningMethodsPage> createState() => _AI2AILearningMethodsPageState();
}

class _AI2AILearningMethodsPageState extends State<AI2AILearningMethodsPage> {
  AI2AILearning? _learningService;
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

      // Get service from dependency injection
      final service = di.sl<AI2AILearning>();

      if (mounted) {
        setState(() {
          _learningService = service;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize AI2AI learning: $e';
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI2AI Learning Methods'),
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

          if (_learningService == null) {
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
              
              // Section 1: Learning Methods Overview
              _buildSectionHeader(context, 'Learning Methods Overview'),
              const SizedBox(height: 8),
              Text(
                'See how your AI learns from other AIs',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              AI2AILearningMethodsWidget(
                userId: userId,
                learningService: _learningService!,
              ),
              const SizedBox(height: 32),
              
              // Section 2: Learning Effectiveness
              _buildSectionHeader(context, 'Learning Effectiveness Metrics'),
              const SizedBox(height: 8),
              Text(
                'Track how effectively your AI is learning',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              AI2AILearningEffectivenessWidget(
                userId: userId,
                learningService: _learningService!,
              ),
              const SizedBox(height: 32),
              
              // Section 3: Learning Insights
              _buildSectionHeader(context, 'Active Learning Insights'),
              const SizedBox(height: 8),
              Text(
                'Recent insights from AI2AI interactions',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              AI2AILearningInsightsWidget(
                userId: userId,
                learningService: _learningService!,
              ),
              const SizedBox(height: 32),
              
              // Section 4: Learning Recommendations
              _buildSectionHeader(context, 'Learning Recommendations'),
              const SizedBox(height: 8),
              Text(
                'Optimal learning partners and development areas',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              AI2AILearningRecommendationsWidget(
                userId: userId,
                learningService: _learningService!,
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
              Icons.psychology,
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
                  'AI2AI Learning Methods',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'See how your AI learns from other AIs',
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
            'AI2AI learning enables your AI to learn from interactions with other AIs '
            'through secure, privacy-preserving connections. Your AI discovers new '
            'personality insights, learns from cross-personality patterns, and evolves '
            'through collective intelligence. All learning happens on your device to '
            'protect your privacy.',
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
