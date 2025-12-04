import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spots/core/models/tax_document.dart';
import 'package:spots/core/models/tax_profile.dart';
import 'package:spots/core/services/tax_compliance_service.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';

/// Tax Documents Page
/// 
/// Agent 2: Phase 5, Week 18-19 - Tax UI
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - List of tax documents
/// - Download 1099 forms
/// - Tax year selection
/// - Earnings summary
class TaxDocumentsPage extends StatefulWidget {
  const TaxDocumentsPage({super.key});

  @override
  State<TaxDocumentsPage> createState() => _TaxDocumentsPageState();
}

class _TaxDocumentsPageState extends State<TaxDocumentsPage> {
  final TaxComplianceService _taxService = TaxComplianceService(
    paymentService: GetIt.instance<PaymentService>(),
  );

  int _selectedYear = DateTime.now().year;
  List<TaxDocument> _documents = [];
  TaxProfile? _taxProfile;
  double _currentYearEarnings = 0.0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('Please sign in to view tax documents');
      }

      // Load tax profile
      final profile = await _taxService.getTaxProfile(authState.user.id);
      
      // Calculate current year earnings
      final needsDocs = await _taxService.needsTaxDocuments(authState.user.id, _selectedYear);
      final earnings = await _calculateEarnings(authState.user.id, _selectedYear);

      // Load documents for selected year
      final documents = await _taxService.getTaxDocuments(
        authState.user.id,
        _selectedYear,
      );

      setState(() {
        _taxProfile = profile;
        _currentYearEarnings = earnings;
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<double> _calculateEarnings(String userId, int year) async {
    // In production, this would calculate from PaymentService
    // For now, return a placeholder
    return 0.0;
  }

  Future<void> _downloadDocument(TaxDocument document) async {
    if (document.documentUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document not yet available'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(document.documentUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening document: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tax Documents',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Earnings Summary
                        _buildEarningsSummary(),
                        const SizedBox(height: 24),

                        // Tax Year Selector
                        _buildYearSelector(),
                        const SizedBox(height: 24),

                        // Documents List
                        _buildDocumentsList(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEarningsSummary() {
    final needsDocs = _currentYearEarnings >= 600.0;

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
            '${_selectedYear} Earnings Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Earnings',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${_currentYearEarnings.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: needsDocs
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : AppColors.electricGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      needsDocs ? Icons.info : Icons.check_circle,
                      size: 16,
                      color: needsDocs
                          ? AppTheme.primaryColor
                          : AppColors.electricGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      needsDocs ? 'Tax Docs Required' : 'Below Threshold',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: needsDocs
                            ? AppTheme.primaryColor
                            : AppColors.electricGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (needsDocs && !(_taxProfile?.w9Submitted ?? false)) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: AppTheme.warningColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'W-9 form required to generate tax documents',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tax Year',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.grey300),
          ),
          child: DropdownButton<int>(
            value: _selectedYear,
            isExpanded: true,
            underline: const SizedBox(),
            items: List.generate(5, (index) {
              final year = DateTime.now().year - index;
              return DropdownMenuItem(
                value: year,
                child: Text(
                  year.toString(),
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              );
            }),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedYear = value;
                });
                _loadData();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsList() {
    if (_documents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.description, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No tax documents for ${_selectedYear}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentYearEarnings < 600.0
                  ? 'Earnings are below the $600 threshold. No tax documents required.'
                  : 'Tax documents will be generated after W-9 submission.',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tax Documents',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ..._documents.map((document) {
          return _buildDocumentCard(document);
        }),
      ],
    );
  }

  Widget _buildDocumentCard(TaxDocument document) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getFormTypeDisplayName(document.formType),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Tax Year ${document.taxYear}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(document.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Earnings',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '\$${document.totalEarnings.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (document.documentUrl != null)
                OutlinedButton.icon(
                  onPressed: () => _downloadDocument(document),
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TaxStatus status) {
    Color badgeColor;
    String badgeText;

    switch (status) {
      case TaxStatus.notRequired:
        badgeColor = AppColors.grey400;
        badgeText = 'Not Required';
        break;
      case TaxStatus.pending:
        badgeColor = AppTheme.warningColor;
        badgeText = 'Pending';
        break;
      case TaxStatus.generated:
        badgeColor = AppTheme.primaryColor;
        badgeText = 'Generated';
        break;
      case TaxStatus.sent:
        badgeColor = AppColors.electricGreen;
        badgeText = 'Sent';
        break;
      case TaxStatus.filed:
        badgeColor = AppColors.electricGreen;
        badgeText = 'Filed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }

  String _getFormTypeDisplayName(TaxFormType formType) {
    switch (formType) {
      case TaxFormType.form1099K:
        return 'Form 1099-K';
      case TaxFormType.form1099NEC:
        return 'Form 1099-NEC';
      case TaxFormType.formW9:
        return 'Form W-9';
    }
  }
}

