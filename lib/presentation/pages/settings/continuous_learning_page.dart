import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/presentation/widgets/settings/continuous_learning_status_widget.dart';
import 'package:spots/presentation/widgets/settings/continuous_learning_progress_widget.dart';
import 'package:spots/presentation/widgets/settings/continuous_learning_data_widget.dart';
import 'package:spots/presentation/widgets/settings/continuous_learning_controls_widget.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/ai/continuous_learning_system.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';

/// Continuous Learning Page
/// 
/// Phase 7, Section 39 (7.4.1): Continuous Learning UI - Integration & Polish
/// 
/// Combines all 4 continuous learning widgets into a single comprehensive page:
/// 1. Learning Status Overview (status, active processes, metrics)
/// 2. Learning Progress by Dimension (progress for all 10 dimensions)
/// 3. Data Collection Status (status of all 10 data sources)
/// 4. Learning Controls (start/stop, parameters, privacy settings)
class ContinuousLearningPage extends StatefulWidget {
  const ContinuousLearningPage({super.key});

  @override
  State<ContinuousLearningPage> createState() => _ContinuousLearningPageState();
}

class _ContinuousLearningPageState extends State<ContinuousLearningPage> {
  ContinuousLearningSystem? _learningSystem;
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

      final system = ContinuousLearningSystem();
      await system.initialize();

      if (mounted) {
        setState(() {
          _learningSystem = system;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize continuous learning system: $e';
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Clean up learning system if it was started
    if (_learningSystem != null && _learningSystem!.isLearningActive) {
      _learningSystem!.stopContinuousLearning();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Continuous Learning'),
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

          if (_learningSystem == null) {
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
              
              // Section 1: Learning Status Overview
              _buildSectionHeader(context, 'Learning Status Overview'),
              const SizedBox(height: 8),
              Text(
                'Current learning status and system metrics',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ContinuousLearningStatusWidget(
                userId: userId,
                learningSystem: _learningSystem!,
              ),
              const SizedBox(height: 32),
              
              // Section 2: Learning Progress by Dimension
              _buildSectionHeader(context, 'Learning Progress by Dimension'),
              const SizedBox(height: 8),
              Text(
                'Track progress across all 10 learning dimensions',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ContinuousLearningProgressWidget(
                userId: userId,
                learningSystem: _learningSystem!,
              ),
              const SizedBox(height: 32),
              
              // Section 3: Data Collection Status
              _buildSectionHeader(context, 'Data Collection Status'),
              const SizedBox(height: 8),
              Text(
                'Monitor data collection from all 10 sources',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ContinuousLearningDataWidget(
                userId: userId,
                learningSystem: _learningSystem!,
              ),
              const SizedBox(height: 32),
              
              // Section 4: Learning Controls
              _buildSectionHeader(context, 'Learning Controls'),
              const SizedBox(height: 8),
              Text(
                'Start, stop, and configure continuous learning',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ContinuousLearningControlsWidget(
                userId: userId,
                learningSystem: _learningSystem!,
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
              Icons.auto_awesome,
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
                  'Continuous Learning',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'See how your AI continuously learns',
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
            'Continuous learning enables your AI to learn from everything and improve itself '
            'every second. Your AI learns from your actions, location data, weather conditions, '
            'time patterns, social connections, and more. All learning happens on your device '
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

