/// Privacy Metrics Widget
/// 
/// Part of Feature Matrix Phase 2: Medium Priority UI/UX
/// 
/// Widget showing privacy compliance, anonymization levels, and data protection metrics:
/// - Privacy compliance display (personalized to user)
/// - Anonymization levels (user-specific)
/// - Data protection metrics (user-specific)
/// - Re-identification risk
/// - Data exposure level
/// - Encryption strength
/// - Privacy violations count
/// 
/// Location: Settings/Account page (within Federated Learning section)
/// Uses AppColors and AppTheme for consistent styling per design token requirements.

import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/monitoring/network_analytics.dart';
import 'package:spots/core/services/storage_service.dart' show SharedPreferencesCompat;
import 'package:get_it/get_it.dart';

/// Widget displaying user-specific privacy metrics
class PrivacyMetricsWidget extends StatefulWidget {
  const PrivacyMetricsWidget({super.key});

  @override
  State<PrivacyMetricsWidget> createState() => _PrivacyMetricsWidgetState();
}

class _PrivacyMetricsWidgetState extends State<PrivacyMetricsWidget> {
  PrivacyMetrics? _privacyMetrics;
  bool _isLoading = true;
  String? _errorMessage;
  NetworkAnalytics? _networkAnalytics;

  @override
  void initState() {
    super.initState();
    _loadPrivacyMetrics();
  }

  Future<void> _loadPrivacyMetrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get SharedPreferencesCompat for NetworkAnalytics from DI
      final prefs = GetIt.instance<SharedPreferencesCompat>();
      _networkAnalytics = NetworkAnalytics(prefs: prefs);

      // Get privacy metrics from network health report
      final healthReport = await _networkAnalytics!.analyzeNetworkHealth();
      _privacyMetrics = healthReport.privacyMetrics;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load privacy metrics: ${e.toString()}';
          _isLoading = false;
          _privacyMetrics = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _privacyMetrics == null) {
      return _buildLoadingOrErrorState();
    }

    final overallScore = _privacyMetrics!.overallPrivacyScore;
    final scoreColor = _getScoreColor(overallScore);
    final scoreLabel = _getScoreLabel(overallScore);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
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
                    Icons.lock,
                    color: AppColors.electricGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Privacy Metrics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Semantics(
                  label: 'Learn more about privacy metrics',
                  button: true,
                  child: IconButton(
                    icon: const Icon(
                      Icons.info_outline,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => _showPrivacyInfoDialog(context),
                    tooltip: 'Learn more about privacy',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Overall Privacy Score
            Semantics(
              label: 'Overall Privacy Score: ${(overallScore * 100).round()}%, $scoreLabel',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: scoreColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Overall Privacy Score',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: scoreColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${(overallScore * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.surface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scoreLabel,
                      style: TextStyle(
                        fontSize: 14,
                        color: scoreColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: overallScore,
                        backgroundColor: AppColors.grey200,
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Privacy Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            // Anonymization Level
            _buildMetricRow(
              'Anonymization Level',
              _privacyMetrics!.anonymizationLevel,
              Icons.visibility_off,
              isGood: true,
            ),
            const SizedBox(height: 12),
            // Re-identification Risk
            _buildMetricRow(
              'Re-identification Risk',
              _privacyMetrics!.reidentificationRisk,
              Icons.shield_outlined,
              isRisk: true,
            ),
            const SizedBox(height: 12),
            // Data Security Score
            _buildMetricRow(
              'Data Security Score',
              _privacyMetrics!.dataSecurityScore,
              Icons.security,
              isGood: true,
            ),
            const SizedBox(height: 12),
            // Data Exposure Level
            _buildMetricRow(
              'Data Exposure Level',
              _privacyMetrics!.dataExposureLevel,
              Icons.warning_outlined,
              isRisk: true,
            ),
            const SizedBox(height: 12),
            // Encryption Strength
            _buildMetricRow(
              'Encryption Strength',
              _privacyMetrics!.encryptionStrength,
              Icons.vpn_key,
              isGood: true,
            ),
            const SizedBox(height: 12),
            // Privacy Violations
            _buildViolationsRow(),
            const SizedBox(height: 12),
            // Compliance Rate
            _buildMetricRow(
              'Privacy Compliance Rate',
              _privacyMetrics!.complianceRate,
              Icons.check_circle_outline,
              isGood: true,
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOrErrorState() {
    if (_isLoading) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.electricGreen,
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage ?? 'An error occurred',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadPrivacyMetrics,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricGreen,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    double value,
    IconData icon, {
    bool isGood = false,
    bool isRisk = false,
  }) {
    final percentage = (value * 100).toStringAsFixed(1);
    final color = isRisk
        ? (value < 0.05 ? AppColors.electricGreen : AppColors.error)
        : _getScoreColor(value);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: AppColors.grey200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViolationsRow() {
    final violations = _privacyMetrics!.privacyViolations;
    final color = violations == 0 ? AppColors.electricGreen : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            violations == 0 ? Icons.check_circle : Icons.error_outline,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Privacy Violations',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              violations == 0 ? 'None' : '$violations detected',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.95) return AppColors.electricGreen;
    if (score >= 0.85) return AppColors.warning;
    return AppColors.error;
  }

  String _getScoreLabel(double score) {
    if (score >= 0.95) return 'Excellent - Maximum privacy protection';
    if (score >= 0.85) return 'Good - Strong privacy protection';
    if (score >= 0.75) return 'Fair - Adequate privacy protection';
    return 'Needs improvement - Privacy protection below standard';
  }

  void _showPrivacyInfoDialog(BuildContext context) {
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
              Icons.lock,
              color: AppColors.electricGreen,
            ),
            SizedBox(width: 8),
            Text(
              'Privacy Metrics Explained',
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
                'These metrics show how well your data is protected in federated learning.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                'Anonymization Level',
                'How well your data is anonymized before sharing. Higher is better.',
              ),
              _buildInfoItem(
                'Re-identification Risk',
                'Risk that your data could be re-identified. Lower is better (should be <5%).',
              ),
              _buildInfoItem(
                'Data Security Score',
                'Overall security of your data. Higher is better.',
              ),
              _buildInfoItem(
                'Data Exposure Level',
                'Level of data exposure risk. Lower is better (should be <5%).',
              ),
              _buildInfoItem(
                'Encryption Strength',
                'Strength of encryption protecting your data. Higher is better.',
              ),
              _buildInfoItem(
                'Privacy Violations',
                'Number of privacy violations detected. Should always be 0.',
              ),
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
                      Icons.info_outline,
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
}

