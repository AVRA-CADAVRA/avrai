import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/core/legal/privacy_policy.dart';
import 'package:spots/core/services/legal_document_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';

/// Privacy Policy Page
///
/// Agent 2: Phase 5, Week 18-19 - Legal Document UI
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Privacy Policy display
/// - Version number
/// - Effective date
/// - Accept button (optional)
class PrivacyPolicyPage extends StatefulWidget {
  final bool requireAcceptance;

  const PrivacyPolicyPage({
    super.key,
    this.requireAcceptance = false,
  });

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  final LegalDocumentService _legalService =
      GetIt.instance<LegalDocumentService>();

  bool _hasAccepted = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAcceptanceStatus();
  }

  Future<void> _checkAcceptanceStatus() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final accepted =
            await _legalService.hasAcceptedPrivacyPolicy(authState.user.id);
        setState(() {
          _hasAccepted = accepted;
        });
      }
    } catch (e) {
      // Ignore errors, assume not accepted
    }
  }

  Future<void> _acceptPrivacyPolicy() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('Please sign in to accept Privacy Policy');
      }

      await _legalService.acceptPrivacyPolicy(
        userId: authState.user.id,
        ipAddress: null, // In production, get from request
        userAgent: null, // In production, get from request
      );

      setState(() {
        _hasAccepted = true;
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Privacy Policy accepted'),
            backgroundColor: AppColors.electricGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: AppColors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        if (widget.requireAcceptance) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Info
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.privacy_tip, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Version ${PrivacyPolicy.version}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Effective: ${_formatDate(PrivacyPolicy.effectiveDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_hasAccepted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.electricGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: 16, color: AppColors.electricGreen),
                            const SizedBox(width: 4),
                            Text(
                              'Accepted',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.electricGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Privacy Policy Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Text(
                PrivacyPolicy.content,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
              ),
            ),
          ),

          // Accept Button (if required or not yet accepted)
          if (widget.requireAcceptance || !_hasAccepted) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.grey300)),
              ),
              child: Column(
                children: [
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                  color: AppColors.error, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _acceptPrivacyPolicy,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white),
                            ),
                          )
                        : const Text('I Accept the Privacy Policy'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
