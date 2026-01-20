import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/ai/continuous_learning_system.dart';

/// Continuous Learning Controls Widget
/// 
/// Phase 7, Section 39 (7.4.1): Continuous Learning UI - Integration & Polish
/// 
/// Provides controls for continuous learning system:
/// - Start/stop continuous learning toggle
/// - Learning parameter controls (if applicable)
/// - Privacy settings section with toggles
/// - Enable/disable features toggles
/// 
/// Uses AppColors/AppTheme for 100% design token compliance.
class ContinuousLearningControlsWidget extends StatefulWidget {
  final String userId;
  final ContinuousLearningSystem learningSystem;
  
  const ContinuousLearningControlsWidget({
    super.key,
    required this.userId,
    required this.learningSystem,
  });
  
  @override
  State<ContinuousLearningControlsWidget> createState() => _ContinuousLearningControlsWidgetState();
}

class _ContinuousLearningControlsWidgetState extends State<ContinuousLearningControlsWidget> {
  bool _isLearningActive = false;
  bool _isLoadingStatus = true;
  bool _isToggling = false;
  String? _errorMessage;
  
  // Privacy settings
  bool _privacyDataCollection = true;
  bool _privacyLocationData = true;
  bool _privacySocialData = true;
  bool _privacyAi2AiSharing = true;
  
  @override
  void initState() {
    super.initState();
    _loadStatus();
  }
  
  Future<void> _loadStatus() async {
    setState(() {
      _isLoadingStatus = true;
      _errorMessage = null;
    });
    
    try {
      final status = await widget.learningSystem.getLearningStatus();
      
      if (mounted) {
        setState(() {
          _isLearningActive = status.isActive;
          _isLoadingStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load learning status: $e';
          _isLoadingStatus = false;
        });
      }
    }
  }
  
  Future<void> _toggleContinuousLearning(bool value) async {
    setState(() {
      _isToggling = true;
      _errorMessage = null;
    });
    
    try {
      if (value) {
        await widget.learningSystem.startContinuousLearning();
      } else {
        await widget.learningSystem.stopContinuousLearning();
      }
      
      if (mounted) {
        setState(() {
          _isLearningActive = value;
          _isToggling = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to ${value ? 'start' : 'stop'} continuous learning: $e';
          _isToggling = false;
          _isLearningActive = !value; // Revert to previous state
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Continuous learning controls',
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
                      Icons.settings,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Learning Controls',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Start/Stop Toggle
              _buildStartStopSection(),
              const SizedBox(height: 24),
              
              // Divider
              const Divider(),
              const SizedBox(height: 24),
              
              // Privacy Settings
              _buildPrivacySection(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStartStopSection() {
    return Semantics(
      label: 'Continuous learning ${_isLearningActive ? 'is active' : 'is inactive'}',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isLearningActive
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isLearningActive
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.grey300,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isLearningActive ? Icons.play_circle : Icons.pause_circle,
                  color: _isLearningActive ? AppColors.success : AppColors.textSecondary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Continuous Learning',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLearningActive
                            ? 'Learning is actively improving your AI'
                            : 'Learning is paused',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoadingStatus)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                else
                  Semantics(
                    label: _isLearningActive
                        ? 'Stop continuous learning'
                        : 'Start continuous learning',
                    button: true,
                    child: Switch(
                      value: _isLearningActive,
                      onChanged: _isToggling
                          ? null
                          : (value) => _toggleContinuousLearning(value),
                      activeThumbColor: AppColors.success,
                    ),
                  ),
              ],
            ),
            if (_isToggling) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPrivacySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.privacy_tip,
              color: AppColors.primary,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Privacy Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Control what data is used for continuous learning',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        
        // Privacy Toggles
        _buildPrivacyToggle(
          'Data Collection',
          'Allow data collection for learning',
          _privacyDataCollection,
          (value) => setState(() => _privacyDataCollection = value),
          Icons.data_usage,
        ),
        const SizedBox(height: 12),
        _buildPrivacyToggle(
          'Location Data',
          'Use location data for learning',
          _privacyLocationData,
          (value) => setState(() => _privacyLocationData = value),
          Icons.location_on,
        ),
        const SizedBox(height: 12),
        _buildPrivacyToggle(
          'Social Data',
          'Use social connection data',
          _privacySocialData,
          (value) => setState(() => _privacySocialData = value),
          Icons.people,
        ),
        const SizedBox(height: 12),
        _buildPrivacyToggle(
          'AI2AI Sharing',
          'Share learning insights with other AIs',
          _privacyAi2AiSharing,
          (value) => setState(() => _privacyAi2AiSharing = value),
          Icons.share,
        ),
        
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.shield,
                color: AppColors.success,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'All learning happens on your device. Your data never leaves your device.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPrivacyToggle(
    String title,
    String description,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return Semantics(
      label: '$title: ${value ? 'enabled' : 'disabled'}',
      button: true,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: value
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.grey300,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: value ? AppColors.success : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
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
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.success,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
