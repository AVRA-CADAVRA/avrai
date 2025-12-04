import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spots/core/models/verification_session.dart';
import 'package:spots/core/services/identity_verification_service.dart';
import 'package:spots/core/services/tax_compliance_service.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';

/// Identity Verification Page
///
/// Agent 2: Phase 5, Week 20-21 - Identity Verification UI
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Verification instructions
/// - Verification URL/link
/// - Status display
/// - Document upload (if needed)
/// - Verification progress
class IdentityVerificationPage extends StatefulWidget {
  const IdentityVerificationPage({super.key});

  @override
  State<IdentityVerificationPage> createState() =>
      _IdentityVerificationPageState();
}

class _IdentityVerificationPageState extends State<IdentityVerificationPage> {
  final IdentityVerificationService _verificationService =
      IdentityVerificationService(
    taxComplianceService: TaxComplianceService(
      paymentService: GetIt.instance<PaymentService>(),
    ),
  );

  VerificationSession? _session;
  bool _needsVerification = false;
  bool _isLoading = true;
  bool _isInitiating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('Please sign in to view verification status');
      }

      // Check if user needs verification
      final needsVerification =
          await _verificationService.requiresVerification(authState.user.id);

      // Get current session if exists
      VerificationSession? session;
      try {
        session =
            await _verificationService.getUserVerification(authState.user.id);
      } catch (e) {
        // No session exists yet
      }

      setState(() {
        _needsVerification = needsVerification;
        _session = session;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _initiateVerification() async {
    setState(() {
      _isInitiating = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('Please sign in to initiate verification');
      }

      final session =
          await _verificationService.initiateVerification(authState.user.id);

      setState(() {
        _session = session;
        _isInitiating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Verification session created. Please complete the verification process.'),
            backgroundColor: AppColors.electricGreen,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isInitiating = false;
      });
    }
  }

  Future<void> _openVerificationUrl() async {
    if (_session?.verificationUrl == null) return;

    try {
      final uri = Uri.parse(_session!.verificationUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening verification link: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _refreshStatus() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) return;

      final session =
          await _verificationService.getUserVerification(authState.user.id);
      setState(() {
        _session = session;
      });
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Identity Verification',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStatus,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    _buildInfoCard(),
                    const SizedBox(height: 24),

                    // Verification Status
                    if (_session != null) ...[
                      _buildStatusCard(),
                      const SizedBox(height: 24),
                    ],

                    // Instructions
                    _buildInstructions(),
                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionButtons(),

                    // Error Display
                    if (_error != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: AppColors.error),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: AppTheme.primaryColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Identity Verification',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _needsVerification
                ? 'You need to verify your identity to continue receiving payments. This is required for users earning \$5,000+ per month or \$20,000+ lifetime.'
                : 'Identity verification is not currently required. You\'ll be notified if verification becomes necessary.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _session!.status;
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case VerificationStatus.pending:
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.pending;
        statusText = 'Pending';
        break;
      case VerificationStatus.processing:
        statusColor = AppTheme.primaryColor;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Processing';
        break;
      case VerificationStatus.verified:
        statusColor = AppColors.electricGreen;
        statusIcon = Icons.check_circle;
        statusText = 'Verified';
        break;
      case VerificationStatus.failed:
        statusColor = AppColors.error;
        statusIcon = Icons.error;
        statusText = 'Failed';
        break;
      case VerificationStatus.expired:
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.access_time;
        statusText = 'Expired';
        break;
      case VerificationStatus.cancelled:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.cancel;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, size: 32, color: statusColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: $statusText',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      'Started: ${_formatDate(_session!.createdAt)}',
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
          if (_session!.expiresAt != null &&
              status == VerificationStatus.pending) ...[
            const SizedBox(height: 12),
            Text(
              'Expires: ${_formatDateTime(_session!.expiresAt!)}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.warningColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructions() {
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
            'Verification Instructions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInstructionStep(
            1,
            'Click "Start Verification" to begin the process',
          ),
          _buildInstructionStep(
            2,
            'You\'ll be redirected to our secure verification partner (Stripe Identity)',
          ),
          _buildInstructionStep(
            3,
            'Follow the on-screen instructions to upload your ID documents',
          ),
          _buildInstructionStep(
            4,
            'Complete the verification process (usually takes 5-10 minutes)',
          ),
          _buildInstructionStep(
            5,
            'Return to this page to check your verification status',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(int step, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_session == null) {
      return ElevatedButton(
        onPressed: _isInitiating ? null : _initiateVerification,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 48),
        ),
        child: _isInitiating
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : const Text('Start Verification'),
      );
    }

    if (_session!.status == VerificationStatus.verified) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.electricGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.electricGreen.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.electricGreen, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your identity has been verified successfully!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.electricGreen,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_session!.status == VerificationStatus.pending ||
        _session!.status == VerificationStatus.processing) {
      return Column(
        children: [
          ElevatedButton.icon(
            onPressed:
                _session!.verificationUrl != null ? _openVerificationUrl : null,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Continue Verification'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppColors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          if (_session!.status == VerificationStatus.processing) ...[
            const SizedBox(height: 12),
            Text(
              'Your verification is being processed. Please check back later.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      );
    }

    if (_session!.status == VerificationStatus.failed ||
        _session!.status == VerificationStatus.expired ||
        _session!.status == VerificationStatus.cancelled) {
      return ElevatedButton(
        onPressed: _isInitiating ? null : _initiateVerification,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 48),
        ),
        child: _isInitiating
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : const Text('Retry Verification'),
      );
    }

    return const SizedBox.shrink();
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
