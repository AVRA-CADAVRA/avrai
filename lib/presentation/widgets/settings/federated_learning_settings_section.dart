/// Federated Learning Settings Section
///
/// Part of Feature Matrix Phase 2: Medium Priority UI/UX
///
/// Settings section for federated learning participation:
/// - Explains what federated learning is and how it works
/// - Shows participation benefits
/// - Explains negative consequences of not participating
/// - Opt-in/opt-out controls
///
/// Location: Settings/Account page
/// Uses AppColors and AppTheme for consistent styling per design token requirements.
library;

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/services/storage_service.dart';

/// Settings section widget for federated learning participation
class FederatedLearningSettingsSection extends StatefulWidget {
  const FederatedLearningSettingsSection({super.key});

  @override
  State<FederatedLearningSettingsSection> createState() =>
      _FederatedLearningSettingsSectionState();
}

class _FederatedLearningSettingsSectionState
    extends State<FederatedLearningSettingsSection> {
  bool _isParticipating = true;
  final _storageService = StorageService.instance;
  static const String _participationKey = 'federated_learning_participation';

  @override
  void initState() {
    super.initState();
    _loadParticipationStatus();
  }

  void _loadParticipationStatus() {
    final stored = _storageService.getBool(_participationKey);
    setState(() {
      _isParticipating = stored ?? true; // Default to participating
    });
  }

  Future<void> _toggleParticipation(bool value) async {
    setState(() {
      _isParticipating = value;
    });

    try {
      await _storageService.setBool(_participationKey, value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Federated learning participation enabled'
                  : 'Federated learning participation disabled',
            ),
            backgroundColor:
                value ? AppColors.electricGreen : AppColors.warning,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _isParticipating = !value;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preference: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showInfoDialog() {
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
              Icons.school,
              color: AppColors.electricGreen,
            ),
            SizedBox(width: 8),
            Text(
              'What is Federated Learning?',
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
                'Federated learning is a privacy-preserving way for AI to learn from your data without exposing it.',
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
              _buildInfoItem('1. Local Training',
                  'Your device trains a model on your data (data never leaves your device)'),
              _buildInfoItem('2. Update Sharing',
                  'Only model updates (patterns), not raw data, are sent'),
              _buildInfoItem('3. Aggregation',
                  'Updates from all participants are combined to improve the global model'),
              _buildInfoItem('4. Distribution',
                  'The improved model is sent back to your device'),
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
                      Icons.lock,
                      size: 20,
                      color: AppColors.electricGreen,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your data stays on your device. Only anonymized patterns are shared.',
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
                    Icons.school,
                    color: AppColors.electricGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Federated Learning',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Semantics(
                  label: 'Learn more about federated learning',
                  button: true,
                  child: IconButton(
                    icon: const Icon(
                      Icons.info_outline,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: _showInfoDialog,
                    tooltip: 'Learn more',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Help improve avrai AI while keeping your data private',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lock,
                        size: 16,
                        color: AppColors.electricGreen,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Privacy-preserving: Your data stays on your device. Only anonymized model updates (not raw data) are shared.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Benefits of participating:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildBenefitItem('More accurate recommendations'),
            _buildBenefitItem('Faster AI improvement'),
            _buildBenefitItem('Better personalized experiences'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Not participating may result in:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Less accurate recommendations\n• Slower AI improvement\n• Less personalized experiences',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              label:
                  'Participate in Federated Learning toggle. Currently ${_isParticipating ? 'enabled' : 'disabled'}',
              value: _isParticipating ? 'Enabled' : 'Disabled',
              child: Card(
                elevation: 0,
                color: AppColors.grey100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Participate in Federated Learning',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    _isParticipating
                        ? 'Your device will contribute to improving avrai AI'
                        : 'Your device will not participate in federated learning',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: _isParticipating,
                  onChanged: _toggleParticipation,
                  activeThumbColor: AppColors.electricGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String benefit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: AppColors.electricGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              benefit,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
